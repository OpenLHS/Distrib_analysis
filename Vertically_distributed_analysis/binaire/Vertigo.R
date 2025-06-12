library(aplore3)
library(glmnet)

# load data
x_1 <- read.csv("Data_node_1.csv")
x_2 <- read.csv("Data_node_2.csv")
y <- read.csv("outcome_data.csv")[,1]

# scale data
#x_1 <- scale(x_1)
#x_2 <- scale(x_2)

# no not scale data
x_1 <- as.matrix(x_1)
x_2 <- as.matrix(x_2)

# ajouter la colonne constante au dernier noeud
x_2 <- cbind(x_2, rep(1, nrow(x_2)))

#Déterminer la valeur du paramètre de régularisation 
#(pour être cohérent avec l'article, lambda=0.0001 sera utilisé pour comparer avec une
#régression sans pénalisation)
lambda <- 0.0001

################################VERSION OPTIMISÉE DE VERTIGO###############################

################# OPÉRATIONS AUX SITES : LOCAL GRAM MATRIX K_k envoyée au noeud central
K_1 <- x_1%*%t(x_1)
K_2 <- x_2%*%t(x_2)


################# OPÉRATIONS AU NOEUD CENTRAL

#########1. GLOBAL GRAM MATRIX K_all
K_all <- K_1+K_2

write.csv(K_1, file = "K_1.csv", row.names = FALSE)
write.csv(K_2, file = "K_2.csv", row.names = FALSE)
write.csv(K_all, file = "K_all.csv", row.names = FALSE)

#########2. ITÉRATIONS AVEC GRADIENT ET HESSIENNE 

#Quantité en mémoire qui sera réutilisée dans le gradient et la hessienne 
#(pour éviter de recalculer à chaque fois)
short <- (1/lambda)*(diag(y))%*%K_all%*%(diag(y))

###Initialisation du paramètre alpha entre 0 et 1 [exclus] (à n composantes)

alpha_u <- rep(0.5,1000)

#Itérations NEWTON-RAPHSON POUR ALPHA_U - REPROJETÉ DANS LA CONTRAINTE AU BESOIN

nbiter <- 100

for (i in 1:nbiter) {
  alpha_u <- as.vector(alpha_u - (solve(short+diag(1/(alpha_u*(1-alpha_u))),(short%*%alpha_u+(log(alpha_u/(1-alpha_u)))))))
  
  alpha_u[which(alpha_u<0)] <- 0.000000001
  alpha_u[which(alpha_u>1)] <- 0.999999999
  #alpha_u <- 1/(1+exp(-alpha_u))
}
alpha_u
################# OPÉRATIONS AUX SITES : CALCULER LES PARAMÈTRE BETA PRIMAUX

beta_1_u <- (1/lambda)*t(x_1)%*%diag(alpha_u)%*%y
beta_2_u <- (1/lambda)*t(x_2)%*%diag(alpha_u)%*%y

beta <- c(beta_1_u, beta_2_u)

noms <- c(rownames(beta_1_u), rownames(beta_2_u))
noms[length(noms)] <- "intercept"
noms

output <- cbind(noms, beta)

# save outputs
write.csv(output, file = "beta_hat.csv", row.names = FALSE)
write.csv(beta_1_u, file = "beta_1_hat.csv", row.names = FALSE)
write.csv(beta_2_u, file = "beta_2_hat.csv", row.names = FALSE)
write.csv(alpha_u, file = "alpha_hat.csv", row.names = FALSE)
write.csv(lambda, file = "lambda.csv", row.names = FALSE)

#X <- cbind(x_1, x_2)
#data_complete = as.data.frame(cbind(y, X)) %>% 
#  mutate(y = (y+1)/2)
#
#glm(y~., data_complete, family = "binomial")
