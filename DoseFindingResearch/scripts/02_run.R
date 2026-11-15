source("config/parameters.R", encoding = "UTF-8")
source("legacy/unifiDoseF/get_oc_RQ_CRM_bank.R", encoding = "UTF-8")
source("legacy/unifiDoseF/get_oc_QuasiBOIN_bank.R", encoding = "UTF-8")

input <- readRDS(file.path(output_dir, "input.rds"))
settings <- input$settings
score_raw <- settings$score_raw
target_raw <- settings$target_raw
results <- list()

for (scenario in names(input$banks)) {
  bank <- input$banks[[scenario]]

  # 与 legacy/try_bank.R 相同；增加患者记录用于后续分析。
  oc_qcrm <- get_oc_RQ_CRM_bank(
    bank = bank, skeletons = settings$p1,
    target = target_raw, score = score_raw,
    cohortsize = settings$cohortsize, ncohort = settings$ncohort,
    cutoff.eli = settings$cutoff.eli, ntrial = settings$ntrial,
    keep.patient.data = TRUE
  )

  oc_rqcrm <- get_oc_RQ_CRM_bank(
    bank = bank, skeletons = rbind(settings$p1, settings$p2, settings$p3),
    target = target_raw, score = score_raw,
    cohortsize = settings$cohortsize, ncohort = settings$ncohort,
    mselection = 1, cutoff.eli = settings$cutoff.eli,
    ntrial = settings$ntrial, keep.patient.data = TRUE
  )

  oc_qboin <- get_oc_QuasiBOIN_bank(
    bank = bank, target = target_raw / max(score_raw),
    score = score_raw / max(score_raw),
    cohortsize = settings$cohortsize, ncohort = settings$ncohort,
    cutoff.eli = settings$cutoff.eli, ntrial = settings$ntrial,
    keep.patient.data = TRUE
  )

  results[[scenario]] <- list(
    QCRM = oc_qcrm, RQCRM = oc_rqcrm, QBOIN = oc_qboin
  )
  message("完成场景：", scenario)
}

# 保留旧函数的完整输出：N、Y、dselect、stop.reason、patient.data 等。
saveRDS(list(settings = settings, results = results),
        file.path(output_dir, "results.rds"))
