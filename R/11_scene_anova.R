# 11_scene_anova.R — Scene (A/B/C) main effect and interactions
# Primary DV: TTC_s
# M1: RM-ANOVA  TTC ~ frequency x scene  (4 x 3, all conditions)
# M2: RM-ANOVA  TTC ~ depth x scene      (3 x 3, flickering only)
# M3: LMM       TTC ~ frequency x depth x scene + (1|participant_id)
#               trial-level; handles P03/P11 missing cell at 8.33/60%/C
# Post-hoc: Bonferroni pairwise t-tests between scenes (A-B, A-C, B-C) from M1
# GG correction throughout RM-ANOVAs; Satterthwaite df for LMM
source(here::here("R", "00_setup.R"))
if (!requireNamespace("effectsize", quietly = TRUE))
  install.packages("effectsize", repos = "https://cloud.r-project.org")
library(effectsize)

# ── Load ──────────────────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS),
    scene            = factor(scene,            levels = c("A", "B", "C"))
  )
cat(sprintf("[SCENE] master: %d rows | N = %d participants\n",
            nrow(master), n_distinct(master$participant_id)))

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

sig_star <- function(p) {
  if (is.na(p)) return("n/a")
  if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else "ns"
}

add_eta_ci <- function(aov_tbl) {
  df <- as.data.frame(aov_tbl) %>% tibble::rownames_to_column("Effect")
  map_dfr(seq_len(nrow(df)), function(i) {
    r  <- df[i, ]
    ci <- tryCatch(
      effectsize::F_to_eta2(f = r[["F"]], df = r[["num Df"]], df_error = r[["den Df"]],
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

print_anova <- function(res_tbl, title) {
  cat("\n", strrep("-", 70), "\n")
  cat(title, "\n")
  cat(strrep("-", 70), "\n")
  for (i in seq_len(nrow(res_tbl))) {
    r <- res_tbl[i, ]
    cat(sprintf("  %-35s F(%s, %s) = %7.3f  p = %.4f %-3s  eta_p2 = %.3f [%.3f, %.3f]\n",
                r$Effect, r$num_df, r$den_df_GG, r$F,
                r$p_GG, sig_star(r$p_GG),
                r$pes, r$pes_CI_low, r$pes_CI_high))
  }
}

# =========================================================================
# MODEL 1 — frequency x scene (4 x 3 RM-ANOVA)
# Aggregate: participant x frequency x scene  (mean over depths)
# P03/P11 at 8.33 Hz x scene C: mean from 40% + 80% depths  -> no missing cell
# =========================================================================
cat("\n[M1] Aggregate: participant x frequency x scene\n")

agg_m1 <- master %>%
  filter(!flag_skipped_trial) %>%
  group_by(participant_id, frequency, scene) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop") %>%
  filter(!is.na(TTC_s))

cat(sprintf("  Rows: %d  (expected 300 = 25 x 4 x 3)\n", nrow(agg_m1)))

fit_m1 <- tryCatch(
  afex::aov_ez(id = "participant_id", dv = "TTC_s", data = agg_m1,
               within = c("frequency", "scene"), type = 3,
               anova_table = list(correction = "GG", es = "pes")),
  error = function(e) { message("[WARN] M1 failed: ", e$message); NULL }
)

m1_res <- tibble()
if (!is.null(fit_m1)) {
  m1_res <- add_eta_ci(anova(fit_m1, correction = "GG", es = "pes")) %>%
    mutate(Model = "M1_freq_x_scene", DV = "TTC_s", .before = 1)
  print_anova(m1_res, "M1: TTC ~ frequency x scene  (4 x 3 RM-ANOVA, GG-corrected)")
}

# =========================================================================
# MODEL 2 — depth x scene (3 x 3 RM-ANOVA, flickering only)
# Aggregate: participant x modulation_depth x scene  (mean over flickering freqs)
# =========================================================================
cat("\n[M2] Aggregate: participant x depth x scene\n")

agg_m2 <- master %>%
  filter(!flag_skipped_trial, !is.na(modulation_depth)) %>%
  group_by(participant_id, modulation_depth, scene) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop") %>%
  filter(!is.na(TTC_s))

cat(sprintf("  Rows: %d  (expected 225 = 25 x 3 x 3)\n", nrow(agg_m2)))

fit_m2 <- tryCatch(
  afex::aov_ez(id = "participant_id", dv = "TTC_s", data = agg_m2,
               within = c("modulation_depth", "scene"), type = 3,
               anova_table = list(correction = "GG", es = "pes")),
  error = function(e) { message("[WARN] M2 failed: ", e$message); NULL }
)

m2_res <- tibble()
if (!is.null(fit_m2)) {
  m2_res <- add_eta_ci(anova(fit_m2, correction = "GG", es = "pes")) %>%
    mutate(Model = "M2_depth_x_scene", DV = "TTC_s", .before = 1)
  print_anova(m2_res,
    "M2: TTC ~ depth x scene  (3 x 3 RM-ANOVA, flickering only, GG-corrected)")
}

# =========================================================================
# MODEL 3 — LMM: frequency x depth x scene (trial-level, flickering only)
# LMM handles P03/P11 missing cell at 8.33/60%/scene C gracefully
# =========================================================================
cat("\n[M3] LMM: TTC ~ freq x depth x scene + (1|participant_id)\n")

flicker_trials <- master %>%
  filter(!flag_skipped_trial, !is.na(modulation_depth), !is.na(TTC_s)) %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

cat(sprintf("  Trial-level rows: %d\n", nrow(flicker_trials)))

lmm_m3 <- tryCatch(
  lmerTest::lmer(
    TTC_s ~ frequency * modulation_depth * scene + (1 | participant_id),
    data    = flicker_trials,
    REML    = TRUE,
    control = lme4::lmerControl(optimizer = "bobyqa")
  ),
  error = function(e) { message("[WARN] M3 LMM failed: ", e$message); NULL }
)

m3_res <- tibble()
if (!is.null(lmm_m3)) {
  m3_aov <- anova(lmm_m3, ddf = "Satterthwaite") %>%
    as.data.frame() %>% tibble::rownames_to_column("Effect") %>% as_tibble() %>%
    rename(F_value = `F value`, p_value = `Pr(>F)`) %>%
    mutate(across(where(is.numeric), ~round(.x, 4)))
  m3_res <- m3_aov %>% mutate(Model = "M3_LMM_full", DV = "TTC_s", .before = 1)
  cat("\n", strrep("-", 70), "\n")
  cat("M3: TTC ~ freq x depth x scene + (1|participant)  [LMM, Satterthwaite]\n")
  cat(strrep("-", 70), "\n")
  for (i in seq_len(nrow(m3_aov))) {
    r <- m3_aov[i, ]
    cat(sprintf("  %-40s F(%s, %s) = %7.3f  p = %.4f %-3s\n",
                r$Effect,
                round(r$NumDF, 1), round(r$DenDF, 1),
                r$F_value, r$p_value, sig_star(r$p_value)))
  }
}

# =========================================================================
# POST-HOC — Bonferroni pairwise: Scene A vs B, A vs C, B vs C
# Derived from M1 scene marginal means (averaged over frequency)
# Applied when scene main effect p < .05
# =========================================================================
cat("\n", strrep("=", 70), "\n")
cat("POST-HOC: Bonferroni pairwise t-tests between scenes (from M1)\n")
cat(strrep("=", 70), "\n")

scene_emm    <- tibble()
scene_ph     <- tibble()
scene_int_ph <- tibble()

if (!is.null(fit_m1)) {
  scene_p <- m1_res %>% filter(Effect == "scene") %>% pull(p_GG)

  emm_scene <- emmeans(fit_m1, ~scene)
  scene_emm <- summary(emm_scene) %>% as_tibble() %>%
    mutate(across(where(is.numeric), ~round(.x, 4)))

  cat("\nScene marginal means (averaged over 4 frequency levels):\n")
  for (sc in c("A","B","C")) {
    r <- scene_emm %>% filter(scene == sc)
    cat(sprintf("  Scene %s: M = %.3f s  SE = %.3f  95%% CI [%.3f, %.3f]\n",
                sc, r$emmean, r$SE, r$lower.CL, r$upper.CL))
  }

  if (!is.na(scene_p) && scene_p < 0.05) {
    cat(sprintf("\nScene main effect SIGNIFICANT (p = %.4f %s)\n",
                scene_p, sig_star(scene_p)))
    cat("  3 comparisons -> Bonferroni alpha = 0.05/3 = 0.0167\n\n")

    pairs_scene <- summary(pairs(emm_scene, adjust = "bonferroni"), infer = TRUE) %>%
      as_tibble() %>%
      mutate(
        mean_diff_s = round(estimate, 3),
        across(where(is.numeric), ~round(.x, 4)),
        sig = case_when(
          p.value < .001 ~ "***",
          p.value < .01  ~ "**",
          p.value < .05  ~ "*",
          TRUE            ~ "ns"
        )
      )

    scene_ph <- pairs_scene

    cat(sprintf("  %-12s  delta(s)   SE     df       t       p_Bonf   sig\n", "Contrast"))
    cat(sprintf("  %s\n", strrep("-", 62)))
    for (i in seq_len(nrow(pairs_scene))) {
      r <- pairs_scene[i, ]
      cat(sprintf("  %-12s  %+7.3f   %.3f  %5.1f   %+6.3f  %.4f   %s\n",
                  r$contrast, r$mean_diff_s, r$SE, r$df, r$t.ratio, r$p.value, r$sig))
    }

    sig_pairs <- pairs_scene %>% filter(p.value < 0.05)
    if (nrow(sig_pairs) > 0) {
      cat("\n  Significant pairs after Bonferroni correction:\n")
      for (i in seq_len(nrow(sig_pairs))) {
        r <- sig_pairs[i, ]
        cat(sprintf("  [%s] %s  |delta| = %.3f s  95%% CI [%.3f, %.3f]\n",
                    r$sig, r$contrast, abs(r$mean_diff_s), r$lower.CL, r$upper.CL))
      }
    } else {
      cat("\n  No pairwise scene comparisons survive Bonferroni correction (all p > 0.05).\n")
    }

    # Decompose interaction if significant
    int_row <- m1_res %>% filter(str_detect(Effect, "frequency") & str_detect(Effect, "scene"))
    if (nrow(int_row) > 0 && !is.na(int_row$p_GG) && int_row$p_GG < 0.05) {
      cat(sprintf("\n  frequency x scene interaction SIGNIFICANT (p = %.4f) — decomposing by frequency:\n",
                  int_row$p_GG))
      emm_by_freq <- emmeans(fit_m1, ~scene | frequency)
      ph_by_freq  <- summary(pairs(emm_by_freq, adjust = "bonferroni"), infer = TRUE) %>%
        as_tibble() %>%
        mutate(
          across(where(is.numeric), ~round(.x, 4)),
          sig = case_when(p.value < .001 ~ "***", p.value < .01 ~ "**",
                          p.value < .05 ~ "*", TRUE ~ "ns")
        )
      scene_int_ph <- ph_by_freq
      print(ph_by_freq %>% select(contrast, frequency, estimate, SE, df, t.ratio, p.value, sig))
    }

  } else {
    cat(sprintf("\n  Scene main effect NOT significant (p = %.4f %s)\n",
                coalesce(scene_p, NA_real_), sig_star(scene_p)))
    cat("  Post-hoc pairwise tests not warranted; descriptive means reported above.\n")
  }
}

# =========================================================================
# Descriptive TTC by scene
# =========================================================================
scene_desc <- master %>%
  filter(!flag_skipped_trial, !is.na(TTC_s)) %>%
  group_by(scene) %>%
  summarise(
    N  = n(),
    M  = round(mean(TTC_s), 3),
    SD = round(sd(TTC_s),   3),
    SE = round(sd(TTC_s) / sqrt(n()), 3),
    .groups = "drop"
  )

cat("\nDescriptive TTC by scene (raw trial-level, all conditions):\n")
print(as.data.frame(scene_desc))

# =========================================================================
# Save
# =========================================================================
all_anova_res <- bind_rows(m1_res, m2_res)
save_csv(all_anova_res, "11_scene_anova_main")
save_csv(m3_res,        "11_scene_lmm")
save_csv(scene_emm,     "11_scene_emm")
save_csv(scene_ph,      "11_scene_posthoc_bonferroni")
save_csv(scene_desc,    "11_scene_descriptives")
if (nrow(scene_int_ph) > 0)
  save_csv(scene_int_ph, "11_scene_posthoc_by_freq")

cat("\n", strrep("=", 70), "\n")
cat("SCENE ANALYSIS SUMMARY — Effects involving 'scene'\n")
cat(strrep("=", 70), "\n")
if (nrow(all_anova_res) > 0) {
  scene_efx <- all_anova_res %>% filter(str_detect(Effect, "scene"))
  for (i in seq_len(nrow(scene_efx))) {
    r <- scene_efx[i, ]
    cat(sprintf("  [%-20s] %-35s F(%s,%s)=%.3f p=%.4f %-3s eta_p2=%.3f\n",
                r$Model, r$Effect, r$num_df, r$den_df_GG,
                r$F, r$p_GG, sig_star(r$p_GG), r$pes))
  }
}
cat("\n11_scene_anova.R DONE\n")
cat("  -> 11_scene_anova_main.csv   (M1 + M2 RM-ANOVA)\n")
cat("  -> 11_scene_lmm.csv          (M3 LMM type-III)\n")
cat("  -> 11_scene_emm.csv          (scene marginal means)\n")
cat("  -> 11_scene_posthoc_bonferroni.csv\n")
cat("  -> 11_scene_descriptives.csv\n")
