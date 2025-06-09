# Response node split

This code allows the  response node to split its data in two parts:
- `outcome_data.csv`, a single column dataset which corresponds to the outcome variable.
- `Data_node_k.csv`, which corresponds to all other predictors available at the response node.

## Table of contents

1. [Repository structure](#repository-structure)

	1. [List of examples](#list-of-examples)

	2. [Generic code](#generic-code)

2. [Data requirements](#Data-requirements)

3. [Instructions to run the examples/algorithm](#instructions-to-run-the-examplesalgorithm)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Installing an example](#installing-an-example)
	
	4. [Executing the code](#executing-the-code)
	
4. [Expected outputs](#expected-outputs)

5. [License](#license)

6. [Copyright](#copyright-griis--université-de-sherbrooke)

## Repository structure

- Examples  
The examples folder contains a few examples. Each example is self-contained.

- Generic_code  
The generic_code folder contains examplar `R` code files. Please read the code and its comments in the `R` file as files may require edition before being used.

### List of examples

1. `random_data_same_folder`  
This folder makes it easy to look at the output since everything is happening in the same folder. There is no need to copy files across folders.

### Generic code

The files in this folder can be used to support an example splitting the data available at the reponse node.

## Data requirements

The response node must use the following file to split its data:

- Its own data file: `Data_node_k.csv`
- The first column of your data file must be the outcome variable and must be named `out1`. This variable must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values. 

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

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

1.	Open and run the response-node `R` file (`Response_node_call_log-regV.R`).

## Expected outputs

### Response node side

| Step | Files created | Shared? |
| ----------- | ----------- | ----------- |
| Single iteration | `outcome_data.csv` <br> `Data_node_k.csv`\* <br> `Backup_Data_node_k.csv`\* | Yes <br> No <br> No |

\* After running the code, the file `Backup_Data_node_k.csv` will correspond to the original data, whereas the file `Data_node_k.csv` will contain only the predictors in the original data.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
