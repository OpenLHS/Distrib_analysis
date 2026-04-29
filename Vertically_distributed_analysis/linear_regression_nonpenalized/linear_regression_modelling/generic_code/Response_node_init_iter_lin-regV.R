############### Distributed inference ####################
############### Response-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages -------------------------------------------------------------
library(Matrix)
library(Rcpp)
library(RcppArmadillo)
library(RcppEigen)

coord_lin_reg <- function(man_wd=-1, man_tau=-1, man_eta=-1, expath = "") {
  
  # Setting up core variables
  tau <- man_tau
  manualwd <- man_wd
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
  
  # R functions-------------------------------------------------------------------
  
  ### Rank function for Gram matrices
  rank_psd_chol <- function(A) {
    R <- suppressWarnings(chol(A, pivot = TRUE, tol = -1))
    return(attr(R, "rank"))
  }
  
  # Functions RCPP Armadillo  ----------------------------------------------------
  
  Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>
#include <random>

using VecLD = Eigen::Matrix<long double, Eigen::Dynamic, 1>;
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
  
  ### Inverse symmetric positive definite matrix
  cppFunction('
  arma::mat inv_sympd_matrix(const arma::mat& A) {
    // Calculer linverse dune matrice symétrique définie positive
    return arma::inv_sympd(A);
  }
', depends = "RcppArmadillo")
  
  ### Inverse of a matrix S using Woodbury
  Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>
 
// [[Rcpp::export]]
Eigen::MatrixXd S_inv_woodbury(const Eigen::VectorXd& v, const Eigen::MatrixXd& Y, double eta){
    // Computes Sinv = (Diag(v) + Y*Y^T)^{-1} using Woodbury.
    // For A = Diag(v), it computes
    // Sortie =  A^(-1) -  A^(-1) Y (I + Y^top A^(-1) Y)^(-1) Y^top A^(-1)
    // v: n-vector (should be strictly positive)
    // Y: n x k
 
    // Compute A^{-1} = Diag(1/v)
    Eigen::VectorXd a_inv = 1.0 / v.array();
 
    // AY = A^{-1} Y  (scale rows of Y by 1/v)
    Eigen::MatrixXd AY = Y.array().colwise() * a_inv.array();
 
    // M = I + Y^top A^{-1} Y  (k x k)
    Eigen::MatrixXd Mat_M = Y.transpose() * AY;
    Mat_M.diagonal().array() += 1.0;
 
    // Cholesky decomposition of M
    Eigen::LLT<Eigen::MatrixXd> llt(Mat_M);
    Eigen::MatrixXd Minv =
        llt.solve(Eigen::MatrixXd::Identity(Mat_M.rows(), Mat_M.cols()));
    
    // Sortie = A^{-1} - A^{-1} Y M^{-1} Y^top A^{-1}
    Eigen::MatrixXd Sortie = -AY * Minv * AY.transpose();
    Sortie.diagonal().array() += a_inv.array();

    return(Sortie);
}
'
  )
  
  ### Factor a matrix using Cholesky
  Rcpp::sourceCpp(code = '
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>
#include <random>

using VecLD = Eigen::Matrix<long double, Eigen::Dynamic, 1>;
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
'
  )
  
  # Extract node data and Initialization ----------------------------------------
  
  # Import data from response-node and verify if any missing values
  node_1_complete <- (read.csv(paste0(examplefilepath, "Data_node_1.csv")))
  if(any(is.na(node_1_complete))){
    stop("The dataset seems to contain NA value(s). The method cannot be applied. 
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
  }
  
  # Makes sure that the first column is the outcome variable (out1).
  if(colnames(node_1_complete)[1]!="out1"){
    stop("The outcome variable (out1) does not appear. Make sure the first column corresponds to the response vector and is denoted out1.") 
  }
  
  # Extract outcome variable and verify number of covariates at response-node (if any)
  node_1_complete <- as.matrix(node_1_complete)
  y <- node_1_complete[,1]
  y <- as.numeric(as.vector(y))
  p <- ncol(node_1_complete)-1
  p_response_node <- p
  
  # Scale covariates
  n <- nrow(node_1_complete)
  cov_node_1 <- cbind(scale(node_1_complete[,-1]))
  
  # Initialize Gram matrix from response-node
  K_all <- cov_node_1%*%t(cov_node_1)
  
  # Data from covariate-nodes
  K <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))+1
  for (k in 2:K) {
    node_k <- readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds"))
    m <- (-1+sqrt(1+8*length(node_k)))/2
    if (n != m) {
      stop("Nodes files do not seem to contain the same number of individuals.")
    }
    
    # Adding local Gram Matrices
    K_all <- K_all + reconstruct_from_upper_tri(node_k, n)
    p <- p + rank_psd_chol(reconstruct_from_upper_tri(node_k, n))
  }
  
  if(tau==-1){
    stop("The algorithm cannot run because the parameter tau was set to -1 (not initialized)")
  }else{
    eigenvalues <- eigen(K_all, symmetric = TRUE)$values
    smalleigen <- eigenvalues[p]
    lambda <- 2*smalleigen*tau/n
  }
  
  if(lambda<=0){
    stop("The algorithm cannot run because the parameter tau was set lower or equal to 0.")
  }
  
  if(eta==-1){
    eta <- 5*10^(-4)
  }
  
  if(eta<=0){
    stop("The algorithm cannot run because the penalty parameter eta was set lower or equal to 0.")
  }
  
  
  # Algorithm and coefficients ---------------------------------------------
  
  # Compute matrix M
  Id <- diag(1, nrow = n)
  One <- rep(1, n)
  M <- Id - (1/n)*One%*%t(One)
  
  # Compute alpha hat
  alpha_hat <- solve(a = (n*Id/2)+((K_all)/(lambda)), b = M%*%y) 
  
  # Exporting quantities to be sent to covariate-nodes -----------------------
  
  # Produce the inverse matrix of S for standard errors
  sigma2hat <- t(M%*%y - (1/lambda)*K_all%*%alpha_hat)%*%(M%*%y - (1/lambda)*K_all%*%alpha_hat)/(n-p-1)
  
  # Compute S_inv using woodbury identity
  Yk <- gram_factor_pivoted_cholesky(K_all,p+1)
  rm(K_all,node_k)
  #S_inv <- solve(eta*sigma2hat[1,1]*Id + K_all)
  S_inv <- S_inv_woodbury(rep(eta*sigma2hat, n), Y = Yk, eta = 1/n)
  
  gc()
  
  # Produce and export system of equation results and noisy inverse of S for each nodes
  for (k in 2:K) {
    # Vector of ck to export
    gram_k <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath, "Data_node_", k, "_init_output.rds")), n)
    pk <- rank_psd_chol(reconstruct_from_upper_tri(gram_k, n)) 
    c_system_k <- (1/lambda)*gram_k%*%alpha_hat

    eta_shared <- eta
    length(eta_shared) <- length(c_system_k)
    write.csv(data.frame(c_system_k,eta_shared),
              file=paste0(examplefilepath, "Coord_node_primerA_for_data_node_",k ,".csv"), row.names=FALSE)

    # Inverse of S plus part in ker of gram matrix to export
    null_addition_k <- sample_from_ker_Gram(gram_factor_pivoted_cholesky(gram_k,pk),123)
    saveRDS(extract_upper_tri(0.1*tcrossprod(null_addition_k)+S_inv), file = paste0(examplefilepath, "Coord_node_primerB_for_data_node_",k,".rds"), compress = TRUE)
  }
  
  # Exporting final results at response-node (if any covariates)  ---------------------------- 
  covariate_names_response <- "NA"
  
  # Compute coefficients for response-node (if any covariates)
  if(p_response_node>0){
    c_system_1 <- (1/lambda)*cov_node_1%*%t(cov_node_1)%*%alpha_hat
    MX <- M%*%node_1_complete[,-1]
    beta_node_1 <- solve(t(MX)%*%MX)%*%t(MX)%*%c_system_1
    covariate_names_response <- colnames(node_1_complete)[-1]}else{
      beta_node_1 <- NA
    }
  
  # Produce standard error and two-sided p-values for response-node (if any covariates)
  if(p_response_node>0){
    data_unscaled <- as.matrix(node_1_complete[,-1])
    W <- diag(apply(data_unscaled, 2, sd), nrow = p_response_node)
    Winv <- diag(1/apply(data_unscaled, 2, sd), nrow = p_response_node)
    Idpk <- diag(nrow = ncol(data_unscaled))
    
    err_node_1 <- sqrt(diag(
      Winv%*%( (1/eta)*Idpk - (1/eta)*t(cov_node_1)%*%S_inv%*%cov_node_1 )%*%Winv
    ))
    p_vals_1 <- 2*(1 - pnorm(abs(beta_node_1)/err_node_1))}else{
      err_node_1 <- NA
      p_vals_1 <- NA
    }
  
  data.frame(coefs=beta_node_1,std_error=err_node_1,two_sided_pvalue=p_vals_1)
  
  # Export results
  write.csv(data.frame(coefs=beta_node_1,std_error=err_node_1,two_sided_pvalue=p_vals_1),
            file=paste0(examplefilepath, "Data_node_1_results.csv"), row.names=covariate_names_response)
  
  # Remove all environment variables. 
  # If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
