###############  Distributed predictive analytics ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# No modifications should be required below this point
###########################

vert_logistic_regression_example_pooled_handler <- function(man_wd=-1, man_nnodes=-1,man_lambda=-1, expath=""){
  
  manualwd <- man_wd
  lambda <- man_lambda
  K <- man_nnodes
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
  
  # Read data and weights
  library(glmnet)
  
  for(k in 1:K){
    # Data
    node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
    
    if(k==1){
      pooled_data <- node_data
    } else{
      pooled_data <- cbind(pooled_data, node_data)  
    }
    
  }
  
  y <- pooled_data[,1]
  pred <-  pooled_data[,-1]
  n <- length(y)
  
  # Pooled model
  if(lambda==-1){
    #cross-validation parameters
    #Setting parameters lambda (penalty)
    lambda_seq <-  seq(from = 0.005, to = 0.2, by = 0.002)
    nfolds <- 10
    set.seed(123)
    foldid <- sample(rep(1:nfolds, length.out = n))
    foldid <- as.vector(unlist(tapply(1:length(y), y, function(idx) sample(rep(1:nfolds, length.out = length(idx))))))
    
    #Run glmnet cv
    cvfit <- cv.glmnet(as.matrix(pred), y, family=binomial, alpha = 0, lambda=lambda_seq, foldid = foldid)
    lambda <- cvfit$lambda.min
  }
  
  model_pooled <- glmnet(as.matrix(pred), y, family=binomial,alpha=0,lambda=lambda)
  
  # Printing pooled models
  print(coef(model_pooled)[,1])
  
}

