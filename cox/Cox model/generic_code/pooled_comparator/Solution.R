############### POOLED COX MODEL ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Includes
library("survival")
library("survminer")

nbBetas <- ... # Input the number of betas

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

### Code starts here

# Modify this according to the number of data sites
# Make sure the path to the csv files are functional
data1 <- read.csv("../Data_site_1.csv")
data2 <- read.csv("../Data_site_2.csv")
data3 <- read.csv("../Data_site_3.csv")

# Pool data
data <- rbind(data1, data2, data3)

# Calculate Cox model
column_indices <- (3:(nbBetas + 2))
formula <- as.formula(paste("Surv(time, status) ~", paste(paste0("data[,", column_indices, "]"), collapse = " + ")))
res.cox <- coxph(formula, data, ties = "breslow")
summary(res.cox)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())