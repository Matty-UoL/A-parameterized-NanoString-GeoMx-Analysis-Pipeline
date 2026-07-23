README: 4_Exploratory_Data_Analysis.qmd
=======================================

Purpose
-------
This README is a practical user guide for the Quarto workflow:
`4_Exploratory_Data_Analysis.qmd`.

Path portability
----------------
This stage defaults to `project_root: "."` and performs a 200-character path-portability audit before creating outputs. Review the rendered audit when working in Dropbox, OneDrive, or another deeply nested location. Generated diagnostic filenames may be shortened with a deterministic hash; required stage-contract filenames are preserved exactly.
Terminology used in this document:
- This stage runs after normalization and focuses on exploratory diagnostics (not biological interpretation).

The workflow performs these core tasks:
1) Loads normalized objects from the previous stage,
2) Resolves metadata columns from YAML-specified names, allowing for common spacing and punctuation differences,
3) Runs method-consistent PCA + eigencorrelation + pair-plot panels,
4) Runs variance partition analysis to quantify how much of each gene's expression variance is explained by each study variable,
5) Saves EDA figures/reports for method comparison and review.

This document explains what to provide, how to configure YAML, what outputs to expect, and how users/reviewers should run and validate the step.


1) Expected Inputs
------------------
The workflow is parameter-driven and expects outputs from the normalization stage.

Default expected structure:
- `<project_root>/Outputs/3_Norm/results/normalised_spatial_data.RDS`      (required)
- `<project_root>/Outputs/3_Norm/results/GeoDiff_normalised_spatial_data.RDS` (optional)
- `<project_root>/Outputs/3_Norm/results/TMM_normalised_spatial_data.RDS`     (required)
- `<project_root>/src/utilityFunctions.R`                                     (required helper script)

### Required normalized objects
Files expected (defaults):
- `normalised_spatial_data.RDS`
- `TMM_normalised_spatial_data.RDS`
Optional if GeoDiff normalization was run:
- `GeoDiff_normalised_spatial_data.RDS`

What the `.qmd` does with these inputs:
- Loads Q3/negative and TMM-normalized objects, plus GeoDiff-normalized `normmat` when available,
- Runs PCA/eigencor/pairplot workflows for each available method,
- Produces side-by-side exploratory outputs for technical comparison.

If the GeoDiff-normalized `normmat` object is absent, GeoDiff PCA sections are skipped with an explicit message. Q3 and TMM EDA sections remain available.

### Required helper script
Expected path (default):
- `src/utilityFunctions.R`

What the `.qmd` does:
- Sources helper functions used in plotting/utilities during EDA.

### Metadata requirements
The EDA stage depends on metadata columns in `pData` for coloring/shaping/faceting plots.

- YAML parameter `metadata_columns` defines the key covariates resolved for the eigencorrelation / metadata-correlation diagnostics.
- The `col_*` role parameters (`col_disease_status`, `col_segment`, `col_cell_type`, `col_patient`, `col_slide`) name the columns used for the PCA / pairs-plot ROLES (primary grouping, segment, patient, slide/batch).
- The notebook resolves all of these names while allowing spaces, newlines, and punctuation differences. For each role it tries the `col_*` value first, then falls back to built-in canonical names (`disease_status`, `cell_type`, etc.), so datasets that already use the canonical headers need no changes.
- The rendered notebook reports which columns were resolved (a resolved-covariate table plus a per-method role summary), so you can confirm the requested columns were found before interpreting the PCA outputs.


2) YAML Parameters and What They Do
-----------------------------------
Edit the `params:` block at the top of `4_Exploratory_Data_Analysis.qmd`.

### Path and stage wiring parameters
- `project_root`
  - Absolute project root path.
  - If blank/`.` workflow attempts root auto-detection from working directory.
- `dir_outputs`, `dir_src`
  - Core output and project-level helper folders used to resolve all stage paths.
- `utility_functions_r`
  - Utility script filename under `src`.
- `norm_stage`, `norm_results_dir`
  - Define where normalization outputs are read from.
- `rds_normalised`, `rds_geodiff_norm`, `rds_tmm_norm`
  - Filenames for required normalized input objects.

### Output parameters
- `out_stage` (default: `4_EDA`)
  - Stage output root under `Outputs`.
- `out_results`, `out_tables`, `out_figures`
  - Output subfolders created for this stage.
- `plot_prefix`
  - Optional string prepended to saved figure filenames (useful for sensitivity runs/config variants).

### Save behavior parameters
- `save_plots` (TRUE/FALSE)
  - Controls whether plots are written to output figures directory.
- `save_rds` (TRUE/FALSE)
  - Reserved for optional object persistence behavior in this stage configuration.
- `save_tables` (TRUE/FALSE)
  - Reserved for optional table export behavior in this stage configuration.

### Metadata role-column parameters (`col_*`)
These name the `pData` columns used for the PCA / pairs-plot ROLES, so the notebook can adapt to datasets that do not use the canonical column names without any code edits. For each role the value you set is tried first, then the built-in canonical fallbacks are tried. They mirror the `col_*` parameters used in stages 5 and 6.
- `col_disease_status` (default: `disease_status`)
  - Primary study grouping / condition column used to colour the primary PCA and pairs plots. Canonical fallbacks: `disease_status`, `condition`.
- `col_segment` (default: `segment`)
  - Segment / region-of-interest type used for the segment pairs plot and (where supported) shape mapping. Canonical fallbacks: `segment`, `cell_type`, `annotation`.
- `col_cell_type` (default: `cell_type`)
  - Cell-type annotation; also tried as a secondary candidate for the segment role. Point this at the segment column when a dataset has no dedicated cell-type column.
- `col_patient` (default: `patient_id`)
  - Patient / subject identifier used for the patient-coloured PCA panel. Canonical fallbacks: `patient_id`, `sample_id_meta`.
- `col_slide` (default: `slide_name`)
  - Slide / batch identifier used for the plate/batch PCA panel. Canonical fallbacks: `plate_id`, `slide_name`, `slide`.

To adapt a new cohort, set only these values (for example `col_disease_status: "disease"`) — no code chunks need editing.

### Metadata and PCA panel parameters
- `metadata_columns`
  - List of metadata columns resolved for the eigencorrelation / metadata-correlation diagnostics. This feeds the covariate diagnostics; the plot grouping roles are set separately by the `col_*` parameters above.
- `pca_scree_components`
  - Number of principal components included in scree plotting context.
- `pca_main_ncol`
  - Layout columns for saved PCA multi-panel outputs.
- `pca_main_pair`
  - Two PCs used for the primary, patient, and segment PCA score panels.
  - Default: `[1, 2]`.
- `pca_secondary_pair`
  - Two PCs used for the additional PCA score panel after the main PC1/PC2 views.
  - Default: `[3, 6]`.
- `pca_batch_pair`
  - Two PCs used for the plate/batch-oriented PCA score panel.
  - Default: `[1, 3]`.
- `pca_pairs_components`
  - Number of sequential PCs included in PCA pairsplots, starting at PC1.
  - Default: `6`, which plots PCs 1-6.

The PCA pair settings must contain two distinct positive integers that exist in the fitted PCA object. If a configured PC does not exist for a dataset, the notebook stops with a clear configuration error rather than silently substituting another PC view.

### Variance partition parameters
These control the variance partition analysis, which fits a mixed model per gene and reports the percentage of expression variance each study variable explains (a violin plot, one violin per variable plus a `Residuals` violin for unexplained variance). It runs for the TMM, Q3, and GeoDiff branches in linked tabs, alongside the PCA views.
- `varpart_run` (TRUE/FALSE)
  - Whether to run the variance partition section. Set to `false` to skip it (for example to save time on a quick re-render).
- `varpart_categorical`
  - List of categorical study variables, modelled as random effects `(1|x)` (for example `segment`, `slide_name`, `region`, `patient_id`, `disease_status`).
- `varpart_continuous`
  - List of measured numeric variables, modelled as fixed numeric terms (for example `area` or a nuclei count). Leave as `[]` when there are none.
  - If you leave BOTH lists empty, the notebook auto-classifies the `metadata_columns` set (numeric columns become continuous, everything else categorical).
- `varpart_max_genes`
  - Gene cap for speed. `0` (or blank) uses all genes; a positive number (for example `2000`) uses only that many of the most variable genes. Mixed models are slow on many genes, so use this for a faster preview.
- `varpart_seed`
  - Reproducibility seed for the parallel mixed-model fits.
  - Default: `123`.

Columns that are constant, or unique to a single segment (which would make a random effect meaningless), are dropped automatically with a message, so the model only uses variables it can estimate.


3) What the Workflow Outputs
----------------------------
Outputs are written under:
`<project_root>/Outputs/<out_stage>/`

Default root:
`<project_root>/Outputs/4_EDA/`

### Figures (if `save_plots: true`)
Default path:
`<project_root>/Outputs/4_EDA/figures/`

The stage saves method-wise EDA files (with optional `plot_prefix`) including:
- PCA multi-panel summaries (e.g., `TMM_PCA.png`, `Q3_PCA.png`, `GeoDiff_PCA2.png`),
- eigencorrelation and pairplot outputs,
- variance partition violin plots (`TMM_varpart.png`, `Q3_varpart.png`, `GeoDiff_varpart.png`),
- additional method-comparison figures generated across the notebook.

### Results and tables directories
Default paths created:
- `<project_root>/Outputs/4_EDA/results/`
- `<project_root>/Outputs/4_EDA/tables/`

Note:
- Current implementation is primarily figure/report-output focused; results/tables directories are created for stage consistency and future extension.

### Rendered report outputs
The rendered notebook itself is a key output: it contains PCA, eigencor, and pairs visual diagnostics for each normalization method using consistent metadata-role mapping.


4) How to Run the Workflow
--------------------------
Run from R using Quarto rendering.

Example command:

```r
quarto::quarto_render("4_Exploratory_Data_Analysis.qmd")
```

or via CLI:

```bash
quarto render 4_Exploratory_Data_Analysis.qmd
```

Before running:
1) Confirm all required normalized RDS inputs exist in the configured normalization results folder.
2) Confirm `utilityFunctions.R` is available in the configured `src/` directory.
3) Confirm `metadata_columns` entries are appropriate for your dataset metadata.
4) Confirm the `col_*` role parameters point at your dataset's grouping/segment/patient/slide columns (or that your data uses the canonical names).
5) Confirm PCA pair settings are valid for the number of PCs available in your dataset.
6) Confirm `save_plots` and optional `plot_prefix` settings match run intent.


5) Practical YAML Editing Guidance
----------------------------------
Use these practices when editing YAML parameters:

- Validate path wiring first (`norm_stage`, `norm_results_dir`, RDS filenames) before tuning PCA settings.
- Keep `metadata_columns` accurate and minimal; unresolved or noisy covariates make EDA interpretation harder.
- Set the `col_*` role parameters to match your dataset's column names when they differ from the canonical defaults (for example `col_disease_status: "disease"`, or `col_cell_type: "segment"` when there is no dedicated cell-type column). Datasets that already use the canonical headers need no changes. Check the resolved-covariate table and per-method role summary in the rendered notebook to confirm each role mapped to the intended column.
- Use `plot_prefix` when comparing multiple sensitivity runs to avoid file overwrite confusion.
- Keep PCA layout settings (`pca_main_ncol`, scree components) stable during review rounds for easier visual comparison.
- Review the scree and eigencorrelation outputs before changing PCA component pairs:
  - `pca_main_pair` controls the repeated primary/patient/segment PCA score view,
  - `pca_secondary_pair` controls the additional PCA score view used to inspect later PCs,
  - `pca_batch_pair` controls the plate/batch-oriented PCA score view,
  - `pca_pairs_components` controls how many PCs are shown in pairsplots.
- Use PCA titles to identify the method and PC pair only. Color and shape mappings are explained by the plot legends, keeping panel titles compact.
- Leave `save_plots: true` for review-ready runs so figure files are preserved outside rendered HTML.

Recommended review checklist for YAML:
- [ ] `project_root` and input stage paths are correct
- [ ] all required normalized RDS files exist
- [ ] metadata columns are valid and intentional
- [ ] `col_*` role parameters resolve to the intended grouping/segment/patient/slide columns
- [ ] PCA panel pairs and pairsplot component count are valid and intentional
- [ ] save toggles and `plot_prefix` are intentional
- [ ] output subfolder naming is intentional


6) User Notes (for people reviewing this README + QMD)
------------------------------------------------------
What this workflow does for you as a user/reviewer:
- Provides a consistent, parameter-driven EDA comparison across TMM, Q3/negative, and GeoDiff-normalized `normmat` outputs.
- Makes metadata-role resolution explicit, reducing ambiguity in color/shape group assignments.
- Produces reusable visual diagnostics (PCA/eigencor/pairs) that support technical review and method selection.
- Quantifies, genome-wide, how much expression variance each study variable explains (variance partition), helping you decide which covariates to model or adjust for in the differential-expression stage.
- Creates review-ready files that can be compared across reruns using naming prefixes.

How to use this during review:
1) Review YAML first (input files, metadata columns, PCA settings, save behavior).
2) Verify normalized input objects and helper script availability.
3) Run the QMD and inspect method-wise PCA/eigencor/pair outputs.
4) Confirm saved figure files exist and use expected naming (including prefix when set).
5) Compare visual patterns across methods to identify technical differences before later modelling.

In short: this README + QMD pairing is intended to let users/reviewers independently execute and validate EDA-stage behavior without needing a verbal walkthrough.
