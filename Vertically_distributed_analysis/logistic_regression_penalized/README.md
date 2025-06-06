# Vertically distributed penalized logistic regression

## Before using

- It is expected that all data nodes have access to the outcome variable. If that is not the case, the data note holding the outcome variable (labelled the *response node*) must first run the content in `Data_preprocessing/ResponseNode_Split`.
- Make sure to adjust the number of files `Data_node_call_log-regV_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data.

## Repository structure

1. Logistic_regression_modelling  
This folder contains generic code and examples of a vertically distributed logistic regression model.

2. Data_preprocessing  
This folder contains instructions on how to split the response node's data, which must be done before running this vertically distributed logistic regression model.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The outcome variable must be saved in its own file and be named `outcome_data.csv`.
- Rows (individuals) must be in the same order in all data files across all nodes, including the response-node and covariate-nodes.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
