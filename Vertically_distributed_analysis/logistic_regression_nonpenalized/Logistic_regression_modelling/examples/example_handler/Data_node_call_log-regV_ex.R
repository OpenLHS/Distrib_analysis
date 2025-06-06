############### Distributed inference ####################
############### Covariate-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

vert_logistic_regression_nonpenalized_example_datenode_handler <- function(man_wd=-1, nodeid=-1, expath=""){
  
  manualwd <- man_wd
  manualk <- nodeid
  examplefilepath <- expath
  
  # No modifications should be required below this point
  ###########################
  
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
  nb_coordnode_files <- length(list.files(path = examplefilepath, pattern="Coord_node_results_distributed_log_regV.csv"))
  if (nb_coordnode_files==1) {
    source("../../generic_code/Data_node_call_iter_log-regV.R")
    data_call_iter_log_reg(manualwd,manualk,examplefilepath)
  } else {
    source("../../generic_code/Data_node_call_init_log_regV.R")
    data_call_init_log_reg(manualwd,manualk,examplefilepath)
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
}



