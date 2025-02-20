## 
# Cox analysis:
# Assumes dataset "data" was use to create a cox model "res.cox".
##

# Schoenfeld residuals

#res.cox

beta <- coef(res.cox)
OrderedData <- data
x_ordered<-as.matrix(OrderedData[ ,3:5])
n<-nrow(OrderedData)
Numerator1<-numeric(n);Numerator2<-  numeric(n);Numerator3<-  numeric(n);Denominator<-numeric(n)
Num1<-  numeric(n);Num2<-  numeric(n);Num3<-  numeric(n);Den<-numeric(n)
for(j in 1:n) { 
  Numerator1[j] <- x_ordered[j,1]*exp( x_ordered[j,]%*%beta)        * weights_pooled[j] # (!) Probablement qu'il suffit de regarder tout les endroits où weights_pooled est présent et ajuster
  Numerator2[j] <- x_ordered[j,2]*exp( x_ordered[j,]%*%beta)        * weights_pooled[j] # justifiable avec l'
  Numerator3[j] <- x_ordered[j,3]*exp( x_ordered[j,]%*%beta)        * weights_pooled[j]
  Denominator[j]<-exp( x_ordered[j,] %*%beta)                       * weights_pooled[j] # justifiable avec l'
}

for(j in 1:n) {
  thistime<-OrderedData$time[j]
  riskset <- which(thistime<=OrderedData$time)
  Num1[j] <- sum(Numerator1[riskset])
  Num2[j]<- sum(Numerator2[riskset])
  Num3[j]<- sum(Numerator3[riskset])
  Den[j] <- sum(Denominator[riskset]) 
}

Schoenfeld<-as.matrix(cbind( weights_pooled* # justifiable avec l' (et Collett chapite 4)
                               (x_ordered[,1]-Num1/Den), 
                             weights_pooled*
                               (x_ordered[,2]-Num2/Den) , 
                             weights_pooled*
                               (x_ordered[,3]-Num3/Den))  )
rP <- Schoenfeld
rP[OrderedData$status==0,] <-  0 # Valider pour notre exemple à nous. Attention, il faut skipper les lignes de 0 pour comparer avec R

# Test pour l'égalité entre les "vrais" scho res et ce qui est calculé par l'algo distribué.
# En gros, on est semblable à 10^-9 près. (ce qui semble raisonnable?)

rdm_index1 <- runif(1, min = 1, max = nrow(rP)-10)

rP[rdm_index1:(rdm_index1+10),]
scho_dist[rdm_index1:(rdm_index1+10),]
rP[rdm_index1:(rdm_index1+10),]==scho_dist[rdm_index1:(rdm_index1+10),]
rP[rdm_index1:(rdm_index1+10),]-scho_dist[rdm_index1:(rdm_index1+10),]

##### SCORE residuals #####

a_hat <- cbind(Num1/Den,Num2/Den,Num3/Den)

#head(a_hat)
#head(xbarri)

x <- x_ordered
delta <- OrderedData$status
sum_risk <- Den
exp_xb <- exp(as.matrix(x_ordered)%*%beta)

Somme <- matrix(0, nrow = n, ncol = 3)
Somme2 <- matrix(0, nrow = n, ncol = 3)
Somme3 <- matrix(0, nrow = n, ncol = 3)
Somme4 <- matrix(0, nrow = n, ncol = 1)

W_Inv <- matrix(0, nrow = nrow(data), ncol = length(beta))

rS <- matrix(0, nrow = nrow(data), ncol = length(beta))
rS2 <- matrix(0, nrow = nrow(data), ncol = length(beta))

Deuxieme_terme <- matrix(0, nrow = nrow(data), ncol = length(beta))
Troisieme_terme <- matrix(0, nrow = nrow(data), ncol = length(beta))


t1 <- matrix(0, nrow = nrow(data), ncol = length(beta))
t2 <- matrix(0, nrow = nrow(data), ncol = length(beta))

for(i in 1:n){
  
  thistime <- OrderedData$time[i]
  Indices <- which(thistime>=OrderedData$time & OrderedData$status==1)
  
  Partial = matrix(0, nrow=nrow(data), ncol = 3)
  second = matrix(0, nrow=nrow(data), ncol = 3)
  third = matrix(0, nrow=nrow(data), ncol = 3)
  third_sans_x = matrix(0, nrow=nrow(data), ncol = 1)
  W_Inv = matrix(0, nrow=nrow(data), ncol = 1)
  for(r in Indices){
    
    Partial[r,] <-  weights_pooled[r]*(a_hat[r,] - x[i,])*delta[r] / sum_risk[r] # ok par symétrie avec le terme delta
    second[r,] <- weights_pooled[r]*(a_hat[r,])*delta[r] / sum_risk[r]
    third[r,] <- weights_pooled[r]*(x[i,])*delta[r] / sum_risk[r]
    W_Inv[r,] <- weights_pooled[r]*delta[r] / sum_risk[r]
    third_sans_x[r,] <- weights_pooled[r]*(1)*delta[r] / sum_risk[r]
    
  }
  
  Somme[i,] <- colSums(Partial)
  Somme2[i,] <- colSums(second)
  Somme3[i,] <- colSums(third)
  Somme4[i,] <- colSums(third_sans_x)
  
  rS[i,] <- rP[i,] +  weights_pooled[i] *exp_xb[i]*Somme[i,] # ok aussi en lien avec l'...
  rS2[i,] <- rP[i,] + weights_pooled[i] *exp_xb[i]*Somme2[i,] - weights_pooled[i] *exp_xb[i]*Somme3[i,]
  
  Deuxieme_terme[i,] <- weights_pooled[i] *exp_xb[i]*Somme2[i,]
  Troisieme_terme[i,] <- weights_pooled[i] *exp_xb[i]*Somme3[i,]
}

# Pour valider que les deux méthodes ci-dessus donnent les memes valeurs
head(rS)
head(rS2)

deux_dist <- as.matrix(read.csv(paste0("xbarri_inverseWExp_Global_output_", index, ".csv")))
trois_dist <- as.matrix(read.csv(paste0("inverseWExp_Global_output_", index, ".csv")))
xbarri_dist <- read.csv(paste0("xbarri_", index, ".csv"))



# Comparaison de xbar ri avec les ri ici (fonctionne sans poids)
head(unique(a_hat[order(a_hat[,1]),]))
head(xbarri_dist[order(xbarri_dist[,1]),])

tail(unique(a_hat[order(a_hat[,1]),]))
tail(xbarri_dist[order(xbarri_dist[,1]),])

# comparaison terme 2 complet (fonctionne sans poids)
s1 <- read.csv(paste0("second_term1_output_", index, ".csv"))
s2 <- read.csv(paste0("second_term2_output_", index, ".csv"))
s3 <- read.csv(paste0("second_term3_output_", index, ".csv"))
second_term_dist <- rbind(s1,s2,s3)

head(second_term_dist[order(second_term_dist[,1]),])
head(Deuxieme_terme[order(Deuxieme_terme[,1]),])

# comparaison terme 2 

head(deux_dist[order(deux_dist[,1]),])
head(unique(Somme2)[order(deux_dist[,1]),])

# comparaison terme 3 complet (fonctionne sans poids)
t1 <- read.csv(paste0("third_term1_output_", index, ".csv"))
t2 <- read.csv(paste0("third_term2_output_", index, ".csv"))
t3 <- read.csv(paste0("third_term3_output_", index, ".csv"))
third_term_dist <- rbind(t1,t2,t3)

head(third_term_dist[order(third_term_dist[,1]),])
head(Troisieme_terme[order(Troisieme_terme[,1]),])


# comparaison terme 3 (fonctionne sans poids, et ce pour les 2 cas)

  # sans x/z
head(trois_dist[order(trois_dist)])
head(unique(Somme4[order(Somme4)]))

  # avec x/z 
validation <- OrderedData[,3:5]*Somme4[,1]

head(unique(validation[order(validation[,1]),]))
head(unique(Somme3[order(Somme3[,1]),]))

# comparaison score resid (fonctionne sans poids)

head(rS2[order(rS2[,1]),])
head(score[order(score[,1]),])
head(score_dist[order(score_dist[,1]),]) # On voit que l'algo dist a des resultats un peu differents... Ceci réside dans le gros terme.

