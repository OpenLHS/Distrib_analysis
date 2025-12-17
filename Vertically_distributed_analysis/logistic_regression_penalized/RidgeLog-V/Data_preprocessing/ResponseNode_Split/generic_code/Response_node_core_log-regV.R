############### Distributed inference ####################
############### Response-node code ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

response_core_log_reg <- function(man_wd=-1, man_k=-1, expath = "") {

manualwd <- man_wd
k <- man_k
examplefilepath <- expath

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
    
    # no known means to automatically allocate node number
  } else {
    stop("The required conditions to automatically set the working directory are not met. See R file")
  }
} else {
  print("The automated working directory setup has been bypassed. If there is an error, this might be the cause.")
}

# Import data from response-node
response_node <- read.csv(paste0(examplefilepath, "Data_node_", k, ".csv"))

# Verify if there is any missing value
if(any(is.na(response_node))){
  stop("The dataset seems to contain NA value(s). The method cannot be applied. 
    You can verify with other participating nodes if the individual(s) concerned should be removed from all datasets to proceed with complete-case analysis.")
}

# Makes sure that the first column is the outcome variable (out1).
if(colnames(response_node)[1]!="out1"){
  stop("The outcome variable (out1) does not appear as the first column of the dataset. \n Make sure the first column corresponds to the response vector and is denoted out1.") 
}

# Makes sure the outcome variable is properly coded as 0s and 1s.
if(!all(unique(response_node$out1) %in% c(0,1))){
  stop("The outcome variable (out1) contains values that are different from 0 and 1, which isn't allowed.")
}

# Extract outcome from dataset
y <- response_node[,1]
y[which(y==0)] <- -1
y <- as.data.frame(y)

# Save outcome to .csv
write.csv(x = y, file = paste0(examplefilepath, "outcome_data.csv"), row.names = FALSE)

# Save all response node data as a backup file
write.csv(x = response_node, file = paste0(examplefilepath, "Backup_Data_node_", k, ".csv"), row.names = FALSE)

# Save response node data without the outcome variable so that all data_node share the same structure
response_node_no_outcome <- response_node[,-1]
write.csv(x = response_node_no_outcome, file = paste0(examplefilepath, "Data_node_", k, ".csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}
