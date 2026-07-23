README: 2_GeoDiff_Processing.qmd
================================

Purpose
-------
This README is a practical user guide for the Quarto workflow:
`2_GeoDiff_Processing.qmd`.

Path portability
----------------
This stage defaults to `project_root: "."` and performs a 200-character path-portability audit before creating outputs. Review the rendered audit when working in Dropbox, OneDrive, or another deeply nested location. Generated diagnostic filenames may be shortened with a deterministic hash; required stage-contract filenames are preserved exactly.
Terminology used in this document:
- This stage runs after QC and expects the stage-1 QC-pass object as input.

The workflow performs these core tasks:
1) Loads the QC-pass GeoMx object,
2) Fits GeoDiff background models and diagnostics,
3) Performs probe aggregation and background score testing,
4) Estimates signal factors / quantile ranges,
5) Applies segment retention filtering and writes a GeoDiff-filtered count object for later stages.

This document explains what to provide, how to configure YAML, what outputs to expect, and how users/reviewers should run and validate the step.

Terminology note:
- A **segment**, or area of illumination (AOI), is the profiled GeoMx collection area within a region of interest (ROI). One ROI may contain several segments (for example PanCK, A-SMA, CD45, Stroma). The segment is the unit of data here: one segment corresponds to one DCC file and one column of the GeoMx object, so every count reported by this stage is a segment count.

Optional route note:
- GeoDiff is an optional branch of the full protocol. If a dataset is small, poor quality, or loses too many segments after stringent GeoDiff filtering, users may skip this notebook and continue with the Q3/TMM route.
- Later notebooks detect GeoDiff output files automatically: if `GeoDiff_spatial_data.RDS` or `GeoDiff_normalised_spatial_data.RDS` exists, GeoDiff sections use the appropriate route; if not, GeoDiff-only sections are skipped with explicit messages and Q3/TMM sections continue. The filename uses `normalised` because it is the current pipeline filename.


1) Expected Inputs
------------------
The workflow is parameter-driven and expects stage-1 QC output as its main input.

Default expected structure:
- `<project_root>/Outputs/1_QC/results/QC_pass_spatial_data.RDS` (required input from stage 1)
- `<project_root>/Outputs/2_GeoDiff/`                            (created/used for stage outputs)

### Required input from stage 1
File expected (default):
- `Outputs/1_QC/results/QC_pass_spatial_data.RDS`

What the `.qmd` does with this input:
- Reads the QC-pass object,
- Fits Poisson background model (`fitPoisBG`) and runs diagnostics (`diagPoisBG`),
- Optionally attempts split-aware background fitting by `split_var` when group sizes are valid,
- Aggregates probes (`aggreprobe`), runs `BGScoreTest`, and applies `fitNBth` + `QuanRange`,
- Computes and applies segment retention filtering,
- Saves retained-segment object for normalization/DE stages.

### Optional GeoDiff output
Primary output when `save_rds: true`:
- `Outputs/2_GeoDiff/results/GeoDiff_spatial_data.RDS`

This file is the **GeoDiff-filtered count object**. In plain English, it is the count-like GeoMx object after GeoDiff has modeled background signal and kept the segments/features it considers suitable for the later stages. It is not the GeoDiff-normalized `normmat` matrix; that matrix is created later in `3_Normalisation.qmd` and saved in `GeoDiff_normalised_spatial_data.RDS`.

If this file is not produced because GeoDiff is intentionally skipped, Q3/TMM analysis can still proceed. GeoDiff-normalized plots and DE branches that require GeoDiff-filtered count data will be skipped until the relevant GeoDiff files are available.

### Metadata dependency note
This workflow uses metadata already embedded in the QC-pass object from earlier stages, including optional fields such as `disease_status` for diagnostics after segment filtering.


2) YAML Parameters and What They Do
-----------------------------------
Edit the `params:` block at the top of `2_GeoDiff_Processing.qmd`.

### Path and stage wiring parameters
- `project_root`
  - Absolute project root path.
  - If blank/`.` workflow attempts root auto-detection from working directory.
- `dir_outputs`
  - Root outputs folder (default: `Outputs`).
- `qc_stage`, `qc_results_dir`, `qc_pass_rds`
  - Together define where stage-1 QC-pass RDS is loaded from.
- `out_stage`, `out_results`
  - Define stage-2 output folder structure under `Outputs`.

### Save toggle
- `save_rds` (TRUE/FALSE)
  - Controls whether `GeoDiff_spatial_data.RDS` is written.

### GeoDiff behavior parameters
- `seed`
  - Random seed used before stochastic/model operations to improve reproducibility.
- `split_var`
  - Metadata column used for optional split-aware background fitting (commonly `slide_name`).
  - Split fit runs only when each split level has at least 2 segments.
- `bg_pvalue_threshold`
  - P-value threshold used when summarising probes above background signal.
- `rerun_when_high_dispersion` (default: true)
  - When true, the notebook can refit the Poisson background model if the first fit shows high dispersion. Set to false to always keep the first fit.
- `rerun_dispersion_threshold` (default: 2)
  - The background model is refitted only when the initial dispersion is above this value.
- `mask_outliers_before_rerun` (default: true)
  - When true, detected outlier values are set to missing (NA) before the optional refit.
- `fallback_group_var` (default: "segment")
  - Metadata column used to group the diagnostic reports when `split_var` is blank. It must name a column that exists in the object metadata, or the notebook stops with an error.

### QuanRange parameters
- `quanrange_probs`
  - Quantiles used by `QuanRange` (default `[0.75, 0.8, 0.9, 0.95]`).
- `quanrange_split`
  - Whether to run `QuanRange` in split mode.

### Segment filtering parameters
The parameter names keep the `roi_` prefix for backward compatibility with existing YAML headers, but they control **segment** retention.

- `roi_para_quantile`
  - Quantile cutoff for `para`-based segment retention score.
- `roi_signal_threshold`
  - Minimum adjusted signal required to retain a segment.
- `disease_col`
  - Optional metadata column used to report whether filtering removed entire disease groups.


3) What the Workflow Outputs
----------------------------
Outputs are written under:
`<project_root>/Outputs/<out_stage>/`

Default root:
`<project_root>/Outputs/2_GeoDiff/`

### Results output
Default path:
`<project_root>/Outputs/2_GeoDiff/results/`

Primary output (if `save_rds: true`):
- `GeoDiff_spatial_data.RDS`
  - Contains the GeoDiff-filtered count object (`spatial_data[, ROIs_high]`) used by later stages.
  - Preserves count-like expression values in `exprs`; it is the input used by Stage 3 to create GeoDiff-normalized `normmat`.

### Figures and diagnostics
- The QMD includes multiple model diagnostic plots in the rendered report (QQ plots, histogram/scatter diagnostics).
- These plots appear in the rendered HTML report; this stage does not save separate image files.

### Console/report diagnostics
During run, the workflow reports:
- input and output paths,
- whether split-fit was used or skipped,
- probe/background summaries,
- number of retained segments,
- optional disease-group before/after counts and warnings if a state is fully dropped.


4) How to Run the Workflow
--------------------------
Run from R using Quarto rendering.

Example command:

```r
quarto::quarto_render("2_GeoDiff_Processing.qmd")
```

or via CLI:

```bash
quarto render 2_GeoDiff_Processing.qmd
```

Before running:
1) Confirm stage 1 has completed and `QC_pass_spatial_data.RDS` exists at configured path.
2) Confirm `split_var` exists in object metadata if split fitting is intended.
3) Confirm segment filtering parameters (`roi_para_quantile`, `roi_signal_threshold`) are appropriate for your dataset.
4) Confirm `save_rds` is enabled if later stages require the persisted object.
5) Confirm `disease_col` exists if you want disease-state retention diagnostics.


5) Practical YAML Editing Guidance
----------------------------------
Use these practices when editing YAML parameters:

- Start with path/stage wiring (`qc_stage`, `qc_results_dir`, `qc_pass_rds`) before tuning model thresholds.
- Keep seed fixed while tuning thresholds so changes are attributable to parameter edits.
- Validate `split_var` carefully; split-mode fitting is skipped when groups are too small.
- Tune segment filters gradually:
  - Increase/decrease `roi_signal_threshold` in small steps,
  - Adjust `roi_para_quantile` to control strictness.
- Use `disease_col` diagnostics to avoid accidentally removing all segments from a clinically relevant subgroup.
- Keep `save_rds: true` for production runs so later notebooks can use stage-2 outputs.

Recommended review checklist for YAML:
- [ ] `project_root` and outputs root are correct
- [ ] stage-1 QC-pass input path is correct and file exists
- [ ] `split_var` column exists in metadata
- [ ] seed is fixed and intentional
- [ ] background / quantile / segment thresholds are intentional
- [ ] `save_rds` setting is intentional
- [ ] optional refit controls (`rerun_when_high_dispersion`, `rerun_dispersion_threshold`, `mask_outliers_before_rerun`) and `fallback_group_var` are intentional
- [ ] `disease_col` is valid (if used)


6) User Notes (for people reviewing this README + QMD)
------------------------------------------------------
What this workflow does for you as a user/reviewer:
- Converts QC-pass data into GeoDiff-filtered count data using reproducible, YAML-driven settings.
- Makes background/signal modelling steps explicit and reviewable in one pipeline stage.
- Provides checks for split fitting and subgroup retention.
- Produces a GeoDiff-filtered count object for normalization and differential expression analysis.

How to use this during review:
1) Review YAML first (stage-1 input wiring, split settings, thresholds, save toggles).
2) Confirm required stage-1 QC-pass object exists.
3) Run the QMD and inspect rendered diagnostics for model fit and filtering behavior.
4) Verify retained segment count and disease-group warnings/logs.
5) Confirm `GeoDiff_spatial_data.RDS` is produced at expected output path.

In short: this README + QMD pairing is intended to let users/reviewers independently execute and validate GeoDiff stage processing without needing a verbal walkthrough.
