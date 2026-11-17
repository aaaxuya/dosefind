# DoseFindingResearch

比较 RQ-CRM、Quasi-CRM、gBOIN 的 PCS。主代码在 `R/`，控制参数和运行入口在 `scripts/`，新结果输出到 `results/pcs_comparison/`。本次仅交付代码，未执行模拟；`results/mvp/` 中的图和数值为旧结果。

## 使用

打开 `DoseFindingResearch.Rproj`，工作目录设为项目根目录。先安装依赖：

```r
install.packages("UnifiedDoseFinding")
```

实现参考 UnifiedDoseFinding 0.1.10，运行时记录实际包版本。绘图仅用 R 基础图形。

修改 `scripts/00_parameters.R`，然后运行：

```r
source("scripts/run_all.R", encoding = "UTF-8")
```

或在项目根目录命令行运行 `Rscript scripts/run_all.R`。也可分步运行：

```r
source("scripts/01_generate.R", encoding = "UTF-8")
source("scripts/02_run.R", encoding = "UTF-8")
source("scripts/03_analyse.R", encoding = "UTF-8")
```

修改参数后从 01 重新运行。02 和 03 使用保存的参数；当前参数文件的 `output_dir` 仅用于定位输入文件。同名输出会被覆盖，需要保留不同实验时请更换 `output_dir`。

## 参数与方法

- 默认真实毒性概率矩阵沿用 `legacy/unifiDoseF/生成模拟患者数据.R`，行对应毒性等级 0–3，列对应剂量 1–6。
- 2000 次试验；每组 3 人，最多 10 组（30 人）；起始剂量 1；单剂量人数提前停止阈值 100；种子 2026。
- 原始评分 `c(0, 0.5, 1, 1.5)`，目标评分 `0.47`。CRM 方法内部归一化评分和目标；gBOIN 使用原始评分与目标 `0.47`，与原包连续评分接口一致。
- Quasi-CRM 使用旧代码 p1 单 skeleton；RQ-CRM 使用 p1、p2、p3，默认模型选择（`mselection = 1`），支持模型平均（2）。幂模型及先验沿用旧实现。
- gBOIN 按原包 `get_oc_gBOIN_continuous` 的试验流程适配患者库，分配和最终选择直接调用 `UnifiedDoseFinding::next_gBOIN_continuous` 与 `UnifiedDoseFinding::select_mtd_gBOIN_continuous`。只把原模拟函数中的正态结局抽样替换为患者库毒性等级对应的原始评分，不使用 QuasiBOIN。默认 `mu_1 = 0.6 * target = 0.282`、`mu_2 = 1.4 * target = 0.658`，升降剂量边界分别为 `(target + mu_1)/2 = 0.376` 和 `(target + mu_2)/2 = 0.564`。边界含等号；每次最多移动一级，最终选择仅考虑已治疗剂量。
- `cutoff.eli = 0.90` 仅用于两种 CRM。原包 gBOIN 没有 Beta 后验剔除或 `extrasafe` 规则，适配器也不添加。三种方法保留各自停止规则；gBOIN 按原包在当前剂量人数达到 `n.earlystop` 后停止，仍调用原包函数作最终选择。

患者库维度为 `[入组序号, 剂量, 试验]`，三种方法读取同一份库。不同剂量的潜在毒性独立生成；按分配剂量读取该入组患者的毒性，真实分布不进入方法决策。生成函数统一使用 `nmax`、`ntrial`，修正旧生成脚本中混用 `n_max`、`n_trial` 的问题。

真实 MTD 沿用 `try_bank.R`：平均原始评分最接近目标的剂量，距离并列取最低剂量。默认真实均值为 `c(0.115, 0.19, 0.335, 0.475, 0.755, 1.05)`，真实 MTD 为剂量 4。PCS 为推荐真实 MTD 的次数除以全部试验次数；推荐值 99 表示不推荐剂量，计为错误，不从分母剔除。此定义始终指定一个真实剂量，即使自定义场景全部剂量高于目标，也不将“不推荐”定义为正确。

## 代码

| 文件 | 用途 |
|---|---|
| `scripts/00_parameters.R` | 全部参数、skeleton、场景及输出位置 |
| `scripts/run_all.R` | 完整流程入口 |
| `R/generate_bank.R` | 参数校验及患者库生成 |
| `R/get_oc_RQ_CRM_bank.R` | 单/多 skeleton CRM 模拟，自 legacy 复制 |
| `R/get_oc_gBOIN_bank.R` | 原包 gBOIN 患者库适配器，直接调用原包分配与选择接口 |
| `R/run_pcs_comparison.R` | 用共用患者库调用三种方法 |
| `R/analyse_pcs.R` | PCS 汇总、表格导出、带数值标注的图 |

运行无需 source `legacy/`。CRM 方法文件保留原始来源与 GPL-2 注释；gBOIN 实现不依赖 legacy 的 QuasiBOIN。`config/parameters.R` 为旧配置，新流程仅读取 `scripts/00_parameters.R`。

## 输出

| 文件 | 内容 |
|---|---|
| `input.rds` | 实际参数、患者库、R 版本与 RNG 类型 |
| `simulation.rds` | 三种方法完整输出，包括逐试验 N、Y、推荐与停止原因，以及参数和包版本 |
| `comparison.csv` | 每场景每方法的 PCS 百分数、正确次数、MCSE、不推荐比例、平均样本量 |
| `trials.csv` | 逐试验推荐、是否正确、样本量、停止原因 |
| `truth.csv` | 各剂量真实平均评分与真实 MTD |
| `PCS.png`、`PCS.pdf` | 三方法 PCS 对比图，柱上标注两位小数百分数；多场景时分面 |
| `sessionInfo.txt` | 运行环境 |

MCSE 单位为百分点，计算为 `100 * sqrt(PCS * (1 - PCS) / ntrial)`，公式内 PCS 为 0–1 比例。`keep.patient.data = TRUE` 时逐患者记录额外保存在 `simulation.rds`，默认关闭以减少输出体积。

## 参考

患者库及 CRM 参数参考本地 `legacy/unifiDoseF/生成模拟患者数据.R`、`get_oc_RQ_CRM_bank.R`、`try_bank.R`。gBOIN 依据本地安装的 UnifiedDoseFinding 原包 `get_oc_gBOIN_continuous`、`next_gBOIN_continuous`、`select_mtd_gBOIN_continuous` 源码及 [官方手册](https://cloud.r-project.org/web/packages/UnifiedDoseFinding/UnifiedDoseFinding.pdf)，不参考 legacy 的 QuasiBOIN。

注意：原包最终选择函数包含固定的 0.05/0.1 平滑常数，所以 gBOIN 保留原始评分尺度。simulation.rds 中 gBOIN 的 Y 和患者 score 为原始评分，CRM 的 Y 和患者 score 为归一化评分；PCS 均按同一个原始真实 MTD 计算。更新本次代码后，应从 01 重新生成输入，避免使用上一版保存的参数。
