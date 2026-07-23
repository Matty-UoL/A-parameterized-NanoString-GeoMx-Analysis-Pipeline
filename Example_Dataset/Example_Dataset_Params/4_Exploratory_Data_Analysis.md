# Notebook 4 — Exploratory data analysis

Exact `params:` used for the **GSE226829** exemplar render. This stage produces PCA views,
metadata-covariate (eigencorrelation) diagnostics, and a `variancePartition` analysis on the
normalised objects. It is diagnostic only — nothing here feeds the DE calculation.

## Dataset-specific — metadata role columns

| Parameter | Value | Notes |
|---|---|---|
| `col_slide` | `slide_name` | Slide / batch identifier. |
| `col_patient` | `patient_id` | Patient / subject identifier. |
| `col_disease_status` | `disease_status` | Primary study grouping (condition). |
| `col_cell_type` | `cell_type` | Cell-type annotation. |
| `col_segment` | `segment` | Segment / AOI type. |
| `metadata_columns` | `["slide_name", "segment", "location", "patient_id", "disease_status", "cell_type"]` | Covariates inspected in eigencorrelation / correlation diagnostics. |

## Analysis parameters — variance partition

| Parameter | Value | Notes |
|---|---|---|
| `varpart_run` | `true` | Run the per-gene mixed-model variance partition. |
| `varpart_categorical` | `["segment", "slide_name", "region", "patient_id", "disease_status"]` | Categorical variables modelled as random effects `(1\|x)`. |
| `varpart_continuous` | `value: []` | No continuous covariates. |
| `varpart_max_genes` | `0` | Use all genes (no cap). |
| `varpart_seed` | `123` | Reproducibility for the parallel fits. |

## Plot / figure controls

| Parameter | Value |
|---|---|
| `pca_scree_components` | `20` |
| `pca_main_ncol` | `2` |
| `pca_main_pair` | `[1, 2]` |
| `pca_secondary_pair` | `[3, 6]` |
| `pca_batch_pair` | `[1, 3]` |
| `pca_pairs_components` | `6` |
| `pca_pairs_point_size` | `0.6` |
| `pca_pairs_axis_label_size` | `7` |
| `pca_pairs_component_label_size` | `11` |
| `plot_prefix` | `""` |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_outputs` / `dir_src` | `Outputs` / `src` |
| `utility_functions_r` | `utilityFunctions.R` |
| `norm_stage` / `norm_results_dir` | `3_Norm` / `results` |
| `rds_normalised` | `normalised_spatial_data.RDS` |
| `rds_geodiff_norm` | `GeoDiff_normalised_spatial_data.RDS` |
| `rds_tmm_norm` | `TMM_normalised_spatial_data.RDS` |
| `out_stage` | `4_EDA` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `save_plots` / `save_rds` / `save_tables` | `true` / `false` / `false` |
