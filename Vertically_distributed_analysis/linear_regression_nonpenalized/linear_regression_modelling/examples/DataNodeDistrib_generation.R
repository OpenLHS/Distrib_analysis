############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Seed intialisation, unlikely to need to be changed.
set.seed(1)

# Setting current working directory to source file location 
path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

# Sample size
n <- 25

# Number of covariates per covariate-node
p <- c(1,2,3)

#-------------------------------------------------------------------------------
# DO NOT MODIFY BELOW UNLESS YOU KNOW WHAT YOU ARE DOING ;-)
#-------------------------------------------------------------------------------

# Parameter to control variance
sigma <- 1

# Number of predictors (excluding intercept)
beta <- round(rnorm(sum(p)+1, mean=0, sd=2))

# Number of nodes (derived from the predictor length array above)
K <- length(p)

# Generating node datasets according to true LR model
X <- cbind(rep(1, n), matrix(rnorm(sum(p)*n), nrow=n))
y <- rnorm(n, mean = X %*% beta, sd = sigma)
data <- data.frame(y, X[,2:(sum(p)+1)])
colnames(data) <- c("out1", paste0("pred", 1:sum(p)))
data_X <- data[,-1]

for(k in 1:K){
  
  if(k==1){ # Response-node
    c_start <- 1
    c_end <- p[k]+1
    data_k <- as.data.frame(data[,c_start:c_end])
    if(p[k]==0){
      colnames(data_k) <- c("out1")
    }
  }else{ # Covariate-node
    c_start <- sum(p[1:(k-1)])+1
    c_end <- sum(p[1:k])
    data_k <- data_X[,c_start:c_end] 
  }
  
  write.csv(data_k, file=paste0("simulated_data_same_folder/distributed/Data_node_", k, ".csv"), row.names=FALSE)
  write.csv(data_k, file=paste0("simulated_data_same_folder/pooled/Data_node_", k, ".csv"), row.names=FALSE)  
}

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())