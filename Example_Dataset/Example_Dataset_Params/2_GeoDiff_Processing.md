# Notebook 2 — GeoDiff processing

Exact `params:` used for the **GSE226829** exemplar render. This stage fits the GeoDiff
Poisson-background model, flags outliers, estimates quantile factors, and writes the
GeoDiff-filtered count object used by stage 3.

GeoDiff is an addition of this pipeline (the original published analysis did not use it),
so these are the protocol defaults rather than paper-matched values.

## Analysis parameters

| Parameter | Value | Notes |
|---|---|---|
| `seed` | `123` | Reproducibility. |
| `split_var` | `slide_name` | Optional second-pass split variable. Blank (`""`) for single-slide studies. |
| `fallback_group_var` | `segment` | Report grouping when `split_var` is blank. |
| `bg_pvalue_threshold` | `1e-3` | Background-model significance threshold. |
| `rerun_dispersion_threshold` | `2` | Refit Poisson background only when initial dispersion exceeds this. |
| `rerun_when_high_dispersion` | `true` | Allow the refit when dispersion is high. |
| `mask_outliers_before_rerun` | `true` | Set detected outlier cells to NA before the optional refit. |
| `quanrange_probs` | `[0.75, 0.8, 0.9, 0.95]` | Quantile probabilities estimated by QuanRange. |
| `quanrange_split` | `false` | One global quantile-factor estimate (more stable for small/uneven groups). |
| `roi_para_quantile` | `0.90` | Segment parameter quantile for the final keep-list. |
| `roi_signal_threshold` | `2` | Segment signal threshold for the final keep-list (protocol default). |

## Dataset-specific

| Parameter | Value | Notes |
|---|---|---|
| `disease_col` | `disease_status` | Column used for optional metadata diagnostics. |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_src` / `dir_outputs` | `src` / `Outputs` |
| `qc_stage` | `1_QC` |
| `qc_results_dir` | `results` |
| `qc_pass_rds` | `QC_pass_spatial_data.RDS` |
| `out_stage` | `2_GeoDiff` |
| `out_results` | `results` |
| `save_rds` / `save_plots` | `true` / `true` |
