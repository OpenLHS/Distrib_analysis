############### Distributed inference ####################
############### Covariate-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_iter_lin_reg <- function(man_wd,nodeid,expath) {

manualwd <- man_wd  
k <- nodeid
examplefilepath <- expath

# Libraries and functions ------------------------------------------------
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


# Import covariate-node data and intermediary quantities from response-node
node_data_k_unscale <- (as.matrix(read.csv(paste0(examplefilepath,"Data_node_",k, ".csv"))))
node_data_k <- scale(node_data_k_unscale)
n <- nrow(node_data_k)

c_system_k <- as.matrix(read.csv(paste0(examplefilepath,"Coord_node_primerA_for_data_node_",k ,".csv"))[,1])
eta <- as.numeric(read.csv(paste0(examplefilepath,"Coord_node_primerA_for_data_node_",k ,".csv"))[1,2])

S_inv <- reconstruct_from_upper_tri(readRDS(paste0(examplefilepath,"Coord_node_primerB_for_data_node_",k ,".rds")), nrow(node_data_k))

# Computations of parameter estimates
Id <- diag(nrow = n)
One <- rep(1, n)
M <- Id - 1/n*One%*%t(One)
MX <- M%*%node_data_k_unscale
beta_node_k <- solve(t(MX)%*%MX)%*%t(MX)%*%c_system_k

# Computations of standard errors
W <- diag(apply(node_data_k_unscale, 2, sd), nrow = ncol(node_data_k_unscale))
Winv <- diag(1/apply(node_data_k_unscale, 2, sd), nrow = ncol(node_data_k_unscale))
Idpk <- diag(nrow = ncol(node_data_k_unscale))

err_node_k <- sqrt(diag(
  Winv%*%( (1/eta)*Idpk - (1/eta)*t(node_data_k)%*%S_inv%*%node_data_k )%*%Winv
))

p_vals <- 2*(1 - pnorm(abs(beta_node_k)/err_node_k))

# Exporting final results at covariate-node k ------------------------------------------

write.csv(data.frame(coefs=beta_node_k,std_error=err_node_k,two_sided_pvalue=p_vals),
          file=paste0(examplefilepath,"Data_node_",k,"_results.csv"), row.names=colnames(node_data_k))

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)

}
