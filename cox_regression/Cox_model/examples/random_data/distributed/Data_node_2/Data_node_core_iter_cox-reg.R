############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")
library("survminer")

data_iter_cox_reg <- function(man_wd, nodeid, iterationseq) {
  
  manualwd <- man_wd
  k <- nodeid
  t <- iterationseq 
  
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
  
  # Find number of Betas (covariates)
  nbBetas <- dim(node_data)[2]-2
  
  # ------------------------- First iteration only CODE STARTS HERE ------------------------
  if(t==0){
    
    # Read data
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
    
  } 
  
  # ------------------------- All iterations CODE STARTS HERE ------------------------
  
  # Read data needed to compute next value of betak
  beta <-  read.csv(paste0("Beta_", t, "_output.csv"))
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
  write.csv(sumExp, file=paste0("sumExp",k,"_output_", t+1,".csv"),row.names = FALSE,na="")
  write.csv(sumZqExp, file=paste0("sumZqExp",k,"_output_", t+1,".csv"),row.names = FALSE,na="")
  
  # Write in csv for 3D matrix (a bit more complex than 2d)
  list_of_matrices <- lapply(seq_len(dim(sumZqZrExp)[3]), function(i) sumZqZrExp[,,i])
  list_of_vectors <- lapply(list_of_matrices, as.vector)
  combined_matrix <- do.call(cbind, list_of_vectors)
  write.csv(combined_matrix, file = paste0("sumZqZrExp",k,"_output_", t+1,".csv"), row.names = FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
