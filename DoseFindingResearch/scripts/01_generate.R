# 从 DoseFindingResearch.Rproj 的项目根目录运行。
source("config/parameters.R", encoding = "UTF-8")
source("R/generate_bank.R", encoding = "UTF-8")

banks <- list()
for (i in seq_along(settings$scenarios)) {
  scenario <- names(settings$scenarios)[i]
  banks[[scenario]] <- generate_bank(
    ptox = settings$scenarios[[scenario]],
    nmax = settings$cohortsize * settings$ncohort,
    ntrial = settings$ntrial,
    seed = settings$seed + i - 1
  )
}

# 连同参数保存，后续运行和分析均以这份参数为准。
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(settings = settings, banks = banks),
        file.path(output_dir, "input.rds"))
