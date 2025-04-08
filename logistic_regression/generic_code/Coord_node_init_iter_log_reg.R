############### Distributed inference ####################
############### Coordinating node code (t = 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_init_iter_log_reg <- function(man_wd=-1, expath="") {

manualwd <- man_wd
examplefilepath <- expath
  
# Importing data and computing initial simple averaging estimator ---------

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

# Extract node data ----------------------------------------------------------
K <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_iter_0_output.csv"))
p <- 0 
k <- 1
Pred_names <- read.csv(paste0(examplefilepath, "Predictor_names_" ,k, ".csv"))
node_1 <- read.csv(paste0(examplefilepath, "Data_node_", k, "_iter_0_output.csv"))
beta_sa <- rep(0, nrow(node_1))
n <- 0

for (k in 1:K) { 
  node_k <- read.csv(paste0(examplefilepath, "Data_node_", k, "_iter_0_output.csv"))
  Same_names <- read.csv(paste0(examplefilepath, "Predictor_names_" ,k, ".csv"))
  
  if(!all(Pred_names==Same_names)){
    stop("Node data files seems to have different column structure which may yield wrong results. \n Make sure each node uses the same variable names and the same order in the data file before running this algorithm.")
  }
  
  # Adding local estimators and sample sizes 
  beta_k <- node_k[,1]
  n_k <- node_k[1,2]
  beta_sa <- beta_sa + n_k * beta_k
  n <- n + n_k
}
# Computing the simple averaging estimator
beta_sa <- beta_sa/n

# Exporting simple averaging estimator to be sent to data nodes -----------

write.csv(data.frame(coefs=beta_sa),
          file=paste0(examplefilepath, "Coord_node_iter_1_primer.csv"), row.names=FALSE)

write.csv(Pred_names, file=paste0(examplefilepath, "Global_Predictor_names.csv"), row.names=FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
