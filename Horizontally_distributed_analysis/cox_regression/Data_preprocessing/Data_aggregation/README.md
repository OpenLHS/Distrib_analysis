# Data aggregation

This algorithm allows one to group data using the `time` variable of a Cox regression.

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

- Average  
Orders the data by time and averages the time values across a specified number of individuals.

### Generic code

The files in this folder can be used to support an example aggregating the times of a dataset.  
Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute an aggregation of individuals for a data node.

## Data requirements

- Data is expected to be saved in a `.csv` file. 
- The code is written so that `0 = censored` and `1 = event` for the `status` variable. Make sure to follow this structure with your dataset.
- The first two columns of your Data file must be named `time` and `status` (order not important).

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. R should prompt you to download the packages automatically.

- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will need to manually set your working sirectory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the code 

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory, manually set the variable `manualwd = 1` in `data_node_call_precox_average.R`.***

1. Open the file `data_node_call_precox_average.R`.
2. You will need to change the value of `eventbucketsize` according to your specific situation.
3. Select all the code in the file `data_node_call_precox_average.R` and execute it. A new file will be generated, which contains the original data with modified times.

This data can now be used by a data node to participate into a privacy preserving Cox model.

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
