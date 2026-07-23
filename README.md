# GeoMx DSP Parameterized Protocol Pipeline

[![DOI](https://zenodo.org/badge/1283794374.svg)](https://doi.org/10.5281/zenodo.21163241)

![Graphical abstract](Graphical%20Abstract.jpg)

This repository contains a staged, YAML-driven Quarto workflow for NanoString GeoMx Digital Spatial Profiler (DSP) next-generation sequencing (NGS) Whole Transcriptome Atlas (WTA) analysis. The notebooks are designed as a protocol pipeline: each stage states its inputs, writes tables, figures, and RDS files, and explains what the user should check before moving to the next stage.

## Run Requirements

Install R version 4.4.1 or a later compatible version before rendering the workflow. Early quality control and data preparation stages usually require only modest computational resources and can typically be run on a standard workstation with at least 4 CPU cores and 8 GB RAM; 16 GB RAM is recommended for smoother performance. Later interpretation modules can require more memory and longer render times, especially when many contrasts, gene sets, or spatial deconvolution references are evaluated.

## Portable Paths and Cloud Storage

All notebooks default to `project_root: "."` and apply a conservative 200-character portability budget. Stage 0 checks the current project and the deepest standard downstream output before analysis begins; every later stage repeats an audit for its own inputs and outputs.

New runs use compact paths for later stages: Stage 5 writes DE files under `Outputs/5_DE/results/de/`, Stage 6 writes to `Outputs/6_DE_Vis/`, Stage 7 writes to `Outputs/7_Enrichment/`, and Stage 8 writes to `Outputs/8_Deconvolution/`. Stages 6 and 7 automatically read the legacy Stage 5 `results/differential_expression/` directory when `results/de/` is absent.

Generated plots and diagnostic files are shortened deterministically when necessary; the extension and an eight-character hash are retained and the resolved path is recorded in output audits. Required stage-contract filenames are never renamed silently. If one cannot fit, the setup section stops early and reports how much the project or output path must be shortened.

This protection is important for Dropbox, OneDrive, network drives, and other deeply nested locations. Windows long-path support varies across R packages and graphics devices, so enabling it is not a substitute for the pipeline audit. If Stage 0 reports a blocked path, shorten `project_root` or the configured output folder before starting the workflow. If Quarto itself fails before the Stage 0 audit appears, render from a shorter local working copy.
## Getting Started With Example Data

The repository includes runnable example inputs under `Example_Dataset/`. This folder contains the example data files only. Shared helper scripts, bundled GMT files, and small protocol templates are stored once in the top-level `src/` directory so the example cannot drift away from the active pipeline code.

The bundled example uses publicly available NanoString GeoMx DSP data from NCBI GEO accession **GSE226829** (Carpenter et al., *Cancer Discovery*, 2023 — https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE226829). If you use the example data, please cite the original study and acknowledge GEO.

1. Install the required R packages from the repository root:

   ```r
   source("install/install.R")
   ```

   See `install/README_Install.md` for dry-run and optional dependency details.
2. Confirm the example input layout is present:

   ```text
   Example_Dataset/
     Data/
       Individual_Readout_Groups/
       DCC_Files/
       PKC_Files/
       Metadata/
       Spatial_Deconvolution_References/
       contrasts.txt
   ```

3. Render the example from the repository root and keep `dir_src: "src"` so notebooks source helpers from the top-level `src/` directory. For the bundled example, set the stage 0 path parameters to `data_dir_name: "Example_Dataset/Data"` and `outputs_dir_name: "Example_Dataset/Outputs"`. For stages 1-8, set `dir_data: "Example_Dataset/Data"` and `dir_outputs: "Example_Dataset/Outputs"`.
4. Review each rendered notebook before continuing to the next stage. Outputs are written under `Example_Dataset/Outputs/`.

For your own dataset, copy the same `Data/` structure into your analysis project, set `project_root` to the repository root or to a project folder that can resolve the configured `Data/`, `Outputs/`, and `src/` paths, and update the YAML metadata, contrast, and threshold parameters before rendering. Do not copy or maintain a second `src/` directory inside `Example_Dataset/`.

## Setting Up the Directory for Your Own Data

For a new GeoMx DSP dataset, keep the staged notebooks, shared helper files, input data, and outputs under one project root. This makes the YAML paths portable and keeps the workflow reproducible across machines.

A typical analysis directory should look like this:

```text
<project_root>/
  0_Clean_Up_Merge_LWS_Metadata.qmd
  1_Quality_Control.qmd
  2_GeoDiff_Processing.qmd
  3_Normalisation.qmd
  4_Exploratory_Data_Analysis.qmd
  5_Differential_Expression_Calculation.qmd
  6_Differential_Expression_Visualisation.qmd
  7_functional_enrichment.qmd
  8_Spatial_Deconvolution.qmd
  install/
  src/
  Data/
    Individual_Readout_Groups/
    DCC_Files/
    PKC_Files/
    Metadata/
    Spatial_Deconvolution_References/
    contrasts.txt
  Outputs/
```

Set `project_root` in each notebook YAML to the folder represented by `<project_root>/`.

For a standard project-rooted analysis, use these path settings:

```yaml
project_root: "."
portable_path_limit: 200
dir_src: "src"
dir_data: "Data"
dir_outputs: "Outputs"
```

For stage 0, use the stage 0 path parameter names:

```yaml
data_dir_name: "Data"
outputs_dir_name: "Outputs"
```

The `src/` directory should remain at the top level of the project root. Do not copy `src/` into `Data/`, `Outputs/`, or a dataset-specific folder. User-supplied inputs, including DE contrast files such as `contrasts.txt`, should go in `Data/`.

Before rendering the workflow, confirm that the required raw inputs are in the expected locations, review the YAML metadata-column mappings, and render the notebooks in stage order from `0` through `8`.

## Stage Order

Run notebooks in order from the repository root, using the YAML parameters at the top of each notebook to adapt paths, metadata columns, thresholds, and optional analysis choices.

| Stage | Notebook | Purpose | Main outputs |
|---|---|---|---|
| 0 | `0_Clean_Up_Merge_LWS_Metadata.qmd` | Clean and merge LWS metadata. | `Outputs/0_Clean_And_Merge/` cleaned metadata workbook for QC. |
| 1 | `1_Quality_Control.qmd` | Import DCC files, run QC, and export filtered GeoMx objects. | `Outputs/1_QC/` QC objects, tables, and figures. |
| 2 | `2_GeoDiff_Processing.qmd` | Run GeoDiff background modelling and segment retention checks. | `Outputs/2_GeoDiff/` GeoDiff-filtered count object and diagnostics. |
| 3 | `3_Normalisation.qmd` | Generate Q3, TMM, negative-probe, and GeoDiff-normalized outputs. | `Outputs/3_Norm/` normalized objects, including GeoDiff `normmat`, and comparison plots. |
| 4 | `4_Exploratory_Data_Analysis.qmd` | Review PCA and exploratory metadata diagnostics. | `Outputs/4_EDA/` PCA and marker diagnostic outputs. |
| 5 | `5_Differential_Expression_Calculation.qmd` | Fit supported DE models and export model result objects. | `Outputs/5_DE/results/de/` method objects plus stage tables, figures, and output list. |
| 6 | `6_Differential_Expression_Visualisation.qmd` | Visualize and compare outputs from `5_Differential_Expression_Calculation.qmd`, then inspect selected methods and contrasts before enrichment. | `Outputs/6_DE_Vis/` comparison tables, volcano/correlation figures, selected-method heatmaps, top-gene segment panels, and output list. |
| 7 | `7_functional_enrichment.qmd` | Run pathway enrichment from selected DE results. | `Outputs/7_Enrichment/` enrichment tables, figures, and output list. |
| 8 | `8_Spatial_Deconvolution.qmd` | Run reference-matrix SpatialDecon QC and heatmap outputs. | `Outputs/8_Deconvolution/` deconvolution tables, figures, and output list. |

## How to Use the Pipeline

1. Install required R packages from the repository root:

   ```r
   source("install/install.R")
   ```

   See `install/README_Install.md` for dry-run and optional dependency details.
2. Place input files and reference resources under the project root configured by `project_root`.
3. Review each notebook YAML before rendering, especially metadata column mappings, contrast settings, and output stage names.
4. Render stages sequentially so each notebook can find the outputs from earlier stages.
5. Read each rendered HTML before proceeding; each stage includes decision checkpoints for QC, model choice, or interpretation.
6. Archive the output lists with run notes so reviewers can trace which files were generated and why each downstream decision was made.

## Repository Layout

The active notebooks expect shared protocol utilities in the top-level `src/` directory and user-supplied analysis inputs in the configured data directory:

- `src/utilityFunctions.R` contains shared plotting and workflow helper functions.
- `src/pathUtilities.R` contains the path-length checks that every notebook runs at the start of its setup; each stage stops with a clear message if this file is missing.
- GMT files and small protocol templates that are shipped with the repository also live in `src/`.
- User-supplied analysis inputs, including DE contrast tables such as `Data/contrasts.txt`, should live in `Data/`.
- SpatialDecon reference matrices should live in `Data/Spatial_Deconvolution_References/` by default.
- The bundled example stores inputs under `Example_Dataset/Data/` and writes outputs under `Example_Dataset/Outputs/`; it intentionally uses the top-level `src/` directory.

Do not create a separate `Scripts/src/` directory or `Example_Dataset/src/` helper copy for a clean clone. If you keep notebooks and analysis outputs in different locations, set `project_root` and the data/output directory parameters so they resolve to the intended `Data/` and `Outputs/` folders, and leave `dir_src: "src"` unless you intentionally rename the top-level helper directory.

## Stage Guides

Stage-specific Markdown user guides live in `Qmd READMEs/`.

Rendered notebook examples may also be present in `Qmd Renders/` and `Qmd READMEs/`, but the notebooks are the files to edit and re-render.

## Reproducibility Notes

- Use project-rooted paths and notebook YAML parameters rather than editing code paths directly.
- Shared helper files are resolved from `project_root/dir_src`, which defaults to `<project_root>/src`.
- Run `source("install/install.R")` in a clean R environment before rendering the workflow for the first time.
- Define cohort-specific abbreviations and metadata terms before adapting the workflow. In this repository, DCC means digital count conversion, PKC means probe kit configuration, QC means quality control, DE means differential expression, and PCA means principal component analysis.
- ROI means region of interest: a region placed on the tissue. AOI means area of illumination, also called a **segment**: the profiled collection area within an ROI, such as PanCK, A-SMA, CD45, or Stroma. One ROI may contain several segments. The segment is the unit of data throughout this pipeline, because one segment corresponds to one DCC file and one column of the GeoMx object, so counts reported by every stage are segment counts rather than ROI counts.
- Stage 1 QC plots are colored by `segment` using an automatically generated Okabe-Ito palette; no project-specific palette file is required.
- Stage 5 writes DE contracts to `5_DE/results/de`; Stage 6 writes to `6_DE_Vis` and retains read compatibility with the legacy Stage 5 `results/differential_expression` folder.
- In `5_Differential_Expression_Calculation.qmd`, `contrast_factor` controls which metadata column defines DE groups. The default `Annotation` is generated as `<cell_type>_<disease_status>`, but users can provide any existing metadata column and matching contrast table rows.
- In `5_Differential_Expression_Calculation.qmd`, fixed-effect covariates are typed explicitly. Put numeric variables such as `age` in `model_covariates_continuous` and group variables such as `sex`, `slide_name`, or `batch` in `model_covariates_categorical`; confirm numeric covariates are numeric in metadata before Stage 5.
- Machine-specific library setup snippets have been removed from the DE notebooks. Configure R libraries through the active R environment rather than notebook-local setup code.
- For a clean verification pass, render notebooks `0` through `8` in order and confirm there are no unreviewed warnings or missing output files.
