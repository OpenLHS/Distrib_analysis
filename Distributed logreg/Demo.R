############### Distributed inference ####################
############### Demo script ##############################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Fixing randomness -------------------------------------------------------

set.seed(1)

# Setting current working directory to source file location ---------------

path <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(path)

# Generating 3 datasets with random true beta -----------------------------

sigmoid <- function(x) {
  exp(x) / (1 + exp(x))
}

# Number of predictors (excluding intercept)
p <- 4
beta <- round(rnorm(p+1, mean=0, sd=2))

# Node sample sizes
n <- c(30, 100, 60)

# Number of nodes (cannot be changed for now)
K <- 3

# Generating node datasets according to true LR model
for (k in 1:K) {
  n_k <- n[k]
  X_k <- cbind(rep(1, n_k), matrix(rnorm(p*n_k), nrow=n_k))
  y_k <- rbinom(n_k, 1, prob=sigmoid(X_k %*% beta))
  data_k <- data.frame(y_k, X_k[,2:(p+1)])
  colnames(data_k) <- c("out1", paste0("pred", 1:p))
  write.csv(data_k, file=paste0("Node", k, "_data.csv"), row.names=FALSE)
}

# Fixing number of iterations ---------------------------------------------

nb_iter <- 8

# Initializing nodes (iteration t=0) --------------------------------------

source("Node1_init_log-reg.R")
source("Node2_init_log-reg.R")
source("Node3_init_log-reg.R")
source("CoordNode_init_log-reg.R")

# Running iterations t > 1 ------------------------------------------------

last <- FALSE
for (t in 1:nb_iter) {
  if (t > 1) source("CoordNode_iter_log-reg.R")
  source("Node1_iter_log-reg.R")
  source("Node2_iter_log-reg.R")
  source("Node3_iter_log-reg.R")
}
last <- TRUE
source("CoordNode_iter_log-reg.R")

# Running final script ----------------------------------------------------

source("CoordNode_final.R")


# Printing results and comparing with pooled logistic regression ----------

print("Distributed logistic regression results:")
print(output)

# Pooling data for comparison with pooled model
data_pooled <- rbind(read.csv(paste0("Node1_data.csv")),
                     read.csv(paste0("Node2_data.csv")),
                     read.csv(paste0("Node3_data.csv")))

# Fitting and printing pooled model
print("Pooled logistic regression results:")
fit <- glm(out1 ~ ., data=data_pooled, family="binomial")
print(summary(fit)$coefficients)
print("Confidence intervals")
print(confint.default(fit))

# Removing .csv files form the current directory --------------------------

file.remove(file.path(path,
                      list.files(path)[grepl("\\.csv$", list.files(path))]))
