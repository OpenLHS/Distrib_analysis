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
    node_data <- read.csv(paste0("Data_node_", k, ".csv"))
  } else {
    node_data <- read.csv(paste0("Data_node_grouped_", k, ".csv"))
  }
  
  # Method isn't yet available for missing data
  if(any(is.na.data.frame(node_data))){
    stop("At least one NA was found in the data. \n The algorithm currently works only with complete data.")
  }
  
  # Makes sure the status variable is properly coded as 0s and 1s.
  if(any(unique(node_data$status) %in% c(0,1))){
    stop("The status variable contains values that are different from 0 and 1, which isn't allowed.")
  
  # Get event times, write in csv
  event_times <- unique(node_data$time[node_data$status == 1])
  write.csv(event_times, file=paste0("Times_",k,"_output.csv"),row.names = FALSE,na="")
  
  # Find number of Betas (covariates)
  nbBetas <- dim(node_data)[2]-2
  
  # Calculate local Cox model
  column_indices <- (3:(nbBetas + 2))
  formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("node_data[,", column_indices, "]"), collapse = " + ")))
  res.cox <- coxph(formula, node_data, ties = "breslow")
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
