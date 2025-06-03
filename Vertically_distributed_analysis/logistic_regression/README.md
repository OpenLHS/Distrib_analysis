# Vertically distributed logistic regression

## Before using

- Make sure to adjust the number of files `Data_node_call_log-regV_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data.

## Repository structure

1. Logistic_regression_modelling  
This folder contains generic code and examples of a vertically distributed logistic regression model.

2. Data_preprocessing  
This folder contains instructions on how to prepare your data before running the code of a horizontally distributed model.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The code is written so that the binary response output is coded using `0` and `1`. Make sure to follow this structure with your dataset.
- The response-node must be named `Data_node_1.csv`.
- The first column of the data file for the response-node should be the response vector with column name `out1`. Any additional covariate at the response-node (if applies) are put in the same data file as additional columns.
- Rows (individuals) must be in the same order in all data files across all nodes, including the response-node and covariate-nodes.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
