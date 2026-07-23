# Example dataset parameters — all notebooks (GSE226829)

Single-page reference of the **exact `params:` values** used to produce the worked-example
renders. One section per notebook. The per-notebook files in this folder carry the same
content split out individually.

- **Dataset:** [GSE226829](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE226829) — pancreatic (PDAC) GeoMx WTA, 277 segments (AOIs), 6 sections (2 healthy, 4 tumour), 4 slides.
- **To reproduce:** put inputs under `Data/`, helpers under `src/`; set each notebook's `params:` to the values below; render in stage order 0 → 8 with `quarto render <notebook>.qmd`. `project_root: "."` resolves the root via `here::here()`.
- **Grouping in each section:** *Dataset-specific* (match your data — the example values ship in the notebooks) · *Analysis parameters* (keep to replicate) · *I/O & structural* (standard layout).

### Reproduction checkpoints

| Checkpoint | Value |
|---|---|
| Segments passing segment-level QC (stage 1) | **277 / 277** |
| Segments entering DE after gene-detection filtering | **253** |
| Targets after probe/LOQ filtering | **7,792** |
| DE contrasts (one-vs-rest on `cell_type` × `disease_status`) | **9** (`ADM_Tumor` auto-excluded) |
| DE method branches | `dream_GeoDiffCounts`, `limma_voom_TMM`, `limma_voom_GeoDiff`, `limma_trend_Q3`, `limma_trend_GeoDiff` |

### Contents

1. [Notebook 0: Standardise and Merge Metadata](#notebook-0-standardise-and-merge-metadata)
2. [Notebook 1: Quality Control](#notebook-1-quality-control)
3. [Notebook 2: GeoDiff Processing](#notebook-2-geodiff-processing)
4. [Notebook 3: Normalisation](#notebook-3-normalisation)
5. [Notebook 4: Exploratory Data Analysis](#notebook-4-exploratory-data-analysis)
6. [Notebook 5: Differential Expression Calculation](#notebook-5-differential-expression-calculation)
7. [Notebook 6: Differential Expression Visualisation](#notebook-6-differential-expression-visualisation)
8. [Notebook 7: Functional Enrichment](#notebook-7-functional-enrichment)
9. [Notebook 8: Spatial Deconvolution](#notebook-8-spatial-deconvolution)

---

## Notebook 0: Standardise and Merge Metadata

Cleans the LWS / segment-annotation file, optionally merges metadata, writes
`Complete_LWS_Metadata.xlsx`. GSE226829 has a single annotation file and no separate metadata,
so the merge degrades to LWS-only.

**Dataset-specific**

| Parameter | Value |
|---|---|
| `lws_input_file` | `GSE226829_PreQC_segments_annotation.xlsx` |
| `lws_input_files` | `value: []` |
| `metadata_input_file` | `""` |
| `lws_link_column` | `AUTO` |
| `metadata_link_column` | `AUTO` |
| `segment_column_name` | `segment` |

**Analysis / QA:** `check_segment_naming: true`, `warn_on_case_variants: true`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_src: src`,
`data_dir_name: Data`, `individual_readout_group_dir_name: Individual_Readout_Groups`,
`metadata_dir_name: Metadata`, `outputs_dir_name: Outputs`,
`clean_merge_output_dir_name: 0_Clean_And_Merge`, `cleaned_output_dir_name: Cleaned`,
`final_merged_filename: Complete_LWS_Metadata.xlsx`

---

## Notebook 1: Quality Control

Builds the `NanoStringGeoMxSet`, applies segment/probe QC and LOQ detection filtering.
**These thresholds match the original published GSE226829 analysis** — notably
`percentSaturation: 0` (retains all 277 segments and the Healthy groups).

**Analysis parameters — segment QC (`qc:`)**

| Parameter | Value | Notes |
|---|---|---|
| `minSegmentReads` | `1000` | |
| `percentTrimmed` | `80` | |
| `percentStitched` | `80` | |
| `percentAligned` | `75` | Published (default 80). |
| `percentSaturation` | `0` | Published — no saturation gate. |
| `minNegativeCount` | `1` | |
| `maxNTCCount` | `9000` | |
| `minNuclei` | `20` | |
| `nuclei_column` | `""` | No nuclei column → `minNuclei` skipped. |
| `minArea` | `1000` | Published (default 500; no-op for this dataset). |

**Analysis parameters — probe QC & detection**

| Parameter | Value | Notes |
|---|---|---|
| `minProbeRatio` | `0.1` | |
| `percentFailGrubbs` | `20` | |
| `removeLocalOutliers` | `true` | |
| `loq_cutoff_sd` | `2` | LOQ = mean + 2·SD of negatives. |
| `loq_min` | `2` | |
| `min_gene_detection_rate_per_segment` | `0.10` | → 253 segments into DE. |
| `min_gene_detection_rate_across_segments` | `0.10` | → 7,792 targets. |

`cutline_*` values (`cutline_saturation: 50`, `cutline_trimmed: 80`, `cutline_stitched: 50`,
`cutline_aligned: 40`, `cutline_area: 1000`) are **histogram reference lines only** — they do not filter.

**Dataset-specific:** `sample_id_column: library_name`, `key_annotation_column: disease_status`,
`key_annotation_min_segments_per_group: 3`, `pkc_zip_name: GSE226829_Hs_R_NGS_WTA_v1.0.pkc.gz`,
`pkc_file_name: ""`, `dcc_zip_name: GSE226829_RAW.zip`, `dcc_zip_names: value: []`,
`merged_lws_metadata_file: Complete_LWS_Metadata.xlsx`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_data: Data`,
`dir_outputs: Outputs`, `dir_src: src`, `dir_dcc: DCC_Files`, `dir_pkc: PKC_Files`,
`dir_rawdata: rawdata`, `dir_clean_merge_output: 0_Clean_And_Merge`, `out_stage: 1_QC`,
`out_results: results`, `out_tables: tables`, `out_figures: figures`,
`save: save_plots: true, save_rds: true`

---

## Notebook 2: GeoDiff Processing

Fits the GeoDiff Poisson-background model and writes the GeoDiff-filtered count object.
GeoDiff is an addition of this pipeline (not in the original analysis) — protocol defaults.

**Analysis parameters**

| Parameter | Value |
|---|---|
| `seed` | `123` |
| `split_var` | `slide_name` |
| `fallback_group_var` | `segment` |
| `bg_pvalue_threshold` | `1e-3` |
| `rerun_dispersion_threshold` | `2` |
| `rerun_when_high_dispersion` | `true` |
| `mask_outliers_before_rerun` | `true` |
| `quanrange_probs` | `[0.75, 0.8, 0.9, 0.95]` |
| `quanrange_split` | `false` |
| `roi_para_quantile` | `0.90` |
| `roi_signal_threshold` | `2` |

**Dataset-specific:** `disease_col: disease_status`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_src: src`,
`dir_outputs: Outputs`, `qc_stage: 1_QC`, `qc_results_dir: results`,
`qc_pass_rds: QC_pass_spatial_data.RDS`, `out_stage: 2_GeoDiff`, `out_results: results`,
`save_rds: true`, `save_plots: true`

---

## Notebook 3: Normalisation

Computes Q3, TMM, negative-probe, and GeoDiff `normmat` representations.
**Q3 normalisation (`q3_quantile: 0.75`) matches the original published analysis.**

**Analysis parameters**

| Parameter | Value | Notes |
|---|---|---|
| `q3_quantile` | `0.75` | Upper-quartile (Q3) — published. |
| `q3_toElt` | `q_norm` | Q3 assay name. |
| `neg_toElt` | `neg_norm` | Negative-probe assay name. |
| `harmonise_disease_labels` | `true` | Standardise disease-label spellings. |
| `load_existing_norm_objects` | `false` | Recompute from scratch. |

**Dataset-specific:** `ann_of_interest: segment`;
`meta_cols: slide: slide_name, segment: segment, annotation: segment, region: disease_status`;
`marker_genes: ["PTPRC", "KRT8"]`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `qc_stage: 1_QC`, `qc_results_dir: results`,
`qc_filtered_rds: filtered_spatial_data.RDS`, `geodiff_stage: 2_GeoDiff`,
`geodiff_results_dir: results`, `geodiff_rds: GeoDiff_spatial_data.RDS`, `out_stage: 3_Norm`,
`out_results: results`, `out_tables: tables`, `out_figures: figures`, `fig_subdir: Normalisation`,
`save_plots: true`, `save_rds: true`, `save_tables: true`

---

## Notebook 4: Exploratory Data Analysis

PCA, eigencorrelation diagnostics, and `variancePartition`. Diagnostic only — does not feed DE.

**Dataset-specific — metadata role columns**

| Parameter | Value |
|---|---|
| `col_slide` | `slide_name` |
| `col_patient` | `patient_id` |
| `col_disease_status` | `disease_status` |
| `col_cell_type` | `cell_type` |
| `col_segment` | `segment` |
| `metadata_columns` | `["slide_name", "segment", "location", "patient_id", "disease_status", "cell_type"]` |

**Analysis parameters — variance partition**

| Parameter | Value |
|---|---|
| `varpart_run` | `true` |
| `varpart_categorical` | `["segment", "slide_name", "region", "patient_id", "disease_status"]` |
| `varpart_continuous` | `value: []` |
| `varpart_max_genes` | `0` (all genes) |
| `varpart_seed` | `123` |

**Plot controls:** `pca_scree_components: 20`, `pca_main_ncol: 2`, `pca_main_pair: [1, 2]`,
`pca_secondary_pair: [3, 6]`, `pca_batch_pair: [1, 3]`, `pca_pairs_components: 6`,
`pca_pairs_point_size: 0.6`, `pca_pairs_axis_label_size: 7`, `pca_pairs_component_label_size: 11`,
`plot_prefix: ""`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `utility_functions_r: utilityFunctions.R`, `norm_stage: 3_Norm`,
`norm_results_dir: results`, `rds_normalised: normalised_spatial_data.RDS`,
`rds_geodiff_norm: GeoDiff_normalised_spatial_data.RDS`, `rds_tmm_norm: TMM_normalised_spatial_data.RDS`,
`out_stage: 4_EDA`, `out_results: results`, `out_tables: tables`, `out_figures: figures`,
`save_plots: true`, `save_rds: false`, `save_tables: false`

---

## Notebook 5: Differential Expression Calculation

Fits `limma-trend`, `limma-voom`, and `dream`. **The DE design matches the original published
analysis:** one-vs-rest on `Annotation` = `cell_type` × `disease_status`, random effect on
`grouping_id` = `patient_id` + `location`, low-power `ADM_Tumor` auto-excluded → 9 contrasts.
`dream` is the mixed-model equivalent of the paper's `mixedModelDE`.

**Analysis parameters**

| Parameter | Value | Notes |
|---|---|---|
| `contrast_factor` | `Annotation` | Group `<cell_type>_<disease_status>`. |
| `model_mode` | `one_vs_rest_mixed` | Each group vs mean of the rest. |
| `contrast_file` | `""` | Auto-generate contrasts. |
| `random_effect_var` | `grouping_id` | Random intercept. |
| `grouping_id_vars` | `["patient_id", "location"]` | = the paper's `tissue`. |
| `allow_random_slope` | `false` | Random intercept only. |
| `de_methods` | `["limma-trend", "limma-voom", "dream"]` | 5 result branches. |
| `model_covariates_continuous` | `value: []` | |
| `model_covariates_categorical` | `value: []` | |
| `adj_p_cutoff` | `0.05` | BH-adjusted P. |
| `logFC_cutoff` | `0.58` | ≈ 1.5-fold; labelling only. |
| `limma_trend_prior_count` | `1` | |
| `seed` | `123` | |
| `auto_exclude_low_power` | `true` | Drops `ADM_Tumor`. |
| `min_samples_per_group` | `2` | |
| `min_patients_per_group` | `""` | Not enforced. |

**Model-input assays:** `q3_norm_assay: q_norm`, `geodiff_norm_assay: normmat`

**Runtime / cache controls** (speed controls, not analysis parameters — the notebooks ship `false`, which always refits; set `true` only to reuse a cache across repeat runs):

| Parameter | Value | Notes |
|---|---|---|
| `use_dream_cache` | `false` | Shipped default: always refit. Set `true` to load a saved identical fit if present; the result is the same either way. |
| `use_limma_voom_cache` | `false` | Both limma-voom branches. |
| `use_limma_trend_cache` | `false` | Both limma-trend branches. |

**Dataset-specific:** `col_slide: slide_name`, `col_patient: patient_id`,
`col_disease_status: disease_status`, `col_cell_type: cell_type`, `col_segment: segment`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `dir_data: Data`, `geodiff_stage: 2_GeoDiff`, `geodiff_results_dir: results`,
`geodiff_rds: GeoDiff_spatial_data.RDS`, `norm_stage: 3_Norm`, `norm_results_dir: results`,
`norm_rds: normalised_spatial_data.RDS`, `norm_geodiff_rds: GeoDiff_normalised_spatial_data.RDS`,
`norm_tmm_rds: TMM_normalised_spatial_data.RDS`, `out_stage: 5_DE`, `out_results: results`,
`out_tables: tables`, `out_figures: figures`, `de_results_subdir: de`, `de_figures_subdir: de`

---

## Notebook 6: Differential Expression Visualisation

Reads stage-5 results + normalised expression; draws volcanoes, method-overlap/correlation
summaries, and selected-method heatmaps/gene panels. Does not refit models.

**Key parameters**

| Parameter | Value | Notes |
|---|---|---|
| `contrast_factor` | `Annotation` | Match stage 5. |
| `selected_de_method` | `limma_trend_GeoDiff` | Reported branch for deep-dive figures. |
| `expression_assay` | `normmat` | GeoDiff-normalised. |
| `adj_p_cutoff` | `0.05` | |
| `logFC_cutoff` | `0.58` | |
| `selected_heatmap_adj_p_cutoff` | `0.01` | |
| `top_genes_per_volcano` | `5` | |
| `core_heatmap_max_genes` | `25` | |
| `heatmap_max_genes` | `10` | |
| `top_n_genes` | `10` | |
| `selected_contrasts` | `value: []` | All contrasts. |
| `selected_segment_regex` | `""` | |
| `seed` | `123` | |

**Boxplots:** `boxplot_x_col: cell_type`, `boxplot_color_col: disease_status`,
`boxplot_facet_col: ""`, `facet_ncol: 4`, `boxplot_segment_tabs: auto`

**Dataset-specific:** `col_slide: slide_name`, `col_patient: patient_id`,
`col_disease_status: disease_status`, `col_cell_type: cell_type`, `col_segment: segment`,
`stain_regex_override: ""`

**Figure controls:** `volcano_point_size: 0.3`, `fig_width_standard: 10`, `fig_height_standard: 6`,
`fig_width_wide: 12`, `fig_height_wide: 7`, `fig_width_grid: 18`, `fig_height_grid: 10`,
`expression_heatmap_base_font_size: 9`, `expression_heatmap_label_font_size: 7`,
`correlation_heatmap_base_font_size: 10`, `correlation_heatmap_axis_font_size: 5`,
`correlation_heatmap_cell_font_size: 2.4`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `de_calc_stage: 5_DE`, `de_calc_results_dir: results`, `de_calc_results_subdir: de`,
`de_calc_tables: tables`, `norm_stage: 3_Norm`, `norm_results_dir: results`,
`norm_rds: normalised_spatial_data.RDS`, `norm_geodiff_rds: GeoDiff_normalised_spatial_data.RDS`,
`norm_tmm_rds: TMM_normalised_spatial_data.RDS`, `out_stage: 6_DE_Vis`, `out_results: results`,
`out_tables: tables`, `out_figures: figures`, `de_output_subdir: de`

---

## Notebook 7: Functional Enrichment

Ranks genes per method/contrast and runs GSEA against GO, Hallmark, and Reactome.
**Uses MSigDB Hallmark v2026.1 and Reactome v2026.1** (`Hs.symbols`), placed in `src/`.

**Analysis parameters**

| Parameter | Value | Notes |
|---|---|---|
| `selected_de_methods` | `["limma_trend_GeoDiff", "limma_trend_Q3"]` | Two methods → activates cross-method comparison. |
| `selected_contrasts` | `value: []` | All contrasts. |
| `run_go` | `true` | GO via `org.Hs.eg.db`. |
| `ranking_metric` | `signed_neg_log10_p` | `sign(logFC) × −log10(P.Value)`. |
| `go_ontology` | `ALL` | BP+CC+MF. |
| `gene_id_type` | `SYMBOL` | |
| `go_orgdb_package` | `org.Hs.eg.db` | |
| `gsea_pvalue_cutoff` | `0.05` | |
| `p_adjust_method` | `BH` | |
| `min_gene_set_size` | `8` | |
| `max_gene_set_size` | `500` | |
| `fgsea_eps` | `0` | Exact p-values. |
| `seed` | `123` | |

**Gene-set collections (`gmt_collections`)**

| Collection | `gmt_file` | `term_prefix_to_strip` | `enabled` |
|---|---|---|---|
| Hallmark | `h.all.v2026.1.Hs.symbols.gmt` | `HALLMARK_` | `true` |
| Reactome | `c2.cp.reactome.v2026.1.Hs.symbols.gmt` | `REACTOME_` | `true` |

Loaded sizes: Hallmark = 50 sets / 7,322 links; Reactome = 1,839 sets / 102,437 links.

**Figure controls:** `dotplot_show_category: 15`, `fig_width_standard: 11`, `fig_height_standard: 8`,
`fig_width_wide: 13`, `fig_height_wide: 8`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `dir_data: Data`, `de_calc_stage: 5_DE`, `de_calc_results_dir: results`,
`de_calc_results_subdir: de`, `out_stage: 7_Enrichment`, `out_results: results`, `out_tables: tables`,
`out_figures: figures`, `enrichment_output_subdir: enrichment`, `comparison_output_subdir: compare`

---

## Notebook 8: Spatial Deconvolution

Runs `SpatialDecon` against a cell-type reference. **Reference: `Pancreas_HCA`** (local `.RData` in
`Data/Spatial_Deconvolution_References/`) — the worked-example choice for this pancreatic dataset.

**Analysis parameters**

| Parameter | Value | Notes |
|---|---|---|
| `norm_object_file` | `normalised_spatial_data.RDS` | Q3-normalised object. |
| `norm_assay` | `q_norm` | |
| `raw_assay` | `exprs` | Raw counts for background. |
| `reference_source` | `local_file` | |
| `reference_matrix_name` | `Pancreas_HCA` | |
| `reference_file` | `Pancreas_HCA.RData` | |
| `reference_species` | `Human` | |
| `reference_age_group` | `Adult` | |
| `transpose_reference` | `false` | |
| `min_reference_gene_overlap` | `25` | |
| `stop_on_low_gene_overlap` | `true` | |
| `reference_heatmap_max_genes` | `500` | |
| `seed` | `123` | |

**Dataset-specific — annotation columns:**
`metadata_context_columns: ["segment", "cell_type", "disease_status", "patient_id", "slide_name"]`,
`heatmap_annotation_columns: ["segment", "cell_type", "disease_status", "slide_name"]`,
`heatmap_annotation_color_overrides: value: {}`, `show_heatmap_sample_labels: false`

**Reference-source fallbacks (unused this run):** `reference_cache_dir: Spatial_Deconvolution_References`,
`reference_cache_file: ""`, `overwrite_reference_cache: false`, `reference_download_timeout_sec: 600`,
`spatialdecon_builtin_reference: safeTME`

**Figure controls:** `fig_width_standard: 11`, `fig_height_standard: 8`, `fig_width_wide: 13`,
`fig_height_wide: 8`, `figure_dpi: 300`

**I/O & structural:** `project_root: "."`, `portable_path_limit: 200`, `dir_outputs: Outputs`,
`dir_src: src`, `dir_data: Data`, `norm_stage: 3_Norm`, `norm_results_dir: results`,
`out_stage: 8_Deconvolution`, `out_results: results`, `out_tables: tables`, `out_figures: figures`,
`decon_output_subdir: decon`
