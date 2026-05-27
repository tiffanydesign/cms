# 01_ingest.R — read rating_lsg + eyetracking, join → master_long.csv
source(here::here("R", "00_setup.R"))
library(readxl)

RATING_DIR <- here::here("1. Experiment_Result", "Rating&LSG Timing")
EYE_DIR    <- here::here("1. Experiment_Result", "Eyetracking_Data")

# ── seqname parser (mapping confirmed by user 2026-05-24) ────────────────────
DEPTH_CODE_MAP <- c("0"=NA_character_, "1"="40", "2"="60", "3"="80")
FREQ_RAW_MAP   <- c("00"="0", "8_33"="8.33", "12_5"="12.5", "25"="25")

parse_seqname <- function(seqname) {
  s <- str_remove(seqname, "\\.bgr$")
  m <- str_match(s, "^Split_([ABC])_112_L1_F(\\d)_(.+)_$")
  scene      <- m[, 2]
  depth_code <- m[, 3]
  freq_raw   <- m[, 4]
  tibble(
    scene            = scene,
    frequency        = FREQ_RAW_MAP[freq_raw],
    modulation_depth = DEPTH_CODE_MAP[depth_code]
  )
}

# ── 1. Rating&LSG — list files ────────────────────────────────────────────────
rating_files <- list.files(RATING_DIR, pattern = "\\.dat$", full.names = TRUE)
cat(sprintf("\n[RATING] %d files found:\n", length(rating_files)))
walk(basename(rating_files), ~cat("  ", .x, "\n"))

if (length(rating_files) != 25) {
  found_pids   <- str_extract(basename(rating_files), "P\\d+")
  expected_ids <- sprintf("P%02d", 1:25)
  missing      <- setdiff(expected_ids, found_pids)
  cat(sprintf("[RATING] WARNING: expected 25, got %d. Missing: %s\n",
              length(rating_files), paste(missing, collapse = ", ")))
}

# ── 2. Rating&LSG — read each file ────────────────────────────────────────────
read_one_rating <- function(filepath) {
  pid   <- str_extract(basename(filepath), "P\\d+")
  lines <- read_lines(filepath, locale = locale(encoding = "UTF-8"))
  data_lines <- lines[str_starts(lines, "Split_")]

  if (length(data_lines) == 0) {
    warning(paste("[RATING] No data lines in", basename(filepath)))
    return(tibble())
  }

  map_dfr(seq_along(data_lines), function(i) {
    parts <- str_split(data_lines[i], "\t")[[1]]
    parts <- str_trim(parts[parts != ""])
    tibble(
      participant_id = pid,
      source_file    = basename(filepath),
      video_index    = i - 1L,          # 0-based presentation order
      seqname        = parts[1],
      seq_number     = as.integer(parts[2]),
      paddle_time_s  = if (length(parts) >= 3) as.numeric(parts[3]) else NA_real_,
      Q1             = if (length(parts) >= 4) as.numeric(parts[4]) else NA_real_,
      Q2             = if (length(parts) >= 5) as.numeric(parts[5]) else NA_real_,
      Q3             = if (length(parts) >= 6) as.numeric(parts[6]) else NA_real_,
      Q4             = if (length(parts) >= 7) as.numeric(parts[7]) else NA_real_
    )
  })
}

rating_long <- map_dfr(rating_files, read_one_rating)
cat(sprintf("\n[RATING] Total rows: %d (expected 750)\n", nrow(rating_long)))

# ── 3. Confirm paddle_time unit ───────────────────────────────────────────────
rng <- range(rating_long$paddle_time_s, na.rm = TRUE)
cat(sprintf("[RATING] paddle_time_s range: [%.3f, %.3f]\n", rng[1], rng[2]))
if (rng[2] > 25) {
  cat("[RATING] WARNING: max paddle_time > 25. Possible milliseconds — confirm unit!\n")
} else {
  cat("[RATING] Unit looks like SECONDS (values in plausible 0–19 s range). TTC = 19 - paddle_time_s.\n")
}

# ── 4. Assert Q1–Q4 in [1, 7] ────────────────────────────────────────────────
for (q in c("Q1", "Q2", "Q3", "Q4")) {
  bad <- rating_long %>% filter(!is.na(.data[[q]]), .data[[q]] < 1 | .data[[q]] > 7)
  if (nrow(bad) > 0) {
    cat(sprintf("[RATING] WARNING: %d %s values outside [1,7]:\n", nrow(bad), q))
    print(bad %>% select(participant_id, video_index, seqname, all_of(q)))
  }
}
cat("[RATING] Q1–Q4 assertion done.\n")

# ── 5. TTC, join key, seqname columns ─────────────────────────────────────────
# Q1 was displayed with inverted anchors in the experiment software
# (1=Comfortable, 7=Uncomfortable) vs the intended guide (1=Uncomfortable, 7=Comfortable).
# Recode Q1 = 8 - Q1 so that higher values = more visually comfortable throughout.
parsed <- parse_seqname(rating_long$seqname)
rating_long <- rating_long %>%
  mutate(
    Q1         = 8 - Q1,
    video_name = str_remove(seqname, "\\.bgr$"),
    TTC_s      = 19 - paddle_time_s
  ) %>%
  bind_cols(parsed) %>%
  mutate(
    frequency        = factor(frequency, levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS)
  )
# NOTE: paddle_time_s == -1 (skipped trial sentinel) rows are NOT set to NA
# here. Raw derived values (TTC_s, Q1–Q4) are preserved in master_long.csv.
# Skipped trials are identified by flag_skipped_trial in 02_flag.R and
# excluded from analysis aggregations in 05_anova_ttc.R / 06_anova_ratings.R.

# ── 6. Eyetracking — list files ───────────────────────────────────────────────
eye_files <- list.files(EYE_DIR, pattern = "\\.xlsx$", full.names = TRUE)
cat(sprintf("\n[EYE] %d files found:\n", length(eye_files)))
walk(basename(eye_files), ~cat("  ", .x, "\n"))

if (length(eye_files) != 25) {
  found_pids   <- str_extract(basename(eye_files), "P\\d+")
  expected_ids <- sprintf("P%02d", 1:25)
  missing      <- setdiff(expected_ids, found_pids)
  cat(sprintf("[EYE] WARNING: expected 25, got %d. Missing: %s\n",
              length(eye_files), paste(missing, collapse = ", ")))
}

# ── 7. Eyetracking — read each file ───────────────────────────────────────────
read_one_eye <- function(filepath) {
  pid_file <- str_extract(basename(filepath), "P\\d+")
  df <- read_excel(filepath)
  df <- df[, !is.na(names(df))]    # drop unnamed trailing columns

  df <- df %>% mutate(participant_id  = pid_file,
                      source_file_eye = basename(filepath))

  if ("participant" %in% names(df)) {
    bad <- filter(df, participant != participant_id)
    if (nrow(bad) > 0)
      stop(sprintf("[EYE] %s: %d rows where filename PID != participant column",
                   basename(filepath), nrow(bad)))
  }
  df %>% rename(eye_video_index = video_index)
}

eye_long <- map_dfr(eye_files, read_one_eye)
cat(sprintf("\n[EYE] Total rows: %d (expected ~750)\n", nrow(eye_long)))
cat(sprintf("[EYE] Columns (%d): %s\n", ncol(eye_long), paste(names(eye_long), collapse=", ")))
cat("[EYE] NOTE: pupil_diameter_* columns absent from this export.\n")

# ── 8. Join: match rates ──────────────────────────────────────────────────────
cat("\n[JOIN] Match rates:\n")
n_r <- nrow(rating_long)

n_primary <- rating_long %>%
  inner_join(select(eye_long, participant_id, video_name), by = c("participant_id","video_name")) %>%
  nrow()
cat(sprintf("  Primary  (participant_id, video_name):   %d/%d  (%.1f%%)\n",
            n_primary, n_r, 100*n_primary/n_r))

n_fallback <- rating_long %>%
  inner_join(eye_long %>% select(participant_id, video_index = eye_video_index),
             by = c("participant_id","video_index")) %>%
  nrow()
cat(sprintf("  Fallback (participant_id, video_index):  %d/%d  (%.1f%%)\n",
            n_fallback, n_r, 100*n_fallback/n_r))

# ── 9. Full join on primary key ───────────────────────────────────────────────
master_long <- rating_long %>%
  left_join(
    eye_long %>% rename(eye_participant = participant),
    by = c("participant_id", "video_name")
  )

# Verify video_index consistency
n_mismatch <- master_long %>%
  filter(!is.na(eye_video_index), video_index != eye_video_index) %>%
  nrow()
if (n_mismatch > 0)
  cat(sprintf("[JOIN] WARNING: %d rows with video_index != eye_video_index\n", n_mismatch))
master_long <- select(master_long, -eye_video_index)

# ── 10. Row count assertion ────────────────────────────────────────────────────
n_master <- nrow(master_long)
cat(sprintf("\n[MASTER] Rows: %d (expected 750)\n", n_master))
if (n_master != 750) {
  cat(sprintf("[MASTER] Gap: %d row(s). Missing detail:\n", 750 - n_master))
  print(anti_join(rating_long, eye_long, by=c("participant_id","video_name")) %>%
          select(participant_id, video_index, video_name))
  cat("NOTE: not filling or deleting.\n")
}

# ── 11. Save ───────────────────────────────────────────────────────────────────
save_csv(master_long, "master_long", dir = here::here("output"))
cat("\n01_ingest.R DONE → output/master_long.csv\n")
