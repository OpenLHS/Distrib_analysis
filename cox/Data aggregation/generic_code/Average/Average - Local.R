###############  DATA AGGREGATION #####################
############### AVERAGED INTERVALS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("dplyr")        # A fast, consistent tool for working with data frame like objects, both in memory and out of memory.

# Parameters
siteNb <- ...             # Input here the site number
nbDataGrouped <- ...      # Input here the number of subjects grouped together

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

# ------------------------- CODE STARTS HERE ------------------------

# Read the CSV file for the specified site number and store it in 'data1'
data1 <- read.csv(paste0("Data_site_", siteNb, ".csv"))

# Function to create groups with at least nbDataGrouped rows where status == 1
create_groups <- function(data, nbDataGrouped) {
  data <- data %>%
    arrange(time) %>%  # Ensure the data is ordered by time
    mutate(group = 0)  # Initialize group column
  
  current_group <- 1
  count_status_1 <- 0
  
  for (i in 1:nrow(data)) {
    if (data$status[i] == 1) {
      count_status_1 <- count_status_1 + 1
    }
    
    data$group[i] <- current_group
    
    if (count_status_1 >= nbDataGrouped) {
      current_group <- current_group + 1
      count_status_1 <- 0
    }
  }
  
  # Merge the last small group with the previous one if needed
  last_group <- max(data$group)
  if (sum(data$group == last_group & data$status == 1) < nbDataGrouped) {
    data <- data %>%
      mutate(group = if_else(group == last_group, last_group - 1, group))
  }
  
  return(data)
}

# Apply the function to create groups
data1_grouped <- create_groups(data1, nbDataGrouped)

# Calculate the mean 'time' for each group and replace 'time' with the mean value
data1_grouped <- data1_grouped %>%
  group_by(group) %>%
  mutate(time = mean(time)) %>%
  ungroup() %>%
  select(-group)

write.csv(data1_grouped, file=paste0("Grouped_Data_site_", siteNb, ".csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())