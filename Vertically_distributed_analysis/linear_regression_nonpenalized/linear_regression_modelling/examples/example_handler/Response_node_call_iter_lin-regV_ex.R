############### Distributed inference ####################
############### Response-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

vert_linear_regression_example_coordnode_handler <- function(man_wd=-1, man_tau=-1, man_eta=-1, expath="", man_seed){

  manualwd <- man_wd
  tau <- man_tau
  eta <- man_eta
  examplefilepath <- expath
  manualseed <- man_seed
  
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

  # Verifying if there is a coordination node (response-node) data file present
  nb_node1_files <- length(list.files(path=examplefilepath, pattern="Data_node_1.csv"))
  nb_node_output_files <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))
  
  if (nb_node1_files==1 & nb_node_output_files>0) {
    source("../../generic_code/Response_node_init_iter_lin-regV.R")
    coord_lin_reg(man_wd = manualwd, man_tau = tau, man_eta = eta, expath = examplefilepath, man_seed = manualseed)
  } else {
    stop("Node 1 data file missing or no output file from other nodes found")
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())  
  
}
