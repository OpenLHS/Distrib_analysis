############### Distributed inference ####################
############### Data node code - Missing values ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

missing_value_handler <- function(man_wd=-1,nodeid=-1,expath="") {
  
  manualwd <- man_wd
  k <- nodeid
  examplefilepath <- expath
  
  if (k<0){
    stop
  }
  
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
  # Importing data ----------------------------------------------------------
  
  # Read data
  if(!file.exists(paste0(examplefilepath, "Data_node_grouped_", k ,".csv"))){
    filehandle <- paste0(examplefilepath,"Data_node_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  } else {
    filehandle <- paste0(examplefilepath, "Data_node_grouped_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  }
  
  # Verifying if weights are available. 
  n <- nrow(node_data)
  Uniform_weights = TRUE
  source("Data_node_core_weights.R")
  weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
  node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))
  if(any(node_weights!=1)){
    Uniform_weights = FALSE
  }
  
  # Create a single dataset out of node_data et node_weights
  node_data_and_weights <- cbind(node_data, node_weights)
  
  if(any(is.na(node_data_and_weights))){
    # Data  with missing values
    old_data <- node_data
    old_weights <- node_weights
    
    # Data without missing values
    node_data_and_weights <- node_data_and_weights[rowSums(is.na(node_data_and_weights))==0, ]
    
    # Issue warning to user that we changed their main file 
    warning("Missing data has been found. As such, all lines with at least one missing data were removed. Original data was saved in a backup file.")
    
    # Summary and outputs -----------------------------------------------------
    
    new_node_data <- node_data_and_weights[, -(ncol(node_data_and_weights))]
    new_node_weights <- as.data.frame(node_data_and_weights[, (ncol(node_data_and_weights))])
    
    # Save old and new file for data
    write.csv(old_data, file = paste0(examplefilepath, "Backup_", filehandle, "Incomplete_", k, ".csv"), row.names = FALSE)
    write.csv(new_node_data, file = paste0(filehandle, k, ".csv"), row.names = FALSE)
    
    # Save old and new file for weights, unless we have uniform weights
    if(!Uniform_weights){
      write.csv(old_weights, file = paste0(examplefilepath, "Backup_Weights_node_Incomplete_", k, ".csv"), row.names = FALSE)
      write.csv(new_node_weights, file = paste0(examplefilepath, "Weights_node_", k, ".csv"), row.names = FALSE)  
    }
    
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
  
}