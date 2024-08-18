##################  DATA AGGREGATION ######################
################## UNIFORM INTERVALS ######################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Parameters
siteNb <- 1                     # Input here the site number
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
increase <- params[params$V1 == "increase", "V2"]
interval_size <- increase

# ------------------------- CODE STARTS HERE ------------------------

#' This function updates the values of time by determining in which interval each value falls 
#' into and then replacing the original time value with the corresponding interval number.
#'
#' @param data A data frame containing the site data.
#' @param intervals A list containing the interval endpoints.
#' 
#' @return A data frame containing the site data where the time values have been modified.

modify_time <- function(data, intervals) {
  interval_values <- 1:(length(intervals) - 1)
  data$time <- sapply(data$time, function(time_value) {
    if (time_value < intervals[1]) {
      return(interval_values[1])
    } else if (time_value >= intervals[length(intervals)]) {
      return(interval_values[length(interval_values)])
    } else {
      for (i in 1:(length(intervals) - 1)) {
        if (time_value >= intervals[i] && time_value < intervals[i + 1]) {
          return(interval_values[i])
        }
      }
    }
  })
  return(data)
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
  
  # Second step: compute and send interval size matrix
} else if (!file.exists("Global_intervals.csv")) {
  
  # Get local cutoff values and filter data
  local_cutoff_value <- read.csv(paste0("Cutoff_site_", siteNb, ".csv"))
  data1 <- data1[data1$time >= local_cutoff_value[1,] & data1$time <= local_cutoff_value[2,],]
  
  # Get global cutoff values
  global_cutoff_value <- read.csv("Global_cutoff.csv")
  min_cutoff <- as.integer(global_cutoff_value[1,])
  max_cutoff <- as.integer(global_cutoff_value[2,])
    
  # Calculate the number of different interval types (how many interval size will be tried)
  nbTypesOfIntervals <- (max_cutoff - min_cutoff) / increase
  
  # Initialize a binary output matrix to store results
  binary_output_site1 <- matrix(0, nrow = nbTypesOfIntervals, 1)
  
  # Calculate the binary output matrix
  # Outer Loop: This loop iterates over different interval sizes
  # Inner While Loop: This loop ensures that all intervals respect the conditions
  j <- 1
  while (interval_size < (max_cutoff - min_cutoff)) {
    
    left_border <- min_cutoff
    right_border <- min_cutoff + interval_size
    contains_min <- TRUE
    
    # Inner loop to check all intervals
    while (right_border <= max_cutoff) {
      
      # Check if the number of data points within the interval meets the threshold
      data_points_in_interval <- sum(data1$time >= left_border & data1$time < right_border)
      deaths_in_interval <- sum(data1$time >= left_border & data1$time < right_border & data1$status == 1)
      if (deaths_in_interval < nbDataGrouped && data_points_in_interval != 0) {
        contains_min <- FALSE
        break
      }
      
      # Check the next interval
      left_border <- left_border + interval_size
      right_border <- right_border + interval_size
    }
    
    # If contains_min remained true, then all intervals respect the conditions, and binary_output_site1[j] = 1
    binary_output_site1[j] <- ifelse(contains_min, 1, 0)
    
    # Increase interval size (and j)
    interval_size <- interval_size + increase
    j <- j + 1
  }
  
  # Save the binary output matrix to a CSV file
  write.csv(binary_output_site1, file=paste0("Binary_output_site_", siteNb, ".csv"), row.names = FALSE)
  
} else {
  
  # Get global intervals
  intervals <- as.matrix(read.csv(paste0("Global_intervals.csv")))
  
  # Get data
  local_cutoff_value <- read.csv(paste0("Cutoff_site_", siteNb, ".csv"))
  data1 <- data1[data1$time >= local_cutoff_value[1,] & data1$time <= local_cutoff_value[2,],]
  
  # Modify time values in data
  data1 <- modify_time(data1, intervals)
  
  # Write the modified data with intervals to a CSV file
  write.csv(data1, file=paste0("Grouped_Data_site_", siteNb, ".csv"), row.names = FALSE)
  
}

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())
