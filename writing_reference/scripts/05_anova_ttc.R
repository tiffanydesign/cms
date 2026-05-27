# 05_anova_ttc.R — TTC two-step RM-ANOVA + LMM robustness (spec §5.6)
# Step 1 (SRQ1): frequency 4-level single-factor RM-ANOVA + planned contrasts
# Step 2 (SRQ3): frequency × modulation_depth two-way RM-ANOVA (9 flicker conds)
# LMM: TTC ~ frequency*depth + (1|participant) + (1|scene), flickering only
source(here::here("R", "00_setup.R"))
if (!requireNamespace("effectsize", quietly = TRUE))
  install.packages("effectsize", repos = "https://cloud.r-project.org")
library(effectsize)

# ── Load ──────────────────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS),
    scene            = factor(scene)
  )
cat(sprintf("[TTC] master: %d rows\n", nrow(master)))

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

# ── Step 1 aggregate: participant × frequency (4 levels) ──────────────────────
step1 <- master %>%
  group_by(participant_id, frequency) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop")

# ── Step 2 aggregate: participant × freq × depth (9 flickering conditions) ────
step2 <- master %>%
  filter(!is.na(modulation_depth)) %>%
  group_by(participant_id, frequency, modulation_depth) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop") %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

# ── Trial-level flickering data for LMM ───────────────────────────────────────
flicker_trials <- master %>%
  filter(!is.na(modulation_depth), !is.na(TTC_s)) %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

cat(sprintf("[TTC] step1: %d rows | step2: %d rows | LMM trials: %d\n",
            nrow(step1), nrow(step2), nrow(flicker_trials)))

# ── Helper: append η²p 95% CI to ANOVA table ─────────────────────────────────
add_eta_ci <- function(aov_tbl) {
  df <- as.data.frame(aov_tbl) %>% tibble::rownames_to_column("Effect")
  map_dfr(seq_len(nrow(df)), function(i) {
    r <- df[i, ]
    ci <- tryCatch(
      effectsize::F_to_eta2(
        f = r[["F"]], df = r[["num Df"]], df_error = r[["den Df"]],
        ci = 0.95, alternative = "two.sided"),
      error = function(e) list(CI_low = NA_real_, CI_high = NA_real_)
    )
    tibble(
      Effect      = r$Effect,
      F           = round(r[["F"]],        3),
      num_df      = round(r[["num Df"]],   2),
      den_df_GG   = round(r[["den Df"]],   2),
      MSE         = round(r[["MSE"]],       4),
      pes         = round(r[["pes"]],       4),
      pes_CI_low  = round(ci$CI_low,        4),
      pes_CI_high = round(ci$CI_high,       4),
      p_GG        = round(r[["Pr(>F)"]],   4)
    )
  })
}

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 1 (SRQ1) — single-factor RM-ANOVA: frequency (4 levels)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("STEP 1 (SRQ1): frequency 4-level RM-ANOVA [GG correction]\n")
cat(strrep("=", 60), "\n")

fit1 <- afex::aov_ez(
  id    = "participant_id",
  dv    = "TTC_s",
  data  = step1,
  within = "frequency",
  type  = 3,
  anova_table = list(correction = "GG", es = "pes")
)

aov_tbl1  <- anova(fit1, correction = "GG", es = "pes")
step1_main <- add_eta_ci(aov_tbl1)
save_csv(step1_main, "05_anova_ttc_step1_main")

cat("\n[Table] Step 1 ANOVA (GG-corrected):\n")
print(nice(fit1, correction = "GG", es = "pes"))

# ── Estimated marginal means ───────────────────────────────────────────────────
emm1 <- emmeans(fit1, ~frequency)
emm1_df <- summary(emm1) %>% as_tibble() %>%
  mutate(across(where(is.numeric), ~round(.x, 3)))
save_csv(emm1_df, "05_anova_ttc_step1_emm")
cat("\n[EMM] Condition means:\n")
print(emm1_df %>% select(frequency, emmean, SE, lower.CL, upper.CL))

# ── Planned contrasts: each flickering freq vs 0 Hz (Holm) ──────────────────
con_list <- list(
  "8.33 Hz vs 0 Hz"  = c(-1, 1, 0, 0),
  "12.5 Hz vs 0 Hz"  = c(-1, 0, 1, 0),
  "25 Hz vs 0 Hz"    = c(-1, 0, 0, 1)
)
contrasts1     <- contrast(emm1, method = con_list, adjust = "holm")
contrasts1_df  <- summary(contrasts1, infer = TRUE) %>% as_tibble() %>%
  mutate(across(where(is.numeric), ~round(.x, 4)))
save_csv(contrasts1_df, "05_anova_ttc_step1_contrasts")

cat("\n[Contrasts] Planned comparisons vs 0 Hz (Holm-corrected):\n")
print(contrasts1_df %>% select(contrast, estimate, SE, df, t.ratio, p.value, lower.CL, upper.CL))

# ═══════════════════════════════════════════════════════════════════════════════
# STEP 2 (SRQ3) — two-way RM-ANOVA: frequency × modulation_depth (9 conditions)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("STEP 2 (SRQ3): 3x3 two-way RM-ANOVA [GG correction]\n")
cat(strrep("=", 60), "\n")

fit2 <- afex::aov_ez(
  id     = "participant_id",
  dv     = "TTC_s",
  data   = step2,
  within = c("frequency", "modulation_depth"),
  type   = 3,
  anova_table = list(correction = "GG", es = "pes")
)

aov_tbl2  <- anova(fit2, correction = "GG", es = "pes")
step2_main <- add_eta_ci(aov_tbl2)
save_csv(step2_main, "05_anova_ttc_step2_main")

cat("\n[Table] Step 2 ANOVA (GG-corrected):\n")
print(nice(fit2, correction = "GG", es = "pes"))

# ── Post-hoc pairwise comparisons (run always; note parent significance) ──────
emm2_freq <- emmeans(fit2, ~frequency)
emm2_dep  <- emmeans(fit2, ~modulation_depth)
emm2_int  <- emmeans(fit2, ~frequency * modulation_depth)

ph_freq <- summary(pairs(emm2_freq, adjust = "holm"), infer = TRUE) %>%
  as_tibble() %>% mutate(factor = "frequency",         across(where(is.numeric), ~round(.x,4)))
ph_dep  <- summary(pairs(emm2_dep,  adjust = "holm"), infer = TRUE) %>%
  as_tibble() %>% mutate(factor = "modulation_depth",  across(where(is.numeric), ~round(.x,4)))

int_row <- step2_main %>% filter(str_detect(Effect, ":"))
int_p   <- int_row$p_GG

if (!is.na(int_p) && int_p < 0.05) {
  ph_int <- summary(pairs(emm2_int, adjust = "holm"), infer = TRUE) %>%
    as_tibble() %>% mutate(factor = "freq_x_dep", across(where(is.numeric), ~round(.x,4)))
  step2_posthoc <- bind_rows(ph_freq, ph_dep, ph_int)
  cat(sprintf("\n[!] Interaction SIGNIFICANT (p=%.4f) — cell-wise pairs included.\n", int_p))
} else {
  step2_posthoc <- bind_rows(ph_freq, ph_dep)
  cat(sprintf("\n[—] Interaction NOT significant (p=%.4f) — main-effect pairs only.\n",
              coalesce(int_p, NA_real_)))
}
save_csv(step2_posthoc, "05_anova_ttc_step2_posthoc")

cat("\n[Post-hoc] frequency (Holm):\n")
print(ph_freq %>% select(contrast, estimate, SE, df, t.ratio, p.value))
cat("\n[Post-hoc] modulation_depth (Holm):\n")
print(ph_dep  %>% select(contrast, estimate, SE, df, t.ratio, p.value))

# ═══════════════════════════════════════════════════════════════════════════════
# LMM ROBUSTNESS — trial level, flickering conditions
# TTC ~ frequency * modulation_depth + (1|participant_id) + (1|scene)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("LMM ROBUSTNESS: TTC ~ freq*depth + (1|participant) + (1|scene)\n")
cat(strrep("=", 60), "\n")

lmm_fit <- tryCatch(
  lmerTest::lmer(
    TTC_s ~ frequency * modulation_depth + (1 | participant_id) + (1 | scene),
    data    = flicker_trials,
    REML    = TRUE,
    control = lme4::lmerControl(optimizer = "bobyqa")
  ),
  error = function(e) { message("[WARN] LMM: ", e$message); NULL }
)

if (!is.null(lmm_fit)) {
  lmm_anova <- anova(lmm_fit, ddf = "Satterthwaite") %>%
    as.data.frame() %>% tibble::rownames_to_column("Effect") %>% as_tibble() %>%
    rename(F_value = `F value`, p_value = `Pr(>F)`) %>%
    mutate(across(where(is.numeric), ~round(.x, 4)))

  lmm_fixed <- broom.mixed::tidy(lmm_fit, effects = "fixed",
                                  conf.int = TRUE, conf.level = 0.95) %>%
    mutate(across(where(is.numeric), ~round(.x, 4)))

  save_csv(lmm_anova, "05_anova_ttc_lmm_anova")
  save_csv(lmm_fixed, "05_anova_ttc_lmm_fixed")

  cat("\n[LMM] ANOVA-type III (Satterthwaite df):\n")
  print(lmm_anova)
  cat("\n[LMM] Fixed effects with 95% CI:\n")
  print(lmm_fixed %>% select(term, estimate, std.error, statistic, conf.low, conf.high, p.value))
} else {
  cat("[WARN] LMM could not be fitted — check data structure.\n")
}

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("SUMMARY: TTC RM-ANOVA Results\n")
cat(strrep("=", 60), "\n\n")

cat("Step 1 (SRQ1) — frequency (4-level), GG-corrected:\n")
r1 <- step1_main
cat(sprintf("  frequency: F(%s, %s) = %.3f,  p = %.4f,  ηp² = %.4f  [%.4f, %.4f]\n",
            r1$num_df, r1$den_df_GG, r1$F, r1$p_GG, r1$pes, r1$pes_CI_low, r1$pes_CI_high))

cat("\n  Planned contrasts vs 0 Hz (Holm):\n")
for (i in seq_len(nrow(contrasts1_df))) {
  r <- contrasts1_df[i, ]
  sig <- if (r$p.value < .001) "***" else if (r$p.value < .01) "**" else
         if (r$p.value < .05) "*" else "ns"
  cat(sprintf("    %-20s  Δ=%.3f  t(%.1f)=%.3f  p=%.4f  %s\n",
              r$contrast, r$estimate, r$df, r$t.ratio, r$p.value, sig))
}

cat("\nStep 2 (SRQ3) — 3×3 frequency × depth, GG-corrected:\n")
for (i in seq_len(nrow(step2_main))) {
  r <- step2_main[i, ]
  sig <- if (r$p_GG < .001) "***" else if (r$p_GG < .01) "**" else
         if (r$p_GG < .05) "*" else "ns"
  cat(sprintf("  %-30s F(%s, %s) = %.3f  p = %.4f  ηp² = %.4f [%.4f, %.4f]  %s\n",
              r$Effect, r$num_df, r$den_df_GG, r$F, r$p_GG,
              r$pes, r$pes_CI_low, r$pes_CI_high, sig))
}

cat("\n05_anova_ttc.R DONE\n")
cat("  -> 05_anova_ttc_step1_main.csv, _step1_contrasts.csv, _step1_emm.csv\n")
cat("  -> 05_anova_ttc_step2_main.csv, _step2_posthoc.csv\n")
cat("  -> 05_anova_ttc_lmm_anova.csv, _lmm_fixed.csv\n")
