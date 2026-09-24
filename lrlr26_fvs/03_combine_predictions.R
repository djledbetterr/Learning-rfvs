# 03_combine_predictions.R
# Combines the chunk files into one predictions table and runs sanity checks.
# Output: t2_predictions.rds  (one row per tree per snapshot; 'when' is "t1" or "t2")
# Author: Darius J. Ledbetter 9/24

source("config.R")
library(dplyr)

stand_years <- readRDS(file.path(proj_dir, "stand_years.rds"))

files <- list.files(chunk_dir, pattern = "\\.rds$", full.names = TRUE)
stopifnot(length(files) == ceiling(nrow(stand_years) / chunk_size))   # 29 chunks for 703 stands

parts  <- lapply(files, readRDS)
pred   <- bind_rows(lapply(parts, `[[`, "pred"))
failed <- unlist(lapply(parts, `[[`, "failed"))

# each tree must appear once per snapshot, with equal t1 and t2 counts
stopifnot(nrow(count(pred, STAND_ID, TREE_CN, when) %>% filter(n > 1)) == 0,
          sum(pred$when == "t1") == sum(pred$when == "t2"))
if (length(failed) > 0) warning(length(failed), " stand(s) failed; see t2_failed_stands.rds")

saveRDS(pred,   file.path(proj_dir, "t2_predictions.rds"))
saveRDS(failed, file.path(proj_dir, "t2_failed_stands.rds"))

# ---- summary to compare with the README's known-good numbers ----
cat("stands:", n_distinct(pred$STAND_ID), "\n")
cat("failed:", length(failed), "\n")
print(table(pred$when))

growth <- pred %>%
  group_by(STAND_ID, TREE_CN) %>%
  summarise(dbh_t1 = dbh[when == "t1"], dbh_t2 = dbh[when == "t2"],
            ht_t1  = ht[when == "t1"],  ht_t2  = ht[when == "t2"],
            tpa_t1 = tpa[when == "t1"], tpa_t2 = tpa[when == "t2"],
            .groups = "drop")

print(summary(growth$dbh_t2 - growth$dbh_t1))   # DBH change (in)
print(summary(growth$ht_t2  - growth$ht_t1))    # height change (ft)
print(summary(growth$tpa_t2 / growth$tpa_t1))   # < 1 means FVS mortality

# ---- There will be an rds inside of the FVS folder where the run was simulated and to load the predictions of t1 and t2 into this folder copy the syntax code below ' ----
# t2_predictions <- readRDS("C:/FVS/LRLR26_test/t2_predictions.rds")
t2_predictions <- readRDS("C:/FVS/LRLR26_test/t2_predictions.rds")