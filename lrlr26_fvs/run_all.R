# run_all.R -- runs the whole pipeline with one command.
#
# 1. Edit the three paths in config.R.
# 2. Set the working directory to the folder containing this file
#    (RStudio: Session > Set Working Directory > To Source File Location).
# 3. Run:  source("run_all.R")
#
# Each script runs in its own fresh R process (FVS needs a clean session).
# Each script's printed output is saved to logs/<script>.log.

if (!file.exists("config.R"))
  stop("config.R not found. Set the working directory to the folder containing run_all.R.")
source("config.R")

# ---- preflight: is everything the pipeline needs in place? ----
need <- c(file.path(data_dir, "FVS_Input_all_spp.02.xlsx"),
          file.path(data_dir, "data_t1_all_spp.csv"),
          file.path(data_dir, "data_t2_all_spp.csv"),
          file.path(proj_dir, "FVS_Data.db"),
          file.path(fvs_bin,  paste0(fvs_variant, ".dll")))
missing <- need[!file.exists(need)]
if (length(missing))
  stop("Missing file(s). Fix the paths in config.R or add the files:\n",
       paste0("  ", missing, collapse = "\n"))

pkgs   <- c("dplyr", "readxl", "RSQLite", "rFVS")
nopkg  <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(nopkg))
  stop("Install these R packages first: ", paste(nopkg, collapse = ", "),
       "\n(rFVS is installed from source; see README.md)")

# ---- run each script in its own R process ----
rscript <- file.path(R.home("bin"),
                     if (.Platform$OS.type == "windows") "Rscript.exe" else "Rscript")
dir.create("logs", showWarnings = FALSE)

for (s in c("01_build_keyfiles.R", "02_run_rfvs.R", "03_combine_predictions.R")) {
  log <- file.path("logs", paste0(s, ".log"))
  cat("running", s, "... (log: ", log, ")\n", sep = "")
  status <- system2(rscript, s, stdout = log, stderr = log)
  cat(paste0("  ", tail(readLines(log), 8)), sep = "\n")     # last lines of the log
  if (status != 0)
    stop(s, " failed. See ", log, ".\n",
         "If 02_run_rfvs.R crashed partway, set resume <- TRUE in config.R and rerun.")
}

cat("\nDone. Predictions saved to:", file.path(proj_dir, "t2_predictions.rds"), "\n")
cat("Compare the summary printed above with the known-good numbers in README.md.\n")
