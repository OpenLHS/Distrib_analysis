############### Distributed inference ####################
############### Covariate-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library()

data_init_log_reg <- function(man_wd,nodeid,expath) {
  
  manualwd <- man_wd 
  k <- nodeid
  examplefilepath <- expath

  # Importing data ----------------------------------------------------------
  
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

  # Read and scale data
  node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
  node_data <- scale(as.matrix(node_data))
  n <- nrow(node_data)

  # Handles missing values, if any 
  if(any(is.na(node_data))){
    stop("The dataset seems to contain NA value(s). The method cannot be applied. 
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
  }
  
  # Compute local Gram matrix
  node_Gram <- node_data%*%t(node_data)
  
  # Save Gram matrix to .csv / or to RDS format
  saveRDS(object = node_Gram, file = paste0(examplefilepath, "Data_node_", k, "_init_output.rds"), compress = TRUE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)

}