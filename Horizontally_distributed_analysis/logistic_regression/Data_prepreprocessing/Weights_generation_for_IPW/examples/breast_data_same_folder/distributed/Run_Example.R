############### DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# Choose the number of iterations you want to run (only available for "same_folder" examples)
nb_iter <- 8

# If you do not want to use a threshold for the probabilities estimated, input 0 here.
# Threshold value should be between 0 and 0.5. See details in the summary.
manualthresh <- 0.01

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

for(replicate in 1:nb_iter){
  
  # Run data node code
  setwd(this.dir())
  source("../../example_handler/Data_node_call_log-reg_ex.R")
  logistic_regression_IPW_example_datanode_handler(nodeid = 1, expath = examplefilepath, man_thresh = manualthresh)
  logistic_regression_IPW_example_datanode_handler(nodeid = 2, expath = examplefilepath, man_thresh = manualthresh)
  logistic_regression_IPW_example_datanode_handler(nodeid = 3, expath = examplefilepath, man_thresh = manualthresh)
  
  # Run coordination node code
  setwd(this.dir())
  source("../../example_handler/Coord_node_call_iter_log-reg_ex.R")
  logistic_regression_IPW_example_coordnode_handler(expath = examplefilepath)
  
}


## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

