############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

data_init_poi_reg <- function(man_wd,nodeid,expath="") {
  
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
  
  # Handles missing values, if any
  source("Data_node_core_missingvalues.R")
  missing_value_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath)
  
  # Expecting data file name like Data_node_1.csv where 1 is the variable k above
  # Construct file name according to node data
  # Assumes default parameters, like header and separator
  node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
  n <- nrow(node_data)
  
  # Verifying if weights are available. 
  source("Data_node_core_weights.R") 
  weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
  node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
  
  # Makes sure the outcome variable is properly coded as 0s and 1s.
  #if(!all(unique(node_data$out1) %in% c(0,1))){
  #  stop("The outcome variable (out1) contains values that are different from 0 and 1, which isn't allowed.")
  #}
    
  # Fitting local model to generate an initial local estimator --------------
  fit <- glm(out1 ~ ., data=node_data, family="poisson", weights = node_weights)
  coefs <- as.vector(fit$coefficients)
  
  # Exporting local estimator and sample size -------------------------------
  
  length(n) <- length(coefs)
  write.csv(cbind(coefs, n),
            file=paste0(examplefilepath,"Data_node_",k,"_iter_0_output.csv"),
            row.names=FALSE)
  
  # Write variables names
  write.csv(colnames(node_data)[-1], file=paste0(examplefilepath, "Predictor_names_", k, ".csv"), row.names = FALSE)
  
  ## Remove all environment variables. 
  ## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
  rm(list = ls())
  
  return(TRUE)

}