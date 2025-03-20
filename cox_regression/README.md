# Distributed WebDisco-based implementation

## Repository structure

1. The core article "Lu et al. - 2015 - WebDISCO: A Web Service for Distributed Cox Model.pdf" describes the background of the work and presents the method used.

2. Cox_model  
This folder contains generic code and examples of the distributed Cox model.

3. Data_preparation  
This folder contains instructions on how to prepare your data before running the code of the Cox model.

## Before using

- **The Cox model does not ensure data privacy by itself. The data must be aggregated first to ensure confidentiality. (See the folder `Data_preparation`)**
- Make sure to adjust the number of files `Data_node_call_cox-reg_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- Make sure that all local files `Data_node_call_cox-reg_k.R` set the variable `RobustVarianceFlag` to the same value (`TRUE` for a robust variance estimation, `FALSE` for a classic variance estimation).
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data. Should that not be the case, the main algorithm will save a copy of your original data (`Backup_Data_Incomplete_k.csv`) and will also save a new .csv file (`Data_node_k.csv`) that contains all complete rows of the original data. As such, it will be as if you were running a complete case analysis.
- ***OF NOTE, this is PURELY to demonstrate the feasibility of distributed Cox models. The code here has NOT been optimised NOR made secure in a significant way. A thorough review NEEDS to be undertaken before using this code in any production/research project.***

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The code is written so that `0 = censored` and `1 = event` for the `status` variable. Make sure to follow this structure with your dataset.
- The first two columns of your Data file must be named `time` and `status` (order not important).
- All other columns (predictor variables) must be in the same order and must share the same names across nodes.
- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- (optional) Weights are expected to be saved in a separated `.csv` file.

Note: While it is not a requirement, the algorithm expects your data to be ordered by time. Should that not be the case, the main algorithm will save a copy of your original data (`Backup_Data_Unordered_k.csv`) and will also save a new `.csv` file (`Data_node_k.csv`) that is ordered by time.

### License: https://creativecommons.org/licenses/by-nc-sa/4.0/

### Copyright: GRIIS / Université de Sherbrooke
