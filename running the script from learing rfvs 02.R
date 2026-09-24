# Part A ----
library(dplyr)
library(readxl)

data_dir    <- "C:/Users/djledbet/Desktop/rfvs/Learning-rfvs/data"
proj_dir    <- "C:/FVS/LRLRD26 9-23-2026"
keyfile_dir <- file.path(proj_dir, "keyfiles")

# FVS_StandInit = one row per plot (FVS_PlotInit is per subplot; don't use it)
stand_info <- read_excel(file.path(data_dir, "FVS_Input_all_spp.02.xlsx"),
                         sheet = "FVS_StandInit") %>%
  select(STAND_ID, STAND_CN, INV_YEAR)

# STAND_CN (FVS) = PLT_CN (t1), linked to pltID
t1_link <- read.csv(file.path(data_dir, "data_t1_all_spp.csv")) %>%
  select(PLT_CN, pltID) %>% distinct() %>% rename(STAND_CN = PLT_CN)

# pltID -> t2 measurement year
t2_link <- read.csv(file.path(data_dir, "data_t2_all_spp.csv")) %>%
  select(pltID, MEASYEAR) %>% distinct() %>% rename(t2_year = MEASYEAR)

stand_years <- stand_info %>%
  left_join(t1_link, by = "STAND_CN") %>%
  left_join(t2_link, by = "pltID") %>%
  rename(t1_year = INV_YEAR)

# Stop if the join fans out, a stand lacks a t2 year, or the gap is odd
stopifnot(nrow(stand_years) == n_distinct(stand_years$STAND_ID),
          !anyNA(stand_years),
          all(stand_years$t2_year > stand_years$t1_year))

saveRDS(stand_years, file.path(proj_dir, "stand_years.rds"))   # Part B reads this

generate_fvs_keyfile <- function(stand_id, stand_cn, t1_year, t2_year,
                                 db_in = "FVS_Data.db", time_step = 5,
                                 out_dir = keyfile_dir) {
  total_years <- t2_year - t1_year
  num_cycle   <- ceiling(total_years / time_step)
  remainder   <- total_years - ((num_cycle - 1) * time_step)
  
  extra_timeint <- if (remainder != time_step) {
    sprintf("TimeInt       %d        %d\n", as.integer(num_cycle), as.integer(remainder))
  } else ""
  
  id <- format(stand_id, scientific = FALSE, trim = TRUE)
  cn <- format(stand_cn, scientific = FALSE, trim = TRUE)
  
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
NoTriple
Process

Stop
",
    id, id, cn, as.integer(t1_year), as.integer(time_step), extra_timeint,
    as.integer(num_cycle + 1),           # +1 so t2 is a start-of-cycle stop
    paste0(id, "_out.db"), db_in)
  
  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  out_path <- file.path(out_dir, paste0(id, ".key"))
  writeLines(key_text, out_path)
  out_path
}

# remove old keyfiles (including the two test copies), then regenerate
if (dir.exists(keyfile_dir))
  file.remove(list.files(keyfile_dir, pattern = "\\.key$", full.names = TRUE))

for (i in seq_len(nrow(stand_years))) {
  generate_fvs_keyfile(stand_years$STAND_ID[i], stand_years$STAND_CN[i],
                       stand_years$t1_year[i],  stand_years$t2_year[i])
}

files <- list.files(keyfile_dir, pattern = "\\.key$", full.names = TRUE)
stopifnot(length(files) == nrow(stand_years),
          !any(sapply(files, function(f) any(grepl("e\\+", readLines(f))))))
cat("Part A done:", length(files), "keyfiles\n")

file.exists("C:/FVS/LRLRD26 9-23-2026/stand_years.rds")   # want TRUE

#Part B ----
library(rFVS); library(dplyr); library(RSQLite)
setwd("C:/FVS/LRLRD26 9-23-2026")
fvsLoad("FVSsn", bin = "C:/FVS/FVSSoftware/FVSbin")

stand_years <- readRDS("stand_years.rds")
con <- dbConnect(SQLite(), "FVS_Data.db")

capture <- "list(year = fvsGetEventMonitorVariables('year'),
  trees = fvsGetTreeAttrs(c('id','dbh','ht','cratio','tpa')))"

run_stands <- function(sy) {
  results <- list(); failed <- character()
  for (k in seq_len(nrow(sy))) {
    sid <- format(sy$STAND_ID[k], scientific = FALSE, trim = TRUE)
    writeLines(sid, "last_started.txt")      # if R dies, this names the stand
    t1 <- sy$t1_year[k]; t2 <- sy$t2_year[k]
    
    res <- tryCatch({
      # FVS keeps HISTORY 0 and 1, drops 6 and 8
      ti <- dbGetQuery(con, sprintf(
        "SELECT TREE_CN, TREE_ID, PLOT_ID, SPECIES, DIAMETER, HT
         FROM FVS_TreeInit WHERE Stand_ID = '%s' AND HISTORY IN (0, 1)", sid))
      ti$id <- seq_len(nrow(ti))
      
      fvsSetCmdLine(paste0("--keywordfile=keyfiles/", sid, ".key"))
      o <- fvsInteractRun(AfterEM1 = capture)
      yrs <- as.integer(sub(".*:", "", names(o)))
      stopifnot(t1 %in% yrs, t2 %in% yrs)
      
      # safety check: FVS's t1 records must match the database rows
      tr1 <- o[[which(yrs == t1)]]$AfterEM1$trees
      stopifnot(nrow(tr1) == nrow(ti),
                max(abs(ti$DIAMETER - tr1$dbh)) < 0.01,
                max(abs(ti$HT - tr1$ht)) < 0.01)
      
      bind_rows(lapply(c(t1, t2), function(y) {
        tr <- o[[which(yrs == y)]]$AfterEM1$trees
        cbind(STAND_ID = sid, year = y, when = ifelse(y == t1, "t1", "t2"),
              tr, ti[seq_len(nrow(tr)), c("TREE_CN", "TREE_ID", "PLOT_ID", "SPECIES")])
      }))
    }, error = function(e) {
      failed <<- c(failed, paste(sid, "-", conditionMessage(e))); NULL })
    
    results[[sid]] <- res
  }
  list(pred = bind_rows(results), failed = failed)
}

# resumable chunk loop: finished chunks are skipped if you rerun after a crash
dir.create("chunks", showWarnings = FALSE)
chunk_size <- 25
chunks <- split(seq_len(nrow(stand_years)),
                ceiling(seq_len(nrow(stand_years)) / chunk_size))

for (cn in names(chunks)) {
  f <- sprintf("chunks/chunk_%03d.rds", as.integer(cn))
  if (file.exists(f)) next
  saveRDS(run_stands(stand_years[chunks[[cn]], ]), f)
  gc()
  cat("finished chunk", cn, "of", length(chunks), "\n")
}

# Part C: ----
library(dplyr); library(RSQLite)
setwd("C:/FVS/LRLRD26 9-23-2026")

## ---- combine all chunks ----
files <- list.files("chunks", pattern = "\\.rds$", full.names = TRUE)
length(files)                                   # want 29

parts  <- lapply(files, readRDS)
pred   <- bind_rows(lapply(parts, `[[`, "pred"))
failed <- unlist(lapply(parts, `[[`, "failed"))

saveRDS(pred, "t2_predictions.rds")
saveRDS(failed, "t2_failed_stands.rds")

## ---- how did it go? ----
n_distinct(pred$STAND_ID)                       # 703 minus any failures
length(failed)                                  # how many stands were skipped
head(failed, 20)                                # the stand IDs and reasons
table(pred$when)                                # t1 and t2 counts should be equal
nrow(pred)

## ---- what does it look like? ----
head(pred, 10)
str(pred)

# predicted growth per tree (t2 minus t1)
growth <- pred %>%
  group_by(STAND_ID, TREE_CN) %>%
  summarise(dbh_t1 = dbh[when == "t1"], dbh_t2 = dbh[when == "t2"],
            ht_t1  = ht[when == "t1"],  ht_t2  = ht[when == "t2"],
            tpa_t1 = tpa[when == "t1"], tpa_t2 = tpa[when == "t2"],
            .groups = "drop") %>%
  mutate(dbh_change = dbh_t2 - dbh_t1,
         ht_change  = ht_t2 - ht_t1)

summary(growth$dbh_change)
summary(growth$ht_change)
summary(growth$tpa_t2 / growth$tpa_t1)          # below 1 means mortality shows up in tpa

all_preds <- readRDS("C:/FVS/LRLRD26 9-23-2026/t2_predictions.rds")
