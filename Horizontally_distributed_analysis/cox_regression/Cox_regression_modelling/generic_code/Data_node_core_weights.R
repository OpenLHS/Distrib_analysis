############### Distributed inference ####################
############### Data node code - Weights ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

weights_handler <- function(man_wd=-1,nodeid=-1,expath="", nbrow=-1, IPW_Gen=FALSE) {
  
  manualwd <- man_wd
  k <- nodeid
  examplefilepath <- expath
  n = nbrow
  IPW_Generation = IPW_Gen
  
  if (k<0){
    stop
  }
  
  if(n<=0){
    stop
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
  # Importing data ----------------------------------------------------------
  
  # Lists all the weight files provided by the user. There should be either none or 1.
  Userwlist <- list.files(path=examplefilepath, pattern=paste0("Weights_node_", k, ".csv"))
  nbUserwfiles <- length(Userwlist)
  # Assumes there is at most one weight file provided by the user found
  if (nbUserwfiles > 1){
    stop("There is more than one Weight file in this folder, the weights cannot be automatically identified")
  }
  
  # Only try to read IPW when we are NOT running the algorithm to create IPW files.
  if(IPW_Generation==FALSE){
    # Lists all the IPW files conforming the the pattern below. There should be either none or 1.
    IPWfilelist <- list.files(path=examplefilepath, pattern=paste0("IPW_node_", k, "_iter_[[:digit:]]+.csv"))
    nbIPWfiles <- length(IPWfilelist)
    # Assumes there is at most one IPW file found
    if (nbIPWfiles > 1) {
      stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
    } 
    
    # Number of files related to weights
    nbWeightfiles <- nbUserwfiles + nbIPWfiles
    
    # Assumes there is at most one type of weight file found
    if (nbWeightfiles > 1){
      stop("There is nore than one type of weight files in this folder, the weights cannot be automatically identified.")
    }
    # If we ARE running the algorithm to create IPW files, initialize said IPW list to me empty
  } else{
    IPWfilelist <- list()
  }
  
  # Find which weights should be used, if any.  
  # First case checked is for weights provided by the user      
  if (file.exists(paste0(examplefilepath, "Weights_node_", k, ".csv"))) { 
    node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
    
    # Second case is for IPW/ITPW
  } else if(length(IPWfilelist)>0) { 
    filename <- IPWfilelist[[1]]
    lastunders <- max(unlist(gregexpr("_",filename)))
    lastdot <- max(unlist(gregexpr(".", filename, fixed = T)))
    autoiter <- strtoi(substring(filename,lastunders+1,lastdot-1))
    
    iter_weights <- autoiter
    
    node_weights <- read.csv(paste0(examplefilepath, "IPW_node_", k, "_iter_", iter_weights ,".csv"))$IPW
    
    # Last case is when no weights are provided. Uses uniform weights
  } else { 
    node_weights <- rep(1, n)
  }
  
  # Create df and variable name  
  node_weights <- as.data.frame(node_weights)
  colnames(node_weights) <- "Weights"
  
  # Saves which file to use
  write.csv(node_weights, file = paste0(examplefilepath, "Weights_node_", k, ".csv"), row.names = FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
  
}