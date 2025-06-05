############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

# Load package KS : https://cran.r-project.org/package=ks https://cran.r-project.org/web/packages/ks/ks.pdf
# This is required for the analysis to take place
library(ks)

data_lin_reg <- function(man_wd=-1,nodeid=-1,expath="") {
	
	manualwd <- man_wd
	k <- nodeid
	examplefilepath <- expath

	if (k<0){
		stop
	}
	
	if (manualwd != 1) {

	  # Set working directory automatically
	  
	  # this.path package is available
	  if (require(this.path)) {
		setwd(this.dir())
		
		# else if running in R studio and the rstudioapi is available, set the correct working directory
	  } else if ((Sys.getenv("RSTUDIO") == "1") & (require("rstudioapi"))) {
		print("RSTUDIO")
		path <- dirname(rstudioapi::getActiveDocumentContext()$path)
		setwd(path)
		
		# no known means to automatically set working directory
	  } else {
		stop("The required conditions to automatically set the working directory are not met. See R file")
	  }
	} else {
	  print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
	}
	# Importing data ----------------------------------------------------------

	# Handles missing values, if any
	source("Data_node_core_missingvalues.R")
	missing_value_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath)
	
	## Expecting data file name like Data_node_1 where 1 is the variable k above
	## Construct file name according to node data, assumes default parameters, like header and separator
	## This assumes a file with name like Node[[:digit:]]+_data.csv
	node_data <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))
	n <- nrow(node_data)

	# Verifying if weights are available. 
	source("Data_node_core_weights.R") 
	weights_handler(man_wd = manualwd, nodeid = k, expath = examplefilepath, nbrow = n)
	node_weights <- read.csv(paste0(examplefilepath, "Weights_node_", k, ".csv"))[,1]
	
	## Code assumes a data frame where the first column is the outcome
	## Creates a data frame with the outcome
	outcome <- node_data[c(1)]
	## Code assumes the columns 2 and following are predictors
	## Creates a data frame with the predictors
	predictors <- node_data[-c(1)]
	## Create a frame with the intercept (here 1) for each observation
	intercept <- rep(1,nrow(node_data))
	## joins the intercepts and the predictors
	intercept_pred <- data.frame(intercept,predictors)

	# Weights are used through a diagonal matrix
	W = diag(node_weights)

	# Summary statistics to share to coordinating center ----------------------

	## Matrix transpositions
	xtWx <- vec(t(as.matrix(intercept_pred))%*%W%*%as.matrix(intercept_pred))
	ytWy <- vec(t(as.matrix(outcome))%*%W%*%as.matrix(outcome))
	xtWy <- vec(t(as.matrix(intercept_pred))%*%W%*%as.matrix(outcome))
	
	length(ytWy) <- length(xtWx)
	length(xtWy) <- length(xtWx)
	
	# Size of dataset
	length(n) <- length(xtWx)

	# Summary and outputs -----------------------------------------------------

	## Binding all the results together
	outputs <- cbind(xtWx,ytWy,xtWy, n)

	## Producing the CSV file containing the output that will be used by the coordinating node to calculate the final result
	write.csv(outputs, file=paste0(examplefilepath, "Node",k,"_output.csv"),row.names = FALSE,na="")

	# Write variables names
	write.csv(colnames(node_data)[-1], file=paste0(examplefilepath, "Predictor_names_", k, ".csv"), row.names = FALSE)
	
	## Remove all environment variables. 
	## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
	rm(list = ls())
	
	return(TRUE)

}