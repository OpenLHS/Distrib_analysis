# Example list

This folder contains some data examples that can be used to better understand the distributed method's behavior, inputs, outputs and special cases. 

For any given example, it is possible to compare the distributed results with the pooled results.

## Table of contents

1. [Examples](#Examples)

2. [Example handler](#Example-handler)

3. [Instructions to run the examples (labelled same folder)](#Instructions-to-run-the-examples-labelled-same-folder)

    1. [Installing R and R Studio](#Installing-R-and-R-Studio)
	
    2. [Installing the required packages](#Installing-the-required-packages)
	
    3. [Installing an example](#Installing-an-example)
	
    4. [Executing the distributed code](#Executing-the-distributed-code)
	
    5. [Executing the pooled solution code](#Executing-the-pooled-solution-code)

4. [Instructions to run the examples (not labelled same folder)](#Instructions-to-run-the-examples-not-labelled-same-folder)

    1. [Installing R and R Studio](#Installing-R-and-R-Studio-1)
	
    2. [Installing the required packages](#Installing-the-required-packages-1)

    3. [Installing an example](#Installing-an-example-1)
	
    4. [Executing the distributed code](#Executing-the-distributed-code-1)
	
    5. [Executing the pooled solution code](#Executing-the-pooled-solution-code-1)

5. [License](#license)

6. [Copyright](#copyright-griis--université-de-sherbrooke)

## Examples

1. `random_data` and `random_data_same_folder` are based on the same example.
	1. The first one (`random_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where. 
	2. The second example (`random_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across folders.
2. `MatchIt_data` and `MatchIt_data_same_folder` are based on the same example. They both use the `Lalonde` data sets from the `R` package `MatchIt`. See [MatchIt](https://cran.r-project.org/web/packages/MatchIt/index.html).  
Usecase: Weights in our horizontally distributed linear and logistic regression examples (see the folder `MatchIt_data_with_weights` in each of those method).
	1. The first one (`MatchIt_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`MatchIt_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.
3. `breast_data` and `breast_data_same_folder` are based on the same example. They both use the "[Breast Cancer Dataset](https://www.kaggle.com/datasets/utkarshx27/breast-cancer-dataset-used-royston-and-altman)" from Royston and Altman (2013).  
Usecase: Weights in our horizontally distributed cox regression examples (see the folder `breast_data_with_weeights_same_folder` in that method).
	1. The first one (`breast_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`breast_data_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.

## Example handler

This folder contains slightly modified `R` files that allows anyone to quickly run the proposed method from within any of the example folder.

## Instructions to run the examples (labelled same folder)

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

1.	Navigate to the folder `distributed`.
2.	Open the file `Run_Example.R`. It should then appear in `R`.
3.	Select all the code and click `run`.
4.	All iterations results will be saved in `.csv` files.

### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `pooled_solution`. 
2. Open the file `Run_Pooled_Example.R`. It should then appear in `R`.
3.	Select all the code and click `run`.
4.	The results will be available in the console.

## Instructions to run the examples (not labelled same folder)

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

In the following procedure, `k` represents the number of the local node, and `t` represents the iteration number. Note that the iteration number `t` increments everytime the coordination node is reached.

Initialization: 

1. Run the `Run_example.R` file for each data node subfolder (`Data_node_k`).   
The files `Data_node_k_iter_0.csv` and `Predictor_names` will be generated. All files must be sent to the coordination node.

2. Run the `Run_example.R` file for the coordination node, located in its own folder (`Coord_node`).  
The file `Coord_node_iter_1_primer.csv`  will be generated. This file must be shared with the local nodes.  
The file `Global_Predictor_names.csv` will also be generated if all nodes have the same data structure and estimation parameters. It does not need to be shared with the local nodes.

For the first iteration, data node side:

3. Run the `Run_example.R` file for each data node subfolder (`Data_node_k`).  
The file `Data_node_k_iter_1.csv` will be generated. It must be sent to the coordination node.

For the first iteration, coordinating node side:

4. Run the `Run_example.R` file for the coordination node, located in its own folder (`Coord_node`).  
The files `Coord_node_iter_2_primer.csv`, `Coord_node_iter_1_covariance.csv` and `Coord_node_ter_1_results.csv` will be generated. To continue, the coordination node must share the file `Coord_node_iter_2_primer.csv` with the local nodes.

Then, to perform other iterations:

5. Run the `Run_example.R` file for each data node subfolder (`Data_node_k`).  
The file `Data_node_k_iter_(t).csv` will be generated. It must be sent to the coordination node.

6. Run the `Run_example.R` file for the coordination node, located in its own folder (`Coord_node`).  
The files `Coord_node_iter_(t+1)_primer.csv`, `Coord_node_iter_(t)_covariance.csv` and `Coord_node_iter_(t)_results.csv` will be generated. To continue, the coordination node must share the file `Coord_node_iter_(t+1)_primer.csv` with the local nodes.

7. (optional) Compare the results of the previous iteration with the current one to decide if another iteration is pertinent (return to step `5`) or not.


### Executing the pooled solution code

***Make sure `R studio` is not currently running and close it if it is.***  
***This should only be used with the provided examples (or an example of your own), as it requires to pool all your data sources together.***

1. Navigate to the folder `pooled_solution`. 
2. Open the file `Run_Pooled_Example.R`. It should then appear in `R`.
3.	Select all the code and click `run`.
4.	The results will be available in the console.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
