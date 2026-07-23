# Notebook 5 — Differential expression calculation

Exact `params:` used for the **GSE226829** exemplar render. This stage fits the DE models
(`limma-trend`, `limma-voom`, `dream`) and writes one result object per method/normalisation
branch, each holding the per-contrast statistics.

> **The DE design matches the original published GSE226829 analysis.** Contrasts are
> **one-vs-rest** on `Annotation` = `cell_type` × `disease_status` (the paper's `cell_type_DS`),
> with a random effect on `grouping_id` = `patient_id` + `location` (the paper's `tissue`).
> Low-power groups are auto-excluded, dropping `ADM_Tumor` exactly as the paper did by hand,
> leaving **9 contrasts**. The `dream` method is the mixed-model (LMM) equivalent of the paper's
> `mixedModelDE`; the four `limma` branches add this pipeline's method comparison.

## Key analysis parameters

| Parameter | Value | Notes |
|---|---|---|
| `contrast_factor` | `Annotation` | Generated group `<cell_type>_<disease_status>`, e.g. `Acinar_Healthy`. |
| `model_mode` | `one_vs_rest_mixed` | Auto-generate one-vs-rest contrasts (each group vs the mean of the rest). |
| `contrast_file` | `""` | Blank → contrasts auto-generated from the observed groups. |
| `random_effect_var` | `grouping_id` | Random intercept per `grouping_id`. |
| `grouping_id_vars` | `["patient_id", "location"]` | `grouping_id = paste(patient_id, location, sep="_")` = the paper's `tissue`. |
| `allow_random_slope` | `false` | Random intercept only (no random slope). |
| `de_methods` | `["limma-trend", "limma-voom", "dream"]` | Produces 5 result objects (see below). |
| `model_covariates_continuous` | `value: []` | No continuous adjustment covariates. |
| `model_covariates_categorical` | `value: []` | No categorical adjustment covariates. |
| `adj_p_cutoff` | `0.05` | Significance threshold (BH-adjusted P). |
| `logFC_cutoff` | `0.58` | ≈ 1.5-fold; used for DEG counts/labelling, not for fitting. |
| `limma_trend_prior_count` | `1` | Prior count for the limma-trend log-CPM. |
| `seed` | `123` | Reproducibility. |

Method × normalisation branches written: `dream_GeoDiffCounts`, `limma_voom_TMM`,
`limma_voom_GeoDiff`, `limma_trend_Q3`, `limma_trend_GeoDiff`.

### Low-power exclusion

| Parameter | Value | Notes |
|---|---|---|
| `auto_exclude_low_power` | `true` | Drop groups below the minimum-power thresholds → excludes `ADM_Tumor`. |
| `min_samples_per_group` | `2` | Minimum segments per group. |
| `min_patients_per_group` | `""` | Not enforced (blank). |

## Model-input assays

| Parameter | Value | Notes |
|---|---|---|
| `q3_norm_assay` | `q_norm` | Q3 assay (limma-trend-Q3 branch). |
| `geodiff_norm_assay` | `normmat` | GeoDiff-normalised assay (GeoDiff branches). |

## Runtime / cache controls

Set to `true` for the exemplar run:

| Parameter | Value | Notes |
|---|---|---|
| `use_dream_cache` | `true` | Load a previously saved identical `dream` fit when present; on a fresh clone (no cache) it refits and saves. |
| `use_limma_voom_cache` | `true` | Same, for both limma-voom branches. |
| `use_limma_trend_cache` | `true` | Same, for both limma-trend branches. |

> These are runtime speed controls, not analysis parameters. Cached and refit results are
> identical (the cache stores a prior fit): a **fresh clone with no cache refits from scratch**,
> so results reproduce either way, and later re-renders reuse the saved fits for speed. A cache
> load is accepted only when the stored contrast names match the current run, otherwise the
> model is refit.

## Dataset-specific — metadata columns

| Parameter | Value |
|---|---|
| `col_slide` | `slide_name` |
| `col_patient` | `patient_id` |
| `col_disease_status` | `disease_status` |
| `col_cell_type` | `cell_type` |
| `col_segment` | `segment` |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_outputs` / `dir_src` / `dir_data` | `Outputs` / `src` / `Data` |
| `geodiff_stage` / `geodiff_results_dir` / `geodiff_rds` | `2_GeoDiff` / `results` / `GeoDiff_spatial_data.RDS` |
| `norm_stage` / `norm_results_dir` | `3_Norm` / `results` |
| `norm_rds` / `norm_geodiff_rds` / `norm_tmm_rds` | `normalised_spatial_data.RDS` / `GeoDiff_normalised_spatial_data.RDS` / `TMM_normalised_spatial_data.RDS` |
| `out_stage` | `5_DE` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `de_results_subdir` / `de_figures_subdir` | `de` / `de` |
