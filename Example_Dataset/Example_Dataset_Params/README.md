# Example dataset parameters (GSE226829)

This folder records the **exact `params:` values** used to produce the worked-example
renders shipped with this protocol, so a reviewer can reproduce the analysis on their
own machine. Each file documents one notebook's YAML front matter.

The published notebooks ship with the GSE226829 values already in place, so the example
renders reproduce without editing the YAML. Use the files here as the authoritative record
of those values, and as the starting point when adapting the workflow to your own data.

## Dataset

- **GEO accession:** [GSE226829](https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE226829) — pancreatic (PDAC) GeoMx Whole Transcriptome Atlas, 277 segments (AOIs) across 6 tissue sections (2 healthy, 4 tumour) on 4 slides.
- The QC thresholds and DE contrasts were chosen to match the **original published analysis** of this dataset (see notebooks 1 and 5).

## How to reproduce

1. Clone the repository to a **short path** (for example `C:\R\gmx`). The notebooks enforce a
   200-character path budget, so a deeply nested project root will stop the run early.
2. Inputs live under `Example_Dataset/Data/` (DCC zip, PKC, segment-annotation LWS) and helpers
   under `src/`; outputs are written to `Example_Dataset/Outputs/`.
3. The GSE226829 values are already set in each notebook's YAML — no editing is required to
   reproduce the shipped renders. Only the **path** parameters need pointing at the bundled
   example, which is done on the command line so the notebooks keep their generic defaults.
4. Render in stage order 0 → 8. Each stage reads the previous stage's outputs, so order matters.

   Stage 0 takes `data_dir_name` / `outputs_dir_name`:

   ```bash
   quarto render 0_Clean_Up_Merge_LWS_Metadata.qmd \
     -P data_dir_name:Example_Dataset/Data \
     -P outputs_dir_name:Example_Dataset/Outputs
   ```

   Stages 1, 5, 7 and 8 read the raw data, so they take both `dir_data` and `dir_outputs`:

   ```bash
   quarto render 1_Quality_Control.qmd \
     -P dir_data:Example_Dataset/Data \
     -P dir_outputs:Example_Dataset/Outputs
   ```

   Stages 2, 3, 4 and 6 only read earlier stage outputs, so they take `dir_outputs` alone.
   Passing a parameter a notebook does not declare will stop the render.

   ```bash
   quarto render 2_GeoDiff_Processing.qmd -P dir_outputs:Example_Dataset/Outputs
   ```

`project_root: "."` resolves the project root via `here::here()`, so the notebooks find `Data/`,
`src/`, and `Outputs/` relative to the repo root. To run against your own data instead, copy the
`Data/` layout to your project root and drop the `-P` overrides.

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
