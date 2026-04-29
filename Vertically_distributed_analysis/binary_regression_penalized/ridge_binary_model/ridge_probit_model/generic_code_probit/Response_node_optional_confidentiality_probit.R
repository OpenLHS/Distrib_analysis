############### VERTICALLY DISTRIBUTED RIDGE-PENALIZED BINARY REGRESSION ####################
############### Response-node code - Privacy check (Probit) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


# Libraries and rcpp functions needed for the procedure -----------------------

# Privacy check for response data -----------------------

privacy_check_ck2_complete <- function(man_wd=-1,k,expath = "",man_seed){
  
  # Libraries and rcpp functions needed for the procedure -----------------------

  library(Rcpp)
  library(RcppArmadillo)
  
  ### Construct symmetric matrix from upper triangle
  cppFunction('
  arma::mat reconstruct_from_upper_tri(const arma::vec& upper_tri, arma::uword n) {
    arma::mat A(n, n, arma::fill::zeros);
    arma::uword idx = 0;

    for (arma::uword j = 0; j < n; ++j) {
      for (arma::uword i = 0; i <= j; ++i) {
        A(i, j) = upper_tri(idx);      // fill the upper triangular part
        A(j, i) = upper_tri(idx++);    // fill the symmetric lower part
      }
    }

    return A;
  }
', depends = "RcppArmadillo")
  
  
  # SET UP -----------------------
  
  manualwd <- man_wd
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
      
      # no known means to automatically allocate node number
    } else {
      stop("The required conditions to automatically set the working directory are not met. See R file")
    }
  } else {
    print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
  }
  
  
  # Privacy check for response data - Procedure and computations -----------------------
  
  ###Prepare required data for privacy check
  eta <- readRDS(paste0(examplefilepath,"privacy_output.rds"))
  n <- length(eta)
  XXk <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath,"Data_node_", k, "_init_output.rds")), n)
  
  ### QR decomposition for local Gram matrix augmented with column of 1
  qrX <- qr(cbind(rep(1,n),XXk))
  
  ### Privacy check for each component 
  
  # Create progress bar so user know the method isn't stuck
  progressbar <- txtProgressBar(min=0, max = n, style = 3)
  pass_privacy <- rep(NA,n)
  for (i in 1:n) {
    ei <- rep(0,n)
    ei[i] <- 1
    qtv <- qr.qty(qrX, ei)
    pass_privacy[i] <- sum(qtv[(qrX$rank+1):n]^2)
    setTxtProgressBar(progressbar, i) 
  }
  
  count <- length(which(pass_privacy>1e-10))
  index_nosol <- which(pass_privacy<1e-10)
  
  # close progress bar
  close(progressbar) 
  
  # Print results of flips vs no flips
  cat(sprintf(paste0("Flippable coordinate signs with predictor-node ", k,"'s data: %d / %d\n"), count, n))
  
  if(count!=n){
    write.csv(data.frame(index_noflip=index_nosol),
              file=paste0(examplefilepath,"Index_NoFlip_",k ,".csv"), row.names=FALSE)
  }
  return(NULL)
}

