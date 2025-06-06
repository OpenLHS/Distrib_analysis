############### Distributed inference ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# No modifications should be required below this point
###########################

vert_logistic_regression_example_pooled_handler <- function(man_wd=-1, man_nnodes=-1, expath=""){
 
  manualwd <- man_wd
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
  for(k in 1:K){
    # Data
    node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
    
    if(k==1){
      pooled_data <- node_data
    } else{
      pooled_data <- cbind(pooled_data, node_data)  
    }
    
  }

  # Pooled model
  model_pooled <- glm(data=pooled_data, formula=out1~.,family="binomial")
  
  # Printing pooled models
  print(summary(model_pooled))
  
}


