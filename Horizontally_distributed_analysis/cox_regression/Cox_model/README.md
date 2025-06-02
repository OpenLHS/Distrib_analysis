# Horizontally distributed Cox model 

This implementation of the Cox model mimics the following `R` calls: 
- `coxph(formula, data, ties = “breslow”)`, whenever one checks `Results_iter_t.csv` and once convergence is attained.
- `coxph(formula, data, ties = “breslow”, weights, robust = TRUE)`, whenever one checks `RobustResults_t.csv` and once convergence is attained.

As both implementation use the same base files even if different amounts of information is shared troughout the algorithm, this guide has been splitted in two sections to better help users.

## Table of contents

1. [Repository structure](#repository-structure)

	1. [List of examples](#list-of-examples)
	
	2. [Generic code](#generic-code)

2. [Data requirements](#Data-requirements)

3. [Instructions to run the examples/algorithm (classic estimation)](#instructions-to-run-the-examplesalgorithm-classic-estimation)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Installing an example](#installing-an-example)
	
	4. [Executing the distributed code](#executing-the-distributed-code)
	
	5. [Executing the pooled solution code](#executing-the-pooled-solution-code)
	
4. [Instructions to run the examples/algorithm (robust estimation)](#instructions-to-run-the-examplesalgorithm-robust-estimation)

	1. [Installing R and R Studio](#installing-r-and-r-studio-1)
	
	2. [Installing the required packages](#installing-the-required-packages-1)
	
	3. [Installing an example](#installing-an-example-1)
	
	4. [Executing the distributed code](#executing-the-distributed-code-1)
	
	5. [Executing the pooled solution code](#executing-the-pooled-solution-code-1)
	
5. [Expected outputs (classic estimation)](#expected-outputs-classic-estimation)

	1. [Data node side](#data-node-side)
	
	2. [Coordination node side](#coordination-node-side)
	
6. [Expected outputs (robust estimation)](#expected-outputs-robust-estimation)

	1. [Data node side](#data-node-side-1)
	
	2. [Coordination node side](#coordination-node-side-1)

7. [License](#license)

8. [Copyright](#copyright-griis--université-de-sherbrooke)

## Repository structure

- The core article is in the root directory: "Lu et al. - 2015 - WebDISCO: A Web Service for Distributed Cox Model.pdf."  This describes the background of the work and presents the method used.

- Examples  
The examples folder contains a few examples. Each example can be ran directly from their specific folder. Therefore, some files will be duplicated across examples, but this is to facilitate their exploration independantly.

- Generic_code  
The generic_code folder contains examplar `R` code files pertaining to the distributed approach and its pooled comparator. Please read the code and its comments in the `R` file as files may require edition before being used.

### List of examples

- `random_data`, and `random_data_same_folder` are based on the same example (whereas `random_grouped_data`, `random_grouped_data_same_folder` and `random_grouped_data_with_weights_same_folder` are based on the same example where the data was aggregated).  
	- The first one has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.  
	- The second example is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across folders.

- `lung_data_same_folder` is an example based on the `lung` dataset in `R` (whereas `lung_data_grouped_same_folder` is based on the same example where the data was aggregated).

- `breast_data`, `breast_data_same_folder`, `breast_data_with_weights_same_folder` are based on the same example. They all use the "[Breast Cancer Dataset](https://www.kaggle.com/datasets/utkarshx27/breast-cancer-dataset-used-royston-and-altman)" from Royston and Altman (2013).  
	- The first one has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.  
	- The second example is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.  
	- The third example is based on the same dataset alongside weights files. Everything is happening in the same folder, without the need to copy files across.

- *Optional : if you want to try to generate new test datasets, the file `cox_data_generation.R` might be useful.*

### Generic code

The files in this folder can be used to execute a horizontally distributed cox regression analysis.
Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a Cox model.

## Data requirements

- Data is expected to be saved in a `.csv` file.

- The code is written so that `0 = censored` and `1 = event` for the `status` variable. Make sure to follow this structure with your dataset.

- The first two columns of your Data file must be named `time` and `status` (order not important).

- All other columns (predictor variables) must be in the same order and must share the same names across nodes.

- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.

- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).

- (optional) Weights are expected to be saved in a `.csv` file.

## Instructions to run the examples/algorithm (classic estimation)

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [survival](https://cran.r-project.org/web/packages/survival/index.html)
- [MASS](https://cran.r-project.org/web/packages/MASS/index.html)
- [data.table](https://cran.r-project.org/web/packages/data.table/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Data_node_call_cox-reg_k.R` and  `Coord_node_call_iter_cox-reg.R`.***

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number. Note that the iteration number `t` increments everytime the coordination node is reached.

Before running the code:

0. Since we want to use the classic variance estimation, we need to make sure that all manual parameters of the local `R` files (`Data_node_call_cox-reg_k.R`) are set properly. In the header section of the file, make sure that the variable `RobustVarianceFlag` is set to `FALSE`.

Initialization:

1. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local times and local beta estimates.  
The files `Beta_local_k.csv`, `N_node_k.csv`, `Times_k_output.csv`, `Vk_k.csv` and `Local_Settings_k.csv` will be generated. All files must be sent to the coordination node.

2. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global times and to initialise the values of beta.  
The files `Beta_0_output.csv` and `Global_times_output.csv` will be generated. These files must be shared with the local nodes.  
The file `Global_Settings.csv` will also be generated if all nodes have the same data structure and estimation parameters. It does not need to be shared with the local nodes.

For the first iteration (labelled iteration `t=0`), data node side:

3. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local parameters and local aggregates used for derivatives.  
The files `Rik_compk.csv`, `Rikk.csv`, `sumWExpk_output_t.csv`, `sumWZqExpk_output_t.csv`, `sumWZqZrExpk_output_t.csv`, `sumWZrk.csv` and `Wprimek.csv` will be generated. All files but `Rik_compk.csv` and `Rikk.csv` must be sent to the coordination node.

For the first iteration (labelled iteration `t=1`), coordinating node side:

4. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global parameters, to compute first and second derivative and to update beta estimate.  
The files `sumZrGlobal.csv` and `WprimeGlobal.csv` will be generated. They should be kept at the coordination node.  
The files `Beta_t_output.csv` and `Results_iter_t.csv` will be generated. To continue, the coordination node must share the file `Beta_t_output.csv` with the local nodes.

Then, to perform other iterations:

5. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local aggregates used for derivatives.  
The files `sumWExpk_output_t.csv`, `sumWZqExpk_output_t.csv` and `sumWZqZrExpk_output_t.csv` will be generated. All files must be sent to the coordination node.

6. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute first and second derivative and to update beta estimate.  
The file `Beta_t_output.csv` and `Results_iter_t.csv` will be generated. To continue, the coordination node must share the file `Beta_t_output.csv` with the local nodes.

7. (optional) Compare the results of the previous iteration with the current one to decide if another iteration is pertinent (return to step `5`) or not.

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***

1. Navigate to the folder `pooled_solution`.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Since we want to use the classic variance estimation, we need to make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. In the header section of the file, make sure that the variable `robust_flag` is set to `FALSE`.
4. Select all the code and click `run`.
5. The results will be available in the console.

## Instructions to run the examples/algorithm (robust estimation)

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [survival](https://cran.r-project.org/web/packages/survival/index.html)
- [MASS](https://cran.r-project.org/web/packages/MASS/index.html)
- [data.table](https://cran.r-project.org/web/packages/data.table/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is".

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Data_node_call_cox-reg_k.R` and  `Coord_node_call_iter_cox-reg.R`.***

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number.

Before running the code:

0. Since we want to use the robust variance estimation, we need to make sure that all manual parameters of the local `R` files (`Data_node_call_cox-reg_k.R`) are set properly. In the header section of the file, make sure that the variable `RobustVarianceFlag` is set to `TRUE`.

Initialization:

1. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local times and local beta estimates.  
The files `Beta_local_k.csv`, `N_node_k.csv`, `Times_k_output.csv`, `Vk_k.csv` and `Local_Settings_k.csv` will be generated. All files must be sent to the coordination node.

2. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global times and to initialise the values of beta.  
The files `Beta_0_output.csv` and `Global_times_output.csv` will be generated. These files must be shared with the local nodes.  
The file `Global_Settings.csv` will also be generated if all nodes have the same data structure and estimation parameters. It does not need to be shared with the local nodes.

For the first iteration (labelled iteration `t=0`), data node side:

3. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local parameters and local aggregates used for derivatives.  
The files `Rik_compk.csv`, `Rikk.csv`, `sumWExpk_output_t.csv`, `sumWZqExpk_output_t.csv`, `sumWZqZrExpk_output_t.csv`, `sumWZrk.csv` and `Wprimek.csv` will be generated. All files but `Rik_compk.csv` and `Rikk.csv` must be sent to the coordination node.

For the first iteration (labelled iteration `t=1`), coordinating node side:

4. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global parameters, to compute first and second derivative and to update beta estimate.  
The files `sumZrGlobal.csv` and `WprimeGlobal.csv` will be generated. They should be kept at the coordination node.  
The files `Beta_t_output.csv`, `Fisher_t.csv` and `Results_iter_t.csv` will be generated. To continue, the coordination node must share all files but `Results_iter_t.csv` with the local nodes.

Then, to perform other iterations:

5. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local aggregates used for derivatives.  
The files `sumWExpk_output_t.csv`, `sumWZqExpk_output_t.csv` and `sumWZqZrExpk_output_t.csv` will be generated. All files must be sent to the coordination node.  
In order to compute the robust variance estimator, additionnal files `inverseWExp_k_output_(t-2).csv`, `zbarri_inverseWExp_k_output_(t-2).csv` and `DDk_output_(t-3).csv` will be generated whenever `t-x` is greater than `0`. All files must be sent to the coordination node.

6. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute first and second derivative and to update beta estimate.  
The file `Beta_t_output.csv`, `Fisher_t.csv` and `Results_iter_t.csv` will be generated. 
In order to compute the robust variance estimator, additionnal files `sumWExpGlobal_output_(t-1).csv`, `zbarri_(t-1).csv`, `zbarri_inverseWExp_Global_output_(t-2).csv`, `inverseWExp_t_Global_output_(t-2).csv` and `RobustResults_iter_(t-3).csv` will be generated whenever `t-x` is greater than `0`. All files but `RobustResults_iter_(t-3).csv` must be sent to the local nodes.

7. (optional) Compare the results of the previous iteration with the current one to decide if another iteration is pertinent (return to step `5`) or not.

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***

1. Navigate to the folder `pooled_solution`.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Since we want to use the robust variance estimation, we need to make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. In the header section of the file, make sure that the variable `robust_flag` is set to `TRUE`.
4. Select all the code and click `run`.
5. The results will be available in the console.

## Expected outputs (classic estimation)

This implementation of the Cox model mimics the following `R` call: 
- `coxph(formula, data, ties = “breslow”)`, whenever one checks `Results_iter_t.csv` and once convergence is attained.

Since this implementation is made for distributed analysis, the following `R` files should not be shared:
- `Data_node_k.csv`.
- `Weights_node_k.csv`.

### Data node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization | `Beta_local_k.csv` <br> `N_node_k.csv` <br> `Local_Settings_k.csv` <br> `Times_k_output.csv` <br> `Vk_k.csv` <br> `Backup_Data_node_Incomplete_k.csv`\* <br> `Backup_Weights_node_Incomplete_k.csv`\* <br> `Backup_Data_node_Unordered_k.csv`\*\* <br> `Backup_Weights_node_Unordered_k.csv`\*\* | Yes <br> Yes <br> Yes <br> Yes <br> Yes <br> No <br> No <br> No <br> No |
| Iteration `0` | `Rik_comp_k.csv` <br> `Rikk.csv` <br> `sumWExpk_output_0.csv` <br> `sumWZqExpk_output_0.csv` <br> `sumWZqZrExpk_output_0.csv` <br> `sumWZrk.csv` <br> `Wprimek.csv `| No <br> No <br> Yes <br> Yes <br> Yes <br> Yes <br> Yes |
| Iteration `1` | `sumWExpk_output_1.csv` <br> `sumWZqExpk_output_1.csv` <br> `sumWZqZrExpk_output_1.csv` | Yes <br> Yes <br> Yes|
| Iteration `t` | `sumWExpk_output_(t).csv` <br> `sumWZqExpk_output_(t).csv` <br> `sumWZqZrExpk_output_(t).csv` | Yes <br> Yes <br> Yes|

\* The algorithm currently only works when there are no missing value. Should there be any missing value in the `Data_node_k.csv` file, the algorithm will perform a complete case analysis. In order to do so, it will save your data to a backup file and will replace `Data_node_k.csv` with only the complete cases.

\*\* The algorithm currently expects the `time` variable do be ordered. If it isn't, it will save your data to a backup file and will replace `Data_node_k.csv` with the same data but ordered by `time`.

### Coordination node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization  | `Beta_0_output.csv` <br> `Global_Settings.csv` <br> `Global_times_output.csv` | Yes <br> No <br> Yes |
| Iteration `1` | `Beta_1_output.csv` <br> `Results_iter_1.csv` <br> `sumWZrGlobal.csv` <br> `WprimeGlobal.csv` | Yes <br> Does not apply <br> Yes <br> Yes |
| Iteration `t` | `Beta_(t)_output.csv` <br> `Results_iter_(t).csv` | Yes <br> Does not apply |  


## Expected outputs (robust estimation)

This implementation of the Cox model mimics the following `R` call: 
- `coxph(formula, data, ties = “breslow”, weights, robust = TRUE)`, whenever one checks `RobustResults_t.csv` and once convergence is attained.

### Data node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization | `Beta_local_k.csv` <br> `N_node_k.csv` <br> `Local_Settings_k.csv` <br> `Times_k_output.csv` <br> `Vk_k.csv` <br> `Backup_Data_node_Incomplete_k.csv`\* <br> `Backup_Weights_node_Incomplete_k.csv`\* <br> `Backup_Data_node_Unordered_k.csv`\*\* <br> `Backup_Weights_node_Unordered_k.csv`\*\* | Yes <br> Yes <br> Yes <br> Yes <br> Yes <br> No <br> No <br> No <br> No |
| Iteration `0` | `Rik_comp_k.csv` <br> `Rikk.csv` <br> `sumWExpk_output_0.csv` <br> `sumWZqExpk_output_0.csv` <br> `sumWZqZrExpk_output_0.csv` <br> `sumWZrk.csv` <br> `Wprimek.csv `| No <br> No <br> Yes <br> Yes <br> Yes <br> Yes <br> Yes |
| Iteration `1` | `sumWExpk_output_1.csv` <br> `sumWZqExpk_output_1.csv` <br> `sumWZqZrExpk_output_1.csv` | Yes <br> Yes <br> Yes|
| Iteration `2` | `sumWExpk_output_2.csv` <br> `sumWZqExpk_output_2.csv` <br> `sumWZqZrExpk_output_2.csv` | Yes <br> Yes <br> Yes|
| Iteration `3` | `sumWExpk_output_3.csv` <br> `sumWZqExpk_output_3.csv` <br> `sumWZqZrExpk_output_3.csv` <br> `inverseWExp_k_output_1.csv` <br> `zbarri_inverseWExp_k_output_1.csv` | Yes <br> Yes <br> Yes <br> Yes <br> Yes |
| Iteration `4` | `sumWExpk_output_4.csv` <br> `sumWZqExpk_output_4.csv` <br> `sumWZqZrExpk_output_4.csv` <br> `inverseWExp_k_output_2.csv` <br> `zbarri_inverseWExp_k_output_2.csv` <br> `DDk_output_1` | Yes <br> Yes <br> Yes <br> Yes <br> Yes <br> Yes |
| Iteration `t` | `sumWExpk_output_(t).csv` <br> `sumWZqExpk_output_(t).csv` <br> `sumWZqZrExpk_output_(t).csv` <br> `inverseWExp_k_output_(t-2).csv` <br> `zbarri_inverseWExp_k_output_(t-2).csv` <br> `DDk_output_(t-3)` | Yes <br> Yes <br> Yes <br> Yes <br> Yes <br> Yes  |

\* The algorithm currently only works when there are no missing value. Should there be any missing value in the `Data_node_k.csv` file, the algorithm will perform a complete case analysis. In order to do so, it will save your data to a backup file and will replace `Data_node_k.csv` with only the complete cases.

\*\* The algorithm currently expects the `time` variable do be ordered. If it isn't, it will save your data to a backup file and will replace `Data_node_k.csv` with the same data but ordered by `time`.

### Coordination node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization  | `Beta_0_output.csv` <br> `Global_Settings.csv` <br> `Global_times_output.csv` | Yes <br> No <br> Yes |
| Iteration `1` | `Beta_1_output.csv` <br> `Fisher_1.csv` <br> `Results_iter_1.csv` <br> `sumWZrGlobal.csv` <br> `WprimeGlobal.csv` | Yes <br> Yes <br> Does not apply <br> No <br> No |
| Iteration `2` | `Beta_2_output.csv` <br> `Fisher_2.csv` <br> `Results_iter_2.csv` <br> `sumWExpGlobal_output_1.csv` <br> `zbarri_1.csv` | Yes <br> Yes <br> Does not apply <br> Yes <br> Yes|
| Iteration `3` | `Beta_3_output.csv` <br> `Fisher_3.csv` <br> `Results_iter_3.csv` <br> `sumWExpGlobal_output_2.csv` <br> `zbarri_2.csv` <br> `zbarri_inverseWExp_Global_output_1.csv` <br> `inverseWExp_t_Global_output_1.csv` | Yes  <br> Yes <br> Does not apply <br> Yes <br> Yes <br> Yes |
| Iteration `4` | `Beta_4_output.csv` <br> `Fisher_4.csv` <br> `Results_iter_4.csv` <br> `sumWExpGlobal_output_3.csv` <br> `zbarri_3.csv` <br> `zbarri_inverseWExp_Global_output_2.csv` <br> `inverseWExp_t_Global_output_2.csv` <br> `RobustResults_iter_1.csv` | Yes <br> Yes <br> Does not apply <br> Yes <br> Yes <br> Yes <br> Yes <br> Does not apply |
| Iteration `t` | `Beta_(t)_output.csv` <br> `Fisher_(t).csv` <br> `Results_iter_(t).csv` <br> `sumWExpGlobal_output_(t-1).csv` <br> `zbarri_(t-1).csv` <br> `zbarri_inverseWExp_Global_output_(t-2).csv` <br> `inverseWExp_t_Global_output_(t-2).csv` <br> `RobustResults_iter_(t-3).csv` | Yes <br> Yes <br> Does not apply <br> Yes <br> Yes <br> Yes <br> Yes <br> Does not apply |

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
