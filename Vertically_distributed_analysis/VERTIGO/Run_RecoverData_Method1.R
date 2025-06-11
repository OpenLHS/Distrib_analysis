###############################################################################################################################################################

# PROJECT: VERTIGO and VERTIGO-CI implementation
# DOC:     Example illustrating that the CC can recover the original data after VERTIGO-CI has been ran.
# BY:      MPD, JPM
# DATE:    June 2025
# UPDATE:  --  

# License: https://creativecommons.org/licenses/by-nc-sa/4.0/
# Copyright: GRIIS / Université de Sherbrooke

###############################################################################################################################################################

rm(list=ls())

#==============================================================================================================================================================
# Try and recover the original data using all information saved at the CC (Method 1: Main text)
#==============================================================================================================================================================

#-------------------------------------------------------------------------------
# Load data available at CC
#-------------------------------------------------------------------------------
# Response vector
y <- read.csv("Outputs/Coord/y.csv")[,1]

# Parameter lambda 
lambda <- read.csv("Outputs/Coord/lambda.csv")[,1]

# Local matrices K^(k) and global Gram matrix
K1 <- read.csv("Outputs/Coord/K1.csv")
K2 <- read.csv("Outputs/Coord/K2.csv")
K3 <- read.csv("Outputs/Coord/K3.csv")
K_all <- as.matrix(read.csv("Outputs/Coord/K_all.csv"))

# Optimal parameter alpha_hat (checked)
alpha_hat <- as.matrix(read.csv("Outputs/Coord/alpha_hat.csv"))

# Blocks of XVX
Block_Client1 <- as.matrix(read.csv("Outputs/Coord/Block_Client1.csv"))
Block_Client2 <- as.matrix(read.csv("Outputs/Coord/Block_Client2.csv"))
Block_Client3 <- as.matrix(read.csv("Outputs/Coord/Block_Client3.csv"))

#-------------------------------------------------------------------------------
# Compute beta_0_hat + t(X) beta_hat using Equation 17
#-------------------------------------------------------------------------------
beta0_xbeta <- as.vector(1/lambda * t(alpha_hat) %*% diag(y) %*% K_all)

#-------------------------------------------------------------------------------
# Compute the matrix V using Equation 12
#-------------------------------------------------------------------------------
# Compute V^lambda
V <- diag( (exp(beta0_xbeta)/(1+exp(beta0_xbeta)))*(1-(exp(beta0_xbeta)/(1+exp(beta0_xbeta)))) )

# Compute (V^lambda)^(1/2)
sqrtV <- sqrt(V)

# Compute (V^lambda)^(-1/2)
invsqrtV <- solve(sqrtV)

#-------------------------------------------------------------------------------
# Recover original data from the blocks
#-------------------------------------------------------------------------------
recoveredX1 <- t(Block_Client1 %*% invsqrtV)
recoveredX2 <- t(Block_Client2 %*% invsqrtV)
recoveredX3 <- t(Block_Client3 %*% invsqrtV)

#-------------------------------------------------------------------------------
# Compare recovered data with true data
#-------------------------------------------------------------------------------
# Load true data
X1_scaled <- as.matrix(read.csv("Outputs/Node1/X1_scaled.csv"))
X2_scaled <- as.matrix(read.csv("Outputs/Node2/X2_scaled.csv"))
X3_scaled <- as.matrix(read.csv("Outputs/Node3/X3_scaled.csv"))

# Compare all data
all.equal(recoveredX1, X1_scaled, check.attributes = FALSE)
all.equal(recoveredX2, X2_scaled, check.attributes = FALSE)
all.equal(recoveredX3, X3_scaled, check.attributes = FALSE)

#==============================================================================================================================================================
# End of "Recovering the original data at the CC (Method 1: Main text)"
#==============================================================================================================================================================