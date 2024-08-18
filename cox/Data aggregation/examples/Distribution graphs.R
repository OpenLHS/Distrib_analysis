############### GRAPH GENERATION FOR SURVIVAL ANALYSIS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
library("dplyr")                            # Library for generating graphs
library(ggplot2)                            # Library for generating graphs

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

# Read data
data1 <- read.csv("Data_site_1.csv")
data2 <- read.csv("Data_site_2.csv")

# HISTROGRAM ------------------------------------------------------
combined_data <- rbind(transform(data1, dataset = "Dataset 1"),
                       transform(data2, dataset = "Dataset 2"))

# Create histogram plots for each dataset
combined_plot <- ggplot(combined_data, aes(x = time, fill = dataset)) +
  geom_histogram(alpha = 0.6, position = "identity", binwidth = 5) +  # Adjust binwidth as needed
  labs(title = "Histogram of Time", x = "Time", y = "Count") +
  theme_minimal() +
  scale_fill_manual(values = c("Dataset 1" = "blue", "Dataset 2" = "green"))  # Optional: customize colors

# Display the combined plot
print(combined_plot)

# SMOOTH CURVE ----------------------------------------------------
combined_data <- rbind(transform(data1, dataset = "Dataset 1"),
                       transform(data2, dataset = "Dataset 2"))

# Create density plots for each dataset
combined_plot <- ggplot(combined_data, aes(x = time, color = dataset)) +
  geom_density() +
  labs(title = "Density Plot of Time", x = "Time", y = "Density") +
  theme_minimal()

# Display the combined plot
print(combined_plot)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())
