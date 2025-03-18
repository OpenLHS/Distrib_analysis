############### Distributed inference ####################
############### Data node code - Missing values ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

missing_value_handler <- function(man_wd=-1,nodeid=-1) {
  
  manualwd <- man_wd
  k <- nodeid
  
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
  if(!file.exists(paste0("Data_node_grouped_", k ,".csv"))){
    filehandle <- paste0("Data_node_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  } else {
    filehandle <- paste0("Data_node_grouped_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  }
  
  # Verifying if weights are available. 
  Uniform_weights <- FALSE
  
  # Lists all the weight files provided by the user. There should be either none or 1.
  Userwlist <- list.files(pattern=paste0("Weights_node_", k, ".csv"))
  nbUserwfiles <- length(Userwlist)
  # Assumes there is at most one weight file provided by the user found
  if (nbUserwfiles > 1){
    stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
  }
  
  # Lists all the IPW files conforming the the pattern below. There should be either none or 1.
  IPWfilelist <- list.files(pattern=paste0("IPW_node_", k, "_iter_[[:digit:]]+.csv"))
  nbIPWfiles <- length(IPWfilelist)
  # Assumes there is at most one IPW file found
  if (nbIPWfiles > 1) {
    stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
  } 
  
  # Number of files related to weights
  nbWeightfiles <- nbUserwfiles + nbIPWfiles
  
  # Assumes there is at most one type of weight file found
  if (nbWeightfiles > 1){
    stop("There is nore than one type of weight files in this folder, the weights cannot be automatically identified.")
  }
  
  # Find which weights should be used, if any.  
  # First case checked is for weights provided by the user      
  if (file.exists(paste0("Weights_node_", k, ".csv"))) { 
    node_weights <- read.csv(paste0("Weights_node_", k, ".csv"))[,1]
    
    # Second case is for IPW/ITPW
  } else if(length(IPWfilelist)>0) { 
    filename <- IPWfilelist[[1]]
    lastunders <- max(unlist(gregexpr("_",filename)))
    lastdot <- max(unlist(gregexpr(".", filename, fixed = TRUE)))
    autoiter <- strtoi(substring(filename,lastunders+1,lastdot-1))
    
    iter_weights <- autoiter
    
    node_weights <- read.csv(paste0("IPW_node_", k, "_iter_", iter_weights ,".csv"))$IPW
    
    # Last case is when no weights are provided. Uses uniform weights
  } else { 
    n <- nrow(node_data)
    node_weights <- rep(1, n)
    Uniform_weights <- TRUE
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
    write.csv(old_data, file = paste0("Backup_", filehandle, "Incomplete_", k, ".csv"), row.names = FALSE)
    write.csv(new_node_data, file = paste0(filehandle, k, ".csv"), row.names = FALSE)
    
    # Save old and new file for weights, unless we have uniform weights
    if(!Uniform_weights){
      write.csv(old_weights, file = paste0("Backup_Weights_node_Incomplete_", k, ".csv"), row.names = FALSE)
      write.csv(new_node_weights, file = paste0("Weights_node_", k, ".csv"), row.names = FALSE)  
    }
    
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
  
}