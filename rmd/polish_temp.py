from pathlib import Path
import re
p = Path('rmd/uniDoseFind演示.rmd')
s = p.read_text(encoding='utf-8')
s = s.replace('title: "UnifiedDoseFinding 包演示"', 'title: "UnifiedDoseFinding：剂量探索方法与应用演示"\nsubtitle: "函数结构、数据准备与可复现示例"\nlang: zh-CN')
s = s.replace('    number_sections: true', '    number_sections: true\n    highlight: tango\n    css: report.css')
s = s.replace('knitr::opts_chunk$set(echo = TRUE, error = FALSE,warning = FALSE,\n                     fig.width = 8, fig.height = 4)', 'knitr::opts_chunk$set(echo = TRUE, error = FALSE, warning = FALSE,\n                     fig.width = 8, fig.height = 4, dpi = 144)\noptions(knitr.kable.NA = "—")')
s = re.sub(r'```\{=html\}\s*<!--.*?-->\s*```\s*', '', s, flags=re.S)
s = re.sub(r'<!-- TODO:.*?-->|<!-- TODO：.*?-->', '', s, flags=re.S)
s = s.replace('UnifiedDoseFinding 用于剂量探索与决策，里面有多个模型的R包实现。', 'UnifiedDoseFinding 为Ⅰ期剂量探索试验提供剂量决策与模拟工具，涵盖 Ivanova unified design、Quasi-CRM／Robust-Quasi-CRM 和广义 BOIN。除二元毒性结局外，也可使用有序毒性等级对应的评分、毒性负担和连续结局。\n\n本文以 RQ-CRM 为完整示例，再展示其他方法的输入与调用。各节均按“准备数据、下一批剂量、最终选择、模拟试验”展开。')
s = s.replace('本文依据本机安装的 **UnifiedDoseFinding 0.1.10** 的帮助文档与函数源码编写。', '> **演示范围**　基于 UnifiedDoseFinding 0.1.10。每个模拟示例运行 20 次，用于说明函数及输出；不据此判断方法优劣。文中剂量均指按升序排列的剂量编号。')
s = s.replace('包有18个函数，作用可以分为简单的三类。', '包公开导出 18 个函数，按用途分为三类，每类 6 个。')
s = s.replace('其中，`get_oc` 的 OC 指 operating characteristics，即操作特征。 它在假定场景下反复生成患者结局并执行试验。', '其中，OC 指 operating characteristics（操作特征）。`get_oc_*` 在指定的真实场景下反复生成患者结局并执行完整试验，汇总各剂量的选择百分比和平均入组人数。图中表示的是功能关系，模拟实现不一定直接调用对应的两个导出决策函数。')
s = s.replace('# RQ-CRM\n', '# RQ-CRM\n\nRobust-Quasi-CRM 在多条 skeleton 之间进行模型选择或模型平均，以处理剂量—毒性曲线的模型不确定性；Quasi-CRM 使用单条 skeleton。两者采用有序毒性评分构造准似然。[Yuan 等（2007）、Pan 等（2014）](#参考资料)\n', 1)
s = s.replace('这里沿用包帮助文档的四个评分与六个剂量示例。 `target = 0.47` 是目标毒性评分', '以下沿用包帮助文档的四个评分与六个剂量示例。`target = 0.47` 表示原始评分尺度上的目标均值。')
s = s.replace('score <- c(0, 0.5, 1, 1.5)#毒性等级评分', 'score <- c(0, 0.5, 1, 1.5)  # 各毒性等级对应的评分')
s = s.replace('`skeleton_mat` 表示分析时预先给定的剂量—毒性曲线假设。 本例n名患者的原始评分先除以最大评分 1.5，再按剂量累加得到 `y`：', '`skeleton_mat` 的每一行给出一条归一化平均毒性评分的初始参考曲线。例如，`p1[1] = 0.11` 对应原始评分均值 0.165，并不直接表示 DLT 发生率。患者评分先除以最大评分 1.5，再按剂量累加得到 `y`：')
s = s.replace('函数内部还会将 `target` 除以 `max(score)`，因此传入 `target` 时仍使用 0.47。', '函数内部将 `target` 除以 `max(score)`，得到归一化目标约 0.3133。因此，调用时传入原始目标 0.47，而 `y` 应预先归一化并累加。')
s = s.replace('包中的 `next_RQ_CRM()` 和 `select_mtd_RQ_CRM()` 接收参数 `skeleton`， 但函数体内使用了 `skeletons`。下面修改这个问题。不会修改已安装的包。', '在本机 0.1.10 版本中，`next_RQ_CRM()` 和 `select_mtd_RQ_CRM()` 的形参为 `skeleton`，函数体却引用 `skeletons`。以下在两个函数的本地副本中补充赋值，后续以 `_demo` 后缀调用；已安装的包不作修改。')
s = s.replace('`next_dose`模型推荐的下一组剂量。', '`next_dose` 是模型推荐的下一批剂量编号。')
s = s.replace('这里为了演示复用了同一组观察数据。实际使用时，应传入试验结束时的数据。 `next` 要考虑当前剂量和逐级调整，`select_mtd` 则选择估计均值最接近目标的剂量。', '此处复用当前数据，演示假定试验结束时的选择：第 `r selected_dose` 剂量。`next` 按当前剂量逐级调整，`select_mtd` 选择估计均值最接近目标的剂量。0.1.10 的这个最终选择函数未包含最低剂量过毒的停止检查，也未限定只能选择已治疗剂量，应与试验的停止规则一并解释。')
s = s.replace('这里用到了 Rmd 的行内代码：正文中的数值可以随计算结果更新。 ', '')
s = s.replace('本次仅模拟 20 次。', '`selection_percent` 对应 `selpercent`，`mean_n` 对应 `nptsdose`。下文结果表沿用这两个指标。')
# The existing overview is input guidance, not a method-performance comparison.
s = s.replace('# 其他方法概览', '# 其他方法的输入约定')
s = s.replace('将多条 skeleton 换为单条，RQ-CRM的简化', '使用单条 skeleton，与 RQ-CRM 共用函数')
s = s.replace('需说明 `eps` 的作用', '`eps` 控制升降剂量阈值')
s = s.replace('# Ivanova\n', '# Ivanova\n\nIvanova unified design 使用当前剂量下的标准化统计量进行升降决策；试验结束时通过保序估计选择接近目标的剂量。[Ivanova 与 Kim（2009）](#参考资料)\n')
s = s.replace('## 二元\n', '## 二元结局\n')
s = s.replace('## 连续\n', '## 连续结局\n')
s = s.replace('# gBOIN\n', '# gBOIN\n\ngBOIN 将观测均值与预设决策边界比较，给出升、降或维持剂量的决策。以下分别演示毒性负担和连续结局。[Mu 等（2019）](#参考资料)\n')
s = s.replace('## TB\n', '## 毒性负担（TB）\n')
s = s.replace('`p.saf` 和 `p.tox` 分别指定偏低、偏高的参考评分，函数据此计算升降剂量边界。', '`p.saf` 和 `p.tox` 分别指定偏低、偏高的参考评分，函数据此计算升降剂量边界。本文使用 `extrasafe = FALSE`；本版 `next_QuasiBOIN()` 的额外安全分支引用了未在形参中定义的 `offset`，开启该分支前需修正实现。')
s = s.replace('函数将当前剂量的平均 TB 与两个边界比较： 不高于 `(target + mu_1) / 2` 时升一级，不低于 `(target + mu_2) / 2` 时降一级。', '函数将当前剂量的平均 TB 与两个边界比较：不高于 `(target + mu_1) / 2` 时升一级，不低于 `(target + mu_2) / 2` 时降一级；在最高、最低剂量处不越界。当前均值为 `r round(y_tb[d_tb] / n_tb[d_tb], 3)`，下一批推荐第 `r next_dose_tb` 剂量。')
# Chinese table labels keep code field names intact for learning and reproducibility.
s = s.replace('knitr::kable(observed, digits = 3,', 'knitr::kable(observed, digits = 3,\n             col.names = c("剂量", "人数", "归一化累计评分", "平均原始评分"),')
s = s.replace('digits = 3, caption = "场景中的真实平均评分"', 'digits = 3, col.names = c("剂量", "真实平均评分"),\n             caption = "场景中的真实平均评分"')
s = s.replace('knitr::kable(oc_table, digits = 2,', 'knitr::kable(oc_table, digits = 2,\n             col.names = c("剂量", "真实平均评分", "选择百分比（%）", "平均入组人数"),')
s = re.sub(r'\), digits = ([23]), caption = "(Quasi-CRM|Quasi-BOIN|Ivanova|gBOIN)', r'), digits = \1,\n   col.names = c("剂量", "真实均值", "选择百分比（%）", "平均入组人数"),\n   caption = "\2', s)
# Give the binary result column its specific meaning.
s = s.replace('col.names = c("剂量", "真实均值", "选择百分比（%）", "平均入组人数"),\n   caption = "Ivanova 二元', 'col.names = c("剂量", "真实 DLT 率", "选择百分比（%）", "平均入组人数"),\n   caption = "Ivanova 二元')
s = s.replace('caption = "Quasi-BOIN 的模拟结果：true_mean 为归一化评分"', 'caption = "Quasi-BOIN 的模拟结果（均值为归一化评分）"')
start = s.index('# 资料与可复现信息')
s = s[:start] + '''# 参考资料

**包与实现**

- [CRAN：UnifiedDoseFinding](https://cran.r-project.org/package=UnifiedDoseFinding) 与 [源码镜像](https://github.com/cran/UnifiedDoseFinding)。本文参数说明、返回值及版本问题依据本机 0.1.10 帮助文档和实现核对。
- [DeepWiki：UnifiedDoseFinding](https://deepwiki.com/cran/UnifiedDoseFinding)，作为补充阅读入口。

**方法文献**

1. Yuan Z, Chappell R, Bailey H. The continual reassessment method for multiple toxicity grades: a Bayesian quasi-likelihood approach. *Biometrics*, 2007, 63: 173–179. [DOI](https://doi.org/10.1111/j.1541-0420.2006.00666.x)
2. Pan H, et al. The continual reassessment method for multiple toxicity grades: a Bayesian model selection approach. *PLOS ONE*, 2014, 9: e98147. [DOI](https://doi.org/10.1371/journal.pone.0098147)
3. Ivanova A, Kim SH. Dose finding for continuous and ordinal outcomes with a monotone objective function: a unified approach. *Biometrics*, 2009, 65: 307–315. [DOI](https://doi.org/10.1111/j.1541-0420.2008.01045.x)
4. Mu R, Yuan Y, Xu J, Mandrekar SJ, Yin J. gBOIN: a unified model-assisted phase I trial design accounting for toxicity grades, and binary or continuous end points. *Journal of the Royal Statistical Society: Series C*, 2019, 68: 289–308. [DOI](https://doi.org/10.1111/rssc.12263)

# 运行环境

各节按文档顺序执行，后续示例复用前文对象。模拟统一使用随机种子 100、每队列 3 人、最多 10 个队列、20 次重复；各方法的目标、结局分布和安全规则见相应代码。

<details class="session-info">
<summary>查看 R 与依赖包版本</summary>

```{r session-info, echo=FALSE}
sessionInfo()
```

</details>
'''
s = re.sub(r'\n{4,}', '\n\n\n', s)
p.write_text(s, encoding='utf-8')
