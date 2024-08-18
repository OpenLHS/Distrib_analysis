##################  DATA AGGREGATION ######################
################ NON-UNIFORM INTERVALS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Parameters
siteNb <- ...                     # Input here the site number
left_percent_excluded <- 2      # Input here the percent of values to be excluded (left side of the distribution)
right_percent_excluded <- 2     # Input here the percent of values to be excluded (right side of the distribution)

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

nbDataGrouped <- params[params$V1 == "nbDataGrouped", "V2"]
step <- params[params$V1 == "step", "V2"]
interval_size <- params[params$V1 == "interval_size", "V2"]
increase <- params[params$V1 == "increase", "V2"]

# ------------------------- CODE STARTS HERE ------------------------

if (step > interval_size){
  print("Warning: The value of 'step' is bigger than the value of 'interval_size', which may cause suboptimal partionning.")
}

# Read data
data1 <- read.csv(paste0("Data_site_", siteNb, ".csv"))
data1 <- data1[order(data1$time), ]

# First step: choose cutoff
if (!file.exists("Global_cutoff.csv")) {
  
  # Get number of rows
  num_rows <- nrow(data1)
  
  # Calculate the number of rows to exclude from the beginning
  exclude_start_index <- floor(num_rows * (left_percent_excluded / 100))
  exclude_end_index <- floor(num_rows * (right_percent_excluded / 100))
  
  # Determine the range of rows to include
  start_row <- exclude_start_index + 1
  end_row <- num_rows - exclude_end_index
  
  # Filter the data to exclude the specified rows from both ends
  data1_filtered <- data1[start_row:end_row, ]
  array1_filtered <- data1_filtered$time
  
  # Get the first and last value of array1_filtered
  first_value <- array1_filtered[1]
  last_value <- array1_filtered[length(array1_filtered)]
  
  # Write the cutoff value to a CSV file
  write.csv(c(first_value, last_value), file=paste0("Cutoff_site_", siteNb, ".csv"), row.names = FALSE)

# Compute and send interval size matrix
} else if (!file.exists("Global_intervals.csv")) {
  
  # Get local cutoff values and filter data
  local_cutoff_value <- read.csv(paste0("Cutoff_site_", siteNb, ".csv"))
  data1 <- data1[data1$time >= local_cutoff_value[1,] & data1$time <= local_cutoff_value[2,],]
  
  # Get global cutoff values
  global_cutoff_value <- read.csv("Global_cutoff.csv")
  min_cutoff <- as.integer(global_cutoff_value[1,])
  max_cutoff <- as.integer(global_cutoff_value[2,])
  
  # Data initialization
  left_border <- min_cutoff
  right_border <- min_cutoff + interval_size
  initial_interval_size <- interval_size
  
  # Calculate the number of different interval types and the maximum number of intervals
  # Different interval types depends of min, max, interval_size and increase
  # Maximum number of intervals depends on min, max, the smallest interval size and the step
  nbTypesOfIntervals <- floor(((max_cutoff - min_cutoff) - interval_size) / increase) + 1
  maxNbOfIntervals <- floor(((max_cutoff - interval_size) - min_cutoff) / step) + 1
  
  # Initialize a binary output matrix to store results
  binary_output_site1 <- matrix(0, nrow = nbTypesOfIntervals, ncol = maxNbOfIntervals)
  
  # Calculate the binary output matrix
  # Outer loop iterates over different interval sizes
  # Inner loop iterates over different start position for the intervals
  j <- 1
  while (interval_size <= (max_cutoff - min_cutoff)) {
    
    # Inner loop to iterate over different interval positions
    i <- 1
    while (right_border <= max_cutoff) {
      if(right_border < max_cutoff){  
        # Check if the number of data points within the interval meets the threshold
        data_points_in_interval <- sum(data1$time >= left_border & data1$time < right_border)
        deaths_in_interval <- sum(data1$time >= left_border & data1$time < right_border & data1$status == 1)
        data_after <- sum(data1$time >= right_border)
        death_after <- sum(data1$time >= right_border & data1$status == 1)
        
        if ((deaths_in_interval >= nbDataGrouped || data_points_in_interval == 0) && (death_after >= nbDataGrouped || data_after == 0)) {
          binary_output_site1[j,i] <- 1
        }
        
        # Case where the last interval is closed instead of open
      } else{
        # Check if the number of data points within the interval meets the threshold
        data_points_in_interval <- sum(data1$time >= left_border & data1$time <= right_border)
        deaths_in_interval <- sum(data1$time >= left_border & data1$time <= right_border & data1$status == 1)
        
        if ((deaths_in_interval >= nbDataGrouped || data_points_in_interval == 0)) {
          binary_output_site1[j,i] <- 1
        }
      }
      
      # Move the interval window to the right
      left_border <- left_border + step
      right_border <- right_border + step
      i <- i + 1
    }
    
    # Increase the interval size and reset the interval positions
    interval_size <- interval_size + increase
    left_border <- min_cutoff
    right_border <- min_cutoff + interval_size
    j <- j + 1
  }
  
  # Save the binary output matrix to a CSV file
  write.csv(binary_output_site1, file=paste0("Binary_output_site_", siteNb, ".csv"), row.names = FALSE)
  
} else {
  
  # Get global intervals
  intervals <- read.csv(paste0("Global_intervals.csv"))
  
  # Get local cutoff values and filter data
  local_cutoff_value <- read.csv(paste0("Cutoff_site_", siteNb, ".csv"))
  data1 <- data1[data1$time >= local_cutoff_value[1,] & data1$time <= local_cutoff_value[2,],]
  
  # Bin the times into intervals specified by the global intervals file
  data1$time <- cut(data1$time, breaks = c(-Inf, intervals), labels = FALSE, right = FALSE)
  
  # Save the grouped data to a new CSV file
  write.csv(data1, file=paste0("Grouped_Data_site_", siteNb, ".csv"), row.names = FALSE)
  
}

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())
