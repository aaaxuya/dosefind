config <- list(
  ptox = ptox,
  score = c(0, 0.5, 1, 1.5),
  target = 0.47,
  ntrial = 2000,
  nmax = 30,
  cohortsize = 3,
  startdose = 1
)

ext_dose(method, n, y, current_dose, config)#输出下一组剂量的统一接口？

tox_data[试验编号, 患者编号, 剂量编号]# 患者编号



#生成模拟患者的毒性数据

# ==============================
# 1. 设置真实毒性分布
# ==============================

ptox <- rbind(
  c(0.83, 0.75, 0.62, 0.51, 0.34, 0.19),
  c(0.12, 0.15, 0.18, 0.19, 0.16, 0.11),
  c(0.04, 0.07, 0.11, 0.14, 0.15, 0.11),
  c(0.01, 0.03, 0.09, 0.16, 0.35, 0.59)
)


# ==============================
# 2. 定义毒性数据生成函数
# ==============================

generate_toxicity <- function(dose, n) {
  sample(
    x = 0:3,
    size = n,
    replace = TRUE,
    prob = ptox[, dose]
  )
}


# ==============================
# 3. 设置模拟参数
# ==============================

ntrial <- 2000      # 模拟2000次独立临床试验
nmax <- 30          # 每次试验最多30名患者
ndose <- 6          # 6个剂量水平

set.seed(2026)      # 保证结果可重复


# ==============================
# 4. 创建三维数组
# ==============================

bank <- array(
  NA_integer_,
  dim = c(nmax, ndose, ntrial)
)


# ==============================
# 5. 生成2000次模拟试验的患者数据
# ==============================

for (k in 1:ntrial) {
  
  results <- list()
  
  for (dose in 1:ndose) {
    results[[dose]] <- generate_toxicity(dose, nmax)
  }
  
  final <- do.call(cbind, results)
  
  bank[, , k] <- final
  
}















