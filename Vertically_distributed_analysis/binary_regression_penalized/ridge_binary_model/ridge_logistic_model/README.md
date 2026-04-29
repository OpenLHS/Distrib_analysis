# Vertically distributed ridge-penalized binary regression (RidgeBin-V)

This implementation of the Vertical Ridge-Penalized Binary Regression leads to valid estimates for the ridge-penalized logistic regression model.
Provided a binomial family (family_glm) taking the value "logit" and a lambda sequence (lambda_seq), the results can be interpreted as they would with the following `R` calls in a pooled setting: 

- `lambda_central <- cv.glmnet(scale(X), y, family=binomial(link = family_glm), alpha = 0, lambda=lambda_seq,standardize=FALSE,thresh = 1e-25,maxit = 1e6)$lambda.min`

- `coef(glmnet(scale(X), y, family=binomial(link = family_glm),alpha=0,lambda=lambda_central, standardize=FALSE, thresh = 1e-25,maxit = 1e6))[,1]`

## Table of contents

0. [Before using](#before-using)

1. [Repository structure](#repository-structure)

2. [Data requirements](#Data-requirements)

3. [Instructions to run the examples/algorithm](#instructions-to-run-the-examplesalgorithm)

	1. [Installing R and R Studio](#installing-r-and-r-studio)
	
	2. [Installing the required packages](#installing-the-required-packages)
	
	3. [Executing the distributed code](#executing-the-distributed-code)
	
	4. [Executing the pooled solution code](#executing-the-pooled-solution-code)
	
4. [Expected outputs](#expected-outputs)

	1. [Response-node side](#response-node-side)
	
	2. [Predictor-node side](#predictor-node-side)

5. [License](#license)

6. [Copyright](#copyright-griis--université-de-sherbrooke)


## Before using

- To start over, it is important to delete all "output" files.
- The code currently works only with complete data.

## Repository structure

- example_random_data  
The examples folder contains an example of a vertically partitioned dataset to test the method if needed, with adapted `R` files to run the example in a pooled and in a vertical setting.

- generic_code_logistic
The generic_code_logistic folder contains `R` code files pertaining to the vertical approach for the ridge-penalized logistic regression model. Please read the code and its comments in the `R` file as files may require edition before being used.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The code is written so that the binary response output is coded using `0` and `1`. Make sure to follow this structure with your dataset.
- The response-node must be named `Data_node_1.csv`.
- The first column of the data file for the response-node should be the response vector with column name `out1`. Any additional predictor at the response-node (if applies) are put in the same data file as additional columns.
- Rows (individuals) must be in the same order in all data files across all nodes, including the response-node and predictor-nodes.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values.

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Predictor-nodes:
- [Matrix](https://cran.r-project.org/web/packages/Matrix/index.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)

Response-node:
- [glmnet](https://cran.r-project.org/web/packages/glmnet/index.html)
- [Matrix](https://cran.r-project.org/web/packages/Matrix/index.html)
- [pracma](https://cran.r-project.org/web/packages/pracma/index.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [RcppEigen](https://cran.r-project.org/web/packages/RcppEigen/index.html)
- [Rmpfr](https://cran.r-project.org/web/packages/Rmpfr/index.html)
- [withr](https://cran.r-project.org/web/packages/withr/index.html)

Response-node (additional packages required when running the privacy assessment):
- [ROI](https://cran.r-project.org/web/packages/ROI/index.html)
- [ROI.plugin.glpk](https://cran.r-project.org/web/packages/ROI.plugin.glpk/index.html)
- [ROI.plugin.symphony](https://cran.r-project.org/web/packages/ROI.plugin.symphony/index.html)
- [ROI.plugin.nloptr](https://cran.r-project.org/web/packages/ROI.plugin.nloptr/index.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [RcppEigen](https://cran.r-project.org/web/packages/RcppEigen/index.html)

Response-node (optional packages when running the privacy assessment - provided access to Gurobi):
- [slam](https://cran.r-project.org/web/packages/slam/index.html)
- [gurobi](https://cran.r-project.org/web/packages/prioritizr/vignettes/gurobi_installation_guide.html)
- [Rcpp](https://cran.r-project.org/web/packages/Rcpp/index.html)
- [RcppArmadillo](https://cran.r-project.org/web/packages/RcppArmadillo/index.html)
- [RcppEigen](https://cran.r-project.org/web/packages/RcppEigen/index.html)

Note that it might be necessary to install `Rtools` prior to using functions from `Rcpp`, `RcppArmadillo` and `RcppEigen` packages: https://cran.r-project.org/bin/windows/Rtools/.

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.


### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Response_node_call_iter_bin-regV_logistic.R` and  `Data_node_call_bin-regV_logistic.R`.***

In the following procedure, `k` represents the number of the predictor-node. In the Data files, Node `1` must be associated with the response-node. The `R` files mentioned in the procedure are found in the folder generic_code_logistic. 

Initialization:

1. Run the predictor-node `R` file (`Data_node_call_bin-regV_logistic.R`) for each predictor-node to compute local gram matrices.  
The file `Data_node_k_init_output.rds` will be generated and must be sent to the response-node.

For the single iteration, response-node side:

2. Run the response-node `R` file (`Response_node_call_iter_bin-regV_logistic.R`) to compute intermediary quantities for the predictor-nodes,
to obtain the unscaled intercept estimate at the response-node and to obtain parameter estimates associated with predictors at the response-node.
The files `Coord_node_primerA_for_data_node_k.csv` will be generated. These files must be shared with respective local node k.  
The file `Data_node_1_results.csv` will also be generated and contains results associated with the response-node.  
When running this code, indicate if you want to run the data-driven privacy validation at the response-node (default is YES). If so,
precise if you want to use Gurobi as solver (if available) to enhance performance. When the privacy validation is run, the file `privacy_output.csv` will be generated from the estimation procedure and used in the validation. 
The latter file SHOULD NOT be shared outside the response-node.


For the single iteration, predictor-node side:

3. Run the predictor-node `R` file (`Data_node_call_bin-regV_logistic.R`) for each predictor-node to compute parameter estimates and standard errors associated with the predictors it holds.  
The files `Data_node_k_results.csv` will be generated and contains results associated with the predictor-node. 

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `example_random_data/pooled`. You might need to copy the data files in this folder.
2. Open the file `Run_Pooled_Example.R`. It should then appear in `R`. Make sure that all manual parameters of the `R` file are set properly. 
3. Select all the code and click `run`.
4. The results will be available in the console.

## Expected outputs

This implementation leads to valid estimates for the ridge-penalized logistic regression model.
The results can be interpreted as they would with the following `R` calls in a pooled setting, with family_glm taking the value "logit": 

- `lambda_central <- cv.glmnet(scale(X), y, family=binomial(link = family_glm), alpha = 0, lambda=lambda_seq,standardize=FALSE,thresh = 1e-25,maxit = 1e6)$lambda.min`

- `coef(glmnet(scale(X), y, family=binomial(link = family_glm),alpha=0,lambda=lambda_central, standardize=FALSE, thresh = 1e-25,maxit = 1e6))[,1]`


Since this implementation is made for distributed analysis, the following `.csv` data files should not be shared:

- `Data_node_k.csv`.

### Response-node side

| Step | Files created | Shared with predictor-node k? |
| ----------- | ----------- | ----------- |
| Single iteration | `Data_node_1_results.csv`\* <br> `Coord_node_primerA_for_data_node_k.csv` <br> `privacy_output.rds` <br> `Index_NoFlip_k.csv`\*\* | No <br> Yes <br> No <br> No |

\*The file `Data_node_1_results.csv` contains the coefficients (parameter estimates) in their scaled version and original scales version (if there are any predictor at the response-node). The intercept estimate is only provided in its scaled version, but can be computed in its original scale if more information is provided from predictor-nodes.

\*\* The file `Index_NoFlip_k.csv` will only be created  if there is at least one entry in the response vector for which no flip was found by the solver. As mentioned previously, more investigation is required for those entries as a solution might very well exist but was simply not found by our basic implementation.

*If you chose to run the privacy assessment for the response variable, you will see `Flippable coordinate signs: X / N` in the console, where `N` is the sample size and `X` is the number of responses that could be recovered as both `-1` and `1`.*

### Predictor-node side

| Step | Files created | Shared with response-node? |
| ----------- | ----------- | ----------- |
| Initialization | `Data_node_k_init_output.rds` | Yes |
| Single iteration | `Data_node_k_results.csv`\* | No |

\*The file `Data_node_k_results.csv` contains the coefficients (parameter estimates) in their scaled version and original scales version.


## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
