# Example dataset parameters (GSE226829)

This folder records the **exact `params:` values** used to produce the worked-example
renders shipped with this protocol, so a reviewer can reproduce the analysis on their
own machine. Each file documents one notebook's YAML front matter.

The published notebooks ship with dataset-specific values (input filenames, metadata
column names) cleared for reuse. Use the files here to restore the values that produced
the example HTML renders.

## Dataset

- **GEO accession:** [GSE226829](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE226829) — pancreatic (PDAC) GeoMx Whole Transcriptome Atlas, 277 segments (AOIs) across 6 tissue sections (2 healthy, 4 tumour) on 4 slides.
- The QC thresholds and DE contrasts were chosen to match the **original published analysis** of this dataset (see notebooks 1 and 5).

## How to reproduce

1. Place the pipeline notebooks and `render_full_pipeline_timing.R` at the project root.
2. Put the inputs under `Data/` (DCC zip, PKC, segment-annotation LWS) and helpers under `src/`; outputs are written to `Outputs/`.
3. In each notebook's YAML, set the `params:` to the values listed here (or override individually with `quarto render <notebook>.qmd -P key:value`).
4. Render in stage order (0 → 8), e.g. `Rscript render_full_pipeline_timing.R`.

`project_root: "."` resolves the project root via `here::here()`, so the notebooks find `Data/`, `src/`, and `Outputs/` relative to the repo root.

## Expected checkpoints (sanity checks)

| Checkpoint | Value |
|---|---|
| Segments passing segment-level QC (stage 1) | **277 / 277** |
| Segments entering DE after gene-detection filtering | **253** |
| Targets (genes) after probe/LOQ filtering | **7,792** |
| DE contrasts (one-vs-rest on `cell_type` × `disease_status`) | **9** (`ADM_Tumor` auto-excluded for low power) |
| DE methods produced | `dream`, `limma_voom_TMM`, `limma_voom_GeoDiff`, `limma_trend_Q3`, `limma_trend_GeoDiff` |

## Files

Prefer everything on one page? See **[ALL_PARAMS.md](ALL_PARAMS.md)** (all 9 notebooks combined).
The per-notebook files below carry the same content split out:

| Notebook | Parameter record |
|---|---|
| 0 — Standardise & merge metadata / LWS | [0_Clean_Up_Merge_LWS_Metadata.md](0_Clean_Up_Merge_LWS_Metadata.md) |
| 1 — Quality control | [1_Quality_Control.md](1_Quality_Control.md) |
| 2 — GeoDiff processing | [2_GeoDiff_Processing.md](2_GeoDiff_Processing.md) |
| 3 — Normalisation | [3_Normalisation.md](3_Normalisation.md) |
| 4 — Exploratory data analysis | [4_Exploratory_Data_Analysis.md](4_Exploratory_Data_Analysis.md) |
| 5 — Differential expression calculation | [5_Differential_Expression_Calculation.md](5_Differential_Expression_Calculation.md) |
| 6 — Differential expression visualisation | [6_Differential_Expression_Visualisation.md](6_Differential_Expression_Visualisation.md) |
| 7 — Functional enrichment | [7_functional_enrichment.md](7_functional_enrichment.md) |
| 8 — Spatial deconvolution | [8_Spatial_Deconvolution.md](8_Spatial_Deconvolution.md) |

## Legend

Each file groups parameters as:

- **Dataset-specific** — must match your inputs (filenames, metadata column names). These are the values cleared in the public notebooks.
- **Analysis parameters** — the scientifically meaningful choices (thresholds, models, methods). Keep these to replicate our results.
- **I/O & structural** — folder names, save toggles, figure sizes. Standard pipeline layout; rarely changed.
