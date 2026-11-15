source("unifiDoseF/生成模拟患者数据.R", encoding = "UTF-8")
source("unifiDoseF/get_oc_RQ_CRM_bank.R", encoding = "UTF-8")
source("unifiDoseF/get_oc_QuasiBOIN_bank.R", encoding = "UTF-8")

score <- c(0, 0.5, 1, 1.5)
target <- 0.47

p1 <- c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85)
p2 <- c(0.05, 0.10, 0.15, 0.25, 0.40, 0.65)
p3 <- c(0.20, 0.40, 0.60, 0.75, 0.85, 0.95)

# 1. Quasi-CRM：传入一条 skeleton
oc_qcrm <- get_oc_RQ_CRM_bank(
  bank = bank,
  skeletons = p1,
  target = target,
  score = score,
  cutoff.eli = 0.90
)

# 2. Robust-Quasi-CRM：传入多条 skeleton
oc_rqcrm <- get_oc_RQ_CRM_bank(
  bank = bank,
  skeletons = rbind(p1, p2, p3),
  target = target,
  score = score,
  mselection = 1,  # 1：模型选择；2：模型平均
  cutoff.eli = 0.90
)

# 3. Quasi-BOIN：评分和目标都需要标准化
oc_qboin <- get_oc_QuasiBOIN_bank(
  bank = bank,
  target = target / max(score),
  score = score / max(score),
  cutoff.eli = 0.90
)