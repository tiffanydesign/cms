suppressPackageStartupMessages({ library(tidyverse) })
master <- read_csv("output/master_long.csv", show_col_types = FALSE)

cat("=== paddle_time_s < 0 ===\n")
print(master |> filter(paddle_time_s < 0) |>
  select(participant_id, video_index, seqname, paddle_time_s, TTC_s, Q1, Q2, Q3, Q4))

cat("\n=== extreme TTC rows ===\n")
ttc_b <- master |> filter(!is.na(TTC_s)) |>
  group_by(participant_id) |>
  summarise(m = mean(TTC_s), s = sd(TTC_s), .groups = "drop") |>
  mutate(lo = m - 3*s, hi = m + 3*s)

extreme <- master |>
  left_join(ttc_b, by = "participant_id") |>
  filter(!is.na(TTC_s), TTC_s < 0 | TTC_s > 19 | TTC_s < lo | TTC_s > hi) |>
  select(participant_id, video_index, seqname, paddle_time_s, TTC_s, lo, hi)
print(extreme)

cat("\n=== Q value checks ===\n")
cat(sprintf("Rows where any Q == 0:  %d\n",
    nrow(master |> filter(Q1==0|Q2==0|Q3==0|Q4==0))))
cat(sprintf("Rows where any Q is NA: %d\n",
    nrow(master |> filter(is.na(Q1)|is.na(Q2)|is.na(Q3)|is.na(Q4)))))

cat("\n=== low eye quality detail (valid_ratio < 70%) ===\n")
print(master |>
  filter(!is.na(valid_ratio), valid_ratio < 70) |>
  select(participant_id, video_index, scene, frequency, modulation_depth, valid_ratio) |>
  arrange(valid_ratio))
