# 12_ancova_covariates.R
# RM-ANCOVA: does TTC vary with individual driving tendencies?
# Covariates (participant-level, between-subjects):
#   1. exp_confidence — Q7 from Post-Experiment Questionnaire (5-point ordinal)
#   2. driving_style  — from background questionnaire (5-point ordinal)
#
# Design:
#   - Between-subjects covariate + within-subjects factor (frequency) in LMM
#   - Model comparison via LRT (ML fit) and AIC / BIC
#   - Also: simple between-subjects regression on participant-level mean TTC
#   - Interaction test: does the covariate moderate the frequency × TTC effect?
source(here::here("R", "00_setup.R"))
if (!requireNamespace("readxl",     quietly=TRUE)) install.packages("readxl")
if (!requireNamespace("effectsize", quietly=TRUE)) install.packages("effectsize")
library(readxl)
library(effectsize)

FORMS_DIR <- here::here("1. Experiment_Result", "Google Forms")

nan_to_na <- function(x) ifelse(is.nan(x), NA_real_, x)

# ── 1. Load Post-Experiment Q7 ─────────────────────────────────────────────────
cat("\n[COV] Reading Post-Experiment Questionnaire...\n")
post_raw <- read_excel(
  file.path(FORMS_DIR, "Post-Experiment Questionnaire  (Responses).xlsx")
)

# Q7 ordinal encoding (ascending = more confident)
Q7_MAP <- c(
  "Not confident at all" = 1L,
  "Unconfident"          = 2L,
  "Neutral"              = 3L,
  "Somewhat confident"   = 4L,
  "Confident"            = 5L,
  "Very confident"       = 6L
)

post <- post_raw %>%
  select(participant_id = 2, q7_raw = 9) %>%
  mutate(
    participant_id  = str_trim(str_to_upper(participant_id)),
    exp_confidence  = Q7_MAP[q7_raw],
    conf_label      = q7_raw
  )
cat(sprintf("[COV] Post-Exp Q7 — %d participants parsed\n", nrow(post)))
cat("[COV] Q7 distribution:\n")
print(table(post$q7_raw))

# ── 2. Load driving_style ──────────────────────────────────────────────────────
cat("\n[COV] Reading participant characteristics...\n")
chars <- read_csv(
  here::here("output", "tables", "03_participant_characteristics.csv"),
  show_col_types = FALSE
) %>%
  select(participant_id, driving_style)

STYLE_MAP <- c(
  "Very cautious"  = 1L,
  "Cautious"       = 2L,
  "Balanced"       = 3L,
  "Confident"      = 4L,
  "Very confident" = 5L
)

chars <- chars %>%
  mutate(driving_style_num = STYLE_MAP[driving_style])

cat("[COV] Driving style distribution:\n")
print(table(chars$driving_style))

# ── 3. Load master & aggregate Step-1 (participant × frequency) ───────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(frequency = factor(frequency, levels = FREQ_LEVELS))

step1 <- master %>%
  filter(!flag_skipped_trial) %>%
  group_by(participant_id, frequency) %>%
  summarise(TTC_s = nan_to_na(mean(TTC_s, na.rm = TRUE)), .groups = "drop")

# participant-level mean TTC (collapsing frequency — for between-subjects regression)
ptcp_mean <- step1 %>%
  group_by(participant_id) %>%
  summarise(mean_TTC = mean(TTC_s, na.rm = TRUE), .groups = "drop")

cat(sprintf("[COV] Step-1 aggregate: %d rows (%d participants × 4 frequencies)\n",
            nrow(step1), n_distinct(step1$participant_id)))

# ── 4. Join covariates ─────────────────────────────────────────────────────────
step1_cov <- step1 %>%
  left_join(post  %>% select(participant_id, exp_confidence, conf_label), by = "participant_id") %>%
  left_join(chars %>% select(participant_id, driving_style, driving_style_num), by = "participant_id")

ptcp_cov <- ptcp_mean %>%
  left_join(post  %>% select(participant_id, exp_confidence, conf_label), by = "participant_id") %>%
  left_join(chars %>% select(participant_id, driving_style, driving_style_num), by = "participant_id")

cat("\n[COV] Covariate summary (participant level):\n")
print(ptcp_cov %>% select(participant_id, exp_confidence, conf_label, driving_style, driving_style_num), n=25)

# ── 5. Descriptives: mean TTC by covariate level ───────────────────────────────
cat("\n[COV] Mean TTC by experiment confidence level:\n")
conf_desc <- ptcp_cov %>%
  group_by(exp_confidence, conf_label) %>%
  summarise(n = n(), mean_TTC = round(mean(mean_TTC), 3),
            sd_TTC = round(sd(mean_TTC), 3), .groups = "drop") %>%
  arrange(exp_confidence)
print(conf_desc)

cat("\n[COV] Mean TTC by driving style:\n")
style_desc <- ptcp_cov %>%
  group_by(driving_style_num, driving_style) %>%
  summarise(n = n(), mean_TTC = round(mean(mean_TTC), 3),
            sd_TTC = round(sd(mean_TTC), 3), .groups = "drop") %>%
  arrange(driving_style_num)
print(style_desc)

# ── 6. Between-subjects regression: participant mean TTC ~ covariates ──────────
cat("\n", strrep("=", 65), "\n")
cat("BETWEEN-SUBJECTS REGRESSION: mean_TTC ~ covariates\n")
cat(strrep("=", 65), "\n")

lm_base  <- lm(mean_TTC ~ 1,                                    data = ptcp_cov)
lm_conf  <- lm(mean_TTC ~ exp_confidence,                        data = ptcp_cov)
lm_style <- lm(mean_TTC ~ driving_style_num,                     data = ptcp_cov)
lm_both  <- lm(mean_TTC ~ exp_confidence + driving_style_num,    data = ptcp_cov)
lm_int   <- lm(mean_TTC ~ exp_confidence * driving_style_num,    data = ptcp_cov)

cat("\n[BS] exp_confidence:\n")
print(summary(lm_conf)$coefficients)
cat(sprintf("  R² = %.4f   adj.R² = %.4f   F-p = %.4f\n",
            summary(lm_conf)$r.squared, summary(lm_conf)$adj.r.squared,
            pf(summary(lm_conf)$fstatistic[1],
               summary(lm_conf)$fstatistic[2],
               summary(lm_conf)$fstatistic[3], lower.tail=FALSE)))

cat("\n[BS] driving_style_num:\n")
print(summary(lm_style)$coefficients)
cat(sprintf("  R² = %.4f   adj.R² = %.4f   F-p = %.4f\n",
            summary(lm_style)$r.squared, summary(lm_style)$adj.r.squared,
            pf(summary(lm_style)$fstatistic[1],
               summary(lm_style)$fstatistic[2],
               summary(lm_style)$fstatistic[3], lower.tail=FALSE)))

cat("\n[BS] Both covariates:\n")
print(summary(lm_both)$coefficients)
cat(sprintf("  R² = %.4f   adj.R² = %.4f\n",
            summary(lm_both)$r.squared, summary(lm_both)$adj.r.squared))

cat("\n[BS] Incremental R² (conf over null):  ΔR² = %.4f\n",  summary(lm_conf)$r.squared)
cat(sprintf("[BS] Incremental R² (style over null): ΔR² = %.4f\n", summary(lm_style)$r.squared))
delta_r2 <- summary(lm_both)$r.squared - summary(lm_conf)$r.squared
cat(sprintf("[BS] Incremental R² (style|conf):      ΔR² = %.4f\n", delta_r2))

# ── 7. LMM ANCOVA: TTC ~ frequency + covariate + (1|participant) ──────────────
cat("\n", strrep("=", 65), "\n")
cat("LMM ANCOVA: TTC ~ frequency + covariates + (1|participant)\n")
cat(strrep("=", 65), "\n")

# Use ML (not REML) for LRT comparing fixed effects
fit_ml_base <- lmerTest::lmer(
  TTC_s ~ frequency + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_ml_conf <- lmerTest::lmer(
  TTC_s ~ frequency + exp_confidence + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_ml_style <- lmerTest::lmer(
  TTC_s ~ frequency + driving_style_num + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_ml_both <- lmerTest::lmer(
  TTC_s ~ frequency + exp_confidence + driving_style_num + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)

# AIC / BIC table
aic_tbl <- data.frame(
  Model = c("Base (frequency only)",
            "+ exp_confidence",
            "+ driving_style",
            "+ both covariates"),
  AIC   = round(c(AIC(fit_ml_base), AIC(fit_ml_conf),
                  AIC(fit_ml_style), AIC(fit_ml_both)), 2),
  BIC   = round(c(BIC(fit_ml_base), BIC(fit_ml_conf),
                  BIC(fit_ml_style), BIC(fit_ml_both)), 2),
  logLik = round(c(logLik(fit_ml_base), logLik(fit_ml_conf),
                   logLik(fit_ml_style), logLik(fit_ml_both)), 3)
)
aic_tbl$ΔAIC_base <- round(aic_tbl$AIC - aic_tbl$AIC[1], 2)
cat("\n[LMM] Model fit comparison:\n")
print(aic_tbl)

# LRT: base vs each extension
lrt_conf  <- anova(fit_ml_base, fit_ml_conf,  test = "Chisq")
lrt_style <- anova(fit_ml_base, fit_ml_style, test = "Chisq")
lrt_both  <- anova(fit_ml_base, fit_ml_both,  test = "Chisq")

cat("\n[LRT] Base vs + exp_confidence:\n")
print(lrt_conf)
cat("\n[LRT] Base vs + driving_style:\n")
print(lrt_style)
cat("\n[LRT] Base vs + both:\n")
print(lrt_both)

# Fixed effect t-tests from REML models (for reporting coefficients)
fit_reml_conf  <- lmerTest::lmer(
  TTC_s ~ frequency + exp_confidence + (1|participant_id),
  data = step1_cov, REML = TRUE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_reml_style <- lmerTest::lmer(
  TTC_s ~ frequency + driving_style_num + (1|participant_id),
  data = step1_cov, REML = TRUE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_reml_both  <- lmerTest::lmer(
  TTC_s ~ frequency + exp_confidence + driving_style_num + (1|participant_id),
  data = step1_cov, REML = TRUE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)

cat("\n[REML] Fixed effects — model with exp_confidence:\n")
print(summary(fit_reml_conf)$coefficients)
cat("\n[REML] Fixed effects — model with driving_style:\n")
print(summary(fit_reml_style)$coefficients)
cat("\n[REML] Fixed effects — model with both:\n")
print(summary(fit_reml_both)$coefficients)

# ── 8. Interaction test: does covariate moderate frequency effect? ─────────────
cat("\n", strrep("=", 65), "\n")
cat("INTERACTION: frequency × covariate (moderation test)\n")
cat(strrep("=", 65), "\n")

fit_int_conf <- lmerTest::lmer(
  TTC_s ~ frequency * exp_confidence + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)
fit_int_style <- lmerTest::lmer(
  TTC_s ~ frequency * driving_style_num + (1|participant_id),
  data = step1_cov, REML = FALSE,
  control = lme4::lmerControl(optimizer = "bobyqa")
)

lrt_int_conf  <- anova(fit_ml_conf,  fit_int_conf,  test = "Chisq")
lrt_int_style <- anova(fit_ml_style, fit_int_style, test = "Chisq")

cat("\n[INT] Interaction freq × exp_confidence:\n")
print(lrt_int_conf)
cat("\n[INT] Interaction freq × driving_style:\n")
print(lrt_int_style)

# ── 9. Random effect variance: ICC and proportion explained ───────────────────
cat("\n", strrep("=", 65), "\n")
cat("RANDOM EFFECT VARIANCE — between-subject proportion explained\n")
cat(strrep("=", 65), "\n")

extract_var <- function(fit) {
  vc <- as.data.frame(VarCorr(fit))
  pid_var <- vc$vcov[vc$grp == "participant_id"]
  res_var <- vc$vcov[vc$grp == "Residual"]
  total   <- pid_var + res_var
  c(pid_var = pid_var, res_var = res_var,
    ICC = pid_var / total,
    total = total)
}

vbase  <- extract_var(fit_ml_base)
vconf  <- extract_var(fit_ml_conf)
vstyle <- extract_var(fit_ml_style)
vboth  <- extract_var(fit_ml_both)

var_tbl <- data.frame(
  Model     = c("Base", "+exp_confidence", "+driving_style", "+both"),
  Var_PID   = round(c(vbase["pid_var"],  vconf["pid_var"],
                       vstyle["pid_var"], vboth["pid_var"]), 4),
  Var_Resid = round(c(vbase["res_var"],  vconf["res_var"],
                       vstyle["res_var"], vboth["res_var"]), 4),
  ICC       = round(c(vbase["ICC"],  vconf["ICC"],
                      vstyle["ICC"], vboth["ICC"]), 4),
  PID_var_reduced_pct = c(
    0,
    round(100*(vbase["pid_var"] - vconf["pid_var"])  / vbase["pid_var"], 1),
    round(100*(vbase["pid_var"] - vstyle["pid_var"]) / vbase["pid_var"], 1),
    round(100*(vbase["pid_var"] - vboth["pid_var"])  / vbase["pid_var"], 1)
  )
)
cat("\n[VAR] Between-subject variance explained by covariates:\n")
print(var_tbl)

# ── 10. Save outputs ───────────────────────────────────────────────────────────
# AIC/BIC comparison
save_csv(aic_tbl, "12_ancova_model_fit")

# Covariate descriptives
save_csv(bind_rows(
  conf_desc  %>% mutate(covariate = "exp_confidence"),
  style_desc %>% transmute(covariate = "driving_style",
                            exp_confidence = driving_style_num,
                            conf_label = driving_style, n, mean_TTC, sd_TTC)
), "12_ancova_covariate_desc")

# Between-subjects regression summary
bs_summary <- tibble(
  covariate      = c("exp_confidence", "driving_style_num", "both"),
  beta           = c(coef(lm_conf)[2], coef(lm_style)[2], NA_real_),
  SE             = c(summary(lm_conf)$coef[2,2], summary(lm_style)$coef[2,2], NA_real_),
  t              = c(summary(lm_conf)$coef[2,3], summary(lm_style)$coef[2,3], NA_real_),
  p              = c(summary(lm_conf)$coef[2,4], summary(lm_style)$coef[2,4], NA_real_),
  R2             = c(summary(lm_conf)$r.squared,  summary(lm_style)$r.squared,
                     summary(lm_both)$r.squared),
  adj_R2         = c(summary(lm_conf)$adj.r.squared, summary(lm_style)$adj.r.squared,
                     summary(lm_both)$adj.r.squared)
) %>% mutate(across(where(is.numeric), ~round(.x, 4)))
save_csv(bs_summary, "12_ancova_bs_regression")

# LMM fixed effects (both-covariates REML model)
fe_both <- summary(fit_reml_both)$coefficients %>%
  as.data.frame() %>% rownames_to_column("term") %>% as_tibble() %>%
  mutate(across(where(is.numeric), ~round(.x, 4)))
save_csv(fe_both, "12_ancova_lmm_fixed")

# Variance components
save_csv(var_tbl, "12_ancova_variance_components")

# ── 11. Summary ───────────────────────────────────────────────────────────────
cat("\n", strrep("=", 65), "\n")
cat("SUMMARY\n")
cat(strrep("=", 65), "\n")

sig_label <- function(p) {
  if (is.na(p)) return("n/a")
  if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else "ns"
}

p_conf  <- summary(lm_conf)$coef[2, 4]
p_style <- summary(lm_style)$coef[2, 4]
lrt_conf_p  <- lrt_conf[2,  "Pr(>Chisq)"]
lrt_style_p <- lrt_style[2, "Pr(>Chisq)"]
lrt_both_p  <- lrt_both[2,  "Pr(>Chisq)"]

cat(sprintf(
  "\nBetween-subjects regression (participant mean TTC):\n"
))
cat(sprintf(
  "  exp_confidence:   β = %.3f  p = %.4f  %s  R² = %.3f\n",
  coef(lm_conf)[2], p_conf, sig_label(p_conf), summary(lm_conf)$r.squared
))
cat(sprintf(
  "  driving_style:    β = %.3f  p = %.4f  %s  R² = %.3f\n",
  coef(lm_style)[2], p_style, sig_label(p_style), summary(lm_style)$r.squared
))

cat(sprintf(
  "\nLMM model improvement (LRT, df=1):\n"
))
cat(sprintf("  +exp_confidence:  Δχ² = %.3f  p = %.4f  %s\n",
            lrt_conf[2, "Chisq"],  lrt_conf_p,  sig_label(lrt_conf_p)))
cat(sprintf("  +driving_style:   Δχ² = %.3f  p = %.4f  %s\n",
            lrt_style[2, "Chisq"], lrt_style_p, sig_label(lrt_style_p)))
cat(sprintf("  +both:            Δχ² = %.3f  p = %.4f  %s\n",
            lrt_both[2, "Chisq"],  lrt_both_p,  sig_label(lrt_both_p)))

cat(sprintf(
  "\nBetween-subject variance in TTC explained:\n"
))
cat(sprintf("  By exp_confidence:  %.1f%%\n", var_tbl$PID_var_reduced_pct[2]))
cat(sprintf("  By driving_style:   %.1f%%\n", var_tbl$PID_var_reduced_pct[3]))
cat(sprintf("  By both combined:   %.1f%%\n", var_tbl$PID_var_reduced_pct[4]))

cat(sprintf("\nBaseline ICC (proportion of variance between subjects): %.3f\n",
            vbase["ICC"]))

cat("\n12_ancova_covariates.R DONE\n")
cat("  -> 12_ancova_model_fit.csv\n")
cat("  -> 12_ancova_covariate_desc.csv\n")
cat("  -> 12_ancova_bs_regression.csv\n")
cat("  -> 12_ancova_lmm_fixed.csv\n")
cat("  -> 12_ancova_variance_components.csv\n")
