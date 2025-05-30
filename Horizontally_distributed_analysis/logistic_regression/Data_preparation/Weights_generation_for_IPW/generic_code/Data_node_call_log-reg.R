############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# If you want to override the node numbering based on filename, input 0 or a positive integer here
manualk <- 1
manualt <- -1

# If you do not want to use a threshold for the probabilities estimated, input 0 here.
# Threshold value should be between 0 and 0.5. See details in the instructions.
manualthresh <- 0.01

# No modifications should be required below this point
###########################

if (manualthresh<0 | manualthresh>0.5){
  stop("The threshold for propensity score must be between 0 and 0.5.")
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

# Once the working directory as been set, save it so we can pass it to other files
path <- paste0(getwd(), "/")
  
# Veryfiying if there is a coordination node output file present
nbprimerfiles <- length(list.files(path=path, pattern="Coord_node_iter_[[:digit:]]+_W_primer.csv"))
if (nbprimerfiles > 0) {
  source("Data_node_call_iter_log-reg.R")
  data_call_iter_log_reg(manualwd,manualk,manualt,path,manualthresh)
} else {
  source("Data_node_call_init_log_reg.R")
  data_call_init_log_reg(manualwd,manualk,path,manualthresh)
  }

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())