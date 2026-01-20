# Horizontally distributed poisson regression

## Before using

- Make sure to adjust the number of files `Data_node_call_poi-reg_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data. Should that not be the case, the main algorithm will save a copy of your original data (`Backup_Data_Incomplete_k.csv`) and will also save a new .csv file (`Data_node_k.csv`) that contains all complete rows of the original data. As such, it will be as if you were running a complete case analysis.
- ***OF NOTE, this is PURELY to demonstrate the feasibility of distributed poisson regression. The code here has NOT been optimised NOR made secure in a significant way. A thorough review NEEDS to be undertaken before using this code in any production/research project.***

## Repository structure

1. Poisson_regression_modelling  
This folder contains generic code and examples of a horizontally distributed poisson regression model.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The first column of your data file must be the outcome variable and must be named `out1`. This variable must only be non-negative integers.
- All other columns (predictor variables) must be in the same order and must share the same names across nodes.
- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values. Should there be any, they must be coded as `NA` values. In the case, the method will do a complete case analysis.
- (optional) Weights are expected to be saved in a separated `.csv` file.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
