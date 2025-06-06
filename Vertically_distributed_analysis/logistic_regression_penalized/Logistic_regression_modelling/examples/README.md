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

4. [License](#license)

5. [Copyright](#copyright-griis--université-de-sherbrooke)

## Examples

1. `random_data_same_folder` contains two datasets corresponding to different nodes in a vertically distributed analysis and a single column dataset corresponding to the outcome variable. They can be copied and used to run examples of the method and compare with the pooled results. 

## Example handler

This folder contains slightly modified `R` files that allows anyone to quickly run the proposed method from within any of the example folder.

## Instructions to run the examples (labelled same folder)

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

Data nodes:
- There are no package not present in the base installation that are a requirement for this code to run.

Coord node:
- [CVXR](https://cran.r-project.org/web/packages/CVXR/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the address above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

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

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
