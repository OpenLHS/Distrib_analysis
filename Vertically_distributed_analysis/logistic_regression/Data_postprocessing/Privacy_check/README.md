# Privacy check

The allows a covariate-node to verify privacy-preserving properties when disclosing results such as estimates, standard errors and p-values.

## Table of contents

1. [Repository structure](#repository-structure)

	1. [Generic code](#generic-code)

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

- Generic_code  
The generic_code folder contains examplar `R` code files. Please read the code and its comments in the `R` file as files may require edition before being used.

### Generic code

The files in this folder can be used to support an example assessing privacy for a covariate node.  

## Data requirements

The covariate-node must use the following files to run the privacy assessment:

- Its own data file: `Data_node_k.csv`
- Its relevant output files sent by the response-node: `Coord_node_primerA_for_data_node_k.csv`, `Coord_node_primerB_for_data_node_k.rds`

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studion

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Covariate-nodes:
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [nleqslv](https://cran.r-project.org/web/packages/nleqslv/index.html)

Note that it might be necessary to install `Rtools` prior to using functions from `Rcpp` and `RcppArmadillo`: https://cran.r-project.org/bin/windows/Rtools/.

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Executing the code 

***Make sure `R studio` is not currently running and close it if it is.***
***The following assessment is useful for specific settings only, when the covariate-node aims to verify if it can safely share standard errors and p-values associated with continuous covariates. Please refer to original article before using.*** 

1.	Run the distributed algorithm above.
2.	Open the covariate-node `R` file (`Data_node_privacy_call_log-regV.R`).
3.  Specify the index of continuous estimates to disclose and run the `R` file (`Data_node_privacy_call_log-regV.R`).
4.	No files are generated, the results will be available in the `R` console.

## Expected outputs

***See original article for details before interpreting this output.***

In the `R` console, verify if a set of parameters for the rotation has been found and all other outputs show "TRUE" or "NA". 
If so, it confirms that the privacy assessment was done correctly and it can be assumed that an infinite number of solutions exists.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
