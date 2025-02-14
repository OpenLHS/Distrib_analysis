############### POOLED COX MODEL ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Includes
library("survival")

# This assumes that all nodes recorded 3 predictors (covariates) in their data.
nbBetas <- 3 # Input the number of betas

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

# Modify this according to the number of data sites
# Make sure the path to the csv files are functional
# Read data
data = data.frame()
K = 3
for(k in 1:K){
  if(!file.exists(paste0("../distributed/Data_node_grouped_", k ,".csv"))){
    warning("Attempt to find a file with grouped data failed and thus this will use ungrouped data. Be aware that this algorithm is based on WebDisco which is deemed non-confidential for ungrouped data.")
    node_data <- read.csv(paste0("../distributed/Data_node_", k, ".csv"))
  } else {
    node_data <- read.csv(paste0("../distributed/Data_node_grouped_", k, ".csv"))
  }
  data <- rbind(data, node_data)
}

# Calculate Cox model
column_indices <- (3:(nbBetas + 2))
formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("data[,", column_indices, "]"), collapse = " + ")))
res.cox <- coxph(formula, data, ties = "breslow")
summary(res.cox)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())