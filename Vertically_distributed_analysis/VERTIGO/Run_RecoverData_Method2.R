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
# Try and recover the original data using all information saved at the CC (Method 2: Supplementary material)
#==============================================================================================================================================================

#-------------------------------------------------------------------------------
# Load data available at CC
#-------------------------------------------------------------------------------
# Optimal parameter alpha_hat (checked)
alpha_hat <- as.matrix(read.csv("Outputs/Coord/alpha_hat.csv")) 

# Blocks of XVX
Block_Client1 <- as.matrix(read.csv("Outputs/Coord/Block_Client1.csv")) 
Block_Client2 <- as.matrix(read.csv("Outputs/Coord/Block_Client2.csv"))
Block_Client3 <- as.matrix(read.csv("Outputs/Coord/Block_Client3.csv"))

#-------------------------------------------------------------------------------
# Compute the matrix V using Supplemtary material D
#-------------------------------------------------------------------------------
# Compute V^lambda
V <- diag( as.vector(alpha_hat*(1-alpha_hat)) )

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
# End of "Recovering the original data at the CC (Method 2: Supplementary metarial)"
#==============================================================================================================================================================