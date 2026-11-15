source("config/parameters.R", encoding = "UTF-8")
saved <- readRDS(file.path(output_dir, "results.rds"))
settings <- saved$settings
trials <- patients <- doses <- comparison <- list()

for (scenario in names(saved$results)) {
  ptox <- settings$scenarios[[scenario]]
  true_mean <- as.vector(settings$score_raw %*% ptox)
  high_doses <- which(true_mean > settings$target_raw + settings$overdose_margin)
  true_mtd <- which.min(abs(true_mean - settings$target_raw))
  # 演示规则：全部剂量过毒时，以不推荐剂量为正确决定。
  if (length(high_doses) == ncol(ptox)) true_mtd <- 99

  for (method in names(saved$results[[scenario]])) {
    oc <- saved$results[[scenario]][[method]]
    key <- paste(scenario, method, sep = "_")

    patient <- oc$patient.data
    patient$score_raw <- settings$score_raw[patient$grade + 1]
    patient$scenario <- scenario
    patient$method <- method
    patients[[key]] <- patient

    # 每次试验一行。99 沿用旧函数约定，表示不推荐剂量。
    n <- rowSums(oc$N)
    trial <- data.frame(
      scenario = scenario, method = method, trial = seq_len(settings$ntrial),
      selected_dose = oc$dselect, stop_reason = oc$stop.reason,
      total_n = n, correct = as.numeric(oc$dselect == true_mtd),
      no_mtd = as.numeric(oc$dselect == 99),
      selected_overdose = as.numeric(oc$dselect %in% high_doses),
      overdose_fraction = rowSums(oc$N[, high_doses, drop = FALSE]) / n,
      mean_score = rowSums(oc$Y) * max(settings$score_raw) / n
    )
    high_grade_n <- tabulate(patient$trial[patient$grade >= settings$high_grade],
                             nbins = settings$ntrial)
    trial$high_grade_fraction <- high_grade_n / n
    trials[[key]] <- trial

    # 每次试验的每个剂量一行，包含未入组剂量。
    dose <- expand.grid(trial = seq_len(settings$ntrial), dose = seq_len(ncol(ptox)))
    dose$scenario <- scenario
    dose$method <- method
    dose$n <- as.vector(oc$N)
    dose$score_sum <- as.vector(oc$Y) * max(settings$score_raw)
    doses[[key]] <- dose

    # 每个指标一行；比例使用 0–1 尺度。
    for (metric in c("correct", "no_mtd", "selected_overdose", "total_n",
                     "overdose_fraction", "mean_score", "high_grade_fraction")) {
      values <- trial[[metric]]
      comparison[[paste(key, metric)]] <- data.frame(
        scenario = scenario, method = method, metric = metric,
        estimate = mean(values), mcse = sd(values) / sqrt(length(values))
      )
    }
  }
}

trials <- do.call(rbind, trials)
patients <- do.call(rbind, patients)
doses <- do.call(rbind, doses)
comparison <- do.call(rbind, comparison)

write.csv(trials, file.path(output_dir, "trials.csv"), row.names = FALSE)
write.csv(patients, file.path(output_dir, "patients.csv"), row.names = FALSE)
write.csv(doses, file.path(output_dir, "doses.csv"), row.names = FALSE)
write.csv(comparison, file.path(output_dir, "comparison.csv"), row.names = FALSE)

# 相同 trial 编号对应共享患者数据，按试验配对计算方法差异。
differences <- list()
method_pairs <- combn(unique(trials$method), 2, simplify = FALSE)
for (scenario in names(saved$results)) {
  for (pair in method_pairs) {
    a <- trials[trials$scenario == scenario & trials$method == pair[1], ]
    b <- trials[trials$scenario == scenario & trials$method == pair[2], ]
    paired <- merge(a, b, by = "trial", suffixes = c("_a", "_b"))
    for (metric in c("correct", "overdose_fraction", "high_grade_fraction")) {
      delta <- paired[[paste0(metric, "_a")]] - paired[[paste0(metric, "_b")]]
      key <- paste(scenario, pair[1], pair[2], metric)
      differences[[key]] <- data.frame(
        scenario = scenario, method_a = pair[1], method_b = pair[2],
        metric = metric, difference = mean(delta),
        mcse = sd(delta) / sqrt(length(delta))
      )
    }
  }
}
write.csv(do.call(rbind, differences), file.path(output_dir, "differences.csv"),
          row.names = FALSE)

print(comparison[comparison$metric == "correct", ], row.names = FALSE)

png(file.path(output_dir, "PCS.png"), width = 1200, height = 600)
par(mfrow = c(1, length(saved$results)), mar = c(5, 4, 3, 1))
for (scenario in names(saved$results)) {
  selected <- comparison[comparison$scenario == scenario & comparison$metric == "correct", ]
  barplot(selected$estimate * 100, names.arg = selected$method,
          ylim = c(0, 100), ylab = "Correct decision (%)", main = scenario,
          col = c("#5177A6", "#6FA58E", "#D0A25C"))
}
dev.off()
