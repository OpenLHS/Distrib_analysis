############### Distributed inference ####################
############### Coordinating node code (final results) ###

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Setting confidence level ------------------------------------------------

alpha <- 0.05

# Importing total sample size, final estimator and variance estimate ------

Sigma <- as.matrix(read.csv("CoordNode_final_covariance.csv"))
n <- read.csv("CoordNode_sample_size.csv")[,1]
beta <- read.csv("CoordNode_final_estimator.csv")[,1]

# Computing standard error ------------------------------------------------

se <- qnorm(1 - 0.5*alpha) * sqrt(diag(Sigma/n))

# Computing p-values ------------------------------------------------------

p_vals <- 2*(1 - pnorm(abs(beta)/sqrt(diag(Sigma/n))))

# Exporting final results -------------------------------------------------

output <- cbind(beta, beta - se, beta + se, p_vals)
colnames(output) <- c("Estimate", paste0("CI lower bound (alpha=", alpha, ")"),
                      paste0("CI upper bound (alpha=", alpha, ")"), "p-value")
rownames(output) <- c("(Intercept)", paste0("pred", seq(length(beta)-1)))
