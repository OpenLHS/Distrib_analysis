############### Distributed inference ####################
############### Response-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi


# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manually.
manualwd <- -1

# If you want to override the response node numbering based on filename, input 0 or a positive integer here
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
  
k <- -1
# If there is a manual override, the node number (k) is set to the manual value --------------------------
if (manualk >= 0) {
  k <- manualk
  
  # If there is no valid override number, there will be an attempt to extract the node number from the data file name
} else {
  
  # List all the data files conforming the the pattern below. There should be only 1
  datafileslist <- list.files(path=path, pattern="Data_node_[[:digit:]]+.csv")
  
  # Assuming there is only one data file found
  if (length(datafileslist) == 1) {
    
    filename <- datafileslist[[1]]
    lastunders <- max(unlist(gregexpr("_",filename)))
    lenmainfilename <- nchar(filename)-4
    autok <- strtoi(substring(filename,lastunders+1,lenmainfilename))
    
    k <- autok
    
    # If there is more than one data file in the folder, the script will halt.
  } else {
    stop("There is more than one data file in this folder, the response node number cannot be automatically identified")
  }
}

# Verifying if there is a response node output file present
nb_rnode_files <- length(list.files(path = path, pattern="outcome_data.csv"))

if (nb_rnode_files==0) {
  source("Response_node_core_log-regV.R")
  response_core_log_reg(manualwd,k,path)
} else {
    stop("There is already a response node output. There is no need to rerun this file.")
} 

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())