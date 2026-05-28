# 13_post_survey_descriptives.R
# Post-Experiment Questionnaire — Descriptive Statistics
# Source: Google Forms / Post-Experiment Questionnaire  (Responses).xlsx
# N = 25 participants, 9 ordinal questions (single-administration)
# Outputs: 13_post_survey_raw.csv, 13_post_survey_descriptives.csv,
#          13_post_survey_frequencies.csv, fig_post_survey_stacked.png,
#          fig_post_survey_summary.png

source(here::here("R", "00_setup.R"))
library(readxl)
library(scales)

# ── Paths ──────────────────────────────────────────────────────────────────────
SRC <- here::here(
  "1. Experiment_Result", "Google Forms",
  "Post-Experiment Questionnaire  (Responses).xlsx"   # double space intentional
)

# ── Ordinal scale definitions (lowest → highest) ───────────────────────────────
SCALES <- list(
  Q1_difficulty = list(
    label     = "Q1: Lane-change difficulty",
    direction = "higher = more difficult",
    levels    = c("Easy", "Somewhat easy", "Neutral",
                  "Somewhat difficult", "Difficult", "Very difficult")
  ),
  Q2_mental_demand = list(
    label     = "Q2: Mental demand",
    direction = "higher = more demand",
    levels    = c("Low", "Somewhat low", "Moderate",
                  "Somewhat high", "High", "Very high")
  ),
  Q3_effort = list(
    label     = "Q3: Effort exerted",
    direction = "higher = more effort",
    levels    = c("Little", "Somewhat little", "Moderate",
                  "Somewhat much", "Much", "Very much")
  ),
  Q4_motion_clarity = list(
    label     = "Q4: Motion clarity (CMS display)",
    direction = "higher = clearer",
    levels    = c("Very unclear", "Unclear", "Somewhat unclear",
                  "Neutral", "Somewhat clear", "Clear")
  ),
  Q5_flicker_interference = list(
    label     = "Q5: Flicker interference",
    direction = "higher = more interference",
    levels    = c("Slightly", "Moderately", "Strongly",
                  "Very strongly", "Extremely")
  ),
  Q6_visual_discomfort = list(
    label     = "Q6: Visual discomfort / eye fatigue",
    direction = "higher = more discomfort",
    levels    = c("Hardly any", "Slightly", "Moderate",
                  "Noticeable", "Severe")
  ),
  Q7_confidence = list(
    label     = "Q7: Decision confidence",
    direction = "higher = more confident",
    levels    = c("Not confident at all", "Unconfident", "Neutral",
                  "Somewhat confident", "Confident")
  ),
  Q8_flicker_noticeability = list(
    label     = "Q8: Flicker-difference noticeability",
    direction = "higher = more noticeable",
    levels    = c("Slightly noticeable", "Noticeable",
                  "Very noticeable", "Extremely noticeable")
  ),
  Q9_flicker_influence = list(
    label     = "Q9: Flicker influence on decisions",
    direction = "higher = more influence",
    levels    = c("Hardly at all", "Slightly", "Moderately",
                  "Strongly", "Significantly")
  )
)

Q_NAMES <- names(SCALES)

# ── Load raw data ──────────────────────────────────────────────────────────────
# Layout: col1 = timestamp, col2 = participant_id, cols 3-11 = Q1-Q9
xl_raw <- read_excel(SRC, col_names = TRUE)

df_raw <- xl_raw |>
  select(participant_id = 2, all_of(3:11)) |>
  setNames(c("participant_id", Q_NAMES)) |>
  mutate(across(-participant_id, as.character),
         participant_id = as.character(participant_id))

stopifnot("Expected N=25" = nrow(df_raw) == 25)

# ── Encode text → numeric ──────────────────────────────────────────────────────
df_num <- df_raw
for (col in Q_NAMES) {
  lvls   <- SCALES[[col]]$levels
  mapped <- match(df_raw[[col]], lvls)
  if (any(is.na(mapped) & !is.na(df_raw[[col]]))) {
    bad <- unique(df_raw[[col]][is.na(mapped) & !is.na(df_raw[[col]])])
    warning(sprintf("Unmapped values in %s: %s", col, paste(bad, collapse = ", ")))
  }
  df_num[[col]] <- as.numeric(mapped)
}

# ── Descriptive statistics ─────────────────────────────────────────────────────
desc_list <- lapply(Q_NAMES, function(col) {
  meta <- SCALES[[col]]
  s    <- df_num[[col]] |> na.omit()
  med  <- median(s)
  q1v  <- quantile(s, 0.25)
  q3v  <- quantile(s, 0.75)
  mode_val <- as.integer(names(which.max(table(s))))
  tibble(
    question      = col,
    label         = meta$label,
    n             = length(s),
    mean          = round(mean(s), 3),
    SD            = round(sd(s), 3),
    median        = round(med, 2),
    median_label  = meta$levels[round(med)],
    IQR           = round(q3v - q1v, 2),
    Q1            = round(q1v, 2),
    Q3            = round(q3v, 2),
    mode          = mode_val,
    mode_label    = meta$levels[mode_val],
    min           = min(s),
    max           = max(s),
    n_levels      = length(meta$levels),
    direction     = meta$direction
  )
})
df_desc <- bind_rows(desc_list)
save_csv(df_desc, "13_post_survey_descriptives")

# ── Frequency tables ───────────────────────────────────────────────────────────
freq_list <- lapply(Q_NAMES, function(col) {
  meta <- SCALES[[col]]
  tibble(
    question       = col,
    question_label = meta$label,
    numeric_code   = seq_along(meta$levels),
    response_label = meta$levels,
    n              = map_int(meta$levels, ~ sum(df_raw[[col]] == .x, na.rm = TRUE)),
    pct            = round(n / nrow(df_raw) * 100, 1)
  )
})
df_freq <- bind_rows(freq_list)
save_csv(df_freq, "13_post_survey_frequencies")

# ── Raw coded data ─────────────────────────────────────────────────────────────
df_out <- df_raw
for (col in Q_NAMES) {
  df_out[[paste0(col, "_code")]] <- df_num[[col]]
}
save_csv(df_out, "13_post_survey_raw")

# ── Colour palettes (RdYlBu-style, matched to Python script) ──────────────────
PAL <- list(
  `4` = c("#fc8d59", "#fee090", "#91bfdb", "#4575b4"),
  `5` = c("#d73027", "#fc8d59", "#fee090", "#91bfdb", "#4575b4"),
  `6` = c("#d73027", "#fc8d59", "#fee090", "#e0f3f8", "#91bfdb", "#4575b4")
)

# ── Figure 1: Stacked horizontal bar chart ─────────────────────────────────────
# Build cumulative x-positions per question for geom_rect
stacked <- df_freq |>
  group_by(question) |>
  arrange(numeric_code, .by_group = TRUE) |>
  mutate(
    x_end   = cumsum(pct),
    x_start = x_end - pct,
    mid_x   = (x_start + x_end) / 2,
    n_lev   = n(),
    fill_col = PAL[[as.character(n()[1])]][numeric_code]
  ) |>
  ungroup() |>
  mutate(
    q_label = factor(question_label,
                     levels = rev(sapply(Q_NAMES, \(x) SCALES[[x]]$label)))
  )

# Approximate median x-position: sum of bars to the left of median, plus
# half of the median bar (fractional position within the median category)
median_xpos <- df_desc |>
  left_join(
    df_freq |>
      group_by(question) |>
      arrange(numeric_code) |>
      mutate(cum_end  = cumsum(pct),
             cum_prev = lag(cum_end, default = 0)) |>
      ungroup(),
    by = "question"
  ) |>
  filter(numeric_code == round(median)) |>
  mutate(
    frac  = median - floor(median),
    med_x = cum_prev + frac * pct,
    q_label = factor(label, levels = levels(stacked$q_label))
  ) |>
  select(question, q_label, med_x)

fig1 <- ggplot(stacked) +
  geom_rect(aes(xmin = x_start, xmax = x_end,
                ymin = as.integer(q_label) - 0.3,
                ymax = as.integer(q_label) + 0.3,
                fill = I(fill_col)),
            colour = "white", linewidth = 0.3) +
  geom_text(
    data = filter(stacked, pct >= 6),
    aes(x = mid_x, y = as.integer(q_label), label = n),
    size = 2.5, fontface = "bold", colour = "black"
  ) +
  geom_segment(
    data = median_xpos,
    aes(x = med_x, xend = med_x,
        y = as.integer(q_label) - 0.35,
        yend = as.integer(q_label) + 0.35),
    colour = "black", linewidth = 0.9, linetype = "dashed"
  ) +
  scale_x_continuous(labels = label_percent(scale = 1),
                     expand  = c(0, 0), limits = c(0, 100)) +
  scale_y_continuous(
    breaks = seq_along(levels(stacked$q_label)),
    labels = levels(stacked$q_label)
  ) +
  labs(
    title    = "Post-Experiment Questionnaire — Response Distribution (N = 25)",
    subtitle = "Dashed line = median; counts shown when ≥10%",
    x = "Percentage (%)", y = NULL
  ) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 8),
    plot.title         = element_text(size = 10, face = "bold"),
    plot.subtitle      = element_text(size = 8)
  )

save_fig(fig1, "fig_post_survey_stacked", width_in = 13, height_in = 10)

# ── Figure 2: Dot-plot (Median ± IQR, all scales normalised to 0–1) ───────────
df_norm <- df_desc |>
  mutate(
    med_norm  = (median - 1) / (n_levels - 1),
    q1_norm   = (Q1     - 1) / (n_levels - 1),
    q3_norm   = (Q3     - 1) / (n_levels - 1),
    mean_norm = (mean   - 1) / (n_levels - 1),
    short     = paste0("Q", row_number(), ": ",
                       sub("^Q[0-9]+: ", "", label)),
    short     = factor(short, levels = rev(short))
  )

fig2 <- ggplot(df_norm) +
  geom_segment(
    aes(x = q1_norm, xend = q3_norm, y = short, yend = short),
    colour = "#91bfdb", linewidth = 5, alpha = 0.6
  ) +
  geom_point(aes(x = med_norm,  y = short),
             colour = "#d73027", size = 3.5, shape = 16) +
  geom_point(aes(x = mean_norm, y = short),
             colour = "#4575b4", size = 2.5, shape = 18, alpha = 0.85) +
  geom_vline(xintercept = 0.5, colour = "grey60", linetype = "dotted") +
  scale_x_continuous(limits = c(-0.05, 1.05),
                     breaks = seq(0, 1, 0.25),
                     labels = label_number(accuracy = 0.01)) +
  labs(
    title    = "Post-Experiment Questionnaire — Median (red) ± IQR (blue bar)",
    subtitle = "Diamond = Mean; all scales normalised to 0–1",
    x = "Normalised scale position (0 = lowest, 1 = highest)", y = NULL
  ) +
  theme(
    panel.grid.major.y = element_blank(),
    panel.grid.minor   = element_blank(),
    axis.text.y        = element_text(size = 8.5),
    plot.title         = element_text(size = 10, face = "bold"),
    plot.subtitle      = element_text(size = 8)
  )

save_fig(fig2, "fig_post_survey_summary", width_in = 9, height_in = 5.5)

# ── Console summary ────────────────────────────────────────────────────────────
message("\n=== DESCRIPTIVE SUMMARY (N=25) ===")
for (i in seq_len(nrow(df_desc))) {
  r <- df_desc[i, ]
  message(sprintf("  %s", r$label))
  message(sprintf("    M=%.2f (SD=%.2f)  Mdn=%.1f [%s]  IQR=[%.1f, %.1f]  Mode: %s",
                  r$mean, r$SD, r$median, r$median_label,
                  r$Q1, r$Q3, r$mode_label))
}
message("\nDone.")
