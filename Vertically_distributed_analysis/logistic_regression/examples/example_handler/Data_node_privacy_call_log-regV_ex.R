############### Distributed inference ####################
############### Covariate-node code - Privacy assessment ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

vert_logistic_regression_example_privacy_handler <- function(man_wd=-1, nodeid=-1, man_index_se=NA, expath=""){

  # No modifications should be required below this point
  ###########################
    
  manualwd <- man_wd
  manualk <- nodeid
  examplefilepath <- expath
  index_se <- man_index_se

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
  
  k <- -1
  
  # If there is a manual override, the node number (k) is set to the manual value --------------------------
  if (manualk >= 0) {
    k <- manualk
    
    # If there is no valid override number, there will be an attempt to extract the node number from the data file name
  } else {
    
    # List all the data files conforming the the pattern below. There should be only 1
    datafileslist <- list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+.csv")
    
    # Assuming there is only one data file found
    if (length(datafileslist) == 1) {
      
      filename <- datafileslist[[1]]
      lastunders <- max(unlist(gregexpr("_",filename)))
      lenmainfilename <- nchar(filename)-4
      autok <- strtoi(substring(filename,lastunders+1,lenmainfilename))
      
      k <- autok
      
      # If there is more than one data file in the folder, the script will halt.
    } else {
      stop("There is more than one data file in this folder, the node number cannot be automatically identified")
    }
  }
  
  # Verifying that a valid node number and sequence numbers could be allocated manually or automatically
  if (k >= 0) {
    source("../../generic_code/Data_node_privacy_core_log-regV.R")
    data_privacy_log_reg(manualwd,k,index_se,examplefilepath)
  } else {
    stop("Node numbering was not set properly")
  }
  
}



