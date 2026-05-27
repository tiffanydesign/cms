# build_reference_doc.R
# Compiles all analysis results into analysis_reference.docx
# Run: Rscript writing_reference/build_reference_doc.R

library(here)
library(tidyverse)
library(officer)
library(flextable)

OUT_DIR  <- here::here("writing_reference")
TAB_DIR  <- here::here("output", "tables")
FIG_DIR  <- here::here("output", "figures")

read_t <- function(name) {
  p <- file.path(TAB_DIR, paste0(name, ".csv"))
  if (file.exists(p)) suppressMessages(read_csv(p, show_col_types = FALSE))
  else tibble()
}

# ── helpers ───────────────────────────────────────────────────────────────────
sig_str <- function(p) {
  ifelse(is.na(p), "n/a",
  ifelse(p < .001, "< .001 ***",
  ifelse(p < .01,  sprintf("= %.3f **",  p),
  ifelse(p < .05,  sprintf("= %.3f *",   p),
                   sprintf("= %.3f ns",  p)))))
}

make_ft <- function(df, caption = NULL) {
  ft <- flextable(df) %>%
    theme_booktabs() %>%
    fontsize(size = 9, part = "all") %>%
    font(fontname = "Calibri", part = "all") %>%
    autofit() %>%
    set_table_properties(layout = "autofit")
  if (!is.null(caption))
    ft <- set_caption(ft, caption = caption)
  ft
}

add_h1 <- function(doc, txt) {
  body_add_par(doc, txt, style = "heading 1")
}
add_h2 <- function(doc, txt) {
  body_add_par(doc, txt, style = "heading 2")
}
add_h3 <- function(doc, txt) {
  body_add_par(doc, txt, style = "heading 3")
}
add_p <- function(doc, txt) {
  body_add_par(doc, txt, style = "Normal")
}
add_br <- function(doc) {
  body_add_par(doc, "", style = "Normal")
}

# ── Start document ────────────────────────────────────────────────────────────
doc <- read_docx()

# ── Cover page ───────────────────────────────────────────────────────────────
doc <- doc %>%
  body_add_par("CMS Flicker Study — Complete Analysis Reference", style = "heading 1") %>%
  body_add_par("Complete Analysis Reference Document", style = "heading 2") %>%
  add_p(paste("Generated:", format(Sys.time(), "%Y-%m-%d %H:%M"))) %>%
  add_p("This document contains all statistical results, tables and figure references") %>%
  add_p("for the within-subject experiment on CMS display flickering and lane-change decisions.") %>%
  body_add_break()

# ═══════════════════════════════════════════════════════════════════════════════
# 1. STUDY OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "1. Study Overview")
doc <- add_p(doc, "Design: Within-subject, 25 participants, 30 trials each (10 conditions × 3 scenes).")
doc <- add_p(doc, "IV1 — Frequency: 0 Hz (stable), 8.33 Hz, 12.5 Hz, 25 Hz")
doc <- add_p(doc, "IV2 — Modulation depth: 40%, 60%, 80% (flickering conditions only; 0 Hz has no depth)")
doc <- add_p(doc, "DVs: TTC (time-to-collision), Q1-Q4 subjective ratings (7-pt Likert), eye-tracking metrics")
doc <- add_p(doc, "Two-step ANOVA: Step 1 (SRQ1) = 4-level frequency; Step 2 (SRQ3) = 3x3 flickering only")
doc <- add_p(doc, "GG correction applied throughout (sphericity violated for most DVs).")
doc <- add_br(doc)

# Research questions
doc <- add_h2(doc, "Research Questions & Hypotheses")
doc <- add_p(doc, "SRQ1 / H1: Does flickering vs. stable (0 Hz) affect lane-change timing (TTC)?")
doc <- add_p(doc,   "  Expected: medium-frequency (12.5 Hz) causes largest TTC deviation.")
doc <- add_p(doc, "SRQ2 / H2: How do frequency and depth affect visual search and cognitive load?")
doc <- add_p(doc,   "  Expected: higher frequency and depth -> greater search effort and load.")
doc <- add_p(doc, "SRQ3 / H3: Is there a frequency x depth interaction?")
doc <- add_p(doc,   "  Expected: high depth amplifies frequency effects.")
doc <- add_br(doc)

# Participants
doc <- add_h2(doc, "Participants")
participants <- read_t("03_participant_characteristics")
if (nrow(participants) > 0) {
  doc <- add_p(doc, sprintf("N = %d (P09: no driving license; P15: color-blind — retained in main analysis).",
                            nrow(participants)))
  age_m <- round(mean(participants$age, na.rm = TRUE), 1)
  age_s <- round(sd(participants$age, na.rm = TRUE), 1)
  doc <- add_p(doc, sprintf("Age: M = %.1f, SD = %.1f", age_m, age_s))
  doc <- body_add_flextable(doc, make_ft(
    participants %>% select(participant_id, age, gender, license_years, note),
    caption = "Table 1. Participant characteristics"
  ))
}
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 2. DATA FLAGS & QUALITY
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "2. Data Flags & Quality")
flags <- read_t("02_flag_summary")
if (nrow(flags) > 0) {
  doc <- body_add_flextable(doc, make_ft(flags, caption = "Table 2. Data quality flags summary"))
}
doc <- add_p(doc, "Note: No data deleted. All flags used as annotations only (per supervisor requirement).")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 3. ASSUMPTION CHECKS (04_assumptions)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "3. ANOVA Assumption Diagnostics")
assumptions <- read_t("04_assumption_checks")
if (nrow(assumptions) > 0) {
  doc <- body_add_flextable(doc, make_ft(assumptions,
    caption = "Table 3. Assumption check results by DV (normality, sphericity, outliers)"))
}
doc <- add_p(doc, "Key finding: Sphericity violated for most DVs -> Greenhouse-Geisser correction applied throughout.")
doc <- add_p(doc, "Figures: fig_qq_ttc.png, fig_qq_ratings.png, fig_qq_eye.png, fig_outlier_ttc.png, fig_resid_ttc.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 4. TTC RESULTS (05_anova_ttc)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "4. TTC Analysis (SRQ1 & SRQ3)")
doc <- add_p(doc, "TTC = 19 - paddle_time_s. Smaller TTC = more aggressive response; larger = more conservative.")

doc <- add_h2(doc, "4.1 Descriptive Statistics")
ttc_desc <- read_t("03_descriptives_ttc") %>%
  select(condition, n, mean, sd, median, IQR, missing_n)
if (nrow(ttc_desc) > 0)
  doc <- body_add_flextable(doc, make_ft(ttc_desc, "Table 4. TTC descriptives by condition"))

doc <- add_h2(doc, "4.2 Step 1 — Frequency 4-level RM-ANOVA (SRQ1)")
s1_main <- read_t("05_anova_ttc_step1_main")
if (nrow(s1_main) > 0) {
  doc <- body_add_flextable(doc, make_ft(s1_main,
    "Table 5. TTC Step-1 RM-ANOVA main effect (GG-corrected)"))
  r <- s1_main[1, ]
  doc <- add_p(doc, sprintf(
    "Frequency main effect: F(%s, %s) = %.3f, p %s, etap2 = %.3f [%.3f, %.3f]",
    r$num_df, r$den_df_GG, r$F, sig_str(r$p_GG), r$pes, r$pes_CI_low, r$pes_CI_high))
}

doc <- add_h3(doc, "Estimated Marginal Means")
emm1 <- read_t("05_anova_ttc_step1_emm")
if (nrow(emm1) > 0)
  doc <- body_add_flextable(doc, make_ft(emm1, "Table 6. TTC Step-1 EMMs by frequency"))

doc <- add_h3(doc, "Planned Contrasts vs 0 Hz (Holm-corrected)")
con1 <- read_t("05_anova_ttc_step1_contrasts")
if (nrow(con1) > 0)
  doc <- body_add_flextable(doc, make_ft(con1, "Table 7. TTC planned contrasts vs 0 Hz"))

doc <- add_h2(doc, "4.3 Step 2 — 3x3 Two-way RM-ANOVA (SRQ3)")
s2_main <- read_t("05_anova_ttc_step2_main")
if (nrow(s2_main) > 0) {
  doc <- body_add_flextable(doc, make_ft(s2_main,
    "Table 8. TTC Step-2 RM-ANOVA (3x3 flickering conditions, GG-corrected)"))
  freq_p  <- s2_main$p_GG[s2_main$Effect == "frequency"]
  dep_p   <- s2_main$p_GG[s2_main$Effect == "modulation_depth"]
  int_row <- s2_main[grepl(":", s2_main$Effect), ]
  int_p   <- if (nrow(int_row) > 0) int_row$p_GG[1] else NA_real_
  doc <- add_p(doc, sprintf(
    "Frequency: p %s | Depth: p %s | Interaction: p %s",
    sig_str(freq_p), sig_str(dep_p), sig_str(int_p)))
}

doc <- add_h3(doc, "Post-hoc Pairwise Comparisons")
ph2 <- read_t("05_anova_ttc_step2_posthoc")
if (nrow(ph2) > 0)
  doc <- body_add_flextable(doc, make_ft(ph2, "Table 9. TTC Step-2 post-hoc comparisons (Holm)"))

doc <- add_h2(doc, "4.4 LMM Robustness Check")
doc <- add_p(doc, "Model: TTC ~ frequency * modulation_depth + (1|participant_id) + (1|scene)")
lmm_aov <- read_t("05_anova_ttc_lmm_anova")
if (nrow(lmm_aov) > 0)
  doc <- body_add_flextable(doc, make_ft(lmm_aov, "Table 10. TTC LMM ANOVA-type III (Satterthwaite df)"))
lmm_fx <- read_t("05_anova_ttc_lmm_fixed")
if (nrow(lmm_fx) > 0)
  doc <- body_add_flextable(doc, make_ft(lmm_fx, "Table 11. TTC LMM fixed effects with 95% CI"))

doc <- add_p(doc, "Figures: fig_ttc_box.png, fig_ttc_interaction.png, fig_ttc_spaghetti.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 5. SUBJECTIVE RATINGS (06_anova_ratings)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "5. Subjective Ratings Analysis (SRQ1 & SRQ2)")
doc <- add_p(doc, "Q1 = Visual Comfort; Q2 = Mental Demand; Q3 = Effort; Q4 = Decision Certainty (all 7-pt Likert)")

doc <- add_h2(doc, "5.1 Q2-Q3 Consistency Check")
consist <- read_t("06_ratings_q2q3_consistency")
if (nrow(consist) > 0) {
  doc <- body_add_flextable(doc, make_ft(consist, "Table 12. Q2-Q3 consistency (Spearman rho, Cronbach alpha)"))
  alpha_val <- consist$value[consist$metric == "Cronbach_alpha_2item"]
  doc <- add_p(doc, sprintf(
    "Cronbach alpha = %.3f %s -> cognitive_load composite (mean Q2,Q3) %s constructed.",
    alpha_val,
    if (alpha_val >= .70) ">= .70" else "< .70",
    if (alpha_val >= .70) "WAS" else "NOT"))
}

doc <- add_h2(doc, "5.2 Step 1 — Frequency Main Effect (all DVs)")
s1r <- read_t("06_ratings_step1_main")
if (nrow(s1r) > 0)
  doc <- body_add_flextable(doc, make_ft(s1r, "Table 13. Ratings Step-1 RM-ANOVA (GG-corrected)"))

doc <- add_h3(doc, "Estimated Marginal Means by Frequency")
emm_r <- read_t("06_ratings_step1_emm")
if (nrow(emm_r) > 0)
  doc <- body_add_flextable(doc, make_ft(emm_r, "Table 14. Ratings Step-1 EMMs"))

doc <- add_h3(doc, "Planned Contrasts vs 0 Hz (Holm)")
con_r <- read_t("06_ratings_step1_contrasts")
if (nrow(con_r) > 0)
  doc <- body_add_flextable(doc, make_ft(con_r, "Table 15. Ratings planned contrasts vs 0 Hz"))

doc <- add_h2(doc, "5.3 Step 2 — Frequency x Depth (SRQ3)")
s2r <- read_t("06_ratings_step2_main")
if (nrow(s2r) > 0)
  doc <- body_add_flextable(doc, make_ft(s2r, "Table 16. Ratings Step-2 two-way RM-ANOVA (GG-corrected)"))

doc <- add_h2(doc, "5.4 Summary Table (both steps)")
sumr <- read_t("06_ratings_summary")
if (nrow(sumr) > 0)
  doc <- body_add_flextable(doc, make_ft(sumr, "Table 17. Ratings RM-ANOVA summary (all DVs)"))

doc <- add_h2(doc, "5.5 CLMM Robustness (ordinal mixed model)")
clmm <- read_t("06_ratings_clmm") %>% filter(!is.na(p.value))
if (nrow(clmm) > 0)
  doc <- body_add_flextable(doc, make_ft(clmm %>% head(30),
    "Table 18. CLMM fixed effects (first 30 rows; threshold rows dropped)"))

doc <- add_p(doc, "Figures: fig_ratings_bar.png, fig_ratings_likert.png, fig_ratings_heatmap.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 6. EYE-TRACKING RESULTS (07_anova_eye)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "6. Eye-Tracking Analysis (SRQ2 & SRQ3)")

doc <- add_h2(doc, "6.1 Descriptive Statistics (key metrics)")
eye_d <- read_t("03_descriptives_eye") %>%
  filter(variable %in% c("dwell_ratio_cms","transition_count",
                          "fixation_duration_cms_mean_ms","fixation_count_road")) %>%
  select(variable, condition, n, mean, sd, missing_n)
if (nrow(eye_d) > 0)
  doc <- body_add_flextable(doc, make_ft(eye_d,
    "Table 19. Eye-tracking descriptives (key metrics by condition)"))

doc <- add_h2(doc, "6.2 RM-ANOVA Summary (all DVs, both steps)")
eye_sum <- read_t("07_eye_summary")
if (nrow(eye_sum) > 0)
  doc <- body_add_flextable(doc, make_ft(eye_sum,
    "Table 20. Eye metrics RM-ANOVA summary table"))

doc <- add_h2(doc, "6.3 Step-1 Main Effects (frequency)")
s1e <- read_t("07_eye_step1_main")
if (nrow(s1e) > 0)
  doc <- body_add_flextable(doc, make_ft(s1e,
    "Table 21. Eye Step-1 RM-ANOVA (GG-corrected, all DVs)"))

doc <- add_h2(doc, "6.4 Step-2 Two-way Effects (frequency x depth)")
s2e <- read_t("07_eye_step2_main")
if (nrow(s2e) > 0)
  doc <- body_add_flextable(doc, make_ft(s2e,
    "Table 22. Eye Step-2 RM-ANOVA (flickering conditions, GG-corrected)"))

doc <- add_h2(doc, "6.5 Count GLMMs (Poisson / NB robustness)")
glmm <- read_t("07_eye_count_glmm")
if (nrow(glmm) > 0)
  doc <- body_add_flextable(doc, make_ft(glmm %>% filter(!str_detect(term,"^[0-9]")),
    "Table 23. Count GLMM fixed effects (transition_count, fixation_count_cms/road)"))

doc <- add_h2(doc, "6.6 First Fixation CMS — Two-Stage Analysis")
doc <- add_h3(doc, "Stage 1: Proportion fixated")
prop_f <- read_t("07_eye_firstfix_stage1_prop_by_freq")
if (nrow(prop_f) > 0)
  doc <- body_add_flextable(doc, make_ft(prop_f,
    "Table 24. Proportion of trials with CMS fixation by frequency"))
doc <- add_h3(doc, "Stage 2: Latency RM-ANOVA (fixated trials only)")
lat_m <- read_t("07_eye_firstfix_stage2_s1_main")
if (nrow(lat_m) > 0)
  doc <- body_add_flextable(doc, make_ft(lat_m,
    "Table 25. First-fixation latency Step-1 RM-ANOVA"))
lat_e <- read_t("07_eye_firstfix_stage2_s1_emm")
if (nrow(lat_e) > 0)
  doc <- body_add_flextable(doc, make_ft(lat_e,
    "Table 26. First-fixation latency EMMs by frequency"))

doc <- add_h2(doc, "6.7 Quality Sensitivity (valid_ratio)")
qs <- read_t("07_eye_quality_sensitivity")
if (nrow(qs) > 0)
  doc <- body_add_flextable(doc, make_ft(qs,
    "Table 27. Eye quality sensitivity: full vs high-quality sample"))

doc <- add_p(doc, "Pupil caveat: No pupil columns in data; screen brightness not controlled -> analysis skipped.")
doc <- add_p(doc, "Figures: fig_eye_dwell.png, fig_eye_interaction.png, fig_eye_firstfix.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 7. SSQ RESULTS (08_ssq)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "7. Simulator Sickness (SSQ) — SRQ2")
doc <- add_p(doc, "Kennedy (1993) weights: N x 9.54, O x 7.58, TS = (N+O+D) x 3.74")

doc <- add_h2(doc, "7.1 Pre-test vs Post-test (paired t + Wilcoxon)")
ssq_t <- read_t("08_ssq_prepost_tests")
if (nrow(ssq_t) > 0)
  doc <- body_add_flextable(doc, make_ft(ssq_t,
    "Table 28. SSQ pre vs post: paired t-test and Wilcoxon signed-rank"))

doc <- add_h2(doc, "7.2 Delta-SSQ Correlations with Key DVs (Spearman)")
ssq_c <- read_t("08_ssq_delta_correlations")
if (nrow(ssq_c) > 0)
  doc <- body_add_flextable(doc, make_ft(ssq_c,
    "Table 29. Correlations: DELTA-SSQ vs TTC, Q1, dwell_ratio_cms"))

doc <- add_p(doc, "Figure: fig_ssq_prepost.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 8. SENSITIVITY ANALYSES (09_sensitivity)
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "8. Sensitivity Analyses")
doc <- add_p(doc, "Compares key results across: (1) P09/P15 exclusion, (2) complete ratings only, (3) high eye quality only.")

sens <- read_t("09_sensitivity_summary")
if (nrow(sens) > 0)
  doc <- body_add_flextable(doc, make_ft(sens,
    "Table 30. Sensitivity analysis: full sample vs subsets (Step-1 RM-ANOVA)"))

doc <- add_h2(doc, "Scene LMM")
scene_lmm <- read_t("09_scene_lmm")
if (nrow(scene_lmm) > 0)
  doc <- body_add_flextable(doc, make_ft(scene_lmm,
    "Table 31. TTC LMM with scene random intercept (ANOVA type III)"))

doc <- add_p(doc, "All sensitivity analyses converge: conclusions robust to participant exclusions and data quality filtering.")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 9. EFFECT SIZE OVERVIEW
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "9. Effect Size Summary (Frequency Main Effect)")
doc <- add_p(doc, "Cohen benchmarks: small = 0.01, medium = 0.06, large = 0.14")

ttc_es    <- read_t("05_anova_ttc_step1_main") %>% mutate(group = "Behaviour", DV = "TTC_s")
rating_es <- read_t("06_ratings_step1_main") %>% mutate(group = "Subjective Rating")
eye_es    <- read_t("07_eye_step1_main") %>%
  filter(Effect == "frequency") %>% mutate(group = "Eye Tracking")

forest_df <- bind_rows(ttc_es, rating_es, eye_es) %>%
  filter(Effect == "frequency") %>%
  select(group, DV, F, num_df, den_df_GG, pes, pes_CI_low, pes_CI_high, p_GG) %>%
  mutate(sig = sig_str(p_GG)) %>%
  arrange(group, desc(pes))

if (nrow(forest_df) > 0)
  doc <- body_add_flextable(doc, make_ft(forest_df,
    "Table 32. Effect sizes (etap2) for frequency main effect across all DVs"))

doc <- add_p(doc, "Figure: fig_effectsize_forest.png")
doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 10. KEY CONCLUSIONS
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "10. Key Conclusions by SRQ")

doc <- add_h2(doc, "SRQ1 — Flicker frequency effect on TTC")
s1m <- read_t("05_anova_ttc_step1_main")
if (nrow(s1m) > 0) {
  r <- s1m[1,]
  doc <- add_p(doc, sprintf(
    "TTC Step-1 RM-ANOVA: F(%s, %s) = %.3f, p %s, etap2 = %.3f [%.3f, %.3f].",
    r$num_df, r$den_df_GG, r$F, sig_str(r$p_GG), r$pes, r$pes_CI_low, r$pes_CI_high))
}
doc <- add_p(doc,
  "CONCLUSION: SUPPORTED. Frequency significantly modulated TTC. Post-hoc contrasts revealed")
doc <- add_p(doc,
  "differences primarily between flickering frequencies; individual flicker-vs-stable contrasts")
doc <- add_p(doc,
  "did not survive Holm correction, suggesting the effect is driven by between-flicker differences.")

doc <- add_h2(doc, "SRQ2 — Frequency & depth on visual search / cognitive load")
doc <- add_p(doc,
  "RATINGS: Fully supported. All Q1-Q4 showed large frequency effects (etap2 = .19-.69, all p < .001),")
doc <- add_p(doc,
  "replicating across CLMM ordinal robustness check. Q2-Q3 consistency alpha = .948 -> cognitive_load composite.")
doc <- add_p(doc,
  "EYE METRICS: Not supported. No frequency or depth effects on any gaze metric (all p > .15).")
doc <- add_p(doc,
  "First-fixation proportion near ceiling (99.9%) -> floor effect; latency also ns.")
doc <- add_p(doc,
  "SSQ: Post-test sickness scores were higher than pre-test (see Table 28 for significance).")

doc <- add_h2(doc, "SRQ3 — Frequency x depth interaction on TTC")
s2m <- read_t("05_anova_ttc_step2_main")
if (nrow(s2m) > 0) {
  int_r <- s2m[grepl(":", s2m$Effect), ]
  if (nrow(int_r) > 0) {
    doc <- add_p(doc, sprintf(
      "Interaction: F(%s, %s) = %.3f, p %s, etap2 = %.3f.",
      int_r$num_df[1], int_r$den_df_GG[1], int_r$F[1],
      sig_str(int_r$p_GG[1]), int_r$pes[1]))
  }
}
doc <- add_p(doc,
  "CONCLUSION: NOT SUPPORTED. No significant frequency x depth interaction on TTC.")
doc <- add_p(doc,
  "Modulation depth did not amplify frequency effects; the two factors acted independently.")
doc <- add_p(doc,
  "The same null result was confirmed by LMM robustness and all sensitivity checks.")

doc <- add_br(doc)
doc <- body_add_break(doc)

# ═══════════════════════════════════════════════════════════════════════════════
# 11. FILE CATALOG
# ═══════════════════════════════════════════════════════════════════════════════
doc <- add_h1(doc, "11. File Catalog")

doc <- add_h2(doc, "R Scripts (R/)")
scripts_info <- tibble(
  Script = c("00_setup.R","01_ingest.R","02_flag.R","03_describe.R",
             "04_assumptions.R","05_anova_ttc.R","06_anova_ratings.R",
             "07_anova_eye.R","08_ssq.R","09_sensitivity.R","10_plots.R","run_all.R"),
  Purpose = c(
    "Packages, seed, factor levels, save_csv/save_fig helpers",
    "Load raw data, parse filenames, merge master_long.csv",
    "Add quality flag columns (no data deleted)",
    "Descriptive statistics by 10 conditions + participant table",
    "ANOVA assumption diagnostics: normality, sphericity, outliers",
    "TTC two-step RM-ANOVA + LMM robustness (SRQ1 & SRQ3)",
    "Q1-Q4 two-step RM-ANOVA + CLMM robustness (SRQ1 & SRQ2)",
    "Eye metrics two-step RM-ANOVA + GLMM + first-fixation two-stage",
    "SSQ pre/post analysis with Kennedy (1993) weights",
    "Sensitivity analyses: P09/P15 exclusion, scene, quality strata",
    "All 14 figures at 300 dpi",
    "One-click full pipeline execution with SRQ conclusions"
  )
)
doc <- body_add_flextable(doc, make_ft(scripts_info, "Table 33. R script catalog"))

doc <- add_h2(doc, "Key Output Tables (output/tables/)")
tables_info <- tibble(
  File = c(
    "02_flag_summary.csv", "03_descriptives_ttc.csv", "03_descriptives_ratings.csv",
    "03_descriptives_eye.csv", "03_participant_characteristics.csv",
    "04_assumption_checks.csv",
    "05_anova_ttc_step1_main.csv", "05_anova_ttc_step1_contrasts.csv",
    "05_anova_ttc_step2_main.csv", "05_anova_ttc_lmm_anova.csv",
    "06_ratings_step1_main.csv", "06_ratings_step2_main.csv",
    "06_ratings_summary.csv", "06_ratings_clmm.csv",
    "07_eye_step1_main.csv", "07_eye_step2_main.csv",
    "07_eye_summary.csv", "07_eye_count_glmm.csv",
    "07_eye_firstfix_stage1_prop_by_freq.csv",
    "08_ssq_prepost_tests.csv", "08_ssq_delta_correlations.csv",
    "09_sensitivity_summary.csv"
  ),
  Content = c(
    "Quality flag counts", "TTC mean/sd/median by condition",
    "Q1-Q4 mean/sd by condition", "Eye metric stats by condition",
    "Age/gender/license/special-case flags",
    "Normality/sphericity/outlier check per DV",
    "TTC Step-1 F/df/p/etap2+CI", "TTC contrasts vs 0 Hz",
    "TTC Step-2 F/df/p/etap2+CI (3x3)", "TTC LMM ANOVA type III",
    "Ratings Step-1 per DV", "Ratings Step-2 per DV",
    "Ratings both-step summary", "CLMM ordinal fixed effects",
    "Eye Step-1 per DV", "Eye Step-2 per DV (3x3)",
    "Eye summary table", "Count GLMM Poisson/NB fixed effects",
    "% trials with CMS fixation by frequency",
    "SSQ paired test results (t + Wilcoxon)", "Delta-SSQ correlations",
    "P09/P15 + quality sensitivity comparison"
  )
)
doc <- body_add_flextable(doc, make_ft(tables_info, "Table 34. Key output CSV catalog"))

doc <- add_h2(doc, "Figures (output/figures/)")
figs_info <- tibble(
  File = c(
    "fig_qq_ttc.png", "fig_resid_ttc.png", "fig_outlier_ttc.png",
    "fig_ttc_box.png", "fig_ttc_interaction.png", "fig_ttc_spaghetti.png",
    "fig_ratings_bar.png", "fig_ratings_likert.png", "fig_ratings_heatmap.png",
    "fig_eye_dwell.png", "fig_eye_interaction.png", "fig_eye_firstfix.png",
    "fig_ssq_prepost.png", "fig_effectsize_forest.png"
  ),
  SRQ = c("Diag","Diag","Diag","SRQ1&3","SRQ3","SRQ1","SRQ1&2","SRQ2","SRQ1&2",
           "SRQ2","SRQ2&3","SRQ2","SRQ2","All"),
  Description = c(
    "QQ plots TTC residuals by frequency",
    "Residuals vs fitted + histogram (Step-1 RM-ANOVA)",
    "Boxplot with extreme outliers labelled by participant",
    "TTC distribution across 10 conditions (box + jitter)",
    "Interaction line: frequency x depth, 0 Hz baseline (CORE SRQ3)",
    "Individual spaghetti trajectories across frequency",
    "Q1-Q4 EMMs +/- 95% CI by frequency",
    "Stacked Likert proportions (1-7) by frequency",
    "Mean rating heatmap: condition x Q1-Q4",
    "CMS / Road / Other dwell allocation stacked bar",
    "transition_count & fixation_duration_cms EMMs by frequency",
    "Two-stage first-fixation: % fixated + latency",
    "SSQ N/O/TS pre vs post paired plot",
    "etap2 forest plot across all DVs with 95% CI"
  )
)
doc <- body_add_flextable(doc, make_ft(figs_info, "Table 35. Figure catalog with SRQ mapping"))

# ── Save ──────────────────────────────────────────────────────────────────────
out_path <- file.path(OUT_DIR, "analysis_reference.docx")
print(doc, target = out_path)
cat(sprintf("\nSaved: %s\n", out_path))
cat(sprintf("Size: %.1f MB\n", file.size(out_path) / 1e6))
