# 01_build_keyfiles.R
# Builds the stand table (stand -> t1 year -> t2 year) and one FVS keyword file
# per stand. FVS is not needed for this step.
# Run in a fresh R session, working directory = folder containing config.R.
# Author: Darius J. Ledbetter 9/24 (dates for the precceding scripts are the same due to working in other r scritps before cleaning these up to make scripts 01-03)

source("config.R")
library(dplyr)
library(readxl)

# FVS_StandInit = one row per plot (FVS_PlotInit is one row per subplot; don't use it)
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

# Stop if the join fans out, a stand lacks a t2 year, or a gap is not positive
stopifnot(nrow(stand_years) == n_distinct(stand_years$STAND_ID),
          !anyNA(stand_years),
          all(stand_years$t2_year > stand_years$t1_year))

saveRDS(stand_years, file.path(proj_dir, "stand_years.rds"))   # script 02 reads this

generate_fvs_keyfile <- function(stand_id, stand_cn, t1_year, t2_year,
                                 db_in = "FVS_Data.db", time_step = cycle_years,
                                 out_dir = keyfile_dir) {
  total_years <- t2_year - t1_year
  num_cycle   <- ceiling(total_years / time_step)
  remainder   <- total_years - ((num_cycle - 1) * time_step)

  # shorten the cycle that ends at t2 when the gap isn't a multiple of time_step
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
    as.integer(num_cycle + 1),           # +1 so t2 is a start-of-cycle stop (captured by AfterEM1)
    paste0(id, "_out.db"), db_in)

  if (!dir.exists(out_dir)) dir.create(out_dir, recursive = TRUE)
  out_path <- file.path(out_dir, paste0(id, ".key"))
  writeLines(key_text, out_path)
  out_path
}

# remove old keyfiles in the keyfile folder (this folder should hold only these files)
if (dir.exists(keyfile_dir))
  unlink(list.files(keyfile_dir, pattern = "\\.key$", full.names = TRUE))

for (i in seq_len(nrow(stand_years))) {
  generate_fvs_keyfile(stand_years$STAND_ID[i], stand_years$STAND_CN[i],
                       stand_years$t1_year[i],  stand_years$t2_year[i])
}

files <- list.files(keyfile_dir, pattern = "\\.key$", full.names = TRUE)
stopifnot(length(files) == nrow(stand_years),
          !any(sapply(files, function(f) any(grepl("e\\+", readLines(f))))))
cat("01 done:", length(files), "keyfiles in", keyfile_dir, "\n")   # expect 703
