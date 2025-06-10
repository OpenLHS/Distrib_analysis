###############################################################################################################################################################

# PROJECT: VERTIGO and VERTIGO-CI implementation
# DOC:     Example illustrating the quantities known at the CC and at the local data nodes
# BY:      MPD, JPM
# DATE:    June 2025
# UPDATE:  --  

###############################################################################################################################################################

rm(list=ls())

#==============================================================================================================================================================
# Pooled comparators
#==============================================================================================================================================================

#-------------------------------------------------------------------------------
# Load and pool data
#-------------------------------------------------------------------------------
# Load each node x^(k), k=1,..., K
node_data1 <- read.csv("Data_node_1.csv")
node_data2 <- read.csv("Data_node_2.csv")
node_data3 <- read.csv("Data_node_3.csv")

# Note: Predictor values should be scaled since we are doing a ridge regression
X1_scaled <- scale(node_data1)
X2_scaled <- scale(node_data2)
X3_scaled <- scale(node_data3)

# Note: We do not add a column of ones for the intercept here

# Pool data
X <- cbind(X1_scaled, X2_scaled, X3_scaled)

# Load shared response y
# Note: It is expected that y_i \in {-1, 1}, not y_i \in {0, 1}.
y <- read.csv("outcome_data.csv")[,1]
table(y)

# Fix parameter lambda
lambda <- 0.0001

#-------------------------------------------------------------------------------
# First comparison: Using glm()
#-------------------------------------------------------------------------------
# Model through glm()
glm.model <- glm((y+1)/2 ~ X, family="binomial")

# Format and save output for comparison
output_glm <- summary(glm.model)
output_glm <- output_glm$coefficients[,1:2]
output_glm <- rbind(output_glm[-1,], output_glm[1,])
write.csv(output_glm, file = "glm_output.csv", row.names = TRUE)

#-------------------------------------------------------------------------------
# Second comparison: Using glmnet()
#-------------------------------------------------------------------------------
# Load package
#install.packages("glmnet")
library(glmnet)

# Note: Here, we add a column of values close to 1 to the dataset and we set
# the parameter intercept to FALSE in the glmnet call to account for this.
X <- cbind(X,rep(1,nrow(X))+rnorm(nrow(X), sd = 1e-7))
glmnet.model <- glmnet(X, (y+1)/2, family = "binomial", alpha = 0, lambda = lambda,
                       intercept = FALSE,               # Don't add unpenalized intercept
                       standardize = FALSE,             # Avoid standardization that could affect Intercept column
                       penalty.factor = rep(1, ncol(X)) # Penalize all coefficients, including intercept
)

# Format and save output for comparison
output_glmnet <- cbind(glmnet.model$beta@Dimnames[[1]], glmnet.model$beta@x)
write.csv(output_glmnet, file = "glmnet_output.csv", row.names = FALSE)

#==============================================================================================================================================================
# End of "Pooled comparators"
#==============================================================================================================================================================