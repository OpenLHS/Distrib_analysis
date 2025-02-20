############### Distributed inference ####################
############### Data node code - Missing values ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------

missing_value_handler <- function(man_wd=-1,nodeid=-1) {
	
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
	filename <- paste0("Data_node_", k, ".csv")
	node_data <- read.csv(filename)
	
	if(any(is.na(node_data))){
	  # Data with missing values
	  old_node_data <- node_data
	  
	  # Data without missing values
	  node_data <- node_data[rowSums(is.na(node_data))==0, ]
	  
	  # Issue warning to user that we changed their main file 
	  warning("Missing data has been found. As such, all lines with at least one missing data were removed. Complete data was saved in a backup file.")
	}
	
	# Summary and outputs -----------------------------------------------------
	
	# Keep old data as backup
	write.csv(old_node_data, file = paste0("Backup_", filename), row.names = F)
	
	# Save new data without missing values
	write.csv(node_data, file = filename, row.names = F)
	
	## Remove all environment variables. 
	## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
	rm(list = ls())
	
	return(TRUE)

}