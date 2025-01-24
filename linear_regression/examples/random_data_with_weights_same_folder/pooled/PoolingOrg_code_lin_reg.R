############### Centralised inference ####################
############### Pooling organisation code ################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Importing data ----------------------------------------------------------

# Extracts data from the CSV and creates R data frame
pooled_data <- read.csv("Pooled_data.csv")
pooled_weights <- read.csv("Weights_pooled.csv")

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
W <- diag(pooled_weights[,1])

# Summary statistics for the coefficient estimates in linear regression model----

xtWx <- t(as.matrix(intercept_pred))%*%W%*%as.matrix(intercept_pred)
xtWx_inverse <- solve(xtWx)
ytWy <- t(as.matrix(outcome))%*%W%*%as.matrix(outcome)
xtWy <- t(as.matrix(intercept_pred))%*%W%*%as.matrix(outcome)
xtW <- t(as.matrix(intercept_pred))%*%W

# Coefficient estimates in linear regression model-------------------------

# Coefficients and Variance matrix

beta <- xtWx_inverse%*%xtWy
varbeta <- (1/(nrow(pooled_data)-ncol(intercept_pred)))* as.numeric((ytWy - t(beta)%*%xtWy)) * xtWx_inverse

# Confidence interval with alpha=0.05

upper <- beta + qt(p=.05/2, df=nrow(pooled_data)-ncol(intercept_pred), lower.tail=FALSE)*sqrt(diag(varbeta))
lower <- beta - qt(p=.05/2, df=nrow(pooled_data)-ncol(intercept_pred), lower.tail=FALSE)*sqrt(diag(varbeta))

# Summary and outputs ----------------------------------------------------

output <- setNames(data.frame(beta,lower,upper, row.names = c("Intercept",paste0("Pred", c(1:ncol(predictors))))), c("Beta", "Lower", "Upper"))

## Producing the CSV file containing the final outputs
write.csv(output, file="PoolingOrg_results_centralised_lin_reg.csv")

confint(lm(out1~pred1+pred2+pred3+pred4, data = pooled_data, weights = pooled_weights[,1]))

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())