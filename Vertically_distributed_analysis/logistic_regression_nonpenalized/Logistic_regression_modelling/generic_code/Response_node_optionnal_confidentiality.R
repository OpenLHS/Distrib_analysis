############### Distributed inference ####################
############### Response-node code - Privacy check ###########

## License: https://creativecommons.org/licenses/by-nc-sa/4.0/
## Copyright: GRIIS / Université de Sherbrooke


# Libraries and rcpp functions needed for the procedure -----------------------

### LIBRARY

  library(Matrix)
  library(glmnet)
  library(Rcpp)
  library(RcppArmadillo)
  library(Rmpfr)
  library(pracma)
  library(RcppEigen)
  library(lpSolve)   # for linear programming
  library(ROI)
  library(ROI.plugin.glpk)
  
# Functions RCPP Armadillo

  ### Construct symmetric matrix from upper triangle
cppFunction('
  arma::mat reconstruct_from_upper_tri(const arma::vec& upper_tri, arma::uword n) {
    arma::mat A(n, n, arma::fill::zeros);
    arma::uword idx = 0;

    for (arma::uword j = 0; j < n; ++j) {
      for (arma::uword i = 0; i <= j; ++i) {
        A(i, j) = upper_tri(idx);      // fill the upper triangular part
        A(j, i) = upper_tri(idx++);    // fill the symmetric lower part
      }
    }

    return A;
  }
', depends = "RcppArmadillo")

  ### Define the nullspace of a sumetric positive definite matrix function using Eigen
  cppFunction(depends = "RcppEigen", code = '
  Eigen::MatrixXd nullspace_sym_pd(Eigen::MatrixXd A, double tol = 1e-10) {
    Eigen::SelfAdjointEigenSolver<Eigen::MatrixXd> es(A);
    Eigen::VectorXd evals = es.eigenvalues();
    Eigen::MatrixXd evecs = es.eigenvectors();

    std::vector<int> null_indices;
    for (int i = 0; i < evals.size(); ++i) {
      if (evals[i] < tol) {
        null_indices.push_back(i);
      }
    }

    Eigen::MatrixXd nullspace(A.rows(), null_indices.size());
    for (int i = 0; i < null_indices.size(); ++i) {
      nullspace.col(i) = evecs.col(null_indices[i]);
    }

    return nullspace;
  }
')
  ## Null space of a general matrix 
  cppFunction(depends = "RcppEigen", code = '
  Eigen::MatrixXd nullspace_general(const Eigen::MatrixXd& A, double tol = 1e-10) {
    // Perform full SVD: A = U * S * V^T
    Eigen::JacobiSVD<Eigen::MatrixXd> svd(
      A, Eigen::ComputeFullU | Eigen::ComputeFullV
    );

    // Get singular values and right singular vectors
    Eigen::VectorXd sing_vals = svd.singularValues();
    Eigen::MatrixXd V = svd.matrixV();

    int m = A.rows();
    int n = A.cols();
    int r = 0; // numerical rank

    for (int i = 0; i < sing_vals.size(); ++i) {
      if (sing_vals[i] > tol) {
        r++;
      }
    }

    // Nullity = number of columns - rank
    int nullity = n - r;

    if (nullity <= 0) {
      return Eigen::MatrixXd(n, 0); // full column rank
    }

    // Null space is the last (n - r) columns of V
    Eigen::MatrixXd nullspace = V.rightCols(nullity);
    return nullspace;
  }
')


# Privacy check for response data -----------------------
 
# Main privacy check function
  
  privacy_check_ck2 <- function(K_k,alpha_tilde,y,lambda,n){
    # Compute which entries of y are flippable
    # K_k: gram matrix of node k
    # alpha_tilde: optimal alpha from the dual optimization procedure
    # y: vector of responses
    # lambda: penalty parameter of the dual optimization problem
    
    # Step: Try to flip each coordinate's sign 
    feasible_flip<- logical(n)
    
    V <- nullspace_sym_pd(K_k,tol=1e-8)
    
    # initial solution to the system c_k = 1/(lambda n) K_k (\diag alpha) y
    x0 <- (alpha_tilde * y)
    
    number_of_sols_found <- 0
    
    for (i in 1:n) {
      if (abs(x0[i]) < 1e-8 | feasible_flip[i] == TRUE ) {
        feasible_flip[i] <- TRUE  # zero: already sign-flippable
        next
      }
      
      # Sign flip constraint: (x0[i] + (V b)[i]) * x0[i] < 0
      # -> V[i, ] %*% b < -x0[i]  if x0[i] > 0
      # -> V[i, ] %*% b > -x0[i]  if x0[i] < 0
      
      direction <- if (x0[i] > 0) "<=" else ">="
      
      # Inequality: sign flip
      A_flip <- matrix(V[i, ], nrow = 1)
      dir_flip <- direction
      rhs_flip <- if (x0[i] > 0) -x0[i] - 1e-3  else -x0[i] + 1e-3 # small margin to strictly cross zero
      
      # Box constraints: x0 + V b in (-1,1)^n
      A_box <- rbind(V, -V)
      dir_box <- rep("<=", 2 * n)
      rhs_box <- c(1 - x0-1e-3, 1-1e-3 + x0)
      
      # Combine constraints
      A_total <- rbind(A_box, A_flip)
      dir_total <- c(dir_box, dir_flip)
      rhs_total <- c(rhs_box, rhs_flip)
      
      L <- OP(objective = rep(0,ncol(V)), 
              constraints = L_constraint(L = A_total, dir = dir_total, rhs = rhs_total))
      res2 <- ROI_solve(L, solver = "glpk")
      if(res2$status$code == 0){
        sol <- x0 + V%*% solution(res2)
        signed_flipped <- sol * x0 < 0
        feasible_flip[which(signed_flipped)] <- TRUE
        number_of_sols_found = number_of_sols_found+1
      }
      else{
        ## Try the other solver
        res <- lp("min", rep(0,ncol(V)),
                  const.mat = A_total,
                  const.dir = dir_total,
                  const.rhs = rhs_total,
                  compute.sens = FALSE)
        if((res$status == 0)){
          sol <- x0 + V%*% res$solution
          signed_flipped <- sol * x0 < 0
          feasible_flip[which(signed_flipped)] <- TRUE
          number_of_sols_found = number_of_sols_found+1
        }
      }

    }
    cat(sprintf("Flippable coordinate signs: %d / %d\n", sum(feasible_flip), n))
    cat(sprintf("Number of distinct candidates: %d\n", number_of_sols_found))
    return(list(feasible_flip = feasible_flip, number_of_sols_found = number_of_sols_found ))
  }





