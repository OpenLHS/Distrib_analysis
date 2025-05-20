############### DISTRIBUTED COX MODEL ####################
############### Local site code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")

data_iter_cox_reg <- function(man_wd, nodeid, iterationseq, robflag, expath) {
  
  manualwd <- man_wd
  k <- nodeid
  t <- iterationseq
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
  
  # Read data
  if(!file.exists(paste0(examplefilepath, "Data_node_grouped_", k ,".csv"))){
    warning("Attempt to find a file with grouped data failed and thus this will use ungrouped data. Be aware that this algorithm is based on WebDisco which is deemed non-confidential for ungrouped data.")
    node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
  } else {
    node_data <- read.csv(paste0(examplefilepath, "Data_node_grouped_", k, ".csv"))
  }
  
  # Compute n
  n = nrow(node_data)
  
  # Verifying if weights are available. 
  source("Data_node_core_weights.R") 
  weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
  node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
  
  # Find number of Betas (covariates)
  nbBetas <- dim(node_data)[2]-2
  
  # ------------------------- First iteration only CODE STARTS HERE ------------------------
  if(t==0){
    
    # Read data
    Dlist <- read.csv(paste0(examplefilepath, "Global_times_output.csv"))
    Dlist <- Dlist$x
    
    # Dik: list containing the index sets of subjects with observed events at time i
    # Wprime: total weight of the index sets of subjects with observed events at time i
    Dik <- vector("list", length(Dlist))
    Wprime_list <- vector("list", length(Dlist)) 
    for (i in seq_along(Dlist)) {
      indices <- which(node_data$time == Dlist[i] & node_data$status == 1)
      if (length(indices) > 0) {
        Dik[[i]] <- indices
        Wprime_list[[i]] <- node_weights[indices]
      } else {
        Dik[[i]] <- 0
        Wprime_list[[i]] <- 0
      }
    }
    
    # Rik: list containing the id of subjects still at risk at time i
    Rik <- vector("list", length(Dlist))
    # Rik_comp: list containing the id of subjects that died by time i or at time i (censored times are thus not included)
    Rik_comp <- vector("list", length(Dlist))
    for (i in seq_along(Dlist)) {
      Rik[[i]] <- which(node_data$time >= Dlist[i])
      Rik_comp[[i]] <- which(node_data$time <= Dlist[i] & node_data$status==1)      
    }
    
    # Sum of covariates*weight associated with subjects with observed events at time i 
    sumWZr <- matrix(0, nrow = length(Dik), ncol = nbBetas)
    for (i in seq_along(Dik)) {
      indices <- Dik[[i]]
      for (x in 1:nbBetas) {
        current_sum <- sum(node_data[[3 + x - 1]][indices]*node_weights[indices])           
        sumWZr[i, x] <- ifelse(is.na(current_sum), 0, current_sum)      # if NA, put = 0 (might induce errors, but avoids crashing)
      }
    }
    
    # Summary and outputs -----------------------------------------------------
    
    # Function to convert NULL to a row of NAs of a specified length
    pad_with_na <- function(x, specified_length) {
      if (is.null(x)) {
        return(rep(NA, specified_length))
      } else {
        x[x == 0] <- NA
        length(x) <- specified_length
        return(x)
      }
    }
    
    # Convert Wprime
    max_length <- max(sapply(Wprime_list, function(x) if (is.null(x)) 0 else length(x)))
    padded_rows <- lapply(Wprime_list, pad_with_na, max_length)
    df <- as.data.frame(do.call(rbind, padded_rows))
    df[is.na(df)] <- 0
    
    # Wprimek
    Wprimek <- rowSums(df)
    
    # Convert Rik
    max_length <- max(sapply(Rik, function(x) if (is.null(x)) 0 else length(x)))
    padded_rows <- lapply(Rik, pad_with_na, max_length)
    df2 <- as.data.frame(do.call(rbind, padded_rows))
    
    # Convert Rik_comp
    max_length <- max(sapply(Rik_comp, function(x) if (is.null(x)) 0 else length(x)))
    padded_rows <- lapply(Rik_comp, pad_with_na, max_length)
    df3 <- as.data.frame(do.call(rbind, padded_rows))
    
    # Write
    write.csv(df2, file=paste0(examplefilepath, "Rik",k,".csv"),row.names = FALSE,na="")
    write.csv(df3, file=paste0(examplefilepath, "Rik_comp",k,".csv"),row.names = FALSE,na="")
    write.csv(sumWZr, file=paste0(examplefilepath, "sumWZr",k,".csv"),row.names = FALSE,na="")
    write.csv(Wprimek, file=paste0(examplefilepath, "Wprime",k,".csv"), row.names = FALSE, na="")
    
  } 
  
  # ------------------------- All iterations CODE STARTS HERE ------------------------
  
  # Read data needed to compute next value of betak
  beta <-  read.csv(paste0(examplefilepath, "Beta_", t, "_output.csv"))
  Rik <- read.csv(paste0(examplefilepath, "Rik", k, ".csv"), header = FALSE, blank.lines.skip = FALSE, stringsAsFactors=FALSE)
  Rik <- Rik[-1, ]
  Rik_comp <- read.csv(paste0(examplefilepath, "Rik_comp", k, ".csv"), header = FALSE, blank.lines.skip = FALSE, stringsAsFactors=FALSE)
  Rik_comp <- Rik_comp[-1, ]
  
  # Verifying if weights are available. 
  source("Data_node_core_weights.R") 
  weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
  node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
  
  # Create the sumWExp, sumWZqExp and sumWZqZrExp matrix
  sumWExp <- numeric(nrow(Rik))
  sumWZqExp <- matrix(0, nrow = nrow(Rik), ncol = nbBetas)
  sumWZqZrExp <- array(0, dim = c(nbBetas, nbBetas, nrow(Rik)))
  
  # Loop over rows of Rik
  for (i in 1:nrow(Rik)) {
    
    # Get id of people still in the study
    unlistedRik <- unlist(Rik[i, ], use.names = FALSE)
    indices <- as.numeric(unlistedRik[unlistedRik != ""])
    
    if(length(indices) > 0){
      
      # Get covariates of subjects
      z_matrix <- node_data[indices, 3:ncol(node_data)]
      
      # Convert to matrix to use sweep function
      z_matrix <- as.matrix(z_matrix)
      beta <- as.matrix(beta)
      
      # Beta * z
      beta_z <- sweep(z_matrix, 2, beta, "*")
      beta_z_sum <- rowSums(beta_z)
      
      # 1 - exp(beta*z), Wi*exp(beta*z)
      exp_beta_z <- exp(beta_z_sum)
      W_exp_beta_z <- node_weights[indices] * exp_beta_z
      
      # 2 - W*zq*exp(beta*z)
      W_exp_beta_z_matrix <- matrix(rep(W_exp_beta_z, ncol(z_matrix)), ncol = ncol(z_matrix), byrow = FALSE)
      W_z_exp_beta_z <-  z_matrix * W_exp_beta_z_matrix
      
      # 3 - W*zr*zq*exp(beta*z)
      outer_product_list <- lapply(1:nrow(z_matrix), function(i) {
        z_matrix[i, ] %*% t(z_matrix[i, ])
      })
      
      result_array <- array(unlist(outer_product_list), dim = c(ncol(z_matrix), ncol(z_matrix), nrow(z_matrix)))
      
      W_zr_zq_beta <- array(0, dim = c(ncol(z_matrix), ncol(z_matrix), nrow(z_matrix)))
      W_zr_zq_beta <- array(unlist(lapply(seq_along(W_exp_beta_z), function(u) W_exp_beta_z[u] * result_array[,,u])), dim(result_array))
      
      # Update sumWExp, sumWZqExp, and sumWZqZrExp
      sumWExp[i] <- sum(W_exp_beta_z)
      sumWZqExp[i, ] <- colSums(W_z_exp_beta_z)
      sumWZqZrExp[, , i] <- apply(W_zr_zq_beta, c(1, 2), sum)
    }
    else {
      sumWExp[i] <- 0
      sumWZqExp[i, ] <- rep(0, nbBetas)
      sumWZqZrExp[, , i] <- matrix(0, nrow = nbBetas, ncol = nbBetas)
    }
  }
  
  # Write in csv
  write.csv(sumWExp, file=paste0(examplefilepath, "sumWExp",k,"_output_", t+1,".csv"),row.names = FALSE,na="")
  write.csv(sumWZqExp, file=paste0(examplefilepath, "sumWZqExp",k,"_output_", t+1,".csv"),row.names = FALSE,na="")
  
  # Write in csv for 3D matrix (a bit more complex than 2d)
  list_of_matrices <- lapply(seq_len(dim(sumWZqZrExp)[3]), function(i) sumWZqZrExp[,,i])
  list_of_vectors <- lapply(list_of_matrices, as.vector)
  combined_matrix <- do.call(cbind, list_of_vectors)
  write.csv(combined_matrix, file = paste0(examplefilepath, "sumWZqZrExp",k,"_output_", t+1,".csv"), row.names = FALSE)
  
  # Files and code for robust se -------------------------------------------
  if(Robust){
    # Function to find which risk set to use
    find_Rik_index <- function(Individual, RiskSet, LastIndex = 1){
      
      Ind_Lost <- F
      index <- LastIndex
      for(ind in LastIndex:nrow(RiskSet)){
        Ind_Lost <- !(Individual %in% RiskSet[ind,])
        if(Ind_Lost){
          break
        }
        index <- ind
      }
      
      return(index)
    }
    
    if(t>1){
      # Create matrix that allows to switch between indiviaul row number and global row number
      Ind_to_Global <- matrix(0, nrow = nrow(node_data), ncol = 2) 
      
      Index <- 1 
      for(i in 1:nrow(Ind_to_Global)){
        Index <- find_Rik_index(i, Rik, Index)
        Ind_to_Global[i,] <- c(i, Index)
      }
      
      # Read data produced by coord 
      sumWExpGlobal <- read.csv(paste0(examplefilepath, "sumWExpGlobal_output_", t-1, ".csv"))
      zbarri <- read.csv(paste0(examplefilepath, "zbarri_", t-1, ".csv"))
      
      sumInverseWexp <- matrix(0, nrow = nrow(sumWExpGlobal), ncol = ncol(sumWExpGlobal))
      sumzbarrr_WExp <- matrix(0, nrow = nrow(sumWExpGlobal), ncol = ncol(zbarri))
      
      # Compute sum of individuals in rik' for each possible time: W/SUM[W*exp(b*z)] & W*zbar_rr/[W*exp(b*z)] 
      for(i in 1:nrow(Rik_comp)){
        
        # Find row number associated with individuals in rik'
        individuals <- as.numeric(Rik_comp[i,])
        individuals <- individuals[!is.na(individuals)]
        
        # Change line number for position in global time list
        global_row <- Ind_to_Global[individuals,2]
        
        # W/[W*exp(b*z)]
        sum_w_wexp <- 0
        
        # W*zbar_rr/[W*exp(b*z)]
        sum_wzbarrr_wexp <- 0
        
        # Only enter if there are subjects in current set
        if(length(global_row)>0)  {
          sumWExp_Values <- matrix(0, nrow = length(global_row), ncol = 1)
          sumWExp_Values <- sumWExpGlobal[global_row, 1] 
          
          weight_values <- matrix(0, nrow = length(global_row), ncol = 1)
          weight_values <- node_weights[individuals] 
          
          inverse <- weight_values/sumWExp_Values 
          sum_w_wexp <- sum(inverse)
          
          zbarrr_inverse  <- zbarri[global_row,]*inverse 
          sum_wzbarrr_wexp <- colSums(zbarrr_inverse)
          
        }
        
        sumInverseWexp[i,] <- sum_w_wexp 
        sumzbarrr_WExp[i,] <- sum_wzbarrr_wexp
      }
      
      # write in csv
      write.csv(as.data.frame(sumInverseWexp), file = paste0(examplefilepath, "inverseWExp_", k, "_output_", t-1, ".csv"), row.names = F)
      write.csv(as.data.frame(sumzbarrr_WExp), file = paste0(examplefilepath, "zbarri_inverseWExp_", k, "_output_", t-1, ".csv"), row.names = F)
      
    }
    
    if(t>2){
      # Compute Schoenfeld Residuals (See Collett chapter 4 for formula)
      sch_res <- matrix(0, nrow = nrow(node_data), ncol = nbBetas)
      
      Rik_index <- 1
      for(i in 1:nrow(node_data)){
        Rik_index <- find_Rik_index(i, Rik, Rik_index)
        sch_res[i,] <- node_weights[i]*node_data$status[i]*(as.numeric(node_data[i,3:ncol(node_data)]) - as.numeric(zbarri[Rik_index,]))
      }
      
      # Compute Score Residuals (See Collett chapter 4 for formula)
      old_beta <- read.csv(paste0(examplefilepath, "Beta_", t-2, "_output.csv"))[,1]
      z_matrix <- as.matrix(node_data[, 3:ncol(node_data)])
      
      # 2nd term
      exp_oldb_z <- node_weights * exp(z_matrix%*%old_beta) 
      mult_factor_zbar_exp <- read.csv(paste0(examplefilepath, "zbarri_inverseWExp_Global_output_", t-2, ".csv")) 
      
      # Expand factor
      expanded_mult_factor_zbar_exp <- mult_factor_zbar_exp[Ind_to_Global[,2], ]
  
      second_term <- exp_oldb_z*expanded_mult_factor_zbar_exp
      
      # 3rd term
      mult_factor_1_exp <- read.csv(paste0(examplefilepath, "inverseWExp_Global_output_", t-2, ".csv"))
      
      # Expand factor 
      expanded_mult_factor_1_exp <- mult_factor_1_exp[Ind_to_Global[,2], ]
      third_term <- exp_oldb_z[,1] * z_matrix * expanded_mult_factor_1_exp 
      
      sco_res <- sch_res + second_term - third_term 
      
      # Load Fisher's info from coord
      fisher_info <- read.csv(file = paste0(examplefilepath, "Fisher_", t-2, ".csv"))
      
      # Compute partial robust se (See Modeling Survival Data: Extending the Cox Model)
      Dk <- as.matrix(sco_res)%*%as.matrix(fisher_info)
      DDk <- t(Dk) %*% Dk
      
      # Write csv: Only the diagonal is sent to the Coord node
      write.csv(diag(DDk), file = paste0(examplefilepath, "DD", k, "_output_", t-2, ".csv"), row.names = FALSE, na="")
      
    }
  }
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
}
