############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

cox_regression_example_datanode_handler <- function(man_wd=-1, nodeid=-1, iter=-1, Robust=FALSE, expath=""){
  
  # No modifications should be required below this point
  ###################################################### 
  
  RobustVarianceFlag <- Robust
  manualwd <- man_wd
  manualk <- nodeid
  manualt <- iter
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
  
  # Verifying if there is a coordination node output file present -- Otherwise initialize files
  if (!file.exists(paste0(examplefilepath, "Times_", manualk ,"_output.csv"))) {
    source("../../generic_code/Data_node_call_init_cox-reg.R")
    data_call_init_cox_reg(manualwd, manualk, RobustVarianceFlag, examplefilepath)
    
    # If a coordination node output file exists -- Start a new iteration
  } else {
    source("../../generic_code/Data_node_call_iter_cox-reg.R")
    data_call_iter_cox_reg(manualwd, manualk, manualt, RobustVarianceFlag, examplefilepath)
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
}
