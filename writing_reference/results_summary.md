# CMS Flicker Experiment — Complete Results Summary

**Generated:** 2026-05-26  
**Design:** Within-subject, N = 25, 30 trials/participant (10 conditions × 3 scenes), 750 total observations  
**IV1 — Frequency:** 0 Hz (stable), 8.33 Hz, 12.5 Hz, 25 Hz  
**IV2 — Modulation Depth:** 40%, 60%, 80% (flickering conditions only; 0 Hz has no depth)  
**Two-step design:** Step 1 = 4-level frequency RM-ANOVA (SRQ1); Step 2 = 3×3 flickering only (SRQ3)  
**GG correction:** Applied throughout when Mauchly p < .05; df reported as GG-corrected  

---

## Data Quality & Flags

*Source: 02_flag_summary.csv*

| Flag | n_flagged | % of 750 | Participants |
|------|-----------|----------|-------------|
| flag_no_response | 2 | 0.3% | P03, P11 (video_index=15, 8.33 Hz / 60%) |
| flag_missing_rating | 2 | 0.3% | P03, P11 (same trial) |
| flag_low_eye_quality | 24 | 3.2% | P02, P03, P04, P07, P11, P21, P23, P24 |
| flag_extreme_ttc | 6 | 0.8% | P04, P07, P09, P10, P18 |
| is_P09_nolicense | 30 | 4.0% | P09 (all 30 trials) |
| is_P15_colorblind | 30 | 4.0% | P15 (all 30 trials) |

**Flags are annotations only — no data excluded from primary analyses.**

**Skipped-trial detail (P03 & P11, video_index = 15):** Both participants accidentally clicked "continue" on the rest window before the 16th video played. The experiment software recorded `paddle_time_s = −1` (sentinel) and propagated the prior rating screen values into Q1–Q4 for that trial. These values are invalid. In the pipeline, TTC_s and Q1–Q4 for these two rows are set to NA; `paddle_time_s = −1` is preserved as the raw sentinel. The condition is **8.33 Hz / 60% depth / Scene C** (n = 73 for TTC and ratings at that cell; all other cells n = 75).

**Missing values by column (verified from master_long.csv):**

| Column | NA count | Notes |
|--------|----------|-------|
| TTC_s | 0 | Complete |
| Q1, Q2, Q3, Q4 | 0 each | Complete |
| dwell_ratio_cms, dwell_time_cms_ms | 0 each | Complete |
| transition_count, fixation_count_cms, fixation_count_road | 0 each | Complete |
| fixation_duration_cms_mean_ms | **1** | One trial (8.33 Hz / 60% depth) — participant had zero CMS fixations in that trial → per-trial mean undefined |
| fixation_duration_road_mean_ms | **1** | Same trial as above |
| first_fixation_cms_time_ms = −1 | 1 occurrence | Sentinel, not missing — coded −1 when participant never fixated CMS; excluded from first-fixation latency analyses per pipeline spec |

The single NA in fixation duration metrics appears in the same trial (8.33 Hz / 60% depth condition). Descriptive and inferential statistics for those two columns use n = 74 at that cell (marked †).

---

## 1. Assumption Checks (Step 04)

*Source: 04_assumption_checks.csv*  
Normality = Shapiro–Wilk on participant-level condition means; extreme outliers = |z| > 3.  
Sphericity = Mauchly's W; GG correction applied when p < .05.

### 1.1 Step 1 — 4-Level Frequency RM-ANOVA

| DV | Normality | Mauchly W | p | GG ε | Decision | n extreme |
|----|-----------|-----------|---|------|----------|-----------|
| TTC_s | pass | 0.528 | .013 | 0.745 | VIOLATED → GG | 0 |
| Q1 | pass | 0.188 | <.001 | 0.512 | VIOLATED → GG | 0 |
| Q2 | pass | 0.282 | <.001 | 0.549 | VIOLATED → GG | 0 |
| Q3 | pass | 0.340 | .0002 | 0.611 | VIOLATED → GG | 0 |
| Q4 | pass | 0.184 | <.001 | 0.504 | VIOLATED → GG | 0 |
| dwell_ratio_cms | pass | 0.393 | .0007 | 0.614 | VIOLATED → GG | 0 |
| transition_count | pass | 0.490 | .006 | 0.696 | VIOLATED → GG | 0 |
| fixation_count_cms | pass | 0.694 | .141 | 0.810 | pass | 0 |
| fixation_duration_cms_mean_ms | pass | 0.119 | <.001 | 0.474 | VIOLATED → GG | 1 |

### 1.2 Step 2 — 3×3 Flickering RM-ANOVA

| DV | Normality | Freq GGε / sph | Depth GGε / sph | Int GGε / sph | n extreme |
|----|-----------|----------------|-----------------|---------------|-----------|
| TTC_s | pass | 0.806 / VIOLATED | 0.868 / pass | 0.784 / pass | 0 |
| Q1 | pass | 0.830 / pass | 0.672 / VIOLATED | 0.828 / pass | 1 |
| Q2 | pass | 0.928 / pass | 0.677 / VIOLATED | 0.745 / pass | 0 |
| Q3 | pass | 0.790 / VIOLATED | 0.843 / pass | 0.840 / pass | 0 |
| Q4 | pass | 0.961 / pass | 0.827 / pass | 0.924 / pass | 0 |
| dwell_ratio_cms | pass | 0.961 / pass | 0.915 / pass | 0.701 / VIOLATED | 1 |
| transition_count | pass | 0.941 / pass | 0.932 / pass | 0.774 / pass | 0 |
| fixation_count_cms | pass | 0.924 / pass | 0.862 / pass | 0.889 / pass | 1 |
| fixation_duration_cms_mean_ms | pass | 0.770 / VIOLATED | 0.801 / VIOLATED | 0.767 / pass | 1 |

---

## 2. Descriptive Statistics

### 2.1 TTC (seconds)

*Source: 03_descriptives_ttc.csv; n = 75 per cell*

| Condition | Freq (Hz) | Depth (%) | M | SD | Median | IQR |
|-----------|-----------|-----------|---|----|----|-----|
| 0 Hz (stable) | 0 | — | 4.515 | 2.159 | 4.329 | 3.034 |
| 8.33 Hz / 40% | 8.33 | 40 | 4.257 | 2.359 | 4.002 | 3.564 |
| 8.33 Hz / 60% | 8.33 | 60 | 4.326 | 2.261 | 4.088 | 2.724 | † n=73 (P03 & P11 skipped trial) |
| 8.33 Hz / 80% | 8.33 | 80 | 4.322 | 2.328 | 4.081 | 2.818 |
| 12.5 Hz / 40% | 12.5 | 40 | 4.052 | 2.308 | 3.524 | 3.328 |
| 12.5 Hz / 60% | 12.5 | 60 | 4.113 | 2.356 | 3.844 | 2.773 |
| 12.5 Hz / 80% | 12.5 | 80 | 4.524 | 2.547 | 4.165 | 2.806 |
| 25 Hz / 40% | 25 | 40 | 4.608 | 2.248 | 4.318 | 2.904 |
| 25 Hz / 60% | 25 | 60 | 4.680 | 2.456 | 4.245 | 2.565 |
| 25 Hz / 80% | 25 | 80 | 4.898 | 2.497 | 4.642 | 2.966 |

### 2.2 Subjective Ratings (7-point Likert; Q4: higher = more certain)

*Source: 03_descriptives_ratings.csv; n = 75 per cell; flag_missing_rating = 0 for all 750 observations (ratings are complete — no missing values)*

#### 2.2.0 Unified Descriptive Table — Higher = More Negative (for cross-DV comparison)

*Q1 and Q4 are re-expressed so that all four DVs share a common direction: higher score = more negative subjective experience. Q2 and Q3 are unchanged.*

| | Scale (unified) | Anchor low | Anchor high |
|--|--|--|--|
| **Visual Discomfort** | 8 − Q1 | 1 = Very Comfortable | 7 = Very Uncomfortable |
| **Mental Demand** | Q2 | 1 = Very Low | 7 = Very High |
| **Effort** | Q3 | 1 = Very Little | 7 = A Great Deal |
| **Decision Uncertainty** | 8 − Q4 | 1 = Extremely Certain | 7 = Not at All Certain |

*Source: 10b_ratings_unified_descriptives.csv; SD unchanged by additive transformation*

| Condition | Visual Discomfort M (SD) | Mental Demand M (SD) | Effort M (SD) | Decision Uncertainty M (SD) |
|-----------|--------------------------|----------------------|---------------|-----------------------------|
| 0 Hz (stable) | 2.46 (1.35) | 3.03 (1.21) | 3.01 (1.29) | 2.79 (1.43) |
| 8.33 Hz / 40% | 3.62 (1.40) | 3.55 (1.20) | 3.45 (1.32) | 3.17 (1.41) |
| 8.33 Hz / 60% | 4.42 (1.50) | 3.97 (1.34) | 4.02 (1.33) | 3.23 (1.48) |
| 8.33 Hz / 80% | 5.16 (1.51) | 4.47 (1.18) | 4.26 (1.35) | 3.50 (1.57) |
| 12.5 Hz / 40% | 3.86 (1.38) | 3.75 (1.24) | 3.65 (1.20) | 3.11 (1.41) |
| 12.5 Hz / 60% | 4.72 (1.53) | 4.25 (1.41) | 4.24 (1.41) | 3.32 (1.41) |
| 12.5 Hz / 80% | 5.61 (1.47) | 4.87 (1.53) | 4.89 (1.47) | 3.55 (1.66) |
| 25 Hz / 40% | 4.01 (1.45) | 3.85 (1.41) | 3.60 (1.38) | 3.00 (1.47) |
| 25 Hz / 60% | 4.70 (1.36) | 4.22 (1.20) | 4.25 (1.18) | 3.51 (1.46) |
| 25 Hz / 80% | 5.60 (1.37) | 4.75 (1.40) | 4.63 (1.37) | 3.62 (1.72) |

**Key patterns visible in unified direction:**
- Visual Discomfort shows the largest range (2.46 → 5.61), driven by modulation depth
- Mental Demand and Effort track closely together (cognitive load composite is justified)
- Decision Uncertainty shows the smallest effect (~0.7 points range vs ~3.1 for Discomfort)
- The 80% depth row is consistently the most negative across all four dimensions

*Figures: fig_ratings_unified_emm.png (Step-1 EMMs by frequency), fig_ratings_unified_heatmap.png (10 × 4 grid), fig_ratings_unified_depth.png (depth gradient)*

---

#### Q1 — Visual Comfort (1 = Very Uncomfortable, 7 = Very Comfortable; higher = more comfortable)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz (stable) | 5.539 | 1.348 |
| 8.33 / 40% | 4.380 | 1.403 |
| 8.33 / 60% | 3.604 | 1.487 |
| 8.33 / 80% | 2.843 | 1.512 |
| 12.5 / 40% | 4.141 | 1.383 |
| 12.5 / 60% | 3.281 | 1.528 |
| 12.5 / 80% | 2.390 | 1.472 |
| 25 / 40% | 3.986 | 1.448 |
| 25 / 60% | 3.305 | 1.365 |
| 25 / 80% | 2.396 | 1.367 |

#### Q2 — Mental Demand (1 = Very low, 7 = Very high; higher = more mentally demanding)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz (stable) | 3.029 | 1.214 |
| 8.33 / 40% | 3.550 | 1.200 |
| 8.33 / 60% | 3.978 | 1.327 |
| 8.33 / 80% | 4.475 | 1.177 |
| 12.5 / 40% | 3.750 | 1.236 |
| 12.5 / 60% | 4.247 | 1.411 |
| 12.5 / 80% | 4.873 | 1.527 |
| 25 / 40% | 3.851 | 1.408 |
| 25 / 60% | 4.219 | 1.203 |
| 25 / 80% | 4.753 | 1.395 |

#### Q3 — Effort (1 = Very little, 7 = A great deal; higher = more effort expended)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz (stable) | 3.013 | 1.293 |
| 8.33 / 40% | 3.451 | 1.321 |
| 8.33 / 60% | 4.016 | 1.311 |
| 8.33 / 80% | 4.261 | 1.351 |
| 12.5 / 40% | 3.649 | 1.199 |
| 12.5 / 60% | 4.239 | 1.409 |
| 12.5 / 80% | 4.889 | 1.466 |
| 25 / 40% | 3.596 | 1.379 |
| 25 / 60% | 4.247 | 1.176 |
| 25 / 80% | 4.634 | 1.368 |

#### Q4 — Decision Certainty (1 = Not at all certain, 7 = Extremely certain; higher = more certain)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz (stable) | 5.213 | 1.432 |
| 8.33 / 40% | 4.833 | 1.409 |
| 8.33 / 60% | 4.724 | 1.493 |
| 8.33 / 80% | 4.505 | 1.566 |
| 12.5 / 40% | 4.893 | 1.412 |
| 12.5 / 60% | 4.679 | 1.408 |
| 12.5 / 80% | 4.451 | 1.660 |
| 25 / 40% | 4.996 | 1.469 |
| 25 / 60% | 4.487 | 1.463 |
| 25 / 80% | 4.377 | 1.719 |

### 2.3 Eye-Tracking Metrics

*Source: 03_descriptives_eye.csv; n = 75 per cell except where noted. † n = 74 at 8.33 Hz / 60% for fixation_duration_cms_mean_ms and fixation_duration_road_mean_ms — one participant had zero CMS fixations in that trial (NA). All other eye metrics are complete (0 NA across 750 rows).*

#### dwell_ratio_cms (% of trial time fixating CMS)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 38.689 | 13.518 |
| 8.33 / 40% | 37.663 | 16.181 |
| 8.33 / 60% | 36.862 | 17.115 |
| 8.33 / 80% | 38.504 | 16.476 |
| 12.5 / 40% | 37.368 | 16.985 |
| 12.5 / 60% | 35.363 | 16.650 |
| 12.5 / 80% | 39.416 | 17.644 |
| 25 / 40% | 37.024 | 15.716 |
| 25 / 60% | 37.559 | 17.755 |
| 25 / 80% | 38.651 | 18.949 |

#### dwell_time_cms_ms (ms)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 7854.489 | 2772.003 |
| 8.33 / 40% | 7559.153 | 3104.206 |
| 8.33 / 60% | 7359.653 | 3353.545 |
| 8.33 / 80% | 7759.713 | 3208.507 |
| 12.5 / 40% | 7623.161 | 3258.409 |
| 12.5 / 60% | 7070.037 | 3455.842 |
| 12.5 / 80% | 7866.611 | 3273.628 |
| 25 / 40% | 7583.043 | 3190.546 |
| 25 / 60% | 7449.371 | 3274.125 |
| 25 / 80% | 7843.939 | 3783.696 |

#### transition_count (AOI transitions per trial)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 11.227 | 4.546 |
| 8.33 / 40% | 11.467 | 4.900 |
| 8.33 / 60% | 10.760 | 4.475 |
| 8.33 / 80% | 10.893 | 3.663 |
| 12.5 / 40% | 11.307 | 4.538 |
| 12.5 / 60% | 11.387 | 4.223 |
| 12.5 / 80% | 11.027 | 4.937 |
| 25 / 40% | 11.440 | 5.123 |
| 25 / 60% | 10.960 | 4.569 |
| 25 / 80% | 11.027 | 4.685 |

#### fixation_count_cms

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 17.893 | 7.454 |
| 8.33 / 40% | 17.520 | 7.844 |
| 8.33 / 60% | 16.587 | 8.463 |
| 8.33 / 80% | 18.013 | 7.849 |
| 12.5 / 40% | 17.093 | 8.245 |
| 12.5 / 60% | 16.893 | 7.698 |
| 12.5 / 80% | 17.827 | 8.451 |
| 25 / 40% | 18.013 | 7.827 |
| 25 / 60% | 17.080 | 7.448 |
| 25 / 80% | 17.027 | 7.913 |

#### fixation_count_road

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 27.733 | 8.782 |
| 8.33 / 40% | 29.467 | 10.594 |
| 8.33 / 60% | 27.880 | 10.276 |
| 8.33 / 80% | 27.827 | 9.937 |
| 12.5 / 40% | 30.187 | 10.142 |
| 12.5 / 60% | 29.733 | 10.216 |
| 12.5 / 80% | 28.227 | 11.028 |
| 25 / 40% | 29.493 | 9.074 |
| 25 / 60% | 29.787 | 10.634 |
| 25 / 80% | 28.333 | 10.546 |

#### fixation_duration_cms_mean_ms (ms) — n = 74 at 8.33/60%†

| Condition | n | M | SD |
|-----------|---|---|---|
| 0 Hz | 75 | 527.104 | 393.264 |
| 8.33 / 40% | 75 | 472.752 | 216.943 |
| 8.33 / 60% | 74 | 489.999 | 234.470 |
| 8.33 / 80% | 75 | 464.772 | 182.833 |
| 12.5 / 40% | 75 | 492.021 | 222.587 |
| 12.5 / 60% | 75 | 454.533 | 208.714 |
| 12.5 / 80% | 75 | 476.684 | 191.405 |
| 25 / 40% | 75 | 472.471 | 242.332 |
| 25 / 60% | 75 | 478.562 | 241.201 |
| 25 / 80% | 75 | 503.116 | 251.963 |

#### fixation_duration_road_mean_ms (ms) — n = 74 at 8.33/60%†

| Condition | n | M | SD |
|-----------|---|---|---|
| 0 Hz | 75 | 391.693 | 169.326 |
| 8.33 / 40% | 75 | 369.469 | 121.423 |
| 8.33 / 60% | 74 | 406.872 | 243.419 |
| 8.33 / 80% | 75 | 385.560 | 133.633 |
| 12.5 / 40% | 75 | 379.256 | 235.750 |
| 12.5 / 60% | 75 | 366.862 | 131.418 |
| 12.5 / 80% | 75 | 390.113 | 176.430 |
| 25 / 40% | 75 | 374.095 | 120.529 |
| 25 / 60% | 75 | 377.043 | 177.633 |
| 25 / 80% | 75 | 408.087 | 357.743 |

#### valid_ratio (% valid gaze samples per trial)

| Condition | M | SD |
|-----------|---|---|
| 0 Hz | 91.96 | 9.708 |
| 8.33 / 40% | 91.57 | 8.928 |
| 8.33 / 60% | 89.48 | 14.800 |
| 8.33 / 80% | 91.55 | 7.946 |
| 12.5 / 40% | 92.50 | 6.846 |
| 12.5 / 60% | 90.38 | 13.744 |
| 12.5 / 80% | 91.50 | 8.491 |
| 25 / 40% | 92.59 | 7.546 |
| 25 / 60% | 91.05 | 8.852 |
| 25 / 80% | 91.88 | 6.999 |

### 2.4 SSQ Scores — Group Summaries (Kennedy 1993 weights)

*Source: 08_ssq_prepost_tests.csv; N = 25*

| Subscale | Scoring | M_pre | M_post | M_Δ | SD_Δ |
|----------|---------|-------|--------|-----|------|
| Nausea (N) | N_raw × 9.54 | 2.67 | 5.34 | +2.67 | 6.47 |
| Oculo-motor (O) | O_raw × 7.58 | 6.97 | 17.89 | +10.92 | 18.05 |
| Total Severity (TS) | (N+O+D)_raw × 3.74 | 5.39 | 13.76 | +8.38 | 13.37 |

---

## 3. TTC Analysis

### 3.1 Step 1 — One-way RM-ANOVA (4 frequency levels)

*Source: 05_anova_ttc_step1_main.csv; GG-corrected df*

| Effect | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|--------|---|--------|--------|-----|------|------|--------|
| frequency | 5.094 | 1.83 | 43.91 | 0.4119 | .0121 | .175 | [.010, .362] |

### 3.2 Step 1 — Estimated Marginal Means

*Source: 05_anova_ttc_step1_emm.csv*

| Frequency | EMM (s) | SE | df | 95% CI |
|-----------|---------|----|----|--------|
| 0 Hz | 4.515 | 0.394 | 24 | [3.702, 5.327] |
| 8.33 Hz | 4.297 | 0.406 | 24 | [3.459, 5.136] |
| 12.5 Hz | 4.230 | 0.432 | 24 | [3.338, 5.122] |
| 25 Hz | 4.729 | 0.434 | 24 | [3.833, 5.625] |

### 3.3 Step 1 — Planned Contrasts vs 0 Hz (Holm corrected)

*Source: 05_anova_ttc_step1_contrasts.csv; df = 24 for all*

| Contrast | Estimate (s) | SE | t | 95% CI | p_Holm |
|----------|-------------|----|---|--------|--------|
| 8.33 Hz − 0 Hz | −0.2172 | 0.1657 | −1.311 | [−0.644, 0.209] | .4261 |
| 12.5 Hz − 0 Hz | −0.2848 | 0.1876 | −1.518 | [−0.768, 0.198] | .4261 |
| 25 Hz − 0 Hz | +0.2143 | 0.1749 | +1.225 | [−0.236, 0.664] | .4261 |

**Conclusion: No individual flicker frequency differs significantly from the stable (0 Hz) baseline.**

### 3.4 Step 2 — Two-way RM-ANOVA (3 freq × 3 depth; flickering cells only)

*Source: 05_anova_ttc_step2_main.csv; GG-corrected df*

| Effect | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|--------|---|--------|--------|-----|------|------|--------|
| frequency | 16.096 | 1.99 | 47.65 | 0.3441 | <.001 | .401 | [.181, .562] |
| modulation_depth | 2.694 | 1.74 | 41.68 | 0.6686 | .0864 | .101 | [.000, .282] |
| frequency × depth | 0.716 | 3.13 | 75.23 | 0.6067 | .5511 | .029 | [.000, .104] |

### 3.5 Step 2 — Post-hoc Pairwise Comparisons (Holm corrected)

*Source: 05_anova_ttc_step2_posthoc.csv; df = 24 for all*

**Frequency (within flickering conditions):**

| Contrast | Estimate (s) | SE | t | 95% CI | p_Holm |
|----------|-------------|----|---|--------|--------|
| 8.33 Hz − 12.5 Hz | +0.0676 | 0.0919 | +0.736 | [−0.169, 0.304] | .4692 |
| 8.33 Hz − 25 Hz | −0.4316 | 0.0989 | −4.363 | [−0.686, −0.177] | .0004 *** |
| 12.5 Hz − 25 Hz | −0.4991 | 0.0954 | −5.231 | [−0.745, −0.254] | .0001 *** |

**Modulation Depth:**

| Contrast | Estimate (s) | SE | t | 95% CI | p_Holm |
|----------|-------------|----|---|--------|--------|
| 40% − 60% | −0.0631 | 0.1015 | −0.622 | [−0.324, 0.198] | .540 |
| 40% − 80% | −0.2756 | 0.1440 | −1.914 | [−0.646, 0.095] | .203 |
| 60% − 80% | −0.2125 | 0.1241 | −1.713 | [−0.532, 0.107] | .203 |

### 3.6 LMM Robustness Check (scene as crossed random intercept; flickering cells)

*Source: 05_anova_ttc_lmm_anova.csv; Satterthwaite ddf*

| Effect | Sum Sq | Mean Sq | Num DF | Den DF | F | p |
|--------|--------|---------|--------|--------|---|---|
| frequency | 32.987 | 16.493 | 2 | 638 | 12.083 | <.001 |
| modulation_depth | 9.387 | 4.694 | 2 | 638 | 3.439 | .0327 |
| frequency × depth | 4.066 | 1.017 | 4 | 638 | 0.745 | .5618 |

---

## 4. Subjective Ratings (Q1–Q4 + Cognitive Load)

*Cognitive load = average of Q2 and Q3 (confirmed by EMM cross-check)*

### 4.1 Step 1 — RM-ANOVA Summary

*Source: 06_ratings_step1_main.csv; GG-corrected*

| DV | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|----|---|--------|--------|-----|------|------|--------|
| Q1 | 54.133 | 1.52 | 36.57 | 1.0981 | <.001 | .693 | [.509, .794] |
| Q2 | 28.672 | 1.64 | 39.31 | 0.5653 | <.001 | .544 | [.319, .686] |
| Q3 | 24.186 | 1.83 | 44.02 | 0.5445 | <.001 | .502 | [.281, .647] |
| Q4 | 5.605 | 1.51 | 36.34 | 0.6689 | .0128 | .189 | [.010, .398] |
| cognitive_load | 27.875 | 1.73 | 41.55 | 0.5245 | <.001 | .537 | [.317, .677] |

### 4.2 Step 1 — Estimated Marginal Means

*Source: 06_ratings_step1_emm.csv*

| Frequency | Q1 | SE | Q2 | SE | Q3 | SE | Q4 | SE | CL | SE |
|-----------|----|----|----|----|----|----|----|----|----|----|
| 0 Hz | 5.539 | 0.230 | 3.029 | 0.224 | 3.013 | 0.235 | 5.213 | 0.261 | 3.021 | 0.224 |
| 8.33 Hz | 3.609 | 0.231 | 4.001 | 0.209 | 3.909 | 0.224 | 4.687 | 0.237 | 3.955 | 0.212 |
| 12.5 Hz | 3.271 | 0.237 | 4.290 | 0.240 | 4.259 | 0.219 | 4.675 | 0.231 | 4.274 | 0.228 |
| 25 Hz | 3.229 | 0.232 | 4.274 | 0.232 | 4.159 | 0.216 | 4.620 | 0.265 | 4.217 | 0.223 |

### 4.3 Step 1 — Planned Contrasts vs 0 Hz (Holm corrected)

*Source: 06_ratings_step1_contrasts.csv; df = 24 for all*

| DV | Contrast | Estimate | SE | t | p_Holm |
|----|----------|----------|----|----|--------|
| Q1 | 8.33 − 0 | −1.9402 | 0.2666 | −7.279 | <.001 *** |
| Q1 | 12.5 − 0 | −2.2687 | 0.2774 | −8.179 | <.001 *** |
| Q1 | 25 − 0 | −2.3102 | 0.2788 | −8.285 | <.001 *** |
| Q2 | 8.33 − 0 | +0.9726 | 0.1828 | +5.322 | <.001 *** |
| Q2 | 12.5 − 0 | +1.2615 | 0.2157 | +5.850 | <.001 *** |
| Q2 | 25 − 0 | +1.2458 | 0.1986 | +6.273 | <.001 *** |
| Q3 | 8.33 − 0 | +0.8985 | 0.1766 | +5.087 | <.001 *** |
| Q3 | 12.5 − 0 | +1.2459 | 0.2027 | +6.147 | <.001 *** |
| Q3 | 25 − 0 | +1.1459 | 0.2153 | +5.323 | <.001 *** |
| Q4 | 8.33 − 0 | −0.5062 | 0.1453 | −3.485 | .0057 ** |
| Q4 | 12.5 − 0 | −0.5380 | 0.2219 | −2.424 | .0321 * |
| Q4 | 25 − 0 | −0.5926 | 0.2288 | −2.590 | .0321 * |
| CL | 8.33 − 0 | +0.9355 | 0.1768 | +5.291 | <.001 *** |
| CL | 12.5 − 0 | +1.2537 | 0.2039 | +6.148 | <.001 *** |
| CL | 25 − 0 | +1.1959 | 0.2020 | +5.919 | <.001 *** |

### 4.4 Step 2 — Two-way RM-ANOVA (flickering cells only)

*Source: 06_ratings_step2_main.csv; GG-corrected*

| DV | Effect | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|----|--------|---|--------|--------|-----|------|------|--------|
| Q1 | frequency | 5.692 | 1.66 | 39.82 | 0.6307 | .0098 | .192 | [.014, .390] |
| Q1 | modulation_depth | 78.378 | 1.36 | 32.75 | 0.9279 | <.001 | .766 | [.607, .847] |
| Q1 | freq × depth | 0.407 | 3.32 | 79.57 | 0.4099 | .768 | .017 | [.000, .067] |
| Q2 | frequency | 5.401 | 1.87 | 44.98 | 0.3806 | .009 | .184 | [.015, .369] |
| Q2 | modulation_depth | 42.197 | 1.38 | 33.06 | 0.6265 | <.001 | .637 | [.418, .761] |
| Q2 | freq × depth | 0.423 | 2.96 | 71.07 | 0.3212 | .735 | .017 | [.000, .079] |
| Q3 | frequency | 4.566 | 1.58 | 37.97 | 0.6465 | .024 | .160 | [.001, .362] |
| Q3 | modulation_depth | 44.684 | 1.70 | 40.83 | 0.5286 | <.001 | .651 | [.462, .760] |
| Q3 | freq × depth | 1.676 | 3.35 | 80.44 | 0.2765 | .173 | .065 | [.000, .164] |
| Q4 | frequency | 0.280 | 1.91 | 45.86 | 0.5028 | .747 | .012 | [.000, .104] |
| Q4 | modulation_depth | 11.083 | 1.67 | 40.13 | 0.4367 | .0003 | .316 | [.090, .505] |
| Q4 | freq × depth | 1.178 | 3.66 | 87.84 | 0.3099 | .325 | .047 | [.000, .126] |
| CL | frequency | 5.348 | 1.78 | 42.81 | 0.4394 | .011 | .182 | [.012, .373] |
| CL | modulation_depth | 47.216 | 1.45 | 34.83 | 0.5545 | <.001 | .663 | [.461, .776] |
| CL | freq × depth | 0.928 | 3.11 | 74.56 | 0.2681 | .434 | .037 | [.000, .122] |

**No frequency × depth interaction significant for any rating (all p > .18).**

### 4.5 Step 2 — Post-hoc Pairwise Comparisons (Holm corrected)

*Source: 06_ratings_step2_posthoc.csv; df = 24 for all*

#### Frequency Contrasts (within flickering conditions)

| DV | Contrast | Estimate | SE | t | p_Holm |
|----|----------|----------|----|----|--------|
| Q1 | 8.33 − 12.5 | +0.3225 | 0.1134 | +2.843 | .027 * |
| Q1 | 8.33 − 25 | +0.3640 | 0.1410 | +2.581 | .033 * |
| Q1 | 12.5 − 25 | +0.0415 | 0.0954 | +0.435 | .668 |
| Q2 | 8.33 − 12.5 | −0.2851 | 0.1085 | −2.628 | .030 * |
| Q2 | 8.33 − 25 | −0.2693 | 0.0960 | −2.805 | .029 * |
| Q2 | 12.5 − 25 | +0.0158 | 0.0868 | +0.182 | .857 |
| Q3 | 8.33 − 12.5 | −0.3431 | 0.1174 | −2.923 | .022 * |
| Q3 | 8.33 − 25 | −0.2432 | 0.1401 | −1.735 | .191 |
| Q3 | 12.5 − 25 | +0.0999 | 0.0866 | +1.154 | .260 |
| Q4 | 8.33 − 12.5 | +0.0289 | 0.1238 | +0.233 | 1.000 |
| Q4 | 8.33 − 25 | +0.0834 | 0.1121 | +0.744 | 1.000 |
| Q4 | 12.5 − 25 | +0.0546 | 0.1027 | +0.531 | 1.000 |
| CL | 8.33 − 12.5 | −0.3141 | 0.1078 | −2.913 | .023 * |
| CL | 8.33 − 25 | −0.2563 | 0.1133 | −2.261 | .066 |
| CL | 12.5 − 25 | +0.0578 | 0.0829 | +0.697 | .492 |

#### Modulation Depth Contrasts

| DV | Contrast | Estimate | SE | t | p_Holm |
|----|----------|----------|----|----|--------|
| Q1 | 40% − 60% | +0.7885 | 0.0981 | +8.040 | <.001 *** |
| Q1 | 40% − 80% | +1.6265 | 0.1681 | +9.676 | <.001 *** |
| Q1 | 60% − 80% | +0.8380 | 0.1130 | +7.416 | <.001 *** |
| Q2 | 40% − 60% | −0.4346 | 0.0702 | −6.189 | <.001 *** |
| Q2 | 40% − 80% | −0.9833 | 0.1354 | −7.264 | <.001 *** |
| Q2 | 60% − 80% | −0.5486 | 0.1061 | −5.169 | <.001 *** |
| Q3 | 40% − 60% | −0.6085 | 0.0919 | −6.624 | <.001 *** |
| Q3 | 40% − 80% | −1.0294 | 0.1298 | −7.932 | <.001 *** |
| Q3 | 60% − 80% | −0.4209 | 0.1034 | −4.072 | <.001 *** |
| Q4 | 40% − 60% | +0.2615 | 0.0786 | +3.328 | .006 ** |
| Q4 | 40% − 80% | +0.4633 | 0.1167 | +3.969 | .002 ** |
| Q4 | 60% − 80% | +0.2018 | 0.0970 | +2.080 | .048 * |
| CL | 40% − 60% | −0.5216 | 0.0733 | −7.116 | <.001 *** |
| CL | 40% − 80% | −1.0063 | 0.1294 | −7.777 | <.001 *** |
| CL | 60% − 80% | −0.4848 | 0.1004 | −4.831 | <.001 *** |

### 4.6 CLMM Ordinal Robustness Note

*Source: 06_ratings_clmm.csv*  
Most CLMM fits produced degenerate solutions (extreme coefficient estimates ≥ 15 on log-odds scale, NA standard errors) due to near-complete separation in the ordinal response at extreme conditions. The one partially converged fit (Q2 step1_4freq, frequency12.5: β = 25.26, z = 2.28, p = .022) is directionally consistent with the RM-ANOVA. Primary inference rests on GG-corrected RM-ANOVA.

---

## 5. Eye-Tracking (Seven Metrics)

### 5.1 Step 1 — RM-ANOVA (4-level frequency)

*Source: 07_eye_step1_main.csv; GG-corrected*

| DV | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|----|---|--------|--------|-----|------|------|--------|
| dwell_ratio_cms | 0.397 | 1.84 | 44.21 | 32.896 | .658 | .016 | [.000, .125] |
| dwell_time_cms_ms | 0.623 | 1.96 | 47.06 | 1372482.0 | .537 | .025 | [.000, .142] |
| fixation_duration_cms_mean_ms | 1.076 | 1.42 | 34.10 | 29926.6 | .332 | .043 | [.000, .220] |
| fixation_duration_road_mean_ms | 0.124 | 2.22 | 53.30 | 7814.98 | .902 | .005 | [.000, .052] |
| transition_count | 0.158 | 2.09 | 50.12 | 1.929 | .862 | .007 | [.000, .069] |
| fixation_count_cms | 0.412 | 2.43 | 58.34 | 5.923 | .704 | .017 | [.000, .096] |
| fixation_count_road | 1.892 | 2.22 | 53.19 | 10.419 | .157 | .073 | [.000, .215] |

**All frequency effects non-significant (p = .157–.902).**

### 5.2 Step 1 — Planned Contrasts vs 0 Hz (Holm corrected)

*Source: 07_eye_step1_contrasts.csv; df = 24 for all*

| DV | Contrast | Estimate | SE | t | p_Holm |
|----|----------|----------|----|----|--------|
| dwell_ratio_cms | 8.33 − 0 | −1.013 | 1.469 | −0.690 | 1.000 |
| dwell_ratio_cms | 12.5 − 0 | −1.306 | 1.628 | −0.803 | 1.000 |
| dwell_ratio_cms | 25 − 0 | −0.944 | 1.637 | −0.577 | 1.000 |
| dwell_time_cms_ms | 8.33 − 0 | −294.98 | 302.73 | −0.974 | 1.000 |
| dwell_time_cms_ms | 12.5 − 0 | −334.55 | 340.22 | −0.983 | 1.000 |
| dwell_time_cms_ms | 25 − 0 | −229.04 | 338.47 | −0.677 | 1.000 |
| fixation_duration_cms_mean_ms | 8.33 − 0 | −50.68 | 43.89 | −1.155 | .666 |
| fixation_duration_cms_mean_ms | 12.5 − 0 | −52.69 | 42.03 | −1.254 | .666 |
| fixation_duration_cms_mean_ms | 25 − 0 | −42.39 | 46.89 | −0.904 | .666 |
| fixation_duration_road_mean_ms | 8.33 − 0 | −4.65 | 23.04 | −0.202 | 1.000 |
| fixation_duration_road_mean_ms | 12.5 − 0 | −12.95 | 23.48 | −0.552 | 1.000 |
| fixation_duration_road_mean_ms | 25 − 0 | −5.28 | 28.00 | −0.189 | 1.000 |
| transition_count | 8.33 − 0 | −0.187 | 0.343 | −0.544 | 1.000 |
| transition_count | 12.5 − 0 | +0.013 | 0.437 | +0.031 | 1.000 |
| transition_count | 25 − 0 | −0.084 | 0.369 | −0.229 | 1.000 |
| fixation_count_cms | 8.33 − 0 | −0.520 | 0.708 | −0.735 | 1.000 |
| fixation_count_cms | 12.5 − 0 | −0.622 | 0.697 | −0.893 | 1.000 |
| fixation_count_cms | 25 − 0 | −0.520 | 0.726 | −0.716 | 1.000 |
| fixation_count_road | 8.33 − 0 | +0.658 | 0.880 | +0.748 | .462 |
| fixation_count_road | 12.5 − 0 | +1.649 | 0.977 | +1.687 | .314 |
| fixation_count_road | 25 − 0 | +1.471 | 0.911 | +1.615 | .314 |

### 5.3 Step 2 — Two-way RM-ANOVA (3×3 flickering cells)

*Source: 07_eye_step2_main.csv; GG-corrected*

| DV | Effect | F | df_num | df_den | MSE | p_GG | η²_p | 95% CI |
|----|--------|---|--------|--------|-----|------|------|--------|
| dwell_ratio_cms | frequency | 0.101 | 1.92 | 46.15 | 28.746 | .898 | .004 | — |
| dwell_ratio_cms | depth | 4.102 | 1.83 | 43.93 | 26.496 | .026 * | .146 | [.000, .330] |
| dwell_ratio_cms | freq × depth | 0.782 | 2.80 | 67.31 | 33.966 | .500 | .032 | — |
| dwell_time_cms_ms | frequency | 0.157 | 1.86 | 44.68 | 1458815 | .841 | .007 | — |
| dwell_time_cms_ms | depth | 4.058 | 1.91 | 45.80 | 1368007 | .025 * | .145 | [.000, .324] |
| dwell_time_cms_ms | freq × depth | 0.379 | 2.80 | 67.13 | 1650033 | .754 | .016 | — |
| fixation_duration_cms_mean_ms | frequency | 0.194 | 1.54 | 36.97 | 14693.0 | .767 | .008 | — |
| fixation_duration_cms_mean_ms | depth | 0.114 | 1.60 | 38.46 | 8196.1 | .849 | .005 | — |
| fixation_duration_cms_mean_ms | freq × depth | 1.422 | 3.07 | 73.64 | 9104.2 | .243 | .056 | — |
| fixation_duration_road_mean_ms | frequency | 0.141 | 1.61 | 38.61 | 14149.0 | .824 | .006 | — |
| fixation_duration_road_mean_ms | depth | 1.094 | 1.43 | 34.36 | 9915.3 | .327 | .044 | — |
| fixation_duration_road_mean_ms | freq × depth | 0.708 | 2.85 | 68.35 | 12859.7 | .544 | .029 | — |
| transition_count | frequency | 0.299 | 1.88 | 45.17 | 2.662 | .730 | .012 | — |
| transition_count | depth | 1.023 | 1.86 | 44.76 | 4.156 | .363 | .041 | — |
| transition_count | freq × depth | 0.514 | 3.10 | 74.34 | 2.691 | .680 | .021 | — |
| fixation_count_cms | frequency | 0.026 | 1.85 | 44.37 | 10.687 | .967 | .001 | — |
| fixation_count_cms | depth | 1.696 | 1.72 | 41.36 | 9.170 | .199 | .066 | — |
| fixation_count_cms | freq × depth | 1.524 | 3.56 | 85.35 | 4.966 | .208 | .060 | — |
| fixation_count_road | frequency | 1.475 | 1.66 | 39.82 | 17.113 | .241 | .058 | — |
| fixation_count_road | depth | 3.346 | 1.93 | 46.34 | 14.961 | .046 * | .122 | [.000, .297] |
| fixation_count_road | freq × depth | 0.576 | 3.08 | 74.02 | 16.298 | .637 | .023 | — |

**Significant depth effects (Step 2): dwell_ratio_cms (p = .026), dwell_time_cms_ms (p = .025), fixation_count_road (p = .046).**  
**No frequency effects and no interactions significant.**

### 5.4 Step 2 — Significant Post-hoc Contrasts (Holm corrected)

*Source: 07_eye_step2_posthoc.csv; df = 24*

| DV | Factor | Contrast | Estimate | SE | t | p_Holm | Direction |
|----|--------|----------|----------|----|----|--------|-----------|
| dwell_ratio_cms | depth | 60% − 80% | −2.262 | 0.731 | −3.093 | .015 * | 80% > 60% dwell |
| dwell_time_cms_ms | depth | 60% − 80% | −530.400 | 171.556 | −3.092 | .015 * | 80% > 60% dwell |
| fixation_count_road | depth | 40% − 80% | +1.587 | 0.588 | +2.698 | .038 * | 40% > 80% road fixations |

All other depth and frequency contrasts for eye metrics were non-significant.

### 5.5 Count GLMMs

*Source: 07_eye_count_glmm.csv; reference category = 8.33 Hz / 40% depth*

| DV | Model | Overdispersion | All fixed terms sig? |
|----|-------|---------------|----------------------|
| transition_count | Poisson | 0.783 (< 1; underdispersed, Poisson acceptable) | No; all ns |
| fixation_count_cms | Poisson | 1.276 | No; all ns |
| fixation_count_road | Negative Binomial | 1.899 | No; all ns |

GLMM results fully consistent with RM-ANOVA null findings.

### 5.6 First-Fixation Two-Stage Analysis

**Stage 1 — Proportion first-fixating CMS** *(Source: 07_eye_firstfix_stage1_prop_by_freq.csv)*

| Frequency | n_trials | n_fixated | % fixated |
|-----------|----------|-----------|-----------|
| 0 Hz | 75 | 75 | 100.0 |
| 8.33 Hz | 225 | 224 | 99.6 |
| 12.5 Hz | 225 | 225 | 100.0 |
| 25 Hz | 225 | 225 | 100.0 |

Pooled: 749/750 = 99.87% → ceiling effect. Logistic GLMM is degenerate (near-perfect separation).

**Stage 2 — First-fixation latency RM-ANOVA (Step 1)** *(Source: 07_eye_firstfix_stage2_s1_main.csv)*

| Effect | F | df_num | df_den | MSE | p_GG | η²_p |
|--------|---|--------|--------|-----|------|------|
| frequency | 1.465 | 1.59 | 38.14 | 1626180 | .243 | .058 |

First-fixation latency unaffected by frequency.

---

## 6. Simulator Sickness (SSQ)

### 6.1 Pre/Post Paired Tests

*Source: 08_ssq_prepost_tests.csv; N = 25; Kennedy (1993) weights*

| Subscale | M_pre | M_post | M_Δ | SD_Δ | t | df | p_ttest | W | p_wilcox | Cohen's d |
|----------|-------|--------|-----|------|---|----|----|---|---------|-----------|
| Nausea (N) | 2.67 | 5.34 | +2.67 | 6.47 | 2.064 | 24 | .0500 | 45 | .0593 | 0.413 |
| Oculo-motor (O) | 6.97 | 17.89 | +10.92 | 18.05 | 3.023 | 24 | .0059 | 95 | .0081 | 0.605 |
| Total Severity (TS) | 5.39 | 13.76 | +8.38 | 13.37 | 3.134 | 24 | .0045 | 154 | .0030 | 0.627 |

**Significant post-experiment increases: Oculo-motor (p = .006, d = 0.61) and Total Severity (p = .005, d = 0.63). Nausea borderline (p = .050).**

### 6.2 Delta-SSQ Spearman Correlations with Behavioural DVs

*Source: 08_ssq_delta_correlations.csv; N = 25*

| SSQ Δ | Behaviour | ρ | p |
|-------|-----------|---|---|
| Δ_Nausea | mean_TTC | −0.152 | .468 |
| Δ_Nausea | mean_Q1 | −0.311 | .130 |
| Δ_Nausea | mean_dwell_ratio_cms | −0.134 | .522 |
| Δ_Oculo-motor | mean_TTC | +0.144 | .494 |
| Δ_Oculo-motor | mean_Q1 | −0.554 | .004 ** |
| Δ_Oculo-motor | mean_dwell_ratio_cms | −0.055 | .793 |
| Δ_Total Severity | mean_TTC | +0.100 | .633 |
| Δ_Total Severity | mean_Q1 | −0.536 | .006 ** |
| Δ_Total Severity | mean_dwell_ratio_cms | −0.009 | .965 |

**Greater oculomotor and total sickness severity post-session correlates with lower mean Q1 visual comfort (both p < .01), i.e., participants who experienced less visual comfort showed larger SSQ increases. No significant correlations with TTC or gaze allocation.**

---

## 7. Post-Experiment Questionnaire

*Source: 13_post_survey_descriptives.csv, 13_post_survey_frequencies.csv*  
*N = 25; all items 5-point or 6-point ordinal scales (Google Forms); administered once after full session.*

### 7.1 Descriptive Statistics

| Q | Question (short) | Scale | M | SD | Mdn | Mdn label | IQR |
|---|-----------------|-------|---|----|----|-----------|-----|
| Q1 | Lane-change difficulty | 6-pt (Easy→V.Difficult) | 3.68 | 1.41 | 4 | Somewhat difficult | [3, 5] |
| Q2 | Mental demand | 6-pt (Low→V.High) | 3.24 | 1.45 | 3 | Moderate | [2, 4] |
| Q3 | Effort exerted | 6-pt (Little→V.Much) | 3.20 | 1.47 | 3 | Moderate | [2, 4] |
| Q4 | Motion clarity (CMS) | 6-pt (V.Unclear→Clear) | 4.16 | 1.28 | 5 | Somewhat clear | [3, 5] |
| Q5 | Flicker interference | 5-pt (Slightly→Extremely) | 2.68 | 1.03 | 3 | Strongly | [2, 3] |
| Q6 | Visual discomfort | 5-pt (Hardly any→Severe) | 2.84 | 1.21 | 3 | Moderate | [2, 4] |
| Q7 | Decision confidence | 5-pt (Not at all→Confident) | 3.96 | 1.17 | 4 | Somewhat confident | [4, 5] |
| Q8 | Flicker noticeability | 4-pt (Slightly→Extremely) | 2.88 | 0.93 | 3 | Very noticeable | [2, 4] |
| Q9 | Flicker influence on decisions | 5-pt (Hardly→Significantly) | 3.40 | 1.38 | 4 | Strongly | [2, 5] |

### 7.2 Response Frequency Distributions

| Q | Category | n | % |
|---|----------|---|---|
| **Q1 Lane-change difficulty** | Easy | 3 | 12.0 |
| | Somewhat easy | 3 | 12.0 |
| | Neutral | 1 | 4.0 |
| | Somewhat difficult | 11 | 44.0 |
| | Difficult | 6 | 24.0 |
| | Very difficult | 1 | 4.0 |
| **Q2 Mental demand** | Low | 4 | 16.0 |
| | Somewhat low | 3 | 12.0 |
| | Moderate | 7 | 28.0 |
| | Somewhat high | 7 | 28.0 |
| | High | 2 | 8.0 |
| | Very high | 2 | 8.0 |
| **Q3 Effort exerted** | Little | 4 | 16.0 |
| | Somewhat little | 3 | 12.0 |
| | Moderate | 9 | 36.0 |
| | Somewhat much | 4 | 16.0 |
| | Much | 3 | 12.0 |
| | Very much | 2 | 8.0 |
| **Q4 Motion clarity** | Very unclear | 1 | 4.0 |
| | Unclear | 2 | 8.0 |
| | Somewhat unclear | 4 | 16.0 |
| | Neutral | 5 | 20.0 |
| | Somewhat clear | 11 | 44.0 |
| | Clear | 2 | 8.0 |
| **Q5 Flicker interference** | Slightly | 4 | 16.0 |
| | Moderately | 5 | 20.0 |
| | Strongly | 12 | 48.0 |
| | Very strongly | 3 | 12.0 |
| | Extremely | 1 | 4.0 |
| **Q6 Visual discomfort** | Hardly any | 5 | 20.0 |
| | Slightly | 4 | 16.0 |
| | Moderate | 7 | 28.0 |
| | Noticeable | 8 | 32.0 |
| | Severe | 1 | 4.0 |
| **Q7 Decision confidence** | Not confident at all | 1 | 4.0 |
| | Unconfident | 3 | 12.0 |
| | Neutral | 2 | 8.0 |
| | Somewhat confident | 9 | 36.0 |
| | Confident | 10 | 40.0 |
| **Q8 Flicker noticeability** | Slightly noticeable | 2 | 8.0 |
| | Noticeable | 6 | 24.0 |
| | Very noticeable | 10 | 40.0 |
| | Extremely noticeable | 7 | 28.0 |
| **Q9 Flicker influence** | Hardly at all | 3 | 12.0 |
| | Slightly | 4 | 16.0 |
| | Moderately | 5 | 20.0 |
| | Strongly | 6 | 24.0 |
| | Significantly | 7 | 28.0 |

### 7.3 Key Observations

**Task difficulty and workload:** The majority rated lane-change timing as ≥ "Somewhat difficult" (72%; Q1 Mdn = "Somewhat difficult"). Mental demand and effort were moderate on average (Q2–Q3 Mdn = "Moderate"), with wide individual spread (SD ≈ 1.5).

**CMS display clarity:** Most participants found the CMS motion display at least "Somewhat clear" (52%; Q4 Mdn = "Somewhat clear", M = 4.16/6). Notably, 28% rated it ≤ "Somewhat unclear" (including 4% "Very unclear"), suggesting a minority found the display ambiguous.

**Flicker effects:** 48% rated flicker interference as "Strongly" (Q5 modal response); 64% chose ≥ "Strongly". Flicker differences were highly noticeable: "Very noticeable" + "Extremely noticeable" = 68% (Q8). 52% rated flicker as having "Strongly" or "Significantly" influenced their decisions (Q9).

**Confidence:** Participants were generally confident — 76% chose ≥ "Somewhat confident" (Q7). Only 16% were "Unconfident" or "Not confident at all".

**Visual discomfort:** Moderate-to-noticeable; "Noticeable" (32%) + "Severe" (4%) = 36% reporting noticeable-or-above fatigue.

---

## 8. Sensitivity Analyses

### 7.1 P09/P15 Exclusion (Step 1 RM-ANOVA)

*Source: 09_sensitivity_summary.csv*

| DV | Subset | F | df_num | df_den | η²_p | p_GG |
|----|--------|---|--------|--------|------|------|
| TTC_s | full_sample | 5.094 | 1.83 | 43.91 | .175 | .0121 |
| TTC_s | excl_P09 | 4.858 | 1.83 | 42.15 | .174 | .0147 |
| TTC_s | excl_P15 | 6.157 | 1.98 | 45.60 | .211 | .0044 |
| TTC_s | excl_P09_P15 | 5.776 | 1.98 | 43.64 | .208 | .0061 |
| Q1 | full_sample | 54.133 | 1.52 | 36.57 | .693 | <.001 |
| Q1 | excl_P09 | 50.637 | 1.52 | 35.00 | .688 | <.001 |
| Q1 | excl_P15 | 50.158 | 1.58 | 36.35 | .686 | <.001 |
| Q1 | excl_P09_P15 | 46.603 | 1.58 | 34.71 | .679 | <.001 |

**TTC frequency effect significant in all exclusion sets (p range .004–.015, η²_p range .174–.211). Q1 fully robust.**

### 7.2 Scene LMM (flickering conditions; scene as crossed random intercept)

*Source: 09_scene_lmm.csv; Satterthwaite ddf*

| Effect | Sum Sq | Mean Sq | Num DF | Den DF | F | p |
|--------|--------|---------|--------|--------|---|---|
| frequency | 32.987 | 16.493 | 2 | 638 | 12.083 | <.001 |
| modulation_depth | 9.387 | 4.694 | 2 | 638 | 3.439 | .0327 |
| frequency × depth | 4.066 | 1.017 | 4 | 638 | 0.745 | .5618 |

**Frequency effect replicated (p = .001). Depth and interaction ns. Scene variation does not explain the TTC result.**

### 7.3 Complete-Ratings Comparison

*Source: 09_sensitivity_summary.csv*  
flag_missing_rating = 0 for all 750 observations → full-sample and complete-case analyses are identical.

| DV | Full-sample p | Complete-only p | Full η²_p | Complete-only η²_p |
|----|--------------|-----------------|-----------|-------------------|
| Q1 | <.001 | <.001 | .693 | .693 |
| Q2 | <.001 | <.001 | .544 | .544 |
| Q3 | <.001 | <.001 | .502 | .502 |
| Q4 | .012 | .012 | .193 | .193 |

### 7.4 Eye-Quality Stratification

*Source: 09_sensitivity_summary.csv; high_quality = flag_low_eye_quality == FALSE*

| DV | Sample | p_GG | η²_p |
|----|--------|------|------|
| dwell_ratio_cms | full_sample | .6581 | .016 |
| dwell_ratio_cms | high_quality | .4958 | .028 |
| transition_count | full_sample | .8624 | .007 |
| transition_count | high_quality | .8144 | .008 |

Null frequency effects on gaze allocation persist in the high-quality subsample.

---

## 8. Scene (A/B/C) Analysis

*Source: 11_scene_anova.R; Script: R/11_scene_anova.R*

### 8.1 Descriptive TTC by Scene

*Source: 11_scene_descriptives.csv; raw trial-level, all conditions combined*

| Scene | N | M (s) | SD | SE |
|-------|---|-------|----|----|
| A | 250 | 4.584 | 2.376 | 0.150 |
| B | 250 | 4.470 | 2.463 | 0.156 |
| C | 248 | 4.234 | 2.210 | 0.140 |

Scene C has the shortest TTC (most conservative timing); Scene A the longest.

### 8.2 Model 1 — TTC ~ Frequency × Scene (4×3 RM-ANOVA, GG-corrected)

*Source: 11_scene_anova_main.csv (Model = M1_freq_x_scene)*  
*Aggregate: participant × frequency × scene (mean over modulation depths)*  
*P03/P11 at 8.33 Hz × Scene C: mean computed from 40% and 80% depths only (no missing cell)*

| Effect | F | df (GG) | MSE | p_GG | η²_p | 95% CI |
|--------|---|---------|-----|------|------|--------|
| frequency | 5.113 | (1.83, 43.92) | 1.2367 | .0119 * | .176 | [.010, .363] |
| **scene** | **6.444** | **(1.97, 47.28)** | **0.8458** | **.0035 \*\*** | **.212** | **[.030, .393]** |
| frequency × scene | 2.340 | (4.38, 105.18) | 0.8527 | .0543 ns | .089 | [.000, .178] |

**Scene main effect significant**, F(1.97, 47.28) = 6.444, p = .0035, η²p = .212 (medium-large). Frequency × scene interaction marginal (p = .054, ns by α = .05).

### 8.3 Model 2 — TTC ~ Depth × Scene (3×3 RM-ANOVA, flickering only, GG-corrected)

*Source: 11_scene_anova_main.csv (Model = M2_depth_x_scene)*  
*Aggregate: participant × modulation_depth × scene (mean over flickering frequencies)*

| Effect | F | df (GG) | MSE | p_GG | η²_p | 95% CI |
|--------|---|---------|-----|------|------|--------|
| modulation_depth | 2.741 | (1.74, 41.78) | 0.6667 | .083 ns | .102 | [.000, .283] |
| scene | 2.739 | (1.91, 45.84) | 0.6519 | .078 ns | .102 | [.000, .273] |
| depth × scene | 1.377 | (2.99, 71.73) | 0.5404 | .257 ns | .054 | [.000, .156] |

When restricted to flickering conditions (averaging over frequency), the scene effect weakens and does not reach significance (p = .078). Neither depth × scene interaction is significant.

### 8.4 Model 3 — LMM: TTC ~ Frequency × Depth × Scene + (1 | Participant)

*Source: 11_scene_lmm.csv; trial-level flickering data (n = 673 trials); Satterthwaite df*  
*LMM used to handle P03/P11 missing cell at 8.33 Hz / 60% / Scene C*

| Effect | F | df (num, den) | p |
|--------|---|---------------|---|
| frequency | 12.139 | (2, 622) | < .001 *** |
| modulation_depth | 3.457 | (2, 622) | .032 * |
| **scene** | **3.592** | **(2, 622)** | **.028 \*** |
| frequency × modulation_depth | 0.741 | (4, 622) | .564 ns |
| **frequency × scene** | **2.513** | **(4, 622)** | **.041 \*** |
| modulation_depth × scene | 1.214 | (4, 622) | .304 ns |
| frequency × depth × scene | 0.366 | (8, 622) | .938 ns |

The LMM recovers a significant **frequency × scene** interaction (p = .041), confirming that scene differences vary across flickering frequency levels.

### 8.5 Scene Marginal Means (from M1)

*Source: 11_scene_emm.csv; averaged over 4 frequency levels*

| Scene | EMM (s) | SE | 95% CI |
|-------|---------|----|--------|
| A | 4.643 | 0.414 | [3.789, 5.496] |
| B | 4.495 | 0.440 | [3.587, 5.403] |
| C | 4.189 | 0.389 | [3.386, 4.991] |

### 8.6 Post-hoc: Bonferroni Pairwise t-tests between Scenes

*Source: 11_scene_posthoc_bonferroni.csv; 3 comparisons; Bonferroni α = 0.05/3 = 0.0167*

| Contrast | Δ (s) | SE | df | t | p (Bonferroni) | 95% CI | Sig |
|----------|-------|----|----|---|----------------|--------|-----|
| A − B | +0.148 | 0.134 | 24 | +1.101 | .845 | [−0.198, +0.493] | ns |
| **A − C** | **+0.454** | **0.121** | **24** | **+3.754** | **.003** | **[+0.143, +0.766]** | **\*\*** |
| B − C | +0.306 | 0.132 | 24 | +2.329 | .086 | [−0.032, +0.645] | ns |

**Only Scene A vs. Scene C survives Bonferroni correction.**  
Participants responded **0.454 s earlier** (shorter TTC) in Scene C than in Scene A (95% CI: [+0.143, +0.766] s, p_Bonf = .003). Scene B does not differ significantly from A or C after correction.

---

## Figures Confirmed (output/figures/ — 17 PNG at 300 DPI)

| Filename | Script | Content |
|----------|--------|---------|
| fig_qq_ttc.png | 10_plots FIG 1 | Q–Q plots for TTC residual normality by frequency condition |
| fig_resid_ttc.png | 10_plots FIG 2 | TTC RM-ANOVA residuals vs fitted + distribution |
| fig_outlier_ttc.png | 10_plots FIG 3 | TTC outlier-annotated boxplot (|z| > 3 labelled) |
| fig_ttc_box.png | 10_plots FIG 4 | TTC distribution across 10 conditions (boxplot + jitter) |
| fig_ttc_interaction.png | 10_plots FIG 5 | TTC freq × depth interaction line plot + 0 Hz baseline |
| fig_ttc_spaghetti.png | 10_plots FIG 6 | Individual participant TTC trajectories across frequency |
| fig_ratings_bar.png | 10_plots FIG 7 | Q1–Q4 EMMs by frequency (original scale directions) |
| fig_ratings_likert.png | 10_plots FIG 8 | Likert response distributions (stacked bar) by condition |
| fig_ratings_heatmap.png | 10_plots FIG 9 | Q1–Q4 means as 10×4 heatmap (original scale directions) |
| fig_eye_dwell.png | 10_plots FIG 10 | CMS vs Road vs Other dwell allocation by condition |
| fig_eye_interaction.png | 10_plots FIG 11 | Transition count & fixation duration EMMs by frequency |
| fig_eye_firstfix.png | 10_plots FIG 12 | First-fixation proportion (Stage 1) and latency (Stage 2) |
| fig_ssq_prepost.png | 10_plots FIG 13 | SSQ subscale scores pre vs post (spaghetti + mean) |
| fig_effectsize_forest.png | 10_plots FIG 14 | Forest plot of η²_p [95% CI] for frequency effect across all DVs |
| fig_ratings_unified_emm.png | 10b FIG A | Q1–Q4 Step-1 EMMs, unified negative direction (higher = worse) |
| fig_ratings_unified_heatmap.png | 10b FIG B | 10-condition × 4-DV heatmap, unified direction |
| fig_ratings_unified_depth.png | 10b FIG C | Modulation depth gradient for all 4 DVs, unified direction |

---

## Section 9 — ANCOVA: Individual Driving Tendencies as Covariates

**Research question:** Does self-reported driving confidence during the experiment (Post-Experiment Q7) or real-life driving style (background questionnaire) account for individual differences in TTC judgement, and do they improve model fit?

**Script:** `R/12_ancova_covariates.R`

### 9.1 Covariates

| Covariate | Source | Scale | Encoding |
|-----------|--------|-------|----------|
| `exp_confidence` | Post-Experiment Q7: "How confident or certain were you in the decisions you made during the experiment overall?" | 5-point ordinal | Not confident at all=1, Unconfident=2, Neutral=3, Somewhat confident=4, Confident=5 |
| `driving_style` | Background questionnaire Q8 | 5-point ordinal | Very cautious=1, Cautious=2, Balanced=3, Confident=4, Very confident=5 |

**Distribution:**

exp_confidence — N per level: Not confident at all=1, Unconfident=3, Neutral=2, Somewhat confident=9, Confident=10

driving_style — N per level: Very cautious=4, Cautious=4, Balanced=13, Confident=3, Very confident=1

### 9.2 Between-Subjects Regression (participant mean TTC ~ covariate)

| Covariate | β | SE | t | p | R² |
|-----------|---|----|---|---|----|
| exp_confidence | 0.127 | 0.362 | 0.351 | .729 | .005 |
| driving_style | 0.214 | 0.414 | 0.516 | .611 | .011 |
| Both combined | — | — | — | — | .019 |

Neither covariate significantly predicts participant-level mean TTC. Combined R² = .019 (both covariates explain only 1.9% of between-subject variance in mean TTC).

### 9.3 LMM Model Comparison (LRT, ML estimation)

Base model: `TTC ~ frequency + (1|participant_id)`

| Model | ΔAIC vs base | Δχ²(df) | p |
|-------|-------------|---------|---|
| + exp_confidence | +1.87 | 0.13 (1) | .715 ns |
| + driving_style | +1.72 | 0.29 (1) | .592 ns |
| + both covariates | +3.53 | 0.47 (2) | .789 ns |

AIC **increases** in all extended models (penalised for extra parameters without commensurate fit improvement). LRT non-significant in all cases. **Neither covariate improves model fit.**

### 9.4 Fixed-Effect Coefficients (REML, both-covariates model)

| Term | Estimate | SE | df | t | p |
|------|----------|----|----|---|---|
| (Intercept) | 3.285 | 2.013 | 22.08 | 1.632 | .117 |
| frequency 8.33 Hz | −0.217 | 0.142 | 72 | −1.532 | .130 |
| frequency 12.5 Hz | −0.285 | 0.142 | 72 | −2.010 | .048* |
| frequency 25 Hz | +0.214 | 0.142 | 72 | +1.512 | .135 |
| exp_confidence | 0.150 | 0.370 | 22 | 0.406 | .689 ns |
| driving_style | 0.233 | 0.424 | 22 | 0.550 | .588 ns |

### 9.5 Moderation Test (frequency × covariate interaction)

| Interaction | Δχ²(3) | p |
|-------------|--------|---|
| frequency × exp_confidence | 0.889 | .828 ns |
| frequency × driving_style | 6.603 | .086 (trend only) |

Neither covariate significantly moderates the frequency effect on TTC. The driving_style × frequency interaction shows a marginal trend (p = .086) but does not reach α = .05.

### 9.6 Between-Subject Variance Explained

Baseline ICC = **0.942** — 94.2% of total TTC variance is attributable to stable between-subject differences, reflecting large individual variability in TTC judgement.

| Model | Participant random-effect variance | % between-subject variance reduced |
|-------|-----------------------------------|-------------------------------------|
| Base | 3.932 | — |
| + exp_confidence | 3.911 | 0.5% |
| + driving_style | 3.886 | 1.2% |
| + both | 3.857 | 1.9% |

Both covariates together account for only **1.9%** of the large between-subject variance in TTC.

### 9.7 Conclusion

Neither self-reported experimental decision confidence (Post-Experiment Q7) nor habitual real-life driving style accounts for meaningful individual differences in TTC judgement. Adding either or both covariates does not improve model fit (all ΔAIC > 0, all LRT p > .59). The driving style × frequency interaction is non-significant (p = .086). These null results suggest that TTC individual differences in this experiment are driven by other unmeasured factors (e.g., perceptual sensitivity, speed/distance estimation ability, risk threshold), not by self-categorised driving disposition or task-specific confidence.

**Implication for reporting:** The main frequency effect on TTC is robust to controlling for these individual-difference covariates. The covariate analysis can be reported as a sensitivity/robustness check confirming that the frequency effect is not confounded by driving style or task confidence.

**Output CSVs:** `12_ancova_model_fit.csv`, `12_ancova_bs_regression.csv`, `12_ancova_lmm_fixed.csv`, `12_ancova_variance_components.csv`, `12_ancova_covariate_desc.csv`

---

## CSV Catalog (output/tables/ — 57 files)

| Filename | Content |
|----------|---------|
| 01_filename_decode_check.csv | Input file inventory and parse verification |
| 02_flag_summary.csv | Count/% of each data quality flag; participant list |
| 03_participant_characteristics.csv | Age, gender, license years, occupation, annual km, commercial transport exp, driving style, flicker sensitivity, CMS experience per participant (15 columns) |
| 03_descriptives_ttc.csv | TTC M/SD/median/IQR per 10 conditions (n=75) |
| 03_descriptives_ratings.csv | Q1–Q4 M/SD per 10 conditions |
| 03_descriptives_eye.csv | 7 eye metrics + valid_ratio M/SD per 10 conditions |
| 03_descriptives_firstfix_stage1_prop.csv | First-fixation CMS proportion by full condition cross-tab |
| 03_descriptives_firstfix_stage2_latency.csv | First-fixation latency M/SD by condition |
| 04_assumption_checks.csv | SW normality, Mauchly W, GG ε, n extreme for all DVs × both ANOVA steps |
| 05_anova_ttc_step1_main.csv | TTC Step 1 RM-ANOVA (F, GG-df, p, η²_p, 95% CI) |
| 05_anova_ttc_step1_emm.csv | TTC Step 1 estimated marginal means by frequency |
| 05_anova_ttc_step1_contrasts.csv | TTC planned contrasts vs 0 Hz (Holm) |
| 05_anova_ttc_step2_main.csv | TTC Step 2 (3×3) RM-ANOVA |
| 05_anova_ttc_step2_posthoc.csv | TTC Step 2 pairwise post-hoc (Holm) |
| 05_anova_ttc_lmm_anova.csv | TTC LMM ANOVA table (with scene random intercept) |
| 05_anova_ttc_lmm_fixed.csv | TTC LMM fixed effects coefficient estimates |
| 06_ratings_step1_main.csv | Ratings Step 1 RM-ANOVA (Q1–Q4, cognitive_load) |
| 06_ratings_step1_emm.csv | Ratings Step 1 EMMs by frequency |
| 06_ratings_step1_contrasts.csv | Ratings planned contrasts vs 0 Hz (Holm) |
| 06_ratings_step2_main.csv | Ratings Step 2 (3×3) RM-ANOVA |
| 06_ratings_step2_posthoc.csv | Ratings Step 2 pairwise post-hoc (Holm) |
| 06_ratings_clmm.csv | Cumulative Link Mixed Model (ordinal robustness check) |
| 06_ratings_q2q3_consistency.csv | Q2–Q3 internal consistency |
| 06_ratings_summary.csv | Compact ratings summary table |
| 07_eye_step1_main.csv | Eye Step 1 RM-ANOVA (7 metrics) |
| 07_eye_step1_emm.csv | Eye Step 1 EMMs by frequency |
| 07_eye_step1_contrasts.csv | Eye planned contrasts vs 0 Hz (Holm) |
| 07_eye_step2_main.csv | Eye Step 2 (3×3) RM-ANOVA |
| 07_eye_step2_posthoc.csv | Eye Step 2 pairwise post-hoc (Holm) |
| 07_eye_count_glmm.csv | Poisson / NB GLMM for count-type eye metrics |
| 07_eye_firstfix_stage1_prop_by_freq.csv | First-fixation CMS proportion by frequency level |
| 07_eye_firstfix_stage1_prop_full.csv | First-fixation CMS proportion full cross-tab |
| 07_eye_firstfix_stage1_logit.csv | Logistic GLMM for first-fixation CMS (degenerate — ceiling) |
| 07_eye_firstfix_stage2_s1_main.csv | First-fixation latency Step 1 RM-ANOVA |
| 07_eye_firstfix_stage2_s1_emm.csv | First-fixation latency Step 1 EMMs |
| 07_eye_firstfix_stage2_s1_contrasts.csv | First-fixation latency vs 0 Hz contrasts |
| 07_eye_firstfix_stage2_s2_main.csv | First-fixation latency Step 2 RM-ANOVA |
| 07_eye_quality_sensitivity.csv | Eye metrics: full sample vs high-quality subsample |
| 07_eye_summary.csv | Compact eye metrics summary |
| 07_eye_pupil_caveat.csv | Pupil analysis: luminance confound caveat note |
| 08_ssq_scores.csv | Individual Kennedy (1993) scores per participant (pre/post) |
| 08_ssq_prepost_tests.csv | Paired t-test + Wilcoxon + Cohen's d per SSQ subscale |
| 08_ssq_delta_correlations.csv | Δ-SSQ Spearman correlations vs TTC / Q1 / dwell_ratio |
| 09_sensitivity_summary.csv | All sensitivity subset comparisons (P09/P15 excl, complete-case, eye-QA) |
| 09_scene_lmm.csv | TTC LMM with scene random intercept (flickering conditions) |
| 10b_ratings_unified_descriptives.csv | Unified-direction descriptive table (wide, M(SD)); Q1→Discomfort, Q4→Uncertainty |
| 10b_ratings_unified_descriptives_long.csv | Unified-direction descriptive table (long format, all stats) |
| 11_scene_anova_main.csv | Scene M1 (4×3) and M2 (3×3) RM-ANOVA — F, GG-df, p, η²p, 95% CI |
| 11_scene_lmm.csv | Scene M3 LMM type-III ANOVA table (freq × depth × scene) |
| 11_scene_emm.csv | Scene marginal means from M1 (emmean, SE, df, 95% CI per scene) |
| 11_scene_posthoc_bonferroni.csv | Bonferroni pairwise post-hoc: A−B, A−C, B−C (estimate, t, p, mean diff in s) |
| 11_scene_descriptives.csv | Raw TTC descriptive statistics by scene (N, M, SD, SE) |
| 12_ancova_model_fit.csv | AIC/BIC/logLik/ΔAIC for base vs covariate-extended LMMs |
| 12_ancova_bs_regression.csv | Between-subjects regression: participant mean TTC ~ exp_confidence / driving_style |
| 12_ancova_lmm_fixed.csv | REML fixed-effect coefficients from both-covariates LMM |
| 12_ancova_variance_components.csv | Random-effect variance and ICC per model; % between-subject variance explained |
| 12_ancova_covariate_desc.csv | Mean TTC by exp_confidence level and by driving_style level |
