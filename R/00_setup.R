# 00_setup.R — packages, seed, factor levels, helper functions
# Run once at the top of every other script via: source(here::here("R","00_setup.R"))

# ── 1. Auto-install missing packages ──────────────────────────────────────────
pkgs <- c(
  "tidyverse", "afex", "emmeans", "rstatix", "ggpubr",
  "performance", "car", "broom", "broom.mixed",
  "lme4", "lmerTest", "ordinal", "patchwork", "here", "janitor"
)
missing_pkgs <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing_pkgs) > 0) {
  message("Installing missing packages: ", paste(missing_pkgs, collapse = ", "))
  install.packages(missing_pkgs, repos = "https://cloud.r-project.org")
}
invisible(lapply(pkgs, library, character.only = TRUE))

# ── 2. Reproducibility ────────────────────────────────────────────────────────
set.seed(2026)

# ── 3. Factor level orders ────────────────────────────────────────────────────
FREQ_LEVELS  <- c("0", "8.33", "12.5", "25")          # Hz
DEPTH_LEVELS <- c("40", "60", "80")                    # % modulation depth

# ── 4. Paths (relative to project root via here) ──────────────────────────────
DIR_DATA    <- here::here("data")
DIR_TABLES  <- here::here("output", "tables")
DIR_FIGURES <- here::here("output", "figures")
DIR_OUTPUT  <- here::here("output")

# ── 5. Helper: save a data frame as CSV ───────────────────────────────────────
#   Usage: save_csv(df, "03_descriptives_ttc")
save_csv <- function(df, name, dir = DIR_TABLES) {
  path <- file.path(dir, paste0(name, ".csv"))
  readr::write_csv(df, path)
  message("  [CSV] Saved → ", path)
  invisible(path)
}

# ── 6. Helper: save a ggplot as PNG (300 dpi, unified theme) ──────────────────
#   Usage: save_fig(p, "fig_ttc_box")
#   Optional: width_in / height_in in inches (defaults: 8 × 5)
PLOT_THEME <- ggplot2::theme_minimal(base_size = 12)

save_fig <- function(plot, name, width_in = 8, height_in = 5, dir = DIR_FIGURES) {
  path <- file.path(dir, paste0(name, ".png"))
  ggplot2::ggsave(
    filename = path,
    plot     = plot + PLOT_THEME,
    width    = width_in,
    height   = height_in,
    dpi      = 300,
    units    = "in"
  )
  message("  [FIG] Saved → ", path)
  invisible(path)
}

message("00_setup.R loaded — seed=2026, theme=theme_minimal(12), helpers ready.")
