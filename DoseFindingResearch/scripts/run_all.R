# Rscript scripts/run_all.R
# Or source("scripts/run_all.R", encoding = "UTF-8") in RStudio.
if (!file.exists("DoseFindingResearch.Rproj")) {
  stop("Set the working directory to the DoseFindingResearch project root first.")
}
source("scripts/01_generate.R", encoding = "UTF-8")
source("scripts/02_run.R", encoding = "UTF-8")
source("scripts/03_analyse.R", encoding = "UTF-8")
