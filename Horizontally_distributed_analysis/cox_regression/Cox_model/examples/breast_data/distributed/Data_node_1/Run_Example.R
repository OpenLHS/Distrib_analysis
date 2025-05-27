############### DISTRIBUTED COX MODEL ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# For "classic" variance estimation, set this flag to FALSE
# For "robust" variance estimation, set this flag to TRUE
RobustVarianceFlag <- FALSE

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Run data node code
setwd(this.dir())
source("../../../example_handler/Data_node_call_cox-reg_ex.R")
cox_regression_example_datanode_handler(nodeid = 1, Robust = RobustVarianceFlag, expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

