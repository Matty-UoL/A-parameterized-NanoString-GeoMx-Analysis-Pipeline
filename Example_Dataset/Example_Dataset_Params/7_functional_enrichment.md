# Notebook 7 — Functional enrichment

Exact `params:` used for the **GSE226829** exemplar render. This stage ranks genes per
method/contrast and runs GSEA against GO, MSigDB Hallmark, and Reactome, then writes
enrichment tables, dotplots, and a cross-method pathway comparison.

> **Gene-set collection versions used:** MSigDB **Hallmark v2026.1** and **Reactome v2026.1**
> (both `Hs.symbols`). Place these GMT files in `src/` before rendering.

## Key analysis parameters

| Parameter | Value | Notes |
|---|---|---|
| `selected_de_methods` | `["limma_trend_GeoDiff", "limma_trend_Q3"]` | Two methods → activates the cross-method pathway comparison (GeoDiff route + Q3 comparator). |
| `selected_contrasts` | `value: []` | Blank → all contrasts per selected method. |
| `run_go` | `true` | GO GSEA via `org.Hs.eg.db` (no GMT file needed). |
| `ranking_metric` | `signed_neg_log10_p` | Rank = `sign(logFC) × −log10(P.Value)`. |
| `go_ontology` | `ALL` | BP + CC + MF. |
| `gene_id_type` | `SYMBOL` | |
| `go_orgdb_package` | `org.Hs.eg.db` | |
| `gsea_pvalue_cutoff` | `0.05` | |
| `p_adjust_method` | `BH` | |
| `min_gene_set_size` | `8` | |
| `max_gene_set_size` | `500` | |
| `fgsea_eps` | `0` | Exact p-values (no lower bound). |
| `seed` | `123` | Reproducibility (fgsea forced to `SerialParam`). |

## Gene-set collections (`gmt_collections`)

| Collection | `gmt_file` | `term_prefix_to_strip` | `enabled` |
|---|---|---|---|
| Hallmark | `h.all.v2026.1.Hs.symbols.gmt` | `HALLMARK_` | `true` |
| Reactome | `c2.cp.reactome.v2026.1.Hs.symbols.gmt` | `REACTOME_` | `true` |

Loaded sizes for this dataset: Hallmark = 50 gene sets / 7,322 gene links; Reactome = 1,839 gene sets / 102,437 gene links.

## Figure controls

| Parameter | Value |
|---|---|
| `dotplot_show_category` | `15` |
| `fig_width_standard` / `fig_height_standard` | `11` / `8` |
| `fig_width_wide` / `fig_height_wide` | `13` / `8` |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_outputs` / `dir_src` / `dir_data` | `Outputs` / `src` / `Data` |
| `de_calc_stage` / `de_calc_results_dir` / `de_calc_results_subdir` | `5_DE` / `results` / `de` |
| `out_stage` | `7_Enrichment` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `enrichment_output_subdir` / `comparison_output_subdir` | `enrichment` / `compare` |
