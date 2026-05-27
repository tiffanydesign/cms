# 04_assumptions.R — ANOVA pre-diagnostics ★ (supervisor priority)
# Normality (Shapiro-Wilk per condition cell), sphericity (Mauchly via
# rstatix::anova_test), extreme outliers (rstatix::identify_outliers).
# NEVER deletes rows — marks and reports only.
source(here::here("R", "00_setup.R"))
if (!requireNamespace("ggrepel", quietly = TRUE))
  install.packages("ggrepel", repos = "https://cloud.r-project.org")
library(ggrepel)

DIAG_DVS <- c("TTC_s", "Q1", "Q2", "Q3", "Q4",
              "dwell_ratio_cms", "transition_count",
              "fixation_count_cms", "fixation_duration_cms_mean_ms")

# ── Load & factor ─────────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS)
  )
cat(sprintf("[ASSUMP] master loaded: %d rows\n", nrow(master)))

# ── Aggregate ─────────────────────────────────────────────────────────────────
nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

# Step 1 (SRQ1): participant x frequency (4 levels), avg over scenes & depths
step1 <- master %>%
  group_by(participant_id, frequency) %>%
  summarise(across(all_of(DIAG_DVS), ~nan_to_na(mean(.x, na.rm = TRUE))),
            .groups = "drop")

# Step 2 (SRQ3): participant x frequency x depth (9 flickering conditions)
step2 <- master %>%
  filter(!is.na(modulation_depth)) %>%
  group_by(participant_id, frequency, modulation_depth) %>%
  summarise(across(all_of(DIAG_DVS), ~nan_to_na(mean(.x, na.rm = TRUE))),
            .groups = "drop") %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

cat(sprintf("[ASSUMP] step1: %d rows (expect 100 = 25x4)\n", nrow(step1)))
cat(sprintf("[ASSUMP] step2: %d rows (expect 225 = 25x9)\n", nrow(step2)))

# ── Helpers ───────────────────────────────────────────────────────────────────
sw_by_group <- function(data, dv, group_vars) {
  data %>%
    filter(!is.na(.data[[dv]])) %>%
    group_by(across(all_of(group_vars))) %>%
    rstatix::shapiro_test(dv) %>%
    ungroup()
}

get_sphericity <- function(data, dv, within_vars) {
  tryCatch({
    rt <- rstatix::anova_test(data = data, dv = dv, wid = "participant_id",
                              within = within_vars, effect.size = "pes")
    list(mauchly = rt[["Mauchly's Test for Sphericity"]],
         sph_cor = rt[["Sphericity Corrections"]])
  }, error = function(e) {
    message(sprintf("  [WARN] sphericity(%s, %s): %s",
                    dv, paste(within_vars, collapse = "x"), conditionMessage(e)))
    list(mauchly = NULL, sph_cor = NULL)
  })
}

extreme_outliers <- function(data, dv, group_vars) {
  data %>%
    filter(!is.na(.data[[dv]])) %>%
    group_by(across(all_of(group_vars))) %>%
    rstatix::identify_outliers(dv) %>%
    ungroup() %>%
    filter(is.extreme)
}

mauchly_vals <- function(m_tbl, effect_name, use_grep = FALSE) {
  if (is.null(m_tbl) || nrow(m_tbl) == 0) return(c(W = NA_real_, p = NA_real_))
  mask <- if (use_grep) grepl(effect_name, m_tbl$Effect) else m_tbl$Effect == effect_name
  row  <- m_tbl[mask, , drop = FALSE]
  if (nrow(row) == 0) return(c(W = NA_real_, p = NA_real_))
  c(W = row$W[1], p = row$p[1])
}

sph_gg <- function(sc_tbl, effect_name, use_grep = FALSE) {
  if (is.null(sc_tbl) || nrow(sc_tbl) == 0) return(NA_real_)
  mask <- if (use_grep) grepl(effect_name, sc_tbl$Effect) else sc_tbl$Effect == effect_name
  row  <- sc_tbl[mask, , drop = FALSE]
  if (nrow(row) == 0) return(NA_real_)
  row$GGe[1]
}

sph_verdict <- function(p) {
  case_when(is.na(p) ~ "n/a", p < 0.05 ~ "VIOLATED->GG", TRUE ~ "pass")
}

# ── Main diagnostic loop ──────────────────────────────────────────────────────
cat("\n", strrep("=", 60), "\n")
results <- list()

for (dv in DIAG_DVS) {
  cat(sprintf("\n-- %s --\n", dv))

  sw1  <- sw_by_group(step1, dv, "frequency")
  sph1 <- get_sphericity(step1, dv, "frequency")
  ext1 <- extreme_outliers(step1, dv, "frequency")

  sw2  <- sw_by_group(step2, dv, c("frequency", "modulation_depth"))
  sph2 <- get_sphericity(step2, dv, c("frequency", "modulation_depth"))
  ext2 <- extreme_outliers(step2, dv, c("frequency", "modulation_depth"))

  mv1      <- mauchly_vals(sph1$mauchly, "frequency")
  gg1      <- sph_gg(sph1$sph_cor, "frequency")
  mv2_freq <- mauchly_vals(sph2$mauchly, "frequency")
  gg2_freq <- sph_gg(sph2$sph_cor, "frequency")
  mv2_dep  <- mauchly_vals(sph2$mauchly, "modulation_depth")
  gg2_dep  <- sph_gg(sph2$sph_cor, "modulation_depth")
  mv2_int  <- mauchly_vals(sph2$mauchly, ":", use_grep = TRUE)
  gg2_int  <- sph_gg(sph2$sph_cor, ":", use_grep = TRUE)

  n_sw1_fail <- sum(sw1$p.value < 0.05, na.rm = TRUE)
  n_sw2_fail <- sum(sw2$p.value < 0.05, na.rm = TRUE)

  cat(sprintf("  Shapiro-Wilk: step1 %d/%d fail | step2 %d/%d fail\n",
              n_sw1_fail, nrow(sw1), n_sw2_fail, nrow(sw2)))
  cat(sprintf("  Mauchly step1 (freq 4-lvl): W=%.3f p=%.4f GGe=%.3f -> %s\n",
              mv1["W"], mv1["p"], gg1, sph_verdict(mv1["p"])))
  cat(sprintf("  Extreme outliers: step1=%d  step2=%d\n",
              nrow(ext1), nrow(ext2)))

  results[[dv]] <- list(
    sw1 = sw1, sw2 = sw2, sph1 = sph1, sph2 = sph2, ext1 = ext1, ext2 = ext2,
    n_sw1_fail = n_sw1_fail, n_sw2_fail = n_sw2_fail,
    mv1 = mv1, gg1 = gg1,
    mv2_freq = mv2_freq, gg2_freq = gg2_freq,
    mv2_dep  = mv2_dep,  gg2_dep  = gg2_dep,
    mv2_int  = mv2_int,  gg2_int  = gg2_int
  )
}

# ── Summary table ─────────────────────────────────────────────────────────────
assump_checks <- map_dfr(DIAG_DVS, function(dv) {
  r <- results[[dv]]
  tibble(
    DV            = dv,
    s1_SW_fail    = r$n_sw1_fail,
    s1_SW_cells   = nrow(r$sw1),
    s1_normality  = ifelse(r$n_sw1_fail == 0, "pass", "FAIL"),
    s1_Mauchly_W  = round(r$mv1["W"],  3),
    s1_Mauchly_p  = round(r$mv1["p"],  4),
    s1_GGe        = round(r$gg1,        3),
    s1_sphericity = sph_verdict(r$mv1["p"]),
    s1_n_extreme  = nrow(r$ext1),
    s2_SW_fail    = r$n_sw2_fail,
    s2_SW_cells   = nrow(r$sw2),
    s2_normality  = ifelse(r$n_sw2_fail == 0, "pass", "FAIL"),
    s2_freq_W     = round(r$mv2_freq["W"], 3),
    s2_freq_p     = round(r$mv2_freq["p"], 4),
    s2_freq_GGe   = round(r$gg2_freq,       3),
    s2_freq_sph   = sph_verdict(r$mv2_freq["p"]),
    s2_dep_W      = round(r$mv2_dep["W"],  3),
    s2_dep_p      = round(r$mv2_dep["p"],  4),
    s2_dep_GGe    = round(r$gg2_dep,        3),
    s2_dep_sph    = sph_verdict(r$mv2_dep["p"]),
    s2_int_W      = round(r$mv2_int["W"],  3),
    s2_int_p      = round(r$mv2_int["p"],  4),
    s2_int_GGe    = round(r$gg2_int,        3),
    s2_int_sph    = sph_verdict(r$mv2_int["p"]),
    s2_n_extreme  = nrow(r$ext2)
  )
})

save_csv(assump_checks, "04_assumption_checks")

cat("\n=== Assumption Check Summary ===\n")
print(assump_checks %>%
        select(DV, s1_normality, s1_sphericity, s1_n_extreme,
               s2_normality, s2_freq_sph, s2_dep_sph, s2_int_sph, s2_n_extreme),
      n = 15)

# ── QQ plots ──────────────────────────────────────────────────────────────────
make_qq_s1 <- function(dv) {
  step1 %>%
    filter(!is.na(.data[[dv]])) %>%
    ggplot(aes(sample = .data[[dv]])) +
    stat_qq(size = 1) + stat_qq_line(colour = "tomato") +
    facet_wrap(~frequency, ncol = 4, labeller = label_both) +
    labs(title = dv, subtitle = "Step 1: by frequency (n~25 per cell)") +
    PLOT_THEME
}

make_qq_s2 <- function(dv) {
  step2 %>%
    filter(!is.na(.data[[dv]])) %>%
    mutate(cond = paste0(frequency, " Hz / ", modulation_depth, "%")) %>%
    ggplot(aes(sample = .data[[dv]])) +
    stat_qq(size = 1) + stat_qq_line(colour = "tomato") +
    facet_wrap(~cond, ncol = 3) +
    labs(title = dv, subtitle = "Step 2: 9 flickering conditions") +
    PLOT_THEME
}

p_qq_ttc <- (make_qq_s1("TTC_s") / make_qq_s2("TTC_s")) +
  plot_annotation(title = "QQ plots: TTC_s")
save_fig(p_qq_ttc, "fig_qq_ttc", width_in = 10, height_in = 10)

qq_rating_list <- map(c("Q1","Q2","Q3","Q4"), make_qq_s1)
p_qq_ratings <- wrap_plots(qq_rating_list, ncol = 2) +
  plot_annotation(title = "QQ plots: Q1-Q4 (step 1, by frequency)")
save_fig(p_qq_ratings, "fig_qq_ratings", width_in = 12, height_in = 10)

eye_qq_dvs <- c("dwell_ratio_cms", "transition_count",
                "fixation_count_cms", "fixation_duration_cms_mean_ms")
qq_eye_list <- map(eye_qq_dvs, make_qq_s1)
p_qq_eye <- wrap_plots(qq_eye_list, ncol = 2) +
  plot_annotation(title = "QQ plots: Key eye metrics (step 1, by frequency)")
save_fig(p_qq_eye, "fig_qq_eye", width_in = 12, height_in = 10)

cat("[ASSUMP] QQ plots saved.\n")

# ── Outlier-annotated boxplot: TTC across 10 conditions ───────────────────────
COND10_LEVELS <- c("0\n(stable)",
  "8.33\n40%", "8.33\n60%", "8.33\n80%",
  "12.5\n40%", "12.5\n60%", "12.5\n80%",
  "25\n40%",   "25\n60%",   "25\n80%")

ttc_cond <- master %>%
  mutate(cond = case_when(
    is.na(modulation_depth) ~
      paste0(as.character(frequency), "\n(stable)"),
    TRUE ~
      paste0(as.character(frequency), "\n", as.character(modulation_depth), "%")
  )) %>%
  group_by(participant_id, cond) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop") %>%
  mutate(cond = factor(cond, levels = COND10_LEVELS))

ext_ttc10 <- ttc_cond %>%
  filter(!is.na(TTC_s)) %>%
  group_by(cond) %>%
  rstatix::identify_outliers("TTC_s") %>%
  ungroup() %>%
  filter(is.extreme)

p_outlier_ttc <- ggplot(ttc_cond, aes(x = cond, y = TTC_s)) +
  geom_boxplot(outlier.shape = NA, fill = "steelblue", alpha = 0.4) +
  geom_jitter(width = 0.15, size = 1.5, alpha = 0.35) +
  geom_label_repel(data = ext_ttc10, aes(label = participant_id),
                   size = 2.5, colour = "red", fill = "white",
                   segment.colour = "red", min.segment.length = 0) +
  labs(title = "TTC by condition - extreme outliers labelled (IQR x3)",
       x = "Condition (Hz / depth)", y = "TTC (s)") +
  PLOT_THEME
save_fig(p_outlier_ttc, "fig_outlier_ttc", width_in = 12, height_in = 5)
cat("[ASSUMP] Outlier boxplot saved.\n")

# ── Residual diagnostics: TTC step 1 via LMM ─────────────────────────────────
ttc_lmm <- tryCatch(
  lme4::lmer(TTC_s ~ frequency + (1 | participant_id), data = step1,
             REML = TRUE, control = lme4::lmerControl(optimizer = "bobyqa")),
  error = function(e) { message("[WARN] lmer TTC: ", e$message); NULL }
)
if (!is.null(ttc_lmm)) {
  rd <- tibble(fitted = fitted(ttc_lmm), residual = residuals(ttc_lmm))
  p_rh <- ggplot(rd, aes(residual)) +
    geom_histogram(bins = 25, fill = "steelblue", colour = "white") +
    labs(title = "TTC residuals: histogram") + PLOT_THEME
  p_rq <- ggplot(rd, aes(sample = residual)) +
    stat_qq() + stat_qq_line(colour = "tomato") +
    labs(title = "TTC residuals: QQ") + PLOT_THEME
  p_rf <- ggplot(rd, aes(fitted, residual)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, colour = "tomato", linetype = "dashed") +
    labs(title = "TTC residuals vs fitted") + PLOT_THEME
  save_fig((p_rh | p_rq | p_rf), "fig_resid_ttc", width_in = 14, height_in = 5)
  cat("[ASSUMP] Residual plot saved.\n")
}

# ── Natural language summary ──────────────────────────────────────────────────
txt <- c(
  "04_assumptions.R - ANOVA Pre-Diagnostic Summary",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M")),
  "",
  sprintf("Step 1 aggregate: %d rows (%d participants x 4 frequency levels)",
          nrow(step1), n_distinct(step1$participant_id)),
  sprintf("Step 2 aggregate: %d rows (%d participants x 9 flickering conditions)",
          nrow(step2), n_distinct(step2$participant_id)),
  ""
)

for (dv in DIAG_DVS) {
  r  <- results[[dv]]
  ac <- assump_checks %>% filter(DV == dv)
  txt <- c(txt,
    paste0("=== ", dv, " ==="),
    sprintf("  Normality Step1 (SW/condition): %s -- %d/%d cells p<.05",
            ac$s1_normality, r$n_sw1_fail, nrow(r$sw1)),
    sprintf("  Normality Step2 (SW/condition): %s -- %d/%d cells p<.05",
            ac$s2_normality, r$n_sw2_fail, nrow(r$sw2)),
    sprintf("  Sphericity Step1 freq (4 lvl):  W=%.3f p=%.4f GGe=%.3f -> %s",
            r$mv1["W"], r$mv1["p"], r$gg1, ac$s1_sphericity),
    sprintf("  Sphericity Step2 frequency:     W=%.3f p=%.4f GGe=%.3f -> %s",
            r$mv2_freq["W"], r$mv2_freq["p"], r$gg2_freq, ac$s2_freq_sph),
    sprintf("  Sphericity Step2 depth:         W=%.3f p=%.4f GGe=%.3f -> %s",
            r$mv2_dep["W"], r$mv2_dep["p"], r$gg2_dep, ac$s2_dep_sph),
    sprintf("  Sphericity Step2 freq x depth:  W=%.3f p=%.4f GGe=%.3f -> %s",
            r$mv2_int["W"], r$mv2_int["p"], r$gg2_int, ac$s2_int_sph),
    sprintf("  Extreme outliers: step1=%d  step2=%d", nrow(r$ext1), nrow(r$ext2)),
    ""
  )
}

txt <- c(txt,
  "RECOMMENDATIONS:",
  "  * VIOLATED->GG: apply Greenhouse-Geisser correction in scripts 05-07.",
  "  * Normality violations: RM-ANOVA robust to moderate deviations (CLT, n=25);",
  "    LMM robustness checks included in 05-07.",
  "  * Extreme outliers: retained in main analysis (no deletion);",
  "    sensitivity analysis with P09/P15 exclusion in 09_sensitivity.R."
)

writeLines(txt, here::here("output", "tables", "04_assumption_summary.txt"))
cat("\n")
cat(paste(txt, collapse = "\n"), "\n")

cat("\n04_assumptions.R DONE\n")
cat("  -> output/tables/04_assumption_checks.csv\n")
cat("  -> output/tables/04_assumption_summary.txt\n")
cat("  -> output/figures/fig_qq_ttc.png, fig_qq_ratings.png, fig_qq_eye.png\n")
cat("  -> output/figures/fig_outlier_ttc.png, fig_resid_ttc.png\n")
