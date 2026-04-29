############### VERTICALLY DISTRIBUTED RIDGE-PENALIZED BINARY REGRESSION ####################
############### Response-node code - Privacy check ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Privacy check for response data -----------------------


privacy_check_ck2_complete <- function(man_wd=-1,k,expath = "",man_seed){
  
  
  # Libraries and rcpp functions needed for the procedure -----------------------
  
  library(ROI)
  library(ROI.plugin.glpk)
  library(ROI.plugin.symphony)
  library(ROI.plugin.nloptr)
  library(Rcpp)
  library(RcppArmadillo)
  library(RcppEigen)
  
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
  
  
  # Privacy check for response data - Main function -----------------------
  
  privacy_check_ck2 <- function(V,alpha_new,n,i0){
    
    # Compute which entries of y are flippable
    # V: Matrix in null-space of gram matrix of node k
    # alpha_new: optimal w_i from the optimization procedure
    
    gc()
    
    # Step: Try to flip each coordinate's sign 
    feasible_flip <- logical(n)
    
    # initial solution to the system c_k 
    x0 <- alpha_new
    i <- i0
    
    #if (abs(x0[i]) < 1e-8 | feasible_flip[i] == TRUE ) {
    #  feasible_flip[i] <- TRUE  # zero: already sign-flippable
    #  next
    #}
    
    direction <- if (x0[i] > 0) "<=" else ">="
    
    # Inequality: sign flip
    dir_flip <- direction
    rhs_flip <- if (x0[i] > 0) -x0[i] - 1e-3  else -x0[i] + 1e-3 # small margin to strictly cross zero
    
    # Box constraints: x0 + V b in (-1,1)^n
    dir_box <- rep("<=", 2 * n)
    rhs_box <- c(1 - x0-1e-4, 1-1e-4 + x0)
    
    # Equality constraint added for intercept not penalized
    grad_vec <- as.numeric(colSums(V))
    rhs_equality <- -sum(x0)
    
    # Combine constraints and solve
    
    L <- OP(objective = rep(0,ncol(V)), 
            constraints = L_constraint(L = rbind(V, -V, matrix(V[i, ], nrow = 1),grad_vec),
                                       dir = c(dir_box, dir_flip,"=="), rhs = c(rhs_box, rhs_flip, rhs_equality)))
    
    
    res2 <- ROI_solve(L, solver = "glpk")
    
    gc()
    
    if(res2$status$code == 0){
      sol <- x0 + V%*% solution(res2)
      return(sol)
    }else{return(NULL)}
  }
  
  
  # SET UP -----------------------
  
  manualwd <- man_wd
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
  
  
  # Privacy check for response data - Procedure and computations -----------------------
  
  print(paste0("Privacy check with data from predictor-node ", k, "."))
  
  ###Prepare required data for privacy check
  eta <- readRDS(paste0(examplefilepath,"privacy_output.rds"))
  n <- length(eta)
  y <- as.vector(as.matrix(read.csv(paste0(examplefilepath, "Data_node_1.csv")))[,1])
  V <- nullspace_sym_pd(reconstruct_from_upper_tri(readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds")), n), tol = 1e-8)
  alpha_new <- rep(NA,n)
  
  #Ratios for the logistic regression
  alpha_new[which(y==1)] <- 1/(1+exp(eta[which(y==1)]))
  alpha_new[which(y==0)] <- -1/(1+exp(-eta[which(y==0)]))
  gc()
  y <- sign(alpha_new)
  alpha_tilde <- abs(alpha_new)
  
  #If a seed is provided by the user, use it. 
  if(man_seed!=-1){
    set.seed(man_seed)
  }
  
  #Initialize index and count number of flips
  count <- 0
  nbsol <- 0
  index_nosol <- numeric(0)
  index <- 1:n
  i0 <- index[which.max(alpha_tilde[index])]
  
  # Set number of columns used for partial nullspace
  n_col_sampled <- 1000
  
  # Create progress bar so user know the method isn't stuck
  progressbar <- txtProgressBar(min=0, max = n, style = 3)
  
  # Run over all line-level values in Y
  if(ncol(V)>n_col_sampled){
    while(length(index)!=0){
      d_sol <- NULL
      col_sampled <- sample(x = 1:ncol(V), size = n_col_sampled, replace = FALSE)
      #V_used <- V[,col_sampled]
      #begtime <- Sys.time()
      d_sol <- privacy_check_ck2(V[,col_sampled],alpha_new,n,i0)
      gc()
      #Sys.time()-begtime
      #rm(V_used)
      if (!is.null(d_sol)) {
        count <- count+sum(sign(y[index])!=sign(d_sol[index])) 
        if(length(index_nosol)!=0){
          count <- count+sum(sign(y[index_nosol])!=sign(d_sol[index_nosol])) 
          index_nosol <- index_nosol[which(sign(y[index_nosol])==sign(d_sol[index_nosol]))]
        }
        index <- index [!index %in% c(i0)]
        index <- index[which((sign(y[index])==sign(d_sol[index])))]
        nbsol <- nbsol + 1
      }else{
        index_nosol <- c(index_nosol,i0) 
        index <- index [!index %in% c(i0)] 
      }
      if(length(index)!=0){
        i0 <- index[which.max(alpha_tilde[index])] 
      }
      # Update progress bar
      setTxtProgressBar(progressbar, n-length(index)) 
    }
    
    # If index_nosol is un-empty, try again
    if(length(index_nosol)!=0){
      print("Entering 2nd search stage")
      print(length(index_nosol))
      
      # Reset parameters for 2nd search
      index_after_nosol <- numeric(0)
      index_after <- index_nosol
      i0 <- index_after[which.max(alpha_tilde[index_after])]
      
      # New parameters for 2nd search
      retries_per_i0 <- 1000
      n_col_sampled <- n_col_sampled*1.6
      
      current_retry <- 1
      
      while(length(index_after)!=0){
        d_sol <- NULL
        col_sampled <- sample(x = 1:ncol(V), size = n_col_sampled, replace = FALSE)
        V_used <- V[,col_sampled]
        gc()
        d_sol <- privacy_check_ck2(V_used,alpha_new,n,i0)
        rm(V_used)
        if (!is.null(d_sol)) { 
          count <- count+sum(sign(y[index_after])!=sign(d_sol[index_after])) 
          if(length(index_after_nosol)!=0){ 
            count <- count+sum(sign(y[index_after_nosol])!=sign(d_sol[index_after_nosol])) 
            index_after_nosol <- index_after_nosol[which(sign(y[index_after_nosol])==sign(d_sol[index_after_nosol]))]
          }
          index_after <- index_after [!index_after %in% c(i0)]
          index_after <- index_after[which((sign(y[index_after])==sign(d_sol[index_after])))] 
          nbsol <- nbsol + 1
          
          if(length(index_after)!=0){ 
            i0 <- index_after[which.max(alpha_tilde[index_after])] 
            current_retry <- 1 
          }
          
        }else{
          if(current_retry==retries_per_i0){ 
            index_after_nosol <- c(index_after_nosol,i0) 
            index_after <- index_after [!index_after %in% c(i0)] 
            
            if(length(index_after)!=0){ 
              i0 <- index_after[which.max(alpha_tilde[index_after])] 
              current_retry <- 1
            }
            
            # Reset counter
            current_retry <- 1
            
          } else{ # no solution found for our current try. Let's try again!
            current_retry <- current_retry + 1
          }
          
        }
        
      }
    }
    
  }else{
    while(length(index)!=0){
      d_sol <- privacy_check_ck2(V,alpha_new,n,i0)
      if (!is.null(d_sol)) {
        count <- count+sum(sign(y[index])!=sign(d_sol[index]))
        if(length(index_nosol)!=0){
          count <- count+sum(sign(y[index_nosol])!=sign(d_sol[index_nosol]))
          index_nosol <- index_nosol[which(sign(y[index_nosol])==sign(d_sol[index_nosol]))]
        }
        index <- index [!index %in% c(i0)]
        index <- index[which((sign(y[index])==sign(d_sol[index])))]
        nbsol <- nbsol + 1
      }else{
        index_nosol <- c(index_nosol,i0)
        index <- index [!index %in% c(i0)]
      }
      if(length(index)!=0){
        i0 <- index[which.max(alpha_tilde[index])]  
      }
      # Update progress bar
      setTxtProgressBar(progressbar, n-length(index)) 
    }
  }
  
  # close progress bar
  close(progressbar) 
  
  #
  
  # Print results of flips vs no flips
  cat(sprintf(paste0("Flippable coordinate signs with covariate-node ", k,"'s data: %d / %d\n"), count, n))
  cat(sprintf("Number of distinct candidates: %d\n", nbsol))
  
  if(count!=n){
    write.csv(data.frame(index_noflip=index_nosol),
              file=paste0(examplefilepath,"Index_NoFlip_",k ,".csv"), row.names=FALSE)
  }
  return(NULL)
}

