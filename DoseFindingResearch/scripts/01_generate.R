# Run from the DoseFindingResearch project root.
source("scripts/00_parameters.R", encoding = "UTF-8")
source("R/generate_bank.R", encoding = "UTF-8")
input <- generate_pcs_input(settings)
dir.create(settings$output_dir, recursive = TRUE, showWarnings = FALSE)
saveRDS(input, file.path(settings$output_dir, "input.rds"))
message("Saved patient banks: ", file.path(settings$output_dir, "input.rds"))
