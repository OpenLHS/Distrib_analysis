# Horizontally distributed linear regression 

This implementation of the linear regression model mimics the method presented in the brief summary.


## Table of contents

1. [Repository structure](#repository-structure)

	1. [List of examples](#list-of-examples)
	
	2. [Generic code](#generic-code)

2. [Before using](#Before-using)

3. [Data requirements](#Data-requirements)
	
4. [Instructions to run the examples/algorithm](#instructions-to-run-the-examplesalgorithm)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Installing an example](#installing-an-example)
	
	4. [Executing the distributed code](#executing-the-distributed-code)
	
	5. [Executing the pooled solution code](#executing-the-pooled-solution-code)
	
5. [Expected outputs](#expected-outputs)

	1. [Data node side](#data-node-side)
	
	2. [Coordination node side](#coordination-node-side)
	
6. [License](#license)

7. [Copyright](#copyright-griis--université-de-sherbrooke)

## Repository structure

- Examples  
The examples folder contains a few examples. Each example can be ran directly from their specific folder. Therefore, some files will be duplicated across examples, but this is to facilitate their exploration independantly.

- Generic_code  
The generic_code folder contains examplar `R` code files pertaining to the distributed approach and its pooled comparator. Please read the code and its comments in the `R` file as files may require edition before being used.

### List of examples

1. `random_data`, `random_data_same_folder`, `random_data_same_folder_missing` and `random_data_with_weights_same_folder` are based on the same example.
	1. The first one (`random_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. All the other ones are based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.
	3. The third example (`random_data_same_folder_missing`) is based on the same dataset but has some missing data in the first data node. This will allow one to know how the method behaves when it has to do a complete case analysis.
	4. The fourth example (`random_data_with_weights_same_folder`) is based on the same dataset and also uses weights. The weights used were chosen randomly.	

2. `MatchIt_data_with_weights` and `MatchIt_data_with_weights_same_folder` are based on the same example. They both use the `Lalonde` data sets from the `R` package `MatchIt`. See [MatchIt](hps://cran.r-project.org/web/packages/MatchIt/index.html).  
For both examples, the weights are the ones obtained from running the content of the `Weights_generation_for_IPW` with the MatchIt example.

	1. The first one (`MatchIt_data_with_weights`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`MatchIt_data_with_weights_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.

3.  `newborn_data_same_folder` is yet another example.

### Generic code

The files in this folder can be used to execute a horizontally distributed linear regression analysis.
Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a horizontally distributed linear regression.

## Before using

- Make sure to adjust the number of files `Data_node_call_lin-reg_k.R` according to the number of nodes, and make sure to change the value of `manualk` to the node number.
- To start over, it is important to delete all "output" files.
- The code currently works only with complete data. Should that not be the case, the main algorithm will save a copy of your original data (`Backup_Data_Incomplete_k.csv`) and will also save a new .csv file (`Data_node_k.csv`) that contains all complete rows of the original data. As such, it will be as if you were running a complete case analysis.
- ***OF NOTE, this is PURELY to demonstrate the feasibility of distributed linear regressions. The code here has NOT been optimised NOR made secure in a significant way. A thorough review NEEDS to be undertaken before using this code in any production/research project.***

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The first column of your data file must be the outcome variable (`out1`). # (!) On devrait probablement changer ici le y->out1. À valider aussi dans les fichiers de données si tout est beau.
- All other columns (predictor variables) must be in the same order and must share the same names across nodes.
- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values. Should there be any, they must be coded as `NA` values. In the case, the method will do a complete case analysis.
- (optional) Weights are expected to be saved in a `.csv` file.

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [KS](https://cran.r-project.org/web/packages/ks/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Data_node_call_lin-reg_k.R` and  `Coord_node_lin-reg.R`.***

In the following procedure, `k` represents the number of the local node.

1. Run the local `R` file (`Data_node_call_lin-reg_k.R`) for each data node to compute local matrix products.
The files `Predictor_names_k.csv` and `Nodek_output.csv` will be generated. All files must be sent to the coordination node.

2. Run the coordination `R` file (`Coord_node_lin-reg.R`) to compute global estimates.  
The file `CoordNode_results_distributed_lin_reg.csv` will be generated. 

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `examples/example_handler/pooled_comparator`. You might need to copy the data and weight files in this folder.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. 
4. Select all the code and click `run`.
5. The results will be available in the console.

## Expected outputs

This implementation of the linear regression model mimics the method presented in the brief summary.

Since this implementation is made for distributed analysis, the following `R` files should not be shared:
- `Data_node_k.csv`.
- `Weights_node_k.csv`.

### Data node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Single iteration | `Predictor_names_k.csv` <br> `Nodek_output.csv` <br> `Backup_Data_node_Incomplete_k.csv`\* <br> `Backup_Weights_node_Incomplete_k.csv`\* | Yes <br> Yes <br> No <br> No |

\* The algorithm currently only works when there are no missing value. Should there be any missing value in the `Data_node_k.csv` file, the algorithm will perform a complete case analysis. In order to do so, it will save your data to a backup file and will replace `Data_node_k.csv` with only the complete cases.

### Coordination node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Single iteration | `CoordNode_results_distributed_lin_reg.csv` |  Does not apply  |

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
