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
Usecase: Weights in our horizontally distributed cox regression examples (see the folder `breast_data_with_weeights_same_folder` in that method).
	1. The first one (`breast_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`breast_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.

### Generic code

The files in this folder can be used to support an example aggregating the times of a dataset.  
Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute an aggregation of individuals for a data node.

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

### Executing the code 

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory, manually set the variable `manualwd = 1` in `Data_node_call_cox-reg_k.R` and  `Coord_node_call_iter_cox-reg.R`.***

1. In the file `data_node_call_precox_average.R`, select all the code and execute it. A new file will be generated, which contains the original data with modified times.
2. This data can now be used by a data node to participate into a privacy preserving Cox model.

## Expected outputs

### Data node side

| Step | Files created |
| ----------- | ----------- | 
| Data preparation | `Data_node_grouped_k.csv` |

### Coordination node side

The coordination node should not use this feature.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
