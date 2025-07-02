############### Distributed inference ####################
############### Response-node code - Privacy check ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


# Libraries and rcpp functions needed for the procedure -----------------------

library(ROI)
library(ROI.plugin.glpk)
library(ROI.plugin.symphony)

# Privacy check for response data -----------------------
 
# Main privacy check function
  
privacy_check_ck2 <- function(V,alpha_tilde,y,n,i0){
  # Compute which entries of y are flippable
  # V: Matrix in null-space of gram matrix of node k
  # alpha_tilde: optimal alpha from the dual optimization procedure
  # y: vector of responses
  
  gc()
  
  # Step: Try to flip each coordinate's sign 
  feasible_flip<- logical(n)
  
  # initial solution to the system c_k = 1/(lambda n) K_k (\diag alpha) y
  x0 <- (alpha_tilde * y)
  i <- i0
 
  if (abs(x0[i]) < 1e-8 | feasible_flip[i] == TRUE ) {
    feasible_flip[i] <- TRUE  # zero: already sign-flippable
    next
  }

  direction <- if (x0[i] > 0) "<=" else ">="
  
  # Inequality: sign flip
  A_flip <- matrix(V[i, ], nrow = 1)
  dir_flip <- direction
  rhs_flip <- if (x0[i] > 0) -x0[i] - 1e-2  else -x0[i] + 1e-2 # small margin to strictly cross zero
  
  # Box constraints: x0 + V b in (-1,1)^n
  A_box <- rbind(V, -V)
  dir_box <- rep("<=", 2 * n)
  rhs_box <- c(1 - x0-1e-3, 1-1e-3 + x0)
  
  # Combine constraints
  A_total <- rbind(A_box, A_flip)
  rm(A_box)
  dir_total <- c(dir_box, dir_flip)
  rhs_total <- c(rhs_box, rhs_flip)
  rm(dir_box, dir_flip,rhs_box, rhs_flip)
  L <- OP(objective = rep(0,ncol(V)), 
          constraints = L_constraint(L = A_total, dir = dir_total, rhs = rhs_total))
  gc()

    res2 <- ROI_solve(L, solver = "symphony")

  if(res2$status$code == 0){
    sol <- x0 + V%*% solution(res2)
    return(sol)
  }else{return(NULL)}
}


privacy_check_ck2_complete <- function(V,alpha_tilde,y,n,k){

  #Determine the number of columns of the null matrix used (this number could be modified according to memory access)
  if(ncol(V)>1200){
    V_used <- V[,1:1200]
  }else{V_used <- V}
  
  #Initialize index and count number of flips
  count <- 0
  nbsol <- 0
  index_nosol <- numeric(0)
  index <- 1:n
  i0 <- index[which.max(alpha_tilde[index])]
  
  # Create progress bar so user know the method isn't stuck
  progressbar <- txtProgressBar(min=0, max = n, style = 3)
  
  #Run over all line-level values in Y
  while(length(index)!=0){
    d_sol <- privacy_check_ck2(V_used,alpha_tilde,y,n,i0)
    if (!is.null(d_sol)) {
      count <- count+sum(sign(y[index])!=sign(d_sol[index]))
      index <- index [!index %in% c(i0)]
      index <- index[which((sign(y[index])==sign(d_sol[index])))]
      nbsol <- nbsol + 1
    }else{
      index_nosol <- c(index_nosol,i0)
      index <- index [!index %in% c(i0)]
    }
    if(length(index)!=0){
    i0 <- index[which.max(alpha_tilde[index])]  
    }
    # Update progress bar
    setTxtProgressBar(progressbar, n-length(index)) 
  }
  # close progress bar
  close(progressbar) 
  
  #Print results of flips vs no flips
  cat(sprintf(paste0("Flippable coordinate signs with covariate-node ", k,"'s data: %d / %d\n"), count, n))
  cat(sprintf("Number of distinct candidates: %d\n", nbsol))
  
  if(count!=n){
    write.csv(data.frame(index_noflip=index_nosol),
              file=paste0(examplefilepath, "Index_NoFlip_",k ,".csv"), row.names=FALSE)
  }
  rm(V_used)
  return(NULL)
}

