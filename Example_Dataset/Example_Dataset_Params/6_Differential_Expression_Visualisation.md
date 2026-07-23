# Notebook 6 — Differential expression visualisation

Exact `params:` used for the **GSE226829** exemplar render. This stage reads the stage-5 DE
result objects and the normalised expression, and draws volcanoes, method-overlap/correlation
summaries, and selected-method heatmaps and gene panels. It does **not** refit DE models.

## Key parameters

| Parameter | Value | Notes |
|---|---|---|
| `contrast_factor` | `Annotation` | Must match stage 5 to reconstruct contrast groups. |
| `selected_de_method` | `limma_trend_GeoDiff` | Method used for the deep-dive figures (the reported branch). |
| `expression_assay` | `normmat` | GeoDiff-normalised assay used for heatmaps/gene panels. |
| `adj_p_cutoff` | `0.05` | Significance threshold for comparison summaries. |
| `logFC_cutoff` | `0.58` | ≈ 1.5-fold. |
| `selected_heatmap_adj_p_cutoff` | `0.01` | Stricter cutoff for the focused selected-contrast heatmap. |
| `top_genes_per_volcano` | `5` | Labelled genes per volcano. |
| `core_heatmap_max_genes` | `25` | Genes in the broad method-family heatmaps. |
| `heatmap_max_genes` | `10` | Genes per focused selected-contrast heatmap. |
| `top_n_genes` | `10` | Top genes drawn per selected contrast. |
| `selected_contrasts` | `value: []` | Blank → all contrasts in the selected method. |
| `selected_segment_regex` | `""` | No segment restriction. |
| `seed` | `123` | Reproducibility. |

## Boxplot grouping

| Parameter | Value | Notes |
|---|---|---|
| `boxplot_x_col` | `cell_type` | x-axis = the cell-type groups the one-vs-rest contrasts compare. |
| `boxplot_color_col` | `disease_status` | Points coloured by Tumour/Healthy. |
| `boxplot_facet_col` | `""` | No extra facet. |
| `facet_ncol` | `4` | |
| `boxplot_segment_tabs` | `auto` | Show per-segment tabs only when segment is distinct from the grouping axis. |

## Dataset-specific — metadata columns

| Parameter | Value |
|---|---|
| `col_slide` | `slide_name` |
| `col_patient` | `patient_id` |
| `col_disease_status` | `disease_status` |
| `col_cell_type` | `cell_type` |
| `col_segment` | `segment` |
| `stain_regex_override` | `""` |

## Figure controls

| Parameter | Value |
|---|---|
| `volcano_point_size` | `0.3` |
| `fig_width_standard` / `fig_height_standard` | `10` / `6` |
| `fig_width_wide` / `fig_height_wide` | `12` / `7` |
| `fig_width_grid` / `fig_height_grid` | `18` / `10` |
| `expression_heatmap_base_font_size` | `9` |
| `expression_heatmap_label_font_size` | `7` |
| `correlation_heatmap_base_font_size` | `10` |
| `correlation_heatmap_axis_font_size` | `5` |
| `correlation_heatmap_cell_font_size` | `2.4` |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_outputs` / `dir_src` | `Outputs` / `src` |
| `de_calc_stage` / `de_calc_results_dir` / `de_calc_results_subdir` / `de_calc_tables` | `5_DE` / `results` / `de` / `tables` |
| `norm_stage` / `norm_results_dir` | `3_Norm` / `results` |
| `norm_rds` / `norm_geodiff_rds` / `norm_tmm_rds` | `normalised_spatial_data.RDS` / `GeoDiff_normalised_spatial_data.RDS` / `TMM_normalised_spatial_data.RDS` |
| `out_stage` | `6_DE_Vis` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `de_output_subdir` | `de` |
