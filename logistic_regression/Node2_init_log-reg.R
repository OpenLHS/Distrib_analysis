############### Distributed inference ####################
############### Data node code (t = 0) ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

# Load package this.path to identify the script filename
# and deduce the node number.
# https://cran.r-project.org/package=this.path 
# https://cran.r-project.org/web/packages/this.path/this.path.pdf
library("this.path")

# Set data node number based on the filename. 
# This assumes a file with name like Node[[:digit:]]+_code_lin-reg.R
filename <- basename2(this.path())
fu <- min(unlist(gregexpr("_", filename)))
k <- strtoi(substring(filename, 5, fu-1))

# Importing data ----------------------------------------------------------

# Setting current working directory to source file location
path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

# Expecting data file name like Node1_data.csv where 1 is the variable k above
# Construct file name according to node data
# Assumes default parameters, like header and separator
node_data <- read.csv(paste0("Node", k, "_data.csv"))
n <- nrow(node_data)

# Fitting local model to generate an initial local estimator --------------

fit <- glm(out1 ~ ., data=node_data)
coefs <- as.vector(fit$coefficients)

# Exporting local estimator and sample size -------------------------------

write.csv(c(coefs, n),
          file=paste0("Node",k,"_iter0_output.csv"), row.names=FALSE)
