############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# This assumes three data node files in the same folder named as below
# The output is visible in RStudio console

K <- 3 # Input the number of nodes

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

# Extracts data and weights from the CSVs and creates R data frames
pooled_data = data.frame()
weights_pooled = data.frame()

for(k in 1:K){
  # Data
  node_data <- read.csv(paste0("Data_node_", k, ".csv"))
  
  # Weights, if provided
  if(file.exists(paste0("Weights_node_", k, ".csv"))){
    node_weights <- read.csv(paste0("Weights_node_", k, ".csv"))
  } else{
    node_weights <- as.data.frame(rep(1, nrow(node_data)))
  }
  
  pooled_data <- rbind(pooled_data, node_data)
  weights_pooled <- rbind(weights_pooled, node_weights)
}

# Remove missing values, if any
data_and_weights <- cbind(pooled_data, weights_pooled[,1])
data_and_weights <- data_and_weights[complete.cases(data_and_weights),]
pooled_data <- data_and_weights[, -(ncol(data_and_weights))]
weights_pooled <- data_and_weights[, ncol(data_and_weights)]

# Fitting and printing pooled model
print("Pooled logistic regression results:")
fit <- glm(out1 ~ ., data=pooled_data, family="poisson", weights = weights_pooled)
print(summary(fit)$coefficients)
print("Confidence intervals")
print(confint.default(fit))
