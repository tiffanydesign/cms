suppressMessages({ library(tidyverse) })
m <- read_csv("output/master_long.csv", show_col_types = FALSE)
cat("Scenes:", paste(sort(unique(m$scene)), collapse = ", "), "\n")
tbl <- m %>% count(participant_id, scene) %>%
  group_by(scene) %>% summarise(n_ppts = n(), trials_min = min(n), trials_max = max(n))
print(as.data.frame(tbl))
cat("\nFlag_skipped by scene:\n")
skip <- m %>% filter(flag_skipped_trial) %>%
  count(participant_id, scene, frequency, modulation_depth)
print(as.data.frame(skip))
cat("\nMissing agg cells (participant x freq x scene) after flag filter:\n")
missing <- m %>%
  filter(!flag_skipped_trial) %>%
  group_by(participant_id, frequency, scene) %>%
  summarise(TTC_mean = mean(TTC_s, na.rm = TRUE), n = n(), .groups = "drop") %>%
  filter(is.na(TTC_mean))
print(as.data.frame(missing))
cat("\nN rows in agg_m1 (expect ~300):\n")
agg_m1 <- m %>%
  filter(!flag_skipped_trial) %>%
  group_by(participant_id, frequency, scene) %>%
  summarise(TTC_s = mean(TTC_s, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(TTC_s))
cat(nrow(agg_m1), "\n")
