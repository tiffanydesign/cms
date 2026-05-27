# 02_flag.R — add quality/exception flag columns; output 02_flag_summary.csv
# Principle: NEVER delete rows. Only annotate.
source(here::here("R", "00_setup.R"))

EYE_QUALITY_THRESHOLD <- 70   # valid_ratio % below which flag_low_eye_quality = TRUE

# ── Load master ───────────────────────────────────────────────────────────────
master_long <- read_csv(
  here::here("output", "master_long.csv"),
  show_col_types = FALSE           # let readr auto-detect; avoids clobbering char cols
)
cat(sprintf("[FLAG] master_long loaded: %d rows, %d cols\n", nrow(master_long), ncol(master_long)))

# ── flag_extreme_ttc: within-participant mean±3SD ─────────────────────────────
ttc_bounds <- master_long %>%
  filter(!is.na(TTC_s)) %>%
  group_by(participant_id) %>%
  summarise(
    ttc_mean = mean(TTC_s),
    ttc_sd   = sd(TTC_s),
    .groups  = "drop"
  ) %>%
  mutate(lo = ttc_mean - 3 * ttc_sd,
         hi = ttc_mean + 3 * ttc_sd)

# ── Add all flag columns ───────────────────────────────────────────────────────
master_long <- master_long %>%
  left_join(ttc_bounds %>% select(participant_id, lo, hi), by = "participant_id") %>%
  mutate(
    flag_no_response     = is.na(paddle_time_s) | is.na(TTC_s),
    flag_missing_rating  = is.na(Q1) | is.na(Q2) | is.na(Q3) | is.na(Q4),
    flag_low_eye_quality = !is.na(valid_ratio) & valid_ratio < EYE_QUALITY_THRESHOLD,
    flag_extreme_ttc     = !is.na(TTC_s) & (TTC_s < 0 | TTC_s > 19 |
                                              TTC_s < lo | TTC_s > hi),
    is_P09_nolicense     = participant_id == "P09",
    is_P15_colorblind    = participant_id == "P15"
  ) %>%
  select(-lo, -hi)

# ── Save updated master_long ───────────────────────────────────────────────────
save_csv(master_long, "master_long", dir = here::here("output"))

# ── flag_missing_rating: check if concentrated on video_index 15 ──────────────
cat("\n[FLAG] flag_missing_rating breakdown by video_index:\n")
missing_by_vidx <- master_long %>%
  filter(flag_missing_rating) %>%
  count(video_index, name = "n_missing") %>%
  arrange(desc(n_missing))
print(missing_by_vidx)

n_at_15 <- master_long %>% filter(flag_missing_rating, video_index == 15) %>% nrow()
n_total_missing <- sum(master_long$flag_missing_rating)
cat(sprintf("  → %d / %d missing-rating rows are at video_index=15 (%.0f%%)\n",
            n_at_15, n_total_missing,
            if (n_total_missing > 0) 100 * n_at_15 / n_total_missing else 0))

# ── Build flag summary table ───────────────────────────────────────────────────
flag_cols <- c("flag_no_response", "flag_missing_rating",
               "flag_low_eye_quality", "flag_extreme_ttc",
               "is_P09_nolicense", "is_P15_colorblind")

flag_summary <- map_dfr(flag_cols, function(fc) {
  flagged <- master_long %>% filter(.data[[fc]] == TRUE)
  tibble(
    flag              = fc,
    n_flagged         = nrow(flagged),
    pct_of_750        = round(100 * nrow(flagged) / nrow(master_long), 1),
    participants      = if (nrow(flagged) > 0)
                          paste(sort(unique(flagged$participant_id)), collapse=", ")
                        else "",
    example_vidx      = if (nrow(flagged) > 0)
                          paste(sort(unique(flagged$video_index))[1:min(5, nrow(flagged %>% distinct(video_index)))],
                                collapse=", ")
                        else ""
  )
})

save_csv(flag_summary, "02_flag_summary")

cat("\n[FLAG] Summary:\n")
print(flag_summary %>% select(flag, n_flagged, pct_of_750, participants))

cat("\n02_flag.R DONE → output/tables/02_flag_summary.csv\n")
