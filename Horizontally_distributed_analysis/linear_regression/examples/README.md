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

1. `random_data`, `random_data_same_folder`, `random_data_same_folder_missing` and `random_data_with_weights_same_folder` are based on the same example.
	1. The first one (`random_data`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. All the other ones are based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.
	3. The third example (`random_data_same_folder_missing`) is based on the same dataset but has some missing data in the first data node. This will allow one to know how the method behaves when it has to do a complete case analysis.
	4. The fourth example (`random_data_with_weights_same_folder`) is based on the same dataset and also uses weights. The weights used were chosen randomly.	

2. `MatchIt_data_with_weights` and `MatchIt_data_with_weights_same_folder` are based on the same example. They both use the `Lalonde` data sets from the `R` package `MatchIt`. See [MatchIt](hps://cran.r-project.org/web/packages/MatchIt/index.html).  
For both examples, the weights are the ones obtained from running the content of the `Weights_generation_for_IPW` with the MatchIt example.

	1. The first one (`MatchIt_data_with_weights`) has the files separated in different folders to better mimic a distributed environment. To run, you need to copy the results across folders, which clarifies what is sent where.
	2. The second example (`MatchIt_data_with_weights_same_folder`) is based on the same dataset, but if you simply want to look at the output, everything is happening in the same folder, without the need to copy files across.

3.  `newborn_data_same_folder` is yet another example.

## Example handler

This folder contains slightly modified `R` files that allows anyone to quickly run the proposed method from within any of the example folder.

## Instructions to run the examples (labelled same folder)

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [KS](https://cran.r-project.org/web/packages/ks/index.html)

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

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [KS](https://cran.r-project.org/web/packages/ks/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the distributed code

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory (for example, if you do not have access to `this.path`), manually set the variable `manualwd = 1` in `Data_node_call_lin-reg_k.R` and  `Coord_node_lin-reg.R`.***

In the following procedure, `k` represents the number of the local node.

1. Run the `Run_example.R` file for each data node subfolder (`Data_node_k`).
The files `Predictor_names_k.csv` and `Nodek_output.csv` will be generated. All files must be sent to the coordination node.

2. Run the `Run_example.R` file for the coordination node, located in its own folder (`Coord_node`).
The file `CoordNode_results_distributed_lin_reg.csv` will be generated. 

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
