# clear workspace:  
rm(list=ls())

# load rjags package
library(R2jags)

# set a couple of helpful variables
participantID <- 10308915 # which participant's data to test?
nTrials <- 30 # per block
nBlocks <- 3
nBandits <- 4

# define working directory and datafile
dataDir <- "~/Google Drive/Works in Progress/JSBANDIT/Bandit/data/Bandit project shared data/"
dataFile <- "banditData_v2point2.RData"
bugsFile <- "~/Documents/Git/bandit-jags/bandit_jags_single.txt"

# set working directory and load file
setwd(dataDir)
load(dataFile)

# extract the specified participant
subsetID <- participantID
extract <- subset(sorted.data, ID %in% subsetID)

# recode choices from string to numeric
extract$choice[extract$choice == "top"] = 1
extract$choice[extract$choice == "right"] = 2
extract$choice[extract$choice == "bottom"] = 3
extract$choice[extract$choice == "left"] = 4
extract$choice <- as.numeric(extract$choice)

# create data containers to pass to jags, and fill them
choices <- array(data = NA, dim = c(nBlocks,nTrials)) # choice data
points <- array(data = NA, dim = c(nBlocks,nTrials)) # points data
choices[,] <- matrix(extract[extract$ID == subsetID,]$choice,nBlocks,nTrials,byrow = T)
points[,] <- matrix(extract[extract$ID == subsetID,]$pointsWon,nBlocks,nTrials,byrow = T)

# specify comparison matrix A
A <- array(data = 0, dim = c(3,4,4))
A[,,1] <- matrix(c(1,1,1,-1,0,0,0,-1,0,0,0,-1),nrow = 3, ncol = 4)
A[,,2] <- matrix(c(-1,0,0,1,1,1,0,-1,0,0,0,-1),nrow = 3, ncol = 4)
A[,,3] <- matrix(c(-1,0,0,0,-1,0,1,1,1,0,0,-1),nrow = 3, ncol = 4)
A[,,4] <- matrix(c(-1,0,0,0,-1,0,0,0,-1,1,1,1),nrow = 3, ncol = 4)

# list data to be passed on to JAGS
data <- list("A",
             "choices",
             "nBandits", 
             "nBlocks",
             "nTrials",
             "points"
) 

# list parameters to estimate in JAGS
parameters <- c("sigma_zeta",
                "sigma_epsilon",
                "b",
                "p",
                "q"
) 

# initial values of parameters
initVals <-	list(list(
  sigma_zeta = 10,
  sigma_epsilon = 10,
  b = 5,
  p = 5,
  q = 10
))

# call jags
samples <- jags(data, inits=initVals, parameters, model.file = bugsFile, 
                n.chains=1, n.iter=5000, n.burnin=2000, n.thin=1)

