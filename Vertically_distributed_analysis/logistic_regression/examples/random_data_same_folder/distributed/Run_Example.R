############### VERTICALLY DISTRIBUTED LOGISTIC REGRESSION ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Allow to set working directory automatically
library(this.path)

# Set this flag to "TRUE" if you want to verify that an infinite number of solutions exists.
# Otherwise, set this flag to "FALSE"
PrivacyCheckFlag <- TRUE

########### THE FOLLOWING ONLY APPLIES IF PRIVACYCHECKFLAG IS SET TO "TRUE"
########### IMPORTANT: INDICATE HERE AS VECTOR THE INDEX OF STANDARDS ERRRORS (OR P-VALUES) DISCLOSED.
###########            THE INDEX COMPONENTS MUST REMAIN BETWEEN 1 AND THE NUMBER OF COVARIATES AT NODE K.
###########              EXAMPLE: pk=5 and you want to disclose first and last standard errors, then index_se <- c(1,5).
###########              LEAVE NA IF NONE DISCLOSED.
index_se <- c(1:6)

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- -1

# No modifications should be required below this point
###################################################### 

# Retrieve current working directory
setwd(this.dir())
examplefilepath <- paste0(getwd(), "/")

# Run covariate node code
setwd(this.dir())
source("../../example_handler/Data_node_call_log-regV_ex.R")
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

# Run response node code
setwd(this.dir())
source("../../example_handler/Response_node_call_iter_log-regV_ex.R")
vert_logistic_regression_example_coordnode_handler(man_lambda = lambda, expath = examplefilepath)

# Run covariate node code for results
vert_logistic_regression_example_datanode_handler(nodeid = 2, expath = examplefilepath)

if(PrivacyCheckFlag){
  # Run covariate node code
  setwd(this.dir())
  source("../../example_handler/Data_node_privacy_call_log-regV_ex.R")
  vert_logistic_regression_example_privacy_handler(nodeid = 2, man_index_se = index_se, expath = examplefilepath)
}

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

