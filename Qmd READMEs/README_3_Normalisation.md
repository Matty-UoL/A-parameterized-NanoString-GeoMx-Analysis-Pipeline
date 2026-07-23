README: 3_Normalisation.qmd
===========================

Purpose
-------
This README is a practical user guide for the Quarto workflow:
`3_Normalisation.qmd`.

Path portability
----------------
This stage defaults to `project_root: "."` and performs a 200-character path-portability audit before creating outputs. Review the rendered audit when working in Dropbox, OneDrive, or another deeply nested location. Generated diagnostic filenames may be shortened with a deterministic hash; required stage-contract filenames are preserved exactly.
Terminology used in this document:
- This stage runs after QC and compares multiple normalization methods. GeoDiff outputs are optional.

The workflow performs these core tasks:
1) Loads the filtered object from stage 1 (QC) and detects optional GeoDiff output files,
2) Resolves metadata columns from YAML,
3) Computes/loads TMM, Q3, negative-probe, and, when available, GeoDiff-normalized `normmat`,
4) Generates comparative distribution and marker-gene plots,
5) Saves normalized objects and figure files for later analysis/reporting.

This document explains what to provide, how to configure YAML, what outputs to expect, and how users/reviewers should run and validate the step.


1) Expected Inputs
------------------
The workflow is parameter-driven and expects outputs from prior stages.

Default expected structure:
- `<project_root>/Outputs/1_QC/results/filtered_spatial_data.RDS`      (required from stage 1)
- `<project_root>/Outputs/2_GeoDiff/results/GeoDiff_spatial_data.RDS`  (optional from stage 2)
- `<project_root>/src/pathUtilities.R`                                  (required helper script)
- `<project_root>/src/utilityFunctions.R`                               (required helper script)

### Required input from stage 1 (QC)
File expected (default):
- `Outputs/1_QC/results/filtered_spatial_data.RDS`

What the `.qmd` does with this input:
- Loads the QC-filtered GeoMx object,
- Validates configured metadata columns exist,
- Optionally harmonises disease labels,
- Uses this object for raw, TMM, Q3, and negative-probe normalization views.

### Optional input from stage 2 (GeoDiff)
File expected (default):
- `Outputs/2_GeoDiff/results/GeoDiff_spatial_data.RDS`

What the `.qmd` does with this input:
- Loads the GeoDiff-filtered count object,
- Computes (or reloads) the GeoDiff-normalized `normmat` matrix,
- Uses GeoDiff-normalized data in method-comparison and marker-gene plots.

If this file is absent, the notebook reports the missing path and continues with Q3/TMM normalization. GeoDiff-normalized outputs and GeoDiff-only plots are skipped unless an existing `GeoDiff_normalised_spatial_data.RDS` object is available.

### Required script dependency
Folder expected (default):
- `src/`

What the `.qmd` does:
- Sources `pathUtilities.R` first for the path-length checks, then `utilityFunctions.R` for the shared plotting and processing helpers. The notebook stops with a clear message if either file is missing.


2) YAML Parameters and What They Do
-----------------------------------
Edit the `params:` block at the top of `3_Normalisation.qmd`.

Important Quarto structure note:
- `meta_cols` is a nested list and should remain under `value:`.

### Path and stage wiring parameters
- `project_root`
  - Absolute project root path.
  - If blank/`.` workflow attempts root auto-detection from working directory.
- `dir_outputs`, `dir_src`
  - Core folders for outputs and project-level helper scripts.
- `dir_src`
  - Source/helper folder under `project_root`; the default is `<project_root>/src`.
- `qc_stage`, `qc_results_dir`, `qc_filtered_rds`
  - Together define where the stage-1 filtered object is loaded from.
- `geodiff_stage`, `geodiff_results_dir`, `geodiff_rds`
  - Together define where the stage-2 GeoDiff-filtered count object is loaded from.

### Output structure parameters
- `out_stage` (default: `3_Norm`)
  - Stage output root under `Outputs`.
- `out_results`, `out_tables`, `out_figures`
  - Subfolders under `Outputs/<out_stage>/`.
- `fig_subdir` (default: `Normalisation`)
  - Figure subfolder under `out_figures` used for saved plot files.

### Save and reuse parameters
- `save_plots` (TRUE/FALSE)
  - Controls whether normalization comparison figures are written to disk.
- `save_rds` (TRUE/FALSE)
  - Controls whether normalized RDS objects are persisted.
- `save_tables` (TRUE/FALSE)
  - Reserved for table persistence behavior in this stage configuration.
- `load_existing_norm_objects` (TRUE/FALSE)
  - When TRUE, reuses previously saved normalized objects if present to skip recomputation.

### Normalization method parameters
- `q3_quantile`
  - Quantile used for upper-quantile normalization (Q3 default is 0.75).
- `q3_toElt`
  - Assay element name where Q3-normalized values are stored (default: `q_norm`).
- `neg_toElt`
  - Assay element name where negative-probe normalized values are stored (default: `neg_norm`).

### Metadata and plotting parameters
- `ann_of_interest`
  - Annotation column used in Q3-vs-negative summary plots.
- `meta_cols.value`
  - Mapping for metadata columns used throughout plots:
    - `slide`, `segment`, `annotation`, `region`.
  - For normalization distribution plots:
    - `slide` drives boxplot fill and density-curve color,
    - `region` drives boxplot facets and density-curve linetype,
    - `segment` drives density facets,
    - `annotation` drives sample-axis labels.
  - `segment` and `annotation` are required for the current plotting workflow.
  - `slide` and `region` are optional context fields for distribution plots. If either is absent, the notebook reports this in the normalization distribution plot grouping summary and renders the plots with an explicit fallback group.
- `marker_genes`
  - Marker gene list used for marker-expression comparison panels.
- `harmonise_disease_labels` (TRUE/FALSE)
  - Harmonises disease labels (e.g., tumour/tumor/healthy/control variants) before region-based plotting.


3) What the Workflow Outputs
----------------------------
Outputs are written under:
`<project_root>/Outputs/<out_stage>/`

Default root:
`<project_root>/Outputs/3_Norm/`

### Results (RDS objects; if `save_rds: true`)
Default path:
`<project_root>/Outputs/3_Norm/results/`

Common saved objects:
- `TMM_normalised_spatial_data.RDS` (full metadata-rich TMM object used by later stages)
- `TMM_normalised_spatial_minimal_Counts_data.RDS` (minimal counts-only TMM object for audit/debug checks)
- `normalised_spatial_data.RDS` (contains Q3 and negative-probe assays)
- `GeoDiff_normalised_spatial_data.RDS` (contains GeoDiff-normalized `normmat`)

### Figures (if `save_plots: true`)
Default path:
`<project_root>/Outputs/3_Norm/figures/Normalisation/`

Examples of saved figures:
- `q3vsneg.png`
- `rawDataBoxplots.png`, `rawDataDensity.png`
- `TMMNormalisedPlot.png`, `TMMNormalisedDensity.png`
- `Q3NormalisedPlot.png`, `q3NormalisedDensity.png`
- `negProbeNormalisedPlot.png`, `negProbeNormalisedDensity.png`
- `geoDiffNormalisedPlot.png`, `geoDiffNormalisedDensity.png`
- `antibodyValues_TMM.png`, `antibodyValues_Q3.png`, `antibodyValues_negProbe.png`, `antibodyValues_GeoDiff.png`

### Tables
Default path created:
`<project_root>/Outputs/3_Norm/tables/`

Note:
- This stage creates the tables directory and can be extended for explicit table exports; current implementation is primarily figure and RDS-output oriented.

### Rendered report outputs
In addition to saved files, the rendered QMD provides side-by-side visual comparison panels for raw/TMM/Q3/negative/GeoDiff-normalized data and marker-gene inspection.


4) How to Run the Workflow
--------------------------
Run from R using Quarto rendering.

Example command:

```r
quarto::quarto_render("3_Normalisation.qmd")
```

or via CLI:

```bash
quarto render 3_Normalisation.qmd
```

Before running:
1) Confirm stage-1 and stage-2 RDS inputs exist at configured paths.
2) Confirm `meta_cols.value` mappings match columns present in `pData(target_spatial_data)`.
3) Confirm `marker_genes` are available in feature data (or update list to panel-relevant markers).
4) Decide if you want to recompute (`load_existing_norm_objects: false`) or reuse existing objects (`true`).
5) Confirm `save_plots` / `save_rds` toggles are set for your run purpose.


5) Practical YAML Editing Guidance
----------------------------------
Use these practices when editing YAML parameters:

- Validate path wiring first (stage inputs and output folders) before changing method settings.
- Keep `meta_cols.value` aligned with actual metadata names; this prevents plotting errors in later stages.
- Review the normalization distribution plot grouping summary after rendering:
  - it shows which metadata columns are used for boxplot fill/facets and density color/linetype/facets,
  - missing slide or disease-status metadata is handled with a visible fallback group rather than a plotting crash,
  - legends and captions state the active grouping variables so saved figures remain interpretable outside the rendered notebook.
- If metadata labels are inconsistent, keep `harmonise_disease_labels: true` to avoid split categories in plots and summaries.
- Tune normalization settings carefully:
  - `q3_quantile` affects Q3 scaling behavior,
  - `q3_toElt` and `neg_toElt` should remain stable unless you intentionally change assay names.
- For iterative runs, set `load_existing_norm_objects: true` to speed rerenders once baseline outputs are produced.
- Keep `save_rds: true` for production workflows so DE/EDA stages can use persisted objects.

Recommended review checklist for YAML:
- [ ] `project_root` and stage input paths are correct
- [ ] stage-1 and stage-2 input RDS files exist
- [ ] `meta_cols.value` fields exist in metadata
- [ ] `marker_genes` are intentional and valid for panel
- [ ] recompute/reuse mode (`load_existing_norm_objects`) is intentional
- [ ] save toggles (`save_plots`, `save_rds`, `save_tables`) are intentional
- [ ] output subfolder naming is intentional


6) User Notes (for people reviewing this README + QMD)
------------------------------------------------------
What this workflow does for you as a user/reviewer:
- Standardizes comparison of multiple normalization approaches in one reproducible stage.
- Makes metadata mappings explicit so plotting/grouping behavior is easy to review.
- Produces both persisted normalized objects and visual diagnostics to support method selection.
- Provides the normalized objects needed for exploratory and differential analyses.

How to use this during review:
1) Review YAML first (input paths, metadata mappings, normalization settings, save/reuse toggles).
2) Verify required earlier-stage RDS objects and the `src/pathUtilities.R` and `src/utilityFunctions.R` helper files exist.
3) Run the QMD and inspect rendered comparison panels across methods.
4) Confirm expected RDS outputs and figure files were produced (if save toggles enabled).
5) Check marker-gene plots for expected segment-level signal patterns and consistency across methods.

In short: this README + QMD pairing is intended to let users/reviewers independently execute and validate normalization-stage behavior without needing a verbal walkthrough.
