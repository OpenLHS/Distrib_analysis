############### Distributed inference ####################
############### Covariate-node code - Privacy assessment ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


###############################################
# LOAD LIBRARIES AND DATA
###############################################

data_privacy_log_reg <- function(man_wd,nodeid,index_se) {
  
  manualwd <- man_wd  
  k <- nodeid

library(nleqslv)
library(Rcpp)
library(RcppArmadillo)

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

# Construct symmetric matrix from upper triangle
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
node_data_k_unscale <- (as.matrix(read.csv(paste0("Data_node_",k, ".csv"))))
node_data_k <- scale(node_data_k_unscale)
lambda <- as.numeric(read.csv(paste0("Coord_node_primerA_for_data_node_",k ,".csv"))[1,2])
S_inv <- reconstruct_from_upper_tri(readRDS(paste0("Coord_node_primerB_for_data_node_",k ,".rds")), nrow(node_data_k))
node_k_results <- read.csv(paste0("Data_node_",k, "_results.csv"))






#############################################################
# Define the system of equations & solve, given covariances
#############################################################


solve_theta12 <- function(Sigma,beta,Sigma_data_diag,S_inv,se_beta,index_se=NA,lambda, 
                          start = rep(0, ncol(Sigma)-1+sum(!is.na(index_se))), 
                          theta_fix = rep(pi/4, ncol(Sigma)*(ncol(Sigma)-1)/2-(ncol(Sigma)-1)-sum(!is.na(index_se))), max_attempts = 50000) {
  # This function fixes all but the first ncol(Sigma)-1+nb_se_disclosed theta's, 
  # and finds the first ncol(Sigma)-1+nb_se_disclosed thetas that make the column variances of XP equal to 1.
  # The standard errors desired to be disclosed (if any) are identified in index_se (e.g. if the standard errors of the 
  # estimates corresponding to the first and third columns would be disclosed, then index_se=c(1,3)). If none, leave at NA.
  # Sigma: correlation matrix, beta: Estimates obtained at site, Sigma_data_diag: standard deviations of initial data matrix,
  # S_inv: intermediary quantity S_inv (or equivalently S_inv+NN^t) sent from response-node for standard errors computation,
  # se_beta: Standard errors of the estimates at site
  # index_se: Index of the standard errors that would be disclosed.
  
  p_k <- ncol(Sigma)
  
  if((p_k*(p_k-1)/2-(p_k-1)-sum(!is.na(index_se)))<1){
    stop("The number of standard errors disclosed is too large for the number of covariates")
  }
  
  system_eqs <- function(theta) {
    # Project theta back to [0, 2pi)
    theta <- theta %% (2*pi)
    theta_complete <- c(theta, theta_fix)
    P_Givens <- givens_basis(p_k, theta_complete)
    eq <- apply(P_Givens[, -p_k], 2, p_jSigma_minusI_pj, Sigma, p_k)
    if(any(is.na(index_se))){
    return(eq)}else{
      eq_se <- rep(NA,length(index_se))
      for ( i in (index_se) ){
      eq_se[i] <- (1/se_beta[i])*sqrt(lambda^(-1)-lambda^(-2)*(diag((t(Xcs%*%P_Givens))%*%S_inv%*%(Xcs%*%P_Givens)))[i])-
        (1/beta[i])*colSums(t((t(P_Givens[,i]))*(Sigma_data_diag)*beta))}
      eq_se <- eq_se[!is.na(eq_se)]
      return(c(eq,eq_se))}
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
Sigma_data_diag <- sapply(as.data.frame(node_data_k_unscale), sd, na.rm = TRUE)
Xcs <- node_data_k  #scaled data at node k
Sigma <- t(Xcs) %*% Xcs /(n-1)
beta <- node_k_results[,1]# estimates at node k 
se_beta <- node_k_results[,2] #standard errors at node k


#Solve
solution <- solve_theta12(Sigma,beta,Sigma_data_diag,S_inv,se_beta,index_se,lambda)
print(solution$attempts)
theta_fix = rep(pi/4, ncol(Sigma)*(ncol(Sigma)-1)/2-(ncol(Sigma)-1)-sum(!is.na(index_se)))
theta <- c(unlist(solution$theta_sol),theta_fix)
print(theta)
P <- givens_basis(p,theta)
A <- Xcs %*% P


#### Are the constraints met?
print(max(abs(diag(t(A) %*% A /(n-1))-rep(1,p)))<10^(-6))
print(max(abs((A) %*% t(A) - Xcs %*% t(Xcs)))<10^(-6))
for ( i in (index_se) ){
  print(((1/se_beta[i])*sqrt(lambda^(-1)-lambda^(-2)*(diag((t(A))%*%S_inv%*%(A)))[i])-
          (1/beta[i])*colSums(t((t(P[,i]))*(Sigma_data_diag)*beta)))<10^(-6))}

return(TRUE)

}
