############### Distributed inference ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

K <- -1 # Input the number of nodes

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- 1e-04

# No modifications should be required below this point
###########################

# Loading packages and setting up core variables --------------------------
library(glmnet)

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
    
    # no known means to automatically set working directory
  } else {
    stop("The required conditions to automatically set the working directory are not met. See R file")
  }
} else {
  print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
}

if(K<1){
  stop
}

### Code starts here

# Read and scale data
for(k in 1:K){
  # Data
  node_data <- read.csv(paste0("Data_node_", k, ".csv"))
  
  if(k==1){
    pooled_data <- node_data
  } else{
    pooled_data <- cbind(pooled_data, node_data)  
  }
  
}
pooled_data <- scale(pooled_data)

# Read outcome
y <- read.csv(paste0("outcome_data.csv"))[,1]
n <- length(y)

#Setting parameter lambda (penalty) for the algorithm 
#Can be adjusted if needed, please refer to article to ensure adequate settings
if(lambda==-1){
  if(n<=10000){
    lambda <- 0.0001
  }else{lambda <- 1/n}}

if(lambda<=0){
  stop("The algorithm cannot run because the penalty parameter lambda was set lower or equal to 0.")
}

# Pooled model
glmnet_model <- glmnet(pooled_data, (y+1)/2, family=binomial, lambda=lambda, alpha=0, standardize=FALSE)

# Printing pooled models
print(coef(glmnet_model)[,1])

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

