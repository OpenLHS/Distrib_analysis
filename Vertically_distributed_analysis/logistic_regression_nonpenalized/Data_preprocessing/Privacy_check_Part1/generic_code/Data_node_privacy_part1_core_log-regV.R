############### Distributed inference ####################
############### Covariate-node code - Privacy assessment - Part 1 ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


###############################################
# LOAD LIBRARIES AND DATA
###############################################

data_privacy_log_reg <- function(man_wd,nodeid,expath) {
  
  manualwd <- man_wd  
  k <- nodeid
  examplefilepath <- expath
  
  library(nleqslv)
  
  ###############################################
  # Useful functions
  ###############################################
  
  # Function to generate a Givens rotation matrix
  givens_matrix <- function(p, i, j, theta) {
    # Create an identity matrix of size p x p
    G <- diag(1, p)
    
    # Fill in the rotation entries
    G[i,i] <- cos(theta)
    G[j,j] <- cos(theta)
    G[i,j] <- -sin(theta)
    G[j,i] <- sin(theta)
    
    return(G)
  }
  givens_basis <- function(p,theta){
    A <- diag(1, p)
    counter <- 1
    for(i in 1:(p-1)){
      for(j in ( (i+1):p)){
        A <- A %*% givens_matrix(p,i,j,theta[counter])
        counter <- counter + 1
      }
    }
    return(A)
  }
  p_jSigma_minusI_pj <- function(pj,Sigma,p)
  {
    return(t(pj)%*% (Sigma -diag(1, p) ) %*% pj )
  }
  
  
  # Importing data ----------------------------------------------------------
  
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
  
  
  #Import covariate-node data and intermediary quantities from response-node
  node_data_k_unscale <- (as.matrix(read.csv(paste0(examplefilepath, "Data_node_",k, ".csv"))))
  node_data_k <- scale(node_data_k_unscale)
  
  
  
  
  
  #############################################################
  # Define the system of equations & solve, given covariances
  #############################################################
  
  
  solve_theta12 <- function(Sigma, 
                            start = rep(0, ncol(Sigma)-1), 
                            theta_fix = rep(pi/4, ncol(Sigma)*(ncol(Sigma)-1)/2-(ncol(Sigma)-1)), max_attempts = 50000) {
    # This function fixes all but the first ncol(Sigma)-1 theta's, 
    # and finds the first ncol(Sigma)-1 thetas that make the column variances of XP equal to 1.
    # Sigma: correlation matrix.

    
    p_k <- ncol(Sigma)
    
    system_eqs <- function(theta) {
      # Project theta back to [0, 2pi)
      theta <- theta %% (2*pi)
      theta_complete <- c(theta, theta_fix)
      P_Givens <- givens_basis(p_k, theta_complete)
      eq <- apply(P_Givens[, -p_k], 2, p_jSigma_minusI_pj, Sigma, p_k)
    }
    
    attempt <- 1
    success <- FALSE
    current_start <- start
    
    while (attempt <= max_attempts && !success) {
      result <- nleqslv(current_start, system_eqs, method = "Broyden")
      
      if (result$termcd == 1) {
        success <- TRUE
      } else {
        # New random starting point between [0, 2pi)
        current_start <- runif(length(start), min = 0, max = 2*pi)
        attempt <- attempt + 1
      }
    }
    
    if (success) {
      theta_sol <- result$x %% (2*pi)
      return(list(theta_sol = theta_sol, attempts = attempt))
    } else {
      return(NA)  # No solution found after max_attempts
    }
  }
  
  
  
  
  #############################################################
  # verify solution for given dataset
  #############################################################
  
  n <- nrow(node_data_k) 
  p <- ncol(node_data_k)   
  Xcs <- node_data_k  #scaled data at node k
  Sigma <- t(Xcs) %*% Xcs /(n-1)
  
  
  #Solve
  solution <- solve_theta12(Sigma)
  print(solution$attempts)
  theta_fix = rep(pi/4, ncol(Sigma)*(ncol(Sigma)-1)/2-(ncol(Sigma)-1))
  theta <- c(unlist(solution$theta_sol),theta_fix)
  print(theta)
  P <- givens_basis(p,theta)
  A <- Xcs %*% P
  
  
  #### Are the constraints met?
  print(max(abs(diag(t(A) %*% A /(n-1))-rep(1,p)))<10^(-6))
  print(max(abs((A) %*% t(A) - Xcs %*% t(Xcs)))<10^(-6))
  
  return(TRUE)
  
}
