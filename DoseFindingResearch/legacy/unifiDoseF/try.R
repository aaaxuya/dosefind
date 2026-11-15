library(UnifiedDoseFinding)

score_raw <- c(0, 0.5, 1, 1.5)#毒性等级评分，从0级到三级对应
target_raw <- 0.47 #目标毒性等级评分
target_norm <- target_raw / max(score_raw) #标化

#三种不同的初始假设
p1 <- c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85)
p2 <- c(0.05, 0.10, 0.15, 0.25, 0.40, 0.65)
p3 <- c(0.20, 0.40, 0.60, 0.75, 0.85, 0.95)

#剂量-毒性发生概率
ptox <- rbind(
  c(0.83, 0.75, 0.62, 0.51, 0.34, 0.19),
  c(0.12, 0.15, 0.18, 0.19, 0.16, 0.11),
  c(0.04, 0.07, 0.11, 0.14, 0.15, 0.11),
  c(0.01, 0.03, 0.09, 0.16, 0.35, 0.59)
)

true_mean <- as.vector(score_raw %*% ptox)
true_mtd <- which.min(abs(true_mean - target_raw))
high_doses <- which(true_mean > target_raw + 0.20)  # 过毒剂量，教学阈值，自行定义过毒标准

ntrial <- 2000
seed <- 2026

# A：单 skeleton，Quasi-CRM
oc_qcrm <- get_oc_RQ_CRM(
  ptox = ptox, skeletons = p1,
  target = target_raw, score = score_raw,
  cohortsize = 3, ncohort = 10,
  cutoff.eli = 0.90,
  ntrial = ntrial, seed = seed
)

# B：多 skeleton，Robust-Quasi-CRM（模型选择）
oc_rqcrm <- get_oc_RQ_CRM(
  ptox = ptox, skeletons = rbind(p1, p2, p3),
  target = target_raw, score = score_raw,
  cohortsize = 3, ncohort = 10,
  mselection = 1, cutoff.eli = 0.90,
  ntrial = ntrial, seed = seed
)

# C：Quasi-BOIN，注意目标/分数标准化、概率矩阵转置
# 这个版本内部有 print(d)，仅捕获重复打印，保留结果对象
invisible(capture.output(
  oc_qboin <- get_oc_QuasiBOIN(
    target = target_norm,
    p.true = t(ptox),
    score = score_raw / max(score_raw),
    ncohort = 10, cohortsize = 3,
    cutoff.eli = 0.90,
    ntrial = ntrial, seed = seed
  )
))


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

print(round(comparison[-1], 2)) # 只打印数值部分
print(comparison)               # 完整表

# 一张简单的 PCS 对比图（仅 R 基础图形）
barplot(comparison$PCS_percent,
        names.arg = comparison$design,
        ylim = c(0, 100),
        ylab = "PCS (%)",
        main = paste("True MTD = dose", true_mtd),
        col = c("#5177A6", "#6FA58E", "#D0A25C"))

