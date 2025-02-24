############### DISTRIBUTED COX MODEL ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("survival")          # Contains the core survival analysis routines
library(MASS)                # Functions for matrix manipulation (ginv)

coord_call_add_iter_cox_reg <- function(man_wd=-1, man_t=-1){
  
  # Can be adjusted as needed  
  alpha <- 0.05
  
  # No modifications should be needed below this
  # -------------------------------------------------------------------------
  
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
  K=length(list.files(pattern="Times_[[:digit:]]+_output.csv"))
  
  # If first tration - some more initialization
  if (t == 1){
    
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
  if (file.exists((paste0("sumExp", K, "_output_", t, ".csv")))){
    
    # Get old beta
    beta <-  read.csv(paste0("Beta_", t-1, "_output.csv"))
    nbBetas <- dim(beta)[1]
    
    # Read files and sum values
    for(i in 1:K){
      
      # Retrieve data from local sts
      sumExp <- read.csv(paste0("sumExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumExp <- matrix(as.numeric(as.matrix(sumExp[-1, ])), ncol = 1, byrow = FALSE)
      
      sumZqExp <- read.csv(paste0("sumZqExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumZqExp <- matrix(as.numeric(as.matrix(sumZqExp[-1, ])), ncol = nbBetas, byrow = FALSE)
      
      sumZqZrExp <- read.csv(paste0("sumZqZrExp", i, "_output_", t, ".csv"), header = FALSE, blank.lines.skip = FALSE)
      sumZqZrExp <- array(as.numeric(as.matrix(sumZqZrExp[-1, ])), dim = c(nbBetas, nbBetas, ncol(sumZqZrExp)))
      
      # Initialize global matrices if first tration
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
    
    # Wrt in CSV
    write.csv(beta, file=paste0("Beta_", t, "_output.csv"), row.names = FALSE)
    
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
    Predictor_names <- read.csv("Global_Predictor_names.csv")
    
    rownames(output) <- Predictor_names$x[-(1:2)]
    
    # Wrt the output to a CSV file
    write.csv(output, file = paste0("Results_iter_", t, ".csv"), quote = FALSE, row.names = TRUE)
    
    
    if (!is.null(error_message)) {
      message(error_message)
    }
    
    # Clear variables
    rm(list = ls())
  
  }
}


