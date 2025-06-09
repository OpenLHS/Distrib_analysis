###############################################################################################################################################################

# PROJECT: VERTIGO and VERTIGO-CI implementation
# DOC:     Example illustrating the quantities known at the CC and at the local data nodes
# BY:      MPD, JPM
# DATE:    June 2025
# UPDATE:  --  

###############################################################################################################################################################

#==============================================================================================================================================================
# Beginning of "Algorithm 3: VERTIGO Original"
#==============================================================================================================================================================

# Fix convergence parameter
epsilon <- 1e-6

#-------------------------------------------------------------------------------
# Inputs
#-------------------------------------------------------------------------------

# Load each node x^(k), k=1,..., K
node_data1 <- read.csv("Data_node_1.csv")
node_data2 <- read.csv("Data_node_2.csv")

# Note: Predictor values should be scaled since we are doing a ridge regression
X1_scaled <- scale(node_data1)
X2_scaled <- scale(node_data2)

# Note: It is expected that the last data node will hold a column of 1s in order to estimate the intercept
X2_scaled <- cbind(X2_scaled, rep(1, nrow(X2_scaled))) # (!) valider si l'on veut la colonne de 1 ici ou non.

# Load shared response y
# Note: It is expected that y_i \in {-1, 1}, not y_i \in {0, 1}.
y <- read.csv("outcome_data.csv")[,1]
table(y)

# Fix parameter lambda
lambda <- 0.0001

# Fix initial solution alpha_s, s=0
alpha_s <- matrix(data = 0.5, nrow = length(y), ncol = 1)

#-------------------------------------------------------------------------------
# 1. Nodes: Compute the local matrix K^(k)
#-------------------------------------------------------------------------------

K1 <- X1_scaled %*% t(X1_scaled)
K2 <- X2_scaled %*% t(X2_scaled)

#-------------------------------------------------------------------------------
# 2. CC: Compute the global matrix K
#-------------------------------------------------------------------------------

K_all <- K1 + K2

#-------------------------------------------------------------------------------
# 3. Do:
#-------------------------------------------------------------------------------

# Initialize convergence boolean
converged = FALSE
nb_iter <- 0

while(!converged){
  
  #-----------------------------------------------------------------------------
  # a. Nodes: Compute e^(k)(alpha_s).
  #-----------------------------------------------------------------------------

  e_1 <- 1/lambda *  diag(y) %*% X1_scaled %*% t(X1_scaled) %*% diag(y) %*% alpha_s
  e_2 <- 1/lambda *  diag(y) %*% X2_scaled %*% t(X2_scaled) %*% diag(y) %*% alpha_s
  
  #-----------------------------------------------------------------------------
  # b. CC: Calculate e_s = sum e^(k)(alpha_s) and the gradient of J^lambda(alpha_s)
  #-----------------------------------------------------------------------------
  
  # Compute the sum of e^(k)(alpha_s)
  e_s <- e_1 + e_2
  
  # Compute the gradient of J^lambda(alpha_s)
  gradient_J <- e_s + log( alpha_s/(1-alpha_s) )
  
  #-----------------------------------------------------------------------------
  # c. CC: Compute the hessian matrix H(alpha_s) # (!) Possibility to add + C*I_n to hesssian 
  #-----------------------------------------------------------------------------
  
  Hessian <- 1/lambda * diag(y) %*% K_all %*% diag(y) + diag( 1/(alpha_s[,1]*(1-alpha_s[,1])) )
  
  #-----------------------------------------------------------------------------
  # d. CC: Update alpha_s
  #-----------------------------------------------------------------------------
  
  # Update parameters alpha through NR step
  alpha_new <- alpha_s - solve(Hessian, gradient_J)
  
  # Note: As alpha_i \in (0, 1), we need to make sure that no values are out of bounds
  alpha_new[which(alpha_new<0)] <- 0.000000001
  alpha_new[which(alpha_new>1)] <- 0.999999999
  
  # Compare new alpha to current one. Did we converge?
  if(norm(alpha_new - alpha_s, type = "2")<epsilon){
    converged = TRUE
  }
  
  # Update alpha and counter
  alpha_s <- alpha_new
  nb_iter <- nb_iter + 1
}

#-------------------------------------------------------------------------------
# 4. CC: Save optimal values alpha_hat
#-------------------------------------------------------------------------------

alpha_hat <- alpha_s

#==============================================================================================================================================================
# End of "Algorithm 3: VERTIGO Original"
# We follow with the rest of "Algorithm 4: VERTIGO-CI Original"
#==============================================================================================================================================================

#-------------------------------------------------------------------------------
# 5. CC: Send alpha_hat to nodes
#-------------------------------------------------------------------------------

# Nothing

#-------------------------------------------------------------------------------
# 6. Nodes (all but last): Calculate beta_hat^(k)
#-------------------------------------------------------------------------------
beta_node_1 <- 1/lambda * t(alpha_hat) %*% diag(y) %*% X1_scaled 

#-------------------------------------------------------------------------------
# 7. Last node: Calculate beta_0_hat and beta_hat^(K)
#-------------------------------------------------------------------------------
beta_node_2 <- 1/lambda * t(alpha_hat) %*% diag(y) %*% X2_scaled 
beta_0 <- 1/lambda * sum(alpha_hat*y)


#-------------------------------------------------------------------------------
# 8. Client-to-client communication
#-------------------------------------------------------------------------------

  #-----------------------------------------------------------------------------
  # a. Nodes (all but last): Compute exp{t(X^(k))\beta_hat^(k)}, send to node 1
  #-----------------------------------------------------------------------------
  exp_client1 <- exp(X1_scaled%*%t(beta_node_1))

  #-----------------------------------------------------------------------------
  # b. Last node: Compute exp{beta_0_hat}exp{t(X^(K))\beta_hat^(K)} (!) Erreur dans l'article? On semble multiplier les exponentielles. Sinon, grand K? (!)
  #-----------------------------------------------------------------------------
  exp_client2 <- exp(beta_0)*exp(X2_scaled%*%t(beta_node_2))

  #-----------------------------------------------------------------------------
  # c. Node 1: Combine the results to compute V^lambda, send to all nodes
  #-----------------------------------------------------------------------------
  exp_all <- exp_client1 * exp_client2

  V = (exp_all/(1+exp_all)) * (1-(exp_all/(1+exp_all)))
  V = diag(V[,1])
  sqrtV <- sqrt(V)
  
#-------------------------------------------------------------------------------
# 9. Nodes (all but last): Calculate t(X^(k)) (V^lambda)^(1/2), send to CC.
#-------------------------------------------------------------------------------
Block_Client1 <- t(X1_scaled) %*% sqrtV
  
#-------------------------------------------------------------------------------
# 10. Last node: Calculate t[X^(K), 1_n] (V^lambda)^(1/2), send to CC.
#-------------------------------------------------------------------------------
Block_Client2 <- t(X2_scaled) %*% sqrtV

#-------------------------------------------------------------------------------
# 11. CC: build t[X, 1_n] V^lambda [X, 1n] by bloc and invert to obtain variance estimates
#-------------------------------------------------------------------------------

Block_1_1 <- Block_Client1 %*% t(Block_Client1)
Block_1_2 <- Block_Client1 %*% t(Block_Client2)

Row_1 <- cbind(Block_1_1, Block_1_2)

Block_2_1 <- Block_Client2 %*% t(Block_Client1)
Block_2_2 <- Block_Client2 %*% t(Block_Client2)

Row_2 <- cbind(Block_2_1, Block_2_2)

XVX <- rbind(Row_1, Row_2)

invXVX <- solve(XVX)

std.error <- sqrt(diag(invXVX))

### OUTPUT
beta <- c(beta_node_1, beta_node_2[-length(beta_node_2)], beta_0)
output <- cbind(beta, std.error)
rownames(output) <- c(colnames(node_data1), colnames(node_data2), "intercept")

### Comparator GLM
X <- cbind(X1_scaled, X2_scaled)
X <- X[,-ncol(X)]
summary(glm((y+1)/2 ~ X, family="binomial"))

### Comparator GLMNET
library(glmnet)
X <- cbind(X,rep(1,nrow(X))+rnorm(nrow(X), sd = 1e-7))
fit <- glmnet(
  X,
  (y+1)/2,
  family = "binomial",
  alpha = 0,
  lambda = lambda,
  intercept = FALSE,               # Don't add unpenalized intercept
  standardize = FALSE,             # Avoid standardization that could affect Intercept column
  penalty.factor = rep(1, ncol(X)) # Penalize all coefficients, including intercept
)
fit$beta

output
