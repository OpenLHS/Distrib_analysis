############### Distributed inference ####################
############### Response-node code ###########################

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke

# Loading packages and setting up core variables --------------------------
# Currently, the automated node number allocation currently requires execution in R studio and rstudioapi package
# https://cran.r-project.org/package=rstudioapi
library(tcltk)

# If you want to skip the automated working directory setting, input 1 here. 
# If you do so, make sure the working directory is set correctly manually.
manualwd <- -1

# If you want to manually set the parameter lambda, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
lambda <- -1

# If you want to manually set the parameter eta, specify value here.
# If you do so, please refer to article to ensure adequate settings. 
# Else, an automated value that complies with the assumptions of the method will be assigned.
eta <- -1

# If you want to use a specific seed for the privacy check, specify it here.
# If you do so, all nodes will use the same seed for their privacy check.
# Else, no seed will be used
manualseed <- -1

# No modifications should be required below this point
###########################

popup_window <- function(prompt){
  # Create pop up box
  popup <- tktoplevel()
  tkwm.title(popup, "Choose an Option")
  
  label <- tklabel(popup, text = prompt)
  tkpack(label, padx = 20, pady = 10)
  
  user_choice <- tclVar("")
  
  # Define how the user-response is registered
  on_true <- function() {
    tclvalue(user_choice) <- "TRUE"
    tkdestroy(popup)
  }
  on_false <- function() {
    tclvalue(user_choice) <- "FALSE"
    tkdestroy(popup)
  }
  on_cancel <- function() {
    tclvalue(user_choice) <- "NULL"
    tkdestroy(popup)
  }
  
  # Define behavior of buttons
  tkpack(tkbutton(popup, text = "Yes", command = on_true), side = "left", padx = 10)
  tkpack(tkbutton(popup, text = "No", command = on_false), side = "left", padx = 10)
  tkpack(tkbutton(popup, text = "Cancel", command = on_cancel), side = "left", padx = 10)
  
  tkwait.window(popup)
  
  result <- tclvalue(user_choice)
  
  # Transorm user-response into the privacy assessment boolean
  if(result=="NULL" | result==""){
    stop("User need to specify if the privacy assessment on the response variable should be run or not.")
  } else if(result=="TRUE"){
    privacy = 1
  } else {
    privacy = 0
  }
  
  return(privacy)
  
}

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

# Ask user if we should run the privacy assessment on Y
privacy <- popup_window("Do you want to run the privacy assessment on the response variable?")

# Once the working directory as been set, save it so we can pass it to other files
path <- paste0(getwd(), "/")
  
# Verifying if there is a coordination node (response-node) data file present
nb_node1_files <- length(list.files(path=path, pattern="Data_node_1.csv"))
nb_node_output_files <- length(list.files(path=path, pattern="Data_node_[[:digit:]]+_init_output.rds"))

if (nb_node1_files==1 & nb_node_output_files>0) {
  source("Response_node_init_iter_log-regV.R")
  coord_log_reg(man_wd = manualwd, man_lambda = lambda, man_eta = eta, expath = path, privacy_switch = privacy, man_seed = manualseed)
} else {
  stop("Node 1 data file missing or no output file from other nodes found")
  }

## Remove all environment variables. 
## If you want to see the variable that were create, simply don't execute that line (and clear them manually after)
rm(list = ls())