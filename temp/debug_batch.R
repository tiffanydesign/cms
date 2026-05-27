suppressPackageStartupMessages({ library(tidyverse) })

RATING_DIR <- "C:/Users/50560/Desktop/cms_analysis/1. Experiment_Result/Rating&LSG Timing"

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

read_one_rating <- function(filepath) {
  pid   <- str_extract(basename(filepath), "P\\d+")
  lines <- read_lines(filepath, locale = locale(encoding = "UTF-8"))
  data_lines <- lines[str_starts(lines, "Split_")]
  map_dfr(seq_along(data_lines), function(i) {
    parts <- str_split(data_lines[i], "\t")[[1]]
    parts <- str_trim(parts[parts != ""])
    tibble(
      participant_id = pid, video_index = i - 1L,
      seqname        = parts[1],
      paddle_time_s  = if (length(parts) >= 3) as.numeric(parts[3]) else NA_real_,
      Q1 = if (length(parts) >= 4) as.numeric(parts[4]) else NA_real_
    )
  })
}

rating_files <- list.files(RATING_DIR, pattern = "\\.dat$", full.names = TRUE)
rating_long  <- map_dfr(rating_files, read_one_rating)
cat(sprintf("rating_long rows: %d\n", nrow(rating_long)))

# Check P03 and P11 at video_index=15 BEFORE any transform
cat("\n--- P03/P11 at video_index=15 BEFORE parse ---\n")
print(rating_long |> filter(participant_id %in% c("P03","P11"), video_index == 15))

# Now apply parse_seqname in batch
parsed <- parse_seqname(rating_long$seqname)
cat("\n--- parsed rows for P03/P11 at video_index=15 ---\n")
idx <- which(rating_long$participant_id %in% c("P03","P11") & rating_long$video_index == 15)
cat("Row indices:", idx, "\n")
print(parsed[idx, ])

# Bind cols
rating_long2 <- rating_long |>
  mutate(video_name = str_remove(seqname, "\\.bgr$")) |>
  bind_cols(parsed)

cat("\n--- After bind_cols ---\n")
print(rating_long2 |> filter(participant_id %in% c("P03","P11"), video_index == 15) |>
  select(participant_id, video_index, seqname, video_name, scene, frequency, modulation_depth))
