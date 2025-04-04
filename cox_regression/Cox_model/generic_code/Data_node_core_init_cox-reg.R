############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")

data_init_cox_reg <- function(man_wd, nodeid, robflag, expath) {
  
  manualwd <- man_wd
  k <- nodeid
  Robust <- robflag
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
  
  # Handles missing values, if any
  source("Data_node_core_missingvalues.R")
  missing_value_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath)
  
  # Read data
  if(!file.exists(paste0(examplefilepath, "Data_node_grouped_", k ,".csv"))){
    warning("Attempt to find a file with grouped data failed and thus this will use ungrouped data. Be aware that this algorithm is based on WebDisco which is deemed non-confidential for ungrouped data.")
    filehandle <- paste0("Data_node_")
    node_data <- read.csv(paste0(examplefilepath, filehandle, k, ".csv"))
  } else {
    filehandle <- paste0("Data_node_grouped_")
    node_data <- read.csv(paste0(examplefilepath, filehandle, k, ".csv"))
  }
  
  # Compute n
  n = nrow(node_data)
  
  # Verifying if weights are available. 
  Uniform_weights <- TRUE
  source("Data_node_core_weights.R") 
  weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
  node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
  if(any(node_weights!=1)){
    Uniform_weights <- FALSE
  }
  
  # Makes sure the data is ordered properly
  old_data <- node_data
  node_data <- node_data[order(node_data$time),]
  
  # Should the data not be ordered by time, save old copy of data and a new one of the ordered data. Make sure to do the same with weights
  if(!all(old_data$time==node_data$time)){
    warning("Data file was not ordered based on the time variable. As such, the whole dataset and the weights were reordered. Original data was saved in backup files.")
    
    # Joint dataset to reorder the weights properly
    unordered_data_and_weights <- cbind(old_data, node_weights)
    ordered_data_and_weights <- unordered_data_and_weights[order(unordered_data_and_weights$time),]
    
    old_weights <- node_weights
    node_weights <- as.data.frame(ordered_data_and_weights$node_weights)
    
    # Save old and new file for weights, unless we have uniform weights
    if(!Uniform_weights){
      write.csv(old_weights, file = paste0(examplefilepath, "Backup_Weights_node_Unordered_", k, ".csv"), row.names = FALSE)
      write.csv(node_weights, file = paste0(examplefilepath, "Weights_node_", k, ".csv"), row.names = FALSE)  
    }
    
    # Save old and new file for data
    write.csv(old_data, file = paste0(examplefilepath, "Backup_", filehandle, "Unordered_", k, ".csv"), row.names = FALSE)
    write.csv(node_data, file = paste0(examplefilepath, filehandle, k, ".csv"), row.names = FALSE)  
    
    # Transform weights as numeric object
    node_weights <- node_weights[,1]
    
  }
  
  # Makes sure the status variable is properly coded as 0s and 1s.
  if(!all(unique(node_data$status) %in% c(0,1))){
    stop("The status variable contains values that are different from 0 and 1, which isn't allowed.")
  }
  
  # Get event times, write in csv
  event_times <- unique(node_data$time[node_data$status == 1])
  write.csv(event_times, file=paste0(examplefilepath, "Times_",k,"_output.csv"),row.names = FALSE,na="")
  
  # Find number of Betas (covariates)
  nbBetas <- dim(node_data)[2]-2
  
  # Calculate local Cox model
  column_indices <- (3:(nbBetas + 2))
  formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("node_data[,", column_indices, "]"), collapse = " + ")))
  res.cox <- coxph(formula, node_data, ties = "breslow", weights = node_weights)
  write.csv(coef(res.cox), file=paste0(examplefilepath, "Beta_local_",k,".csv"),row.names = FALSE,na="0")
  
  # Get variance-covariance matrix
  Vk <- vcov(res.cox)
  write.csv(Vk, file=paste0(examplefilepath, "Vk_",k,".csv"),row.names = FALSE,na="")
  
  # Get number of data for beta initialization
  write.csv(nrow(node_data), file=paste0(examplefilepath, "N_node_",k,".csv"),row.names = FALSE,na="0")
  
  # Export local settings
  length(Robust) <- length(colnames(node_data))
  localinfo <- cbind(colnames(node_data), Robust)
  colnames(localinfo)[1] <- "Predictor_names"
  colnames(localinfo)[2] <- "Robust_Flag"
  write.csv(localinfo, file=paste0(examplefilepath, "Local_Settings_", k, ".csv"), row.names = FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
