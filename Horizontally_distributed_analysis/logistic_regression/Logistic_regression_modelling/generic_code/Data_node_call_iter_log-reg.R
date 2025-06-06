############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi

data_call_iter_log_reg <- function(man_wd=-1,man_nodeid=-1, man_iter=-1, expath="") {

manualwd <- man_wd
manualk <- man_nodeid
manualt <- man_iter
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


k <- -1
t <- -1
# If there is a manual override, the node number (k) is set to the manual value --------------------------
if (manualk >= 0) {
  k <- manualk
  
  # If there is no valid override number, there will be an attempt to extract the node number from the data file name
} else {
  
  # List all the data files conforming the the pattern below. There should be only 1
  datafileslist <- list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+.csv")
  
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

# If there is a manual override, the iteration sequence number (t) is set to the manual value ------------
if (manualt >= 0) {
  t <- manualt
  
  # If there is no valid override sequence number, there will be an attempt to extract the number from the data file name
} else {
  
  # List all the data files conforming the the pattern below. There should be at least 1
  coordouputfileslist <- list.files(path=examplefilepath, pattern="Coord_node_iter_[[:digit:]]+_primer.csv")
  # Assuming there is at least one file found
  if (length(coordouputfileslist) > 0) {
    
    itervec=vector(mode="numeric")
    for (fl in coordouputfileslist){
      outputfname <- fl
      underspositions <- unlist(gregexpr("_",outputfname))
      lastundersf <- max(underspositions)
      beforelastundersf <- underspositions[length(underspositions)-1]
      iterfl <- strtoi(substring(outputfname,beforelastundersf+1,lastundersf-1)) 
      itervec <- append(itervec,iterfl)
    }
    
    t <- max(itervec)
  } else {
    stop("There is no primer file found")
  }
}

# Verifying that a valid node number and sequence numbers could be allocated manually or automatically
if (k >= 0 & t >= 0) {
  source("Data_node_core_iter_log-reg.R")
  data_iter_log_reg(manualwd,k,t,examplefilepath)
} else {
  stop("Node numbering was not set properly")
}

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}