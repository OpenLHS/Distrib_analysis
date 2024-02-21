############### Distributed inference ####################
############### Data node code (t > 0) ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Iteration t -------------------------------------------------------------

# THIS LINE COMMENTED FOR DEMO
# Change the value of t accordingly
# t <- 1

# Loading packages and setting up core variables and functions  -----------

# Load package this.path to identify the script filename and deduce node number.
# https://cran.r-project.org/package=this.path 
# https://cran.r-project.org/web/packages/this.path/this.path.pdf
library("this.path")

# Set data node number based on the filename. 
# This assumes a file with name like Node[[:digit:]]+_code_lin-reg.R

filename <- basename2(this.path())
fu <- min(unlist(gregexpr("_", filename)))
k <- strtoi(substring(filename, 5, fu-1))

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

# Setting current working directory to source file location
path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

node_data <- read.csv(paste0("Node", k, "_data.csv"))

beta_t <- read.csv(paste0("CoordNode_iter", t, "_output.csv"))[,1]

X_k <- as.matrix(cbind(1, node_data[,-1]))
y_k <- node_data[,1]


# Computing local gradient and hessian for current iteration --------------

D_k_t <- logreg_D(beta_t, X_k, y_k)
V_k_t <- logreg_V(beta_t, X_k)


# Exporting gradient and hessian ------------------------------------------

write.csv(cbind(D_k_t, V_k_t),
          file=paste0("Node", k, "_iter", t, "_output.csv"), row.names=FALSE)
