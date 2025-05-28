############### Distributed inference ####################
############### Covariate-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

data_init_log_reg <- function(man_wd,nodeid) {
  
  manualwd <- man_wd 
  
  k <- nodeid

  # Importing data ----------------------------------------------------------
  
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

  
  # Expecting data file name like Data_node_k.csv where 1 is the variable k above
  # Construct file name according to node data
  # Assumes default parameters, like header and separator
  
  # Library and functions --------------------------------------------------
  library(Matrix)
  library(Rcpp)
  library(RcppArmadillo)
  ### Extract upper triangle symmetric matrix
  cppFunction('
  arma::vec extract_upper_tri(const arma::mat& A) {

    // Extract the upper triangular part including the diagonal
    arma::uword n = A.n_rows;
    arma::vec upper_tri(n * (n + 1) / 2);  // storage for upper triangular elements
    arma::uword idx = 0;

    for (arma::uword j = 0; j < n; ++j) {
      for (arma::uword i = 0; i <= j; ++i) {
        upper_tri(idx++) = A(i, j);  // store upper triangular elements
      }
    }

    return upper_tri;
  }
', depends = "RcppArmadillo")
  
  # Import and Verify condition over data --------------------
  node_data_k <- scale(as.matrix(read.csv(paste0("Data_node_", k, ".csv"))))
  if(any(is.na(node_data_k))){
    stop("The dataset seems to contain NA value(s). The method cannot be applied. 
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
  }
  
  # Verify working condition for the method
  if(rankMatrix(node_data_k)!=ncol(node_data_k)){
    stop("The condition over the rank of the data matrix is not met.")
  }

  # Exporting local Gram Matrix -------------------------------
  saveRDS(extract_upper_tri(node_data_k%*%t(node_data_k)), paste0("Data_node_",k,"_init_output.rds"), compress = TRUE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)

}