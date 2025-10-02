############### VERTICALLY DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- -1

# If you want to manually set the parameter eta, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
eta <- -1

# If you want to use a specific seed for the privacy check, specify it here.
# If you do so, all nodes will use the same seed for their privacy check.
# If commented, no seed will be used
manualseed <- -1

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Retrieve source code
setwd("../../example_handler")
source("Data_node_call_log-regV_ex.R")
source("Response_node_call_iter_log-regV_ex.R")

# Run covariate node code
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

# Run response node code
vert_logistic_regression_example_coordnode_handler(man_lambda = lambda, man_eta = eta, expath = examplefilepath, man_seed = manualseed)

# Run covariate node code for results
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

