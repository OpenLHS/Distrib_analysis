############### VERTICALLY DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- -1

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Retrieve source code
setwd("../../example_handler")
source("Data_node_call_log-regV_ex.R")
source("Response_node_call_iter_log-regV_ex.R")

# Run data node code
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

# Run coordination node code
vert_logistic_regression_example_coordnode_handler(man_lambda = lambda, expath = examplefilepath)

# Run data node code
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

