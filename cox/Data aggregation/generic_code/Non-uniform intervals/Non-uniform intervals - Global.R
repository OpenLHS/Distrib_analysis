##################  DATA AGGREGATION ######################
################ NON-UNIFORM INTERVALS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

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

# Import parameters (do not edit)
# See Data_aggregation_Brief_Summary for explanation
params <- read.csv("Parameters.csv", header = FALSE)
step <- params[params$V1 == "step", "V2"]
interval_size <- params[params$V1 == "interval_size", "V2"]
increase <- params[params$V1 == "increase", "V2"]

# ------------------------- CODE STARTS HERE ------------------------

# Calculate number of data nodes from files fitting the pattern in the working directory
# This assumes cutoff times outputs have a name like Cutoff_site_[[:digit:]]+.csv
K=length(list.files(pattern="Cutoff_site_[[:digit:]]+.csv"))

if (step > interval_size){
  print("Warning: The value of 'step' is bigger than the value of 'interval_size', which may cause suboptimal partionning.")
}

# Find the global cutoff values
if (file.exists(paste0("Cutoff_site_", K, ".csv")) && !file.exists(paste0("Binary_output_site_", K, ".csv"))) {
  
  # Loop over sites to find global min and max cutoff values
  min_cutoff <- Inf
  max_cutoff <- 0
  for(k in 1:K){
    cutoff_local <- read.csv(paste0("Cutoff_site_", k, ".csv"))
    if (cutoff_local[1,] < min_cutoff){
      min_cutoff <- cutoff_local[1,]
    }
    if (cutoff_local[2,] > max_cutoff){
      max_cutoff <- cutoff_local[2,]
    }
  }
  
  # Write cutoff values in CSV
  write.csv(c(min_cutoff, max_cutoff), file="Global_cutoff.csv", row.names = FALSE)
  
} else if (file.exists(paste0("Binary_output_site_", K, ".csv"))){

  # Aggregate binary output matrices from all sites
  for (i in 1:K) {
    binary_output_site <- as.matrix(read.csv(paste0("Binary_output_site_", i, ".csv")))
    if (i == 1) {
      binary_output_global <- binary_output_site
    } else {
      binary_output_global <- binary_output_global + binary_output_site
    }
  }
  
  # Get cutoff values
  global_cutoff_value <- read.csv("Global_cutoff.csv")
  min_cutoff <- as.integer(global_cutoff_value[1,])
  max_cutoff <- as.integer(global_cutoff_value[2,])
  
  # Initialize variables for finding intervals
  intervals <- list()
  initial_interval_size <- interval_size
  value <- min_cutoff
  nbRows <- nrow(binary_output_global)
  done <- FALSE
  position <- 1
  
  # Loop through positions in the binary output matrix to find valid intervals
  # Check Data_aggregation_Brief_Summary for a clearer explanation of the algorithm
  while (position <= ncol(binary_output_global)) {
    for (i in 1:nbRows) {
      if (!done) {
        # Check if the interval is valid across all sites
        if (binary_output_global[i, position] == K) {
          # Calculate the interval start value and append it to the list
          intervals <- append(intervals, value)
          value <- value + (initial_interval_size + (i - 1) * increase)
          
          # Update the next position to check for the next interval
          position <- floor((value - min_cutoff) / step) + 1
          done <- TRUE
        }
        # If reached the last row without finding a valid interval, exit the loop
        if (i == nbRows) {
          position <- ncol(binary_output_global)
        }
      }
    } 
    done <- FALSE
  }
  
  # Add the last interval border
  intervals <- append(intervals, max_cutoff + 1)
  
  # Write intervals to a CSV
  write.csv(intervals, file=paste0("Global_intervals.csv"), row.names = FALSE)
}

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())
