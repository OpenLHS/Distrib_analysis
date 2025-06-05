############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

cox_regression_example_coordnode_handler <- function(man_wd=-1, Robust=FALSE, expath=""){
  
  # Loading packages and setting up core variables --------------------------
  library("survival")          # Contains the core survival analysis routines
  library(MASS)                # Functions for matrix manipulation (ginv)
  
  manualwd <- man_wd
  RobustFlag <- Robust
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
  
  # Initialise error messages
  error_message <- NULL
  
  # ------------------------- CODE STARTS HERE ------------------------
  
  # Calculate number of data nodes from files fitting the pattern in the working directory
  # This assumes unique event times outputs have a name like Times_[[:digit:]]+_output.csv
  K=length(list.files(path=examplefilepath, pattern="Times_[[:digit:]]+_output.csv")) 
  
  
  # First step: initialization of times and betas
  if (!file.exists(paste0(examplefilepath, "Global_times_output.csv"))) {
    
    source("../../generic_code/Coord_node_init_iter_cox-reg.R")
    coord_init_iter_cox_reg(man_wd = manualwd, expath = examplefilepath)
    
  } else {
    
    # Find current iteration number
    files <- list.files(path = examplefilepath, pattern = "Beta_\\d+_output.csv")
    indext <- as.numeric(gsub("Beta_(\\d+)_output.csv", "\\1", files))
    t <- max(indext, 0)  
    t <- t + 1
    
    source("../../generic_code/Coord_node_add_iter_cox-reg.R")
    coord_call_add_iter_cox_reg(man_wd=manualwd, man_t=t, expath=examplefilepath)
    
  } 
  
  # Clear variables
  rm(list = ls())
  
}