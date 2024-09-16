############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")
library("survminer")

#' @title calculate_local_values
#'
#' @description This function calculates the parameters needed for the global first and second derivative.
#'
#' @param man_wd Parameter for manual working directory setting, integer.
#' @param nodeid Site number, integer.
#' @param nodebetas Number of covariates (betas), integer.
#' @param nodenumber Iteration number, integer.
#' 
#' This function generates the following files:
#' - sumExpk_output_it.csv, which is the sum of exp(beta*z) for each subject in the risk set at the i-th distinct event time.
#' - sumZqExpk_output_it.csv, which isthe sum of zqexp(beta*z) for each subject in the risk set at the i-th distinct event time.
#' - sumZqZrExpk_output_it.csv, which is the sum of zrzqexp(beta*z) for each subject in the risk set at the i-th distinct event time.

calculate_local_values <- function(man_wd=-1,nodeid=-1, nodebetas=-1, nodenumber=-1) {
  
  manualwd <- man_wd
  k <- nodeid
  nbBetas <- nodebetas
  max_number <- nodenumber
  
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
  beta <-  read.csv(paste0("Beta_", max_number, "_output.csv"))
  Rik <- read.csv(paste0("Rik", k, ".csv"), header = FALSE, blank.lines.skip = FALSE)
  Rik <- Rik[-1, ]
  
  # Create the sumExp, sumZqExp and sumZqZrExp matrix
  sumExp <- numeric(nrow(Rik))
  sumZqExp <- matrix(0, nrow = nrow(Rik), ncol = nbBetas)
  sumZqZrExp <- array(0, dim = c(nbBetas, nbBetas, nrow(Rik)))
  
  # Loop over rows of Rik
  for (i in 1:nrow(Rik)) {
    
    # Get id of people still in the study
    indices <- as.numeric(unlist(Rik[i, ])[unlist(Rik[i, ]) != ""])
    
    if(length(indices) > 0){
      
      # Get covariates of subjects
      z_matrix <- node_data[indices, 3:ncol(node_data)]
      
      # Convert to matrix to use sweep function
      z_matrix <- as.matrix(z_matrix)
      beta <- as.matrix(beta)

      # Beta * z
      beta_z <- sweep(z_matrix, 2, beta, "*")
      beta_z_sum <- rowSums(beta_z)
      
      # 1 - exp(beta*z)
      exp_beta_z <- exp(beta_z_sum)
      
      # 2 - zq*exp(beta*z)
      exp_beta_z_matrix <- matrix(rep(exp_beta_z, ncol(z_matrix)), ncol = ncol(z_matrix), byrow = FALSE)
      z_exp_beta_z <-  z_matrix * exp_beta_z_matrix
      
      # 3 - zr*zq*exp(beta*z)
      outer_product_list <- lapply(1:nrow(z_matrix), function(i) {
        z_matrix[i, ] %*% t(z_matrix[i, ])
      })
      
      result_array <- array(unlist(outer_product_list), dim = c(ncol(z_matrix), ncol(z_matrix), nrow(z_matrix)))

      zr_zq_beta <- array(0, dim = c(ncol(z_matrix), ncol(z_matrix), nrow(z_matrix)))
      zr_zq_beta <- array(unlist(lapply(seq_along(exp_beta_z), function(u) exp_beta_z[u] * result_array[,,u])), dim(result_array))
      
      # Update sumExp, sumZqExp, and sumZqZrExp
      sumExp[i] <- sum(exp_beta_z)
      sumZqExp[i, ] <- colSums(z_exp_beta_z)
      sumZqZrExp[, , i] <- apply(zr_zq_beta, c(1, 2), sum)
    }
    else {
      sumExp[i] <- 0
      sumZqExp[i, ] <- rep(0, nbBetas)
      sumZqZrExp[, , i] <- matrix(0, nrow = nbBetas, ncol = nbBetas)
    }
  }

  # Write in csv
  write.csv(sumExp, file=paste0("sumExp",k,"_output_", max_number+1,".csv"),row.names = FALSE,na="")
  write.csv(sumZqExp, file=paste0("sumZqExp",k,"_output_", max_number+1,".csv"),row.names = FALSE,na="")
  
  # Write in csv for 3D matrix (a bit more complex than 2d)
  list_of_matrices <- lapply(seq_len(dim(sumZqZrExp)[3]), function(i) sumZqZrExp[,,i])
  list_of_vectors <- lapply(list_of_matrices, as.vector)
  combined_matrix <- do.call(cbind, list_of_vectors)
  write.csv(combined_matrix, file = paste0("sumZqZrExp",k,"_output_", max_number+1,".csv"), row.names = FALSE)
  
  rm(list = ls())
  
  return(TRUE)
}
