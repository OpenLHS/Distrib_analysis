############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Set working directory automatically
library(this.path)
setwd(this.dir())

# Retrieve current working directory
examplefilepath <- paste0(getwd(), "/")

# Run coordination node code
source("../../../../generic_code/example_handler/Coord_node_lin-reg_ex.R")
linear_regression_example_coordnode_handler(expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())
	
