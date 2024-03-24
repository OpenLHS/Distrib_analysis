############### Distributed inference ####################
############### Coordinating node code (final results) ###

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# No modifications should be required below this point
###########################

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

# List all the data files conforming the the pattern below. There should be at least one of iteration 2 or above
coordouputfileslist <- list.files(pattern="Coord_node_iter_[[:digit:]]+_primer.csv")
# Assuming there is at least one file found
if (length(coordouputfileslist) > 0) {
  
  iterlst=list()
  for (fl in coordouputfileslist){
    outputfname <- fl
    lastundersf <- max(unlist(gregexpr("_",outputfname)))
    suffname <- nchar(outputfname)-11
    iterfl <- strtoi(substring(outputfname,lastundersf-1,suffname))
    iterlst <- append(iterlst,iterfl)
  }
  sortediterlst <- iterlst[order(names(setNames(iterlst, iterlst)),decreasing=TRUE)]
  
  t <- sortediterlst[[1]]
} else {
  stop("There is no primer file found")
}

if (t>1) {
  
  # Importing data and aggregating gradients and hessians -------------------
  
  beta_old <- read.csv(paste0("Coord_node_iter_", t, "_primer.csv"))[,1]
  
  K <- length(list.files(pattern=paste0("Data_node_[[:digit:]]+_iter_", t, "_output.csv")))
  p <- 0
  for (k in 1:K) {
    node_k <- read.csv(paste0("Data_node_", k, "_iter_", t, "_output.csv"))
    q <- nrow(node_k)
    if (p == 0) {
      p <- q
      D_t <- rep(0, p)
      V_t <- matrix(0, p, p)
    }
    else if (p != q) 
      stop("Nodes files do not seem to contain the same number of predictors.")
    D_t <- D_t + node_k[,1]
    V_t <- V_t + as.matrix(node_k[,-1])
  }
  
  # Newton-Raphson update ---------------------------------------------------
  
  beta_new <- beta_old + solve(V_t, D_t)
  
  write.csv(beta_new,
            file="Coord_node_final_estimator.csv", row.names=FALSE)
  n <- read.csv("Coord_node_sample_size.csv")[,1]
  Sigma <- n * solve(V_t)
  write.csv(Sigma, file="Coord_node_final_covariance.csv", row.names=FALSE)

  # Setting confidence level ------------------------------------------------
  
  alpha <- 0.05
  beta <- beta_new
  
  # Importing total sample size, final estimator and variance estimate ------
  
  #Sigma <- as.matrix(read.csv("CoordNode_final_covariance.csv"))
  #n <- read.csv("CoordNode_sample_size.csv")[,1]
  #beta <- read.csv("CoordNode_final_estimator.csv")[,1]
  
  # Computing standard error ------------------------------------------------
  
  se <- qnorm(1 - 0.5*alpha) * sqrt(diag(Sigma/n))
  
  # Computing p-values ------------------------------------------------------
  
  p_vals <- 2*(1 - pnorm(abs(beta)/sqrt(diag(Sigma/n))))
  
  # Exporting final results -------------------------------------------------
  
  output <- cbind(beta, beta - se, beta + se, p_vals)
  colnames(output) <- c("Estimate", paste0("CI lower bound (alpha=", alpha, ")"),
                        paste0("CI upper bound (alpha=", alpha, ")"), "p-value")
  rownames(output) <- c("(Intercept)", paste0("pred", seq(length(beta)-1)))
  
  } else {
    print("No primer file of iteration 2 or more were found")
}
