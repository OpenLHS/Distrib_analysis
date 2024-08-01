############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Variables that might need to be adjusted

## Number of predictors (excluding intercept)
p <- 4
beta <- round(rnorm(p+1, mean=0, sd=2))

# Node sample sizes
n <- c(50, 100, 60)

## Seed intialisation, unlikely to need to be changed.
seedstart <- 1

# DO NOT MODIFY BELOW UNLESS YOU KNOW WHAT YOU ARE DOING ;-)

# Fixing randomness -------------------------------------------------------
set.seed(seedstart)

# Function to generate distribution -----------------------------
sigmoid <- function(x) {
  exp(x) / (1 + exp(x))
}

# Number of nodes (derived from the sample sizes array above)
K <- length(n)

# Setting current working directory to source file location ---------------

path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

# Generating node datasets according to true LR model
for (k in 1:K) {
  n_k <- n[k]
  X_k <- cbind(rep(1, n_k), matrix(rnorm(p*n_k), nrow=n_k))
  y_k <- rbinom(n_k, 1, prob=sigmoid(X_k %*% beta))
  data_k <- data.frame(y_k, X_k[,2:(p+1)])
  colnames(data_k) <- c("out1", paste0("pred", 1:p))
  write.csv(data_k, file=paste0("Node", k, "_data.csv"), row.names=FALSE)
}