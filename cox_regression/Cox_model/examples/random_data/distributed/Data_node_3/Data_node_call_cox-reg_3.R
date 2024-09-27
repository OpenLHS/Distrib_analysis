############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines 

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# If you want to override the node numbering based on filename, input 0 or a positive integer here
manualk <- 3
manualt <- -1

# No modifications should be required below this point
######################################################

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
if (!file.exists(paste0("Times_", manualk ,"_output.csv"))) {
  source("Data_node_call_init_cox-reg.R")
  data_call_init_cox_reg(manualwd, manualk)
    
  # If a coordination node output file exists -- Start a new iteration
} else {
  source("Data_node_call_iter_cox-reg.R")
  data_call_iter_cox_reg(manualwd, manualk, manualt)
}

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())
