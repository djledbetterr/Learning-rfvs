# okay so this script is just me working through and learning rFVS since there is so much information about this
# I will be talking through things that work and do not work for this package 

rm(list = ls())

# lets start  with installing this 

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

# working with the LRLR2026 Data ----
# Code to test this out on my end 
# So I uploaded my data set for LRLR26 into FVS and then it output the .db to my C drive in the FVS folder 


# after doing these steps I want to confirm it is the right one on my end

install.packages("RSQLite", repos = "https://cloud.r-project.org")
library(RSQLite)
ls("package:RSQLite")
?dbConnect

con <- dbConnect(SQLite(), "C:/FVS/LRLRD26 9-23-2026/FVS_Data.db")

dbListTables(con)
dbGetQuery(con, "SELECT COUNT(*) FROM FVS_TreeInit")
dbDisconnect(con)

devtools::install("C:/Users/djledbet/ForestVegetationSimulator-Interface/fvsOL")

library(fvsOL)
ls("package:fvsOL")

args(fvsOL)
fvsOL(prjDir = "C:/FVS/LRLRD26 9-23-2026", fvsBin = "C:/FVS/FVSSoftware/FVSbin")

# after running in the fvsOL verison and simulating a stand to get the key I then had to go to powershell and type in 

#  Get-ChildItem -Path "C:\FVS\LRLRD26 9-23-2026" -Filter "*.key" -Recurse
# which gave me this output 

# Directory: C:\FVS\LRLRD26 9-23-2026
# 
# 
# Mode                 LastWriteTime         Length Name
# 
#   -a----         9/23/2026   3:16 PM            813 bda1a100-cd6a-4bd5-845b-f38ba5363566.key

# And then after running that run something in this syntax with the code below to see what is inside of the keyword file I ran 
# below was ran in powershell
# Get-Content "C:\FVS\LRLRD26 9-23-2026\bda1a100-cd6a-4bd5-845b-f38ba5363566.key"
# 
# Which gave me 
# !!title: Run 1
# !!uuid:  bda1a100-cd6a-4bd5-845b-f38ba5363566
# !!built: 2026-09-23_15:16:58
# StdIdent
# 11410300001                Run 1
# StandCN
# 189296681020004
# MgmtId
# A001
# InvYear       2013
# TimeInt                 5
# TimeInt       3        3
# NumCycle     13
# 
# DataBase
# DSNOut
# bda1a100-cd6a-4bd5-845b-f38ba5363566.db
# * FVS_Summary, FVS_Compute, Mistletoe
# Summary        2
# Computdb          0         1
# MisRpts        2
# End
# 
# DelOTab            1
# DelOTab            2
# DelOTab            4
# !Exten:base Title:From: FVS_GroupAddFilesAndKeywords
# Database
# DSNIn
# FVS_Data.db
# StandSQL
# SELECT * FROM FVS_StandInit
# WHERE Stand_ID= '%StandID%'
# EndSQL
# TreeSQL
# SELECT * FROM FVS_TreeInit
# WHERE Stand_ID= '%StandID%'
# EndSQL
# END
# SPLabel
# All_FIA_Plots, &
#   All_Stands
# Process
# 
# Stop


# below this combines th ejoin (linking stand -> t1 -> t2) with the keyfile-generation loop ----
library(dplyr)
library(readxl)

## ---- 1. Load and join stand years ----
# all FVS spp for LRLR26 input workbook esalbsihed form github and scripts 01a-01d (on github)
stand_info <- read_excel('C:\\Users\\djledbet\\Desktop\\rfvs\\Learning-rfvs\\data\\FVS_Input_all_spp.02.xlsx', sheet = "FVS_PlotInit") %>%
  select(STAND_ID, STAND_CN, INV_YEAR)

# t1 csv - STAND_CN (FVS) = PLT_CN (t1), linked to pltID
t1_link <- read.csv("C:/Users/djledbet/Desktop/rfvs/Learning-rfvs/data/data_t1_all_spp.csv") %>%
  select(PLT_CN, pltID) %>%
  distinct() %>%
  rename(STAND_CN = PLT_CN)

# t2 csv - pltID linked to its measurement year
t2_link <- read.csv("C:/Users/djledbet/Desktop/rfvs/Learning-rfvs/data/data_t2_all_spp.csv") %>%
  select(pltID, MEASYEAR) %>%
  distinct() %>%
  rename(t2_year = MEASYEAR)

# join everything into one table: one row per stand
stand_years <- stand_info %>%
  left_join(t1_link, by = "STAND_CN") %>%
  left_join(t2_link, by = "pltID") %>%
  rename(t1_year = INV_YEAR)


# check for stands with no t2 match before running anything
cat("Stands with no t2 match:", sum(is.na(stand_years$t2_year)), "out of", nrow(stand_years), "\n")

# drop any stands missing t2 (can't project without a target year), there is none but jsut incase 
stand_years <- stand_years %>% filter(!is.na(t2_year))

# ---- 2. Keyfile generator function ----

generate_fvs_keyfile <- function(stand_id, stand_cn, t1_year, t2_year,
                                 db_in = "FVS_Data.db",
                                 time_step = 5,
                                 out_dir = "C:/FVS/LRLRD26 9-23-2026/keyfiles") {
  
  total_years <- t2_year - t1_year
  num_cycle <- ceiling(total_years / time_step)
  remainder <- total_years - ((num_cycle - 1) * time_step)
  
  extra_timeint <- if (remainder != time_step) {
    sprintf("TimeInt       %d        %d\n", num_cycle, remainder)
  } else {
    ""
  }
  
  out_db <- paste0(stand_id, "_out.db")
  
  key_text <- sprintf(
    "StdIdent
%s                Run_%s
StandCN
%s
MgmtId
A001
InvYear       %d
TimeInt                 %d
%sNumCycle     %d

DataBase
DSNOut
%s
* FVS_Summary, FVS_Compute, Mistletoe
Summary        2
Computdb          0         1
MisRpts        2
End

DelOTab            1
DelOTab            2
DelOTab            4
!Exten:base Title:From: FVS_GroupAddFilesAndKeywords
Database
DSNIn
%s
StandSQL
SELECT * FROM FVS_StandInit
WHERE Stand_ID= '%%StandID%%'
EndSQL
TreeSQL
SELECT * FROM FVS_TreeInit
WHERE Stand_ID= '%%StandID%%'
EndSQL
END
SPLabel
  All_FIA_Plots, &
  All_Stands
Process

Stop
",
    stand_id, stand_id, stand_cn, t1_year, time_step, extra_timeint, num_cycle,
    out_db, db_in
  )
  
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  
  out_path <- file.path(out_dir, paste0(stand_id, ".key"))
  writeLines(key_text, out_path)
  
  return(out_path)
}

# ---- 3. Test on one stand first ----

test_row <- stand_years[1, ]

test_path <- generate_fvs_keyfile(
  stand_id = test_row$STAND_ID,
  stand_cn = test_row$STAND_CN,
  t1_year  = test_row$t1_year,
  t2_year  = test_row$t2_year
)

file.show(test_path)

# ---- 4. Once the test looks right, loop over all stands ----

keyfile_paths <- character(nrow(stand_years))

for (i in seq_len(nrow(stand_years))) {
  keyfile_paths[i] <- generate_fvs_keyfile(
    stand_id = stand_years$STAND_ID[i],
    stand_cn = stand_years$STAND_CN[i],
    t1_year  = stand_years$t1_year[i],
    t2_year  = stand_years$t2_year[i]
  )
}

cat("Generated", length(keyfile_paths), "keyword files in", 
    "C:/FVS/LRLRD26 9-23-2026/keyfiles\n")

keyfile_dir <- "C:/FVS/LRLRD26 9-23-2026/keyfiles"

# figuring out if eveyrthign is right 
# 1. Rows vs. unique stands vs. files actually on disk
nrow(stand_years)
n_distinct(stand_years$STAND_ID)
length(list.files(keyfile_dir, pattern = "\\.key$"))

# 2. Any stand with more than one row (meaning conflicting t2 years)?
stand_years %>% count(STAND_ID) %>% filter(n > 1)

# 3. Remeasurement intervals should be plausible (roughly 4-15 yrs)
stand_years %>% mutate(gap = t2_year - t1_year) %>% count(gap)

# 4. Missing values
colSums(is.na(stand_years))

# -----
# rows per key in each source table
stand_info %>% count(STAND_ID) %>% count(n, name = "n_stands")
t1_link    %>% count(STAND_CN) %>% count(n, name = "n_cn")
t2_link    %>% count(pltID)    %>% count(n, name = "n_plots")

# in the joined table: do the duplicate rows actually disagree?
stand_years %>%
  group_by(STAND_ID) %>%
  summarise(rows = n(), n_cn = n_distinct(STAND_CN),
            n_t1 = n_distinct(t1_year), n_t2 = n_distinct(t2_year)) %>%
  count(rows, n_cn, n_t1, n_t2)

path <- "C:/Users/djledbet/Desktop/rfvs/Learning-rfvs/data/FVS_Input_all_spp.02.xlsx"
excel_sheets(path)  

# do the duplicate rows in FVS_PlotInit disagree on CN or year?
stand_info %>%
  group_by(STAND_ID) %>%
  summarise(rows = n(), n_cn = n_distinct(STAND_CN), n_yr = n_distinct(INV_YEAR)) %>%
  count(rows, n_cn, n_yr)

# peek at the odd stands (5-7 rows) and one normal one
pi_full <- read_excel(path, sheet = "FVS_PlotInit")
names(pi_full)
pi_full %>% filter(STAND_ID %in% (stand_info %>% count(STAND_ID) %>% filter(n > 4) %>% pull(STAND_ID))[1]) %>% print(width = Inf)

stand_info <- read_excel(path, sheet = "FVS_StandInit") %>%
  select(STAND_ID, STAND_CN, INV_YEAR)

stand_info %>% count(STAND_ID) %>% count(n, name = "n_stands")   # expect all n = 1

stand_years <- stand_info %>%
  left_join(t1_link, by = "STAND_CN") %>%
  left_join(t2_link, by = "pltID") %>%
  rename(t1_year = INV_YEAR)

# 1. Are t1_link / t2_link one row per key?
t1_link %>% count(STAND_CN) %>% count(n, name = "n_cn")
t2_link %>% count(pltID)    %>% count(n, name = "n_plots")

# 2. Final table: want rows = 703, one row per stand
nrow(stand_years)
stand_years %>% count(STAND_ID) %>% count(n, name = "n_stands")

# 3. NAs and gaps
colSums(is.na(stand_years))
stand_years %>% mutate(gap = t2_year - t1_year) %>% count(gap)

keyfile_dir <- "C:/FVS/LRLRD26 9-23-2026/keyfiles"
unlink(keyfile_dir, recursive = TRUE)

# make sure you're using the corrected 703-row table
nrow(stand_years)   # should print 703

keyfile_paths <- character(nrow(stand_years))

for (i in seq_len(nrow(stand_years))) {
  keyfile_paths[i] <- generate_fvs_keyfile(
    stand_id = stand_years$STAND_ID[i],
    stand_cn = stand_years$STAND_CN[i],
    t1_year  = stand_years$t1_year[i],
    t2_year  = stand_years$t2_year[i]
  )
}

length(list.files(keyfile_dir, pattern = "\\.key$"))   # should now be 703

chk <- stand_years %>%
  mutate(gap = t2_year - t1_year) %>%
  filter(gap %in% c(1, 5, 7, 13)) %>%
  group_by(gap) %>%
  slice(1)
chk

file.show(file.path(keyfile_dir, paste0(chk$STAND_ID[1], ".key")))

for (id in chk$STAND_ID) {
  cat("\n=====", id, "=====\n")
  cat(readLines(file.path(keyfile_dir, paste0(id, ".key")), n = 14), sep = "\n")
}

bad <- sapply(list.files(keyfile_dir, full.names = TRUE), function(f) {
  any(grepl("e\\+", readLines(f)))
})
sum(bad)   # want 0

library(rFVS)
setwd("C:/FVS/LRLRD26 9-23-2026")
fvsLoad("FVSsn", bin = "C:/FVS/FVSSoftware/FVSbin")

id  <- format(chk$STAND_ID[3], scientific = FALSE, trim = TRUE)   # the 7-year stand
fvsSetCmdLine(paste0("--keywordfile=keyfiles/", id, ".key"))

out <- fvsInteractRun(
  AfterEM1 = "list(year = fvsGetEventMonitorVariables('year'),
                   trees = fvsGetTreeAttrs(c('dbh','ht','cratio','species','tpa')))"
)

str(out, max.level = 2)   # what does the returned structure look like?
names(out)                # which years were captured?

# -----
setwd("C:/FVS/LRLRD26 9-23-2026")

# 1. Make a test copy of the keyfile with one extra cycle
id <- "11410300001"
kf <- readLines(paste0("keyfiles/", id, ".key"))

i  <- grep("^NumCycle", kf)
kf[i]                                   # should show: NumCycle     2
n  <- as.integer(sub("NumCycle\\s+", "", kf[i]))
kf[i] <- sprintf("NumCycle     %d", n + 1)
kf[i]                                   # should now show: NumCycle     3

writeLines(kf, "keyfiles/test_extra_cycle.key")

# 2. Run it (same call as before, new keyword file)
fvsSetCmdLine("--keywordfile=keyfiles/test_extra_cycle.key")

# test 2 -----
library(rFVS)
setwd("C:/FVS/LRLRD26 9-23-2026")
fvsLoad("FVSsn", bin = "C:/FVS/FVSSoftware/FVSbin")

kf <- readLines("keyfiles/test_extra_cycle.key")
p  <- grep("^Process", kf)
kf <- append(kf, "NoTriple", after = p - 1)     # insert before Process
writeLines(kf, "keyfiles/test_notriple.key")

fvsSetCmdLine("--keywordfile=keyfiles/test_notriple.key")
out <- fvsInteractRun(
  AfterEM1 = "list(year = fvsGetEventMonitorVariables('year'),
                   trees = fvsGetTreeAttrs(c('id','species','dbh','ht','cratio','tpa','mort','dg','htg')))"
)

names(out)
sapply(out, function(x) nrow(x$AfterEM1$trees))   # want 52 at every year
str(out[[1]]$AfterEM1$trees)

out <- fvsInteractRun(
  AfterEM1 = "list(year = fvsGetEventMonitorVariables('year'),
                   trees = fvsGetTreeAttrs(c('dbh','ht','cratio','species','tpa')))"
)

names(out)

t1 <- out[["11410300001:A001:2013"]]$AfterEM1$trees
t2 <- out[["11410300001:A001:2020"]]$AfterEM1$trees

str(t1)
nrow(t1); nrow(t2)
summary(t1$dbh); summary(t2$dbh)

library(RSQLite)
con <- dbConnect(SQLite(), "FVS_Data.db")
ti <- dbGetQuery(con, "SELECT * FROM FVS_TreeInit WHERE Stand_ID = '11410300001'")
dbDisconnect(con)

names(ti)
nrow(ti)                                        # should be 52
head(ti[, c("Tree_ID", "Species", "DBH", "Height")], 10)
head(out[[1]]$AfterEM1$trees[, c("id", "dbh", "ht")], 10)
