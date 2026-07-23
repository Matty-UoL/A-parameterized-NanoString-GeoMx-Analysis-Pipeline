# 6 Differential Expression Visualisation

`6_Differential_Expression_Visualisation.qmd` reads the differential expression result objects written by `5_Differential_Expression_Calculation.qmd` and the normalized expression objects from `3_Normalisation.qmd`, then produces method-level visual summaries, cross-method comparison tables, and selected-method gene-level checks.

## When to Run

Run this notebook after `5_Differential_Expression_Calculation.qmd` has completed and result objects are available under `Outputs/5_DE/results/de/` or the supported legacy `results/differential_expression/` folder.

## Path Portability

Stage 6 writes to `Outputs/6_DE_Vis/` and uses compact `figures/de/top/all` and `figures/de/top/segment` folders. It reads `Outputs/5_DE/results/de/` first and automatically falls back to the legacy `results/differential_expression/` directory. Long generated plot names are shortened deterministically instead of aborting the render.
This notebook does not refit differential expression models. It visualizes and audits the existing outputs from `5_Differential_Expression_Calculation.qmd` so the user can choose which method, contrast set, and segment filter should be carried forward to pathway enrichment.

Defaults remain GeoDiff-oriented. If GeoDiff was intentionally skipped, select available non-GeoDiff methods from `5_Differential_Expression_Calculation.qmd` before rendering detailed selected-method outputs.

Method-name terminology:
- `limma_voom_GeoDiff` is the Stage 5 voom branch fitted from GeoDiff-filtered count data.
- `limma_trend_GeoDiff` is the Stage 5 limma-trend branch fitted from GeoDiff-normalized `normmat`.

## Key YAML Decisions

- `de_calc_stage`: defaults to `5_DE`; this must match the output folder written by `5_Differential_Expression_Calculation.qmd`.
- `norm_stage`: defaults to `3_Norm`; normalized expression objects are used for heatmap and gene-level plots.
- `out_stage`: defaults to `6_DE_Vis`.
- `adj_p_cutoff` and `logFC_cutoff`: define the significance thresholds used in comparison summaries.
- `top_genes_per_volcano`: number of genes labelled on each volcano plot. Volcano plots use the raw `logFC` range from each result table.
- `core_heatmap_max_genes`: maximum number of genes shown in the per-method comparison heatmaps (default 25).
- `heatmap_max_genes`: maximum number of genes shown in the selected-method focused heatmaps (default 10).
- `selected_de_method`: choose the `5_Differential_Expression_Calculation.qmd` method output for detailed inspection. The default is `limma_trend_GeoDiff`.
- `selected_contrasts`: leave blank to inspect all contrasts for the selected method, or provide exact contrast names.
- `selected_segment_regex`: optionally restrict focused heatmaps and top-gene segment tabs to matching segment labels.
- `selected_heatmap_adj_p_cutoff` and `top_n_genes`: control selected-method heatmap and top-gene boxplot panels. The default top-gene panel shows the top 10 DE genes per selected contrast.
- `col_slide`, `col_patient`, `col_disease_status`, `col_cell_type`, and `col_segment`: map dataset metadata columns used for annotations and grouping.
- `boxplot_x_col`, `boxplot_color_col`, `boxplot_facet_col`, and `facet_ncol`: define selected-gene boxplot aesthetics. When Stage 5 contrast metadata resolves, the plotted samples are limited to the two groups in the contrast, but the x-axis and point colours still use `boxplot_x_col` and `boxplot_color_col` (by default, disease status). When contrast metadata cannot be resolved, all samples are shown using the same x-axis and colour columns.
- `boxplot_segment_tabs`: controls the per-segment tab strip in the top-gene boxplot panels. With the default `"auto"`, each contrast shows an "All matched samples" panel and adds one tab per segment only when the segment column is genuinely distinct from the contrast/grouping axis; the per-segment tabs are suppressed automatically when segment is already built into your contrasts, when there is no separate segment column, or when the segment column collapses to a single level within the contrast. Use `"always"` to always show the per-segment tabs (the previous behaviour) or `"never"` to only ever show the "All matched samples" panel. This means your dataset does not need separate segment and cell-type columns for the boxplots to display sensibly.

When GeoDiff outputs are absent:
- Available non-GeoDiff choices usually include `limma_trend_Q3` and `limma_voom_TMM`, if those methods were run in `5_Differential_Expression_Calculation.qmd`.
- Update `selected_de_method` away from the GeoDiff default before relying on selected-method heatmaps or top-gene boxplots.
- Review the method availability and selected-method status tables before continuing.

## Outputs to Check

- Method availability and contrast inventory tables.
- DE signal summaries using the configured adjusted P-value and log fold-change thresholds.
- Per-method volcano plots, DE heatmaps, and DE-gene count figures.
- Full, hierarchically clustered fold-change and untransformed adjusted P-value correlation heatmaps across method/contrast outputs.
- Conserved-gene CSV and RDS summaries for contrasts shared across every active method.
- DE gene overlap outputs, including Venn or UpSet summaries where enough methods are available. Venn diagrams include set outlines to make overlap regions easier to audit.
- Selected-method contrast inventory, expression-object summary, heatmap audit, and top-gene boxplot audit summary.
- Missing-gene audit tables for selected top-gene boxplots.
- `Outputs/6_DE_Vis/tables/phase6_output_list.csv`.

## Decision Before Continuing

Use the method inventories, visual summaries, overlap evidence, selected-method heatmaps, and gene-level panels to choose the DE method and contrasts to carry into `7_functional_enrichment.qmd`.

Record the selected method, selected contrasts, segment filter, thresholds, and any model-specific caveats in the analysis notes before pathway enrichment. If results differ meaningfully across supported methods, report that uncertainty rather than treating a single method as automatically definitive.
