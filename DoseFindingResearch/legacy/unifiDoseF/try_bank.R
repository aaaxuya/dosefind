# 基于 try.R，使用同一份 bank 比较三种剂量探索方法。
# 可在 DoseFind 根目录或 unifiDoseF 项目目录运行本脚本。
script_dir <- if (file.exists("get_oc_RQ_CRM_bank.R")) "." else "unifiDoseF"

# 生成 bank，并加载修改后的模拟函数。
# 生成脚本同时定义真实毒性分布 ptox；随机种子在其中设置为 2026。
source(file.path(script_dir, "生成模拟患者数据.R"), encoding = "UTF-8")
source(file.path(script_dir, "get_oc_RQ_CRM_bank.R"), encoding = "UTF-8")
source(file.path(script_dir, "get_oc_QuasiBOIN_bank.R"), encoding = "UTF-8")

score_raw <- c(0, 0.5, 1, 1.5) # 毒性等级 0～3 对应的评分
target_raw <- 0.47
target_norm <- target_raw / max(score_raw)

# 三种初始假设，与 try.R 一致。
p1 <- c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85)
p2 <- c(0.05, 0.10, 0.15, 0.25, 0.40, 0.65)
p3 <- c(0.20, 0.40, 0.60, 0.75, 0.85, 0.95)

# 真实分布仅用于计算真实 MTD 和评价指标，患者结局由 bank 提供。
true_mean <- as.vector(score_raw %*% ptox)
true_mtd <- which.min(abs(true_mean - target_raw))
high_doses <- which(true_mean > target_raw + 0.20)

ntrial <- dim(bank)[3L] # 当前为 2000；调试时可改为 20
cohortsize <- 3
ncohort <- 10

# A：单 skeleton，Quasi-CRM。
oc_qcrm <- get_oc_RQ_CRM_bank(
  bank = bank, skeletons = p1,
  target = target_raw, score = score_raw,
  cohortsize = cohortsize, ncohort = ncohort,
  cutoff.eli = 0.90, ntrial = ntrial
)

# B：多 skeleton，Robust-Quasi-CRM（模型选择）。
oc_rqcrm <- get_oc_RQ_CRM_bank(
  bank = bank, skeletons = rbind(p1, p2, p3),
  target = target_raw, score = score_raw,
  cohortsize = cohortsize, ncohort = ncohort,
  mselection = 1, cutoff.eli = 0.90, ntrial = ntrial
)

# C：Quasi-BOIN，目标和评分使用标准化尺度。
# 不再传入 p.true、seed，也无需捕获原函数的重复打印。
oc_qboin <- get_oc_QuasiBOIN_bank(
  bank = bank, target = target_norm,
  score = score_raw / max(score_raw),
  ncohort = ncohort, cohortsize = cohortsize,
  cutoff.eli = 0.90, ntrial = ntrial
)

# 汇总指标与 try.R 一致。
summarise_oc <- function(x, design) {
  data.frame(
    design = design,
    PCS_percent = unname(x$selpercent[true_mtd]),
    no_MTD_percent = 100 - sum(x$selpercent),
    mean_total_n = sum(x$nptsdose),
    mean_n_at_true_MTD = unname(x$nptsdose[true_mtd]),
    mean_n_at_high_dose = sum(x$nptsdose[high_doses])
  )
}

comparison <- rbind(
  summarise_oc(oc_qcrm, "Quasi-CRM"),
  summarise_oc(oc_rqcrm, "Robust-Quasi-CRM"),
  summarise_oc(oc_qboin, "Quasi-BOIN")
)

print(round(comparison[-1], 2))
print(comparison)

# PCS 对比图。
barplot(comparison$PCS_percent,
        names.arg = comparison$design,
        ylim = c(0, 100),
        ylab = "PCS (%)",
        main = paste("True MTD = dose", true_mtd),
        col = c("#5177A6", "#6FA58E", "#D0A25C"))
