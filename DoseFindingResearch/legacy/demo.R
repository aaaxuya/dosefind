
library(UnifiedDoseFinding)

# 目标毒性评分
target <- 0.47

# 四个毒性等级对应的权重
score <- c(0, 0.5, 1, 1.5)

# 六个剂量的初始毒性假设
p1 <- c(0.11, 0.25, 0.40, 0.55, 0.75, 0.85)

# 每个剂量已经治疗的人数
n <- c(3, 3, 3, 9, 3, 0)

# 各剂量的累计等效毒性评分
y <- c(0, 0, 1, 1.333333, 3, 0)

# 复制原函数
next_RQ_CRM_fixed <- UnifiedDoseFinding::next_RQ_CRM

# 修复函数内部的变量名问题
old_body <- body(next_RQ_CRM_fixed)

body(next_RQ_CRM_fixed) <- bquote({
  skeletons <- skeleton
  .(old_body)
})

# 使用修复后的函数
result <- next_RQ_CRM_fixed(
  target = target,
  n = n,
  y = y,
  dose.curr = 5,
  score = score,
  skeleton = p1
)

print(result)

y2 <- y
y2[5] <- 0

next_RQ_CRM_fixed(
  target = target,
  n = n,
  y = y2,
  dose.curr = 5,
  score = score,
  skeleton = p1
)