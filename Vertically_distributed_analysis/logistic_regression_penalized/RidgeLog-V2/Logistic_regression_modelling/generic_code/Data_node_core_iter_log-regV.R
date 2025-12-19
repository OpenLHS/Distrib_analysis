###############  Distributed predictive analytics ####################
############### Covariate-node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_iter_log_reg <- function(man_wd,nodeid,expath) {
  
  manualwd <- man_wd  
  k <- nodeid
  examplefilepath <- expath
  
  
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
  
  
  #Import covariate-node data and intermediary quantities from response-node
  node_data_k_unscale <- (as.matrix(read.csv(paste0(examplefilepath,"Data_node_",k, ".csv"))))
  node_data_k <- scale(node_data_k_unscale)
  n <- nrow(node_data_k)
  
  c_system_k <- as.matrix(read.csv(paste0(examplefilepath,"Coord_node_primerA_for_data_node_",k ,".csv"))[,1])

  #Computations of parameter estimates
  t_node_data_k <-t(node_data_k)
  q <- qr(t_node_data_k)
  node_data_k_indep <- t_node_data_k[,q$pivot[seq(q$rank)]]
  
  beta_node_k <- solve(t(node_data_k_indep),c_system_k[q$pivot[seq(q$rank)]])
  beta_node_k_adjusted <- beta_node_k/sapply(as.data.frame(node_data_k_unscale), sd)

  
  
  # Exporting final results at covariate-node k ------------------------------------------
  
  write.csv(data.frame(coefs_scaled=beta_node_k,coefs_originalscale=beta_node_k_adjusted),
            file=paste0(examplefilepath,"Data_node_",k,"_results.csv"), row.names=colnames(node_data_k))
  
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)
  
}