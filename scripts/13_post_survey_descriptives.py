"""
Script 13: Post-Experiment Questionnaire Descriptive Statistics
Source: Google Forms / Post-Experiment Questionnaire (Responses).xlsx
N = 25 participants
9 ordinal questions; output frequency tables + visualizations
"""

import openpyxl
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path
from scipy import stats

# ── Paths ────────────────────────────────────────────────────────────────────
BASE   = Path(__file__).resolve().parent.parent
SRC    = BASE / "1. Experiment_Result" / "Google Forms" / "Post-Experiment Questionnaire  (Responses).xlsx"
TABLES = BASE / "output" / "tables"
FIGS   = BASE / "output" / "figures"
TABLES.mkdir(parents=True, exist_ok=True)
FIGS.mkdir(parents=True, exist_ok=True)

# ── Ordinal scale definitions (low → high) ───────────────────────────────────
SCALES = {
    "Q1_difficulty": {
        "label": "Q1: Lane-change difficulty",
        "direction": "higher = more difficult",
        "ordered": ["Easy", "Somewhat easy", "Neutral",
                    "Somewhat difficult", "Difficult", "Very difficult"],
    },
    "Q2_mental_demand": {
        "label": "Q2: Mental demand",
        "direction": "higher = more demand",
        "ordered": ["Low", "Somewhat low", "Moderate",
                    "Somewhat high", "High", "Very high"],
    },
    "Q3_effort": {
        "label": "Q3: Effort exerted",
        "direction": "higher = more effort",
        "ordered": ["Little", "Somewhat little", "Moderate",
                    "Somewhat much", "Much", "Very much"],
    },
    "Q4_motion_clarity": {
        "label": "Q4: Motion clarity (CMS display)",
        "direction": "higher = clearer",
        "ordered": ["Very unclear", "Unclear", "Somewhat unclear",
                    "Neutral", "Somewhat clear", "Clear"],
    },
    "Q5_flicker_interference": {
        "label": "Q5: Flicker interference",
        "direction": "higher = more interference",
        "ordered": ["Slightly", "Moderately", "Strongly",
                    "Very strongly", "Extremely"],
    },
    "Q6_visual_discomfort": {
        "label": "Q6: Visual discomfort / eye fatigue",
        "direction": "higher = more discomfort",
        "ordered": ["Hardly any", "Slightly", "Moderate",
                    "Noticeable", "Severe"],
    },
    "Q7_confidence": {
        "label": "Q7: Decision confidence",
        "direction": "higher = more confident",
        "ordered": ["Not confident at all", "Unconfident", "Neutral",
                    "Somewhat confident", "Confident"],
    },
    "Q8_flicker_noticeability": {
        "label": "Q8: Flicker-difference noticeability",
        "direction": "higher = more noticeable",
        "ordered": ["Slightly noticeable", "Noticeable",
                    "Very noticeable", "Extremely noticeable"],
    },
    "Q9_flicker_influence": {
        "label": "Q9: Flicker influence on decisions",
        "direction": "higher = more influence",
        "ordered": ["Hardly at all", "Slightly", "Moderately",
                    "Strongly", "Significantly"],
    },
}

# ── Load data ─────────────────────────────────────────────────────────────────
wb = openpyxl.load_workbook(SRC)
ws = wb.active
rows = list(ws.iter_rows(min_row=2, values_only=True))   # skip header

COL_NAMES = list(SCALES.keys())
raw_data = {col: [] for col in COL_NAMES}
participant_ids = []

for row in rows:
    pid = str(row[1]).strip()
    participant_ids.append(pid)
    for i, col in enumerate(COL_NAMES):
        raw_data[col].append(str(row[i + 2]).strip() if row[i + 2] is not None else None)

df_raw = pd.DataFrame(raw_data, index=participant_ids)
df_raw.index.name = "participant_id"

# ── Encode to numeric ─────────────────────────────────────────────────────────
df_num = pd.DataFrame(index=participant_ids)
df_num.index.name = "participant_id"

for col, meta in SCALES.items():
    mapping = {label: i + 1 for i, label in enumerate(meta["ordered"])}
    encoded = df_raw[col].map(mapping)
    unmapped = df_raw[col][encoded.isna()]
    if len(unmapped) > 0:
        print(f"WARNING: unmapped values in {col}: {unmapped.unique().tolist()}")
    df_num[col] = encoded.astype(float)

# ── Descriptive statistics ────────────────────────────────────────────────────
rows_desc = []
for col, meta in SCALES.items():
    s = df_num[col].dropna()
    n = len(s)
    m = s.mean()
    sd = s.std(ddof=1)
    med = s.median()
    q1_iqr, q3_iqr = s.quantile(0.25), s.quantile(0.75)
    iqr = q3_iqr - q1_iqr
    mode_val = s.mode().iloc[0] if not s.mode().empty else np.nan
    mode_label = meta["ordered"][int(mode_val) - 1] if not np.isnan(mode_val) else ""
    med_label  = meta["ordered"][int(round(med)) - 1] if not np.isnan(med) else ""
    rows_desc.append({
        "question":   col,
        "label":      meta["label"],
        "n":          n,
        "mean":       round(m, 3),
        "SD":         round(sd, 3),
        "median":     round(med, 2),
        "median_label": med_label,
        "IQR":        round(iqr, 2),
        "Q1":         round(q1_iqr, 2),
        "Q3":         round(q3_iqr, 2),
        "mode":       int(mode_val) if not np.isnan(mode_val) else "",
        "mode_label": mode_label,
        "min":        int(s.min()),
        "max":        int(s.max()),
        "n_levels":   len(meta["ordered"]),
        "direction":  meta["direction"],
    })

df_desc = pd.DataFrame(rows_desc)
df_desc.to_csv(TABLES / "13_post_survey_descriptives.csv", index=False)
print("Saved: 13_post_survey_descriptives.csv")

# ── Frequency tables ──────────────────────────────────────────────────────────
freq_rows = []
for col, meta in SCALES.items():
    for i, lbl in enumerate(meta["ordered"]):
        n_obs = int((df_raw[col] == lbl).sum())
        freq_rows.append({
            "question":     col,
            "question_label": meta["label"],
            "numeric_code": i + 1,
            "response_label": lbl,
            "n":            n_obs,
            "pct":          round(n_obs / len(df_raw) * 100, 1),
        })

df_freq = pd.DataFrame(freq_rows)
df_freq.to_csv(TABLES / "13_post_survey_frequencies.csv", index=False)
print("Saved: 13_post_survey_frequencies.csv")

# ── Raw coded data ─────────────────────────────────────────────────────────────
df_out = df_raw.copy()
for col, meta in SCALES.items():
    mapping = {label: i + 1 for i, label in enumerate(meta["ordered"])}
    df_out[col + "_code"] = df_raw[col].map(mapping)

df_out.to_csv(TABLES / "13_post_survey_raw.csv")
print("Saved: 13_post_survey_raw.csv")

# ── Figure 1: Stacked bar chart for all 9 questions ──────────────────────────
PALETTE = {
    5: ["#d73027", "#fc8d59", "#fee090", "#91bfdb", "#4575b4"],
    6: ["#d73027", "#fc8d59", "#fee090", "#e0f3f8", "#91bfdb", "#4575b4"],
    4: ["#fc8d59", "#fee090", "#91bfdb", "#4575b4"],
}

fig, axes = plt.subplots(9, 1, figsize=(12, 18))
fig.subplots_adjust(hspace=0.55, left=0.35, right=0.95)

for ax, (col, meta) in zip(axes, SCALES.items()):
    ordered = meta["ordered"]
    n_levels = len(ordered)
    counts = [int((df_raw[col] == lbl).sum()) for lbl in ordered]
    pcts   = [c / len(df_raw) * 100 for c in counts]

    colors = PALETTE.get(n_levels, plt.cm.RdYlBu(np.linspace(0.1, 0.9, n_levels)))

    left = 0.0
    for k, (pct, color, lbl) in enumerate(zip(pcts, colors, ordered)):
        bar = ax.barh(0, pct, left=left, color=color, edgecolor="white", height=0.6)
        if pct >= 6:
            ax.text(left + pct / 2, 0, f"{counts[k]}", ha="center", va="center",
                    fontsize=7.5, fontweight="bold", color="black")
        left += pct

    med_val = df_num[col].median()
    med_pct_approx = sum(pcts[:int(med_val) - 1]) + pcts[int(med_val) - 1] * 0.5
    ax.axvline(sum(pcts[:int(med_val) - 1]) + pcts[int(med_val) - 1] * 0.5,
               color="black", linewidth=1.5, linestyle="--", alpha=0.7)

    ax.set_xlim(0, 100)
    ax.set_yticks([])
    ax.set_xlabel("Percentage (%)", fontsize=8)
    ax.set_title(meta["label"], fontsize=8.5, loc="left", pad=3)
    ax.tick_params(axis="x", labelsize=7)
    ax.spines[["top", "right", "left"]].set_visible(False)

    # Legend inside ax
    patches = [mpatches.Patch(color=c, label=l)
               for c, l in zip(colors, ordered)]
    ax.legend(handles=patches, fontsize=6, loc="lower right",
              bbox_to_anchor=(1.0, -0.35), ncol=n_levels,
              frameon=False, handlelength=0.8)

fig.suptitle("Post-Experiment Questionnaire — Response Distribution (N = 25)\nDashed line = median",
             fontsize=10, y=0.995)

outpath = FIGS / "fig_post_survey_stacked.png"
fig.savefig(outpath, dpi=150, bbox_inches="tight")
plt.close(fig)
print(f"Saved: {outpath.name}")

# ── Figure 2: Dot-plot summary (median ± IQR for all 9 Qs) ──────────────────
fig2, ax2 = plt.subplots(figsize=(7, 5))

q_labels   = [meta["label"].replace("Q", "Q") for meta in SCALES.values()]
short_labels = [f"Q{i+1}" for i in range(9)]
medians    = df_desc["median"].values
q1_vals    = df_desc["Q1"].values
q3_vals    = df_desc["Q3"].values
n_levels   = df_desc["n_levels"].values
means      = df_desc["mean"].values

# Normalise to 0–1 within each question's scale
med_norm  = (medians - 1) / (n_levels - 1)
q1_norm   = (q1_vals - 1)  / (n_levels - 1)
q3_norm   = (q3_vals - 1)  / (n_levels - 1)
mean_norm = (means - 1)    / (n_levels - 1)

y = np.arange(9)
ax2.barh(y, q3_norm - q1_norm, left=q1_norm, height=0.35,
         color="#91bfdb", alpha=0.6, label="IQR")
ax2.scatter(med_norm, y, color="#d73027", s=60, zorder=5, label="Median")
ax2.scatter(mean_norm, y, color="#4575b4", s=30, marker="D",
            zorder=4, label="Mean", alpha=0.8)
ax2.axvline(0.5, color="grey", linestyle=":", linewidth=1)

ax2.set_yticks(y)
ax2.set_yticklabels([f"Q{i+1}: {list(SCALES.values())[i]['label'].split(': ')[1][:40]}"
                     for i in range(9)], fontsize=7.5)
ax2.set_xlabel("Normalised scale position (0 = lowest, 1 = highest)", fontsize=8)
ax2.set_xlim(-0.05, 1.05)
ax2.set_title("Post-Experiment Questionnaire — Median (red) ± IQR (blue bar)\n"
              "Diamond = Mean; all scales normalised to 0–1", fontsize=8.5)
ax2.legend(fontsize=8, loc="lower right")
ax2.spines[["top", "right"]].set_visible(False)

fig2.tight_layout()
outpath2 = FIGS / "fig_post_survey_summary.png"
fig2.savefig(outpath2, dpi=150, bbox_inches="tight")
plt.close(fig2)
print(f"Saved: {outpath2.name}")

# ── Console summary ───────────────────────────────────────────────────────────
print("\n=== DESCRIPTIVE SUMMARY (N=25) ===")
for _, row in df_desc.iterrows():
    print(f"  {row['label']}")
    print(f"    M={row['mean']:.2f} (SD={row['SD']:.2f})  "
          f"Mdn={row['median']:.1f} [{row['median_label']}]  "
          f"IQR=[{row['Q1']:.1f}, {row['Q3']:.1f}]  "
          f"Mode: {row['mode_label']}")

print("\nDone.")
