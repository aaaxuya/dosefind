# 原包比较：全部直接调用 UnifiedDoseFinding 的模拟函数。
# 从项目根目录运行：source("R/原包比较.R", encoding = "UTF-8")
# 本文件运行后会执行模拟，并保存表格、原始输出和 PCS 图。
#
# 结局生成方式由原包决定：
# - CRM：按 ptox 抽取毒性等级，再转换为评分。
# - gBOIN：get_oc_gBOIN_continuous 按正态分布生成结局，
#   均值为 c_true[d]，标准差为 0.3 * d（原包 0.1.10）。
# 因此三种方法的真实均值与 MTD 相同，但结局分布不同；不共用 bank。
# 相同 seed 也不表示使用相同患者结局。

if (!requireNamespace("UnifiedDoseFinding", quietly = TRUE)) {
  stop('请先安装依赖：install.packages("UnifiedDoseFinding")')
}
if (!file.exists("DoseFindingResearch.Rproj")) {
  stop("请将工作目录设为 DoseFindingResearch 项目根目录后运行。")
}

# ---------- 控制参数 ----------
output_dir <- "results/original_package_comparison"
ntrial <- 4000L
seed <- 2026L
cohortsize <- 3L
ncohort <- 10L
startdose <- 1L
n.earlystop <- 100L
cutoff.eli <- 0.90  # 仅用于 CRM；原包 gBOIN 无此参数
mselection <- 1L   # RQ-CRM：1 = 模型选择，2 = 模型平均

score_raw <- c(0, 0.5, 1, 1.5)
target_raw <- 0.47
mu_1 <- 0.6 * target_raw
mu_2 <- 1.4 * target_raw

# 行对应毒性等级 0:3，列对应剂量 1:6。
ptox <- rbind(
  c(0.83, 0.75, 0.62, 0.51, 0.34, 0.19),
  c(0.12, 0.15, 0.18, 0.19, 0.16, 0.11),
  c(0.04, 0.07, 0.11, 0.14, 0.15, 0.11),
  c(0.01, 0.03, 0.09, 0.16, 0.35, 0.59)
)
p1 <- c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85)
p2 <- c(0.05, 0.10, 0.15, 0.25, 0.40, 0.65)
p3 <- c(0.20, 0.40, 0.60, 0.75, 0.85, 0.95)

true_mean <- as.vector(score_raw %*% ptox)
true_mtd <- which.min(abs(true_mean - target_raw))
truth <- data.frame(
  dose = seq_along(true_mean),
  true_mean_raw = true_mean,
  target_raw = target_raw,
  is_true_mtd = seq_along(true_mean) == true_mtd
)

package_version <- as.character(utils::packageVersion("UnifiedDoseFinding"))
if (package_version != "0.1.10") {
  warning("参考原包版本为 0.1.10，当前版本为 ", package_version)
}

# ---------- 直接调用原包模拟函数 ----------
# CRM 接受原始 score 和 target，归一化由原包内部处理。
message("模拟 RQ-CRM ...")
oc_rqcrm <- UnifiedDoseFinding::get_oc_RQ_CRM(
  ptox = ptox,
  skeletons = rbind(p1, p2, p3),
  target = target_raw,
  score = score_raw,
  cohortsize = cohortsize,
  ncohort = ncohort,
  n.earlystop = n.earlystop,
  start.dose = startdose,
  mselection = mselection,
  cutoff.eli = cutoff.eli,
  ntrial = ntrial,
  seed = seed
)

message("模拟 Quasi-CRM ...")
oc_qcrm <- UnifiedDoseFinding::get_oc_RQ_CRM(
  ptox = ptox,
  skeletons = p1,
  target = target_raw,
  score = score_raw,
  cohortsize = cohortsize,
  ncohort = ncohort,
  n.earlystop = n.earlystop,
  start.dose = startdose,
  mselection = 1L,
  cutoff.eli = cutoff.eli,
  ntrial = ntrial,
  seed = seed
)

message("模拟 gBOIN ...")
# 使用原包 gBOIN 模拟函数，不使用 QuasiBOIN 或自定义患者库适配器。
oc_gboin <- UnifiedDoseFinding::get_oc_gBOIN_continuous(
  target = target_raw,
  c_true = true_mean,
  ncohort = ncohort,
  cohortsize = cohortsize,
  n.earlystop = n.earlystop,
  ntrial = ntrial,
  mu_1 = mu_1,
  mu_2 = mu_2,
  startdose = startdose,
  seed = seed
)

# ---------- PCS 汇总 ----------
# selpercent 已是百分数；不推荐剂量计为错误，保留在 PCS 分母中。
summarise_original_oc <- function(oc, method) {
  if (is.null(oc$selpercent) || length(oc$selpercent) != ncol(ptox)) {
    stop(method, " 未返回预期的剂量选择比例。")
  }
  pcs <- unname(oc$selpercent[true_mtd])
  data.frame(
    method = method,
    true_mtd = true_mtd,
    ntrial = ntrial,
    PCS_percent = pcs,
    MCSE_percent = 100 * sqrt((pcs / 100) * (1 - pcs / 100) / ntrial),
    no_MTD_percent = max(0, 100 - sum(oc$selpercent)),
    mean_total_n = sum(oc$nptsdose)
  )
}
comparison <- rbind(
  summarise_original_oc(oc_rqcrm, "RQ-CRM"),
  summarise_original_oc(oc_qcrm, "Quasi-CRM"),
  summarise_original_oc(oc_gboin, "gBOIN")
)
print(truth, row.names = FALSE)
print(comparison, row.names = FALSE)

# ---------- 保存结果 ----------
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
utils::write.csv(comparison, file.path(output_dir, "comparison.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
utils::write.csv(truth, file.path(output_dir, "truth.csv"),
                 row.names = FALSE, fileEncoding = "UTF-8")
saveRDS(list(
  settings = list(
    ntrial = ntrial, seed = seed, cohortsize = cohortsize, ncohort = ncohort,
    startdose = startdose, n.earlystop = n.earlystop,
    cutoff.eli = cutoff.eli, mselection = mselection,
    score_raw = score_raw, target_raw = target_raw, mu_1 = mu_1, mu_2 = mu_2,
    ptox = ptox, skeletons_rqcrm = rbind(p1, p2, p3), skeleton_qcrm = p1,
    gboin_c_true = true_mean,
    outcome_generation = c(CRM = "ordinal grades", gBOIN = "normal, SD = 0.3 * dose")
  ),
  results = list("RQ-CRM" = oc_rqcrm, "Quasi-CRM" = oc_qcrm, "gBOIN" = oc_gboin),
  comparison = comparison, truth = truth,
  package_version = package_version, session_info = utils::sessionInfo()
), file.path(output_dir, "simulation.rds"))
capture.output(utils::sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))

# ---------- 柱上标注数值的 PCS 对比图 ----------
draw_original_pcs <- function() {
  positions <- graphics::barplot(
    comparison$PCS_percent,
    names.arg = comparison$method,
    ylim = c(0, 110),
    ylab = "PCS (%)",
    main = paste("Original package | True MTD = dose", true_mtd),
    col = c("#5177A6", "#6FA58E", "#D0A25C"),
    border = NA, yaxt = "n"
  )
  graphics::axis(2, at = seq(0, 100, 20), las = 1)
  graphics::text(
    x = as.vector(positions), y = comparison$PCS_percent + 3,
    labels = sprintf("%.2f%%", comparison$PCS_percent), font = 2
  )
  graphics::mtext("CRM: ordinal outcomes; gBOIN: normal outcomes", side = 1, line = 3, cex = 0.8)
}

save_original_pcs <- function(file, device) {
  if (device == "png") {
    grDevices::png(file, width = 1600, height = 1100, res = 180)
  } else {
    grDevices::pdf(file, width = 8, height = 5.5)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(6, 5, 4, 1))
  draw_original_pcs()
}
save_original_pcs(file.path(output_dir, "PCS.png"), "png")
save_original_pcs(file.path(output_dir, "PCS.pdf"), "pdf")
if (interactive()) draw_original_pcs()
message("结果已保存至：", output_dir)
