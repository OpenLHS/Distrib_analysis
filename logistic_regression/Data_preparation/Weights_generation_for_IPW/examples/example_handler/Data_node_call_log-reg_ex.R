############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

logistic_regression_IPW_example_datanode_handler <- function(man_wd=-1, man_t=-1, nodeid=-1, expath="", man_thresh=-1){
  
  # No modifications should be required below this point
  ###########################
  
  manualwd <- man_wd
  manualt <- man_t
  manualk <- nodeid
  examplefilepath <- expath
  probthresh <- man_thresh
  
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
  
  # Veryfiying if there is a coordination node output file present
  nbprimerfiles <- length(list.files(path = examplefilepath, pattern="Coord_node_iter_[[:digit:]]+_W_primer.csv"))
  if (nbprimerfiles > 0) {
    source("../../generic_code/Data_node_call_iter_log-reg.R")
    data_call_iter_log_reg(manualwd,manualk,manualt,examplefilepath,man_thresh=probthresh)
  } else {
    source("../../generic_code/Data_node_call_init_log_reg.R")
    data_call_init_log_reg(manualwd,manualk,expath=examplefilepath,man_thresh=probthresh)
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
}