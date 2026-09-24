# config.R -- the only file a new user needs to edit.
# Every script starts with source("config.R"), so run them with the working
# directory set to the folder that contains this file.
# Author: Darius J. Ledbetter 9/24

# ---- EDIT THESE THREE PATHS ------------------------------------------------
proj_dir <- "C:/FVS/LRLR26_test"   # contains FVS_Data.db; keyfiles/, chunks/ and results are written here # to get this path I just loaded the excel file into fvs and it created this in my FVS folder on my computer connected to the software
data_dir <- "C:/Users/djledbet/Desktop/rfvs/Learning-rfvs/data"   # FVS_Input_all_spp.02.xlsx, data_t1_all_spp.csv, data_t2_all_spp.csv
fvs_bin  <- "C:/FVS/FVSSoftware/FVSbin"  # contains FVSsn.dll

# ---- Settings (leave as is to reproduce the published run) ------------------
fvs_variant <- "FVSsn"   # southern variant
cycle_years <- 5         # FVS cycle length in years
chunk_size  <- 25        # stands per saved chunk
resume      <- FALSE     # FALSE = clean run (old chunks are deleted).
                         # TRUE  = continue after a crash, reusing finished chunks.

# ---- Derived paths (don't edit) ---------------------------------------------
keyfile_dir <- file.path(proj_dir, "keyfiles")
chunk_dir   <- file.path(proj_dir, "chunks")
