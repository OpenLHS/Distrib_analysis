############### Distributed inference ####################
############### Data node code (t > 0) ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_iter_log_reg <- function(man_wd,nodeid,iterationseq,expath="",man_thresh) {

manualwd <- man_wd  
k <- nodeid
t <- iterationseq
examplefilepath <- expath
probthresh <- man_thresh

# Logistic-regression-specific functions

sigmoid <- function(x) {
  exp(x) / (1 + exp(x))
}

logreg_D <- function(beta, X, y, W) {
  n <- nrow(X)
  t(X) %*% W %*% (y - sigmoid(X %*% beta)) # / n
}

logreg_V <- function(beta, X, W) {
  n <- nrow(X)
  sig <- sigmoid(X %*% beta)[,1]
  t(X) %*% W %*% diag(sig*(1-sig)) %*% X # / n
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

node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
n <- nrow(node_data)

# Verifying if weights are available. 
source("Data_node_core_weights.R") 
weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n, IPW_Gen = TRUE)
node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]

beta_t <- read.csv(paste0(examplefilepath, "Coord_node_iter_", t, "_W_primer.csv"))[,1]

X_k <- as.matrix(cbind(1, node_data[,-1]))
y_k <- node_data[,1]
W_k <- diag(node_weights)

# Computing local gradient and hessian for current iteration --------------

D_k_t <- logreg_D(beta_t, X_k, y_k, W_k)
V_k_t <- logreg_V(beta_t, X_k, W_k)


# Exporting gradient and hessian ------------------------------------------

output <- cbind(D_k_t, V_k_t)
colnames(output)[1] <- "gradient"
colnames(output)[2] <- "hessian_intercept"
colnames(output)[-c(1,2)] <- paste("hessian", colnames(output)[-c(1,2)], sep = "_")
write.csv(output,
          file=paste0(examplefilepath, "Data_node_", k, "_iter_", t, "_W_output.csv"), row.names=FALSE)

# Computing & exporting weight predictions --------------------------------

node_propensity <- sigmoid(X_k %*% beta_t)

# If needed, apply threshold on probabilities smaller/bigger than preset threshold 
node_propensity[node_propensity<probthresh] = probthresh
node_propensity[node_propensity>(1-probthresh)] = 1-probthresh

IPW <- node_data$Tx/node_propensity + (1-node_data$Tx)/(1-node_propensity)

Weights_output <- as.data.frame(cbind(IPW, node_propensity))
colnames(Weights_output)[1] <- "IPW"
colnames(Weights_output)[2] <- "Propensity_score"

write.csv(Weights_output,
          file=paste0(examplefilepath, "IPW_node_", k, "_iter_", t, ".csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)

}
