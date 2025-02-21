# Case study 1: Single covariate is constant

# Load data
data <- read.csv("Data_node_1.csv")

# Save dataframe as backup
write.csv(data, file = "Backup_Data_node_1.csv", row.names = F)

# Show table of the categorical variable X2
table(data$X2)

# Convert all of X2 to a single value, but only for node 1
data$X2 <- 0
table(data$X2)

# save datafame
write.csv(data, file = "Data_node_1.csv", row.names = F)

# Run distributed analysis

  # Node side
  source("Data_node_call_cox-reg_1.R") # Our warning: related to WD
  source("Data_node_call_cox-reg_2.R") # Our warning: related to WD

  # Coord side
  source("Coord_node_call_iter_cox-reg.R") # Warning: System is singular (since we have a constant covariate)

  # Repeat for a few iterations
  iteration_to_do <- 3
  for(i in 1:iteration_to_do){
    source("Data_node_call_cox-reg_1.R") # Our warning: related to WD (each iteration)
    source("Data_node_call_cox-reg_2.R") # Our warning: related to WD (each iteration)
    
    # Coord side
    source("Coord_node_call_iter_cox-reg.R") # Issues no warning
  }
  
# Run pooled analysis
source("../pooled_solution/Solution.R") # Our warning: related to WD

# Compare results:
iteration_to_do <- 3
    
  # DA
  Results_DA <- read.csv(paste0("../distributed/Results_iter_", iteration_to_do, ".csv"))
  Results_DA
  
  # Pooled
  summary(res.cox)
  
# In this case, values are the same.
# Question is most likely: While we can estimate "something", are we using the appropriate model?

rm(list = ls())
    
# Note: What if the pooled data had a single covariate that is actually constant?
#       Assume Data_node_1 is the pooled data for this test.
data <- read.csv("../distributed/Data_node_1.csv")

# We do have a constant covariate
table(data$X2)

# Usual cox regression R function
res.cox <- coxph( Surv(time, status) ~ X1 + X2 + X3, data, ties = "breslow")
summary(res.cox)

# Issues no warning, but no estimation provided for constant covariate. 

# Let's remove the constant covariate
data_without_X2 <- data[, -4]
head(data_without_X2)

# Usual cox regression R function for the new dataset
res.cox2 <- coxph( Surv(time, status) ~ X1 + X3, data_without_X2, ties = "breslow")

# Compare results
summary(res.cox)
summary(res.cox2)

# Esimates are the same. As such, it seems that R drops all constant covariate, but doesn't issue a warning to the user. 