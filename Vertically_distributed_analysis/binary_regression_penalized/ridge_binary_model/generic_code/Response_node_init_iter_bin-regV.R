############### VERTICALLY DISTRIBUTED RIDGE-PENALIZED BINARY REGRESSION ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


response_bin_reg <- function(man_wd=-1, man_lambda, expath = "", model_choice) {
  manualwd <- man_wd
  lambda <- man_lambda
  examplefilepath <- expath
  family_glm <- model_choice
  
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
  library(withr)
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
  
  ### Pivoted Cholesky Decomposition
  Rcpp::sourceCpp(code = ' 
// [[Rcpp::depends(RcppEigen)]]
#include <RcppEigen.h>

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
  }'
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
  
  # Transform outcome and verify number of predictors at response-node (if any)
  node_1_complete <- as.matrix(node_1_complete)
  y <- node_1_complete[,1]
  y <- as.numeric(as.vector(y))
  p <- ncol(node_1_complete)-1
  p_response_node <- p
  
  # Scale predictors
  n <- nrow(node_1_complete)
  
  if(p_response_node>0){
  cov_node_1 <- scale(node_1_complete[,-1])
  ### Initialize substitute matrix from response-node
  X_tilde <- cov_node_1}
  
  ### Data from predictor-nodes
  K <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))+1
  
  rank_k <- rep(NA,K)
  rank_k[1] <- p_response_node
  
  for (k in 2:K) {
    node_k <- readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds"))
    m <- (-1+sqrt(1+8*length(node_k)))/2
    if (n != m) {
      stop("Nodes files do not seem to contain the same number of individuals.")
    }
    
    # Gram local
    Gram_k <- reconstruct_from_upper_tri(node_k, n)
    rank_k[k] <- rank_psd_chol(Gram_k)
    # Adding to substitute matrix, using pivoted cholesky decomposition
    if(k==2){
      if(p_response_node>0){
        X_tilde <- cbind(X_tilde,gram_factor_pivoted_cholesky(Gram_k,rank_k[k]))}else{
          X_tilde <- gram_factor_pivoted_cholesky(Gram_k,rank_k[k])
        }}else{
          X_tilde <- cbind(X_tilde,gram_factor_pivoted_cholesky(Gram_k,rank_k[k]))
        }
  }
  rm(Gram_k)
  p <- sum(rank_k)
  
  #Conducting 10-folds cross-validation to find optimal penalty lambda if not specified
  if(lambda==-1){
    ###Lambda sequence (could be varied)
    lambda_seq <- seq(from = 0.0005 * 0.2, to = 0.2, length.out = 100)
    ###CV
    cvfit_Xtilde <- with_seed(123,cv.glmnet(X_tilde, y, family=binomial(link = family_glm), alpha = 0, lambda=lambda_seq, standardize = FALSE,thresh = 1e-25,maxit = 1e6))
    lambda <- cvfit_Xtilde$lambda.min
  }
  
  if(lambda<=0){
    stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
  }
  
  
  ####Fit model with optimal lambda value (or predetermined lambda value)
  glmnet_model_Xtilde <- glmnet(X_tilde, y, family=binomial(link = family_glm), alpha=0,lambda=lambda, standardize = FALSE,thresh = 1e-25,maxit = 1e6)

  # Intercept value at response-node
  beta0_hat <- coef(glmnet_model_Xtilde)[1,1]
  
  # Compute parameters if any co-located at the response-node
  if(p_response_node>0){
    beta_node_1 <- coef(glmnet_model_Xtilde)[2:(p_response_node+1),1]
    beta_node_1_adjusted <- c(beta_node_1/sapply(as.data.frame(node_1_complete[,-1]), sd))
    covariate_names_response <- colnames(node_1_complete)[-1]}else{
      covariate_names_response <- "Intercept"
      beta_node_1_adjusted <- "None"
      beta_node_1 <- "None"
    }
  
  ### Export results data-node 1
  write.csv(data.frame(model_choice=family_glm,lambda_model=lambda,beta0_scaled=beta0_hat, coefs_scaled=beta_node_1, coefs_originalscale=beta_node_1_adjusted),
            file=paste0(examplefilepath, "Data_node_1_results.csv"), row.names=covariate_names_response)
  
  
  # Export quantities for predictor-nodes
  for (k in 2:K) {
    gram_k <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds")), n)
    p_prev <- sum(rank_k[1:k-1])
    c_system_k <- as.vector(X_tilde[,(p_prev+1):(p_prev+rank_k[k])]%*%coef(glmnet_model_Xtilde)[(p_prev+2):(p_prev+rank_k[k]+1),1])
    write.csv(data.frame(c_system_k),
              file=paste0(examplefilepath, "Coord_node_primerA_for_data_node_",k ,".csv"), row.names=FALSE)
  }
  
  ### Export XBeta
  eta <- beta0_hat+X_tilde%*%coef(glmnet_model_Xtilde)[-1,1]
  saveRDS(eta,file=paste0(examplefilepath, "privacy_output.rds"))
  
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
