###############################################################
####### Test for Beta Contraints with Priors for GLM  #########
###############################################################
#setwd("/Users/amy/h2o/R/tests/testdir_jira")

setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../findNSourceUtils.R')

test.Priors.BetaConstraints <- function(conn) {
  Log.info("Import modelStack data into H2O...")
  ## Import data
  homeDir = "/mnt/0xcustomer-datasets/c27/"
  pathToFile = paste0(homeDir, "data.csv")
  pathToConstraints <- paste0(homeDir, "constraints_indices.csv")
  modelStack = h2o.importFile(conn, pathToFile)
  betaConstraints.hex = h2o.importFile(conn, pathToConstraints)
  beta_nointercept.hex <- betaConstraints.hex[1:nrow(betaConstraints.hex)-1,]
  beta_nointercept.hex
  
  ## Set Parameters (default standardization = T)
  betaConstraints = as.data.frame(betaConstraints.hex)
  indVars =  as.character(betaConstraints$names[1:nrow(betaConstraints)-1])
  depVars = "C3"
  totRealProb=0.002912744
  higherAccuracy = TRUE
  lambda = 0
  alpha = 0
  family_type = "binomial"
  
  ## Take subset of data
  Log.info("Subset dataset to only predictor and response variables...")
  data.hex = modelStack[,c(indVars, depVars)]
  summary(data.hex)
  
  ## Test/Train Split
  Log.info("Split into test/train frame...")
  data.split = h2o.splitFrame(data = data.hex, ratios = 0.9, shuffle = T)
  data.train = data.split[[1]]
  data.test = data.split[[2]]
  
  
  ## Run full H2O GLM
  Log.info("Run a logistic regression with no regularization and alpha = 0 and beta constraints without priors. ")
  glm.h2o = h2o.glm(x = indVars, y = depVars, data = data.train, family = family_type,
                    lambda = 0, higher_accuracy = T,
                    alpha = alpha, beta_constraints = beta_nointercept.hex)
  best_model = glm.h2o
  pred = h2o.predict(best_model, data.test)
  perf = h2o.performance(data = pred[,3], reference = data.test[,depVars])
  
  
  ## Run full glmnet
  Log.info("Run a logistic regression with alpha = 0 and beta constraints ")
  train.df = as.data.frame(data.train)
  test.df = as.data.frame(data.test)
  
  xDataFrame = cbind(train.df[,indVars], rep(0, times = nrow(train.df)))
  names(xDataFrame) = c(names(xDataFrame)[1:ncol(xDataFrame)-1], "Intercept")
  xMatrix = as.matrix(xDataFrame)
  
  glm.r = glmnet(x = xMatrix, alpha = alpha, standardize = T,
                 y = train.df[,depVars], family = family_type, lower.limits = -100000, upper.limits = 100000)
  
  xTestFrame = cbind(test.df[,indVars], rep(0, times = nrow(test.df)))
  xTestMatrix = as.matrix(xTestFrame)
  pred_test.r = predict(glm.r, newx = xTestMatrix, type = "response")
  pred_train.r = predict(glm.r, newx = xMatrix, type = "response")
    
  ### Grab ROC and AUC
  library(AUC)
  
  h2o_pred = as.data.frame(pred)
  h2o_roc  = roc(h2o_pred$X1, factor(test.df[, depVars]))
  h2o_auc = auc(h2o_roc)
  
  # Find auc for both the testing and training set...
  glm_auc <- function(pred.r, ref.r){
    glmnet_pred = pred.r[,ncol(pred.r)]
    glmnet_roc = roc(glmnet_pred, factor(ref.r))
    glmnet_auc = auc(glmnet_roc)    
    return(glmnet_auc)
  }

  glmnet_test_auc = glm_auc(pred_test.r, test.df[,depVars])
  glmnet_train_auc = glm_auc(pred_train.r, train.df[,depVars])
  glmnet_deviance = deviance(glm.r)
  h2o_deviance = best_model@model$deviance
  
  print(paste0("AUC of H2O model on training set:  ", best_model@model$auc))
  print(paste0("AUC of H2O model on testing set:  ", h2o_auc))
  print(paste0("AUC of GLMnet model on training set:  ", glmnet_train_auc))
  print(paste0("AUC of GLMnet model on testing set:  ", glmnet_test_auc))
  
  checkEqualsNumeric(h2o_auc, glmnet_test_auc, tolerance = 0.05)
  
  ### Functions to calculate logistic gradient
  logistic_gradient <- function(x,y,beta) {
    y = -1 + 2*y
    eta = x %*% beta
    d = 1 + exp(-y*eta)
    grad = -y * (1-1.0/d)
    t(grad) %*% x
  }
  # no L1 here, alpha is 0
  h2o_logistic_gradient <- function(x,y,beta,beta_given,rho,lambda) {
    grad <- logistic_gradient(x,y,beta)/nrow(x) + (beta - beta_given)*rho + lambda*beta
  }
  
  ########### Run check of priors vs no priors  
  glm.h2o1 = h2o.glm(x = indVars, y = depVars, data = data.hex, family = family_type,
                    higher_accuracy = T, standardize = F,  prior = totRealProb,
                    alpha = alpha, beta_constraints = betaConstraints.hex)  
  glm.h2o2 = h2o.glm(x = indVars, y = depVars, data = data.hex, family = family_type,
                    higher_accuracy = T, standardize = F, prior = totRealProb,
                    alpha = alpha, beta_constraints = betaConstraints.hex[c("names","lower_bounds","upper_bounds")] )    
  
  ## Seperate into x and y matrices
  y = as.matrix(modelStack[,depVars])
  x = cbind(as.matrix(modelStack[,indVars]),1)
  
  Log.info("Calculate the gradient: ")  
  beta1 = as.numeric(glm.h2o1@model$coefficients)
  beta2 = as.numeric(glm.h2o2@model$coefficients)
  beta_given = as.numeric(betaConstraints$beta_given)
  rho = as.data.frame(betaConstraints.hex$rho)
  lambda = glm.h2o1@model$lambda
  logistic_gradient(x,y,beta1)
  gradient1 = h2o_logistic_gradient(x,y,beta1, beta_given, rho=1, lambda)
  gradient1
  gradient2 = h2o_logistic_gradient(x,y,beta2, beta_given, rho=0, lambda)
  gradient2
  
  Log.info("Check gradient of beta constraints with priors or beta given...")
  threshold = 1E-4
  print(gradient1)
  if(!all(gradient1 < threshold)) stop(paste0("Gradients from model output > ", threshold))
  
  Log.info("Check gradient of beta constraints without priors or beta given...")
  print(gradient2)
  if(!all(gradient2 < threshold)) stop(paste0("Gradients from model output > ", threshold))
  testEnd()
}

doTest("GLM Test: Beta Constraints with added Rho penalty", test.Priors.BetaConstraints)




