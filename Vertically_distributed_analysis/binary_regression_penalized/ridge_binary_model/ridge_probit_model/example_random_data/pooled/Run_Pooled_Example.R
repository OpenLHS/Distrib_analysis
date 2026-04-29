############### VERTICALLY DISTRIBUTED RIDGE-PENALIZED BINARY REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

model_choice <- "probit"

# Set number of nodes 
K <- 2

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- -1

# No modifications should be required below this point
###################################################### 

# Allow to set working directory automatically
library(this.path)

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Retrieve source code
setwd("../../../example_handler")
source("PoolingOrg_code_bin-regV_ex.R")

# Run pooled code
vert_binary_regression_example_pooled_handler(man_nnodes = K, man_lambda = lambda, expath = examplefilepath,model_choice=model_choice)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

