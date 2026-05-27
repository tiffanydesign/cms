# 06_anova_ratings.R — Ratings Q1–Q4 two-step RM-ANOVA + CLMM (spec §5.7)
# Q2-Q3 consistency check → cognitive_load composite if α ≥ .70
# Step 1 (SRQ1): frequency 4-level RM-ANOVA + planned contrasts vs 0 Hz
# Step 2 (SRQ3): frequency × depth two-way RM-ANOVA, GG correction throughout
# CLMM (ordinal::clmm) robustness for each integer-scale Q
# Missing ratings left as NA; no participant deletion.
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
cat(sprintf("[RATINGS] master: %d rows | flag_missing_rating: %d\n",
            nrow(master), sum(master$flag_missing_rating)))

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

# ═══════════════════════════════════════════════════════════════════════════════
# Q2–Q3 CONSISTENCY
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n===== Q2–Q3 Consistency (NASA-TLX: mental demand × effort) =====\n")
q23 <- master %>% filter(!is.na(Q2), !is.na(Q3))
rho    <- cor(q23$Q2, q23$Q3, method = "spearman")
r_p    <- cor(q23$Q2, q23$Q3,  method = "pearson")
alpha2 <- 2 * r_p / (1 + r_p)           # Spearman-Brown for 2-item scale

cat(sprintf("  Spearman ρ = %.3f   Pearson r = %.3f   Cronbach α = %.3f\n",
            rho, r_p, alpha2))

consist_df <- tibble(
  metric = c("Spearman_rho", "Pearson_r", "Cronbach_alpha_2item"),
  value  = round(c(rho, r_p, alpha2), 4)
)
save_csv(consist_df, "06_ratings_q2q3_consistency")

HIGH_CONSIST <- alpha2 >= 0.70
if (HIGH_CONSIST) {
  master <- master %>% mutate(cognitive_load = (Q2 + Q3) / 2)
  cat(sprintf("  → α=%.3f ≥ .70: cognitive_load = mean(Q2,Q3) constructed.\n", alpha2))
} else {
  cat(sprintf("  → α=%.3f < .70: no composite score.\n", alpha2))
}

BASE_DVS   <- c("Q1","Q2","Q3","Q4")
ALL_DVS    <- if (HIGH_CONSIST) c(BASE_DVS, "cognitive_load") else BASE_DVS
CLMM_DVS   <- BASE_DVS          # CLMM only on integer-scale Likert items

# ── Helpers ───────────────────────────────────────────────────────────────────
add_eta_ci <- function(aov_tbl) {
  df <- as.data.frame(aov_tbl) %>% tibble::rownames_to_column("Effect")
  map_dfr(seq_len(nrow(df)), function(i) {
    r <- df[i, ]
    ci <- tryCatch(
      effectsize::F_to_eta2(f = r[["F"]], df = r[["num Df"]], df_error = r[["den Df"]],
                            ci = 0.95, alternative = "two.sided"),
      error = function(e) list(CI_low = NA_real_, CI_high = NA_real_)
    )
    tibble(Effect = r$Effect, F = round(r[["F"]], 3),
           num_df = round(r[["num Df"]], 2), den_df_GG = round(r[["den Df"]], 2),
           MSE    = round(r[["MSE"]], 4),    pes = round(r[["pes"]], 4),
           pes_CI_low = round(ci$CI_low, 4), pes_CI_high = round(ci$CI_high, 4),
           p_GG   = round(r[["Pr(>F)"]], 4))
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
  "8.33 Hz vs 0 Hz"  = c(-1, 1, 0, 0),
  "12.5 Hz vs 0 Hz"  = c(-1, 0, 1, 0),
  "25 Hz vs 0 Hz"    = c(-1, 0, 0, 1)
)

# Collectors
all_s1_main  <- tibble(); all_s1_contr <- tibble(); all_s1_emm  <- tibble()
all_s2_main  <- tibble(); all_s2_ph    <- tibble()
all_clmm     <- tibble()
summary_tbl  <- tibble()

# ═══════════════════════════════════════════════════════════════════════════════
# MAIN LOOP — one DV at a time
# ═══════════════════════════════════════════════════════════════════════════════
for (dv in ALL_DVS) {
  cat(sprintf("\n%s\n%s\n%s\n", strrep("-",55), dv, strrep("-",55)))

  s1 <- make_step1_agg(dv)
  s2 <- make_step2_agg(dv)

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

    int_p  <- s2_main %>% filter(str_detect(Effect, ":")) %>% pull(p_GG)
    cat(sprintf("  Step2 freq: p=%.4f  depth: p=%.4f  int: p=%.4f\n",
                s2_main$p_GG[1], s2_main$p_GG[2], coalesce(int_p, NA_real_)))

    ph_f <- summary(pairs(emmeans(fit2, ~frequency),           adjust = "holm"), infer = TRUE) %>%
      as_tibble() %>% mutate(DV = dv, factor = "frequency",        across(where(is.numeric),~round(.x,4)))
    ph_d <- summary(pairs(emmeans(fit2, ~modulation_depth),    adjust = "holm"), infer = TRUE) %>%
      as_tibble() %>% mutate(DV = dv, factor = "modulation_depth", across(where(is.numeric),~round(.x,4)))

    if (!is.na(int_p) && int_p < 0.05) {
      ph_i <- summary(pairs(emmeans(fit2, ~frequency * modulation_depth),
                            adjust = "holm"), infer = TRUE) %>%
        as_tibble() %>% mutate(DV = dv, factor = "freq_x_dep", across(where(is.numeric),~round(.x,4)))
      all_s2_ph <- bind_rows(all_s2_ph, ph_f, ph_d, ph_i)
      cat("  [!] Interaction significant — cell pairs included.\n")
    } else {
      all_s2_ph <- bind_rows(all_s2_ph, ph_f, ph_d)
    }
  }

  # ── CLMM robustness (integer Likert only) ───────────────────────────────────
  if (dv %in% CLMM_DVS) {
    cat(sprintf("  CLMM %s ...\n", dv))

    make_ord <- function(data, col)
      data %>% filter(!is.na(.data[[col]])) %>%
      mutate(y_ord = factor(.data[[col]], levels = 1:7, ordered = TRUE))

    clmm1 <- tryCatch(
      ordinal::clmm(y_ord ~ frequency + (1 | participant_id),
                    data = make_ord(master, dv), link = "logit"),
      error = function(e) { message("    CLMM s1 failed: ", e$message); NULL }
    )
    clmm2 <- tryCatch(
      ordinal::clmm(y_ord ~ frequency * modulation_depth + (1 | participant_id),
                    data = make_ord(
                      master %>% filter(!is.na(modulation_depth)) %>%
                        mutate(frequency = factor(as.character(frequency),
                                                  levels = c("8.33","12.5","25"))),
                      dv),
                    link = "logit"),
      error = function(e) { message("    CLMM s2 failed: ", e$message); NULL }
    )

    extract_clmm <- function(fit, step_lbl) {
      if (is.null(fit)) return(tibble())
      coef(summary(fit)) %>% as.data.frame() %>%
        tibble::rownames_to_column("term") %>% as_tibble() %>%
        rename(estimate = Estimate, std.error = `Std. Error`,
               z.value  = `z value`, p.value   = `Pr(>|z|)`) %>%
        mutate(DV = dv, step = step_lbl, across(where(is.numeric), ~round(.x, 4))) %>%
        filter(!str_detect(term, "^[1-6]\\|"))   # drop threshold rows for brevity
    }

    all_clmm <- bind_rows(all_clmm,
                          extract_clmm(clmm1, "step1_4freq"),
                          extract_clmm(clmm2, "step2_3x3"))
  }

  # ── Summary row ──────────────────────────────────────────────────────────────
  if (!is.null(fit2)) {
    sm <- s2_main
    summary_tbl <- bind_rows(summary_tbl, tibble(
      DV         = dv,
      s1_F       = s1_main$F,  s1_df = paste0(s1_main$num_df,", ",s1_main$den_df_GG),
      s1_p       = s1_main$p_GG, s1_pes = s1_main$pes,
      s2_freq_p  = sm$p_GG[sm$Effect=="frequency"],
      s2_freq_pes= sm$pes[sm$Effect=="frequency"],
      s2_dep_p   = sm$p_GG[sm$Effect=="modulation_depth"],
      s2_dep_pes = sm$pes[sm$Effect=="modulation_depth"],
      s2_int_p   = coalesce(sm$p_GG[str_detect(sm$Effect,":")][1], NA_real_),
      s2_int_pes = coalesce(sm$pes[str_detect(sm$Effect,":")][1], NA_real_)
    ))
  }
}

# ── Save all ──────────────────────────────────────────────────────────────────
save_csv(all_s1_main,  "06_ratings_step1_main")
save_csv(all_s1_contr, "06_ratings_step1_contrasts")
save_csv(all_s1_emm,   "06_ratings_step1_emm")
save_csv(all_s2_main,  "06_ratings_step2_main")
save_csv(all_s2_ph,    "06_ratings_step2_posthoc")
save_csv(all_clmm,     "06_ratings_clmm")
save_csv(summary_tbl,  "06_ratings_summary")

# ── Final summary ─────────────────────────────────────────────────────────────
cat("\n", strrep("=", 70), "\n")
cat("SUMMARY: Ratings RM-ANOVA (GG-corrected)\n")
cat(strrep("=", 70), "\n\n")

sig <- function(p) {
  if (is.na(p)) return("n/a")
  if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else "ns"
}

for (i in seq_len(nrow(summary_tbl))) {
  r <- summary_tbl[i, ]
  cat(sprintf(
    "%-17s  Step1 freq: F(%s)=%.2f p=%.4f ηp²=%.3f %s\n",
    r$DV, r$s1_df, r$s1_F, r$s1_p, r$s1_pes, sig(r$s1_p)))
  cat(sprintf(
    "%-17s  Step2 freq p=%.4f ηp²=%.3f %s | depth p=%.4f ηp²=%.3f %s | int p=%.4f %s\n",
    "", r$s2_freq_p, r$s2_freq_pes, sig(r$s2_freq_p),
    r$s2_dep_p, r$s2_dep_pes, sig(r$s2_dep_p),
    r$s2_int_p, sig(r$s2_int_p)))
}

cat("\n06_anova_ratings.R DONE\n")
cat("  -> 06_ratings_q2q3_consistency.csv\n")
cat("  -> 06_ratings_step1_main/contrasts/emm.csv\n")
cat("  -> 06_ratings_step2_main/posthoc.csv\n")
cat("  -> 06_ratings_clmm.csv, 06_ratings_summary.csv\n")
