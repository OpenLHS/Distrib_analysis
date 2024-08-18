##################  DATA AGGREGATION ######################
################## UNIFORM INTERVALS ######################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manualy.
manualwd <- -1

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

####################################

source("Uniform intervals - Local - site1.R", local = T)
source("Uniform intervals - Local - site2.R", local = T)

source("Uniform intervals - Global.R", local = T)

source("Uniform intervals - Local - site1.R", local = T)
source("Uniform intervals - Local - site2.R", local = T)

source("Uniform intervals - Global.R", local = T)

source("Uniform intervals - Local - site1.R", local = T)
source("Uniform intervals - Local - site2.R", local = T)

