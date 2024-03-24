############### Distributed inference ####################
############### Data node code (t > 0) ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_iter_log_reg <- function(nodeid, iterationseq) {

k <- nodeid
t <- iterationseq

# Logistic-regression-specific functions

sigmoid <- function(x) {
  exp(x) / (1 + exp(x))
}

logreg_D <- function(beta, X, y) {
  n <- nrow(X)
  t(X) %*% (y - sigmoid(X %*% beta)) # / n
}

logreg_V <- function(beta, X) {
  n <- nrow(X)
  sig <- sigmoid(X %*% beta)[,1]
  W <- diag(sig * (1-sig))
  t(X) %*% W %*% X # / n
}

# Importing data ----------------------------------------------------------

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

node_data <- read.csv(paste0("Data_node_", k, ".csv"))

beta_t <- read.csv(paste0("Coord_node_iter_", t, "_primer.csv"))[,1]

X_k <- as.matrix(cbind(1, node_data[,-1]))
y_k <- node_data[,1]


# Computing local gradient and hessian for current iteration --------------

D_k_t <- logreg_D(beta_t, X_k, y_k)
V_k_t <- logreg_V(beta_t, X_k)


# Exporting gradient and hessian ------------------------------------------

write.csv(cbind(D_k_t, V_k_t),
          file=paste0("Data_node_", k, "_iter_", t, "_output.csv"), row.names=FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)

}
