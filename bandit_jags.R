# clear workspace:  
rm(list=ls())

# load rjags package
library(R2jags)

# set a couple of helpful variables
nTrials <- 30 # per block
nBlocks <- 3
nBandits <- 4
mean0 <- 0
variance0 <- 1000
fudgeFactor <- .00001

# define working directory and datafile
dataDir <- "~/Google Drive/Works in Progress/JSBANDIT/Bandit/data/Bandit project shared data/"
dataFile <- "banditData_v2point2.RData"
bugsFile <- "~/Documents/Git/bandit-jags/bandit_jags.txt"

# set working directory and load file
setwd(dataDir)
load(dataFile)

# extract participant data
nParticipants <- 3#length(unique(sorted.data$ID)) # how many participants' data to test?
subsetID <- unique(sorted.data$ID)[1:nParticipants]
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

# create data containers to pass to jags
choices <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # choice data
points <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # points data
changeLag <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # change lag data
whichFilled <- array(data = NA, dim = c(nBlocks,nTrials,nParticipants)) # change lag data

# deal data to arrays built above
for (p in 1:nParticipants){
  choices[,,p] <- matrix(extract[extract$ID == subsetID[p],]$choice,nBlocks,nTrials,byrow = T)
  points[,,p] <- matrix(extract[extract$ID == subsetID[p],]$pointsWon,nBlocks,nTrials,byrow = T)
  changeLag[,,p] <- matrix(extract[extract$ID == subsetID[p],]$changeLag,nBlocks,nTrials,byrow = T)
  whichFilled[,,p] <- matrix(extract[extract$ID == subsetID[p],]$whichFilled,nBlocks,nTrials,byrow = T)
}

# list data to be passed on to JAGS
data <- list("choices",
             "points",
             "changeLag",
             "whichFilled",
             "nBandits", 
             "nBlocks",
             "nTrials",
             "nParticipants",
             "mean0",
             "variance0",
             "fudgeFactor"
) 

# list parameters to estimate in JAGS
parameters <- c("sigma_zeta",
                "sigma_epsilon",
                "mu_q",
                "sigma_q",
                "mu_p",
                "sigma_p",
                "mu_b", 
                "sigma_b"
                ) 

# initial values of parameters
initVals <-	list(list(
            sigma_zeta = 4,
            sigma_epsilon = 24,
            mu_q = 1,
            sigma_q = .2,
            mu_p = 1,
            sigma_p = .2,
            mu_b = 4,
            sigma_b = 1
            ))

# call jags
ptm <- proc.time()
samples <- jags(data, inits=initVals, parameters, model.file = bugsFile, 
                n.chains=1, n.iter=5000, n.burnin=2000, n.thin=2)
proc.time() - ptm
