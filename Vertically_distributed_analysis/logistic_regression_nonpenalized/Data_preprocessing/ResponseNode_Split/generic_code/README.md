# Generic code

The files in this folder can be used to execute a vertically distributed logistic regression analysis. Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a vertically distributed logistic regression model.

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
| Single iteration | `outcome_data.csv` <br> `Data_node_k.csv`\* <br> `Backup_Data_node_k.csv` | Yes <br> No <br> No |

\* After running the code, the file `Backup_Data_node_k.csv` will correspond to the original data, whereas the file `Data_node_k.csv` will contain only the predictors in the original data.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
