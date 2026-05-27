suppressPackageStartupMessages({ library(tidyverse) })
# Read with ALL character columns to avoid type-guessing masking values
m <- read_csv("output/master_long.csv",
              col_types = cols(.default = col_character()),
              show_col_types = FALSE)
cat("Columns:", paste(names(m), collapse=", "), "\n")
cat("\n--- P03/P11 video_index=15: seqname + join evidence ---\n")
print(m |> filter(participant_id %in% c("P03","P11"), video_index == "15") |>
  select(participant_id, video_index, seqname, video_name, scene, frequency,
         modulation_depth, paddle_time_s, valid_ratio, dwell_ratio_cms))
