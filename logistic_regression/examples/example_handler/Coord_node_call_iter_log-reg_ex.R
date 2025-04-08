############### Distributed inference ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

logistic_regression_example_coordnode_handler <- function(man_wd=-1, man_t=-1, expath=""){
  
  manualwd <- man_wd
  manualt <- man_t
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
  
  # Verifying if there is a coordination node output file present
  nbprimerfiles <- length(list.files(path=examplefilepath, pattern="Coord_node_iter_[[:digit:]]+_primer.csv"))
  if (nbprimerfiles > 0) {
    source("../../generic_code/Coord_node_call_add_iter_log-reg.R")
    coord_call_add_iter_log_reg(manualwd,manualt, examplefilepath)
  } else {
    source("../../generic_code/Coord_node_init_iter_log_reg.R")
    coord_init_iter_log_reg(manualwd, examplefilepath)
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
}