###############  DATA AGGREGATION #####################
############### AVERAGED INTERVALS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

data_node_precox_average <- function(man_wd=-1,man_nodeid=-1,evbucketsize=-1) {

manualwd <- man_wd  
k <- man_nodeid

# Loading packages and setting up core variables --------------------------
library("dplyr")        # A fast, consistent tool for working with data frame like objects, both in memory and out of memory.


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

# Function to create groups with at least eventbucketsize rows where there is an event recorded
# See data aggregation function code for the expected file csv file structure (time,"status","X1","X2","X3")
# Where status is coded as 0 for censored and 1 for event

create_groups <- function(data, fcteventbucketsize) {
  data <- data %>%
    arrange(time) %>%  # Ensure the data is ordered by time
    mutate(group = 0)  # Initialize group column
  
  current_group <- 1
  count_status_event <- 0
  
  for (i in 1:nrow(data)) {
    if (data$status[i] == 1) {
      count_status_event <- count_status_event + 1
    }
    
    data$group[i] <- current_group
    
    if (count_status_event >= fcteventbucketsize) {
      current_group <- current_group + 1
      count_status_event <- 0
    }
  }
  
  # Merge the last small group with the previous one if needed
  last_group <- max(data$group)
  if (sum(data$group == last_group & data$status == 1) < fcteventbucketsize) {
    data <- data %>%
      mutate(group = ifelse(group == last_group, last_group - 1, group))
  }
  
  return(data)
}

# Read the CSV file for the specified site number and store it in 'node_data'
node_data <- read.csv(paste0("Data_node_", k, ".csv"))

# Apply the function to create groups
node_data_grouped <- create_groups(node_data, evbucketsize)

# Calculate the mean 'time' for each group and replace 'time' with the mean value
node_data_grouped <- node_data_grouped %>%
  group_by(group) %>%
  mutate(time = mean(time)) %>%
  ungroup() %>%
  select(-group)

write.csv(node_data_grouped, file=paste0("Data_node_grouped_", k, ".csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())

return(TRUE)
}