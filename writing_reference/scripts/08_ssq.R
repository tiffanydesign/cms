# 08_ssq.R — SSQ pre/post analysis with Kennedy (1993) weights (spec §5.9)
# Subscales: Nausea (N), Oculo-motor (O), Total Severity (TS)
# N = items 1,6,7,8,12,13,14,15,16  x 9.54
# O = items 2,3,4,5,9,10,11          x 7.58
# D = items 5,8,10,11,12,13,14       x 13.92  (for TS)
# TS = (N_raw + O_raw + D_raw) x 3.74
# Paired t-test + Wilcoxon (both, because SSQ is often skewed)
# Explore DELTA_SSQ correlations with TTC, Q1, dwell_ratio_cms
source(here::here("R", "00_setup.R"))
if (!requireNamespace("readxl", quietly = TRUE))
  install.packages("readxl", repos = "https://cloud.r-project.org")
library(readxl)

FORMS_DIR <- here::here("1. Experiment_Result", "Google Forms")

# ── Load SSQ ──────────────────────────────────────────────────────────────────
ssq_raw <- read_excel(
  file.path(FORMS_DIR, "Simulator Sickness Questionnaire (SSQ) (Responses).xlsx")
)
cat(sprintf("[SSQ] Raw file: %d rows x %d cols\n", nrow(ssq_raw), ncol(ssq_raw)))

# Parse response columns: "0 None" / "1 Slight" / "2 Moderate" / "3 Severe" -> 0/1/2/3
ssq <- ssq_raw %>%
  rename(pid = `Participant ID`, session = `Test Session`) %>%
  mutate(pid = str_trim(pid)) %>%
  select(pid, session, starts_with("Symptom")) %>%
  mutate(across(starts_with("Symptom"),
                ~as.numeric(str_extract(as.character(.x), "^\\d+"))))

item_cols <- names(ssq)[3:ncol(ssq)]   # 16 symptom item columns (items 1-16)
cat(sprintf("[SSQ] Items found: %d | Participants: %d | Sessions: %s\n",
            length(item_cols),
            n_distinct(ssq$pid),
            paste(unique(ssq$session), collapse = " / ")))

# ── Kennedy (1993) subscale scores ────────────────────────────────────────────
# Item numbering follows column order in the spreadsheet
N_idx <- c(1, 6, 7, 8, 12, 13, 14, 15, 16)
O_idx <- c(2, 3, 4, 5,  9, 10, 11)
D_idx <- c(5, 8, 10, 11, 12, 13, 14)

ssq_scores <- ssq %>%
  rowwise() %>%
  mutate(
    N_raw   = sum(c_across(all_of(item_cols[N_idx])), na.rm = TRUE),
    O_raw   = sum(c_across(all_of(item_cols[O_idx])), na.rm = TRUE),
    D_raw   = sum(c_across(all_of(item_cols[D_idx])), na.rm = TRUE),
    N_score = N_raw * 9.54,
    O_score = O_raw * 7.58,
    D_score = D_raw * 13.92,
    TS      = (N_raw + O_raw + D_raw) * 3.74
  ) %>%
  ungroup() %>%
  select(pid, session, N_raw, O_raw, D_raw, N_score, O_score, D_score, TS)

save_csv(ssq_scores, "08_ssq_scores")
cat("\n[SSQ] Kennedy (1993) scores (N x 9.54 / O x 7.58 / TS = (N+O+D) x 3.74):\n")
print(ssq_scores %>%
  group_by(session) %>%
  summarise(across(c(N_score, O_score, TS),
                   list(mean = ~round(mean(.x, na.rm=TRUE), 2),
                        sd   = ~round(sd(.x,   na.rm=TRUE), 2)),
                   .names = "{.col}_{.fn}"),
            .groups = "drop"))

# ── Paired t-test + Wilcoxon: Pre vs Post ────────────────────────────────────
ssq_wide <- ssq_scores %>%
  select(pid, session, N_score, O_score, TS) %>%
  pivot_wider(names_from  = session,
              values_from = c(N_score, O_score, TS),
              names_glue  = "{session}_{.value}") %>%
  janitor::clean_names()

# Identify actual column names robustly after clean_names
find_col <- function(pattern) grep(pattern, names(ssq_wide), value = TRUE, ignore.case = TRUE)[1]
pre_n   <- find_col("pre.*n_score");  post_n  <- find_col("post.*n_score")
pre_o   <- find_col("pre.*o_score");  post_o  <- find_col("post.*o_score")
pre_ts  <- find_col("pre.*_ts$");     post_ts <- find_col("post.*_ts$")

ssq_wide <- ssq_wide %>%
  mutate(
    delta_N  = .data[[post_n]]  - .data[[pre_n]],
    delta_O  = .data[[post_o]]  - .data[[pre_o]],
    delta_TS = .data[[post_ts]] - .data[[pre_ts]]
  )

run_paired <- function(dv_pre, dv_post, label) {
  pre  <- ssq_wide[[dv_pre]]
  post <- ssq_wide[[dv_post]]
  tt   <- t.test(post, pre, paired = TRUE)
  wt   <- wilcox.test(post, pre, paired = TRUE, exact = FALSE)
  d    <- mean(post - pre, na.rm = TRUE) / sd(post - pre, na.rm = TRUE)
  tibble(
    subscale   = label,
    mean_pre   = round(mean(pre,  na.rm = TRUE), 2),
    mean_post  = round(mean(post, na.rm = TRUE), 2),
    mean_delta = round(mean(post - pre, na.rm = TRUE), 2),
    sd_delta   = round(sd(post - pre, na.rm = TRUE), 2),
    t          = round(tt$statistic, 3),
    df_t       = round(tt$parameter, 1),
    p_ttest    = round(tt$p.value, 4),
    W          = round(wt$statistic, 1),
    p_wilcox   = round(wt$p.value,  4),
    cohens_d   = round(d, 3)
  )
}

ssq_tests <- bind_rows(
  run_paired(pre_n,  post_n,  "Nausea (N)"),
  run_paired(pre_o,  post_o,  "Oculo-motor (O)"),
  run_paired(pre_ts, post_ts, "Total Severity (TS)")
)
save_csv(ssq_tests, "08_ssq_prepost_tests")

cat("\n[SSQ] Pre vs Post tests:\n")
print(ssq_tests %>% select(subscale, mean_pre, mean_post, mean_delta,
                            t, p_ttest, p_wilcox, cohens_d))

# ── Delta-SSQ correlations with key DVs ───────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE)

ppt_means <- master %>%
  group_by(participant_id) %>%
  summarise(
    mean_TTC   = mean(TTC_s,           na.rm = TRUE),
    mean_Q1    = mean(Q1,              na.rm = TRUE),
    mean_dwell = mean(dwell_ratio_cms, na.rm = TRUE),
    .groups    = "drop"
  )

corr_df <- ssq_wide %>%
  rename(participant_id = pid) %>%
  select(participant_id, delta_N, delta_O, delta_TS) %>%
  left_join(ppt_means, by = "participant_id") %>%
  filter(!is.na(mean_TTC))

corr_results <- map_dfr(c("delta_N","delta_O","delta_TS"), function(dv_ssq) {
  map_dfr(c("mean_TTC","mean_Q1","mean_dwell"), function(dv_beh) {
    x  <- corr_df[[dv_ssq]]; y <- corr_df[[dv_beh]]
    ok <- !is.na(x) & !is.na(y)
    r  <- tryCatch(cor.test(x[ok], y[ok], method = "spearman"),
                   error = function(e) list(estimate = NA_real_, p.value = NA_real_))
    tibble(ssq_delta = dv_ssq, behaviour = dv_beh,
           rho = round(r$estimate, 3), p_value = round(r$p.value, 4))
  })
})
save_csv(corr_results, "08_ssq_delta_correlations")

cat("\n[SSQ] Delta-SSQ correlations (Spearman rho):\n")
print(corr_results)

# ── Final summary ─────────────────────────────────────────────────────────────
sig_str <- function(p) {
  if (is.na(p)) "n/a"
  else if (p < .001) "***" else if (p < .01) "**" else if (p < .05) "*" else "ns"
}
cat("\n", strrep("=", 60), "\n")
cat("SUMMARY: SSQ pre vs post (Kennedy 1993)\n")
cat(strrep("=", 60), "\n\n")
for (i in seq_len(nrow(ssq_tests))) {
  r <- ssq_tests[i, ]
  cat(sprintf("  %-24s pre=%.1f  post=%.1f  delta=%.1f  t(%s)=%.2f  p=%.4f %s  d=%.2f\n",
              r$subscale, r$mean_pre, r$mean_post, r$mean_delta,
              r$df_t, r$t, r$p_ttest, sig_str(r$p_ttest), r$cohens_d))
}
cat("\n08_ssq.R DONE\n")
cat("  -> 08_ssq_scores.csv\n")
cat("  -> 08_ssq_prepost_tests.csv\n")
cat("  -> 08_ssq_delta_correlations.csv\n")
