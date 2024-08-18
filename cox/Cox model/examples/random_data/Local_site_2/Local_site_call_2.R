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
manualk <- 2

# Number of parameters (covariates)
nbBetas <- 3

# No modifications should be required below this point
######################################################

k <- -1

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


# If there is a manual override, the node number (k) is set to the manual value --------------------------
if (manualk >= 0) {
  k <- manualk
  
  # If there is no valid override number, there will be an attempt to extract the node number from the data file name
} else {
  
  # List all the data files conforming the the pattern below. There should be only 1
  datafileslist <- list.files(pattern="Data_site_[[:digit:]]+.csv")
  
  # Assuming there is only one data file found
  if (length(datafileslist) == 1) {
    
    filename <- datafileslist[[1]]
    lastunders <- max(unlist(gregexpr("_",filename)))
    lenmainfilename <- nchar(filename)-4
    autok <- strtoi(substring(filename,lastunders+1,lenmainfilename))
    
    k <- autok
    
    # If there is more than one data file in the folder, the script will halt.
  } else {
    stop("There is more than one data file in this folder, the node number cannot be automatically identified")
  }
}

# Verifying that a valid node number could be allocated manually or automatically
if (k >= 0) {
  
  # If no files found --- call first function to initialize time and local betas
  if (!file.exists(paste0("Times_", manualk ,"_output.csv"))) {
    source("Local_site_core_times.R")
    data_event_times(manualwd, k, nbBetas)
    
    # If global times file exists -- call second function to calculate params
  } else if (!file.exists(paste0("normDik", manualk ,".csv"))) {
    source("Local_site_core_params.R")
    parameters_sites(manualwd, k, nbBetas)
    
    source("Local_site_core_betas.R")
    calculate_local_values(manualwd, k, nbBetas, 0)
    
    # If beta file exists --- call third function to calculate aggregates
  } else if (file.exists("Beta_0_output.csv")) {
    # Get the iteration number
    files <- list.files(pattern = "Beta_\\d+_output.csv")
    numbers <- as.numeric(gsub("Beta_(\\d+)_output.csv", "\\1", files))
    max_number <- max(numbers)
    
    source("Local_site_core_betas.R")
    calculate_local_values(manualwd, k, nbBetas, max_number)
  }
} else {
  stop("Node numbering was not set properly")
}

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())