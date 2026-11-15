library(UnifiedDoseFinding)

# 目标毒性评分
target <- 0.47

# 毒性权重
score <- c(0, 0.5, 1, 1.5)

# 六个剂量的已有患者数据
n <- c(3, 3, 3, 9, 3, 0)
y <- c(0, 0, 1, 1.333333, 3, 0)

# 当前剂量水平
d <- 5

# Quasi-BOIN 推荐下一组剂量
result_boin <- next_QuasiBOIN(
  target = target / max(score),
  n = n,
  y = y,
  d = d
)

print(result_boin)

# 设置四种毒性情况
test_y5 <- c(0, 1, 2, 3)

# 分别计算下一组推荐剂量
results <- sapply(test_y5, function(value) {

  y_test <- y
  y_test[5] <- value

  next_QuasiBOIN(
    target = target / max(score),
    n = n,
    y = y_test,
    d = 5
  )
})

# 汇总结果
data.frame(
  Toxicity_Sum = test_y5,
  Toxicity_Mean = test_y5 / 3,
  Next_Dose = results
)
