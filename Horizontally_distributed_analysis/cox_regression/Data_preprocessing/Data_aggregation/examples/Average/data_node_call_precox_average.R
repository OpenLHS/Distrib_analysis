###############  DATA AGGREGATION #####################
############### AVERAGED INTERVALS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi

# Prepopulated value as an example is -1 to force user to choose a value. 
# Adjust according to your specific situation.
eventbucketsize <- -1

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# If you want to override the node numbering based on filename, input 0 or a positive integer here
manualk <- -1

# No modifications should be required below this point
###########################

# Checks weither it makes sense or not to group data based on minimal bucket size.
if (eventbucketsize < 1) {
	stop(paste0("Minimum number of events to group together is currently set to ", eventbucketsize, ".\n It should be set to a value greater than 1, unless you do not want to group your data."))
} else{
  k <- -1
  # If there is a manual override, the node number (k) is set to the manual value --------------------------
  if (manualk >= 0) {
    k <- manualk
    
    # If there is no valid override number, there will be an attempt to extract the node number from the data file name
    } else {
      
      # List all the data files conforming the the pattern below. There should be only 1
      datafileslist <- list.files(pattern="Data_node_[[:digit:]]+.csv")
    
      # Assuming there is only one data file found
      if (length(datafileslist) == 1) {
  
        filename <- datafileslist[[1]]
        lastunders <- max(unlist(gregexpr("_",filename)))
        lenmainfilename <- nchar(filename)-4
        autok <- strtoi(substring(filename,lastunders+1,lenmainfilename))
        
        k <- autok
        
        # If there is more than one data file in the folder, the script will halt.
        } else {
          stop("There is more than one data file in this folder, the node number cannot be automatically identified")
      }
  }
  
  # Verifying that a valid node number could be allocated manually or automatically
  if (k >= 0 & file.exists(paste0("Data_node_", k, ".csv"))) {
    source("data_node_precox_average.R")
    data_node_precox_average(manualwd,k,eventbucketsize)
  }  else {
    stop(paste0("Either node numbering was not set properly or file 'Data_node_", k, ".csv' doesn't exist."))
  }

}

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

