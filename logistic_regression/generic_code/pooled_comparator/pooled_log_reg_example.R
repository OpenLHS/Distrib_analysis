############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# This assumes three data node files in the same folder named as below
# The output is visible in RStudio console

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

# Fitting and printing pooled model
print("Pooled logistic regression results:")
fit <- glm(out1 ~ ., data=data_pooled, family="binomial")
print(summary(fit)$coefficients)
print("Confidence intervals")
print(confint.default(fit))
