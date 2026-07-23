# Notebook 3 — Normalisation

Exact `params:` used for the **GSE226829** exemplar render. This stage computes the
normalised expression representations (Q3, TMM, negative-probe, and GeoDiff `normmat`)
consumed by stages 4–8.

> **Q3 normalisation matches the original published GSE226829 analysis** (`q3_quantile: 0.75`,
> i.e. upper-quartile / Q3, stored as assay `q_norm`).

## Key analysis parameters

| Parameter | Value | Notes |
|---|---|---|
| `q3_quantile` | `0.75` | Upper-quartile (Q3) normalisation — matches the published analysis. |
| `q3_toElt` | `q_norm` | Assay name for Q3-normalised values (read by stages 5/6/8). |
| `neg_toElt` | `neg_norm` | Assay name for negative-probe normalisation. |
| `harmonise_disease_labels` | `true` | Standardise disease-status label spellings/case before downstream use. |
| `load_existing_norm_objects` | `false` | Recompute normalisation from scratch (reproducibility-first). |

## Dataset-specific

| Parameter | Value | Notes |
|---|---|---|
| `ann_of_interest` | `segment` | Annotation used in normalisation comparison plots. |
| `meta_cols` | `slide: slide_name`, `segment: segment`, `annotation: segment`, `region: disease_status` | Metadata role mapping for plots. |
| `marker_genes` | `["PTPRC", "KRT8"]` | Marker panel shown in the normalisation marker plots (immune / epithelial). |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_outputs` / `dir_src` | `Outputs` / `src` |
| `qc_stage` / `qc_results_dir` / `qc_filtered_rds` | `1_QC` / `results` / `filtered_spatial_data.RDS` |
| `geodiff_stage` / `geodiff_results_dir` / `geodiff_rds` | `2_GeoDiff` / `results` / `GeoDiff_spatial_data.RDS` |
| `out_stage` | `3_Norm` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `fig_subdir` | `Normalisation` |
| `save_plots` / `save_rds` / `save_tables` | `true` / `true` / `true` |
