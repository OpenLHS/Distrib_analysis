############### Distributed inference ####################
############### Coordinating node code (t > 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Iteration t > 1 ---------------------------------------------------------

# THIS LINE COMMENTED FOR DEMO
# t <- 2

# Last iteration ----------------------------------------------------------

# THIS LINE COMMENTED FOR DEMO
# last <- FALSE

# Importing data and aggregating gradients and hessians -------------------

beta_old <- read.csv(paste0("CoordNode_iter", t-1, "_output.csv"))[,1]

K <- length(list.files(pattern=paste0("Node[[:digit:]]+_iter", t-1, "_output.csv")))
p <- 0
for (k in 1:K) {
  node_k <- read.csv(paste0("Node", k, "_iter", t-1, "_output.csv"))
  q <- nrow(node_k)
  if (p == 0) {
    p <- q
    D_t <- rep(0, p)
    V_t <- matrix(0, p, p)
  }
  else if (p != q) 
    stop("Nodes files do not seem to contain the same number of predictors.")
  D_t <- D_t + node_k[,1]
  V_t <- V_t + as.matrix(node_k[,-1])
}

# Newton-Raphson update ---------------------------------------------------

beta_new <- beta_old + solve(V_t, D_t)

# Exporting updated estimator  --------------------------------------------

if (!last) {
  write.csv(beta_new,
          file=paste0("CoordNode_iter", t, "_output.csv"), row.names=FALSE)
}
  
# Exporting estimated variances for last iteration ------------------------

if (last) {
  write.csv(beta_new,
            file="CoordNode_final_estimator.csv", row.names=FALSE)
  n <- read.csv("CoordNode_sample_size.csv")[,1]
  Sigma <- n * solve(V_t)
  write.csv(Sigma, file="CoordNode_final_covariance.csv", row.names=FALSE)
}

