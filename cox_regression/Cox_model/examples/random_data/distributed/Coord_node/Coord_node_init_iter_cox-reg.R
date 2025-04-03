############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines
library(MASS)                # Functions for matrix manipulation (ginv)

coord_init_iter_cox_reg <- function(man_wd=-1) {

  manualwd <- man_wd
  
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
      
      # no known means to automatically allocate node number
    } else {
      stop("The required conditions to automatically set the working directory are not met. See R file")
    }
  } else {
    print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
  }
  
  # Initialise error messages
  error_message <- NULL

  # Calculate number of data nodes from files fitting the pattern in the working directory
  # This assumes unique event times outputs have a name like Times_[[:digit:]]+_output.csv
  K <- length(list.files(pattern="Times_[[:digit:]]+_output.csv")) 
  p <- 0
  k <- 1
  
  # Compares local settings to ensure all data nodes are 1) aligned and 2) expect the same kind of estimation
  Settings <- read.csv(file = paste0("Local_Settings_", k, ".csv"), stringsAsFactors = FALSE)
  Pred_names <- Settings[,1]
  Robust <- Settings[1,2]
  
  for(k in 2:K){
    OtherSettings <- read.csv(file = paste0("Local_Settings_", k, ".csv"), stringsAsFactors = FALSE)
    Same_names <- OtherSettings[,1]
    Same_Robust <- OtherSettings[1,2]
    
    # Do all nodes use the same predictors?
    if(!all(Pred_names==Same_names)){
      stop("Node data files seems to have different column structure which may yield wrong results. \n Make sure each node uses the same variable names and the same order in the data file before running this algorithm.")
    }
    # Do all nodes expect the same kind of estimation?
    if(Robust!=Same_Robust){
      stop("Node data files seems to use different values for the robust estimation flag.\n Make sure all nodes expect the same kind of estimation before running this algorithm.")
    }
  }

  # Exporting global settings
  length(Robust) <- length(Pred_names)
  globalinfo <- cbind(Pred_names, Robust)
  colnames(globalinfo)[1] <- "Predictor_names"
  colnames(globalinfo)[2] <- "Robust_Flag"
  write.csv(globalinfo, file="Global_Settings.csv", row.names = FALSE)
  
  # Time initialization -----------------------------------------------------
  # Read local times from all sites
  times_list <- list()
  for (k in 1:K) {
    times_list[[k]] <- read.csv(paste0("Times_", k, "_output.csv"))
  }
  
  # Combine and get all unique event times
  combined_times <- do.call(c, lapply(times_list, function(df) unlist(df)))
  Times_list <- sort(unique(combined_times))
  write.csv(Times_list, file="Global_times_output.csv", row.names = FALSE)
  
  # Beta initialization -----------------------------------------------------
  # Here, we try the inverse variance method for beta initialization.
  # If it fails (singular matrix), beta is initialized with a simple average.
  tryCatch({
    Bk_list <- list()
    Vk_list <- list()
    Vk_inv_list <- list()
    
    # Read matrices from files and calculate inverses
    for (k in 1:K) {
      Bk_list[[k]] <- as.matrix(read.csv(paste0("Beta_local_", k, ".csv")))
      Vk_list[[k]] <- as.matrix(read.csv(paste0("Vk_", k, ".csv")))
      Vk_inv_list[[k]] <- solve(Vk_list[[k]])
    }
    
    # Initialize the sums
    Vk_inv_sum <- matrix(0, nrow=nrow(Vk_inv_list[[1]]), ncol=ncol(Vk_inv_list[[1]]))
    Vk_inv_Bk_sum <- matrix(0, nrow=nrow(Vk_inv_list[[1]]), ncol=ncol(Bk_list[[1]]))
    
    # Sum the matrices
    for (k in 1:K) {
      Vk_inv_sum <- Vk_inv_sum + Vk_inv_list[[k]]
      Vk_inv_Bk_sum <- Vk_inv_Bk_sum + Vk_inv_list[[k]] %*% Bk_list[[k]]
    }
    
    beta <- t(Vk_inv_Bk_sum) %*% solve(Vk_inv_sum)
    write.csv(t(beta), file="Beta_0_output.csv", row.names = FALSE)
    
  }, error = function(e) {
    error_message <<- paste("Warning: Initial beta estimate done with simple averaging method, as an error occured trying the inverse variance weighted initial estimator.\n", e$message)
    message("Warning: Initial beta estimate done with simple averaging method, as an error occured trying the inverse variance weighted initial estimator.\n", e$message)
    
    # Find number of Betas (covariates) and makes sure this number is the same across nodes
    nbBetas <- nrow(read.csv(paste0("Beta_local_1.csv")))
    
    # Beta is a weighted sum of local betas depending on the number of individuals in the sites
    
    p <- 0
    for (k in 1:K) {
      local_beta = as.matrix(read.csv(paste0("Beta_local_", k, ".csv")))
      q <- nrow(local_beta)
      if(p==0){
        p <- q
        beta_sum <- matrix(0, p, 1)
        total_subjects <- 0
      }
      else if (p != q)
        stop("Nodes files do not seem to contain the same number of predictors.")
      local_subjects <- as.integer(read.csv(paste0("N_node_", k, ".csv")))
      total_subjects <- total_subjects + local_subjects
      beta_sum <- beta_sum + local_subjects * local_beta
    }
    beta <- beta_sum/total_subjects
    
    write.csv(beta, file="Beta_0_output.csv", row.names = FALSE)
  })
  
  if (!is.null(error_message)) {
    message(error_message)
  }
  
  # Clear variables
  rm(list = ls())
  
} 

