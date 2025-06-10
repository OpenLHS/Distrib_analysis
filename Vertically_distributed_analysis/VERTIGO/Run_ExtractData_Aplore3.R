###############################################################################################################################################################

# PROJECT: VERTIGO and VERTIGO-CI implementation
# DOC:     Example illustrating the quantities known at the CC and at the local data nodes
# BY:      MPD, JPM
# DATE:    June 2025
# UPDATE:  --  

###############################################################################################################################################################

#==============================================================================================================================================================
# Data files creation
#==============================================================================================================================================================

rm(list=ls())

#-------------------------------------------------------------------------------
# Load libraries
#-------------------------------------------------------------------------------
library(aplore3)      # For the burn1000 dataset
library(tidyverse)    # For data manipulation

#-------------------------------------------------------------------------------
# Load and transform data
#-------------------------------------------------------------------------------
# Remove the "id" column
# Transform factors to numeric variables
df <- burn1000 %>% 
  select(-id) %>%
  mutate(death = case_when(death=="Alive"~1,
                           death=="Dead"~0)) %>% 
  mutate(gender = case_when(gender=="Male"~0,
                            gender=="Female"~1)) %>% 
  mutate(race = case_when(race=="White"~0,
                          race=="Non-White"~1)) %>% 
  mutate(inh_inj = case_when(inh_inj=="Yes"~0,
                             inh_inj=="No"~1)) %>% 
  mutate(flame = case_when(flame=="Yes"~0,
                           flame=="No"~1))

# Save the outcome by itself
# Note: It is expected that y_i \in {-1, 1}, not y_i \in {0, 1}.
y <- df %>% 
  select(death) %>% 
  mutate(y = 2*death-1) %>% 
  select(-death)

# Remove outcome from the dataset
df <- df %>% 
  select(-death) %>% 
  select(facility, age, tbsa, gender, race, inh_inj, flame)

# Create data nodes
datanode1 <- df %>% 
  select(1)
datanode2 <- df %>% 
  select(2:5)
datanode3 <- df %>% 
  select(6:7)

# Save to .csv
write.csv(datanode1, file = "Data_node_1.csv", row.names = FALSE)
write.csv(datanode2, file = "Data_node_2.csv", row.names = FALSE)
write.csv(datanode3, file = "Data_node_3.csv", row.names = FALSE)
write.csv(y, file = "outcome_data.csv", row.names = FALSE)
