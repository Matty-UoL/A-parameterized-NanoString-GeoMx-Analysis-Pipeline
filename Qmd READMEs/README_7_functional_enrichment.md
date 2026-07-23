# 7 Functional Enrichment

`7_functional_enrichment.qmd` runs pathway enrichment for selected DE methods and contrasts, using ranked gene lists from the result objects written by `5_Differential_Expression_Calculation.qmd`.

## When to Run

Run this notebook after `5_Differential_Expression_Calculation.qmd` has completed and after `6_Differential_Expression_Visualisation.qmd` review has identified which DE method(s) and contrasts are suitable for pathway interpretation.

## Path Portability

Stage 7 writes to `Outputs/7_Enrichment/`, with enrichment files under compact `results/enrichment/` and `figures/enrichment/` folders. It reads the compact Stage 5 `results/de/` directory first and falls back to legacy `results/differential_expression/` when needed.
Defaults remain GeoDiff-oriented. If GeoDiff was intentionally skipped, choose available non-GeoDiff method outputs from `5_Differential_Expression_Calculation.qmd` before rendering enrichment.

Method-name terminology follows Stage 5: `limma_voom_GeoDiff` is fitted from GeoDiff-filtered count data, while `limma_trend_GeoDiff` is fitted from GeoDiff-normalized `normmat`.

## Key YAML Decisions

- `de_calc_stage`: defaults to `5_DE`.
- `selected_de_methods`: methods to include in enrichment.
- `selected_contrasts`: leave blank to use all available contrasts, or provide exact contrast names.
- `run_go`: choose whether to run GO enrichment.
- `gmt_collections`: enable or disable GMT-based collections and define Hallmark, Reactome, or other GMT resources.
- `dotplot_show_category`: limits how many pathways are shown in each dotplot.

When GeoDiff outputs are absent:
- Use `selected_de_methods: ["limma_trend_Q3"]`, `["limma_voom_TMM"]`, or both when those outputs exist from `5_Differential_Expression_Calculation.qmd`.
- If a selected method that requires GeoDiff-filtered count data or GeoDiff-normalized `normmat` is absent, the notebook stops with an explicit message and does not silently switch methods.

## Outputs to Check

- Ranked-gene audit tables.
- GO and GMT enrichment result tables.
- Enrichment dotplots with readable axis labels.
- Conditional pathway-level method-comparison figures.
- `Outputs/7_Enrichment/tables/stage7_output_list.csv`.

## Decision Before Continuing

Use pathway results only when the underlying DE model evidence is acceptable. If enrichment changes across methods, report that clearly and prioritize pathways supported by more than one selected method.
