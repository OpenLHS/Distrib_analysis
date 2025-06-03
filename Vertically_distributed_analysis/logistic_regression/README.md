# Vertically distributed Logistic Regression

This implementation of the Vertical Logistic Regression leads to valid estimates and standard errors for the logistic regression model (with no penalization).
The results can be interpreted as they would with the following `R` calls in a pooled setting: 
- `glm(formula, data, family = “binomial”)`

## Table of contents

0. [Before using](#before-using)

1. [Repository structure](#repository-structure)

	a. [List of examples](#list-of-examples)
	
	b. [Generic code](#generic-code)

2. [Instructions to run the algorithm](#instructions-to-run-the-algorithm)

	a. [Installing R and R Studio](#installing-r-and-r-studio)
	
	b. [Installing the required packages](#installing-the-required-packages)
	
	c. [Executing the distributed algorithm code](#executing-the-distributed-code)
	
	d. [Executing the privacy assessment code](#executing-the-privacy-assessment-code)
	
3. [Expected outputs](#expected-outputs)

	a. [Response-node side](#response-node-side)
	
	b. [Covariate-node side](#covariate-node-side)
	
	c. [Covariate-node side - Privacy assessment](#covariate-node-side-privacy-assessment)

4. [License](#license-httpscreativecommonsorglicensesby-nc-sa40)

5. [Copyright](#copyright-griis--université-de-sherbrooke)


## Before using

- The implementation was tested to operate using R version 4.4.1.
- Data requirements should be read and followed before running.


## Repository structure

- The core article (Preprint) is in the root directory: "Camirand Lemyre et al. - 2025 - Vertically Distributed Logistic Regression.pdf."  This describes the background of the work and presents the method used. 

- Examples  
The examples folder contains an example of a vertically partitioned dataset to test the method if needed.

- Generic_code  
The generic_code folder contains `R` code files pertaining to the distributed approach. Please read the code and its comments in the `R` file as files may require edition before being used.

- Privacy_check
The privacy_check folder contains `R` code files allowing one covariate-node to verify privacy-preserving properties while disclosing results such as estimates, standard errors and p-values.

### List of examples

- `random_data_same_folder` contains two datasets corresponding to different nodes in a vertically distributed analysis. They can be copied and used to run examples of the method and compare with the pooled results. 

### Generic code

The files in this folder can be used to execute a vertically distributed logistic regression analysis.
The generic code assumes a data structure with one response-node holding the response-vector (and potentially covariates) and covariate-nodes holding only covariates.

## Instructions to run the algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Covariate-nodes:
- [Matrix](https://cran.r-project.org/web/packages/Matrix/index.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [nleqslv](https://cran.r-project.org/web/packages/nleqslv/index.html)

Response-node:
- [Matrix](https://cran.r-project.org/web/packages/Matrix/index.html)
- [glmnet](https://cran.r-project.org/web/packages/glmnet/index.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [Rmpfr](https://cran.r-project.org/web/packages/Rmpfr/index.html)
- [pracma](https://cran.r-project.org/web/packages/pracma/index.html)
- [RcppEigen](https://cran.r-project.org/web/packages/RcppEigen/index.html)

Note that it might be necessary to install Rtools prior to using functions from Rcpp, RcppArmadillo and RcppEigen packages: https://cran.r-project.org/bin/windows/Rtools/.

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.


### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Response_node_call_iter_log-regV.R` and  `Data_node_call_log-regV.R`.***

In the following procedure, `k` represents the number of the local node. In the Datafiles, Node 1 must be associated with the response-node. 

Initialization:

1. Run the covariate-node `R` file (`Data_node_call_log-regV.R`) for each covariate-node to compute local gram matrices.  
The file `Data_node_k_init_output.rds` will be generated and must be sent to the response-node.

2. Run the response-node `R` file (`Response_node_call_iter_log-regV.R`) to compute intermediary quantities for the covariate-nodes,
to obtain the unscaled intercept estimate at the response-node and, if any, to obtain parameter estimates and standard errors asssociated with covariates at the response-node.  
The files `Coord_node_primerA_for_data_node_k.csv` and `Coord_node_primerB_for_data_node_k.rds` will be generated. These files must be shared with respective local node k.  
The file `Data_node_1_results.csv` will also be generated and contains results associated with the response-node. 

3. Run the covariate-node `R` file (`Data_node_call_log-regV.R`) for each covariate-node to compute parameter estimates and standard errors associated with the covariates it holds.  
The files `Data_node_k_results.csv` will be generated and contains results associated with the covariate-node. 


### Executing the privacy assessment code

***Make sure `R studio` is not currently running and close it if it is.***
***The following assessment is useful for specific settings only, when the covariate-node aims to verify if it can safely share standard errors and p-values associated with continuous covariates. Please refer to original article before using.*** 

1.	Run the distributed algorithm above.
2.	Open the covariate-node `R` file (`Data_node_privacy_call_log-regV.R`).
3.  Specify the index of continuous estimates to disclose and run the `R` file (`Data_node_privacy_call_log-regV.R`).
4.	No files are generated, the results will be available in the `R` console.


## Expected outputs


### Response-node side

| Step | Files created | Shared with covariate-node k? |
| ----------- | ----------- | ----------- |
| Single iteration | `Data_node_1_results.csv` <br> `Coord_node_primerA_for_data_node_k.csv` <br> `Coord_node_primerB_for_data_node_k.rds` | No <br> Yes <br> Yes |

The file `Data_node_1_results.csv` contains the scaled intercept coefficient and standard error, along with the coefficients (parameter estimates) and standard errors in their original scales (if any covariate at the response-node). The two-sided p-values are also provided.

### Covariate-node side

| Step | Files created | Shared with response-node? |
| ----------- | ----------- | ----------- |
| Initialization | `Data_node_k_init_output.rds` | Yes |
| Single iteration | `Data_node_k_results.csv` | No |

The file `Data_node_k_results.csv` contains the coefficients (parameter estimates) and standard errors in their original scales. The two-sided p-values are also provided.


### Data node side - Privacy Assessment

***See original article for details before interpreting this output.***

In the `R` console, verify if a set of parameters for the rotation has been found and all other outputs show "TRUE" or "NA". 
If so, it confirms that the privacy assessment was done correctly and it can be assumed that an infinite number of solutions exists.

### License: https://creativecommons.org/licenses/by-nc-sa/4.0/

### Copyright: GRIIS / Université de Sherbrooke
