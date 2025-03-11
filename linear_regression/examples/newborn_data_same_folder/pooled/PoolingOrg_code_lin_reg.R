############### Centralised inference ####################
############### Pooling organisation code ################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Importing data ----------------------------------------------------------

# Extracts data from the CSV and creates R data frame
if (file.exists("Pooled_data.csv")){
  pooled_data <- read.csv("Pooled_data.csv")
  
  # Pooling data for comparison with pooled model
} else{
  pooled_data <- rbind(read.csv(paste0("Data_node_1.csv")),
                       read.csv(paste0("Data_node_2.csv")))
}

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

# Verifying if weights are available. If not, use values of 1s as uniform weights.
if (file.exists(paste0("Weights_pooled.csv"))) {
  weights_pooled <- read.csv("Weights_pooled.csv")[,1]
} else {
  weights_pooled <- rep(1, nrow(pooled_data))
}

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
