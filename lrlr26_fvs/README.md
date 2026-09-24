# LRLR26: FVS (SN variant) t1 -> t2 projection with rFVS

Projects each FIA plot from its t1 inventory to its own t2 measurement year with FVS
(run through rFVS) and saves the predicted tree list, so predictions can be compared
with observed t2 trees.

## Requirements
- Windows (uses `FVSsn.dll`)
- R with packages: dplyr, readxl, RSQLite, rFVS
- rFVS 2024.7.1, installed from source with
  devtools::install("<path>/ForestVegetationSimulator-Interface/rFVS") <-- this is what you run in R as of 9/24/2026 if you do not have it installed 
  Repository: https://github.com/USDAForestService/ForestVegetationSimulator-Interface
  Commit: 5e46bd30ca5e96e481ea351357f29c86747365ca
  Local modifications to the package source: none
- FVS binaries folder containing `FVSsn.dll` (record the version: see `run_info.txt`, which stores its md5)

## Inputs
| File | Where | Notes |
|---|---|---|
| `FVS_Input_all_spp.02.xlsx` | `data_dir` | FVS input workbook (sheets FVS_StandInit, FVS_PlotInit, FVS_TreeInit). Built with scripts 01a-01d on GitHub. |
| `data_t1_all_spp.csv` | `data_dir` | observed t1 trees (`PLT_CN`, `pltID`) |
| `data_t2_all_spp.csv` | `data_dir` | observed t2 trees (`PREV_TRE_CN`, `MEASYEAR`, `DIA`, `HT`, `STATUSCD`, ...) |
| `FVS_Data.db` | `proj_dir` | database FVS reads. TODO: describe exactly how it was created (import of the workbook in fvsOL, settings used): ______ |

## How to run
1. Edit the three paths in `config.R`.
2. Set R's working directory to the folder containing `run_all.R`, then run
   `source("run_all.R")`. It checks that the input files and packages exist, then runs the
   three scripts, each in its own fresh R process. Output is saved in `logs/`.
   - `01_build_keyfiles.R` -> `stand_years.rds` and 703 keyfiles in `keyfiles/`
   - `02_run_rfvs.R` -> chunk files in `chunks/`, plus `run_info.txt`
   - `03_combine_predictions.R` -> `t2_predictions.rds`
3. If step 2 crashes, set `resume <- TRUE` in `config.R` and run `source("run_all.R")` again.
   Set it back to `FALSE` for a clean run.

To run a script on its own, open it in a fresh R session with the working directory set to
the folder containing `config.R`.

## Known-good results (what a correct run prints)
- stands: 703, failed: 0
- rows: 36,242 at t1 and 36,242 at t2 (72,484 total)
- DBH change (in): min 0.011, median 1.157, mean 1.363, max 7.984
- height change (ft): median 8.293, mean 8.546
- tpa t2 / tpa t1: min 0.161, median 0.928, mean 0.881, max 1.000

## Method notes and assumptions
- `InvYear` = t1 year. `NumCycle` = ceiling(gap / 5) + 1. The extra cycle makes t2 a
  start-of-cycle stop, which the `AfterEM1` capture can see. The `TimeInt` override sits on
  the cycle that ends at t2.
- `NoTriple` keeps one record per input tree.
- FVS loads trees with `HISTORY` 0 and 1 and drops 6 and 8. Found empirically; the per-stand
  safety check in step 2 confirms it for every stand.
- FVS's `id` is not unique within a stand, so `TREE_CN` is attached by row position. Step 2
  checks each stand's t1 record count, DBH and HT against the database rows.
- Observed t2 trees link to predictions through `PREV_TRE_CN` = `TREE_CN`. Ingrowth
  (no `PREV_TRE_CN`) has no prediction.

## Checking a rerun
Keep a copy of a trusted `t2_predictions.rds` and compare:
`all.equal(readRDS("new/t2_predictions.rds"), readRDS("reference/t2_predictions.rds"))`
