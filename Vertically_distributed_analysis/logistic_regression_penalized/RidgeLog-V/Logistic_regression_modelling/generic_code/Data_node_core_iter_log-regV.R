############### Distributed inference ####################
############### Covariate-node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_iter_log_reg <- function(man_wd,nodeid,expath) {

manualwd <- man_wd  
k <- nodeid
examplefilepath <- expath

# Read and scale data
node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
node_data <- scale(as.matrix(node_data))
n <- nrow(node_data)

# Read outcome data
y <- as.matrix(read.csv(paste0(examplefilepath, "outcome_data.csv")))

# Read coordination node outputs
outputs <- read.csv(paste0(examplefilepath, "Coord_node_results_distributed_log_regV.csv"))
alpha_hat <- outputs[,1]
beta0_hat <- outputs[1,2]
lambda <- outputs[1,3]

# Compute local beta_hat
local_betahat <- 1/(lambda*n) * t(node_data) %*% diag(alpha_hat) %*% y

# Format output
output <- cbind(colnames(node_data), local_betahat)
colnames(output) <- c("Variable", "betak_hat")

# Export results
write.csv(x=output, file=paste0(examplefilepath, "Data_node_", k, "_results.csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)

}
