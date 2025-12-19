############### Distributed inference ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library(CVXR)

coord_log_reg <- function(man_wd=-1, man_lambda, expath = "") {

manualwd <- man_wd
lambda <- man_lambda
examplefilepath <- expath

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

# Extract response data
y <- as.vector(read.csv(file=paste0(examplefilepath, "outcome_data.csv"))[,1])
n <- length(y)

# Verify if there is any missing value in the outcome column
if(any(is.na(y))){
  stop("The dataset 'outcome_data.csv' seems to contain NA value(s). The method cannot be applied.
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
}

# Makes sure the outcome variable is properly coded as -1s and 1s.
if(!all(unique(y) %in% c(-1,1))){
  stop("The outcome variable (see file 'outcome_data.csv) contains values that are different from -1 and 1, which isn't allowed at this point. 
       The response node might need to re-run the preprocessing files.")
}

# Extract nodes' Gram matrices
K <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))
Global_Gram <- readRDS(paste0(examplefilepath, "Data_node_", 1, "_init_output.rds"))

#Setting parameter lambda (penalty) for the algorithm 
#Can be adjusted if needed, please refer to article to ensure adequate settings
if(lambda==-1){
  if(n<=10000){
    lambda <- 0.0001
  }else{lambda <- 1/n}}

if(lambda<=0){
  stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
}

for(k in 2:K){
  node_Gram <- readRDS(paste0(examplefilepath, "Data_node_", k, "_init_output.rds"))
  local_n <- nrow(node_Gram)
  if(local_n != n){
    stop("Node files do not seem to contain the same number of individuals.")
  }
  
  # Adding local Gram matrix to the global one
  Global_Gram <- Global_Gram + node_Gram
}

# State the optimization problem
alpha <- Variable(n)
Q <- 1/(2*lambda*n) * diag(y) %*% Global_Gram %*% diag(y)

objective <- Minimize(
  quad_form(alpha, Q) 
  - sum(entr(1-alpha) + entr(alpha))
)

constraint1 <- alpha >= 0
constraint2 <- alpha <= 1
constraint3 <- sum(y * alpha) == 0

problem <- Problem(objective, constraints=list(constraint1, constraint2, constraint3))

# Solve the optimization problem
solution <- solve(problem)
alpha_hat <- solution$getValue(alpha)[,1]

# Compute beta0_hat
beta0_hat <- 1/y[1] * (log(1/alpha_hat[1] - 1) - y[1] * 1/(lambda*n) * (Global_Gram %*% diag(alpha_hat) %*% y)[1])

# Combine outputs
length(beta0_hat) <- length(alpha_hat)
length(lambda) <- length(alpha_hat)
outputs <- cbind(alpha_hat, beta0_hat, lambda)

# Export results
write.csv(x=outputs, file=paste0(examplefilepath, "Coord_node_results_distributed_log_regV.csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
