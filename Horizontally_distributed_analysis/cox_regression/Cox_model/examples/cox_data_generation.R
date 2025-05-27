############### DATA GENERATION FOR SURVIVAL ANALYSIS ####################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Includes
library("survival")
library("dplyr")

# Set the node number
k <- 1

# Set the specific beta values
betas <- c(-2, -0.5, -1.4, 2, 3,
           1,2,3,4,5,
           5,4,3,2,1,
           -1,-2,-3,-4,-5, -6)  # Adjust these values

# Number of observations
N <- 500000  # When N is big, the model coefficients are close to betas

# Generate custom covariates
set.seed(k)

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

# No modifications should be required below this point
###########################

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

# Distribution of covariates
X1 <- rgamma(N, shape=2, scale=1)
X2 <- rnorm(N, mean=1, sd=1)
X3 <- rbinom(N, size=1, prob=0.3)
X4 <- rgamma(N, shape=2, scale=1)
X5 <- rnorm(N, mean=1, sd=1)
X6 <- rbinom(N, size=1, prob=0.3)
X7 <- rgamma(N, shape=2, scale=1)
X8 <- rnorm(N, mean=1, sd=1)
X9 <- rbinom(N, size=1, prob=0.3)
X10 <- rgamma(N, shape=2, scale=1)
X11 <- rnorm(N, mean=1, sd=1)
X12 <- rbinom(N, size=1, prob=0.3)
X13 <- rgamma(N, shape=2, scale=1)
X14 <- rnorm(N, mean=1, sd=1)
X15 <- rbinom(N, size=1, prob=0.3)
X16 <- rgamma(N, shape=2, scale=1)
X17 <- rnorm(N, mean=1, sd=1)
X18 <- rbinom(N, size=1, prob=0.3)
X19 <- rgamma(N, shape=2, scale=1)
X20 <- rnorm(N, mean=1, sd=1)


# Combine into a data frame
covariates <- data.frame(X1, X2, X3, X4, X5,
                         X6, X7, X8, X9, X10,
                         X11, X12, X13, X14, X15, 
                         X16, X17, X18, X19, X20)

# Calculate the linear predictor (eta)
eta <- betas[1] * X1 + betas[2] * X2 + betas[3] * X3 + betas[4] * X4 + betas[5] * X5 +
  betas[6] *  X6 +  betas[7] *  X7  + betas[8]  * X8  + betas[9]  * X9  + betas[10] * X10 +
  betas[11] * X11 + betas[12] * X12 + betas[13] * X13 + betas[14] * X14 + betas[15] * X15 +
  betas[16] * X16 + betas[17] * X17 + betas[18] * X18 + betas[19] * X19 + betas[20] * X20 

hist(eta)

# Baseline hazard (constant for simplicity)
baseline_hazard <- 0.058  # Adjust these values

hist(baseline_hazard*eta)

# Generate survival times
U <- runif(N, min=0, max=1)
survival_times <- (-log(U))/(baseline_hazard*exp(eta)) * 1  # Increased multiplier for spread

hist(survival_times)

# Transformation to shift the peak of the survival time distribution
shift_factor <- 10  # Adjust this factor to move the peak
transformed_survival_times <- survival_times + shift_factor

# Generate censoring times (for example, uniformly between 0 and 100)
censoring_times <- runif(N, min = 0, max = 100)

# Uncomment if you want to specify the amount of censored data
#desired_censored_proportion <- 0.9
#censor_index <- sample(1:N, size = floor(N * desired_censored_proportion))
#censoring_times[censor_index] <- pmin(censoring_times[censor_index], transformed_survival_times[censor_index] - 1e-5)

# Determine observed times and event indicator
observed_times <- pmin(transformed_survival_times, censoring_times)
event_indicator <- as.numeric(transformed_survival_times <= censoring_times)

hist(observed_times)

# Combine into a data frame
simdata <- data.frame(
  time = round(observed_times),
  status = event_indicator,
  X1 = X1,
  X2 = X2,
  X3 = X3,
  X4 = X4,
  X5 = X5,
  X6 = X6,
  X7 = X7,
  X8 = X8,
  X9 = X9,
  X10 = X10,
  X11 = X11,
  X12 = X12,
  X13 = X13,
  X14 = X14,
  X15 = X15,
  X16 = X16,
  X17 = X17,
  X18 = X18,
  X19 = X19,
  X20 = X20
)

# Fit a Cox proportional hazards model to the generated data
model <- coxph(Surv(time+ status) ~ X1+ X2+ X3+ X4+ X5+
               X6+ X7+ X8+ X9+ X10+
               X11+ X12+ X13+ X14+ X15+ 
               X16+ X17+ X18+ X19+ X20, data = simdata)

# Display the coefficients of the fitted model
model$coefficients

# Save the generated data to a CSV file
write.csv(simdata, file=paste0("Data_node_", k, ".csv"), row.names = FALSE)

## Remove all environment variables. 
## If you want to see the variable that were created, simply don't execute that line (and clear them manually after)
rm(list = ls())