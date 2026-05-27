# 10b_ratings_unified.R — Descriptive table + 3 figures, unified negative direction
# All four DVs transformed so higher = more negative subjective experience:
#   Q1 → Visual Discomfort    = 8 − Q1_recoded  (Q1_recoded = comfort in ingest)
#   Q2 → Mental Demand        = Q2  (unchanged)
#   Q3 → Effort               = Q3  (unchanged)
#   Q4 → Decision Uncertainty = 8 − Q4
source(here::here("R", "00_setup.R"))

COND_ORDER <- c(
  "0 Hz (stable)",
  "8.33 Hz / 40%", "8.33 Hz / 60%", "8.33 Hz / 80%",
  "12.5 Hz / 40%", "12.5 Hz / 60%", "12.5 Hz / 80%",
  "25 Hz / 40%",   "25 Hz / 60%",   "25 Hz / 80%"
)

FREQ_PAL  <- c("0"="#888888","8.33"="#2196F3","12.5"="#FF9800","25"="#E53935")
DEPTH_PAL <- c("40"="#4CAF50","60"="#FF9800","80"="#E53935")
DEPTH_LTY <- c("40"="solid","60"="dashed","80"="dotted")
DV_LEVELS <- c("Visual Discomfort","Mental Demand","Effort","Decision Uncertainty")
DV_COLORS <- c(
  "Visual Discomfort"    = "#E53935",
  "Mental Demand"        = "#FF9800",
  "Effort"               = "#9C27B0",
  "Decision Uncertainty" = "#2196F3"
)

flip8 <- function(x) 8 - x   # invert: 1↔7, 2↔6, 3↔5, midpoint 4=4

make_cond_label <- function(freq, depth) {
  ifelse(is.na(depth), paste0(freq, " Hz (stable)"), paste0(freq, " Hz / ", depth, "%"))
}

# ── Load raw descriptives ──────────────────────────────────────────────────────
desc <- read_csv(here::here("output","tables","03_descriptives_ratings.csv"),
                 show_col_types = FALSE) %>%
  filter(variable %in% c("Q1","Q2","Q3","Q4")) %>%
  mutate(
    mean_u = case_when(variable %in% c("Q1","Q4") ~ flip8(mean), TRUE ~ mean),
    se     = sd / sqrt(n),
    ci_lo  = mean_u - 1.96 * se,
    ci_hi  = mean_u + 1.96 * se,
    DV_label = factor(dplyr::recode(variable,
      Q1 = "Visual Discomfort", Q2 = "Mental Demand",
      Q3 = "Effort",             Q4 = "Decision Uncertainty"),
      levels = DV_LEVELS),
    condition = factor(
      make_cond_label(as.character(frequency), as.character(modulation_depth)),
      levels = COND_ORDER),
    freq_f  = factor(as.character(frequency),        levels = FREQ_LEVELS),
    depth_f = factor(as.character(modulation_depth), levels = DEPTH_LEVELS)
  )

# ── Step-1 EMMs: flip Q1 & Q4, mirror CI ──────────────────────────────────────
emm <- read_csv(here::here("output","tables","06_ratings_step1_emm.csv"),
                show_col_types = FALSE) %>%
  filter(DV %in% c("Q1","Q2","Q3","Q4")) %>%
  mutate(
    freq_f  = factor(str_remove(as.character(frequency), "^X"), levels = FREQ_LEVELS),
    em_u    = case_when(DV %in% c("Q1","Q4") ~ flip8(emmean),  TRUE ~ emmean),
    lo_u    = case_when(DV %in% c("Q1","Q4") ~ flip8(upper.CL), TRUE ~ lower.CL),
    hi_u    = case_when(DV %in% c("Q1","Q4") ~ flip8(lower.CL), TRUE ~ upper.CL),
    DV_label = factor(dplyr::recode(DV,
      Q1 = "Visual Discomfort", Q2 = "Mental Demand",
      Q3 = "Effort",             Q4 = "Decision Uncertainty"),
      levels = DV_LEVELS)
  )

# ── Build & save descriptive table (wide, M (SD) format) ─────────────────────
cat("\n[10b] Unified Descriptive Statistics (higher = more negative):\n")

tbl_wide <- desc %>%
  mutate(val = sprintf("%.2f (%.2f)", mean_u, sd)) %>%
  select(condition, DV_label, val) %>%
  pivot_wider(names_from = DV_label, values_from = val)

save_csv(tbl_wide, "10b_ratings_unified_descriptives")
print(as.data.frame(tbl_wide))

# ── Also save long form with all statistics ───────────────────────────────────
tbl_long <- desc %>%
  select(condition, DV_label, n, mean_neg = mean_u, sd, se, ci_lo, ci_hi) %>%
  mutate(across(where(is.numeric), ~round(.x, 3)))
save_csv(tbl_long, "10b_ratings_unified_descriptives_long")

# ═══════════════════════════════════════════════════════════════════════════════
# FIG A — Step-1 EMMs by frequency (4-level), unified direction
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n[FIG A] EMM bar chart by frequency...\n")

pA <- ggplot(emm, aes(x = freq_f, y = em_u, fill = freq_f, ymin = lo_u, ymax = hi_u)) +
  geom_col(width = 0.65, alpha = 0.85) +
  geom_errorbar(width = 0.28, linewidth = 0.65) +
  facet_wrap(~DV_label, nrow = 2, scales = "free_y") +
  scale_fill_manual(values = FREQ_PAL) +
  scale_x_discrete(labels = function(x) paste0(x, " Hz")) +
  labs(
    title    = "Subjective Ratings by Frequency — Unified Negative Direction",
    subtitle = "Estimated Marginal Means ± 95% CI (Step-1 GG-corrected RM-ANOVA); higher = worse",
    x        = "Flicker Frequency",
    y        = "Mean Rating (1–7)",
    caption  = "Q1 Discomfort = 8 − Comfort; Q4 Uncertainty = 8 − Certainty"
  ) +
  theme(
    legend.position   = "none",
    axis.text.x       = element_text(angle = 30, hjust = 1, size = 8),
    strip.text        = element_text(size = 10, face = "bold"),
    panel.spacing     = unit(1.2, "lines")
  )

save_fig(pA, "fig_ratings_unified_emm", width_in = 9, height_in = 6)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG B — Heatmap: 10 conditions × 4 DVs, unified direction
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG B] Heatmap 10 × 4...\n")

pB <- ggplot(desc, aes(x = condition, y = DV_label, fill = mean_u)) +
  geom_tile(color = "white", linewidth = 0.5) +
  geom_text(aes(label = sprintf("%.2f", mean_u)), size = 2.8, color = "black",
            fontface = "bold") +
  scale_fill_gradient(
    low    = "#FFFFFF",
    high   = "#B71C1C",
    limits = c(1, 7),
    name   = "Mean\n(1–7)"
  ) +
  scale_x_discrete(labels = function(x) str_replace_all(x, " / ", "\n")) +
  scale_y_discrete(limits = rev(DV_LEVELS)) +
  labs(
    title    = "Subjective Ratings: Condition × Dimension",
    subtitle = "Unified direction — higher = worse; darker red = more negative experience",
    x        = NULL,
    y        = NULL,
    caption  = "Q1 = Visual Discomfort (8−Comfort); Q4 = Decision Uncertainty (8−Certainty)"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 7.5),
    axis.text.y = element_text(size = 9.5)
  )

save_fig(pB, "fig_ratings_unified_heatmap", width_in = 11, height_in = 4.5)

# ═══════════════════════════════════════════════════════════════════════════════
# FIG C — Modulation depth effect: 4-DV line plot (flickering conditions)
# ═══════════════════════════════════════════════════════════════════════════════
cat("[FIG C] Modulation depth line plot...\n")

depth_agg <- desc %>%
  filter(!is.na(depth_f)) %>%
  group_by(DV_label, depth_f) %>%
  summarise(
    M  = mean(mean_u, na.rm = TRUE),
    SD = sd(mean_u, na.rm = TRUE),   # between-cell variability across frequencies
    N  = n(),
    SE = SD / sqrt(N),
    .groups = "drop"
  ) %>%
  mutate(CI_lo = M - 1.96 * SE, CI_hi = M + 1.96 * SE)

pC <- ggplot(depth_agg,
             aes(x = depth_f, y = M, color = DV_label, group = DV_label,
                 linetype = DV_label, ymin = CI_lo, ymax = CI_hi)) +
  geom_line(linewidth = 1.15, position = position_dodge(0.08)) +
  geom_point(size = 3.5,      position = position_dodge(0.08)) +
  geom_errorbar(width = 0.18, linewidth = 0.65, position = position_dodge(0.08)) +
  scale_x_discrete(labels = function(x) paste0(x, "%")) +
  scale_color_manual(values = DV_COLORS) +
  scale_linetype_manual(values = c("solid","longdash","dotted","dotdash")) +
  coord_cartesian(ylim = c(1, 7)) +
  labs(
    title    = "Modulation Depth Effect — Unified Negative Direction",
    subtitle = "Means averaged over frequency; 95% CI from between-cell SD ÷ √3 (flickering only)",
    x        = "Modulation Depth",
    y        = "Mean Rating (1–7, higher = worse)",
    color    = NULL,
    linetype = NULL,
    caption  = "Each point = mean of 3 depth × 25 participants; Q2 & Q3 show strong depth gradient"
  ) +
  theme(legend.position = "right", legend.text = element_text(size = 9))

save_fig(pC, "fig_ratings_unified_depth", width_in = 8.5, height_in = 5)

# ═══════════════════════════════════════════════════════════════════════════════
# DONE
# ═══════════════════════════════════════════════════════════════════════════════
cat("\n", strrep("=", 60), "\n")
cat("10b_ratings_unified.R DONE\n")
cat(strrep("=", 60), "\n")
cat("  CSV: 10b_ratings_unified_descriptives.csv  (wide, M(SD))\n")
cat("  CSV: 10b_ratings_unified_descriptives_long.csv  (long, all stats)\n")
cat("  FIG A: fig_ratings_unified_emm.png       — Step-1 EMMs by frequency\n")
cat("  FIG B: fig_ratings_unified_heatmap.png   — 10 conditions × 4 DVs\n")
cat("  FIG C: fig_ratings_unified_depth.png     — depth effect, all 4 DVs\n")
