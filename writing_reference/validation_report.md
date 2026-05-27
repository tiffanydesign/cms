# CMS Flicker Experiment — Validation Report

## Material Passport


---

## Validation Report

- **Source**: external — `cms_analysis/writing_reference/results_summary.md` (complete R pipeline output)
- **Design**: Within-subject, N=25, 10 conditions × 3 scenes, 750 trials total
- **IVs**: Frequency (0/8.33/12.5/25 Hz) × Modulation Depth (40/60/80%; flickering only)
- **DVs**: TTC (behavioral), Q1–Q4 + Cognitive Load (subjective), 7 eye-tracking metrics, SSQ
- **Analysis structure**: Two-step (Step 1: 4-level frequency; Step 2: 3×3 flickering only)
- **Corrections applied**: GG for sphericity violations; Holm–Bonferroni for post-hoc
- **Overall Confidence**: CAUTION (solid primary findings; see fallacy scan for caveats)

---

## Statistical Findings

### TTC (Time-to-Collision)

| Metric | Test | Value | Effect Size | CI | Confidence |
|--------|------|-------|-------------|-----|------------|
| Frequency (4-level, Step 1) | RM-ANOVA (GG) | F(1.83, 43.91) = 5.094, p = .012 | η²_p = .175 (medium) | [.010, .362] | SOLID |
| 8.33 Hz − 0 Hz (planned contrast) | t(24) | t = −1.311, p = .426 (Holm) | — | [−0.644, 0.209] s | CAUTION (ns; wide CI) |
| 12.5 Hz − 0 Hz (planned contrast) | t(24) | t = −1.518, p = .426 (Holm) | — | [−0.768, 0.198] s | CAUTION (ns; wide CI) |
| 25 Hz − 0 Hz (planned contrast) | t(24) | t = +1.225, p = .426 (Holm) | — | [−0.236, 0.664] s | CAUTION (ns; wide CI) |
| Frequency (3-level, Step 2) | RM-ANOVA (GG) | F(1.99, 47.65) = 16.096, p < .001 | η²_p = .401 (large) | [.181, .562] | SOLID |
| Depth (Step 2) | RM-ANOVA (GG) | F(1.74, 41.68) = 2.694, p = .086 | η²_p = .101 (medium) | [.000, .282] | CAUTION (marginal; large CI includes 0) |
| Frequency × Depth interaction (Step 2) | RM-ANOVA (GG) | F(3.13, 75.23) = 0.716, p = .551 | η²_p = .029 (small) | [.000, .104] | SOLID (null) |
| 8.33 Hz − 25 Hz (post-hoc) | t(24) | t = −4.363, p = .0004 | — | [−0.686, −0.177] s | SOLID |
| 12.5 Hz − 25 Hz (post-hoc) | t(24) | t = −5.231, p = .0001 | — | [−0.745, −0.254] s | SOLID |
| 8.33 Hz − 12.5 Hz (post-hoc) | t(24) | t = +0.736, p = .469 | — | [−0.169, 0.304] s | SOLID (null) |
| Depth contrasts (Step 2, all) | t(24), 3 pairs | all p > .20 | all η²_p small | overlapping 0 | SOLID (null) |
| LMM robustness (with scene random intercept) | LMM (Satterthwaite) | Frequency F(2,638) = 12.083, p < .001 | — | — | SOLID |

**Interpretation**: The 4-level frequency effect is significant and medium, but dissolves into non-significance when tested as individual planned contrasts vs 0 Hz after Holm correction — driven by insufficient per-contrast power (N=25) rather than a true null. Within flickering conditions, the frequency effect is large, carried specifically by 25 Hz producing longer TTC (M = 4.7 s) vs 8.33 Hz (M = 4.3 s) and 12.5 Hz (M = 4.3 s). **This is opposite to H1's prediction that 12.5 Hz would show the largest deviation.**

---

### Subjective Ratings (Q1–Q4 + Cognitive Load)

| Metric | Test | Value | Effect Size | CI | Confidence |
|--------|------|-------|-------------|-----|------------|
| Q1 Visual Comfort (Step 1) | RM-ANOVA (GG) | F(1.52, 36.57) = 54.133, p < .001 | η²_p = .693 (large) | [.509, .794] | SOLID |
| Q2 Mental Demand (Step 1) | RM-ANOVA (GG) | F(1.64, 39.31) = 28.672, p < .001 | η²_p = .544 (large) | [.319, .686] | SOLID |
| Q3 Effort (Step 1) | RM-ANOVA (GG) | F(1.83, 44.02) = 24.186, p < .001 | η²_p = .502 (large) | [.281, .647] | SOLID |
| Q4 Decision Certainty (Step 1) | RM-ANOVA (GG) | F(1.51, 36.34) = 5.605, p = .013 | η²_p = .189 (medium) | [.010, .398] | SOLID |
| Cognitive Load composite (Step 1) | RM-ANOVA (GG) | F(1.73, 41.55) = 27.875, p < .001 | η²_p = .537 (large) | [.317, .677] | SOLID |
| Q1 Frequency (Step 2) | RM-ANOVA (GG) | F(1.66, 39.85) = 6.053, p = .008 | η²_p = .201 (medium) | [.018, .400] | SOLID |
| Q1 Depth (Step 2) | RM-ANOVA (GG) | F(1.34, 32.24) = 79.203, p < .001 | η²_p = .767 (large) | [.609, .849] | SOLID |
| Q2 Depth (Step 2) | RM-ANOVA (GG) | F(1.35, 32.52) = 42.531, p < .001 | η²_p = .639 (large) | [.419, .763] | SOLID |
| Q3 Depth (Step 2) | RM-ANOVA (GG) | F(1.69, 40.45) = 44.940, p < .001 | η²_p = .652 (large) | [.463, .762] | SOLID |
| Q4 Depth (Step 2) | RM-ANOVA (GG) | F(1.65, 39.71) = 11.255, p < .001 | η²_p = .319 (large) | [.091, .509] | SOLID |
| All Frequency × Depth interactions | RM-ANOVA (GG) | all p > .18 | all η²_p < .065 | — | SOLID (null) |
| All depth contrasts Q1 (Holm) | t(24) | all p < .001 | — | — | SOLID |

**Interpretation**: Flicker frequency and modulation depth both significantly affect all subjective dimensions. Depth effects dominate (η²_p .319–.767), especially for visual discomfort (Q1). All flickering frequencies reduced comfort vs 0 Hz (all p < .001) — confirming H1 directionally. No frequency × depth interaction found, disconfirming H3.

---

### Eye-Tracking Metrics (7 metrics)

| Metric | Test | Value | Effect Size | CI | Confidence |
|--------|------|-------|-------------|-----|------------|
| All 7 metrics — Frequency (Step 1) | RM-ANOVA (GG) | all p = .157–.902 | all η²_p = .005–.073 | all small | SOLID (null) |
| dwell_ratio_cms — Depth (Step 2) | RM-ANOVA (GG) | F(1.83, 43.93) = 4.102, p = .026 | η²_p = .146 (medium) | [.000, .330] | CAUTION (η²_p CI includes 0) |
| dwell_time_cms_ms — Depth (Step 2) | RM-ANOVA (GG) | F(1.91, 45.80) = 4.058, p = .025 | η²_p = .145 (medium) | [.000, .324] | CAUTION (η²_p CI includes 0) |
| fixation_count_road — Depth (Step 2) | RM-ANOVA (GG) | F(1.93, 46.34) = 3.346, p = .046 | η²_p = .122 (medium) | [.000, .297] | CAUTION (borderline p; CI includes 0) |
| All Frequency × Depth interactions | RM-ANOVA (GG) | all p > .19 | all η²_p small | — | SOLID (null) |
| dwell_ratio_cms 60%–80% (post-hoc) | t(24) | t = −3.093, p = .015 | — | — | SOLID |
| GLMM (count metrics) | Poisson/NB | all terms ns | — | — | SOLID (null) |

**Interpretation**: Flicker frequency has no detectable effect on any gaze metric — participants did not redistribute visual attention in response to frequency changes. Depth shows small-to-medium effects on CMS dwell allocation, but effect-size CIs are very wide and touch zero, making these tentative. H2 (visual search effort increases with frequency + depth) is not supported for eye-tracking; subjective ratings show the cognitive load increase but gaze behavior does not mirror it.

---

### Simulator Sickness (SSQ)

| Metric | Test | Value | Effect Size | Confidence |
|--------|------|-------|-------------|------------|
| Oculo-motor Δ | Paired t + Wilcoxon | t(24) = 3.023, p = .006; W = 95, p = .008 | Cohen's d = 0.605 (medium) | SOLID |
| Total Severity Δ | Paired t + Wilcoxon | t(24) = 3.134, p = .005; W = 154, p = .003 | Cohen's d = 0.627 (medium) | SOLID |
| Nausea Δ | Paired t + Wilcoxon | t(24) = 2.064, p = .050; W = 45, p = .059 | Cohen's d = 0.413 (small-medium) | CAUTION (borderline p) |
| Δ-Oculomotor × mean Q1 | Spearman | ρ = −0.557, p = .004 | — | SOLID |
| Δ-Total Severity × mean Q1 | Spearman | ρ = −0.540, p = .005 | — | SOLID |

**Interpretation**: Significant post-session increases in oculomotor symptoms (d = 0.61) and total sickness (d = 0.63). Nausea borderline significant (t p = .050; Wilcoxon ns at .059). Participants with lower visual comfort ratings showed larger SSQ increases — indicating the subjective discomfort ratings captured something real.

---

### ANCOVA — Individual Differences Covariates

| Metric | Test | Value | Confidence |
|--------|------|-------|------------|
| exp_confidence × TTC | OLS regression | β = 0.127, p = .729, R² = .005 | SOLID (null) |
| driving_style × TTC | OLS regression | β = 0.214, p = .611, R² = .011 | SOLID (null) |
| Both covariates — LRT | LMM model comparison | ΔAIC = +3.53, χ²(2) = 0.47, p = .789 | SOLID (null) |
| Participant ICC (baseline LMM) | Random-effects | ICC = 0.942 | Informative — see below |

**Interpretation**: Between-subject ICC = 0.942 indicates that 94.2% of TTC variance is due to stable individual differences (not experimental conditions). Neither driving confidence nor driving style explains this. The massive individual variability warrants explicit discussion in the paper — perceptual sensitivity or idiosyncratic risk threshold likely mediates TTC.

---

## Warnings

| Type | Detail | Affected Metrics |
|------|--------|-----------------|
| ASSUMPTION VIOLATION | Sphericity violated for most DVs in Step 1 (Mauchly p < .001); GG correction applied throughout | TTC, Q1–Q4, CL, dwell_ratio, transition_count, fixation_duration |
| SAMPLE SIZE | N=25; paired contrasts have limited power (~0.60 at medium η²_p with 3 comparisons after Holm) — individual planned contrasts vs 0 Hz all non-significant despite overall RM-ANOVA F being significant | TTC planned contrasts |
| WIDE CI | Several η²_p 95% CIs span from near-zero to large, including for nominally significant effects | dwell_ratio depth effect, fixation_count_road depth effect |
| SPECIAL CASES | P09 (no driving license) and P15 (colorblind) included in primary analysis; sensitivity check shows all key results robust | TTC, Q1 |
| BORDERLINE p | Nausea Δ (t p = .050; Wilcoxon p = .059) — should not be over-interpreted | SSQ Nausea |
| HYPOTHESIS DIRECTION | TTC result for 25 Hz is LONGER (more conservative), not shorter — direction is opposite to H1 prediction (H1 expected 12.5 Hz to deviate most). Paper should address this explicitly. | TTC Step 2 post-hoc |
| CLMM DEGENERATE | Ordinal robustness check failed to converge for most rating DVs due to near-complete separation — only one partial result available | Q2 Step 1 |
| ICC | Between-subject ICC = 0.942 means individual differences dominate; the experimental effect sizes, while statistically significant, explain a minority of total variance | TTC |

---

## Fallacy Scan — 11/11 Types Checked

| # | Fallacy | Severity | Detail | Recommendation |
|---|---------|----------|--------|----------------|
| 1 | Simpson's Paradox | NOTE | Not applicable: within-subject design; no grouping variable where aggregate vs subgroup directions could diverge. Scene analysis (A/B/C) shows consistent frequency effects across scenes. | None required |
| 2 | Ecological Fallacy | NOTE | Not applicable: individual-level trial data used for individual-level inference. | None required |
| 3 | Berkson's Paradox | CAUTION | Participants are volunteer university students in a VR lab study — possible self-selection for tech-comfort and CMS experience. May affect generalizability of TTC absolute values. | Acknowledge self-selection limitation in Discussion |
| 4 | Collider Bias | CAUTION | ANCOVA model includes exp_confidence as covariate. exp_confidence could plausibly be influenced by both frequency/depth (harder conditions → less confidence) and TTC (faster responders → more confident). Collider if both causal paths exist. | Report LMM-only results as primary; treat ANCOVA as sensitivity check. Flagged in Section 9. |
| 5 | Base Rate Neglect | NOTE | Not applicable: not a diagnostic/screening study; no PPV/NPV/sensitivity/specificity reported. | None required |
| 6 | Regression to the Mean | NOTE | Not applicable: conditions are randomly counterbalanced within-subject; no group selection based on extreme scores. | None required |
| 7 | Survivorship Bias | NOTE | All 25 participants completed the study; no dropouts. P09 and P15 flagged but retained and sensitivity-checked. flag_no_response = 0.3% (2 trials), all retained with NA. Attrition effectively zero. | None required |
| 8 | Look-Elsewhere Effect | CAUTION | 14+ DVs tested (TTC, Q1–Q4, CL, 7 eye metrics, SSQ subscales, ANCOVA) with many sub-tests. Holm correction applied within each DV family but NOT across DVs. A Bonferroni correction across all primary DVs would set α ≈ .003, which would leave only large-effect rating/TTC findings significant. | Be explicit that eye-tracking depth effects (p = .025–.046) should be treated as exploratory given familywise context. State Holm correction scope clearly in Methods. |
| 9 | Garden of Forking Paths | CAUTION | Two-step analysis (Step 1 = 4-level; Step 2 = 3×3 flickering only) was pre-specified in ANALYSIS_SPEC.md and motivated by structural design constraints. However: cognitive load composite (Q2+Q3 mean) was confirmed post-hoc via EMM cross-check, not pre-registered. Scene analysis added exploratorily. ANCOVA added as sensitivity. | Label exploratory analyses explicitly in the paper. The two-step structure is confirmatory; scene/ANCOVA analyses are exploratory. |
| 10 | Correlation ≠ Causation | NOTE | Within-subject experimental design with controlled IV manipulation — causality is defensible for frequency and depth effects on DVs. SSQ correlations with Q1 (ρ = −0.54 to −0.56) are observational/correlational — causal language should be avoided for those. | Maintain experimental causal framing for ANOVA results. Use associational language for SSQ correlations. |
| 11 | Reverse Causality | NOTE | Not applicable for experimental main effects (IV was manipulated). SSQ correlation (Δ-SSQ × Q1): plausible that discomfort causes sickness OR that sickness susceptibility causes discomfort — cross-sectional correlation, direction unresolvable. | Avoid directional causal claims for SSQ correlation; use bidirectional language or frame as convergent validity. |

---

## Hypothesis Verdict

| Hypothesis | Prediction | Result | Verdict |
|-----------|------------|--------|---------|
| H1: Flicker vs stable (SRQ1) | Flickering reduces TTC (more risk-taking); 12.5 Hz deviates most | 25 Hz actually INCREASES TTC (more conservative); no individual frequency significantly differs from 0 Hz in planned contrasts. Subjective discomfort confirmed for all flickering conditions. | PARTIALLY SUPPORTED — direction unexpected for TTC; subjective component confirmed |
| H2: Freq + Depth → search effort + cognitive load (SRQ2) | Both ↑ → search effort ↑, cognitive load ↑ | Subjective ratings fully support (large effects). Eye-tracking does NOT support — no frequency effects on any gaze metric; only small depth effects on dwell. | PARTIALLY SUPPORTED — subjective only; gaze null |
| H3: Frequency × Depth interaction (SRQ3) | High depth amplifies frequency effect | No significant interaction for any DV (all p > .18) | NOT SUPPORTED |

---

## Reproducibility

- **Method**: N/A — human study; cannot re-run data collection. R pipeline scripts are deterministic with `set.seed(2026)` and all scripts committed. Sensitivity analyses (P09/P15 exclusion, scene stratification, eye quality subsample) confirm robustness.
- **Verdict**: CANNOT_VERIFY (human study) — Pipeline is reproducible; results from `run_all.R` are deterministic given the input data.

---

## Recommended Reporting Notes for Paper

1. **Lead with depth as dominant predictor** for subjective ratings — η²_p up to .767 vs frequency η²_p up to .201.
2. **TTC direction is counterintuitive** — 25 Hz → longer TTC (more conservative timing, not more risk-taking). Frame as a potential "over-caution under high-frequency flicker" effect.
3. **No frequency × depth interaction** is a reportable null — reject H3 cleanly.
4. **Eye-tracking and subjective ratings dissociate**: participants felt more discomfort and cognitive load but did not shift gaze allocation. This dissociation is theoretically interesting.
5. **ICC = 0.942**: large individual differences in TTC warrant explicit discussion. Perceptual sensitivity or idiosyncratic risk threshold are candidate explanations.
6. **Label exploratory analyses**: scene analysis, ANCOVA, and eye-tracking depth effects should be labeled as exploratory.
7. **SSQ correlation is convergent validity evidence**, not a causal claim.

---

*Generated by experiment-agent validate mode | cms_analysis dataset | 2026-05-28*
