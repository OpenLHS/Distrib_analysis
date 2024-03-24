############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


# Loading packages and setting up core variables --------------------------

# The package this.path is to automatically identify the script filename and deduce the node identifier.
# https://cran.r-project.org/package=this.path https://cran.r-project.org/web/packages/this.path/this.path.pdf

# It is NOT required to run the analysis. If the package is not available, the node identifier (variable k) will need to be set manually
# If the this.path package is not installed but you did set the node identifier manually below, you can safely ignore the R warning about the "this.path" package not being available.

# Insert the data node identifier here (integer >=0). If the this.path package is available, you can simply leave the default value (-1)
k <- -1

# Check if the package is installed
thispath_available <- require("this.path")


if (thispath_available) {

	# When the this.path package is installed, automatically set data node identifier based on the filename.
	# This assumes a file with name like Data-node_[[:digit:]]+_call_lin-reg.R
	filename <- basename2(this.path())
	fu<- min(unlist(gregexpr("_",filename)))
	k <- strtoi(substring(filename,11,fu+1))

} else {
	# if the r package this.path is not available/installed, the data node identifier set above will be used instead.
	if (k < 0) {stop("The node identifier is not correct")}
}

source("Data-node_core_code_lin-reg.R")
data_lin_reg(k)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())