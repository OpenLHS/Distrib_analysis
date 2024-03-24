############### Distributed inference ####################
############### Coordinating node code (t = 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Load package rstudioapi : https://cran.r-project.org/package=rstudioapi 
library(rstudioapi)

# Importing data and computing initial simple averaging estimator ---------

# Setting current working directory to source file location
path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

K <- length(list.files(pattern="Node[[:digit:]]+_iter0_output.csv"))
p <- 0
for (k in 1:K) {
  node_k <- read.csv(paste0("Node", k, "_iter0_output.csv"))[,1]
  q <- length(node_k) - 1
  if (p == 0) {
    # Initializing the number of predictors p, beta_sa and total sample size n
    p <- q
    beta_sa <- rep(0, q)
    n <- 0
    }
  else if (p != q) {
    stop("Nodes files do not seem to contain the same number of predictors.")
  }
  
  # Adding local estimators and sample sizes
  beta_k <- node_k[1:q]
  n_k <- node_k[q+1]
  beta_sa <- beta_sa + n_k * beta_k
  n <- n + n_k
}
# Computing the simple averaging estimator
beta_sa <- beta_sa/n

# Exporting simple averaging estimator to be sent to data nodes -----------

write.csv(beta_sa,
          file="CoordNode_iter1_output.csv", row.names=FALSE)

# Exporting total sample size for variance estimation ---------------------

write.csv(n, file="CoordNode_sample_size.csv", row.names=FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())
