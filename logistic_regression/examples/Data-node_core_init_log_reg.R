############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

# Load package rstudioapi : https://cran.r-project.org/package=rstudioapi 
library(rstudioapi)

data_init_log_reg <- function(nodeid) {
  
  k <- nodeid

  # Importing data ----------------------------------------------------------
  
  # Setting current working directory to source file location
  path <- dirname(rstudioapi::getActiveDocumentContext()$path)
  setwd(path)
  
  # Expecting data file name like Node1_data.csv where 1 is the variable k above
  # Construct file name according to node data
  # Assumes default parameters, like header and separator
  node_data <- read.csv(paste0("Node", k, "_data.csv"))
  n <- nrow(node_data)
  
  # Fitting local model to generate an initial local estimator --------------
  
  fit <- glm(out1 ~ ., data=node_data)
  coefs <- as.vector(fit$coefficients)
  
  # Exporting local estimator and sample size -------------------------------
  
  write.csv(c(coefs, n),
            file=paste0("Node",k,"_iter0_output.csv"), row.names=FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)

}