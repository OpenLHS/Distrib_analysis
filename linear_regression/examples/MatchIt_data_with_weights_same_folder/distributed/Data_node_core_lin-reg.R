############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

# Load package KS : https://cran.r-project.org/package=ks https://cran.r-project.org/web/packages/ks/ks.pdf
# This is required for the analysis to take place
library(ks)

data_lin_reg <- function(man_wd=-1,nodeid=-1) {
	
	manualwd <- man_wd
	k <- nodeid

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

	## Expecting data file name like Data_node_1 where 1 is the variable k above
	## Construct file name according to node data, assumes default parameters, like header and separator
	## This assumes a file with name like Node[[:digit:]]+_data.csv
	node_data <- read.csv(paste0("Data_node_", k, ".csv"))
	n <- nrow(node_data)

	# Verifying if weights are available. 
	
	# Lists all the weight files provided by the user. There should be either none or 1.
	Userwlist <- list.files(pattern=paste0("Weights_node_", k, ".csv"))
	nbUserwfiles <- length(Userwlist)
	# Assumes there is at most one weight file provided by the user found
	if (nbUserwfiles > 1){
	  stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
	}
	
	# Lists all the IPW files conforming the the pattern below. There should be either none or 1.
	IPWfilelist <- list.files(pattern=paste0("IPW_node_", k, "_iter_[[:digit:]]+.csv"))
	nbIPWfiles <- length(IPWfilelist)
	# Assumes there is at most one IPW file found
	if (nbIPWfiles > 1) {
	  stop("There is more than one IPW file in this folder, the weights cannot be automatically identified")
	} 
	
	# Number of files related to weights
	nbWeightfiles <- nbUserwfiles + nbIPWfiles
	
	# Assumes there is at most one type of weight file found
	if (nbWeightfiles > 1){
	  stop("There is nore than one type of weight files in this folder, the weights cannot be automatically identified.")
	}
	
	# Find which weights should be used, if any.  
	# First case checked is for weights provided by the user      
	if (file.exists(paste0("Weights_node_", k, ".csv"))) { 
	  node_weights <- read.csv(paste0("Weights_node_", k, ".csv"))[,1]
	  
	  # Second case is for IPW/ITPW
	} else if(length(IPWfilelist)>0) { 
	  filename <- IPWfilelist[[1]]
	  lastunders <- max(unlist(gregexpr("_",filename)))
	  lastdot <- max(unlist(gregexpr(".", filename, fixed = T)))
	  autoiter <- strtoi(substring(filename,lastunders+1,lastdot-1))
	  
	  iter_weights <- autoiter
	  
	  node_weights <- read.csv(paste0("IPW_node_", k, "_iter_", iter_weights ,".csv"))$IPW
	  
	  # Last case is when no weights are provided. Uses uniform weights
	} else { 
	  node_weights <- rep(1, n)
	}
	
	# Method isn't yet available for missing data
	if(any(is.na.data.frame(node_data))){
	  stop("At least one NA was found in the data. \n The algorithm currently works only with complete data.")
	}
	
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
	write.csv(outputs, file=paste0("Node",k,"_output.csv"),row.names = FALSE,na="")

	# Write variables names
	write.csv(colnames(node_data)[-1], file=paste0("Predictor_names_", k, ".csv"), row.names = FALSE)
	
	## Remove all environment variables. 
	## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
	rm(list = ls())
	
	return(TRUE)

}