# Distributed Cox model 

## Repository structure

- The core article is in the root directory: "Lu et al. - 2015 - WebDISCO: A Web Service for Distributed Cox Model.pdf."  This describes the background of the work and presents the method used.

- Examples  
The examples folder contains a few examples. Each example folder is self-contained. Therefore, some files will be duplicated across examples, but this is to facilitate their exploration independantly.

- Generic_code  
The generic_code folder contains examplar `R` code files pertaining to the distributed approach and its pooled comparator. Please read the code and its comments in the `R` file as files may require edition before being used.

#### List of examples

- `random_data`, and `random_data_same_folder` are based on the same example (whereas `random_grouped_data`, `random_grouped_data_same_folder` and `random_grouped_data_with_weights_same_folder` are based on the same example where the data was aggregated).  
	- The first one has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.  
	- The second example is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across folders.

- `lung_data_same_folder` is an example based on the `lung` dataset in `R` (whereas `lung_data_grouped_same_folder` is based on the same example where the data was aggregated).

- `breast_data`, `breast_data_same_folder`, `breast_data_with_weights_same_folder` are based on the same example. They both use the "[Breast Cancer Dataset](https://www.kaggle.com/datasets/utkarshx27/breast-cancer-dataset-used-royston-and-altman)" from Royston and Altman (2013).  
	- The first one has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.  
	- The second example is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.  
	- The third example is based on the same dataset alongside weights files. Everything is happening in the same folder, without the need to copy files across.

- * Optional : if you want to try to generate new test datasets, the file `cox_data_generation.R` might be useful.*

#### Generic code

The files in this folder can be used to support an example of distributed survival analysis with a Cox model.  
Assuming a data structure similar to the data nodes `.csv` files in the example folder, this code can be used to execute a data node operation or a coordination node operation for a Cox model.

## Instructions to run the examples/algorithm

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

#### INSTALLING R and R STUDIO

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

#### INSTALLING THE REQUIRED PACKAGES

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [survival](https://cran.r-project.org/web/packages/survival/index.html)
- [MASS](https://cran.r-project.org/web/packages/MASS/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is".

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

#### INSTALLING AN EXAMPLE

1. Unpack one of the example folders on one of your drives.

#### EXECUTING THE DISTRIBUTED CODE

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory, manually set the variable `manualwd = 1` in `Data_node_call_cox-reg_k.R` and  `Coord_node_call_iter_cox-reg.R`.***

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number.

Initialization:

1. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local times and local beta estimates.  
The files `Beta_local_k.csv`, `N_node_k.csv`, `Times_k_output.csv`, `Vk_k.csv` and `Predictor_names_1.csv` will be generated. All files must be sent to the coordination node.

2. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global times and to initialise the values of beta.  
The files `Beta_0_output.csv` and `Global_times_output.csv` will be generated. These files must be shared with the local nodes.  
The file `Global_Predictor_names.csv` will also be generated if all nodes have the same data structure. It does not need to be shared with the local nodes.

For the first iteration (labelled iteration `t=0`):

3. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local parameters and local aggregates used for derivatives.  
The files `Rikk.csv`, `normDikk.csv`, `sumZrk.csv`, `sumExpx_output_t.csv`, `sumZqExpk_output_t.csv` and `sumZqZrExpk_output_t.csv` will be generated. All files but `Rikk.csv` must be sent to the coordination node.

4. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute global parameters, to compute first and second derivative and to update beta estimate.  
The files `normDikGlobal.csv` and `sumZrGlobal.csv` will be generated. They should be kept at the coordination node.  
The files `Beta_t_output.csv` and `Results_iter_t.csv` will be generated. To continue, the coordination node must share the file `Beta_t_output.csv` with the local nodes.

Then, to perform other iterations:

5. Run the local `R` file (`Data_node_call_cox-reg_k.R`) for each data node to compute local aggregates used for derivatives.  
The files `sumExpk_output_t.csv`, `sumZqExpk_output_t.csv` and `sumZqZrExpk_output_t.csv` will be generated. All files must be sent to the coordination node.

6. Run the coordination `R` file (`Coord_node_call_iter_cox-reg.R`) to compute first and second derivative and to update beta estimate.  
The file `Beta_t_output.csv` and `Results_iter_t.csv` will be generated. To continue, the coordination node must share `Beta_t_output.csv` with the local nodes.

7. (optional) Compare the results of the previous iteration with the current one to decide if another iteration is pertinent (return to step 5) or not.

#### EXECUTING THE POOLED SOLUTION CODE

***Make sure `R studio` is not currently running and close it if it is.***

1.	Navigate to the folder `pooled_solution`.
2.	Open the file `Solution.R`. It should then appear in `R`.
3.	Select all the code and click `run`.
4.	The results will be available in the console.

## Expected outputs

#### Data node side

| Initialization | files... | Shared? |
| ----------- | ----------- |
| Iteration 0 | `Beta_local_k.csv` <br> `N_node_k.csv` <br> `Predictor_names_k.csv` <br> `Times_k_output.csv` <br> `Vk_k.csv` | Yes <br> Yes <br> Yes <br> Yes <br> Yes |
| Iteration 1 | files... | Y/N |
| Iteration 2 | files... | Y/N |

#### Coordination node side

| Initialization | files... |
| ----------- | ----------- |
| Iteration 1 | files... |
| Iteration 2 | files... | 


### License: https://creativecommons.org/licenses/by-nc-sa/4.0/

### Copyright: GRIIS / Université de Sherbrooke
