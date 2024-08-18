############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")
library("survminer")

#' @title data_event_times
#'
#' @description This function calculates the different event times for a single site.
#' @description This function also calculates a local Cox model.
#'
#' @param man_wd Parameter for manual working directory setting, integer.
#' @param nodeid Site number, integer.
#' @param nodebetas Number of covariates (betas), integer.
#' 
#' This function generates the following files:
#' - Times_k_output.csv, which contains the unique event times for the site
#' - Beta_local_k.csv, which contains the local beta estimate
#' - Vk_k.csv, which contains the variance-covariance matrix
#' - Number_of_subjects_site_k.csv, which contains the total number of subjects at the site

data_event_times <- function(man_wd=-1,nodeid=-1,nodebetas=-1) {
  
  manualwd <- man_wd
  k <- nodeid
  nbBetas <- nodebetas
  
  if (k<0){
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
  
  # ------------------------- CODE STARTS HERE ------------------------
  
  # Read data, get event times, write in csv
  node_data <- read.csv(paste0("Data_site_", k, ".csv"))
  event_times <- unique(node_data$time[node_data$status == 1])
  write.csv(event_times, file=paste0("Times_",k,"_output.csv"),row.names = FALSE,na="")
  
  # Calculate local Cox model
  column_indices <- (3:(nbBetas + 2))
  formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("node_data[,", column_indices, "]"), collapse = " + ")))
  res.cox <- coxph(formula, node_data, ties = "breslow")
  write.csv(coef(res.cox), file=paste0("Beta_local_",k,".csv"),row.names = FALSE,na="0")
  
  # Get variance-covariance matrix
  Vk <- vcov(res.cox)
  write.csv(Vk, file=paste0("Vk_",k,".csv"),row.names = FALSE,na="")
  
  # Get number of data for beta initialization
  write.csv(nrow(node_data), file=paste0("Number_of_subjects_site_",k,".csv"),row.names = FALSE,na="0")

  rm(list = ls())
  
  return(TRUE)
}
