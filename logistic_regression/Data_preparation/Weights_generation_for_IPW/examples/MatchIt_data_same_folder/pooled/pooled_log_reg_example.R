############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# This assumes three data node files in the same folder named as below
# The output is visible in RStudio console

# If you do not want to use a threshold for the probabilities estimated, input 0 here.
# Threshold value should be betweeen 0 and 0.5 and will be applied like this:
# score<threshold || score>(1-threshold)
manualthresh <- 0.01

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

# Pooling data for comparison with pooled model
data_pooled <- rbind(read.csv(paste0("Data_node_1.csv")),
                     read.csv(paste0("Data_node_2.csv")),
                     read.csv(paste0("Data_node_3.csv")))

# Verifying if weights are available. If not, use values of 1s as uniform weights.
if (file.exists(paste0("Weights_pooled.csv"))) {
  weights_pooled <- read.csv("Weights_pooled.csv")[,1]
} else {
  weights_pooled <- rep(1, nrow(data_pooled))
}

# Fitting and printing pooled model
print("Pooled logistic regression results:")
fit <- glm(Tx ~ ., data=data_pooled, family="binomial", weights = weights_pooled)
print(summary(fit)$coefficients)
print("Confidence intervals")
print(confint.default(fit))

# Predicted probabilities
predprop <- predict(fit, data_pooled, type="response")

# Predicted probabilities after threshold
predprop[predprop<manualthresh] = manualthresh
predprop[predprop>(1-manualthresh)] = 1-manualthresh

predprop