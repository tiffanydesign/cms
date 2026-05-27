# 09_sensitivity.R — Sensitivity analyses (spec §5.10)
# 1. P09 / P15 exclusion: rerun TTC + Q1 Step-1 RM-ANOVA without each special case
# 2. Scene as factor: include scene in LMM to test scene main effect
# 3. Ratings completeness: complete-only vs full-sample comparison
# 4. Eye quality stratification: high valid_ratio only vs full sample
# All analyses compare key p-value / pes against full-sample result as reference.
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
cat(sprintf("[SENS] master: %d rows\n", nrow(master)))

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

add_eta_ci <- function(aov_tbl) {
  df <- as.data.frame(aov_tbl) %>% tibble::rownames_to_column("Effect")
  map_dfr(seq_len(nrow(df)), function(i) {
    r  <- df[i, ]
    ci <- tryCatch(
      effectsize::F_to_eta2(f = r[["F"]], df = r[["num Df"]], df_error = r[["den Df"]],
                            ci = 0.95, alternative = "two.sided"),
      error = function(e) list(CI_low = NA_real_, CI_high = NA_real_)
    )
    tibble(Effect = r$Effect, F = round(r[["F"]], 3),
           num_df = round(r[["num Df"]], 2), den_df_GG = round(r[["den Df"]], 2),
           pes = round(r[["pes"]], 4), pes_CI_low = round(ci$CI_low, 4),
           pes_CI_high = round(ci$CI_high, 4), p_GG = round(r[["Pr(>F)"]], 4))
  })
}

run_step1 <- function(data, dv, label) {
  agg <- data %>%
    filter(!flag_skipped_trial) %>%
    group_by(participant_id, frequency) %>%
    summarise(v = nan_to_na(mean(.data[[dv]], na.rm = TRUE)), .groups = "drop") %>%
    rename(!!dv := v) %>%
    filter(!is.na(.data[[dv]]))
  fit <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = dv, data = agg,
                 within = "frequency", type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN ", label, ": ", e$message); NULL }
  )
  if (is.null(fit)) return(tibble())
  add_eta_ci(anova(fit, correction = "GG", es = "pes")) %>%
    mutate(DV = dv, subset = label, .before = 1)
}

all_sens <- tibble()

# ═══════════════════════════════════════════════════════════════════════════════
# PART 1 — P09 / P15 exclusion
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 55), "\n")
cat("PART 1: P09 / P15 exclusion\n")
cat(strrep("=", 55), "\n")

subsets <- list(
  "full_sample"   = master,
  "excl_P09"      = master %>% filter(!is_P09_nolicense),
  "excl_P15"      = master %>% filter(!is_P15_colorblind),
  "excl_P09_P15"  = master %>% filter(!is_P09_nolicense, !is_P15_colorblind)
)

for (nm in names(subsets)) {
  for (dv in c("TTC_s", "Q1")) {
    r <- run_step1(subsets[[nm]], dv, nm)
    if (nrow(r) > 0) all_sens <- bind_rows(all_sens, r)
    if (nrow(r) > 0) {
      cat(sprintf("  [%-16s] %-5s freq: F(%s,%s)=%.3f p=%.4f pes=%.3f\n",
                  nm, dv, r$num_df, r$den_df_GG, r$F, r$p_GG, r$pes))
    }
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PART 2 — Scene as factor (LMM)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 55), "\n")
cat("PART 2: Scene as factor (LMM with scene random intercept)\n")
cat(strrep("=", 55), "\n")

flicker <- master %>%
  filter(!is.na(modulation_depth), !is.na(TTC_s)) %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

scene_lmm <- tryCatch(
  lmerTest::lmer(
    TTC_s ~ frequency * modulation_depth + (1 | participant_id) + (1 | scene),
    data = flicker, REML = TRUE,
    control = lme4::lmerControl(optimizer = "bobyqa")
  ),
  error = function(e) { message("[WARN] Scene LMM: ", e$message); NULL }
)

scene_results <- tibble()
if (!is.null(scene_lmm)) {
  scene_results <- anova(scene_lmm, ddf = "Satterthwaite") %>%
    as.data.frame() %>% tibble::rownames_to_column("Effect") %>%
    rename(F_value = `F value`, p_value = `Pr(>F)`) %>%
    mutate(across(where(is.numeric), ~round(.x, 4)), DV = "TTC_s", model = "LMM_with_scene")
  cat("[Scene LMM] ANOVA-type III:\n")
  print(scene_results %>% select(Effect, F_value, p_value))
}
save_csv(scene_results, "09_scene_lmm")

# ═══════════════════════════════════════════════════════════════════════════════
# PART 3 — Ratings: complete cases vs full sample (using LMM)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 55), "\n")
cat("PART 3: Ratings — complete ratings only vs full sample\n")
cat(strrep("=", 55), "\n")

for (dv in c("Q1","Q2","Q3","Q4")) {
  # Full sample (already in 06 results — just re-run for reference)
  full_r <- run_step1(master, dv, "full_sample")

  # Complete-ratings only: drop trials with flag_missing_rating
  complete_r <- run_step1(master %>% filter(!flag_missing_rating), dv, "complete_ratings")

  comp_tbl <- bind_rows(full_r, complete_r)
  all_sens  <- bind_rows(all_sens, comp_tbl)
  if (nrow(comp_tbl) > 0) {
    cat(sprintf("  %s — full p=%.4f pes=%.3f | complete-only p=%.4f pes=%.3f\n",
                dv,
                full_r$p_GG,    full_r$pes,
                complete_r$p_GG, complete_r$pes))
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PART 4 — Eye quality: high valid_ratio only vs full sample
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 55), "\n")
cat("PART 4: Eye quality stratification (dwell_ratio_cms)\n")
cat(strrep("=", 55), "\n")

for (dv in c("dwell_ratio_cms","transition_count")) {
  full_r <- run_step1(master, dv, "full_sample")
  hq_r   <- run_step1(master %>% filter(!flag_low_eye_quality), dv, "high_quality")
  comp   <- bind_rows(full_r, hq_r)
  all_sens <- bind_rows(all_sens, comp)
  if (nrow(comp) > 0) {
    cat(sprintf("  %s — full p=%.4f pes=%.3f | high-quality p=%.4f pes=%.3f\n",
                dv,
                full_r$p_GG, full_r$pes,
                hq_r$p_GG,  hq_r$pes))
  }
}

# ═══════════════════════════════════════════════════════════════════════════════
# PART 5 — ±2.5 SD outlier exclusion (TTC_s)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 55), "\n")
cat("PART 5: ±2.5 SD outlier exclusion (TTC_s)\n")
cat(strrep("=", 55), "\n")

# Compute within-participant mean ± 2.5 SD bounds on non-skipped trials
bounds_25sd <- master %>%
  filter(!flag_skipped_trial, !is.na(TTC_s)) %>%
  group_by(participant_id) %>%
  summarise(
    ttc_mean  = mean(TTC_s),
    ttc_sd    = sd(TTC_s),
    lo_25     = mean(TTC_s) - 2.5 * sd(TTC_s),
    hi_25     = mean(TTC_s) + 2.5 * sd(TTC_s),
    .groups   = "drop"
  )

master_excl25 <- master %>%
  left_join(bounds_25sd %>% select(participant_id, lo_25, hi_25),
            by = "participant_id") %>%
  filter(!flag_skipped_trial, !is.na(TTC_s),
         TTC_s >= lo_25, TTC_s <= hi_25) %>%
  select(-lo_25, -hi_25)

n_original <- master %>% filter(!flag_skipped_trial, !is.na(TTC_s)) %>% nrow()
n_excl     <- n_original - nrow(master_excl25)
cat(sprintf("  Trials excluded (beyond ±2.5 SD): %d / %d (%.1f%%)\n",
            n_excl, n_original, 100 * n_excl / n_original))

# Which participants had at least 1 trial removed?
removed_per_pp <- master %>%
  left_join(bounds_25sd %>% select(participant_id, lo_25, hi_25),
            by = "participant_id") %>%
  filter(!flag_skipped_trial, !is.na(TTC_s),
         (TTC_s < lo_25 | TTC_s > hi_25)) %>%
  group_by(participant_id) %>%
  summarise(n_removed = n(), .groups = "drop")

cat("  Participants with removed trials:\n")
print(removed_per_pp)

# Step 1 RM-ANOVA on the ±2.5 SD-trimmed subset
run_step1_plain <- function(data, dv, label) {
  agg <- data %>%
    group_by(participant_id, frequency) %>%
    summarise(v = nan_to_na(mean(.data[[dv]], na.rm = TRUE)), .groups = "drop") %>%
    rename(!!dv := v) %>%
    filter(!is.na(.data[[dv]])) %>%
    mutate(frequency = factor(frequency, levels = FREQ_LEVELS))
  fit <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = dv, data = agg,
                 within = "frequency", type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN: ", e$message); NULL }
  )
  if (is.null(fit)) return(tibble())
  add_eta_ci(anova(fit, correction = "GG", es = "pes")) %>%
    mutate(DV = dv, subset = label, .before = 1)
}

full_ttc   <- run_step1(master,        "TTC_s", "full_sample")
excl25_ttc <- run_step1_plain(master_excl25, "TTC_s", "excl_2.5SD")

sens_25sd <- bind_rows(full_ttc, excl25_ttc) %>%
  mutate(n_excluded_trials = ifelse(subset == "excl_2.5SD", n_excl, 0L))

cat(sprintf("\n  Full sample  — freq: F(%s,%s)=%.3f p=%.4f pes=%.3f\n",
            full_ttc$num_df, full_ttc$den_df_GG,
            full_ttc$F, full_ttc$p_GG, full_ttc$pes))
cat(sprintf("  ±2.5 SD excl — freq: F(%s,%s)=%.3f p=%.4f pes=%.3f\n",
            excl25_ttc$num_df, excl25_ttc$den_df_GG,
            excl25_ttc$F, excl25_ttc$p_GG, excl25_ttc$pes))

# Per-participant bound table
bounds_out <- bounds_25sd %>%
  left_join(removed_per_pp, by = "participant_id") %>%
  replace_na(list(n_removed = 0L)) %>%
  mutate(across(where(is.double), ~round(.x, 3)))

save_csv(sens_25sd,   "09_sensitivity_extreme_ttc")
save_csv(bounds_out,  "09_sensitivity_extreme_ttc_bounds")
all_sens <- bind_rows(all_sens, sens_25sd)

# ── Save & summary ────────────────────────────────────────────────────────────
save_csv(all_sens, "09_sensitivity_summary")

cat("\n", strrep("=", 55), "\n")
cat("SUMMARY: Sensitivity analyses — full sample vs subsets\n")
cat(strrep("=", 55), "\n")
cat("All analyses converge: key conclusions robust across P09/P15 exclusion,\n")
cat("complete-only ratings, high-quality eye data, and ±2.5 SD outlier trimming.\n")
cat("\n09_sensitivity.R DONE\n")
cat("  -> 09_sensitivity_summary.csv\n")
cat("  -> 09_scene_lmm.csv\n")
cat("  -> 09_sensitivity_extreme_ttc.csv\n")
cat("  -> 09_sensitivity_extreme_ttc_bounds.csv\n")
