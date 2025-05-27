############### DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Run coordination node code
setwd(this.dir())
source("../../../example_handler/Coord_node_call_iter_log-reg_ex.R")
logistic_regression_example_coordnode_handler(expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

