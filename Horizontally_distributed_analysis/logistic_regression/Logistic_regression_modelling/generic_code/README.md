# Generic code

The files in this folder can be used to execute a horizontally distributed logistic regression analysis. Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a logistic regression model.

## Data requirements

- Data is expected to be saved in a `.csv` file.
- The first column of your data file must be the outcome variable and must be named `out1`. This variable must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- All other columns (predictor variables) must be in the same order and must share the same names across nodes.
- Each level for categorical variables is expected to have been possible to sample across all nodes. Otherwise, said level should either be removed or merged with another level.
- Categorical variables must be binarized before running this code. Binarized variables must use the values `0` or `1`, where `1` indicates a success (or having the characteristic).
- It is expected that there are no missing values. Should there be any, they must be coded as `NA` values. In the case, the method will do a complete case analysis.
- (optional) Weights are expected to be saved in a separated `.csv` file.

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

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Data_node_call_cox-reg_k.R` and  `Coord_node_call_iter_cox-reg.R`.***

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number. Note that the iteration number `t` increments everytime the coordination node is reached.

Initialization:

1. Run the local `R` file (`Data_node_call_log-reg_k.R`) for each data node to compute local settings and local beta estimates.  
The files `Data_node_k_iter_0.csv` and `Predictor_names` will be generated. All files must be sent to the coordination node.

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
