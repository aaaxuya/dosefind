# 沿用 legacy/生成模拟患者数据.R 的抽样顺序。
# 返回 bank[患者入组编号, 剂量编号, 试验编号]。
generate_bank <- function(ptox, nmax, ntrial, seed) {
  set.seed(seed)
  bank <- array(NA_integer_, dim = c(nmax, ncol(ptox), ntrial))

  for (trial in seq_len(ntrial)) {
    for (dose in seq_len(ncol(ptox))) {
      bank[, dose, trial] <- sample(
        x = seq_len(nrow(ptox)) - 1L,
        size = nmax,
        replace = TRUE,
        prob = ptox[, dose]
      )
    }
  }
  bank
}
