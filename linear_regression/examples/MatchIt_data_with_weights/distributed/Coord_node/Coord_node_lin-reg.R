############### Distributed inference ####################
############### Coordinating node code ###################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Load package KS : https://cran.r-project.org/package=ks https://cran.r-project.org/web/packages/ks/ks.pdf
# This is required for the analysis to take place
library(ks)

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# Importing data ----------------------------------------------------------

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

# Calculate number of data nodes from files fiting the pattern in the working directory
# This assumes intermediate data results with a name like Node[[:digit:]]+_output.csv
K=length(list.files(pattern="Node[[:digit:]]+_output.csv"))

# Predictor verification
k <- 1
Pred_names <- read.csv(paste0("Predictor_names_" ,k, ".csv"))
for(k in 2:K){
  Same_names <- read.csv(paste0("Predictor_names_" ,k, ".csv"))
  
  if(!all(Pred_names==Same_names)){
    stop("Node data files seems to have different column structure which may yield wrong results. \n Make sure each node uses the same variable names and the same order in the data file before running this algorithm.")
  }
}
p <- nrow(Pred_names) 

# Create data structures to load the data node outputs
all_local_xtWx <- array(0, dim=c(p+1,p+1, K))
all_local_xtWy <- matrix(0, nrow=p+1, ncol=K)
all_local_ytWy <- rep(0,K)
all_local_n <- rep(0,K)

# Loading output from all nodes in previously created data structures
for (k in 1:K) {
  output_k <- read.csv(paste0("Node", k, "_output.csv"))
  all_local_xtWx[,,k] <- invvec(output_k[,1])
  all_local_xtWy[,k] <- output_k[1:(p+1),3]
  all_local_ytWy[k] <- output_k[1,2]
  all_local_n[k] <- output_k[1,4]
  
}

# Aggregate of local statistics for linear regression model estimates -------

xtWy <- as.matrix(rowSums(all_local_xtWy))
ytWy <- sum(all_local_ytWy)
xtWx <- rowSums(all_local_xtWx,dims=2)
xtWx_inverse <- solve(xtWx)
n <- sum(all_local_n)

# Coefficient estimates in linear regression model-------------------------

#Calculating estimates and Variance matrix

beta <- xtWx_inverse%*%xtWy
varbeta <- (1/(n-p-1))*drop((ytWy-((t(beta))%*%xtWy))) * xtWx_inverse 

#Calculating CI bounds, here based on 0.05

upper <- beta + qt(p=.05/2, df=n-p-1, lower.tail=FALSE)*sqrt(diag(varbeta))
lower <- beta - qt(p=.05/2, df=n-p-1, lower.tail=FALSE)*sqrt(diag(varbeta))

# Summary and output ------------------------------------------------------
## Binding all the results together
output <- setNames(data.frame(beta,lower,upper, row.names = c("Intercept",Pred_names$x)), c("Beta", "Lower", "Upper"))

## Producing the CSV file containing the final outputs
write.csv(output, file="CoordNode_results_distributed_lin_reg.csv")

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())