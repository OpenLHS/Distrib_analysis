############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")
library("survminer")

#' @title parameters_sites
#'
#' @description This function calculates Dik and Rik, which are the index sets of subjects with observed events and at risk for the event at the i-th distinct event time.
#' @description This function also calculates parameters that stem from Dik and Rik.
#'
#' @param man_wd Parameter for manual working directory setting, integer.
#' @param nodeid Site number, integer.
#' @param nodebetas Number of covariates (betas), integer.
#' 
#' This function generates the following files:
#' - normDikk.csv, which is the number of events at the i-th distinct event time.
#' - Rikk.csv, which is the risk set.
#' - sumZrk.csv, which is the sum of the covariates of subjects that had an even the i-th distinct event time.

parameters_sites <- function(man_wd=-1,nodeid=-1, nodebetas=-1) {
  
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
  
  # Read data
  node_data <- read.csv(paste0("Data_site_", k, ".csv"))
  Dlist <- read.csv("Global_times_output.csv")
  Dlist <- Dlist$x
  
  # Dik: list containing the index sets of subjects with observed events at time i
  Dik <- vector("list", length(Dlist))
  for (i in seq_along(Dlist)) {
    indices <- which(node_data$time == Dlist[i] & node_data$status == 1)
    if (length(indices) > 0) {
      Dik[[i]] <- indices
    } else {
      Dik[[i]] <- 0
    }
  }
  
  # Rik: list containing the id of subjects still at risk at time i
  Rik <- vector("list", length(Dlist))
  for (i in seq_along(Dlist)) {
    Rik[[i]] <- which(node_data$time >= Dlist[i])
  }
  
  # Sum of covariates associated with subjects with observed events at time i
  sumZr <- matrix(0, nrow = length(Dik), ncol = nbBetas)
  for (i in seq_along(Dik)) {
    indices <- Dik[[i]]
    for (x in 1:nbBetas) {
      current_sum <- sum(node_data[[3 + x - 1]][indices])           
      sumZr[i, x] <- ifelse(is.na(current_sum), 0, current_sum)      # if NA, put = 0 (might induce errors, but avoids crashing)
    }
  }
  
  # Summary and outputs -----------------------------------------------------
  
  # Function to convert NULL to a row of NAs of a specified length
  pad_with_na <- function(x, max_length) {
    if (is.null(x)) {
      return(rep(NA, max_length))
    } else {
      x[x == 0] <- NA
      length(x) <- max_length
      return(x)
    }
  }
  
  # Convert Dik
  max_length <- max(sapply(Dik, function(x) if (is.null(x)) 0 else length(x)))
  padded_rows <- lapply(Dik, pad_with_na, max_length)
  df <- as.data.frame(do.call(rbind, padded_rows))
  df[is.na(df)] <- ""
  
  # Norm Dik
  normDik <- apply(df, 1, function(row) sum(row != ""))
  
  # Convert Rik
  max_length <- max(sapply(Rik, function(x) if (is.null(x)) 0 else length(x)))
  padded_rows <- lapply(Rik, pad_with_na, max_length)
  df2 <- as.data.frame(do.call(rbind, padded_rows))
  
  # Write
  write.csv(normDik, file=paste0("normDik",k,".csv"),row.names = FALSE,na="")
  write.csv(df2, file=paste0("Rik",k,".csv"),row.names = FALSE,na="")
  write.csv(sumZr, file=paste0("sumZr",k,".csv"),row.names = FALSE,na="")

  rm(list = ls())
  
  return(TRUE)
}