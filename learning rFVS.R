# okay so this script is just me working through and learning rFVS since there is so much information about this
# I will be talking through things that work and do not work for this package 

rm(list = ls())

# lets start with installing this 

# Installing ----
# okay so i had to look up steps on how to install this and this was the one this was found in the terminal so I can just install it since it is on my
# desktop somewhere 
install.packages("devtools", repos = "https://cloud.r-project.org")  # skip if already installed
devtools::install("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS")


# Getting a feel for the core workflow (do this first) ----

# Every rFVS session follows the same basic pattern

library(rFVS)

# this line of code list all of the different things you do with rFVS
ls("package:rFVS")

# these below do not work with this pacakge 
?fvsAddActivity
??fvsMakeKeyFile

# so this is the help page in R ran this and found out it tell you nothing
help(package = 'rFVS')

args(fvsMakeKeyFile)
fvsMakeKeyFile

# Ok this line of code right here is what I was looking fro it opens up another tab of the function
# it also tells you the parameters with and e.g., on how to write it 
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsMakeyFile.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsAddActivity.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsAddTrees.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsCompositeSum.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsCutNow.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetDims.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetEventMonitorVariables.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetRestartcode.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetSpeciesAttrs.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetSpeciesCodes.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetStandIDs.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetSVSObjectSet.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsLoad.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsSetCmdLine.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsSetTreeAttrs.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetSummary.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetTreeAttrs.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsSetEventMonitorVariables.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsSetupSummary.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsGetSVSDims.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsInteractRun.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsRun.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsSetSpeciesAttrs.R")
file.show("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/R/fvsUnitConversion.R")

# Practice run ----
fvsLoad("FVSsn", bin = "C:/FVS/FVSSoftware/FVSbin")
setwd("C:/Users/djledbet/ForestVegetationSimulator-Interface/rFVS/tests")
fvsSetCmdLine("--keywordfile=iet01.key")
fvsRun()

rtn <- fvsRun()
print(rtn)
fvsGetRestartcode()

summary_data <- fvsGetSummary()
print(summary_data)

trees <- fvsGetTreeAttrs(c("dbh", "ht", "species", "tpa"))
head(trees)

species_codes <- fvsGetSpeciesCodes()
print(species_codes)

fvsGetDims()

fvsGetStandIDs()

fvsSetCmdLine("--keywordfile=iet01.key")

fetchTrees <- function(captureYears) {
  curYear <- fvsGetEventMonitorVariables("year")
  if (is.na(match(curYear, captureYears))) NULL else
    fvsGetTreeAttrs(c("dbh", "ht", "species"))
}

output <- fvsInteractRun(AfterEM1 = "fetchTrees(c(2020,2070))", SimEnd = fvsGetSummary)

str(output)

