############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines
library(MASS)                # Functions for matrix manipulation (ginv)

coord_call_add_iter_cox_reg <- function(man_wd=-1, man_t=-1, expath=""){
  
  # Can be adjusted as needed  
  alpha <- 0.05
  
  # No modifications should be needed below this
  # -------------------------------------------------------------------------
  
  examplefilepath <- expath
  
  # If you want to skip the automated working directory setting, input 1 here. 
  # If you do so, make sure the working directory is set correctly manualy.
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
  
  t <- man_t
  
  # Initialise error messages
  error_message <- NULL
  
  # Calculate number of data nodes from files fiting the pattern in the working directory
  # This assumes unique event times outputs have a name like Times_[[:digit:]]+_output.csv
  K=length(list.files(path=examplefilepath, pattern="Times_[[:digit:]]+_output.csv"))
  
  # If first iteration - some more initialization
  if (t == 1){
    
    sumWZrGlobal <- 0
    
    for(i in 1:K){
      Wprimek <- read.csv(paste0(examplefilepath, "Wprime",i,".csv"))[,1]
      if(i == 1){
        Wprime <- vector(mode = "numeric", length = length(Wprimek))
      }
      Wprime <- Wprime + Wprimek
      
      sumWZr <- read.csv(paste0(examplefilepath, "sumWZr", i, ".csv"))
      sumWZrGlobal <- sumWZrGlobal + colSums(sumWZr) 
    }

    write.csv(Wprime, file = paste0(examplefilepath, "WprimeGlobal.csv"), row.names = FALSE)
    write.csv(sumWZrGlobal, file=paste0(examplefilepath, "sumWZrGlobal.csv"), row.names = FALSE) 
  }
  
  # Verification to make sure new data is used to compute beta
  if (file.exists((paste0(examplefilepath, "sumWExp", K, "_output_", t, ".csv")))){
    
    # Get old beta
    beta <-  read.csv(paste0(examplefilepath, "Beta_", t-1, "_output.csv"))
    nbBetas <- dim(beta)[1]
    
    # Read files and sum values
    for(i in 1:K){
      
      # Retrieve data from local sts
      sumWExp <- read.csv(paste0(examplefilepath, "sumWExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE) 
      sumWExp <- matrix(as.numeric(as.matrix(sumWExp[-1, ])), ncol = 1, byrow = FALSE)
      
      sumWZqExp <- read.csv(paste0(examplefilepath, "sumWZqExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumWZqExp <- matrix(as.numeric(as.matrix(sumWZqExp[-1, ])), ncol = nbBetas, byrow = FALSE)
      
      sumWZqZrExp <- read.csv(paste0(examplefilepath, "sumWZqZrExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumWZqZrExp <- array(as.numeric(as.matrix(sumWZqZrExp[-1, ])), dim = c(nbBetas, nbBetas, ncol(sumWZqZrExp)))
      
      # Initialize global matrices if first iteration
      if(i == 1){
        sumWExpGlobal <- matrix(0, nrow = nrow(sumWExp), ncol = ncol(sumWExp))
        sumWZqExpGlobal <- matrix(0, nrow = nrow(sumWZqExp), ncol = ncol(sumWZqExp))
        sumWZqZrExpGlobal <- array(0, dim = dim(sumWZqZrExp))
      }
      
      # Sum values
      sumWExpGlobal <- sumWExpGlobal + sumWExp
      sumWZqExpGlobal <- sumWZqExpGlobal + sumWZqExp
      sumWZqZrExpGlobal <- sumWZqZrExpGlobal + sumWZqZrExp
    }
    
    # Calculate first derivative -------------------------------------------
    WprimeGlobal <- as.matrix(read.csv(paste0(examplefilepath, "WprimeGlobal.csv")))
    sumWZrGlobal <- as.matrix(read.csv(paste0(examplefilepath, "sumWZrGlobal.csv")))
    
    WZrExp_Divided_by_WExp <- sumWZqExpGlobal/do.call(cbind, replicate(nbBetas, sumWExpGlobal, simplify = FALSE))
    Norm_Times_WZrExp_Divided_by_WExp <- do.call(cbind, replicate(nbBetas, WprimeGlobal, simplify = FALSE)) * WZrExp_Divided_by_WExp
    sum_Norm_Times_WZrExp_Divided_by_WExp <- colSums(Norm_Times_WZrExp_Divided_by_WExp)
    
    lr_beta <- sumWZrGlobal - sum_Norm_Times_WZrExp_Divided_by_WExp
    
    # Calculate second derivative ------------------------------------------
    lrq_beta <- matrix(NA, nrow = nbBetas, ncol = nbBetas)
    
    # a, b and c are the three division present in the equation
    for (i in 1:nbBetas) {
      for (j in 1:nbBetas) {
        a <- sumWZqZrExpGlobal[i, j, ] / sumWExpGlobal
        b <- sumWZqExpGlobal[, i] / sumWExpGlobal
        c <- sumWZqExpGlobal[, j] / sumWExpGlobal
        
        value_ij <- a - b * c
        Norm_times_value_ij <- WprimeGlobal * value_ij
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
    write.csv(beta, file=paste0(examplefilepath, "Beta_", t, "_output.csv"), row.names = FALSE)
    
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
    Predictor_names <- read.csv(paste0(examplefilepath, "Global_Settings.csv"), stringsAsFactors=FALSE)[,1]
    Robust <- read.csv(paste0(examplefilepath, "Global_Settings.csv"), stringsAsFactors=FALSE)[1,2]
    
    rownames(output) <- Predictor_names[-(1:2)]
    
    # Write the output to a CSV file
    write.csv(output, file = paste0(examplefilepath, "Results_iter_", t, ".csv"), quote = FALSE, row.names = TRUE)
    if(Robust){
      write.csv(fisher_info, file = paste0(examplefilepath, "Fisher_", t, ".csv"), quote = FALSE, row.names = FALSE)  
    }
    
    
    # Files and code for robust se -------------------------------------------
    if(Robust){
      # Iteration specific
      if(t>1){
        # Compute zbar ri (also known as \hat{a} in Collett)
        zbarri <- sumWZqExpGlobal/do.call(cbind, replicate(nbBetas, sumWExpGlobal, simplify = FALSE))
        
        write.csv(sumWExpGlobal, file = paste0(examplefilepath, "sumWExpGlobal_output_", t-1, ".csv"), row.names = FALSE)
        write.csv(as.data.frame(zbarri), file = paste0(examplefilepath, "zbarri_", t-1, ".csv"), quote = FALSE, row.names = FALSE)
      }
      
      
      if(t>2){ 
        # Sum over sites
        for(k in 1:K){
          # zbar ri / sum(exp(b*z)): global 
          x_invWExp_k <- read.csv(paste0(examplefilepath, "zbarri_inverseWExp_", k, "_output_", t-2, ".csv"))
          if(k == 1){
            x_invWexpGlobal <- matrix(0, nrow = nrow(x_invWExp_k), ncol = ncol(x_invWExp_k))
          }
          x_invWexpGlobal <- x_invWexpGlobal + x_invWExp_k
          
          # 1 / sum(exp(b*z)): global
          invWExp_k <- read.csv(paste0(examplefilepath, "inverseWExp_", k, "_output_", t-2, ".csv"))
          if(k == 1){
            invWExpGlobal <- matrix(0, nrow = nrow(invWExp_k), ncol = ncol(invWExp_k))
          }
          invWExpGlobal <- invWExpGlobal + invWExp_k
        }
        
        # Write csv
        write.csv(x_invWexpGlobal, file = paste0(examplefilepath, "zbarri_inverseWExp_Global_output_", t-2, ".csv"), row.names = FALSE) 
        write.csv(invWExpGlobal, file = paste0(examplefilepath, "inverseWExp_Global_output_", t-2, ".csv"), row.names = FALSE)
      }
      
      if(t>3){
        # Compute Robust SE
        RobustSE2 <- vector(mode = "numeric", length = nbBetas)
        for(i in 1:K){
          DDk <- as.vector(read.csv(paste0(examplefilepath, "DD", i, "_output_", t-3, ".csv"))[,1])
          RobustSE2 <- RobustSE2 + DDk
        }
   
        RobustSE <- sqrt(RobustSE2)
             
        # Create output
        oldBeta <- read.csv(paste0(examplefilepath, "Beta_", t-3, "_output.csv"))
        Robustz <- abs(oldBeta/RobustSE)
        RobustP <- 2*(1-pnorm(Robustz$x))
        
        alphaz <- abs(qnorm(alpha/2))
        
        # Exporting final results
        output <- cbind(oldBeta, exp(oldBeta), exp(-oldBeta),  exp(oldBeta - RobustSE*alphaz), exp(oldBeta + RobustSE*alphaz), RobustSE, RobustP)
        output <- format(output, digits = 6, nsmall = 6)
        colnames(output) <- c(" coef", " exp(coef)", " exp(-coef)", " lower .95", " upper .95", " se(coef)", " Pr(>|z|)")
        Predictor_names <- read.csv(paste0(examplefilepath, "Global_Settings.csv"), stringsAsFactors=FALSE)[,1]
        
        rownames(output) <- Predictor_names[-(1:2)]
        
        write.csv(output, file = paste0(examplefilepath, "RobustResults_iter_", t-3, ".csv"))
      }
    }
    
    if (!is.null(error_message)) {
      message(error_message)
    }
    
    # Clear variables
    rm(list = ls())
  
  }
}


