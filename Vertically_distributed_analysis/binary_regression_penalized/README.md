# Vertically distributed ridge-penalized binary regression (RidgeBin-V)

## Repository structure

- ridge_binary_model: This folder contains generic code and examples of vertically distributed ridge-penalized binary regression models. Specific subfolders are designed to conduct analyses with the logistic regression model, the probit model and the cloglog model. To avoid code files duplicates, additional subfolders contain common code files used for the procedure with all three models. 
RidgeBin-V does not require to share the response vector outside the response-node and allows the response-node to conduct cross-validation for the choice of the penalty parameter.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The code is written so that the binary response output is coded using `0` and `1`. Make sure to follow this structure with your dataset.
- The response-node must be named `Data_node_1.csv`.
- The first column of the data file for the response-node should be the response vector with column name `out1`. Any additional predictor at the response-node (if applies) are put in the same data file as additional columns.
- Rows (individuals) must be in the same order in all data files across all nodes, including the response-node and predictor-nodes.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
