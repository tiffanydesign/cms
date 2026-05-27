# 03_describe.R — descriptive statistics by 10 conditions + participant table
source(here::here("R", "00_setup.R"))
library(readxl)

FORMS_DIR <- here::here("1. Experiment_Result", "Google Forms")

# ── Load master ───────────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS),
    cms_fixated      = (first_fixation_cms_time_ms != -1) & !is.na(first_fixation_cms_time_ms)
  )

make_cond_label <- function(freq, depth) {
  ifelse(is.na(depth),
         paste0(freq, " Hz (stable)"),
         paste0(freq, " Hz / ", depth, "%"))
}
COND_ORDER <- c("0 Hz (stable)",
  "8.33 Hz / 40%", "8.33 Hz / 60%", "8.33 Hz / 80%",
  "12.5 Hz / 40%", "12.5 Hz / 60%", "12.5 Hz / 80%",
  "25 Hz / 40%",   "25 Hz / 60%",   "25 Hz / 80%")

master <- master %>%
  mutate(condition = factor(
    make_cond_label(as.character(frequency), as.character(modulation_depth)),
    levels = COND_ORDER))

# ── Generic stats helper (trial-level; n up to 75 per condition) ──────────────
desc_by_cond <- function(data, var) {
  data %>%
    group_by(condition, frequency, modulation_depth) %>%
    summarise(
      n         = sum(!is.na(.data[[var]])),
      mean      = round(mean(.data[[var]], na.rm = TRUE), 3),
      sd        = round(sd(.data[[var]],   na.rm = TRUE), 3),
      median    = round(median(.data[[var]], na.rm = TRUE), 3),
      IQR       = round(IQR(.data[[var]],   na.rm = TRUE), 3),
      missing_n = sum(is.na(.data[[var]])),
      .groups   = "drop"
    ) %>%
    arrange(condition) %>%
    mutate(variable = var, .before = condition)
}

# ── 1. TTC ────────────────────────────────────────────────────────────────────
ttc_desc <- desc_by_cond(master, "TTC_s")
save_csv(ttc_desc, "03_descriptives_ttc")
cat("[DESC] TTC done.\n")

# ── 2. Ratings Q1–Q4 ──────────────────────────────────────────────────────────
rating_desc <- map_dfr(c("Q1","Q2","Q3","Q4"), ~desc_by_cond(master, .x))
save_csv(rating_desc, "03_descriptives_ratings")
cat("[DESC] Ratings done.\n")

# ── 3. Eye metrics ────────────────────────────────────────────────────────────
eye_vars <- c("dwell_ratio_cms", "dwell_time_cms_ms",
              "transition_count", "fixation_count_cms", "fixation_count_road",
              "fixation_duration_cms_mean_ms", "fixation_duration_road_mean_ms",
              "valid_ratio")
eye_desc <- map_dfr(eye_vars, ~desc_by_cond(master, .x))
save_csv(eye_desc, "03_descriptives_eye")
cat("[DESC] Eye metrics done.\n")

# ── 4. first_fixation two-stage ───────────────────────────────────────────────
fix_stage1 <- master %>%
  group_by(condition, frequency, modulation_depth) %>%
  summarise(n_trials = n(), n_cms_fixated = sum(cms_fixated, na.rm=TRUE),
            pct_cms_fixated = round(100 * mean(cms_fixated, na.rm=TRUE), 1),
            .groups = "drop") %>%
  arrange(condition)
fix_stage2 <- master %>%
  filter(cms_fixated == TRUE) %>%
  desc_by_cond("first_fixation_cms_time_ms")

save_csv(fix_stage1, "03_descriptives_firstfix_stage1_prop")
save_csv(fix_stage2, "03_descriptives_firstfix_stage2_latency")
cat("[DESC] first_fixation two-stage done.\n")

# ── 5. Console: TTC ───────────────────────────────────────────────────────────
cat("\n=== TTC (s) by condition [up to 75 trials per condition] ===\n")
cat(sprintf("%-22s %5s %6s %6s %6s %6s\n", "Condition","n","mean","sd","median","IQR"))
cat(strrep("-",55),"\n")
for (i in seq_len(nrow(ttc_desc))) {
  r <- ttc_desc[i,]
  cat(sprintf("%-22s %5d %6.3f %6.3f %6.3f %6.3f\n",
              as.character(r$condition), r$n, r$mean, r$sd, r$median, r$IQR))
}

# ── 6. Console: Ratings ───────────────────────────────────────────────────────
cat("\n=== Mean Q1–Q4 by condition ===\n")
rating_wide <- rating_desc %>%
  select(condition, variable, mean) %>%
  pivot_wider(names_from=variable, values_from=mean)
print(rating_wide, n=20)

# ── 7. Console: Eye key metrics ───────────────────────────────────────────────
cat("\n=== dwell_ratio_cms (mean/sd) & transition_count (mean/sd) by condition ===\n")
eye_key <- eye_desc %>%
  filter(variable %in% c("dwell_ratio_cms","transition_count")) %>%
  select(condition, variable, mean, sd) %>%
  pivot_wider(names_from=variable, values_from=c(mean,sd), names_glue="{variable}_{.value}")
print(eye_key, n=20)

cat("\n=== first_fixation CMS: % fixated ===\n")
print(fix_stage1 %>% select(condition, n_trials, n_cms_fixated, pct_cms_fixated), n=20)

# ── 8. Participant characteristics ────────────────────────────────────────────
bg_raw <- read_excel(file.path(FORMS_DIR, "Background questions (Responses).xlsx"))

parse_license_years <- function(x) {
  x <- str_to_lower(str_trim(as.character(x)))
  case_when(
    x %in% c("na","n/a","none","") ~ NA_real_,
    str_detect(x, "month")         ~ suppressWarnings(as.numeric(str_extract(x,"[0-9.]+"))) / 12,
    TRUE                            ~ suppressWarnings(as.numeric(str_extract(x,"[0-9.]+")))
  )
}

clean_km <- function(x) {
  s <- as.character(x)
  case_when(
    str_detect(s, "20 000")                      ~ "10000-20000",
    str_detect(s, "10 000") & !str_detect(s,"20 000") ~ "5000-10000",
    str_detect(s, "5 000")                        ~ "0-5000",
    TRUE                                          ~ NA_character_
  )
}

clean_driving_style <- function(x) {
  s <- as.character(x)
  case_when(
    str_detect(s, "Very cautious")  ~ "Very cautious",
    str_detect(s, "Very confident") ~ "Very confident",
    str_detect(s, "Cautious")       ~ "Cautious",
    str_detect(s, "Confident")      ~ "Confident",
    str_detect(s, "Balanced")       ~ "Balanced",
    TRUE                            ~ str_trim(str_extract(s, "^[^(]+"))
  )
}

participants <- bg_raw %>%
  select(
    timestamp         = 1,
    participant_id    = 2,
    age               = 3,
    gender            = 4,
    license_type      = 5,
    occupation        = 6,
    license_yrs_raw   = 7,
    annual_km_raw     = 8,
    commercial_transport_exp = 9,
    driving_style_raw = 10,
    flicker_discomfort = 11,
    cms_experience    = 12
  ) %>%
  mutate(
    participant_id    = str_trim(participant_id),
    experiment_date   = as.Date(timestamp),
    age               = as.numeric(age),
    gender            = str_to_title(str_trim(gender)),
    license_type      = str_to_upper(str_trim(license_type)),
    license_years     = parse_license_years(license_yrs_raw),
    occupation        = str_to_title(str_trim(occupation)),
    annual_km         = clean_km(annual_km_raw),
    commercial_transport_exp = case_when(
      str_to_lower(str_trim(commercial_transport_exp)) == "no" ~ "No",
      TRUE ~ str_trim(commercial_transport_exp)
    ),
    driving_style     = clean_driving_style(driving_style_raw),
    flicker_discomfort = case_when(
      str_detect(flicker_discomfort, "Never")       ~ "Never",
      str_detect(flicker_discomfort, "Occasionally") ~ "Occasionally",
      str_detect(flicker_discomfort, "Frequently")  ~ "Frequently",
      TRUE ~ flicker_discomfort
    ),
    cms_experience    = case_when(
      str_detect(cms_experience, "never") ~ "No",
      str_detect(cms_experience, "Yes")   ~ "Yes",
      TRUE ~ cms_experience
    ),
    is_P09_nolicense  = (participant_id == "P09"),
    is_P15_colorblind = (participant_id == "P15"),
    note = case_when(
      participant_id == "P09" ~ "No driving license",
      participant_id == "P15" ~ "Color blind (experimenter record)",
      TRUE ~ ""
    )
  ) %>%
  select(participant_id, experiment_date, age, gender, license_type, license_years,
         occupation, annual_km, commercial_transport_exp, driving_style,
         flicker_discomfort, cms_experience,
         is_P09_nolicense, is_P15_colorblind, note) %>%
  arrange(participant_id)

save_csv(participants, "03_participant_characteristics")

cat("\n=== Participant characteristics (N=25) ===\n")
cat(sprintf("Age:           mean=%.1f  sd=%.1f  range=[%.0f, %.0f]\n",
    mean(participants$age, na.rm=TRUE), sd(participants$age, na.rm=TRUE),
    min(participants$age, na.rm=TRUE),  max(participants$age, na.rm=TRUE)))
cat(sprintf("Gender:        %s\n",
    paste(names(table(participants$gender)), table(participants$gender),
          sep="=", collapse="  ")))
valid_yrs <- participants %>% filter(!is_P09_nolicense)
cat(sprintf("License years: mean=%.1f  sd=%.1f  (P09 excluded)\n",
    mean(valid_yrs$license_years, na.rm=TRUE), sd(valid_yrs$license_years, na.rm=TRUE)))
n_flicker <- sum(participants$flicker_discomfort != "Never", na.rm=TRUE)
cat(sprintf("Flicker discomfort history: %d / 25 (not 'Never')\n", n_flicker))
n_cms <- sum(participants$cms_experience == "Yes", na.rm=TRUE)
cat(sprintf("CMS experience: %d / 25 (Yes)\n", n_cms))
drive_style_tbl <- table(participants$driving_style)
cat(sprintf("Driving style: %s\n",
    paste(names(drive_style_tbl), drive_style_tbl, sep="=", collapse="  ")))
cat(sprintf("Special cases: P09 (no license), P15 (colorblind)\n\n"))
print(participants %>% select(participant_id, age, gender, license_years,
                               driving_style, flicker_discomfort, note), n=25)

cat("\n03_describe.R DONE → 6 CSVs in output/tables/\n")
