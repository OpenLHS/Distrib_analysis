# Privacy check (Part 1)

*Please read the following to make sure this step is relevant with the target analysis and coherent for the dataset at hand.*

This code allows a covariate-node to verify privacy-preserving properties when disclosing results such as estimates, standard errors and p-values.
The privacy check is composed of two parts. This first part should be conducted BEFORE running the VALORIS algorithm in any setting of the decision trees in the original article for which an infinite number of possibilities is indicated (see Original Article for details).


**For the following setting, the Privacy check (Part 2) should additionally be run before sharing standard errors and/or p-values**:
- Covariate-node does not assume that the response-node cleared intermediary quantities, and there are 4 or more continuous covariates at the covariate-node. 



## Table of contents

1. [Repository structure](#repository-structure)

	1. [Generic code](#generic-code)

2. [Data requirements](#Data-requirements)

3. [Instructions to run the examples/algorithm](#instructions-to-run-the-examplesalgorithm)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Executing the code](#executing-the-code)
	
4. [Expected outputs](#expected-outputs)

5. [License](#license)

6. [Copyright](#copyright-griis--université-de-sherbrooke)

## Repository structure

- Generic_code  
The generic_code folder contains examplar `R` code files. Please read the code and its comments in the `R` file as files may require edition before being used.

### Generic code

The files in this folder can be used to support an example assessing privacy for a covariate-node.  

## Data requirements

The covariate-node must use the following file to run the privacy assessment:

- Its own data file: `Data_node_k.csv`

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Covariate-nodes:
- [nleqslv](https://cran.r-project.org/web/packages/nleqslv/index.html)


Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Executing the code 

***Make sure `R studio` is not currently running and close it if it is.***
***The following assessment is useful for specific settings only, when the covariate-node aims to verify if it can safely share standard errors and p-values associated with continuous covariates. Please refer to original article before using.*** 

1.	Open and run the covariate-node `R` file (`Data_node_privacy_part1_call_log-regV.R`).
2.	No files are generated, the results will be available in the `R` console.

## Expected outputs

***See original article for details before interpreting this output.***

In the `R` console, verify if a set of parameters for the rotation has been found and all other outputs show "TRUE" or "NA". 
If so, it confirms that the privacy assessment was done correctly and it can be assumed that an infinite number of solutions exists.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
