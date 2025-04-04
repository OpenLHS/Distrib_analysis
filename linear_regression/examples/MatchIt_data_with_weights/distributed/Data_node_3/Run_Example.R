############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Set working directory automatically
library(this.path)
setwd(this.dir())

# Retrieve current working directory
examplefilepath <- paste0(getwd(), "/")

# Run data node code
source("../../../example_handler/Data_node_call_lin-reg_ex.R")
linear_regression_example_datanode_handler(nodeid = 3, expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())
	
