############### Distributed inference ####################
############### Coordinating node code (t > 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_add_iter_log_reg <- function(iterationseq) {

# Can be adjusted as needed  
alpha <- 0.05

# No modifications should be needed below this
# -------------------------------------------------------------------------

t <- iterationseq

# Importing data and aggregating gradients and hessians -------------------

beta_old <- read.csv(paste0("Coord_node_iter_", t, "_primer.csv"))[,1]

K <- length(list.files(pattern=paste0("Data_node_[[:digit:]]+_iter_", t, "_output.csv")))
p <- 0
for (k in 1:K) {
  node_k <- read.csv(paste0("Data_node_", k, "_iter_", t, "_output.csv"))
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

# Exporting updated estimator for a subsequent iteration ------------------

write.csv(data.frame(coefs=beta_new),
          file=paste0("Coord_node_iter_", t+1, "_primer.csv"), row.names=FALSE)

# Calculating current round estimates if we have at least one round completed
if (t>0) {
  Sigma <- solve(V_t)
  colnames(Sigma) <- c("(Intercept)", paste0("pred", seq(length(beta_new)-1)))
  write.csv(Sigma, file=paste0("Coord_node_iter_", t, "_covariance.csv"), row.names=FALSE)
  beta <- beta_new
  # Computing standard error ------------------------------------------------
  
  se <- qnorm(1 - 0.5*alpha) * sqrt(diag(Sigma))
  
  # Computing p-values ------------------------------------------------------
  
  p_vals <- 2*(1 - pnorm(abs(beta)/sqrt(diag(Sigma))))
  
  # Exporting final results -------------------------------------------------
  
  output <- cbind(beta, beta - se, beta + se, p_vals)
  colnames(output) <- c("Estimate", paste0("CI lower bound (alpha=", alpha, ")"),
                        paste0("CI upper bound (alpha=", alpha, ")"), "p-value")
  rownames(output) <- c("(Intercept)", paste0("pred", seq(length(beta)-1)))
  write.csv(output,file=paste0("Coord_node_iter_", t, "_results.csv"))
  
}

return(TRUE)
}
