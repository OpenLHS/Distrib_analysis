############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Retrieve source code
setwd("../../example_handler")
source("Data_node_call_lin-reg_ex.R")
source("Coord_node_lin-reg_ex.R")

# Run data node code
linear_regression_example_datanode_handler(nodeid = 1, expath = examplefilepath)
linear_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

# Run coordination node code
linear_regression_example_coordnode_handler(expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

