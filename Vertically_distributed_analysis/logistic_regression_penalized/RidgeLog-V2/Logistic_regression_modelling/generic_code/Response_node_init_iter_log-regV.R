###############  Distributed predictive analytics ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


coord_log_reg <- function(man_wd=-1, man_lambda, expath = "", privacy_switch, man_seed) {
  
  manualseed <- man_seed
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
  library(CVXR)
  
  
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
  
  # Scale covariates
  n <- nrow(node_1_complete)
  
  if(p_response_node>0){
  cov_node_1 <- scale(node_1_complete[,-1])
  
  ### Initialize Gram matrix from response-node
  K_all <- cov_node_1%*%t(cov_node_1)}else{
    K_all <- matrix(0, nrow = n, ncol = n)
  }
  
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
  
    
    ###Cross-validation (parameters could be varied)
    
    ###Setting parameters lambda (penalty) - Default at nfolds=10 and lambda_seq=seq(from = 0.005, to = 0.1, by = 0.002)
    #Lambda sequence tested
    lambda_seq <-  seq(from = 0.005, to = 0.1, by = 0.002)
    #Number of folds
    nfolds <- 10
    chunk_size <- ceiling(n / nfolds)
    #Associate observation to a fold id
    set.seed(123)
    foldid <- sample(rep(1:nfolds, length.out = n))
    foldid <- unlist(tapply(1:length(y), y, function(idx) sample(rep(1:nfolds, length.out = length(idx)))))
    
    #Cross-validation function
    CV_iteration <- function(lambda){
      
      error_each_chunk <- rep(NA,nfolds)
      
      ###For each fold: Fit model without the current fold observations (reduced sample)
      for (i in 1:nfolds) {
        fold <- i
        Global_Gram_red  <- K_all[foldid != fold,foldid != fold]
        y_red <- y[foldid != fold]
        n_ad <- n-length(which(foldid==fold))
        
        # State the optimization problem
        alpha <- Variable(n_ad)
        Q <- (1/(2*lambda*n_ad)) * (t(y_red*(Global_Gram_red)))*y_red
        
        objective <- Minimize(
          quad_form(alpha, Q) 
          - sum(entr(1-alpha) + entr(alpha))
        )
        
        constraint1 <- alpha >= 0
        constraint2 <- alpha <= 1
        constraint3 <- sum(y_red*alpha) == 0
        
        problem <- Problem(objective, constraints=list(constraint1, constraint2, constraint3))
        
        
        # Solve the optimization problem
        solution <- solve(problem, solver ="ECOS")
        if(solution$status=="solver_error"){
          solution <- solve(problem, solver = "SCS",
                            eps = 1e-6, max_iters = 20000, alpha = 1.5, normalize = TRUE, scale = 1.0)
        }
        alpha_hat <- solution$getValue(alpha)[,1]
        
        # Compute deviance among the current fold observations
        beta0_hat <- 1/y_red[1] * (log(1/alpha_hat[1] - 1) - y_red[1] * 1/(lambda*n_ad) * (Global_Gram_red %*% diag(alpha_hat) %*% y_red)[1])
        
        error_each_chunk[i] <- (2/(n-n_ad))*sum(log(1+exp(-y[foldid == fold]*((((1/(n_ad*lambda)))*(K_all[foldid == fold,foldid != fold])%*%diag(alpha_hat)%*%y_red) 
                                                                              +beta0_hat))))
        gc()
      }
      
      # Return mean deviance
      return(mean(error_each_chunk)) 
    }
    
    # Conduct cross-validation for the sequence of lambda
    deviance_seqlambda <- sapply(lambda_seq,CV_iteration)
    
    
    ###Optimal Lambda value
    lambda <- lambda_seq[which.min(deviance_seqlambda)]
  }
  
  if(lambda<=0){
    stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
  }
  
  
  ####Fit model with optimal lambda value (or predetermined lambda value)
  
  # State the optimization problem
  alpha <- Variable(n)
  Q <- (1/(2*lambda*n)) * (t(y*(K_all)))*y
  
  objective <- Minimize(
    quad_form(alpha, Q) 
    - sum(entr(1-alpha) + entr(alpha))
  )
  
  constraint1 <- alpha >= 0
  constraint2 <- alpha <= 1
  constraint3 <- sum(y * alpha) == 0
  
  problem <- Problem(objective, constraints=list(constraint1, constraint2, constraint3))
  
  # Solve the optimization problem
  solution <- solve(problem)
  if(solution$status=="solver_error"){
    solution <- solve(problem, solver = "SCS",
                      eps = 1e-6, max_iters = 20000, alpha = 1.5, normalize = TRUE, scale = 1.0)
  }
  alpha_hat <- solution$getValue(alpha)[,1]
  
  
  # Compute beta0_hat at response-node
  beta0_hat <- 1/y[1] * (log(1/alpha_hat[1] - 1) - y[1] * 1/(lambda*n) * (K_all %*% diag(alpha_hat) %*% y)[1])
  
  # Compute parameters if any co-located at the response-node
  if(p_response_node>0){
    beta_node_1 <- (1/(lambda*n))*arma_mm(t(cov_node_1),(alpha_hat*y))
    beta_node_1_adjusted <- c(beta_node_1/sapply(as.data.frame(node_1_complete[,-1]), sd))
    covariate_names_response <- colnames(node_1_complete)[-1]}else{
    covariate_names_response <- "Intercept"
    beta_node_1_adjusted <- "None"
    beta_node_1 <- "None"
    }
  
  ### Export results data-node 1
  write.csv(data.frame(beta0_scaled=beta0_hat, coefs_scaled=beta_node_1, coefs_originalscale=beta_node_1_adjusted),
            file=paste0(examplefilepath, "Data_node_1_results.csv"), row.names=covariate_names_response)
  
  
  # Export quantities for predictor-nodes and conduct privacy check
  
  if(privacy_switch==1){
    source("Response_node_optional_confidentiality.R")
  }
  
  for (k in 2:K) {
    gram_k <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath, "Data_node_", k, "_init_output.rds")), n)
    c_system_k <- (1/(n*lambda))*arma_mm(gram_k,(alpha_hat*y))
    write.csv(data.frame(c_system_k),
              file=paste0(examplefilepath, "Coord_node_primerA_for_data_node_",k ,".csv"), row.names=FALSE)
    
    # If Privacy-check switch is on for response-node data, run privacy check
    if(privacy_switch==1){
      print(paste0("Privacy check with data from covariate node ", k, "."))
      flippable_ys_nodek <- privacy_check_ck2_complete(nullspace_sym_pd(gram_k, tol = 1e-8),alpha_hat,y,n,k,examplefilepath,manualseed)
    }  
  }
  
  
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
