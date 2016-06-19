# clear workspace:  
rm(list=ls()) 

# set a couple of helpful variables
participantID <- 10308915
nTrials <- 30 # per block
nBlocks <- 3
nBandits <- 4


# define working directory and datafile
dataDir <- "~/Google Drive/Works in Progress/JSBANDIT/Bandit/data/Bandit project shared data/"
dataFile <- "banditData_v2point2.RData"

# set working directory and load file
setwd(dataDir)
load(dataFile)

# load rjags package
library(R2jags)

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
d <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # choice data
points <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # points data

for (p in 1:nParticipants){
  d[,,p] <- matrix(extract[extract$ID == subsetID[p],]$choice,nBlocks,nTrials,byrow = T)
  points[,,p] <- matrix(extract[extract$ID == subsetID[p],]$pointsWon,nBlocks,nTrials,byrow = T)
}

# list data to be passed on to JAGS
data <- list("nTrials",
             "nBlocks",
             "nParticipants",
             "nBandits",
             "d", 
             "points"
) 

# list parameters to estimate in JAGS
parameters <- c("sigma_zeta",
                "sigma_gamma",
                "q",
                "p",
                "b"
) 

# initial values of parameters
initVals <-	list(list(
  sigma_zeta = 10,
  sigma_gamma = 10,
  q = 5,
  p = 5,
  b = 10,
))

# call jags
samples <- jags(data, inits=initVals, parameters, model.file = "bandit_jags_single.txt", 
                n.chains=1, n.iter=5000, n.burnin=2000, n.thin=1)

