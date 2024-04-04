############### Distributed inference ####################
############### Coordinating node code (t = 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_init_iter_log_reg <- function() {

# Importing data and computing initial simple averaging estimator ---------

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

# Extract node data ----------------------------------------------------------
K <- length(list.files(pattern="Data_node_[[:digit:]]+_iter_0_output.csv"))
p <- 0
for (k in 1:K) {
  node_k <- read.csv(paste0("Data_node_", k, "_iter_0_output.csv"))
  q <- nrow(node_k)
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
  beta_k <- node_k[,1]
  n_k <- node_k[1,2]
  beta_sa <- beta_sa + n_k * beta_k
  n <- n + n_k
}
# Computing the simple averaging estimator
beta_sa <- beta_sa/n

# Exporting simple averaging estimator to be sent to data nodes -----------

write.csv(data.frame(coefs=beta_sa),
          file="Coord_node_iter_1_primer.csv", row.names=FALSE)


## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
