# Case study 2: Subgroup without recorded event

# Load data
data <- read.csv("Data_node_1.csv")

# Save dataframe as backup
write.csv(data, file = "Backup_Data_node_1.csv", row.names = F)

# Show table of the categorical variable X2 x status
table(data$X2, data$status)

# Convert all status of 1s of X2 to 0 (unobserved)
data$status[data$X2==1] <- 0
table(data$X2, data$status)

# save datafame
write.csv(data, file = "Data_node_1.csv", row.names = F)

# Run distributed analysis

  # Node side
  source("Data_node_call_cox-reg_1.R") # Our warning: related to WD
                                       # Warning: loglik converge before variable X2; coefficient may be infinite.
  source("Data_node_call_cox-reg_2.R") # Our warning: related to WD

  # Coord side
  source("Coord_node_call_iter_cox-reg.R") # Issues no warning

  # Repeat for a few iterations
  iteration_to_do <- 6
  for(i in 1:iteration_to_do){
    source("Data_node_call_cox-reg_1.R") # Our warning: related to WD (each iteration)
    source("Data_node_call_cox-reg_2.R") # Our warning: related to WD (each iteration)
    
    # Coord side
    source("Coord_node_call_iter_cox-reg.R") # Issues no warning
  }
  
# Run pooled analysis
source("../pooled_solution/Solution.R") # Our warning: related to WD

# Compare results:
iteration_to_do <- 6
    
  # DA
  Results_DA <- read.csv(paste0("../distributed/Results_iter_", iteration_to_do, ".csv"))
  Results_DA
  
  # Pooled
  summary(res.cox)
  
# In this case, values are the same. Seems to have converged.

rm(list = ls())
    
# Note: What if the pooled data had a single covariate that is actually constant?
#       Assume Data_node_1 is the pooled data for this test.
data <- read.csv("../distributed/Data_node_1.csv")

# We do have a constant covariate
table(data$X2, data$status)

# Usual cox regression R function
res.cox <- coxph( Surv(time, status) ~ X1 + X2 + X3, data, ties = "breslow") # Warning: loglik converge before variable X2; coefficient may be infinite.
summary(res.cox)

# Issues no warning, but estimation issue for covariate X2 (see variance and/or CI)

# Let's check if this is a codification issue.
data_switch <- data
data_switch$X2[data$X2==1] = 0
data_switch$X2[data$X2==0] = 1

table(data_switch$X2, data_switch$status)

res2.cox <- coxph( Surv(time, status) ~ X1 + X2 + X3, data_switch, ties = "breslow") # Warning: loglik converge before variable X2; coefficient may be infinite.
summary(res.cox)
summary(res2.cox) # This means that the issue is not related to codification, as the results are the same. (Expceted, so reassuring!)

# Let's remove the constant covariate
data_without_X2 <- data[, -4]
head(data_without_X2)

# Usual cox regression R function for the new dataset
res.cox2 <- coxph( Surv(time, status) ~ X1 + X3, data_without_X2, ties = "breslow")

# Compare results
summary(res.cox)
summary(res.cox2)

# Estimates are NOT the same. Expected since we do have events for some other subgroups in X2

# Note: Perhaps we should only drop the individuals of the subgroup?
data <- read.csv("../distributed/Data_node_1.csv")

# We do have a constant covariate
table(data$X2, data$status)

data_without_no_events <- data[data$X2==0,]
table(data_without_no_events$X2, data_without_no_events$status)

res.cox3 <- coxph( Surv(time, status) ~ X1 + X2 + X3, data_without_no_events, ties = "breslow")

summary(res.cox)
summary(res.cox3)

# Results for X1 and X3 seems to be the same
# This makes it seem like the warning might should be taken in to account, as it is not obvious what exactly we are estimating