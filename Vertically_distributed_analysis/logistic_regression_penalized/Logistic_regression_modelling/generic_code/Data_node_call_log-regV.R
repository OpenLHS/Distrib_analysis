############### Distributed inference ####################
############### Data-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# If you want to override the node numbering based on filename, input 0 or a positive integer here
manualk <- -1

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

# Once the working directory as been set, save it so we can pass it to other files
path <- paste0(getwd(), "/")
  
# Veryfiying if there is a coordination node output file present
nb_coordnode_files <- length(list.files(path = path, pattern="Coord_node_results_distributed_log_regV.csv"))
if (nb_coordnode_files==1) {
  source("Data_node_call_iter_log-regV.R")
  data_call_iter_log_reg(manualwd,manualk,path)
} else {
  source("Data_node_call_init_log_regV.R")
  data_call_init_log_reg(manualwd,manualk,path)
  }

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())