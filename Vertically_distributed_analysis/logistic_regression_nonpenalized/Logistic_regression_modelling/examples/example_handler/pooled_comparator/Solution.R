############### Distributed inference ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

K <- -1 # Input the number of nodes

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# No modifications should be required below this point
###########################

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

# Once the working directory as been set, save it so we can pass it to other files
path <- paste0(getwd(), "/")

if(K<1){
  stop("The number of nodes K cannot be smaller than 1.")
}

### Code starts here

# Read data and weights
for(k in 1:K){
  # Data
  node_data <- read.csv(paste0(path, "Data_node_", k, ".csv"))
  
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

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

