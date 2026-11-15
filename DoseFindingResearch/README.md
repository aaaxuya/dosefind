# DoseFindingResearch

打开 DoseFindingResearch.Rproj，从项目根目录依次运行：

```r
source("scripts/01_generate.R", encoding = "UTF-8")
source("scripts/02_run.R", encoding = "UTF-8")
source("scripts/03_analyse.R", encoding = "UTF-8")
```

## 代码

- config/parameters.R：修改场景、评分、目标、skeleton、样本量、重复次数和输出目录。
- R/generate_bank.R：从 legacy 提取的患者数据生成函数。
- scripts/01_generate.R：生成共享患者库，连同参数保存为 input.rds。
- scripts/02_run.R：照着 legacy/try_bank.R 直接调用三个旧函数，保存 results.rds。
- scripts/03_analyse.R：整理患者、试验与剂量表，汇总指标、配对差异并画图。

没有增加方法注册、运行引擎或配置校验框架。旧函数自身的检查保留在 legacy 中。

## 保存的数据

默认结果放在 results/mvp/：

| 文件 | 内容 |
|---|---|
| input.rds | 实际使用的参数、场景和全部患者库 |
| results.rds | 参数和三个旧函数的完整原始输出 |
| trials.csv | 一次试验一行：推荐、停止原因、人数、正确决定、过毒分配、平均评分等 |
| patients.csv | 一名患者一行；score 为归一化分数，score_raw 为原始分数 |
| doses.csv | 一次试验的一个剂量一行；包含未入组剂量 |
| comparison.csv | 每场景、方法、指标的平均值和蒙特卡洛标准误 |
| differences.csv | 配对方法差异及其标准误，方向为 method_a − method_b |
| PCS.png | 各场景正确决策率图 |

selected_dose=99 表示不推荐剂量，沿用 legacy。mcse 为试验指标的样本标准差除以重复次数的平方根。各类比例按每次试验计算后取平均。

演示中，过毒定义为真实平均评分 > 目标 + overdose_margin；通常以均值最接近目标的剂量为真值（并列取第一个，沿用 legacy）；全部剂量过毒时以不推荐为正确决定。当前数值仅用于跑通程序。

## 使用约定

修改参数后，从 01 重新运行；02 和 03 使用已保存的参数。运行会覆盖 output_dir 中同名文件。需要保留不同实验时，在 parameters.R 中更换 output_dir。当前失败直接报错，修正后重新运行。

先实现 legacy 已有的 QCRM、RQCRM、QBOIN。其他方法与连续结局在后续研究需要时添加。

legacy/ 保留原代码；archive/framework_v1/ 存放上一版框架和结果，日常运行无需读取。
