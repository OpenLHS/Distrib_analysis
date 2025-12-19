############### Distributed inference ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# No modifications should be required below this point
###########################

# Loading packages and setting up core variables --------------------------
library(glmnet)

vert_logistic_regression_nonpenalized_example_pooled_handler <- function(man_wd=-1, man_nnodes=-1, man_lambda=-1, expath=""){
 
  manualwd <- man_wd
  K <- man_nnodes
  examplefilepath <- expath
  lambda <- man_lambda
  
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
    stop("Cannot run a pooled analysis when the number of node K is less than 1.")
  }
  
  ### Code starts here
  
  # Read and scale data
  for(k in 1:K){
    # Data
    node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
    
    if(k==1){
      pooled_data <- node_data
    } else{
      pooled_data <- cbind(pooled_data, node_data)  
    }
    
  }
  pooled_data <- scale(pooled_data)
  
  # Read outcome
  y <- read.csv(paste0(examplefilepath, "outcome_data.csv"))[,1]
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
  
}


