# Vertically distributed penalized Logistic Regression

This implementation of the Vertical Logistic Regression leads to valid estimates for the logistic regression model (with no penalization).
The results can be interpreted as they would with the following `R` calls in a pooled setting: 
- `glmnet_model <- glmnet(scale(x), y, family=binomial, lambda=lambda, alpha=0, standardize=FALSE)`

## Table of contents

0. [Before using](#before-using)

1. [Repository structure](#repository-structure)

	1. [List of examples](#list-of-examples)
	
	2. [Generic code](#generic-code)

2. [Data requirements](#Data-requirements)

3. [Instructions to run the examples/algorithm](#instructions-to-run-the-examplesalgorithm)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Installing an example](#installing-an-example)
	
	4. [Executing the distributed code](#executing-the-distributed-code)
	
	5. [Executing the pooled solution code](#executing-the-pooled-solution-code)
	
4. [Expected outputs](#expected-outputs)

	1. [Data node side](#data-node-side)
	
	2. [Coordination node side](#coordination-node-side)

5. [License](#license)

6. [Copyright](#copyright-griis--université-de-sherbrooke)


## Before using

- It is expected that all data nodes have access to the outcome variable. If that is not the case, the data note holding the outcome variable (labelled the *response node*) must first run the content in `Data_preprocessing/ResponseNode_Split`.
- Make sure to adjust the number of files `Data_node_call_log-regV_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data.

## Repository structure

- The core article (Preprint) is in the root directory: "Domingue et al. - 2025 - Revisiting VERTIGO and VERTIGO-CI.pdf."  This describes the background of the work and presents the method used. 

- Examples  
The examples folder contains an example of a vertically partitioned dataset to test the method if needed.

- Generic_code  
The generic_code folder contains `R` code files pertaining to the distributed approach. Please read the code and its comments in the `R` file as files may require edition before being used.

### List of examples

1. `random_data_same_folder`  
   This folder makes it easy to look at the output since everything is happening in the same folder. There is no need to copy files across folders.

### Generic code

The files in this folder can be used to execute a vertically distributed logistic regression analysis. Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation of a coordination node operation for a vertically distributed logistic regression model.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The outcome variable must be saved in its own file and be named `outcome_data.csv`. It is expected that the outcome variable has been extracted and taken out of its respective dataset before running this method.
- Rows (individuals) must be in the same order in all data files across all nodes, including the file `outcome_data.csv`.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values.

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Data nodes:
- There are no package not present in the base installation that are a requirement for this code to run.

Coord node:
- [CVXR](https://cran.r-project.org/web/packages/CVXR/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Coord_node_call_iter_log-regV.R` and  `Data_node_call_log-regV.R`.***

In the following procedure, `k` represents the number of the local node.

Initialization:

1. Run the data node `R` file (`Data_node_call_log-regV.R`) for each data node to compute local gram matrices.   
The file `Data_node_k_init_output.rds` will be generated and must be sent to the coordination node.

For the single iteration, coordination node side:

2. Run the coordination node `R` file (`Coord_node_call_iter_log-regV.R`) to compute the optimal dual parameters and to obtain parameter estimates for the intercept.
The file `Coord_node_results_distributed_log_regV.csv` will be generated and contains those results.  This file must be shared with each local node k.  

For the single iteration, data node side:

3. Run the data node `R` file (`Data_node_call_log-regV.R`) for each data node to compute parameter estimates and standard errors associated with the covariates it holds.  
The files `Data_node_k_results.csv` will be generated and contains results associated with the data node. 

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `examples/example_handler/pooled_comparator`. You might need to copy the data files in this folder.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. 
4. Select all the code and click `run`.
5. The results will be available in the console.

## Expected outputs

This implementation of the Vertical Logistic Regression leads to valid estimates for the logistic regression model (with no penalization).
The results can be interpreted as they would with the following `R` calls in a pooled setting: 
- `glmnet_model <- glmnet(scale(x), y, family=binomial, lambda=lambda, alpha=0, standardize=FALSE)`

Since this implementation is made for distributed analysis, the following `.csv` files should not be shared:
- `Data_node_k.csv`.

However, it is expected that all data nodes and the coordination node have access to the following `.csv` file:
- `outcome_data.csv`.

### Data node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization | `Data_node_k_init_output.rds` | Yes |
| Single iteration | `Data_node_k_results.csv` | Does not apply |

### Coordination node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Single iteration | `Coord_node_results_distributed_log_regV.csv` | Yes |

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
