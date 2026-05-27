# CMS 闪烁研究 — R 数据分析规格（喂给 Claude Code）

> 这是一份**给 AI 编码助手（Claude Code）执行的工作规格**。请严格按本文件构建一套可复现的 R 分析管线。
> 语言：R。所有输出（清洗标记表、统计结果、图表）写入 `output/` 子目录。
> **最高原则：不删除任何数据、不做数据清洗，只做"标注"。** 这是研究者导师的明确要求，任何步骤都不得 listwise 删除被试或 trial。

---

## 0. 角色与总目标

你是一名严谨的实验数据科学家。任务：把分散的实验数据合并成分析长表，**先诊断 Two-way Repeated-Measures ANOVA 的前提假设是否被满足，再完整跑通 RM-ANOVA**，覆盖行为(TTC)、主观评分、眼动三大因变量，并产出论文级图表。

执行哲学：
1. **保留全部观测**。缺失/异常用"标记列 + 模型方法"处理，绝不删行删人。
2. **诊断在前，检验在后（导师明确要求，两者都要做）**。导师要求：先不清洗数据，直接看原始数据是否满足 Two-way RM-ANOVA 的前提，**再**完整跑通 RM-ANOVA。因此每个因变量都必须先输出正态性、球形度、离群点诊断（脚本 04），用户/导师确认后再进入 ANOVA（脚本 05–07）。诊断与完整检验**缺一不可**，且顺序固定为诊断→检验。
3. **可复现**。固定随机种子；所有结果存成 csv + 图片；脚本可一键重跑。
4. **遇到不确定先停下报告**，不要擅自猜测文件名编码或删数据。

---

## 1. 实验设计（分析的事实基础）

| 项目 | 内容 |
|---|---|
| 设计 | 被试内（within-subject），25 名被试 |
| 每人 trial 数 | 30 = 10 条件 × 3 场景 |
| 自变量1：闪烁频率 frequency | 0 Hz(稳定)、8.33 Hz、12.5 Hz、25 Hz |
| 自变量2：调制深度 modulation_depth | 40%(F1)、60%(F2)、80%(F3)；**仅 9 个闪烁条件有，稳定条件 0Hz 无调制深度 → NA** |
| 主行为因变量 | **TTC = 19 − paddle_time_s**（被试按拨片时刻）。TTC 越小=越冒险，越大=越保守 |
| 主观因变量（每 trial 4 题，7点Likert） | Q1 视觉舒适度 / Q2 心理需求 / Q3 努力 / Q4 决策确定性 |
| 眼动因变量 | dwell_time_cms_ms, dwell_ratio_cms, transition_count, fixation_count_cms/road, fixation_duration_cms/road_mean_ms, first_fixation_cms_time_ms, pupil_diameter_*（详见第4节定义） |
| 场景 scene | 3 个场景是**重复测量**，非自变量。默认对同一条件的 3 场景取均值；另做 scene 敏感性分析 |

### 研究问题与假设
- **SRQ1 / H1**：闪烁 vs. 稳定(0Hz)如何影响换道决策；预期中频(12.5Hz)偏离最大。
- **SRQ2 / H2**：频率与深度如何影响视觉搜索与认知负荷；预期频率↑深度↑ → 搜索努力↑、负荷↑。
- **SRQ3 / H3**：频率 × 深度交互；预期高深度放大频率效应。

---

## 2. 已知数据陷阱（务必按此处理，不得自行删数据）

1. **结构性缺失：稳定条件无调制深度。** 0Hz 不能进入 4×3 完整析因表（会产生空单元格）。→ 采用**两步分析结构**：
   - 第一步（SRQ1）：把 frequency 作为 **4 水平**单因素（0/8.33/12.5/25），跑单因素 RM-ANOVA + 对 0Hz 的计划对比。
   - 第二步（SRQ3）：**仅在 9 个闪烁条件**上跑 **Two-way RM-ANOVA**（3 frequency × 3 depth），含交互项。
2. **第 16 个 trial 主观评分缺失。** 部分被试在休息窗口误点继续，看完呈现顺序第 16 个视频后才休息，漏填该 trial 的 4 题评分；但 LSG/paddle 通常仍记录。
   - 缺失锚定在**呈现顺序 video_index == 15（0-based）或第16位**，因为呈现是随机化的，每人对应的具体 condition 不同。
   - 处理：**保留该 trial 的 TTC 与眼动**，仅在主观分析按缺失处理；标记 `flag_missing_rating=TRUE`。不删被试。
3. **P09 无驾照、P15 色盲。** 不剔除。加被试级标记 `is_P09_nolicense` / `is_P15_colorblind`，主分析含全体，另做剔除二人的敏感性分析。
4. **first_fixation_cms_time_ms == -1** 表示整段未注视 CMS = 结构性缺失，**不可当数值求均值**。两段式处理（见 4.3）。
5. **TTC 反向指标**：解读时统一说明"小=冒险/晚按，大=保守/早按"。

---

## 3. 输入数据与文件名解析

> 用户后续会把数据文件夹放进项目。**先用一个脚本探测目录结构，把发现的文件清单和字段名打印出来给用户确认，再继续。**

### 3.1 输入布局（已确认：均为"每人一个文件"）
> 用户已确认：rating_lsg 与 eyetracking **都是每名被试一个独立文件**。脚本据此设计为"逐文件读入 → 从文件名提取 participant_id → 纵向拼接（bind_rows）→ 按 participant_id 横向连接"。**不要再写汇总表分支，但要稳健处理文件数不齐、命名不规整的情况。**

- `data/rating_lsg/`：**每人一个文件**（如 `P01.txt` / `P01.csv` / `P01_*.txt` 等，共约 25 个）。
  - 每个文件含该被试 30 个 trial 的记录；每条记录含：seqname/video_name、被试估计的最后安全换道时刻（**第一串长数字 = paddle_time_s**）、其后 **4 位数字 = Q1..Q4 评分**。
  - **participant_id 从文件名提取**（用正则抓 `P\d+`，如 P01–P25），不要依赖文件内是否有 ID 列。
  - 读入时**对每种实际遇到的分隔符/编码都打印一次样例**，确认 paddle_time 和 4 个评分被正确切分（这是高风险点，见 3.3）。
- `data/eyetracking/`：**每人一个文件**（约 25 个），字段名见第 4 节（dwell_*、fixation_*、transition_count、first_fixation_cms_time_ms、pupil_*、valid_ratio、eyes_not_found_ratio、video_index、video_name、participant 等）。
  - 同样**优先从文件名提取 participant_id**；若文件内已有 participant 列，则交叉核对两者一致，不一致时停下报告。
- `data/questionnaires/`：SSQ 前测、SSQ 后测、background、post-experiment、vision test（Google form 导出，已整理；通常是汇总表，每行一名被试）。

### 3.1b 逐文件读入的稳健性要求
- 用 `list.files(pattern=...)` 列出全部文件；**先打印文件数与文件名清单**，确认是否 25 个、命名是否规整。文件数 ≠ 25 时打印缺哪些 PXX，但**不补不删**，继续用现有文件。
- 逐文件读入后立刻给每行加 `participant_id` 与 `source_file` 两列，再 `bind_rows`。
- rating_lsg 拼接后断言总行数应 ≈ 25×30=750；eyetracking 拼接后断言 ≈ 750（眼动可能因 trial 缺失略少）。偏差只报告不修。
- rating_lsg 与 eyetracking 两张长表，按 `(participant_id, video_name)` 为主键连接；若 video_name 命名风格不一致，退而用 `(participant_id, video_index)`，并打印两种键的匹配率供用户判断。

### 3.2 Rating&LSG 文件内字段切分（每人一文件的高风险点）
每条记录形如：`seqname  <一串长数字>  <数字><数字><数字><数字>`。
- **第一串长数字 = paddle_time_s**（被试按拨片、即最后安全换道时刻）。注意单位：确认它是秒还是毫秒——若数值远大于 19（如几千），很可能是毫秒或帧，需要换算后再算 TTC。**先打印 paddle_time 的数值范围让用户确认单位。**
- **其后 4 位 = Q1..Q4**，每个取值应在 1–7。读入后**立即断言 4 个评分都在 [1,7]**，越界则打印该行原文供用户核对切分是否错位（不删，只报告）。
- 若 4 个评分是"连在一起的 4 位数字"（如 `5746`）而非分开的列，需要按位拆分；**先对 1 个文件验证拆分逻辑**再套用。
- 第 16 个 trial（呈现顺序）可能整行缺 4 个评分但有 paddle_time——这是已知缺失，标记即可。

### 3.3 文件名编码解析（高风险步骤——先验证再批量）
视频文件名编码了 scene、frequency、modulation_depth。
- **第一步：写一个解析函数把 seqname → (scene, frequency, modulation_depth)。**
- **第二步：先对 1–2 名被试打印解析结果表，让用户人工核对** F1=40% / F2=60% / F3=80% 的映射正确、0Hz 被正确识别为稳定条件、3 个 scene 被正确区分。**用户确认后再批量套用全体。**
- 若文件名规则不明确，**停下来把样例文件名列给用户，问清楚编码规则**，不要猜。

---

## 4. 眼动指标定义（用于分析与解读）

| 指标 | 字段 | 用途 / 解读 |
|---|---|---|
| CMS 停留时间/占比 | dwell_time_cms_ms / dwell_ratio_cms | 对 CMS 的注意分配。**优先用比例 dwell_ratio_cms**（不同 trial 有效时长不同） |
| CMS↔Road 转移次数 | transition_count | 视觉扫描频率/搜索努力（计数型） |
| CMS/Road 注视次数 | fixation_count_cms / fixation_count_road | 注视频次（计数型） |
| CMS/Road 平均注视时长 | fixation_duration_cms_mean_ms / fixation_duration_road_mean_ms | CMS 注视越长→处理越费力 |
| 首次注视 CMS 时间 | first_fixation_cms_time_ms | 闪烁吸引还是延迟初始注意。**-1=未注视，两段式处理** |
| 瞳孔直径 | pupil_diameter_mean/std/cms/road | 认知负荷代理，**但受亮度干扰**，仅作辅助证据，CMS vs road 直接比要加 caveat |
| 数据质量 | valid_ratio, eyes_not_found_ratio, clock_offset_s | 作为质量协变量/分层依据，**不用于删除** |

### 4.3 first_fixation 两段式
- 第一段：对每条记录构造 `cms_fixated = (first_fixation_cms_time_ms != -1)`，用逻辑回归/比例分析看"是否注视过 CMS"随条件变化。
- 第二段：仅对 `cms_fixated==TRUE` 的记录分析 first_fixation 时间。

---

## 5. 分析管线（按脚本顺序组织）

把管线拆成**编号 R 脚本**，每个脚本独立可跑、有清晰输入输出。建议结构：

```
project/
├── data/                  # 用户提供（只读）
├── R/
│   ├── 00_setup.R         # 加载包、定义路径、固定种子、helper 函数
│   ├── 01_ingest.R        # 探测目录 + 读入 + 文件名解析 + 合并长表
│   ├── 02_flag.R          # 打质量标记列（不删数据）
│   ├── 03_describe.R      # 描述统计 + 数据概览
│   ├── 04_assumptions.R   # ★ ANOVA 前提诊断（导师要先看这个）
│   ├── 05_anova_ttc.R     # TTC 两步走 RM-ANOVA
│   ├── 06_anova_ratings.R # 4 项主观评分 RM-ANOVA
│   ├── 07_anova_eye.R     # 眼动指标 RM-ANOVA
│   ├── 08_ssq.R           # SSQ 前后配对检验
│   ├── 09_sensitivity.R   # 敏感性分析（P09/P15、scene、缺失对照）
│   └── 10_plots.R         # 汇总所有图表
├── output/
│   ├── tables/            # 所有 csv 结果
│   ├── figures/           # 所有图（png + 可选 pdf）
│   └── master_long.csv    # 合并后的主分析长表
└── run_all.R              # source 所有脚本一键重跑
```

### 5.1 `00_setup.R`
- 包：`tidyverse, afex, emmeans, rstatix, ggpubr, performance, car, broom, broom.mixed, lme4, lmerTest, ordinal, patchwork, here, janitor`。开头检测缺失包并 `install.packages` 安装。
- `set.seed(2026)`。
- 定义因子顺序：frequency = c("0","8.33","12.5","25")；modulation_depth = c("40","60","80")。
- 定义 helper：保存 csv、保存图（统一 300 dpi、宽高、主题 `theme_minimal(base_size=12)`）。

### 5.2 `01_ingest.R`（探测优先；每人一文件）
1. 探测 `data/` 下实际目录与文件，**打印清单 + 文件数 + 每个文件的列名 + 前几行**，写入 `output/tables/00_data_inventory.csv`。
2. **逐文件读入**（rating_lsg 与 eyetracking 均为每人一文件）：用 `list.files()` 取全部文件 → 每个文件读入后从文件名正则提取 `participant_id`（`P\d+`）并加 `source_file` 列 → `bind_rows` 纵向拼接。文件数≠25 时打印缺哪些 PXX，不补不删。
3. 按 3.2 切分 Rating&LSG 字段：先打印 paddle_time 数值范围确认单位、断言 4 评分∈[1,7]，越界打印原文。
4. 实现 3.3 的文件名解析函数；**先对前 2 名被试输出解析对照表 `output/tables/01_filename_decode_check.csv` 并在控制台醒目提示用户核对**。
5. 计算 `TTC_s = 19 - paddle_time_s`（先确认 paddle_time 单位为秒）。
5. 合并 rating_lsg + eyetracking → `master_long.csv`（每行一个 participant×trial）。合并后断言行数应=25×30=750，否则打印缺口明细，**不补不删，只报告**。

### 5.3 `02_flag.R`（标记，不删）
新增列（全部 TRUE/FALSE 或比例，均保留在数据里）：
- `flag_no_response`（paddle/TTC 缺失）
- `flag_missing_rating`（4 题评分缺失；并交叉验证是否多落在 video_index 第16位）
- `flag_low_eye_quality`（valid_ratio < 70%，阈值设为可调参数）
- `flag_extreme_ttc`（TTC 超出 mean±3SD 或越界 [<0 或 >19]；按被试内分布判定）
- `is_P09_nolicense`, `is_P15_colorblind`
- 输出标记汇总 `output/tables/02_flag_summary.csv`：每类标记的计数、占比、涉及哪些被试/trial。

### 5.4 `03_describe.R`
- 按 10 条件输出 TTC/4评分/各眼动指标的 n, mean, sd, median, IQR, missing_n → `output/tables/03_descriptives_*.csv`。
- 输出被试特征表（年龄/性别/驾龄/视力/色盲），标注 P09/P15。

### 5.5 `04_assumptions.R` ★导师最关心
对**每个主因变量**（TTC、Q1–Q4、关键眼动指标）在分析用的"被试×条件"聚合数据上做：
1. **聚合**：每名被试每条件用其可用 trial（跨 3 场景）取均值，得到平衡的"被试×条件"矩阵（缺失单元如实留 NA，不强行补）。
2. **正态性**：对每个条件的残差/单元做 Shapiro–Wilk；输出 QQ 图；并对 ANOVA 残差整体做正态性检验。
3. **球形度**：Two-way 设计用 `afex::aov_ez` / `rstatix::anova_test` 自带的 Mauchly 检验，输出 Mauchly W、p、以及 GG / HF epsilon。
4. **离群点**：`rstatix::identify_outliers`（标记 is.outlier / is.extreme），**只标记不删**。
5. **方差齐性**（如适用）：Levene。
6. 把所有诊断结果汇总成一张"前提是否满足"判定表 `output/tables/04_assumption_checks.csv`，每个因变量一行，列出：正态(通过/违反)、球形度(通过/违反→需GG校正)、极端离群点数。
7. 在控制台和一个 `output/tables/04_assumption_summary.txt` 里用自然语言总结："TTC 在 X 条件下偏离正态；球形度违反，建议对频率主效应用 Greenhouse–Geisser 校正"等。

### 5.6 `05_anova_ttc.R`（两步走）
- **第一步 SRQ1**：单因素 RM-ANOVA，frequency 4 水平。`afex::aov_ez(id="participant", dv="TTC", within="frequency")`。GG 校正。计划对比：每个闪烁频率 vs 0Hz（`emmeans` + Holm 校正）。
- **第二步 SRQ3**：**Two-way RM-ANOVA**，仅 9 闪烁条件，`within = c("frequency","modulation_depth")`，含交互。GG 校正。
- 显著则 `emmeans` 做事后成对比较，**Holm–Bonferroni 校正**。
- 报告偏 η²、F、df、p、95%CI → `output/tables/05_anova_ttc_*.csv`。
- **稳健性平行**：同时跑一个 LMM `TTC ~ frequency*modulation_depth + (1|participant) + (1|scene)`（在 9 闪烁条件上），结果并列保存，证明对缺失更友好的方法结论是否一致。

### 5.7 `06_anova_ratings.R`
- 对 Q1、Q2、Q3、Q4 各重复 5.6 的两步走。
- 先检验 Q2 与 Q3（NASA-TLX 两项）相关/一致性（Spearman + Cronbach α），若高度一致，额外构造 `cognitive_load = mean(Q2,Q3)` 复合分并分析。
- **稳健性**：因 Likert 有序，额外用 `ordinal::clmm`（cumulative link mixed model）跑一遍作对照。
- 主观分析中 `flag_missing_rating` 的 trial 自然为 NA，afex 聚合到被试×条件均值时用可用场景，LMM/CLMM 用可用观测——**不删被试**。

### 5.8 `07_anova_eye.R`
- 对 dwell_ratio_cms、transition_count、fixation_count_cms、fixation_duration_cms_mean_ms 等各跑两步走 RM-ANOVA。
- 计数型指标（transition_count, fixation_count_*）额外用泊松/负二项 GLMM 作稳健性对照。
- `first_fixation_cms_time_ms` 按 4.3 两段式处理，**绝不把 -1 当数值**。
- 瞳孔指标分析时在输出里加亮度 caveat 文字。
- 质量：把 valid_ratio 作为协变量纳入一个对照模型，或做 `flag_low_eye_quality` 分层敏感性。

### 5.9 `08_ssq.R`
- 按 Kennedy(1993) 加权公式计算 Nausea(N)、Oculo-motor(O)、Total(TS)。**用原始加权系数（N×9.54、O×7.58、TS×3.74，权重在脚本里写清注释），不是简单求和。** 子量表条目归属：
  - N = items 1+6+7+8+12+13+14+15+16
  - O = items 2+3+4+5+9+10+11
- 前测 vs 后测：对 N/O/TS 做配对 t 检验 + Wilcoxon 符号秩（SSQ 常偏态，两个都给）。
- 计算 ΔSSQ（后−前），重点 Oculo-motor。报告效应量。
- 探索 ΔSSQ 与 视觉舒适度 / CMS 注视时长 / TTC 的相关。

### 5.10 `09_sensitivity.R`
统一汇总所有敏感性分析，每项都"全样本 vs 子样本"对照、报告结论是否一致：
1. 剔除 P09 / P15 / 二者后重跑 TTC 与关键主观/眼动模型。
2. scene 作为因子：跑一个含 scene 的模型，看 scene 主效应与是否改变频率/深度结论。
3. 缺失对照：主观分析"仅完整数据 vs 全数据（LMM/CLMM）"结论对照。
4. 眼动质量分层：全样本 vs 仅高 valid_ratio。
- 输出 `output/tables/09_sensitivity_summary.csv`。

### 5.11 `10_plots.R`
见第 6 节"必备图表清单"，全部生成并存 `output/figures/`。

### 5.12 `run_all.R`
依次 `source()` 全部脚本；最后打印一份"已生成的表与图清单 + 关键结论摘要"。

---

## 6. 必备图表清单（务必全部生成，png 300dpi，命名见括号）

### 诊断类（导师先看）
1. **QQ 图矩阵**：TTC 各条件残差正态性（`fig_qq_ttc.png`）；主观与关键眼动各一张。
2. **残差诊断图**：RM-ANOVA/LMM 残差 vs 拟合、残差直方图（`fig_resid_ttc.png`）。
3. **离群点标注箱线图**：各条件 TTC 箱线图,极端点高亮标 participant（`fig_outlier_ttc.png`）。

### TTC 主结果
4. **TTC 箱线图 + 散点**：横轴 10 条件，叠加个体点（`fig_ttc_box.png`）。
5. **TTC 交互作用线图**：横轴 frequency(8.33/12.5/25)，3 条线=3 个 modulation_depth，纵轴 TTC 均值±95%CI；另用单独点/水平线标 0Hz 基线（`fig_ttc_interaction.png`）。**这是回答 SRQ3 的核心图。**
6. **TTC 个体轨迹图（spaghetti）**：每名被试一条线跨条件，看个体差异（`fig_ttc_spaghetti.png`）。

### 主观评分
7. **4 评分分组条形/箱线图**：各条件下 Q1–Q4 均值±CI（`fig_ratings_bar.png`）。
8. **Likert 发散堆叠条形图**：1–7 各分值占比，每个维度一图或分面（`fig_ratings_likert.png`）。
9. **条件 × 维度热力图**：均值矩阵，一眼看哪种条件最不适/负荷最高（`fig_ratings_heatmap.png`）。

### 眼动
10. **CMS vs Road 注意分配堆叠条形图**：各条件 dwell_ratio（`fig_eye_dwell.png`）。
11. **关键眼动指标交互线图**：transition_count、fixation_duration_cms 随 frequency×depth（`fig_eye_interaction.png`）。
12. **首次注视 CMS**：两段式——是否注视比例条形图 + 注视者时间分布（`fig_eye_firstfix.png`）。

### SSQ
13. **SSQ 前后对比图**：N/O/TS 前测 vs 后测配对点线图或哑铃图（`fig_ssq_prepost.png`）。

### 汇总
14. **效应量森林图（可选但加分）**：各因变量频率/深度/交互的偏 η² 或效应量 + CI 一图汇总（`fig_effectsize_forest.png`）。

每张图都配一句图注说明它回答哪个 SRQ。

---

## 7. 报告规范（脚本输出里固定）
- 每个检验报告：统计量、df、p、效应量、95%CI。
- 多重比较一律 Holm–Bonferroni；球形度违反一律 GG 校正。
- 每个主分析配敏感性对照结论。
- 明确写出缺失数量、机制（休息误点）、处理方式，体现"不删除、用模型处理"。
- 所有数值结果存 csv，便于直接进论文表格。

## 8. 交互守则（给 Claude Code 的行为约束）
1. 拿到数据文件夹后，**先跑 01 的探测部分，把目录结构和列名打印给用户确认**，不要直接全跑。
2. **文件名编码解析必须先让用户核对前 2 名被试的对照表**再批量。
3. 任何会"删数据/删被试"的诱惑都拒绝；遇到缺失/异常一律"标记 + 模型处理 + 报告"。
4. 不确定字段含义或编码规则时**停下来问**，附上你看到的样例。
5. 每个脚本跑完打印"本步生成了哪些文件 + 关键发现一句话"。
