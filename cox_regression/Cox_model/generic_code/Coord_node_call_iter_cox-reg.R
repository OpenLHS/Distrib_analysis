############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines
library(MASS)                # Functions for matrix manipulation (ginv)

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1 

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

# Initialise error messages
error_message <- NULL

# ------------------------- CODE STARTS HERE ------------------------

# Calculate number of data nodes from files fitting the pattern in the working directory
# This assumes unique event times outputs have a name like Times_[[:digit:]]+_output.csv
K=length(list.files(path=path, pattern="Times_[[:digit:]]+_output.csv")) 


# First step: initialization of times and betas
if (!file.exists(paste0(path,"Global_times_output.csv"))) {

  source("Coord_node_init_iter_cox-reg.R")
  coord_init_iter_cox_reg(manualwd, path)
  
} else {
  
  # Find current iteration number
  files <- list.files(path=path, pattern = "Beta_\\d+_output.csv")
  indext <- as.numeric(gsub("Beta_(\\d+)_output.csv", "\\1", files))
  t <- max(indext, 0)  
  t <- t + 1
  
  source("Coord_node_add_iter_cox-reg.R")
  coord_call_add_iter_cox_reg(manualwd, t, path)
    
} 

# Clear variables
rm(list = ls())