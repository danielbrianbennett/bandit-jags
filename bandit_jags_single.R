# clear workspace:  
rm(list=ls())

# load rjags package
library(R2jags)

# set a couple of helpful variables
participantID <- 10308915 # which participant's data to test?
nTrials <- 30 # per block
nBlocks <- 3
nBandits <- 4
mean0 <- 0
variance0 <- 1000
fudgeFactor <- .00001

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

extract$whichFilled[extract$whichFilled == "none"] = 0
extract$whichFilled[extract$whichFilled == "top"] = 1
extract$whichFilled[extract$whichFilled == "right"] = 2
extract$whichFilled[extract$whichFilled == "bottom"] = 3
extract$whichFilled[extract$whichFilled == "left"] = 4
extract$whichFilled <- as.numeric(extract$whichFilled)

# recode negative change lags
extract$changeLag[extract$changeLag < 0] <- fudgeFactor

# create data containers to pass to jags, and fill them
choices <- array(data = NA, dim = c(nBlocks,nTrials)) # choice data
points <- array(data = NA, dim = c(nBlocks,nTrials)) # points data
changeLag <- matrix(extract[extract$ID == subsetID,]$changeLag,nBlocks,nTrials,byrow = T) # record how long since change
choices[,] <- matrix(extract[extract$ID == subsetID,]$choice,nBlocks,nTrials,byrow = T)
points[,] <- matrix(extract[extract$ID == subsetID,]$pointsWon,nBlocks,nTrials,byrow = T)
whichFilled <- matrix(extract[extract$ID == subsetID,]$whichFilled,nBlocks,nTrials,byrow = T) 


# list data to be passed on to JAGS
data <- list("choices",
             "changeLag",
             "nBandits", 
             "nBlocks",
             "nTrials",
             "points",
             "whichFilled",
             "mean0",
             "variance0",
             "fudgeFactor"
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
  b = 10,
  p = .1,
  q = .1
))

# call jags
samples <- jags(data, inits=initVals, parameters, model.file = bugsFile, 
                n.chains=1, n.iter=5000, n.burnin=2000, n.thin=1)