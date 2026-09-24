# 02_run_rfvs.R
# Runs FVS on every stand through rFVS and saves the tree list at t1 and t2.
# Run in a FRESH R session (Session > Restart R), working directory = folder
# containing config.R. Results are saved in chunks so a crash loses little.
# Author: Darius J. Ledbetter 9/24

source("config.R")
library(rFVS); library(dplyr); library(RSQLite)

setwd(proj_dir)   # keyfiles use relative paths (FVS_Data.db, keyfiles/)
fvsLoad(fvs_variant, bin = fvs_bin)

stand_years <- readRDS("stand_years.rds")
con <- dbConnect(SQLite(), "FVS_Data.db")

# ---- record what produced these results ----
dll <- file.path(fvs_bin, paste0(fvs_variant, ".dll"))
writeLines(c(
  paste("run date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
  paste(fvs_variant, "dll md5:", unname(tools::md5sum(dll))),
  paste("FVS_Data.db md5:",      unname(tools::md5sum("FVS_Data.db"))),
  paste("rFVS version:",         as.character(packageVersion("rFVS"))),
  "", capture.output(sessionInfo())
), "run_info.txt")

# ---- what to capture at each FVS stop (start of each cycle) ----
capture <- "list(year = fvsGetEventMonitorVariables('year'),
  trees = fvsGetTreeAttrs(c('id','dbh','ht','cratio','tpa')))"

run_stands <- function(sy) {
  results <- list(); failed <- character()
  for (k in seq_len(nrow(sy))) {
    sid <- format(sy$STAND_ID[k], scientific = FALSE, trim = TRUE)
    writeLines(sid, "last_started.txt")      # if R dies, this names the stand
    t1 <- sy$t1_year[k]; t2 <- sy$t2_year[k]

    res <- tryCatch({
      # FVS loads HISTORY 0 and 1 and drops 6 and 8 (found empirically; see README)
      ti <- dbGetQuery(con, sprintf(
        "SELECT TREE_CN, TREE_ID, PLOT_ID, SPECIES, DIAMETER, HT
         FROM FVS_TreeInit WHERE Stand_ID = '%s' AND HISTORY IN (0, 1)", sid))

      fvsSetCmdLine(paste0("--keywordfile=keyfiles/", sid, ".key"))
      o <- fvsInteractRun(AfterEM1 = capture)
      yrs <- as.integer(sub(".*:", "", names(o)))
      stopifnot(t1 %in% yrs, t2 %in% yrs)

      # safety check: FVS's t1 records must match the database rows, in order
      tr1 <- o[[which(yrs == t1)]]$AfterEM1$trees
      stopifnot(nrow(tr1) == nrow(ti),
                max(abs(ti$DIAMETER - tr1$dbh)) < 0.01,
                max(abs(ti$HT - tr1$ht)) < 0.01)

      bind_rows(lapply(c(t1, t2), function(y) {
        tr <- o[[which(yrs == y)]]$AfterEM1$trees
        stopifnot(nrow(tr) == nrow(ti))
        # tree keys are attached by row position (FVS's 'id' is NOT unique within a stand)
        cbind(STAND_ID = sid, year = y, when = ifelse(y == t1, "t1", "t2"),
              tr, ti[seq_len(nrow(tr)), c("TREE_CN", "TREE_ID", "PLOT_ID", "SPECIES")])
      }))
    }, error = function(e) {
      failed <<- c(failed, paste(sid, "-", conditionMessage(e))); NULL })

    results[[sid]] <- res
  }
  list(pred = bind_rows(results), failed = failed)
}

# ---- chunked loop ----
dir.create(chunk_dir, showWarnings = FALSE)
if (!resume) unlink(list.files(chunk_dir, full.names = TRUE))   # clean run: no stale chunks

chunks <- split(seq_len(nrow(stand_years)),
                ceiling(seq_len(nrow(stand_years)) / chunk_size))

for (cn in names(chunks)) {
  f   <- file.path(chunk_dir, sprintf("chunk_%03d.rds", as.integer(cn)))
  tmp <- paste0(f, ".tmp")
  if (file.exists(f)) next
  saveRDS(run_stands(stand_years[chunks[[cn]], ]), tmp)
  file.rename(tmp, f)      # only a finished save gets the real name
  gc()
  cat("finished chunk", cn, "of", length(chunks), "\n")
}

dbDisconnect(con)
