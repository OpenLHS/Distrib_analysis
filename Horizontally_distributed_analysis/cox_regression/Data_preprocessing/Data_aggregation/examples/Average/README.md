## Instruction to run the example (Average)

There are many ways to run `R` code. The proposed instructions here are focusing on using a graphical interface.

### Installing R and R Studio

1. Go to the page : https://posit.co/download/rstudio-desktop/ and follow the instructions for your operating system

### Installing the required packages

The algorithm currently requires the use of package(s) not present in the base installation. `R` should prompt you to download the packages automatically.

- [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html)

Furthermore, the examples will be easier to explore and adapt/change if the package `this.path` is also available. Yet this is NOT required and you can safely ignore any warning about this is if you want to use the algorithm "as-is". Should you choose not to use this package, you will then need to manually set your working directory in your `R` instance.

- [this.path](https://cran.r-project.org/package=this.path)

If you work in an isolated environment, you might need to download them manually at the adress above and install them for your `RStudio` instance. While describing the process here is out of scope, a web search will yield resources like https://riptutorial.com/r/example/5556/install-package-from-local-source that can be helpful.

### Installing an example

1. Unpack one of the example folders on one of your drives.

### Executing the code 

***Make sure `R studio` is not currently running and close it if it is.***  
***If you are not able to automatically set your working directory, manually set the variable `manualwd = 1` in `data_node_call_precox_average.R`.***

1. Open the file `data_node_call_precox_average.R`.
2. You will need to change the value of `eventbucketsize` according to your specific situation.
3. Select all the code in the file `data_node_call_precox_average.R` and execute it. A new file will be generated, which contains the original data with modified times.

This data can now be used by a data node to participate into a privacy preserving Cox model.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
