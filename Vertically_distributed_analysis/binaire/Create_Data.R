library(aplore3)
library(tidyverse)
library(glmnet)

df <- burn1000 %>% 
  select(-id) %>% 
  mutate(death = case_when(death=="Dead"~1, 
                           death=="Alive"~0)) %>% 
  mutate(y = death*2 - 1) %>% 
  mutate(gender = case_when(gender=="Male"~1,
                            gender=="Female"~0)) %>% 
  mutate(race = case_when(race=="White"~1,
                          race=="Non-White"~0)) %>% 
  mutate(inh_inj = case_when(inh_inj=="Yes"~1,
                             inh_inj=="No"~0)) %>% 
  mutate(flame = case_when(flame=="Yes"~1,
                           flame=="No"~0)) %>% 
  select(y, facility, age, tbsa, gender, race, inh_inj, flame)

y <- df %>% 
  select(y)

df <- df %>% 
  select(-y)

df_bin <- df %>% 
  select(gender, race, inh_inj, flame)

df_cont <- df %>% 
  select(facility, age, tbsa)

write.csv(y, file = "outcome_data.csv", row.names = FALSE)
write.csv(df_bin, file = "Data_node_1.csv", row.names = FALSE)
write.csv(df_cont, file = "Data_node_2.csv", row.names = FALSE)
