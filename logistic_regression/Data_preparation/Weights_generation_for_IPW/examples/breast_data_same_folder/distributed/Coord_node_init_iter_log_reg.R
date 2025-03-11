############### Distributed inference ####################
############### Coordinating node code (t = 1) ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

coord_init_iter_log_reg <- function(man_wd=-1) {

manualwd <- man_wd
  
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
K <- length(list.files(pattern="Data_node_[[:digit:]]+_iter_0_W_output.csv"))
p <- 0 
k <- 1
Settings <- read.csv(paste0("Local_Settings_" ,k, ".csv"))
Pred_names <- Settings[,1]
Threshold <- Settings[1,2]
node_1 <- read.csv(paste0("Data_node_", k, "_iter_0_W_output.csv"))
beta_sa <- rep(0, nrow(node_1))
n <- 0

for (k in 1:K) { 
  node_k <- read.csv(paste0("Data_node_", k, "_iter_0_W_output.csv"))
  OtherSettings <- read.csv(paste0("Local_Settings_" ,k, ".csv"))
  Same_names <- OtherSettings[,1]
  Same_Threshold <- OtherSettings[1,2]
  
  if(!all(Pred_names==Same_names)){
    stop("Node data files seems to have different column structure which may yield wrong results. \n Make sure each node uses the same variable names and the same order in the data file before running this algorithm.")
  }
  
  if(!Threshold==Same_Threshold){
    stop("Node data files seems to use different threshold values for probabilities, which may yield incoherent results. \n Make sure each node uses the same threshold before running this algorithm.")
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
          file="Coord_node_iter_1_W_primer.csv", row.names=FALSE)

# Exporting global settings
length(Threshold) <- length(Pred_names)
globalinfo <- cbind(Pred_names, Threshold)
colnames(globalinfo)[1] <- "Predictor_names"
colnames(globalinfo)[2] <- "Prob_threshold"
write.csv(globalinfo, file="Global_Settings.csv", row.names=FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
