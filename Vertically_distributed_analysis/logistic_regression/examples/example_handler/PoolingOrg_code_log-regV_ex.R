############### Distributed inference ####################
############### Exemple ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi


# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manually.
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

#### Import example datasets

datatset_complete_pooled <- cbind(read.csv("Data_node_1.csv"), read.csv("Data_node_2.csv"))

model_pooled <- glm(data=datatset_complete_pooled, formula=out1~.,family="binomial")

summary(model_pooled)


