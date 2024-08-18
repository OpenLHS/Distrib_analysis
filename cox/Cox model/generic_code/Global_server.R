############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines
library(MASS)                # Functions for matrix manipulation (ginv)

# General parameters
nbBetas <- ...    # Input the number of covariates (betas) here
alpha <- 0.05     # Change if needed (used in confidence intervals)

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

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

# Initialise error messages
error_message <- NULL

# ------------------------- CODE STARTS HERE ------------------------

# Calculate number of data nodes from files fiting the pattern in the working directory
# This assumes unique event times outputs have a name like Times_[[:digit:]]+_output.csv
K=length(list.files(pattern="Times_[[:digit:]]+_output.csv"))

# First step: initialization of times and betas
if (!file.exists("Global_times_output.csv")) {
  
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
    
    # Beta is a weighted sum of local betas depending on the number of individuals in the sites
    beta_sum <- matrix(0, nbBetas, 1)
    total_subjects <- 0
    for (k in 1:K) {
      local_subjects <- as.integer(read.csv(paste0("Number_of_subjects_site_", k, ".csv")))
      total_subjects <- total_subjects + local_subjects
      beta_sum <- beta_sum + local_subjects * as.matrix(read.csv(paste0("Beta_local_", k, ".csv")))
    }
    beta <- beta_sum/total_subjects
    
    write.csv(beta, file="Beta_0_output.csv", row.names = FALSE)
  })
  
  # Iterations: Calculate derivatives and new beta
} else if (file.exists("sumExp1_output_1.csv") ) {
  
  # Get iteration number
  files <- list.files(pattern = "Beta_\\d+_output.csv")
  numbers <- as.numeric(gsub("Beta_(\\d+)_output.csv", "\\1", files))
  ite <- max(numbers)
  
  ite <- ite + 1
  
  # If first iteration - some more initialization
  if (ite == 1){
    
    sumZrGlobal <- 0
    
    for(i in 1:K){
      normDik <- read.csv(paste0("normDik", i, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      if(i == 1){
        normDikGlobal <- matrix(0, nrow = nrow(normDik)-1, ncol = 1)
      }
      normDikGlobal <- normDikGlobal + matrix(as.numeric(as.matrix(normDik[-1, ])), ncol = 1, byrow = FALSE)
      
      sumZr <- read.csv(paste0("sumZr", i, ".csv"))
      sumZrGlobal <- sumZrGlobal + colSums(sumZr)
    }
    
    write.csv(normDikGlobal, file="normDikGlobal.csv", row.names = FALSE)
    write.csv(sumZrGlobal, file="sumZrGlobal.csv", row.names = FALSE)
  }
  
  # Verification to make sure new data is used to compute beta
  if (file.exists((paste0("sumExp", K, "_output_", ite, ".csv")))){
    
    # Get old beta
    beta <-  read.csv(paste0("Beta_", ite-1, "_output.csv"))
    
    # Read files and sum values
    for(i in 1:K){
      
      # Retrieve data from local sites
      sumExp <- read.csv(paste0("sumExp", i, "_output_", ite, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumExp <- matrix(as.numeric(as.matrix(sumExp[-1, ])), ncol = 1, byrow = FALSE)
      
      sumZqExp <- read.csv(paste0("sumZqExp", i, "_output_", ite, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumZqExp <- matrix(as.numeric(as.matrix(sumZqExp[-1, ])), ncol = nbBetas, byrow = FALSE)
      
      sumZqZrExp <- read.csv(paste0("sumZqZrExp", i, "_output_", ite, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumZqZrExp <- array(as.numeric(as.matrix(sumZqZrExp[-1, ])), dim = c(nbBetas, nbBetas, ncol(sumZqZrExp)))
      
      # Initialize global matrices if first iteration
      if(i == 1){
        sumExpGlobal <- matrix(0, nrow = nrow(sumExp), ncol = ncol(sumExp))
        sumZqExpGlobal <- matrix(0, nrow = nrow(sumZqExp), ncol = ncol(sumZqExp))
        sumZqZrExpGlobal <- array(0, dim = dim(sumZqZrExp))
      }
      
      # Sum values
      sumExpGlobal <- sumExpGlobal + sumExp
      sumZqExpGlobal <- sumZqExpGlobal + sumZqExp
      sumZqZrExpGlobal <- sumZqZrExpGlobal + sumZqZrExp
    }
    
    # Calculate first derivative -------------------------------------------
    normDikGlobal <- as.matrix(read.csv("normDikGlobal.csv"))
    sumZrGlobal <- as.matrix(read.csv("sumZrGlobal.csv"))
    
    ZrExp_Divided_by_Exp <- sumZqExpGlobal/do.call(cbind, replicate(nbBetas, sumExpGlobal, simplify = FALSE))
    Norm_Times_ZrExp_Divided_by_Exp <- do.call(cbind, replicate(nbBetas, normDikGlobal, simplify = FALSE)) * ZrExp_Divided_by_Exp
    sum_Norm_Times_ZrExp_Divided_by_Exp <- colSums(Norm_Times_ZrExp_Divided_by_Exp)
    
    lr_beta <- sumZrGlobal - sum_Norm_Times_ZrExp_Divided_by_Exp
    
    # Calculate second derivative ------------------------------------------
    lrq_beta <- matrix(NA, nrow = nbBetas, ncol = nbBetas)
    
    # a, b and c are the three division present in the equation
    for (i in 1:nbBetas) {
      for (j in 1:nbBetas) {
        a <- sumZqZrExpGlobal[i, j, ] / sumExpGlobal
        b <- sumZqExpGlobal[, i] / sumExpGlobal
        c <- sumZqExpGlobal[, j] / sumExpGlobal
        
        value_ij <- a - b * c
        Norm_times_value_ij <- normDikGlobal * value_ij
        lrq_beta[i, j] <- -sum(Norm_times_value_ij)
      }
    }
    
    # Try to inverse matrix with solve()
    # If it fails (singular matrix), use the pseudo inverse (ginv)
    tryCatch({
      lrq_beta_inv <<- solve(lrq_beta)
    }, error = function(e) {
      error_message <<- paste("Warning: Pseudo inverse used to invert the matrix.\n", e$message)
      message("Warning: Pseudo inverse used to invert the matrix.\n", e$message)
      lrq_beta_inv <<- ginv(lrq_beta)
    })
    
    lr_beta <- matrix(as.numeric(lr_beta), nrow = nbBetas, ncol = 1)
    
    beta <- beta - (lrq_beta_inv %*% lr_beta)
    
    # Write in CSV
    write.csv(beta, file=paste0("Beta_", ite, "_output.csv"), row.names = FALSE)
    
    # Result file ------------------------------------------------------------
    fisher_info <- -lrq_beta_inv
    
    var <- diag(fisher_info)
    se <- qnorm(1 - 0.5*alpha) * sqrt(var)
    temp <- abs(beta)/sqrt(diag(fisher_info))
    p_vals <- 2*(1 - pnorm(temp$x))
    
    # Exporting final results
    output <- cbind(beta, exp(beta), exp(-beta),  exp(beta - se), exp(beta + se), sqrt(var), p_vals)
    output <- format(output, digits = 6, nsmall = 6)
    colnames(output) <- c(" coef", " exp(coef)", " exp(-coef)", " lower .95", " upper .95", " se(coef)", " Pr(>|z|)")
    rownames(output) <- paste0("X", seq_len(length(beta$x)))
    
    # Write the output to a CSV file
    write.csv(output, file = paste0("Results_iter_", ite, ".csv"), quote = FALSE, row.names = TRUE)
    
  } else {
    print("New values must be computed locally in order to do another iteration.")
  }
}

if (!is.null(error_message)) {
  message(error_message)
}

# Clear variables
rm(list = ls())