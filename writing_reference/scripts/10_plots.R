# 10_plots.R — All 14 figures (spec §6), 300 dpi PNG, output/figures/
# Each figure is labelled with the SRQ it addresses.
source(here::here("R", "00_setup.R"))
for (pkg in c("readxl", "ggrepel")) {
  if (!requireNamespace(pkg, quietly = TRUE))
    install.packages(pkg, repos = "https://cloud.r-project.org")
}
library(readxl)
library(ggrepel)

# ── Shared constants ──────────────────────────────────────────────────────────
COND_ORDER <- c("0 Hz (stable)",
  "8.33 Hz / 40%", "8.33 Hz / 60%", "8.33 Hz / 80%",
  "12.5 Hz / 40%", "12.5 Hz / 60%", "12.5 Hz / 80%",
  "25 Hz / 40%",   "25 Hz / 60%",   "25 Hz / 80%")

FREQ_PAL   <- c("0"="#888888","8.33"="#2196F3","12.5"="#FF9800","25"="#E53935")
DEPTH_PAL  <- c("40"="#4CAF50","60"="#FF9800","80"="#E53935")
DEPTH_LTY  <- c("40"="solid","60"="dashed","80"="dotted")

make_cond_label <- function(freq, depth) {
  ifelse(is.na(depth),
         paste0(freq, " Hz (stable)"),
         paste0(freq, " Hz / ", depth, "%"))
}

# ── Load master_long ─────────────────────────────────────────────────────────
master <- read_csv(here::here("output", "master_long.csv"), show_col_types = FALSE) %>%
  mutate(
    frequency        = factor(frequency,        levels = FREQ_LEVELS),
    modulation_depth = factor(modulation_depth, levels = DEPTH_LEVELS),
    scene            = factor(scene),
    condition        = factor(
      make_cond_label(as.character(frequency), as.character(modulation_depth)),
      levels = COND_ORDER)
  )

cat(sprintf("[PLOTS] master loaded: %d rows\n", nrow(master)))

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 1 — QQ plot matrix: TTC residuals per frequency (SRQ1 diagnostic)
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n[FIG 1] QQ TTC...\n")

ttc_step1 <- master %>%
  group_by(participant_id, frequency) %>%
  summarise(TTC_s = mean(TTC_s, na.rm = TRUE), .groups = "drop") %>%
  filter(!is.na(TTC_s))

# Compute within-cell residuals (cell mean subtracted)
ttc_resid <- ttc_step1 %>%
  group_by(frequency) %>%
  mutate(resid = TTC_s - mean(TTC_s, na.rm = TRUE)) %>%
  ungroup()

p1 <- ggplot(ttc_resid, aes(sample = resid)) +
  stat_qq(color = "#2196F3", size = 0.8) +
  stat_qq_line(color = "#E53935", linewidth = 0.6) +
  facet_wrap(~frequency, nrow = 2, labeller = labeller(frequency = function(x) paste0(x, " Hz"))) +
  labs(
    title   = "QQ Plots: TTC Residuals by Frequency Condition",
    subtitle = "Diagnostic — SRQ1: Are residuals normally distributed within frequency levels?",
    x = "Theoretical Quantiles", y = "Sample Quantiles"
  )
save_fig(p1, "fig_qq_ttc", width_in = 8, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 2 — Residual diagnostic: RM-ANOVA residuals (SRQ1 diagnostic)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 2] Residuals TTC...\n")

fit_diag <- tryCatch(
  afex::aov_ez(id = "participant_id", dv = "TTC_s", data = ttc_step1,
               within = "frequency", type = 3,
               anova_table = list(correction = "GG", es = "pes")),
  error = function(e) NULL
)

if (!is.null(fit_diag)) {
  resid_df <- tibble(
    fitted   = fitted(fit_diag$lm),
    residual = residuals(fit_diag$lm)
  )
  p2a <- ggplot(resid_df, aes(fitted, residual)) +
    geom_hline(yintercept = 0, linetype = "dashed", color = "#888") +
    geom_point(alpha = 0.4, size = 1.5, color = "#2196F3") +
    geom_smooth(method = "loess", se = FALSE, color = "#E53935", linewidth = 0.7) +
    labs(title = "Residuals vs Fitted (TTC Step-1 RM-ANOVA)",
         x = "Fitted values", y = "Residuals")
  p2b <- ggplot(resid_df, aes(residual)) +
    geom_histogram(bins = 20, fill = "#2196F3", color = "white", alpha = 0.8) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "#E53935") +
    labs(title = "Residual Distribution",
         x = "Residuals", y = "Count")
  p2 <- p2a + p2b +
    patchwork::plot_annotation(
      title    = "TTC RM-ANOVA Residual Diagnostics",
      subtitle = "Diagnostic — SRQ1: Homoscedasticity and normality of residuals"
    )
  save_fig(p2, "fig_resid_ttc", width_in = 10, height_in = 4.5)
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 3 — Outlier-annotated boxplot: TTC per condition (SRQ1 diagnostic)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 3] Outlier box TTC...\n")

ttc_outlier <- master %>%
  filter(!is.na(TTC_s)) %>%
  group_by(frequency) %>%
  mutate(
    m  = mean(TTC_s, na.rm = TRUE),
    s  = sd(TTC_s,   na.rm = TRUE),
    is_extreme = abs(TTC_s - m) > 3 * s
  ) %>%
  ungroup()

p3 <- ggplot(ttc_outlier, aes(x = frequency, y = TTC_s, fill = frequency)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.6, width = 0.5) +
  geom_jitter(data = filter(ttc_outlier, !is_extreme),
              width = 0.15, alpha = 0.25, size = 0.8, color = "#555") +
  geom_point(data = filter(ttc_outlier, is_extreme),
             color = "#E53935", size = 2.5, shape = 18) +
  ggrepel::geom_label_repel(
    data    = filter(ttc_outlier, is_extreme),
    aes(label = participant_id),
    size = 2.5, box.padding = 0.3, max.overlaps = 20,
    color = "#E53935"
  ) +
  scale_fill_manual(values = FREQ_PAL) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(title   = "TTC by Frequency — Extreme Outliers Labelled",
       subtitle = "Diagnostic — SRQ1: Identified outliers (|z|>3) highlighted in red",
       x = "Frequency", y = "TTC (s)", fill = "Frequency") +
  theme(legend.position = "none")
save_fig(p3, "fig_outlier_ttc", width_in = 8, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 4 — TTC boxplot + scatter: all 10 conditions (SRQ1 & SRQ3)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 4] TTC box 10 conditions...\n")

ttc_plot <- master %>% filter(!is.na(TTC_s))

p4 <- ggplot(ttc_plot, aes(x = condition, y = TTC_s, fill = frequency)) +
  geom_boxplot(outlier.shape = NA, alpha = 0.55, width = 0.6) +
  geom_jitter(aes(color = frequency), width = 0.18, alpha = 0.3, size = 0.9) +
  scale_fill_manual(values  = FREQ_PAL) +
  scale_color_manual(values = FREQ_PAL) +
  scale_x_discrete(labels = function(x) str_replace(x, " \\(stable\\)", "\n(stable)")) +
  labs(
    title    = "TTC Distribution Across 10 Conditions",
    subtitle = "SRQ1 & SRQ3: Effect of flicker frequency and modulation depth on lane-change timing",
    caption  = "TTC = time to collision; smaller TTC = more aggressive/risky response",
    x = NULL, y = "TTC (s)", fill = "Frequency", color = "Frequency"
  ) +
  theme(axis.text.x = element_text(angle = 40, hjust = 1, size = 8),
        legend.position = "top")
save_fig(p4, "fig_ttc_box", width_in = 10, height_in = 5.5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 5 — TTC interaction line: freq × depth + 0Hz baseline (SRQ3 core)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 5] TTC interaction...\n")

# Cell means from descriptives CSV (already computed)
ttc_desc <- read_csv(here::here("output","tables","03_descriptives_ttc.csv"),
                     show_col_types = FALSE) %>%
  mutate(frequency        = factor(as.character(frequency), levels = FREQ_LEVELS),
         modulation_depth = factor(as.character(modulation_depth), levels = DEPTH_LEVELS),
         se               = sd / sqrt(n),
         ci95_lo          = mean - 1.96 * se,
         ci95_hi          = mean + 1.96 * se)

baseline_ttc <- ttc_desc %>% filter(is.na(modulation_depth)) %>%
  summarise(mean = mean(mean), ci95_lo = mean(ci95_lo), ci95_hi = mean(ci95_hi))

flicker_ttc  <- ttc_desc %>% filter(!is.na(modulation_depth))

p5 <- ggplot(flicker_ttc,
             aes(x = frequency, y = mean, color = modulation_depth,
                 group = modulation_depth, linetype = modulation_depth)) +
  geom_hline(yintercept = baseline_ttc$mean, linetype = "dotted",
             color = "#888", linewidth = 0.8) +
  annotate("text", x = 0.6, y = baseline_ttc$mean + 0.12, label = "0 Hz baseline",
           size = 3, color = "#888") +
  geom_errorbar(aes(ymin = ci95_lo, ymax = ci95_hi),
                width = 0.12, linewidth = 0.6, position = position_dodge(0.1)) +
  geom_line(linewidth = 1, position = position_dodge(0.1)) +
  geom_point(size = 3, position = position_dodge(0.1)) +
  scale_color_manual(values = DEPTH_PAL,  labels = c("40%","60%","80%")) +
  scale_linetype_manual(values = DEPTH_LTY, labels = c("40%","60%","80%")) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "TTC: Frequency × Modulation Depth Interaction",
    subtitle = "SRQ3: Two-way RM-ANOVA (flickering conditions only), mean ± 95% CI",
    caption  = "Dashed line = 0 Hz stable baseline; GG-corrected F showed no significant interaction (p=.18)",
    x = "Flicker Frequency", y = "TTC (s)",
    color = "Mod. Depth", linetype = "Mod. Depth"
  ) +
  theme(legend.position = "right")
save_fig(p5, "fig_ttc_interaction", width_in = 8, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 6 — TTC spaghetti: individual trajectories across frequency (SRQ1)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 6] TTC spaghetti...\n")

ttc_ppt <- master %>%
  filter(!is.na(TTC_s)) %>%
  group_by(participant_id, frequency) %>%
  summarise(TTC_s = mean(TTC_s, na.rm = TRUE), .groups = "drop")

ttc_ppt_mean <- ttc_ppt %>%
  group_by(frequency) %>%
  summarise(mean_TTC = mean(TTC_s, na.rm = TRUE), .groups = "drop")

p6 <- ggplot(ttc_ppt, aes(x = frequency, y = TTC_s, group = participant_id)) +
  geom_line(alpha = 0.35, color = "#2196F3", linewidth = 0.5) +
  geom_point(alpha = 0.4,  color = "#2196F3", size = 1.2) +
  geom_line(data = ttc_ppt_mean, aes(x = frequency, y = mean_TTC, group = 1),
            inherit.aes = FALSE, color = "#E53935", linewidth = 1.4) +
  geom_point(data = ttc_ppt_mean, aes(x = frequency, y = mean_TTC),
             inherit.aes = FALSE, color = "#E53935", size = 3) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "Individual TTC Trajectories Across Frequency Conditions",
    subtitle = "SRQ1: Between-person variability in response to flicker frequency",
    caption  = "Blue lines = individual participants; Red line = group mean",
    x = "Flicker Frequency", y = "TTC (s)"
  )
save_fig(p6, "fig_ttc_spaghetti", width_in = 7, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 7 — Ratings bar: Q1–Q4 means ± CI by frequency (SRQ2)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 7] Ratings bar...\n")

ratings_emm <- read_csv(here::here("output","tables","06_ratings_step1_emm.csv"),
                        show_col_types = FALSE) %>%
  filter(DV %in% c("Q1","Q2","Q3","Q4")) %>%
  mutate(
    frequency = factor(as.character(frequency), levels = FREQ_LEVELS),
    DV_label  = dplyr::recode(DV,
      Q1 = "Q1: Visual Comfort",
      Q2 = "Q2: Mental Demand",
      Q3 = "Q3: Effort",
      Q4 = "Q4: Decision Certainty"
    )
  )

p7 <- ggplot(ratings_emm,
             aes(x = frequency, y = emmean, fill = frequency,
                 ymin = lower.CL, ymax = upper.CL)) +
  geom_col(width = 0.6, alpha = 0.8) +
  geom_errorbar(width = 0.25, linewidth = 0.6) +
  facet_wrap(~DV_label, nrow = 2, scales = "free_y") +
  scale_fill_manual(values = FREQ_PAL) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "Subjective Ratings by Frequency (Estimated Marginal Means)",
    subtitle = "SRQ1 & SRQ2: EMMs ± 95% CI from Step-1 RM-ANOVA (GG-corrected)",
    x = "Flicker Frequency", y = "Mean Rating (1–7)", fill = "Frequency"
  ) +
  theme(legend.position = "none",
        axis.text.x = element_text(angle = 30, hjust = 1, size = 8))
save_fig(p7, "fig_ratings_bar", width_in = 9, height_in = 6)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 8 — Likert stacked bar: Q1–Q4 response distributions (SRQ2)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 8] Ratings Likert...\n")

likert_raw <- master %>%
  filter(!is.na(frequency)) %>%
  select(frequency, Q1, Q2, Q3, Q4) %>%
  pivot_longer(cols = Q1:Q4, names_to = "DV", values_to = "score") %>%
  filter(!is.na(score)) %>%
  mutate(
    score     = as.integer(round(score)),
    frequency = factor(as.character(frequency), levels = FREQ_LEVELS),
    DV_label  = dplyr::recode(DV,
      Q1 = "Q1: Visual Comfort",
      Q2 = "Q2: Mental Demand",
      Q3 = "Q3: Effort",
      Q4 = "Q4: Decision Certainty"
    )
  )

likert_prop <- likert_raw %>%
  group_by(DV_label, frequency, score) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(DV_label, frequency) %>%
  mutate(pct = 100 * n / sum(n)) %>%
  ungroup() %>%
  mutate(score_f = factor(score, levels = 1:7))

LIKERT_PAL <- c("1"="#B71C1C","2"="#E53935","3"="#EF9A9A",
                "4"="#E0E0E0","5"="#90CAF9","6"="#1E88E5","7"="#0D47A1")

p8 <- ggplot(likert_prop,
             aes(x = frequency, y = pct, fill = score_f)) +
  geom_col(width = 0.75, position = "stack") +
  facet_wrap(~DV_label, nrow = 2) +
  scale_fill_manual(values = LIKERT_PAL,
                    labels = c("1=Strongly Low","2","3","4=Neutral","5","6","7=Strongly High")) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "Likert Response Distributions (Q1–Q4) by Frequency",
    subtitle = "SRQ2: Proportion of responses at each scale point; darker blue = higher rating",
    x = "Flicker Frequency", y = "Percentage (%)", fill = "Rating"
  ) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1, size = 8),
        legend.text = element_text(size = 7))
save_fig(p8, "fig_ratings_likert", width_in = 10, height_in = 6)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 9 — Ratings heatmap: condition × dimension (SRQ1 & SRQ2)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 9] Ratings heatmap...\n")

ratings_desc <- read_csv(here::here("output","tables","03_descriptives_ratings.csv"),
                         show_col_types = FALSE) %>%
  filter(variable %in% c("Q1","Q2","Q3","Q4")) %>%
  mutate(
    condition = factor(
      make_cond_label(as.character(frequency), as.character(modulation_depth)),
      levels = COND_ORDER),
    DV_label = dplyr::recode(variable,
      Q1 = "Q1: Visual\nComfort",
      Q2 = "Q2: Mental\nDemand",
      Q3 = "Q3: Effort",
      Q4 = "Q4: Decision\nCertainty"
    )
  )

p9 <- ggplot(ratings_desc, aes(x = condition, y = DV_label, fill = mean)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = sprintf("%.2f", mean)), size = 2.8) +
  scale_fill_gradient2(low = "#1565C0", mid = "#FFFFFF", high = "#B71C1C",
                       midpoint = 4, limits = c(1, 7),
                       name = "Mean\nRating") +
  scale_x_discrete(labels = function(x) str_replace_all(x, " / ", "\n")) +
  labs(
    title    = "Mean Subjective Ratings: Condition × Dimension",
    subtitle = "SRQ1 & SRQ2: Which conditions produce highest discomfort and cognitive load?",
    x = NULL, y = NULL
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7.5),
        axis.text.y = element_text(size = 9))
save_fig(p9, "fig_ratings_heatmap", width_in = 11, height_in = 4.5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 10 — Eye dwell: CMS vs Road attention allocation stacked bar (SRQ2)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 10] Eye dwell...\n")

eye_desc <- read_csv(here::here("output","tables","03_descriptives_eye.csv"),
                     show_col_types = FALSE) %>%
  mutate(condition = factor(
    make_cond_label(as.character(frequency), as.character(modulation_depth)),
    levels = COND_ORDER))

dwell_cms  <- eye_desc %>%
  filter(variable == "dwell_ratio_cms")  %>%
  select(condition, frequency, modulation_depth, mean) %>%
  rename(cms = mean)

dwell_road <- eye_desc %>%
  filter(variable == "dwell_ratio_road") %>%
  select(condition, mean) %>%
  rename(road = mean)

dwell_join <- left_join(dwell_cms, dwell_road, by = "condition") %>%
  mutate(
    other = pmax(0, 1 - cms - road),
    condition = factor(condition, levels = COND_ORDER)
  ) %>%
  pivot_longer(cols = c(cms, road, other),
               names_to = "AOI", values_to = "ratio") %>%
  mutate(AOI = factor(AOI, levels = c("other","road","cms"),
                      labels = c("Other","Road","CMS")))

p10 <- ggplot(dwell_join, aes(x = condition, y = ratio * 100, fill = AOI)) +
  geom_col(width = 0.75) +
  scale_fill_manual(values = c("CMS"="#1E88E5","Road"="#43A047","Other"="#BDBDBD")) +
  scale_x_discrete(labels = function(x) str_replace_all(x, " / ", "\n")) +
  labs(
    title    = "Dwell Time Allocation: CMS vs Road vs Other",
    subtitle = "SRQ2: Visual attention distribution across 10 conditions",
    caption  = "dwell_ratio = proportion of valid gaze time; Other = non-AOI gaze",
    x = NULL, y = "Dwell Time (%)", fill = "AOI"
  ) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 7.5))
save_fig(p10, "fig_eye_dwell", width_in = 10, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 11 — Eye interaction: transition_count & fixation_duration_cms (SRQ2 & SRQ3)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 11] Eye interaction...\n")

eye_emm <- read_csv(here::here("output","tables","07_eye_step1_emm.csv"),
                    show_col_types = FALSE) %>%
  filter(DV %in% c("transition_count","fixation_duration_cms_mean_ms")) %>%
  mutate(
    frequency = factor(as.character(frequency), levels = FREQ_LEVELS),
    DV_label  = dplyr::recode(DV,
      transition_count             = "Transition Count\n(CMS ↔ Road)",
      fixation_duration_cms_mean_ms = "Mean Fixation Duration\non CMS (ms)"
    )
  )

p11 <- ggplot(eye_emm,
              aes(x = frequency, y = emmean, color = DV_label,
                  group = DV_label, ymin = lower.CL, ymax = upper.CL)) +
  geom_errorbar(width = 0.2, linewidth = 0.6) +
  geom_line(linewidth = 1) +
  geom_point(size = 3) +
  facet_wrap(~DV_label, scales = "free_y", nrow = 1) +
  scale_color_manual(values = c("#2196F3","#FF9800")) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "Key Eye Metrics by Frequency (Step-1 EMMs)",
    subtitle = "SRQ2: Visual search effort and CMS processing across flicker conditions",
    caption  = "Estimated Marginal Means ± 95% CI; GG-corrected RM-ANOVA, all p > .15",
    x = "Flicker Frequency", y = "Estimated Mean"
  ) +
  theme(legend.position = "none",
        strip.text = element_text(size = 9))
save_fig(p11, "fig_eye_interaction", width_in = 9, height_in = 4.5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 12 — First fixation CMS: two-stage (SRQ2)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 12] First fixation...\n")

prop_df <- read_csv(here::here("output","tables","07_eye_firstfix_stage1_prop_by_freq.csv"),
                    show_col_types = FALSE) %>%
  mutate(frequency = factor(as.character(frequency), levels = FREQ_LEVELS))

lat_emm <- tryCatch(
  read_csv(here::here("output","tables","07_eye_firstfix_stage2_s1_emm.csv"),
           show_col_types = FALSE) %>%
    mutate(frequency = factor(as.character(frequency), levels = FREQ_LEVELS)),
  error = function(e) NULL
)

p12a <- ggplot(prop_df, aes(x = frequency, y = pct_fixated, fill = frequency)) +
  geom_col(width = 0.6, alpha = 0.85) +
  geom_text(aes(label = sprintf("%.1f%%", pct_fixated)), vjust = -0.3, size = 3) +
  scale_fill_manual(values = FREQ_PAL) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  coord_cartesian(ylim = c(95, 101)) +
  labs(subtitle = "Stage 1: % Trials with CMS Fixation",
       x = "Frequency", y = "% Fixated") +
  theme(legend.position = "none")

if (!is.null(lat_emm) && nrow(lat_emm) > 0) {
  p12b <- ggplot(lat_emm,
                 aes(x = frequency, y = emmean / 1000,
                     ymin = lower.CL / 1000, ymax = upper.CL / 1000,
                     fill = frequency)) +
    geom_col(width = 0.6, alpha = 0.85) +
    geom_errorbar(width = 0.25, linewidth = 0.6) +
    scale_fill_manual(values = FREQ_PAL) +
    scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
    labs(subtitle = "Stage 2: Latency to First CMS Fixation (fixated trials only)",
         x = "Frequency", y = "Latency (s)") +
    theme(legend.position = "none")
} else {
  p12b <- ggplot() + annotate("text", x=1, y=1, label="Latency EMM not available") +
    labs(subtitle = "Stage 2: Latency (insufficient data)")
}

p12 <- p12a + p12b +
  patchwork::plot_annotation(
    title    = "First Fixation to CMS: Two-Stage Analysis",
    subtitle = "SRQ2: Does flicker affect when (and whether) drivers look at CMS?"
  )
save_fig(p12, "fig_eye_firstfix", width_in = 10, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 13 — SSQ pre vs post (SRQ2: simulator sickness)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 13] SSQ pre/post...\n")

ssq_raw <- tryCatch(
  read_excel(here::here("1. Experiment_Result","Google Forms",
                        "Simulator Sickness Questionnaire (SSQ) (Responses).xlsx")),
  error = function(e) { message("[WARN] SSQ file not readable: ", e$message); NULL }
)

if (!is.null(ssq_raw)) {
  # Parse "0 None", "1 Slight", "2 Moderate", "3 Severe" → 0/1/2/3
  ssq_items <- ssq_raw %>%
    rename(pid = `Participant ID`, session = `Test Session`) %>%
    mutate(pid = str_trim(pid)) %>%
    select(pid, session, starts_with("Symptom")) %>%
    mutate(across(starts_with("Symptom"),
                  ~as.numeric(str_extract(as.character(.x), "^\\d+"))))

  # Kennedy (1993) subscale assignment (spec §5.9)
  # N items = 1,6,7,8,12,13,14,15,16 → cols 1,6,7,8,12,13,14,15,16 (1-indexed symptom cols)
  item_cols <- names(ssq_items)[3:ncol(ssq_items)]   # 16 symptom columns
  N_idx  <- c(1, 6, 7, 8, 12, 13, 14, 15, 16)
  O_idx  <- c(2, 3, 4, 5,  9, 10, 11)

  ssq_scores <- ssq_items %>%
    rowwise() %>%
    mutate(
      N_raw = sum(c_across(all_of(item_cols[N_idx])), na.rm = TRUE),
      O_raw = sum(c_across(all_of(item_cols[O_idx])), na.rm = TRUE),
      D_raw = sum(c_across(all_of(item_cols[c(5,8,10,11,12,13,14)])), na.rm = TRUE),
      N_score = N_raw * 9.54,
      O_score = O_raw * 7.58,
      TS      = (N_raw + O_raw + D_raw) * 3.74
    ) %>%
    ungroup() %>%
    select(pid, session, N_score, O_score, TS)

  # Paired pre/post
  ssq_long <- ssq_scores %>%
    pivot_longer(cols = c(N_score, O_score, TS),
                 names_to = "subscale", values_to = "score") %>%
    mutate(
      session   = factor(session, levels = c("Pre-test","Post-test")),
      subscale  = dplyr::recode(subscale,
        N_score = "Nausea", O_score = "Oculo-motor", TS = "Total (TS)")
    )

  # Group summary for overlay
  ssq_grp <- ssq_long %>%
    group_by(session, subscale) %>%
    summarise(mean_score = mean(score, na.rm = TRUE), .groups = "drop")

  p13 <- ggplot(ssq_long, aes(x = session, y = score, group = pid)) +
    geom_line(alpha = 0.3, color = "#888", linewidth = 0.5) +
    geom_point(alpha = 0.4, size = 1.5, color = "#888") +
    geom_line(data = ssq_grp,
              aes(x = session, y = mean_score, group = subscale),
              inherit.aes = FALSE,
              color = "#E53935", linewidth = 1.5) +
    geom_point(data = ssq_grp,
               aes(x = session, y = mean_score),
               inherit.aes = FALSE,
               color = "#E53935", size = 3.5) +
    facet_wrap(~subscale, scales = "free_y", nrow = 1) +
    labs(
      title    = "Simulator Sickness (SSQ): Pre- vs Post-Test",
      subtitle = "SRQ2: Did the simulator session induce sickness? Grey = individual, Red = mean",
      caption  = "Kennedy (1993) weighting: N×9.54, O×7.58, TS = (N+O+D)×3.74",
      x = NULL, y = "SSQ Score"
    ) +
    theme(axis.text.x = element_text(size = 9))
  save_fig(p13, "fig_ssq_prepost", width_in = 10, height_in = 5)
} else {
  cat("  [SKIP] SSQ data not available — fig_ssq_prepost.png skipped.\n")
}

# ═══════════════════════════════════════════════════════════════════════════════
# FIG 14 — Effect size forest plot: ηp² for frequency across all DVs (all SRQs)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG 14] Forest plot...\n")

# Collect frequency Step-1 pes from all analysis CSVs
ttc_es <- read_csv(here::here("output","tables","05_anova_ttc_step1_main.csv"),
                   show_col_types = FALSE) %>%
  mutate(DV = "TTC", group = "Behaviour")

ratings_es <- read_csv(here::here("output","tables","06_ratings_step1_main.csv"),
                       show_col_types = FALSE) %>%
  mutate(group = "Subjective Rating")

eye_es <- read_csv(here::here("output","tables","07_eye_step1_main.csv"),
                   show_col_types = FALSE) %>%
  filter(Effect == "frequency") %>%
  mutate(group = "Eye Tracking")

forest_df <- bind_rows(ttc_es, ratings_es, eye_es) %>%
  filter(Effect == "frequency") %>%
  mutate(
    sig    = case_when(p_GG < .001 ~ "***", p_GG < .01 ~ "**",
                       p_GG < .05 ~ "*",   TRUE ~ "ns"),
    DV     = factor(DV, levels = rev(unique(DV))),
    group  = factor(group, levels = c("Behaviour","Subjective Rating","Eye Tracking"))
  )

p14 <- ggplot(forest_df, aes(x = DV, y = pes, color = group, shape = sig)) +
  geom_hline(yintercept = c(0.01, 0.06, 0.14), linetype = "dotted",
             color = "#BDBDBD", linewidth = 0.5) +
  geom_errorbar(aes(ymin = pes_CI_low, ymax = pes_CI_high),
                width = 0.35, linewidth = 0.7) +
  geom_point(size = 3.5) +
  coord_flip() +
  facet_grid(group ~ ., scales = "free_y", space = "free_y") +
  scale_color_manual(values = c("Behaviour"="#E53935","Subjective Rating"="#FF9800",
                                "Eye Tracking"="#2196F3")) +
  scale_shape_manual(values = c("***"=16,"**"=17,"*"=15,"ns"=21),
                     labels = c("ns"="ns","*"="p<.05","**"="p<.01","***"="p<.001")) +
  scale_y_continuous(limits = c(-0.05, 1.0), breaks = seq(0, 1, 0.2)) +
  labs(
    title    = "Effect Sizes (ηp²): Frequency Main Effect Across All DVs",
    subtitle = "SRQ1: Step-1 RM-ANOVA (4-level frequency); points = ηp², bars = 95% CI",
    caption  = "Cohen benchmarks: small=0.01, medium=0.06, large=0.14",
    y = "Partial η² (ηp²)", x = NULL, color = "Domain", shape = "Sig."
  ) +
  theme(
    strip.text         = element_text(size = 9, face = "bold"),
    legend.position    = "right",
    panel.grid.major.x = element_blank()
  )
save_fig(p14, "fig_effectsize_forest", width_in = 10, height_in = 8)

# ═══════════════════════════════════════════════════════════════════════════════
# DONE — list all generated figures
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 65), "\n")
cat("10_plots.R DONE — figures generated in output/figures/\n")
cat(strrep("=", 65), "\n\n")

figs <- list.files(here::here("output","figures"), pattern = "\\.png$", full.names = FALSE)
for (f in sort(figs)) cat(sprintf("  %s\n", f))
cat(sprintf("\nTotal: %d PNG files\n", length(figs)))
