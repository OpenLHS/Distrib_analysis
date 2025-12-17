# Generic code

The files in this folder can be used to execute a vertically distributed logistic regression analysis. Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a vertically distributed logistic regression model.

## Before using

- ***OF NOTE:***  
	-  ***Our current implementation can lead to time-consuming computations at the response-node for large sample sizes `n`. Other box-constrained algorithms could be investigated to optimize those operations.***
	- ***When the privacy check for the response-node is run, a `.csv` file is created containing the indexes of the line-level entries in the response vector for which a flip was not found by the solver (if any). It would be recommended to try more sophisticated solvers to verify if a solution exists for those indexes (or increase the number of columns used in the null-matrix during the privacy assessment - see privacy source code (`Reponse_node_optionnal_confidentiality.R`) if needed), as a solution might very well exist but was simply not found by our basic implementation.***

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

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

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
- [CVXR](https://cran.r-project.org/web/packages/CVXR/index.html)

Response-node (additional packages required when running the privacy assessment):
- [ROI](https://cran.r-project.org/web/packages/ROI/index.html)
- [ROI.plugin.glpk](https://cran.r-project.org/web/packages/ROI.plugin.glpk/index.html)
- [ROI.plugin.symphony](https://cran.r-project.org/web/packages/ROI.plugin.symphony/index.html)
- [ROI.plugin.nloptr](https://cran.r-project.org/web/packages/ROI.plugin.nloptr/index.html)

Note that it might be necessary to install `Rtools` prior to using functions from `Rcpp`, `RcppArmadillo` and `RcppEigen` packages: https://cran.r-project.org/bin/windows/Rtools/.

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Response_node_call_iter_log-regV.R` and  `Data_node_call_log-regV.R`.***

In the following procedure, `k` represents the number of the predictor-node. In the Datafiles, Node `1` must be associated with the response-node. 

Initialization:

1. Run the predictor-node `R` file (`Data_node_call_log-regV.R`) for each predictor-node to compute local gram matrices.  
The file `Data_node_k_init_output.rds` will be generated and must be sent to the response-node.

For the single iteration, response-node side:

2. Run the response-node `R` file (`Response_node_call_iter_log-regV.R`) to compute intermediary quantities for the predictor-nodes,
to obtain the unscaled intercept estimate at the response-node and, if any, to obtain parameter estimates and standard errors associated with predictors at the response-node.  
The files `Coord_node_primerA_for_data_node_k.csv` will be generated. These files must be shared with respective local node k.  
The file `Data_node_1_results.csv` will also be generated and contains results associated with the response-node.  
When running this code, you will also be asked in a separate window if you want to run the privacy assessment for the response variable.

For the single iteration, predictor-node side:

3. Run the predictor-node `R` file (`Data_node_call_log-regV.R`) for each predictor-node to compute parameter estimates and standard errors associated with the predictors it holds.  
The files `Data_node_k_results.csv` will be generated and contains results associated with the predictor-node. 

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `examples/example_handler/pooled_comparator`. You might need to copy the data files in this folder.
2. Open the file `Solution.R`. It should then appear in `R`.
3. Make sure that all manual parameters of the coordination `R` file (`Solution.R`) are set properly. 
4. Select all the code and click `run`.
5. The results will be available in the console.

## Expected outputs

This implementation of the Vertical Logistic Ridge Regression leads to valid estimates for the logistic regression model (with no penalization).
The results can be interpreted as they would with the following `R` calls in a pooled setting: 
- `glmnet_model <- glmnet(x, y, family=binomial, lambda=lambda, alpha=0)`

Since this implementation is made for distributed analysis, the following `.csv` files should not be shared:
- `Data_node_k.csv`.

### Response-node side

| Step | Files created | Shared with predictor-node k? |
| ----------- | ----------- | ----------- |
| Single iteration | `Data_node_1_results.csv`\* <br> `Coord_node_primerA_for_data_node_k.csv` <br> `Index_NoFlip_k.csv`\*\* | No <br> Yes <br> Yes <br> No |

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
