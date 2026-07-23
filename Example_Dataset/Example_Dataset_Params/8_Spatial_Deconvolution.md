# Notebook 8 — Spatial deconvolution

Exact `params:` used for the **GSE226829** exemplar render. This stage runs `SpatialDecon`
against a cell-type reference to estimate cell-type composition per segment, and draws the
proportion / beta heatmaps.

> **Reference matrix:** `Pancreas_HCA` (Human Pancreas Cell Atlas), loaded from a local
> `.RData` file placed under `Data/Spatial_Deconvolution_References/`. This is the worked-example
> choice for the pancreatic dataset — pick a reference matched to your own tissue/species when
> adapting.

## Key analysis parameters

| Parameter | Value | Notes |
|---|---|---|
| `norm_object_file` | `normalised_spatial_data.RDS` | Q3-normalised object (follows the SpatialDecon GeoMx vignette). |
| `norm_assay` | `q_norm` | Normalised assay used for the fit. |
| `raw_assay` | `exprs` | Raw counts used for the background model. |
| `reference_source` | `local_file` | Load the reference from a local file (vs download/built-in). |
| `reference_matrix_name` | `Pancreas_HCA` | |
| `reference_file` | `Pancreas_HCA.RData` | In `Data/Spatial_Deconvolution_References/`. |
| `reference_species` | `Human` | |
| `reference_age_group` | `Adult` | |
| `transpose_reference` | `false` | |
| `min_reference_gene_overlap` | `25` | Minimum genes shared between data and reference. |
| `stop_on_low_gene_overlap` | `true` | Fail rather than fit on a poorly matched reference. |
| `reference_heatmap_max_genes` | `500` | Genes shown in the reference-profile heatmap. |
| `seed` | `123` | Reproducibility. |

## Dataset-specific — annotation columns

| Parameter | Value |
|---|---|
| `metadata_context_columns` | `["segment", "cell_type", "disease_status", "patient_id", "slide_name"]` |
| `heatmap_annotation_columns` | `["segment", "cell_type", "disease_status", "slide_name"]` |
| `heatmap_annotation_color_overrides` | `value: {}` (use the shared Okabe-Ito palette) |
| `show_heatmap_sample_labels` | `false` |

## Reference-source fallbacks (unused for this run)

| Parameter | Value | Notes |
|---|---|---|
| `reference_cache_dir` | `Spatial_Deconvolution_References` | Cache location for downloaded matrices. |
| `reference_cache_file` | `""` | Auto-named. |
| `overwrite_reference_cache` | `false` | |
| `reference_download_timeout_sec` | `600` | Only used when `reference_source: cell_profile_library`. |
| `spatialdecon_builtin_reference` | `safeTME` | Only used when `reference_source: spatialdecon_builtin`. |

## Figure controls

| Parameter | Value |
|---|---|
| `fig_width_standard` / `fig_height_standard` | `11` / `8` |
| `fig_width_wide` / `fig_height_wide` | `13` / `8` |
| `figure_dpi` | `300` |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `200` |
| `dir_outputs` / `dir_src` / `dir_data` | `Outputs` / `src` / `Data` |
| `norm_stage` / `norm_results_dir` | `3_Norm` / `results` |
| `out_stage` | `8_Deconvolution` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `decon_output_subdir` | `decon` |
