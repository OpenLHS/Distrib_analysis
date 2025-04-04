############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Run data node code
setwd(this.dir())
source("../../example_handler/Data_node_call_lin-reg_ex.R")
linear_regression_example_datanode_handler(nodeid = 1, expath = examplefilepath)
linear_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

# Run coordination node code
setwd(this.dir())
source("../../example_handler/Coord_node_lin-reg_ex.R")
linear_regression_example_coordnode_handler(expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

