############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

data_init_log_reg <- function(nodeid) {
  
  k <- nodeid

  # Importing data ----------------------------------------------------------
  
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
  
  # Expecting data file name like Data_node_k.csv where 1 is the variable k above
  # Construct file name according to node data
  # Assumes default parameters, like header and separator
  node_data <- read.csv(paste0("Data_node_", k, ".csv"))
  n <- nrow(node_data)
  
  # Fitting local model to generate an initial local estimator --------------
  
  fit <- glm(out1 ~ ., data=node_data)
  coefs <- as.vector(fit$coefficients)
  
  # Exporting local estimator and sample size -------------------------------
  
  write.csv(c(coefs, n),
            file=paste0("Data_node_",k,"_iter_0_output.csv"), row.names=FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)

}