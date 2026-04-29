############### VERTICALLY DISTRIBUTED RIDGE-PENALIZED BINARY REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# If you do not want to run the privacy check, specify it here.
# Default is at YES (privacy <- 1), but you can modify for NO (put privacy <- 0)).
privacy <- 1

# If you want to use a specific seed for the privacy check, specify it here.
# If you do so, all nodes will use the same seed for their privacy check.
# Else, no seed will be used
manualseed <- -1

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
setwd("../../../example_handler")
source("Data_node_call_bin-regV_ex.R")

### Run data node code
vert_binary_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

### Run coordination node code
# Verifying if there is a coordination node (response-node) data file present
nb_node1_files <- length(list.files(path=examplefilepath, pattern="Data_node_1.csv"))
nb_node_output_files <- length(list.files(path=examplefilepath, pattern="Data_node_[[:digit:]]+_init_output.rds"))

if (nb_node1_files==1 & nb_node_output_files>0) {
  setwd(this.dir())
  setwd("../../../generic_code")
  source("Response_node_init_iter_bin-regV.R")
  response_bin_reg(man_lambda = lambda, expath = examplefilepath, model_choice = "probit")
  
  if(privacy==1){
    setwd(this.dir())
    setwd("../../generic_code_probit")
    source("Response_node_optional_confidentiality_probit.R")
    
    for (k in 2:(nb_node_output_files+1)){
      privacy_check_ck2_complete(k=k,expath = examplefilepath,man_seed = manualseed)
    }
  }
} else {
  stop("Node 1 data file missing or no output file from other nodes found")
}

# Run data node code
vert_binary_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

