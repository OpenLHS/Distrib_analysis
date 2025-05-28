############### VERTICALLY DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Set number of nodes 
K <- 2

# No modifications should be required below this point
###################################################### 

# Allow to set working directory automatically
library(this.path)

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Run pooled code
setwd(this.dir())
source("../../example_handler/PoolingOrg_code_log-regV_ex.R")
vert_logistic_regression_example_pooled_handler(expath = examplefilepath, man_nnodes = K)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

