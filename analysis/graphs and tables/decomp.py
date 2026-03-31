import pandas as pd
import numpy as np
import matplotlib.pyplot as plt

# ---- paths (Windows) ----
dta_path = r"C:\Users\aljos\OneDrive - University of Arizona\weather_and_agriculture\lsms_ag_prod_data\graphs&tables\dta_files_merge\decomp_hh_early_late_BALANCED.dta"
out_png  = r"C:\Users\aljos\OneDrive - University of Arizona\weather_and_agriculture\lsms_ag_prod_data\graphs&tables\decomp_within_between_facets.png"
# -------------------------

df = pd.read_stata(dta_path)

def pooled_decomp(d, v0, v1, w0, w1):
    # normalize weights within period
    w0n = d[w0].to_numpy()
    w1n = d[w1].to_numpy()
    w0n = w0n / np.nansum(w0n)
    w1n = w1n / np.nansum(w1n)

    y0 = np.nansum(w0n * d[v0].to_numpy())
    y1 = np.nansum(w1n * d[v1].to_numpy())
    dy = y1 - y0

    wbar = 0.5 * (w0n + w1n)
    ybar = 0.5 * (d[v0].to_numpy() + d[v1].to_numpy())
    dyi  = d[v1].to_numpy() - d[v0].to_numpy()
    dwi  = w1n - w0n

    within  = np.nansum(wbar * dyi)
    between = np.nansum(ybar * dwi)
    return y0, y1, dy, within, between


# Outcomes shown in your decomposition figure
metrics = [
    ("Productivity", "y_hh_pt0", "y_hh_pt1"),
    ("Total labor",  "Ltot_hh_pt0", "Ltot_hh_pt1"),
    ("Family labor", "Lfam_hh_pt0", "Lfam_hh_pt1"),
    ("Hired labor",  "Lhir_hh_pt0", "Lhir_hh_pt1"),
]

# Compute pooled within/between contributions
results = []
for lab, v0, v1 in metrics:
    _, _, _, w, b = pooled_decomp(df, v0, v1, "w_hh0", "w_hh1")
    results.append((lab, float(w), float(b)))

# Colors + style to match your example
col_within  = "#1f4e79"   # dark blue
col_between = "#2e86c1"   # lighter blue
strip_color = "#efe3a4"   # pale yellow strip
grid_color  = "#d9d9d9"

# Determine a common y-limit across panels (symmetric around zero)
vals = np.array([v for _, w, b in results for v in (w, b)])
ymax = np.max(np.abs(vals))
ypad = 0.15 * ymax if ymax > 0 else 1
ylim = (-ymax - ypad, ymax + ypad)

fig, axes = plt.subplots(1, len(results), figsize=(10.5, 3.8), sharey=True)

for ax, (lab, w, b) in zip(axes, results):
    # grid + zero line
    ax.set_axisbelow(True)
    ax.yaxis.grid(True, color=grid_color, linewidth=0.8)
    ax.axhline(0, color="#666666", linewidth=1)

    # "lollipop" stems to zero + dots
    xw, xb = 0.85, 1.15
    ax.vlines(xw, 0, w, color=col_within,  linewidth=1.6)
    ax.vlines(xb, 0, b, color=col_between, linewidth=1.6)
    ax.scatter([xw], [w], s=28, color=col_within,  zorder=3)
    ax.scatter([xb], [b], s=28, color=col_between, zorder=3)

    # x formatting
    ax.set_xlim(0.6, 1.4)
    ax.set_xticks([xw, xb])
    ax.set_xticklabels(["Within", "Between"], rotation=90, fontsize=8)

    # y formatting
    ax.set_ylim(*ylim)

    # panel border (match your example’s strong borders)
    for spine in ax.spines.values():
        spine.set_linewidth(1.2)
        spine.set_color("black")

    # title strip
    ax.set_title(
        lab,
        fontsize=9,
        pad=8,
        bbox=dict(facecolor=strip_color, edgecolor="black", boxstyle="square,pad=0.25")
    )

# shared y label
axes[0].set_ylabel("Contribution", fontsize=9)

# legend (optional; can omit since labels are on x-axis)
# fig.legend(["Within", "Between"], loc="lower center", ncol=2, frameon=False)

fig.tight_layout()
fig.savefig(out_png, dpi=300)
plt.show()