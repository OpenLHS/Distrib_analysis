############### Distributed inference ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Load package KS : https://cran.r-project.org/package=ks https://cran.r-project.org/web/packages/ks/ks.pdf
library(ks)

# Importing data ----------------------------------------------------------

# Calculate number of data nodes from files fiting the pattern in the working directory
# This assumes intermediate data results with a name like Node[[:digit:]]+_output.csv
K=length(list.files(pattern="Node[[:digit:]]+_output.csv"))

# calculate number of predictors and validate it is the same in each file
## Initialise p
p <- 0
for (k in 1:K) {
  ## Calculate the number of predictors based on the data node output file
  q = sqrt(nrow(read.csv(paste0("Node", k, "_output.csv"))))-1
  ## if first data file opened, assigned the value to p
  if (p == 0) {
    p <- q
  }
  ## if a file has a different number of predictors, send an error
  else if (p != q) {
    stop("your files do not seem to contain the same number of predictors")
  }
}

# Create data structures to load the data node outputs
all_local_xtx <- array(0, dim=c(p+1,p+1, K))
all_local_xty <- matrix(0, nrow=p+1, ncol=K)
all_local_yty <- rep(0,K)

# Loading output from all nodes in previously created data structures
for (k in 1:K) {
  output_k <- read.csv(paste0("Node", k, "_output.csv"))
  all_local_xtx[,,k] <- invvec(output_k[,1])
  all_local_xty[,k] <- output_k[1:(p+1),3]
  all_local_yty[k] <- output_k[1,2]
}

# Aggregate of local statistics for linear regression model estimates -------

xty <- as.matrix(rowSums(all_local_xty))
yty <- sum(all_local_yty)
xtx <- rowSums(all_local_xtx,dims=2)
xtx_inverse <- solve(xtx)

# Coefficient estimates in linear regression model-------------------------

#Calculating estimates and Variance matrix

beta <- xtx_inverse%*%xty
varbeta <- (1/(xtx[1,1]-p-1))*drop((yty-((t(beta))%*%xty))) * xtx_inverse

#Calculating CI bounds, here based on 0.05

upper <- beta + qt(p=.05/2, df=xtx[1,1]-p-1, lower.tail=FALSE)*sqrt(diag(varbeta))
lower <- beta - qt(p=.05/2, df=xtx[1,1]-p-1, lower.tail=FALSE)*sqrt(diag(varbeta))

# Summary and output ------------------------------------------------------
## Binding all the results together
output <- setNames(data.frame(beta,upper,lower, row.names = c("Intercept",paste0("Pred", c(1:p)))), c("Beta", "Upper", "Lower"))

## Producing the CSV file containing the final outputs
write.csv(output, file="CoordNode_results_distributed_lin_reg.csv")

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())