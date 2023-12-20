############### Distributed inference ####################
############### Data node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Load package KS : https://cran.r-project.org/package=ks https://cran.r-project.org/web/packages/ks/ks.pdf
library(ks)

#Set data node number
k <- 2

# Importing data ----------------------------------------------------------

## Expecting data file name like Node1_data.csv where 1 is the variable k above
## Construct file name according to node data, assumes default parameters, like header and separator
node_data <- read.csv(paste0("Node", k, "_data.csv"))

## Code assumes a data frame where the first column is the outcome
## Creates a data frame with the outcome
outcome <- node_data[c(1)]
## Code assumes the columns 2 and following are predictors
## Creates a data frame with the predictors
predictors <- node_data[-c(1)]
## Create a frame with the intercept (here 1) for each observation
intercept <- rep(1,nrow(node_data))
## joins the intercepts and the predictors
intercept_pred <- data.frame(intercept,predictors)

# Summary statistics to share to coordinating center ----------------------
## Matrix transpositions
xtx <- t(as.matrix(intercept_pred))%*%as.matrix(intercept_pred)
yty <- t(as.matrix(outcome))%*%as.matrix(outcome)
xty <- t(as.matrix(intercept_pred))%*%as.matrix(outcome)

# Summary and outputs -----------------------------------------------
## Binding all the results together
outputs <- cbind(vec(xtx),vec(yty),vec(xty),nrow(node_data))

## Producing the CSV file containing the output that will be used by the coordinating node to calculate the final result
write.csv(outputs, file=paste0("Node",k,"_output.csv"))

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())