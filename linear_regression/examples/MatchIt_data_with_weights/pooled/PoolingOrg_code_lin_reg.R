############### Centralised inference ####################
############### Pooling organisation code ################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Importing data ----------------------------------------------------------

K <- 3 # Input the number of nodes

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

## Code assumes a data frame where the first column is the outcome
## Creates a data frame with the outcome
outcome <- pooled_data[c(1)]
## Code assumes the columns 2 and following are predictors
## Creates a data frame with the predictors
predictors <- pooled_data[-c(1)]
## Create a frame with the intercept (here 1) for each observation
intercept <- rep(1,nrow(pooled_data))
## joins the intercepts and the predictors
intercept_pred <- data.frame(intercept,predictors)

## Code assumes the weights are in the first column
## Weights will be used in a diagonal matrix
W <- diag(weights_pooled)

# Summary statistics for the coefficient estimates in linear regression model---

xtWx <- t(as.matrix(intercept_pred))%*%W%*%as.matrix(intercept_pred)
xtWx_inverse <- solve(xtWx)
ytWy <- t(as.matrix(outcome))%*%W%*%as.matrix(outcome)
xtWy <- t(as.matrix(intercept_pred))%*%W%*%as.matrix(outcome)

# Coefficient estimates in linear regression model------------------------------

# Coefficients and Variance matrix

beta <- xtWx_inverse%*%xtWy
varbeta <- (1/(nrow(pooled_data)-ncol(intercept_pred)))* as.numeric((ytWy - t(beta)%*%xtWy)) * xtWx_inverse

# Confidence interval with alpha=0.05

upper <- beta + qt(p=.05/2, df=nrow(pooled_data)-ncol(intercept_pred), lower.tail=FALSE)*sqrt(diag(varbeta))
lower <- beta - qt(p=.05/2, df=nrow(pooled_data)-ncol(intercept_pred), lower.tail=FALSE)*sqrt(diag(varbeta))

# Summary and outputs ----------------------------------------------------------

output <- setNames(data.frame(beta,lower,upper, row.names = c("Intercept",paste0("Pred", c(1:ncol(predictors))))), c("Beta", "Lower", "Upper"))

## Producing the CSV file containing the final outputs
write.csv(output, file="PoolingOrg_results_centralised_lin_reg.csv")

# Printing pooled models
print("Pooled linear regression results:")
print(output)

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())
