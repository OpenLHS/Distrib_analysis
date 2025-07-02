############### Distributed inference ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_log_reg <- function(man_wd=-1, man_lambda, expath = "", privacy_switch) {

manualwd <- man_wd
lambda <- man_lambda
examplefilepath <- expath

if (manualwd != 1) {
  
  # Set working directory automatically

  # this.path package is available
  if (require(this.path)) {
    setwd(this.dir())
    
    # else if running in R studio and the rstudioapi is available, set the correct working directory
  } else if ((Sys.getenv("RSTUDIO") == "1") & (require("rstudioapi"))) {
    print("RSTUDIO")
    path <- dirname(rstudioapi::getActiveDocumentContext()$path)
    setwd(path)
    
    # no known means to automatically allocate node number
  } else {
    stop("The required conditions to automatically set the working directory are not met. See R file")
  }
} else {
  print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
}

# Libraries and rcpp functions needed for the procedure -----------------------

### LIBRARY
library(Matrix)
library(glmnet)
library(Rcpp)
library(RcppArmadillo)
library(Rmpfr)
library(pracma)
library(RcppEigen)


# Functions RCPP Armadillo

### Matrix times vector multiplication
cppFunction('arma::vec arma_mm(const arma::mat& m, const arma::vec& v) {
       return m * v;
   };', depends = "RcppArmadillo")

### Solve linear system with symmetric positive definite matrix and a vector
cppFunction('
  arma::mat solve_system_spd(const arma::mat& A, const arma::mat& B) {

    // Options pour solve() pour matrice symétrique définie positive
    arma::solve_opts::opts opts = arma::solve_opts::likely_sympd;

    // Résoudre le système linéaire Ax = B avec Armadillo
    return arma::solve(A, B, opts);
  }
', depends = "RcppArmadillo")

### Inverse symmetric positive definite matrix
cppFunction('
  arma::mat inv_sympd_matrix(const arma::mat& A) {
    // Calculer linverse dune matrice symétrique définie positive
    return arma::inv_sympd(A);
  }
', depends = "RcppArmadillo")

### Extract upper triangle from symmetric matrix
cppFunction('
  arma::vec extract_upper_tri(const arma::mat& A) {

    // Extract the upper triangular part including the diagonal
    arma::uword n = A.n_rows;
    arma::vec upper_tri(n * (n + 1) / 2);  // storage for upper triangular elements
    arma::uword idx = 0;

    for (arma::uword j = 0; j < n; ++j) {
      for (arma::uword i = 0; i <= j; ++i) {
        upper_tri(idx++) = A(i, j);  // store upper triangular elements
      }
    }

    return upper_tri;
  }
', depends = "RcppArmadillo")

### Construct symmetric matrix from upper triangle
cppFunction('
  arma::mat reconstruct_from_upper_tri(const arma::vec& upper_tri, arma::uword n) {
    arma::mat A(n, n, arma::fill::zeros);
    arma::uword idx = 0;

    for (arma::uword j = 0; j < n; ++j) {
      for (arma::uword i = 0; i <= j; ++i) {
        A(i, j) = upper_tri(idx);      // fill the upper triangular part
        A(j, i) = upper_tri(idx++);    // fill the symmetric lower part
      }
    }

    return A;
  }
', depends = "RcppArmadillo")

### Efficient L2 norm of a vector
cppFunction(depends = "RcppArmadillo", code = '
double l2_norm_rcpp(const arma::vec& x) {
    return arma::norm(x, 2);
    }
  ')

### Define the nullspace function using Eigen
cppFunction(depends = "RcppEigen", code = '
  Eigen::MatrixXd nullspace_sym_pd(Eigen::MatrixXd A, double tol = 1e-10) {
    Eigen::SelfAdjointEigenSolver<Eigen::MatrixXd> es(A);
    Eigen::VectorXd evals = es.eigenvalues();
    Eigen::MatrixXd evecs = es.eigenvectors();

    std::vector<int> null_indices;
    for (int i = 0; i < evals.size(); ++i) {
      if (evals[i] < tol) {
        null_indices.push_back(i);
      }
    }

    Eigen::MatrixXd nullspace(A.rows(), null_indices.size());
    for (int i = 0; i < null_indices.size(); ++i) {
      nullspace.col(i) = evecs.col(null_indices[i]);
    }

    return nullspace;
  }
')

# Extract node data and Initialization ----------------------------------------

### Import data from response-node and verify if any missing values
node_1_complete <- (read.csv(paste0(examplefilepath, "Data_node_1.csv")))
if(any(is.na(node_1_complete))){
  stop("The dataset seems to contain NA value(s). The method cannot be applied. 
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
}

# Makes sure that the first column is the outcome variable (out1).
if(colnames(node_1_complete)[1]!="out1"){
  stop("The outcome variable (out1) does not appear. Make sure the first column corresponds to the response vector and is denoted out1.") 
}

# Makes sure the outcome variable is properly coded as 0s and 1s.
if(!all(unique(node_1_complete$out1) %in% c(0,1))){
  stop("The outcome variable (out1) contains values that are different from 0 and 1, which isn't allowed.")
}

# Transform outcome and verify number of covariates at response-node (if any)
node_1_complete <- as.matrix(node_1_complete)
y <- node_1_complete[,1]
y[which(y==0)] <- -1
y <- as.numeric(as.vector(y))
p <- ncol(node_1_complete)-1
p_response_node <- p

# Add intercept column and scale covariates
n <- nrow(node_1_complete)
cov_node_1 <- cbind(rep(1,n),scale(node_1_complete[,-1]))

### Initialize Gram matrix from response-node
K_all <- cov_node_1%*%t(cov_node_1)

### Data from covariate-nodes
K <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))+1
for (k in 2:K) {
  node_k <- readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds"))
  m <- (-1+sqrt(1+8*length(node_k)))/2
  if (n != m) {
    stop("Nodes files do not seem to contain the same number of individuals.")
  }
    
  # Adding local Gram Matrices
  K_all <- K_all + reconstruct_from_upper_tri(node_k, n)
  p <- p + rankMatrix(reconstruct_from_upper_tri(node_k, n))[1]
}

#Setting parameters lambda (penalty) and epsilon (convergence) for the algorithm 
#Can be adjusted if needed, please refer to article to ensure adequate settings
if(lambda==-1){
if(n<=10000){
  lambda <- 0.0001
}else{lambda <- 1/n}}

if(lambda<=0){
  stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
}

if(n<=10000){
  epsilon <- 2*lambda*(((p+1)*(p*(n-1)+n))^(-1/2))*n^(-1)
}else{epsilon <- 2*lambda*(((p+1)*(p*(n-1)+n))^(-1/2))*5*(n^(-1))}

# Adjustments to fit the following implementation simplified with a factor of n
lambda <- lambda*n
epsilon <- epsilon*n

# Algorithm and coefficients ---------------------------------------------

###Initialize alpha between 0 and 1 (excluded) and n components
alpha_u <- rep(0.01,n)
alpha_u1 <- alpha_u

###Projected newton raphson 

#Quantity to reuse for Gradient and Hessian
hessian_grad_part1 <- (1/lambda)*(t(y*(K_all)))*y

#Output: Objective function
objfun <- function(x){
  (as.vector((1/(2*lambda))*t(x*y)%*%(K_all)%*%(x*y)))+(sum(x*log(x)+(1-x)*log(1-x)))
}

#Output: Gradient of objective function
gradient <- function(x){
  arma_mm(hessian_grad_part1, x)+(log(x/(1-x)))
}

#Output: Newton-Raphson step
newtonstep <- function(alpha){
  return(as.vector((solve_system_spd(hessian_grad_part1+diag(1/(alpha*(1-alpha))),
                                                      (arma_mm(hessian_grad_part1, alpha)+(log(alpha/(1-alpha))))))))
}

#Output: Difference in objective functions with higher precision for last iterations
diffobj <- function(xu1,xu){
  a <- mpfr(xu1, precBits = 128)  # Set precision to 200 bits
  b <- mpfr(xu, precBits = 128)
  cu1 <- mpfr((sum(a*log(a)+(1-a)*log(1-a))),precBits = 128)
  du <- mpfr((sum(b*log(b)+(1-b)*log(1-b))),precBits = 128)
  eu1 <- mpfr((as.vector((1/(2*lambda))*t(a*y)%*%(K_all)%*%(a*y))),precBits = 128)
  fu <- mpfr((as.vector((1/(2*lambda))*t(b*y)%*%(K_all)%*%(b*y))),precBits = 128)
  return(as.numeric(mpfr(du+fu-cu1-eu1,precBits = 128)))
}

#Algorithm: Update with gradient descent for out of bounds components with direction leading out of bounds+
#newton-raphson for other components. Step size based on Armijo rule adapted for projected newton.
#See original paper for additional details.
repeat{
  stepsize <- 1
  grad_u <- gradient(alpha_u)
  
  #identify components for gradient descent
  i <- which((alpha_u <= 10^(-14) & grad_u>0) | (alpha_u >= (1-10^(-14)) & grad_u<0))
  stepnewton <- newtonstep(alpha_u)
  #Proceed with projected newton using adapted step size
  repeat{
    if(isempty(i)){
      alpha_u1<-alpha_u - stepsize*stepnewton}else{
        alpha_u1[-i]<-alpha_u[-i]- stepsize*stepnewton[-i]
        alpha_u1[i]<-as.vector(alpha_u[i]-stepsize*((grad_u)[i]))}
    alpha_u1[which((alpha_u1 < 0))] <- 10^(-14)
    alpha_u1[which((alpha_u1 > 1))] <- 1-10^(-14)
    if(l2_norm_rcpp(grad_u)>1){
      if ((objfun(alpha_u)-objfun(alpha_u1))>=0.00000001*(sum(grad_u*(alpha_u-alpha_u1)))) break
    }else{
      if (diffobj(alpha_u1,alpha_u)>=0.00000001*(sum(grad_u*(alpha_u-alpha_u1)))) break
    }
    stepsize <- stepsize/2
  }   
  gc()
  #Verify if stopping criteria is satisfied
  if ((l2_norm_rcpp(gradient(alpha_u1)))<epsilon) break
  alpha_u <- alpha_u1
}
alpha_u <- alpha_u1

# Remove environment massive matrices and vector not needed anymore
rm(hessian_grad_part1,alpha_u1,stepnewton)

# If Privacy-check switch is on for response-node data, run privacy check
if(privacy_switch==1){
  source("Response_node_optionnal_confidentiality.R")
  for (k in 2:K) {
    node_k <- readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds"))
    K_k <- reconstruct_from_upper_tri(node_k, n)
    print(paste0("Privacy check with data from covariate node ", k, "."))
    flippable_ys_nodek <- privacy_check_ck2(K_k,alpha_u,y,lambda,n,k)
    rm(K_k)
  }  
}

# Exporting quantities to be sent to covariate-nodes -----------------------

### Produce the inverse matrix of S for standard errors
X_beta <- exp((1/lambda)*arma_mm(K_all,(alpha_u*y)))
S_inv <- inv_sympd_matrix((diag(1/as.vector((X_beta/
                                               (1+X_beta))*(1-(X_beta/(1+X_beta))))))+(1/(lambda/n))*K_all)

### Produce and export system of equation results and noisy inverse of S for each nodes
for (k in 2:K) {
  gram_k <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath, "Data_node_", k, "_init_output.rds")), n)
  c_system_k <- (1/lambda)*arma_mm(gram_k,(alpha_u*y))
  lambda_shared <- lambda/n
  length(lambda_shared) <- length(c_system_k)
  write.csv(data.frame(c_system_k,lambda_shared),
            file=paste0(examplefilepath, "Coord_node_primerA_for_data_node_",k ,".csv"), row.names=FALSE)
  null_addition_k <- nullspace_sym_pd(gram_k, tol = 1e-8)
  null_addition_k <- t(t(null_addition_k)*rnorm(ncol(null_addition_k)))
  saveRDS(extract_upper_tri(0.1*null_addition_k%*%t(null_addition_k)+S_inv), file = paste0(examplefilepath, "Coord_node_primerB_for_data_node_",k,".rds"), compress = TRUE)
}


# Exporting final results at response-node (if any covariates)  ---------------------------- 
covariate_names_response <- "NA"
### Compute coefficients for response-node (if any covariates)
beta_node_1 <- (1/lambda)*arma_mm(t(cov_node_1), alpha_u*y)
if(p_response_node>0){
  beta_node_1_adjusted <- c(beta_node_1[-1]/sapply(as.data.frame(node_1_complete[,-1]), sd))
  covariate_names_response <- colnames(node_1_complete)[-1]}else{
    beta_node_1_adjusted <- NA
  }

### Produce standard error and two-sided p-values for response-node (if any covariates)
err_node_1 <- sqrt(rep((1/(lambda/n)),ncol(cov_node_1))-(1/((lambda^2)/(n^2)))*(as.vector(diag(t(cov_node_1)%*%S_inv%*%cov_node_1))))
if(p_response_node>0){
  err_node_1_adjusted <- c(err_node_1[-1]/sapply(as.data.frame(node_1_complete[,-1]), sd))
  p_vals_1 <- 2*(1 - pnorm(abs(beta_node_1_adjusted)/err_node_1_adjusted))}else{
    err_node_1_adjusted <- NA
    p_vals_1 <- NA
  }


data.frame(coefs=beta_node_1_adjusted,std_error=err_node_1_adjusted,two_sided_pvalue=p_vals_1)
### Export results
write.csv(data.frame(coefs=beta_node_1_adjusted,std_error=err_node_1_adjusted,two_sided_pvalue=p_vals_1),
          file=paste0(examplefilepath, "Data_node_1_results.csv"), row.names=covariate_names_response)


## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
