############### POOLED COX MODEL ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Includes
library("survival")

robust_flag <- T # Sets if we should estimate a robust variance or not
nbBetas <- 6 # Input the number of betas
K <- 3 # Imput the number of nodes

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

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

### Code starts here

# Read data and weights
data = data.frame()
weights_pooled = data.frame()
for(k in 1:K){
  # Data
  if(!file.exists(paste0("Data_node_grouped_", k ,".csv"))){
    warning("Attempt to find a file with grouped data failed and thus this will use ungrouped data. Be aware that this algorithm is based on WebDisco which is deemed non-confidential for ungrouped data.")
    node_data <- read.csv(paste0("Data_node_", k, ".csv"))
  } else {
    node_data <- read.csv(paste0("Data_node_grouped_", k, ".csv"))
  }
  # Weights, if provided
  if(file.exists(paste0("Weights_node_", k, ".csv"))){
    node_weights <- read.csv(paste0("Weights_node_", k, ".csv"))
  } else{
    node_weights <- as.data.frame(rep(1, nrow(node_data)))
  }
  
  data <- rbind(data, node_data)
  weights_pooled <- rbind(weights_pooled, node_weights)
}

# Remove missing values, if any
data_and_weights <- cbind(data, weights_pooled[,1])
data_and_weights <- data_and_weights[complete.cases(data_and_weights),]
data <- data_and_weights[, -(ncol(data_and_weights))]
weights_pooled <- data_and_weights[, ncol(data_and_weights)]

# Cox model estimated
column_indices <- (3:(nbBetas + 2))
formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("data[,", column_indices, "]"), collapse = " + ")))
res.cox <- coxph(formula, data, ties = "breslow", weights = weights_pooled, robust = robust_flag) 
summary(res.cox)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())

