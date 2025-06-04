############### DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# Choose the number of iterations you want to run (only available for "same_folder" examples)
nb_iter <- 8

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Retrieve source code
setwd("../../example_handler")
source("Data_node_call_log-reg_ex.R")
source("Coord_node_call_iter_log-reg_ex.R")

for(replicate in 1:nb_iter){
  
  # Run data node code
  logistic_regression_example_datanode_handler(nodeid = 1, expath = examplefilepath)
  logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)
  logistic_regression_example_datanode_handler(nodeid = 3, expath = examplefilepath)
  
  # Run coordination node code
  logistic_regression_example_coordnode_handler(expath = examplefilepath)
  
}


## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

