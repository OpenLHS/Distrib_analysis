# Vertically distributed ridge-penalized binary regression (RidgeBin-V)

This implementation of the Vertical Ridge-Penalized Binary Regression leads to valid estimates for the logistic regression model, the probit model and the cloglog model.
Provided a binomial family (family_glm) taking the value "logit", "probit" or "cloglog" and a lambda sequence (lambda_seq), the results can be interpreted as they would with the following `R` calls in a pooled setting: 

- `lambda_central <- cv.glmnet(scale(X), y, family=binomial(link = family_glm), alpha = 0, lambda=lambda_seq,standardize=FALSE,thresh = 1e-25,maxit = 1e6)$lambda.min`

- `coef(glmnet(scale(X), y, family=binomial(link = family_glm),alpha=0,lambda=lambda_central, standardize=FALSE, thresh = 1e-25,maxit = 1e6))[,1]`

## Table of contents

0. [Before using](#before-using)

1. [Repository structure](#repository-structure)

2. [License](#license)

3. [Copyright](#copyright-griis--université-de-sherbrooke)


## Before using

- To start over, it is important to delete all "output" files.
- The code currently works only with complete data.

## Repository structure
- ridge_logistic_model
This folder contains `R` code files to run the vertical method for the logistic regression model, with examples. Some files use `R` code files common to all models, available in generic_code and example_handler.

- ridge_probit_model
This folder contains `R` code files to run the vertical method for the probit regression model, with examples. Some files use `R` code files common to all models, available in generic_code and example_handler.

- ridge_cloglog_model
This folder contains `R` code files to run the vertical method for the cloglog regression model, with examples. Some files use `R` code files common to all models, available in generic_code and example_handler.

- example_handler
This folder contains `R` code files common to all ridge-penalized binary regressions used to run examples. Please refer to the folders specific to every model and associated documentation to run the complete procedure on examples.

- generic_code  
The generic_code folder contains `R` code files common to all ridge-penalized binary regressions used for the vertical method. Please refer to the folders specific to every model and associated documentation to run the complete procedure.

## License

https://creativecommons.org/licenses/by-nc-sa/4.0/

## Copyright: GRIIS / Université de Sherbrooke
