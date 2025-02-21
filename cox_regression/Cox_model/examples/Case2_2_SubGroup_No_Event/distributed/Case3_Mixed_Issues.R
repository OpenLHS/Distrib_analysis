# Case study 3: Subgroup without recorded event and constant covariate

# Load data
data <- read.csv("Data_node_1.csv")
data2 <- read.csv("Data_node_2.csv")

# Save dataframe as backup
write.csv(data, file = "Backup_Data_node_1.csv", row.names = F)
write.csv(data2, file = "Backup_Data_node_2.csv", row.names = F)

# Convert all status of 1s of X2 to 0 for node 1 (unobserved)
data$status[data$ph.ecog!=0] <- 0

# Tranform variable into dummy variable (all nodes)
data$ph.ecog[data$ph.ecog!=0] <- 1
data2$ph.ecog[data2$ph.ecog!=0] <- 1

# Set sex as a constant covariate for node 1
data$sex <- 1

# save datafame
write.csv(data, file = "Data_node_1.csv", row.names = F)
write.csv(data2, file = "Data_node_2.csv", row.names = F)

# Run distributed analysis

  # Node side
  source("Data_node_call_cox-reg_1.R") # Our warning: related to WD
                                       # Warning: loglik converge before variable X2; coefficient may be infinite.
  source("Data_node_call_cox-reg_2.R") # Our warning: related to WD

  # Coord side
  source("Coord_node_call_iter_cox-reg.R") # Warning: Singular system (expected based on previous tests)

  # Repeat for a one iteration
  iteration_to_do <- 2
  for(i in 1:iteration_to_do){
    
    # Node side
    source("Data_node_call_cox-reg_1.R") # Our warning: related to WD (each iteration)
    source("Data_node_call_cox-reg_2.R") # Our warning: related to WD (each iteration)
      
    # Coord side
    source("Coord_node_call_iter_cox-reg.R") # Issues no warning
  }
  
# Run pooled analysis
source("../pooled_solution/Solution.R") # Our warning: related to WD

# Compare results:
iteration_to_do <- 2
    
  # DA
  Results_DA <- read.csv(paste0("../distributed/Results_iter_", iteration_to_do, ".csv"))
  Results_DA # Na and NaN produced!
  
  # Pooled
  summary(res.cox)
  
# In this case, values are way different. DA produces NaN. 
# Let's see the Betas output from our DA:
read.csv("../distributed/Beta_0_output.csv")
read.csv("../distributed/Beta_1_output.csv") # Coefficient is LARGE
read.csv("../distributed/Beta_2_output.csv") # NA values only

rm(list = ls())
    
# Note: What if the pooled data had both issues presented here?
#       Assume Data_node_1 is the pooled data for this test.
data <- read.csv("../distributed/Data_node_1.csv")

# Usual cox regression R function
res.cox <- coxph( Surv(time, status) ~ age + sex + ph.ecog + ph.karno + pat.karno + meal.cal + wt.loss, data, ties = "breslow") # Warning: loglik converge before variable X2; coefficient may be infinite.
summary(res.cox)

# Coefficient for ph.ecog is VERY small.
# NA produced for sex (expected, based on previous tests)

# Let's remove the constant covariate
data_without_X2 <- data[, -4]

# Usual cox regression R function for the new dataset
res.cox2 <- coxph( Surv(time, status) ~ age + ph.ecog + ph.karno + pat.karno + meal.cal + wt.loss, data_without_X2, ties = "breslow") # Warning: loglik converge before variable X2; coefficient may be infinite.

# Compare results
summary(res.cox)
summary(res.cox2)

# Produces the same behavior.

