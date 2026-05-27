# 07_anova_eye.R — Eye metrics two-step RM-ANOVA + GLMM robustness (spec §5.8)
# Continuous metrics: dwell_ratio_cms, dwell_time_cms_ms,
#                    fixation_duration_cms_mean_ms, fixation_duration_road_mean_ms
# Count metrics:     transition_count, fixation_count_cms, fixation_count_road
#   -> also Poisson / negative-binomial GLMM robustness
# first_fixation_cms_time_ms: two-stage per spec 4.3 (-1 = no fixation, not a value)
#   Stage 1: proportion of trials with CMS fixation (logistic GLMM)
#   Stage 2: latency RM-ANOVA for cms_fixated == TRUE only
# Pupil: columns absent from data -- caveat note only
# valid_ratio: quality sensitivity stratification
source(here::here("R", "00_setup.R"))

if (!requireNamespace("effectsize", quietly = TRUE))
  install.packages("effectsize", repos = "https://cloud.r-project.org")
if (!requireNamespace("MASS",      quietly = TRUE))
  install.packages("MASS",      repos = "https://cloud.r-project.org")
library(effectsize)
library(MASS)
select <- dplyr::select   # MASS::select masks dplyr::select; restore dplyr version

# ── Load ──────────────────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS),
    scene            = factor(scene),
    cms_fixated      = (!is.na(first_fixation_cms_time_ms)) &
                       (first_fixation_cms_time_ms != -1)
  )

cat(sprintf("[EYE] master: %d rows | cms_fixated: %d | flag_low_eye_quality: %d\n",
            nrow(master),
            sum(master$cms_fixated, na.rm = TRUE),
            sum(master$flag_low_eye_quality, na.rm = TRUE)))

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

# ── Pupil caveat ───────────────────────────────────────────────────────────────
pupil_cols   <- c("pupil_diameter_mean", "pupil_diameter_std",
                  "pupil_diameter_cms",  "pupil_diameter_road")
present_pupil <- intersect(pupil_cols, names(master))
cat("\n[PUPIL] Checking pupil columns...\n")
if (length(present_pupil) == 0) {
  cat("  CAVEAT: No pupil columns found in master_long.csv.\n")
  cat("  Pupil analysis requires luminance-controlled pupillometry data.\n")
  cat("  Screen brightness was not held constant across conditions --\n")
  cat("  any pupil diameter differences would be uninterpretable.\n")
  cat("  Skipping pupil RM-ANOVA.\n")
} else {
  cat(sprintf("  Pupil columns present: %s\n", paste(present_pupil, collapse = ", ")))
  cat("  CAVEAT: Interpret with caution -- luminance not controlled.\n")
}
save_csv(tibble(note = paste(
  "Pupil columns absent from master_long.csv.",
  "Pupil analysis requires luminance-controlled conditions.",
  "Screen brightness was not held constant -- pupil data uninterpretable.",
  "Analysis skipped."
)), "07_eye_pupil_caveat")

# ── Helpers ───────────────────────────────────────────────────────────────────
add_eta_ci <- function(aov_tbl) {
  df <- as.data.frame(aov_tbl) %>% tibble::rownames_to_column("Effect")
  map_dfr(seq_len(nrow(df)), function(i) {
    r  <- df[i, ]
    ci <- tryCatch(
      effectsize::F_to_eta2(f = r[["F"]], df = r[["num Df"]], df_error = r[["den Df"]],
                            ci = 0.95, alternative = "two.sided"),
      error = function(e) list(CI_low = NA_real_, CI_high = NA_real_)
    )
    tibble(Effect      = r$Effect,
           F           = round(r[["F"]],        3),
           num_df      = round(r[["num Df"]],   2),
           den_df_GG   = round(r[["den Df"]],   2),
           MSE         = round(r[["MSE"]],       4),
           pes         = round(r[["pes"]],       4),
           pes_CI_low  = round(ci$CI_low,        4),
           pes_CI_high = round(ci$CI_high,       4),
           p_GG        = round(r[["Pr(>F)"]],    4))
  })
}

make_step1_agg <- function(dv) {
  master %>%
    group_by(participant_id, frequency) %>%
    summarise(v = nan_to_na(mean(.data[[dv]], na.rm = TRUE)), .groups = "drop") %>%
    rename(!!dv := v)
}

make_step2_agg <- function(dv) {
  master %>%
    filter(!is.na(modulation_depth)) %>%
    group_by(participant_id, frequency, modulation_depth) %>%
    summarise(v = nan_to_na(mean(.data[[dv]], na.rm = TRUE)), .groups = "drop") %>%
    rename(!!dv := v) %>%
    mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))
}

CON_LIST <- list(
  "8.33 Hz vs 0 Hz" = c(-1, 1, 0, 0),
  "12.5 Hz vs 0 Hz" = c(-1, 0, 1, 0),
  "25 Hz vs 0 Hz"   = c(-1, 0, 0, 1)
)

# ═══════════════════════════════════════════════════════════════════════════════
# PART A -- Two-step RM-ANOVA for continuous and count eye metrics
# ═══════════════════════════════════════════════════════════════════════════════
CONT_DVS  <- c("dwell_ratio_cms", "dwell_time_cms_ms",
               "fixation_duration_cms_mean_ms", "fixation_duration_road_mean_ms")
COUNT_DVS <- c("transition_count", "fixation_count_cms", "fixation_count_road")
ALL_DVS   <- c(CONT_DVS, COUNT_DVS)

all_s1_main  <- tibble(); all_s1_contr <- tibble(); all_s1_emm <- tibble()
all_s2_main  <- tibble(); all_s2_ph    <- tibble()
summary_tbl  <- tibble()

for (dv in ALL_DVS) {
  cat(sprintf("\n%s\n%s\n%s\n", strrep("-", 55), dv, strrep("-", 55)))

  s1 <- make_step1_agg(dv)
  s2 <- make_step2_agg(dv)

  if (all(is.na(s1[[dv]]))) {
    cat(sprintf("  SKIP: %s is all-NA in step1.\n", dv)); next
  }

  # ── Step 1 ──────────────────────────────────────────────────────────────────
  fit1 <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = dv, data = s1,
                 within = "frequency", type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN s1 ", dv, ": ", e$message); NULL }
  )
  if (is.null(fit1)) next

  s1_main <- add_eta_ci(anova(fit1, correction = "GG", es = "pes")) %>%
    mutate(DV = dv, .before = 1)
  all_s1_main <- bind_rows(all_s1_main, s1_main)

  emm1    <- emmeans(fit1, ~frequency)
  emm1_df <- summary(emm1) %>% as_tibble() %>%
    mutate(DV = dv, across(where(is.numeric), ~round(.x, 3)))
  all_s1_emm <- bind_rows(all_s1_emm, emm1_df)

  contr1 <- summary(contrast(emm1, method = CON_LIST, adjust = "holm"), infer = TRUE) %>%
    as_tibble() %>% mutate(DV = dv, across(where(is.numeric), ~round(.x, 4)))
  all_s1_contr <- bind_rows(all_s1_contr, contr1)

  cat(sprintf("  Step1: F(%s,%s)=%.3f p=%.4f ηp²=%.3f\n",
              s1_main$num_df, s1_main$den_df_GG, s1_main$F,
              s1_main$p_GG, s1_main$pes))
  print(contr1 %>% select(contrast, estimate, t.ratio, p.value))

  # ── Step 2 ──────────────────────────────────────────────────────────────────
  fit2 <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = dv, data = s2,
                 within = c("frequency", "modulation_depth"), type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN s2 ", dv, ": ", e$message); NULL }
  )
  if (!is.null(fit2)) {
    s2_main <- add_eta_ci(anova(fit2, correction = "GG", es = "pes")) %>%
      mutate(DV = dv, .before = 1)
    all_s2_main <- bind_rows(all_s2_main, s2_main)

    int_p <- s2_main %>% filter(str_detect(Effect, ":")) %>% pull(p_GG)
    cat(sprintf("  Step2 freq: p=%.4f  depth: p=%.4f  int: p=%.4f\n",
                s2_main$p_GG[1], s2_main$p_GG[2], coalesce(int_p, NA_real_)))

    ph_f <- summary(pairs(emmeans(fit2, ~frequency),
                          adjust = "holm"), infer = TRUE) %>%
      as_tibble() %>%
      mutate(DV = dv, factor = "frequency", across(where(is.numeric), ~round(.x, 4)))
    ph_d <- summary(pairs(emmeans(fit2, ~modulation_depth),
                          adjust = "holm"), infer = TRUE) %>%
      as_tibble() %>%
      mutate(DV = dv, factor = "modulation_depth", across(where(is.numeric), ~round(.x, 4)))

    if (!is.na(int_p) && int_p < 0.05) {
      ph_i <- summary(pairs(emmeans(fit2, ~frequency * modulation_depth),
                            adjust = "holm"), infer = TRUE) %>%
        as_tibble() %>%
        mutate(DV = dv, factor = "freq_x_dep", across(where(is.numeric), ~round(.x, 4)))
      all_s2_ph <- bind_rows(all_s2_ph, ph_f, ph_d, ph_i)
      cat("  [!] Interaction significant -- cell pairs included.\n")
    } else {
      all_s2_ph <- bind_rows(all_s2_ph, ph_f, ph_d)
    }

    summary_tbl <- bind_rows(summary_tbl, tibble(
      DV          = dv,
      s1_F        = s1_main$F,
      s1_df       = paste0(s1_main$num_df, ", ", s1_main$den_df_GG),
      s1_p        = s1_main$p_GG,
      s1_pes      = s1_main$pes,
      s2_freq_p   = s2_main$p_GG[s2_main$Effect == "frequency"],
      s2_freq_pes = s2_main$pes[s2_main$Effect == "frequency"],
      s2_dep_p    = s2_main$p_GG[s2_main$Effect == "modulation_depth"],
      s2_dep_pes  = s2_main$pes[s2_main$Effect == "modulation_depth"],
      s2_int_p    = coalesce(s2_main$p_GG[str_detect(s2_main$Effect, ":")][1], NA_real_),
      s2_int_pes  = coalesce(s2_main$pes[str_detect(s2_main$Effect, ":")][1], NA_real_)
    ))
  }
}

save_csv(all_s1_main,  "07_eye_step1_main")
save_csv(all_s1_contr, "07_eye_step1_contrasts")
save_csv(all_s1_emm,   "07_eye_step1_emm")
save_csv(all_s2_main,  "07_eye_step2_main")
save_csv(all_s2_ph,    "07_eye_step2_posthoc")
save_csv(summary_tbl,  "07_eye_summary")

# ═══════════════════════════════════════════════════════════════════════════════
# PART B -- Count metrics: Poisson / NB GLMM robustness (trial-level flickering)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("PART B: Count GLMM (Poisson -> NB if overdispersed)\n")
cat(strrep("=", 60), "\n")

flicker_trials <- master %>%
  filter(!is.na(modulation_depth)) %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

all_glmm <- tibble()

for (dv in COUNT_DVS) {
  cat(sprintf("\n  GLMM: %s\n", dv))

  dat      <- flicker_trials %>% filter(!is.na(.data[[dv]]))
  dat[[dv]] <- as.integer(round(dat[[dv]]))

  glmm_pois <- tryCatch(
    lme4::glmer(
      reformulate(c("frequency * modulation_depth",
                    "(1 | participant_id)", "(1 | scene)"),
                  response = dv),
      data    = dat,
      family  = poisson(link = "log"),
      control = lme4::glmerControl(optimizer = "bobyqa")
    ),
    error = function(e) { message("    Poisson failed: ", e$message); NULL }
  )

  overdisp_ratio <- NA_real_
  use_nb         <- FALSE
  if (!is.null(glmm_pois)) {
    overdisp_ratio <- deviance(glmm_pois) / df.residual(glmm_pois)
    cat(sprintf("    Poisson overdispersion ratio = %.3f\n", overdisp_ratio))
    use_nb <- overdisp_ratio > 1.5
  }

  if (is.null(glmm_pois) || use_nb) {
    cat("    -> Fitting NB GLMM (lme4::glmer + MASS::negative.binomial)\n")
    # Estimate theta from Poisson model if available, else use moment estimate
    theta_init <- tryCatch({
      if (!is.null(glmm_pois))
        MASS::theta.ml(y = dat[[dv]], mu = fitted(glmm_pois), limit = 50)
      else
        mean(dat[[dv]])^2 / max(var(dat[[dv]]) - mean(dat[[dv]]), 0.1)
    }, error = function(e) 5)
    glmm_nb <- tryCatch(
      lme4::glmer(
        reformulate(c("frequency * modulation_depth",
                      "(1 | participant_id)", "(1 | scene)"),
                    response = dv),
        data    = dat,
        family  = MASS::negative.binomial(theta = theta_init),
        control = lme4::glmerControl(optimizer = "bobyqa")
      ),
      error = function(e) { message("    NB failed: ", e$message); NULL }
    )
    final_fit  <- if (!is.null(glmm_nb)) glmm_nb else glmm_pois
    model_type <- if (!is.null(glmm_nb)) "NB" else "Poisson(overdispersed)"
  } else {
    final_fit  <- glmm_pois
    model_type <- "Poisson"
  }

  if (!is.null(final_fit)) {
    fixed_df <- broom.mixed::tidy(final_fit, effects = "fixed",
                                  conf.int = TRUE, conf.level = 0.95) %>%
      mutate(DV = dv, model = model_type,
             overdispersion_ratio = round(overdisp_ratio, 3),
             across(where(is.numeric), ~round(.x, 4)))
    all_glmm <- bind_rows(all_glmm, fixed_df)
    cat(sprintf("    Model: %s | fixed terms: %d\n", model_type, nrow(fixed_df)))
    print(fixed_df %>% select(term, estimate, std.error, statistic, p.value) %>% head(6))
  }
}

save_csv(all_glmm, "07_eye_count_glmm")

# ═══════════════════════════════════════════════════════════════════════════════
# PART C -- first_fixation_cms_time_ms: two-stage
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("PART C: first_fixation -- Stage 1 proportion + Stage 2 latency\n")
cat(strrep("=", 60), "\n")

# Stage 1: proportion cms_fixated by frequency
cat("\n[Stage 1] Proportion fixated by frequency\n")
fix_prop_freq <- master %>%
  group_by(frequency) %>%
  summarise(n_trials    = n(),
            n_fixated   = sum(cms_fixated, na.rm = TRUE),
            pct_fixated = round(100 * mean(cms_fixated, na.rm = TRUE), 1),
            .groups = "drop")
print(fix_prop_freq)
save_csv(fix_prop_freq, "07_eye_firstfix_stage1_prop_by_freq")

fix_prop_full <- master %>%
  group_by(frequency, modulation_depth) %>%
  summarise(n_trials    = n(),
            n_fixated   = sum(cms_fixated, na.rm = TRUE),
            pct_fixated = round(100 * mean(cms_fixated, na.rm = TRUE), 1),
            .groups = "drop")
save_csv(fix_prop_full, "07_eye_firstfix_stage1_prop_full")
print(fix_prop_full, n = 15)

# Logistic GLMM: P(cms_fixated) ~ frequency + (1|participant_id)
cat("\n  [Stage 1 GLMM] Logistic: P(fixated) ~ frequency + (1|participant)\n")
logit_fit <- tryCatch(
  lme4::glmer(
    cms_fixated ~ frequency + (1 | participant_id),
    data    = master,
    family  = binomial(link = "logit"),
    control = lme4::glmerControl(optimizer = "bobyqa")
  ),
  error = function(e) { message("    Logistic GLMM failed: ", e$message); NULL }
)
if (!is.null(logit_fit)) {
  logit_df <- broom.mixed::tidy(logit_fit, effects = "fixed",
                                conf.int = TRUE, conf.level = 0.95,
                                exponentiate = FALSE) %>%
    mutate(OR = round(exp(estimate), 3),
           across(where(is.numeric), ~round(.x, 4)))
  save_csv(logit_df, "07_eye_firstfix_stage1_logit")
  cat("\n  Log-odds and OR:\n")
  print(logit_df %>% select(term, estimate, OR, std.error, statistic, p.value))
}

# Stage 2: latency RM-ANOVA on cms_fixated == TRUE trials only
cat("\n[Stage 2] Latency RM-ANOVA (cms_fixated == TRUE)\n")

latency_trials <- master %>%
  filter(cms_fixated == TRUE, !is.na(first_fixation_cms_time_ms))
cat(sprintf("  Trials with CMS fixation: %d / %d (%.1f%%)\n",
            nrow(latency_trials), nrow(master),
            100 * nrow(latency_trials) / nrow(master)))

# Step 1 latency: participant x frequency (4 levels)
lat_s1 <- latency_trials %>%
  group_by(participant_id, frequency) %>%
  summarise(first_fixation_cms_time_ms =
              nan_to_na(mean(first_fixation_cms_time_ms, na.rm = TRUE)),
            .groups = "drop") %>%
  filter(!is.na(first_fixation_cms_time_ms))

# Need participants with all 4 frequency levels for RM-ANOVA
complete_ppt <- lat_s1 %>%
  group_by(participant_id) %>%
  summarise(n = n()) %>%
  filter(n == 4) %>%
  pull(participant_id)
lat_s1_complete <- lat_s1 %>% filter(participant_id %in% complete_ppt)
cat(sprintf("  Participants with all 4 freq levels: %d\n", length(complete_ppt)))

lat_s1_main  <- NULL; lat_s1_emm <- NULL; lat_s1_contr <- NULL
lat_s2_main  <- NULL

if (length(complete_ppt) >= 5) {
  fit_lat1 <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = "first_fixation_cms_time_ms",
                 data = lat_s1_complete, within = "frequency", type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN lat s1: ", e$message); NULL }
  )
  if (!is.null(fit_lat1)) {
    lat_s1_main <- add_eta_ci(anova(fit_lat1, correction = "GG", es = "pes")) %>%
      mutate(DV = "first_fixation_cms_time_ms", stage = "stage2_latency_s1", .before = 1)
    emm_lat     <- emmeans(fit_lat1, ~frequency)
    lat_s1_emm  <- summary(emm_lat) %>% as_tibble() %>%
      mutate(DV = "first_fixation_cms_time_ms", across(where(is.numeric), ~round(.x, 3)))
    lat_s1_contr <- summary(contrast(emm_lat, method = CON_LIST, adjust = "holm"),
                            infer = TRUE) %>%
      as_tibble() %>%
      mutate(DV = "first_fixation_cms_time_ms", across(where(is.numeric), ~round(.x, 4)))
    cat(sprintf("  Stage2 Step1: F(%s,%s)=%.3f p=%.4f ηp²=%.3f\n",
                lat_s1_main$num_df, lat_s1_main$den_df_GG,
                lat_s1_main$F, lat_s1_main$p_GG, lat_s1_main$pes))
    print(lat_s1_contr %>% select(contrast, estimate, t.ratio, p.value))
  }
} else {
  cat(sprintf("  SKIP Step1: only %d participants with all 4 freq levels.\n",
              length(complete_ppt)))
}

# Step 2 latency: participant x freq x depth (flickering only)
lat_s2 <- latency_trials %>%
  filter(!is.na(modulation_depth)) %>%
  group_by(participant_id, frequency, modulation_depth) %>%
  summarise(first_fixation_cms_time_ms =
              nan_to_na(mean(first_fixation_cms_time_ms, na.rm = TRUE)),
            .groups = "drop") %>%
  filter(!is.na(first_fixation_cms_time_ms)) %>%
  mutate(frequency = factor(as.character(frequency), levels = c("8.33","12.5","25")))

complete_ppt2 <- lat_s2 %>%
  group_by(participant_id) %>%
  summarise(n = n()) %>%
  filter(n == 9) %>%
  pull(participant_id)
lat_s2_complete <- lat_s2 %>% filter(participant_id %in% complete_ppt2)
cat(sprintf("  Participants with all 9 cells (Stage2 Step2): %d\n", length(complete_ppt2)))

if (length(complete_ppt2) >= 5) {
  fit_lat2 <- tryCatch(
    afex::aov_ez(id = "participant_id", dv = "first_fixation_cms_time_ms",
                 data = lat_s2_complete,
                 within = c("frequency", "modulation_depth"), type = 3,
                 anova_table = list(correction = "GG", es = "pes")),
    error = function(e) { message("WARN lat s2: ", e$message); NULL }
  )
  if (!is.null(fit_lat2)) {
    lat_s2_main <- add_eta_ci(anova(fit_lat2, correction = "GG", es = "pes")) %>%
      mutate(DV = "first_fixation_cms_time_ms", stage = "stage2_latency_s2", .before = 1)
    int_p_lat <- lat_s2_main %>% filter(str_detect(Effect, ":")) %>% pull(p_GG)
    cat(sprintf("  Stage2 Step2: freq p=%.4f  depth p=%.4f  int p=%.4f\n",
                lat_s2_main$p_GG[1], lat_s2_main$p_GG[2],
                coalesce(int_p_lat, NA_real_)))
  }
} else {
  cat(sprintf("  SKIP Step2: only %d participants with all 9 cells.\n",
              length(complete_ppt2)))
}

if (!is.null(lat_s1_main))  save_csv(lat_s1_main,  "07_eye_firstfix_stage2_s1_main")
if (!is.null(lat_s1_emm))   save_csv(lat_s1_emm,   "07_eye_firstfix_stage2_s1_emm")
if (!is.null(lat_s1_contr)) save_csv(lat_s1_contr, "07_eye_firstfix_stage2_s1_contrasts")
if (!is.null(lat_s2_main))  save_csv(lat_s2_main,  "07_eye_firstfix_stage2_s2_main")

# ═══════════════════════════════════════════════════════════════════════════════
# PART D -- valid_ratio quality sensitivity
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("PART D: valid_ratio quality stratification\n")
cat(strrep("=", 60), "\n")

cat("\nRow distribution by flag_low_eye_quality:\n")
print(master %>% group_by(flag_low_eye_quality) %>% summarise(n = n(), .groups="drop"))

# Repeat dwell_ratio_cms step1 on high-quality subset only
dwell_hq <- master %>%
  filter(flag_low_eye_quality == FALSE) %>%
  group_by(participant_id, frequency) %>%
  summarise(dwell_ratio_cms = nan_to_na(mean(dwell_ratio_cms, na.rm = TRUE)),
            .groups = "drop")

fit_hq <- tryCatch(
  afex::aov_ez(id = "participant_id", dv = "dwell_ratio_cms",
               data = dwell_hq, within = "frequency", type = 3,
               anova_table = list(correction = "GG", es = "pes")),
  error = function(e) { message("WARN hq: ", e$message); NULL }
)

sensitivity_df <- tibble()
if (!is.null(fit_hq)) {
  hq_main <- add_eta_ci(anova(fit_hq, correction = "GG", es = "pes")) %>%
    mutate(DV = "dwell_ratio_cms", subset = "high_quality_only", .before = 1)
  full_main <- all_s1_main %>%
    filter(DV == "dwell_ratio_cms") %>%
    mutate(subset = "full_sample")
  sensitivity_df <- bind_rows(full_main, hq_main)
  cat("\ndwell_ratio_cms: full sample vs high-quality only (step1):\n")
  print(sensitivity_df %>% select(subset, F, num_df, den_df_GG, p_GG, pes))
}
save_csv(sensitivity_df, "07_eye_quality_sensitivity")

# ═══════════════════════════════════════════════════════════════════════════════
# FINAL SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
sig <- function(p) {
  if (is.na(p)) return("n/a")
  if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else "ns"
}

cat("\n", strrep("=", 70), "\n")
cat("SUMMARY: Eye Metrics RM-ANOVA (GG-corrected)\n")
cat(strrep("=", 70), "\n\n")

for (i in seq_len(nrow(summary_tbl))) {
  r <- summary_tbl[i, ]
  cat(sprintf("%-34s  Step1 freq: F(%s)=%.2f p=%.4f ηp²=%.3f %s\n",
              r$DV, r$s1_df, r$s1_F, r$s1_p, r$s1_pes, sig(r$s1_p)))
  cat(sprintf("%-34s  Step2 freq p=%.4f %s | depth p=%.4f %s | int p=%.4f %s\n",
              "", r$s2_freq_p, sig(r$s2_freq_p),
              r$s2_dep_p,  sig(r$s2_dep_p),
              r$s2_int_p,  sig(r$s2_int_p)))
}

if (!is.null(lat_s1_main)) {
  cat(sprintf(
    "\nfirst_fixation latency (Stage2 Step1): F(%s,%s)=%.2f p=%.4f ηp²=%.3f %s\n",
    lat_s1_main$num_df, lat_s1_main$den_df_GG,
    lat_s1_main$F, lat_s1_main$p_GG, lat_s1_main$pes, sig(lat_s1_main$p_GG)))
}

cat("\n07_anova_eye.R DONE\n")
cat("  -> 07_eye_step1_main/contrasts/emm.csv\n")
cat("  -> 07_eye_step2_main/posthoc.csv\n")
cat("  -> 07_eye_summary.csv\n")
cat("  -> 07_eye_count_glmm.csv\n")
cat("  -> 07_eye_firstfix_stage1_prop_*.csv\n")
cat("  -> 07_eye_firstfix_stage1_logit.csv\n")
cat("  -> 07_eye_firstfix_stage2_*.csv\n")
cat("  -> 07_eye_quality_sensitivity.csv\n")
cat("  -> 07_eye_pupil_caveat.csv\n")
