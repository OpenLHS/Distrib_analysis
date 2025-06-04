# Horizontally distributed weights generation (Inverse Probability Weighting)

This algorithm allows one to computes the propensity score of an individual and the inverse probability weight associated with that score, using distributed logistic regression.  
Note that most assets from the horizontally distributed logistic regression are reused here.


## Table of contents

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

5. [License](#license-httpscreativecommonsorglicensesby-nc-sa40)

6. [Copyright](#copyright-griis--université-de-sherbrooke)

## Repository structure

- Examples  
The examples folder contains a few examples. Each example folder is self-contained. 

- Generic_code  
The generic_code folder contains examplar `R` code files. Please read the code and its comments in the `R` file as files may require edition before being used.

### List of examples

1. `random_data` and `random_data_same_folder` are based on the same example.
	1. The first one (`random_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where. 
	2. The second example (`random_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across folders.
2. `MatchIt_data` and `MatchIt_data_same_folder` are based on the same example. They both use the `Lalonde` data sets from the `R` package `MatchIt`. See [MatchIt](https://cran.r-project.org/web/packages/MatchIt/index.html).  
Usecase: Weights in our horizontally distributed linear and logistic regression examples (see the folder `MatchIt_data_with_weights` in each of those method).
	1. The first one (`MatchIt_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`MatchIt_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.
3. `breast_data` and `breast_data_same_folder` are based on the same example. They both use the "[Breast Cancer Dataset](https://www.kaggle.com/datasets/utkarshx27/breast-cancer-dataset-used-royston-and-altman)" from Royston and Altman (2013).  
Usecase: Weights in our horizontally distributed cox regression examples (see the folder `breast_data_with_weights_same_folder` in that method).
	1. The first one (`breast_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`breast_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.

### Generic code

The files in this folder can be used to support an example that generates weights for horizontally distribtued data.
This method assumes a data structure similar to the data nodes `.csv` files in the example folder.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The first column of your data file must be the outcome variable and must be named `Tx`. This variable must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- All other columns (predictor variables) must be in the same order and must share the same names across nodes.
- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values. Should there be any, they must be coded as `NA` values. In the case, the method will do a complete case analysis.
- (optional) Weights are expected to be saved in a separated `.csv` file.

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studion

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

There are no package not present in the base installation that are a requirement for this code to run.

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code 

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number. Note that the iteration number `t` increments everytime the coordination node is reached.

Initialization:

1. Run the local `R` file (`Data_node_call_log-reg_k.R`) for each data node to compute local settings and local beta estimates.  
The files `Data_node_k_iter_0_W_output.csv` and `Local_Settings_k.csv` will be generated. All files must be sent to the coordination node.

2. Run the coordination `R` file (`Coord_node_call_iter_log-reg.R`) to initialise the values of beta.  
The file `Coord_node_iter_1_primer.csv`  will be generated. This file must be shared with the local nodes.  
The file `Global_Predictor_names.csv` will also be generated if all nodes have the same data structure and estimation parameters. It does not need to be shared with the local nodes.

For the first iteration, data node side:

3. Run the local `R` file (`Data_node_call_log-reg_k.R`) for each data node to compute local aggregates used for derivatives.  
The file `Data_node_k_iter_1.csv` will be generated. It must be sent to the coordination node.

For the first iteration, coordinating node side:

4. Run the coordination `R` file (`Coord_node_call_iter_log-reg.R`)to compute first and second derivative and to update beta estimate.  
The files `Coord_node_iter_2_primer.csv`, `Coord_node_iter_1_covariance.csv` and `Coord_node_ter_1_results.csv` will be generated. To continue, the coordination node must share the file `Coord_node_iter_2_primer.csv` with the local nodes.

Then, to perform other iterations:

5. Run the local `R` file (`Data_node_call_log-reg_k.R`) for each data node to compute local aggregates used for derivatives.  
The file `Data_node_k_iter_(t).csv` will be generated. It must be sent to the coordination node.

6. Run the coordination `R` file (`Coord_node_call_iter_log-reg.R`)to compute first and second derivative and to update beta estimate.  
The files `Coord_node_iter_(t+1)_primer.csv`, `Coord_node_iter_(t)_covariance.csv` and `Coord_node_iter_(t)_results.csv` will be generated. To continue, the coordination node must share the file `Coord_node_iter_(t+1)_primer.csv` with the local nodes.

7. (optional) Compare the results of the previous iteration with the current one to decide if another iteration is pertinent (return to step `5`) or not.

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `examples/example_handler/pooled_comparator`. You might need to copy the data and weight files in this folder.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. 
4. Select all the code and click `run`.
5. The results will be available in the console.

## Expected outputs

This implementation of the logistic regression model mimics the following `R` calls: 
- `glm(formula, data, family="binomial", weights)`, whenever one checks `Coord_node_iter_t_results.csv` and once convergence is attained. 

Since this implementation is made for distributed analysis, the following `R` files should not be shared:
- `Data_node_k.csv`.
- `Weights_node_k.csv`.

### Data node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization | `Data_node_k_iter_0_output.csv` <br> `Predictor_names_k.csv` <br> `Backup_Data_node_Incomplete_k.csv`\* <br> `Backup_Weights_node_Incomplete_k.csv`\* | Yes <br> Yes <br> No <br> No |
| Iteration `1`  | `Data_node_k_iter_1_output.csv` | Yes |
| Iteration `t`  | `Data_node_k_iter_(t)_output.csv` | Yes |

\* The algorithm currently only works when there are no missing value. Should there be any missing value in the `Data_node_k.csv` file, the algorithm will perform a complete case analysis. In order to do so, it will save your data to a backup file and will replace `Data_node_k.csv` with only the complete cases.

### Coordination node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Initialization  | `Coord_node_iter_1_primer.csv` <br> `Global_Predictor_names.csv` | Yes <br> No |
| Iteration `1`   | `Coord_node_iter_2_primer.csv` <br> `Coord_node_iter_1_covariance.csv` <br> `Coord_node_iter_1_results.csv` | Yes <br> Does not apply <br> Does not apply |
| Iteration `t`   | `Coord_node_iter_(t+1)_primer.csv` <br> `Coord_node_iter_(t)_covariance.csv` <br> `Coord_node_iter_(t)_results.csv` | Yes <br> Does not apply <br> Does not apply |

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
