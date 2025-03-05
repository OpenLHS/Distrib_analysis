############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")

data_init_cox_reg <- function(man_wd,nodeid) {
  
  manualwd <- man_wd
  k <- nodeid
  
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
  
  # Read data
  if(!file.exists(paste0("Data_node_grouped_", k ,".csv"))){
    warning("Attempt to find a file with grouped data failed and thus this will use ungrouped data. Be aware that this algorithm is based on WebDisco which is deemed non-confidential for ungrouped data.")
    filehandle <- paste0("Data_node_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  } else {
    filehandle <- paste0("Data_node_grouped_")
    node_data <- read.csv(paste0(filehandle, k, ".csv"))
  }
  
  # Makes sure the data is ordered properly
  old_data <- node_data
  node_data <- node_data[order(node_data$time),]
  
  # Should the data not be ordered by time, save old copy of data and a new one of the ordered data
  if(!all(old_data$time==node_data$time)){
    write.csv(old_data, file = paste0("Backup_", filehandle, "Unordered_", k, ".csv"), row.names = F)
    write.csv(node_data, file = paste0(filehandle, k, ".csv"), row.names = F)  
  }

  # Verifying if weights are available. 
  
  # Lists all the weight files provided by the user. There should be either none or 1.
  Userwlist <- list.files(pattern=paste0("Weights_node_", k, ".csv"))
  nbUserwfiles <- length(Userwlist)
  # Assumes there is at most one weight file provided by the user found
  if (nbUserwfiles > 1){
    stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
  }
  
  # Lists all the IPW files conforming the the pattern below. There should be either none or 1.
  IPWfilelist <- list.files(pattern=paste0("IPW_node_", k, "_iter_[[:digit:]]+.csv"))
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
  
  # Find which weights should be used, if any.  
  # First case checked is for weights provided by the user      
  if (file.exists(paste0("Weights_node_", k, ".csv"))) { 
    node_weights <- read.csv(paste0("Weights_node_", k, ".csv"))[,1]
    
    # Second case is for IPW/ITPW
  } else if(length(IPWfilelist)>0) { 
    filename <- IPWfilelist[[1]]
    lastunders <- max(unlist(gregexpr("_",filename)))
    lastdot <- max(unlist(gregexpr(".", filename, fixed = T)))
    autoiter <- strtoi(substring(filename,lastunders+1,lastdot-1))
    
    iter_weights <- autoiter
    
    node_weights <- read.csv(paste0("IPW_node_", k, "_iter_", iter_weights ,".csv"))$IPW
    
    # Last case is when no weights are provided. Uses uniform weights
  } else { 
    n <- nrow(node_data)
    node_weights <- rep(1, n)
  }
  
  # Method isn't yet available for missing data
  if(any(is.na.data.frame(node_data))){
    stop("At least one NA was found in the data. \n The algorithm currently works only with complete data.")
  }
  
  # Makes sure the status variable is properly coded as 0s and 1s.
  if(!all(unique(node_data$status) %in% c(0,1))){
    stop("The status variable contains values that are different from 0 and 1, which isn't allowed.")
  }
  
  # Get event times, write in csv
  event_times <- unique(node_data$time[node_data$status == 1])
  write.csv(event_times, file=paste0("Times_",k,"_output.csv"),row.names = FALSE,na="")
  
  # Find number of Betas (covariates)
  nbBetas <- dim(node_data)[2]-2
  
  # Calculate local Cox model
  column_indices <- (3:(nbBetas + 2))
  formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("node_data[,", column_indices, "]"), collapse = " + ")))
  res.cox <- coxph(formula, node_data, ties = "breslow", weights = node_weights)
  write.csv(coef(res.cox), file=paste0("Beta_local_",k,".csv"),row.names = FALSE,na="0")
  
  # Write variables names
  write.csv(colnames(node_data), file=paste0("Predictor_names_", k, ".csv"), row.names = FALSE)
  
  # Get variance-covariance matrix
  Vk <- vcov(res.cox)
  write.csv(Vk, file=paste0("Vk_",k,".csv"),row.names = FALSE,na="")
  
  # Get number of data for beta initialization
  write.csv(nrow(node_data), file=paste0("N_node_",k,".csv"),row.names = FALSE,na="0")
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
