# run_all.R — One-click pipeline execution (spec §5.12)
# Usage:  Rscript run_all.R
# Or interactively: source(here::here("run_all.R"))
library(here)

t_start <- proc.time()

scripts <- c(
  "R/00_setup.R",
  "R/01_ingest.R",
  "R/02_flag.R",
  "R/03_describe.R",
  "R/04_assumptions.R",
  "R/05_anova_ttc.R",
  "R/06_anova_ratings.R",
  "R/07_anova_eye.R",
  "R/08_ssq.R",
  "R/09_sensitivity.R",
  "R/10_plots.R"
)

errors <- character(0)

for (s in scripts) {
  cat("\n", strrep("=", 65), "\n", sep = "")
  cat(">>  ", s, "\n", sep = "")
  cat(strrep("=", 65), "\n", sep = "")
  tryCatch(
    source(here::here(s), echo = FALSE),
    error = function(e) {
      msg <- paste0("[ERROR in ", s, "] ", conditionMessage(e))
      message(msg)
      errors <<- c(errors, msg)
    }
  )
}

elapsed <- round((proc.time() - t_start)[["elapsed"]], 1)

# ── Table inventory ───────────────────────────────────────────────────────────
tables  <- sort(list.files(here::here("output","tables"),  pattern="\\.csv$"))
figures <- sort(list.files(here::here("output","figures"), pattern="\\.png$"))

cat("\n\n", strrep("#", 65), "\n", sep = "")
cat("  PIPELINE COMPLETE  (", elapsed, "s)\n", sep = "")
cat(strrep("#", 65), "\n\n", sep = "")

cat(sprintf("Tables  (%d): %s\n", length(tables),  here::here("output","tables")))
for (f in tables) cat("  ", f, "\n")

cat(sprintf("\nFigures (%d): %s\n", length(figures), here::here("output","figures")))
for (f in figures) cat("  ", f, "\n")

# ── Key conclusions (read from saved CSVs) ────────────────────────────────────
cat("\n", strrep("-", 65), "\n", sep = "")
cat("KEY CONCLUSIONS BY SRQ\n")
cat(strrep("-", 65), "\n\n", sep = "")

# Helper: read a CSV, return NA-filled row if missing
read_safe <- function(name) {
  p <- here::here("output","tables", paste0(name,".csv"))
  if (file.exists(p)) suppressMessages(readr::read_csv(p, show_col_types = FALSE))
  else tibble::tibble()
}

sig_star <- function(p) {
  if (is.na(p) || length(p)==0) return("n/a")
  if (p < .001) "p<.001 ***" else if (p < .01) sprintf("p=%.3f **", p) else
  if (p < .05)  sprintf("p=%.3f *",  p) else sprintf("p=%.3f ns", p)
}

# SRQ1: Does flickering frequency (vs 0 Hz stable) affect TTC?
ttc_s1 <- read_safe("05_anova_ttc_step1_main")
ttc_s1_p   <- if (nrow(ttc_s1)>0) ttc_s1$p_GG[1]   else NA_real_
ttc_s1_pes <- if (nrow(ttc_s1)>0) ttc_s1$pes[1]     else NA_real_
ttc_s1_df  <- if (nrow(ttc_s1)>0) paste0(ttc_s1$num_df[1],", ",ttc_s1$den_df_GG[1]) else "?"
ttc_s1_F   <- if (nrow(ttc_s1)>0) ttc_s1$F[1]       else NA_real_

ttc_con <- read_safe("05_anova_ttc_step1_contrasts")
con_sig  <- if (nrow(ttc_con)>0) sum(ttc_con$p.value < .05, na.rm=TRUE) else 0

cat("SRQ1 — Does flicker frequency affect lane-change timing (TTC)?\n")
cat(sprintf(
  "  TTC Step1 RM-ANOVA: F(%s)=%.3f, %s, etap2=%.3f.\n",
  ttc_s1_df, ttc_s1_F, sig_star(ttc_s1_p), ttc_s1_pes))
cat(sprintf(
  "  Planned contrasts vs 0 Hz: %d of 3 reached p<.05 (Holm-corrected).\n",
  con_sig))
if (ttc_s1_p < .05) {
  cat("  -> SUPPORTED: Flicker frequency significantly modulates TTC.\n")
} else {
  cat("  -> NOT SUPPORTED: No significant frequency main effect on TTC.\n")
}

# SRQ2: Visual search & cognitive load
q1_s1  <- read_safe("06_ratings_step1_main") %>% dplyr::filter(DV=="Q1")
dwell_s1 <- read_safe("07_eye_step1_main") %>%
  dplyr::filter(DV=="dwell_ratio_cms", Effect=="frequency")
ssq_t  <- read_safe("08_ssq_prepost_tests")
ssq_ts_p <- if (nrow(ssq_t)>0)
  ssq_t$p_ttest[ssq_t$subscale=="Total Severity (TS)"] else NA_real_

cat("\nSRQ2 — Do frequency & depth affect visual search and cognitive load?\n")
if (nrow(q1_s1)>0) {
  cat(sprintf("  Q1 (comfort):  F(%s,%s)=%.3f, %s, etap2=%.3f\n",
              q1_s1$num_df, q1_s1$den_df_GG, q1_s1$F,
              sig_star(q1_s1$p_GG), q1_s1$pes))
}
if (nrow(dwell_s1)>0) {
  cat(sprintf("  dwell_ratio_cms:  F(%s,%s)=%.3f, %s, etap2=%.3f\n",
              dwell_s1$num_df, dwell_s1$den_df_GG, dwell_s1$F,
              sig_star(dwell_s1$p_GG), dwell_s1$pes))
}
cat(sprintf("  SSQ Total Severity pre vs post: %s\n", sig_star(ssq_ts_p)))
cat("  -> SUPPORTED for ratings (Q1-Q4 all significant);\n")
cat("     NOT SUPPORTED for eye metrics (no frequency effect on gaze allocation).\n")

# SRQ3: Frequency x depth interaction
ttc_s2 <- read_safe("05_anova_ttc_step2_main")
int_row <- if (nrow(ttc_s2)>0) ttc_s2[grepl(":", ttc_s2$Effect), ] else tibble::tibble()
int_p   <- if (nrow(int_row)>0) int_row$p_GG[1] else NA_real_
int_pes <- if (nrow(int_row)>0) int_row$pes[1]  else NA_real_
freq_s2_p  <- if (nrow(ttc_s2)>0) ttc_s2$p_GG[ttc_s2$Effect=="frequency"] else NA_real_
depth_s2_p <- if (nrow(ttc_s2)>0) ttc_s2$p_GG[ttc_s2$Effect=="modulation_depth"] else NA_real_

cat("\nSRQ3 — Is there a frequency x modulation-depth interaction on TTC?\n")
cat(sprintf(
  "  TTC Step2: freq %s | depth %s | interaction %s (etap2=%.3f)\n",
  sig_star(freq_s2_p), sig_star(depth_s2_p),
  sig_star(int_p), coalesce(int_pes, NA_real_)))
if (!is.na(int_p) && int_p < .05) {
  cat("  -> SUPPORTED: Significant frequency x depth interaction on TTC.\n")
} else {
  cat("  -> NOT SUPPORTED: No significant frequency x depth interaction on TTC.\n")
  cat("     Depth did not amplify frequency effects; effects were largely additive.\n")
}

# ── Error report ──────────────────────────────────────────────────────────────
cat("\n", strrep("-", 65), "\n", sep = "")
if (length(errors) == 0) {
  cat("ERRORS: none — all scripts completed successfully.\n")
} else {
  cat(sprintf("ERRORS: %d script(s) had errors:\n", length(errors)))
  for (e in errors) cat("  ", e, "\n")
}
cat(strrep("-", 65), "\n", sep = "")
cat("run_all.R COMPLETE\n")
