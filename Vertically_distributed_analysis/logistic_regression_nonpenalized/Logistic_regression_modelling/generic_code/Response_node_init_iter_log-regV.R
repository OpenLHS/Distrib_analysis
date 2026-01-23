############### Distributed inference ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_log_reg <- function(man_wd=-1, man_lambda, man_eta, expath = "", privacy_switch, man_seed) {

manualseed <- man_seed
manualwd <- man_wd
lambda <- man_lambda
eta <- man_eta
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

### Rank function for Gram matrices
rank_psd_chol <- function(A) {
  R <- suppressWarnings(chol(A, pivot = TRUE, tol = -1))
  return(attr(R, "rank"))
}

### Inverse of a matrix S using Woodbury
Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>
 
// [[Rcpp::export]]
Eigen::MatrixXd S_inv_woodbury(const Eigen::VectorXd& v, const Eigen::MatrixXd& Y, double eta){
    // Computes Sinv = (Diag(v)^{-1} + (1/(n*eta))*Y*Y^T)^{-1} using Woodbury.
    // For A = Diag(v)^{-1}, it computes
    // Sortie =  A^(-1) -  A^(-1) Y (n*eta*I + Y^top A^(-1) Y)^(-1) Y^top A^(-1)
    // v: n-vector (should be strictly positive)
    // Y: n x k
    const int n = static_cast<int>(v.size());
 
    // Compute a_vect
    Eigen::VectorXd a_vect = (1/v.array());
 
 
 
    // M = eta*I + Y^top A Y (k x k)
    Eigen::MatrixXd AY = Y.array().colwise() / a_vect.array();  // A^{-1}Y
    Eigen::MatrixXd Mat_M = Y.transpose() * AY;
    Mat_M.diagonal().array() += eta*n;
 
    // Construct Cholesky decomposition of M
    Eigen::LLT<Eigen::MatrixXd> llt(Mat_M);
    Eigen::MatrixXd Minv =
    llt.solve(Eigen::MatrixXd::Identity(Mat_M.rows(), Mat_M.cols()));
    
 
 
    // compute -A^(-1) Y (eta*I + Y^top A^(-1) Y)^(-1) Y^top A^(-1) = M_inv * Y^top A^(-1)
    Eigen::MatrixXd Sortie = -AY * Minv * AY.transpose();
 
    // compute A^(-1) -  A^(-1) Y (eta*I + Y^top A^(-1) Y)^(-1) Y^top A^(-1)
    Sortie.diagonal().array() += 1.0/a_vect.array();
    return(Sortie);
}
'
)

###Solve parameter of dual optimization problem
Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>
#include <random>

using VecLD = Eigen::Matrix<long double, Eigen::Dynamic, 1>;

// [[Rcpp::export]]
double fix_lambda(const int& n){
    double lambda = 0.000005;
    if(n>200000){
        lambda = 1.0/n;
    }
    return(lambda);
}

double fix_epsilon(const int& n, const int& p, const double& lambda){
    double epsilon = 0.0;
    if(n<=10000){
        epsilon = 2.0*lambda/( sqrt((p+1.0)*(p*(n-1.0)+n) ) *n);
    }else{
        epsilon = 10.0*lambda/( sqrt((p+1.0)*(p*(n-1.0)+n) ) *n );
    }
    return(epsilon);
}

double objective_fct(const Eigen::VectorXd& alpha, const Eigen::MatrixXd& Yk){
    // Compute the objective function J lambda (alpha)
    // Yk is a matrix such that Yk Yk^top = 1/lambda diag(y) ( XXt + 11^top) diag(y)
    
    double t1 = 0.5 * (Yk.transpose() * alpha).squaredNorm();
    int n = static_cast<int>(alpha.size());
    
    double temp2 =0;
    for(int i =0; i <n; i++){
        temp2 += (1.0-alpha(i)) * std::log(1.0-alpha(i)) + alpha(i)  * std::log(alpha(i));
    }
    return(t1 + temp2);
}

long double objective_fct_high_prec(const Eigen::VectorXd& alpha, const Eigen::MatrixXd& Yk){
    // Compute the objective function
    
    VecLD v_ld = (Yk.transpose() * alpha).cast<long double>();
    long double t1 = 0.5 * v_ld.squaredNorm();
    int n = static_cast<int>(alpha.size());
    
    long double temp2 =0.0;
    for(int i =0; i <n; i++){
        temp2 += (1.0-alpha(i)) * std::log(1.0-alpha(i)) + alpha(i)  * std::log(alpha(i));
    }
    return(t1 + temp2);
}

Eigen::VectorXd grad_fct(const Eigen::VectorXd& alpha, const int& n, const double& lambda, const Eigen::MatrixXd& Ky){
    // compute the gradient of objective_fct
    // equals to nabla J lambda (alpha)
    // Ky = diag(y) (K + 1_n 1_n top) diag(y)
    
    Eigen::VectorXd grad(n);
    // First compute Ky alpha and store result inthe vector result
    Eigen::VectorXd result = Ky * alpha;
    
    for(int i=0; i<n; i++){
        grad(i) = result(i)/(lambda) + std::log(alpha(i)/(1-alpha(i)));
    }
    return(grad);
}

Eigen::VectorXd Newton_Update(const Eigen::VectorXd& alpha, const int& n, const Eigen::MatrixXd& Yk, const Eigen::VectorXd& grad_c){
    // compute the Newton Update using Woodbury identity.
    
    Eigen::VectorXd Dalpha_inv(alpha.size());
    Dalpha_inv.array() = 1.0 / (alpha.array() * (1.0 - alpha.array()));
    
    Eigen::MatrixXd Xs =  Yk.array().colwise() / Dalpha_inv.array().sqrt();
    Eigen::MatrixXd Mat_M = Xs.transpose() * Xs;
    Mat_M.diagonal().array() += 1.0;
    
    // Construct Cholesky decomposition of M
    Eigen::LLT<Eigen::MatrixXd> llt;
    llt.compute(Mat_M);
    
    Eigen::VectorXd grand_alpha = grad_c.array()/ sqrt(Dalpha_inv.array());
    Eigen::VectorXd rhs = Xs.transpose() * grand_alpha;
    Eigen::VectorXd x = llt.solve(rhs);
    
    Eigen::VectorXd grad_2 = grad_c - Yk * x;
    Eigen::VectorXd sortie = grad_2.array()/Dalpha_inv.array();
    
    return(sortie);
}

// [[Rcpp::export]]
Eigen::MatrixXd gram_factor_pivoted_cholesky(const Eigen::MatrixXd& G,int max_rank, double tol = 1e-12) {
    const Eigen::Index n = G.rows();

    // Diagonal residuals residual_diag = diag(G - L L^T). Initially diag(G).
    Eigen::VectorXd residual_diag = G.diagonal();
    double traceG = residual_diag.sum();

    // Permutation vector (we pivot by swapping indices)
    std::vector<Eigen::Index> piv(n); // piv(n) is a vector that is used to separate “used” from “unused” indices as the factorization grows. At iteration k, as a column l is selected among piv(k:n), it is brought in position k so that piv(0:k) contains indices of pivots (columns) that have already been chosen.
    
    for (Eigen::Index i = 0; i < n; ++i) piv[i] = i; // initialization of the pivot vector

    Eigen::MatrixXd L = Eigen::MatrixXd::Zero(n, max_rank); // matrix that will be outputed, to be progressively build.

    double resid_trace = traceG;
    int k = 0;

    while (k < max_rank && resid_trace > tol * traceG) {
        // Find pivot: index with largest residual diagonal
        Eigen::Index jmax = k; // will contain the index such that piv(jmax) has the largest residual diagnoal among remaining pivots stored in piv(k:n)
        double rmax = residual_diag(piv[k]); // will contain the largest residual diagonal among remaining pivots stored in piv(k:n)
        
        for (Eigen::Index j = k + 1; j < n; ++j) {
            double val = residual_diag(piv[j]);
            if (val > rmax) { rmax = val; jmax = j; }
        }
        if (rmax <= 0.0) break; // no more PSD mass

        // Swap pivot into position k
        std::swap(piv[k], piv[jmax]); // bring the pivot at position piv[jmax] in position piv[k] so that piv(0:k) contains the indices that have already been selected.

        Eigen::Index pk = piv[k]; // pk now denotes the index of the pivot
        double diagk = residual_diag(pk);
        double Lkk = std::sqrt(diagk);
        L(pk, k) = Lkk;

        // Compute column k for all remaining pivot indices i >= k
        for (Eigen::Index t = k + 1; t < n; ++t) {
            Eigen::Index pi = piv[t];

            // Compute: (G(pi, pk) - sum_{m<k} L(pi,m)*L(pk,m)) / Lkk
            double s = G(pi, pk);
            for (int m = 0; m < k; ++m) {
                s -= L(pi, m) * L(pk, m);
            }
            double Lik = s / Lkk;
            L(pi, k) = Lik;

            // Update residual diagonal r(pi) -= Lik^2
            residual_diag(pi) -= Lik * Lik;
            if (residual_diag(pi) < 0.0) residual_diag(pi) = 0.0; // numerical guard
        }

        // Update residual trace (sum of remaining diagonals)
        resid_trace = 0.0;
        for (Eigen::Index t = k + 1; t < n; ++t) resid_trace += residual_diag(piv[t]);

        ++k;
    }

    // Return only computed rank k columns
    return L.leftCols(k);
}

// [[Rcpp::export]]
Eigen::VectorXd find_alpha_chap(Eigen::MatrixXd& K,Eigen::VectorXd& y, const int& p_covariates, double lambda){
    // K is the sum of all the local gram matrix, excluding the constant 11 top
    // p_covariate is the total number of covariates
    // the gram matrix K is modified within this algorithm to save mempory space!!!
    
    // Defining the parameter lambda to be used during the optimization
    const int n = static_cast<int>(y.size());
    
    // Defining the parameter tau for the armijo criteria in the optimization producedure
    const double tau = 0.00000001;
    
    // Defining the parameter eps for defining the box contraint
    double eps = 1e-14;

    
    // Initialisations pour lalgorithme dopimisation de Alpha
    K.array() += 1.0; // K is now the gram matrix + 1n 1n top
    K.array().colwise() *= y.array();               // right multiply by diag(y): scale columns
    K.array().rowwise() *= y.transpose().array();   // left multiply by diag(y): scale rows
    // La matrice K est donc égale à K = diag(y)(gram matrix + 1n 1n top) diag(y)
    
    Eigen::MatrixXd Yk = gram_factor_pivoted_cholesky(K,p_covariates+1);
    // sort une matrice Yk telle que Yk Yk^top = K
    //
    // Boucle pour trouver alpha chapeau
    //
    
    Eigen::VectorXd alpha_courrant=Eigen::VectorXd::Constant(n, 0.1); // initialisation du vecteur alpha
    Eigen::VectorXd grad_courrant = grad_fct(alpha_courrant, n, lambda, K);
    
    bool condition_sortie = true; // initialisation de la condition de sortie de la boucle
    
    double epsilon = fix_epsilon(n, static_cast<int>(Yk.cols()) -1 ,lambda); //rank of Yk = p+1, epsilon takes p as input
    
    lambda *= n; // To match MPDs code
    epsilon *= n; // To match MPDs code
    
    Yk.array() *= (1.0/sqrt(lambda));          // Yk contient maintenant une matrice telle que Yk Yk top = (1/lambda) diag(y)(K + 1n 1n top)diag(y)
    
    while(condition_sortie){
        
        double Newton_stepsize = 1.0;
        Eigen::VectorXd Newton_dc = Newton_Update(alpha_courrant, n,Yk, grad_courrant);
        
        Eigen::VectorXd alpha_candidate(n);
        bool reject_new_candidate = true;
        while(reject_new_candidate){
            
            // calculate alpha_candidate with current Newton_stepsize;
            for(int i = 0; i<n;i++){
                bool condition_i = ((alpha_courrant(i) <= eps ) & (grad_courrant(i) >0.0) ) | ((alpha_courrant(i) >= (1.0-eps) ) & (grad_courrant(i) < 0.0) );
                if(condition_i){
                    alpha_candidate(i) = alpha_courrant(i) - Newton_stepsize * grad_courrant(i);
                }
                else{
                    alpha_candidate(i) = alpha_courrant(i) - Newton_stepsize * Newton_dc(i);
                }
                
                double temp = std::clamp(alpha_candidate(i), eps, 1.0 - eps); // if alpha_i is outside the box, re-enter it in the box
                alpha_candidate(i) = temp;
                
            }
            
            // In praparation for assessing if convergence conditions are met
            
            double norm_grad = grad_courrant.norm(); // sqrt(sum_i ai 2 )
            
            Eigen::VectorXd Diff_alpha = alpha_courrant - alpha_candidate; // The following two lines: to compute Sum(grad_i *(alpha_courrant_i - alpha_candidate_i))
            double prod_grad_diffapha = grad_courrant.dot(Diff_alpha);
            
            double rhs_armijo = tau * prod_grad_diffapha; // compute 0.00000001*(sum(grad_u*(alpha_u-alpha_u1)))
            if(norm_grad>1){
                double objective_alpha_courrant = objective_fct(alpha_courrant,Yk);
                double objective_alpha_candidate = objective_fct(alpha_candidate,Yk);
                double diff = objective_alpha_courrant - objective_alpha_candidate;
                if(diff >= rhs_armijo){
                    reject_new_candidate = false;
                }
            }
            else{
                long double objective_alpha_courrant = objective_fct_high_prec(alpha_courrant,Yk);
                long double objective_alpha_candidate = objective_fct_high_prec(alpha_candidate,Yk);
                long double diff = objective_alpha_courrant - objective_alpha_candidate;
                if(diff >= rhs_armijo){
                    reject_new_candidate = false;
                }
            }
            
            Newton_stepsize *= 0.5;
        }
        alpha_courrant =alpha_candidate;
        grad_courrant = grad_fct(alpha_courrant, n, lambda, K);
        double norm_grad = grad_courrant.norm();
        if(norm_grad<epsilon){
            condition_sortie = false;
        }
        
    }
    return(alpha_courrant);
}

// [[Rcpp::export]]
Eigen::VectorXd sample_from_ker_Gram(Eigen::MatrixXd& Yk, const int random_seed=123){
    // Yk is a matrix such that Yk Yk top = Gram
    // random_seed is to initialize the random number generator
    // returns a vector that lives in Ker(Gram) = Ker(Yk top)
    // computes the projection matrix I - Yk (Yk top Yk) pow(-1) Yk top, then samples and project onto Ker(Yk top).
    
    const int n = static_cast<int>(Yk.rows());
    
    Eigen::MatrixXd S_varcovar = Yk.transpose() * Yk;          // rank(Yk) x rank(Yk)
    Eigen::LLT<Eigen::MatrixXd> llt(S_varcovar);             // Cholesky

    // One sample
    std::mt19937_64 rng(random_seed);
    std::normal_distribution<double> normal(0.0, 1.0);

    Eigen::VectorXd z =
      Eigen::VectorXd::NullaryExpr(n, [&](){ return normal(rng); }); // creates a vector of n iid normal(0,1)
    
    double nz = z.norm();
    z.array() *= 1.0/nz;

    Eigen::VectorXd u = Yk.transpose() * z;          // = Yk * z
    Eigen::VectorXd w = llt.solve(u);               // = (Yk top Yk) pow(-1) Yk z
    Eigen::VectorXd x = z - Yk * w;                 // = (I - Yk (Yk top Yk) pow(-1) Yk) z
    
    return(x);
}
'
)


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
  p <- rank_psd_chol(reconstruct_from_upper_tri(node_k, n))
}

#Setting parameters lambda (penalty) and epsilon (convergence) for the algorithm 
#Can be adjusted if needed, please refer to article to ensure adequate settings
if(lambda==-1){
  lambda = fix_lambda(n)
}

if(lambda<=0){
  stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
}

if(eta==-1){
  eta <- 10^(-7)
}

if(eta<=0){
  stop("The algorithm cannot run because the penalty parameter eta was set lower or equal to 0.")
}


# Algorithm and coefficients ---------------------------------------------

###Projected newton raphson 

alpha_chap <- find_alpha_chap(K_all-1,y, p, lambda) 
gc()
alpha_u <- alpha_chap

# Exporting quantities to be sent to covariate-nodes -----------------------

### Adjustments to fit the following implementation simplified with a factor of n
lambda <- lambda*n

###Recomputing Global Gram matrix
K_all <- cov_node_1%*%t(cov_node_1)
for (k in 2:K) {
  node_k <- readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds"))
  # Adding local Gram Matrices
  K_all <- K_all + reconstruct_from_upper_tri(node_k, n)
}

### Produce the inverse matrix of S for standard errors
Yk <- gram_factor_pivoted_cholesky(K_all,p+1)
rm(K_all,node_k)
gc()
S_inv <- S_inv_woodbury(alpha_chap*(1-alpha_chap), Yk, eta)
gc()


### Produce and export system of equation results and noisy inverse of S for each nodes

# If Privacy-check switch is on for response-node data, import privacy check function
if(privacy_switch==1){
  source("Response_node_optionnal_confidentiality.R")
}

for (k in 2:K) {
  # Vector of ck to export
  gram_k <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath, "Data_node_", k, "_init_output.rds")), n)
  pk <- rank_psd_chol(reconstruct_from_upper_tri(gram_k, n))
  c_system_k <- (1/lambda)*arma_mm(gram_k,(alpha_u*y))
  eta_shared <- eta
  length(eta_shared) <- length(c_system_k)
  write.csv(data.frame(c_system_k,eta_shared),
            file=paste0(examplefilepath, "Coord_node_primerA_for_data_node_",k ,".csv"), row.names=FALSE)
  
  # If Privacy-check switch is on for response-node data, run privacy check
  if(privacy_switch==1){
    null_addition_k2 <- nullspace_sym_pd(gram_k, tol = 1e-8)
    print(paste0("Privacy check with data from covariate node ", k, "."))
    flippable_ys_nodek <- privacy_check_ck2_complete(null_addition_k2,alpha_u,y,n,k,examplefilepath,manualseed)
    rm(null_addition_k2)
  } 
  
  # Inverse of S plus part in ker of gram matrix to export
  null_addition_k <- sample_from_ker_Gram(gram_factor_pivoted_cholesky(gram_k,pk),123)
  saveRDS(extract_upper_tri(0.1*tcrossprod(null_addition_k)+S_inv), file = paste0(examplefilepath, "Coord_node_primerB_for_data_node_",k,".rds"), compress = TRUE)
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
err_node_1 <- sqrt(rep((1/(n*eta)),ncol(cov_node_1))-(1/((n^2)*(eta^2)))*(as.vector(diag(t(cov_node_1)%*%S_inv%*%cov_node_1))))
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
