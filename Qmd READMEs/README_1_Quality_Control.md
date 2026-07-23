README: 1_Quality_Control.qmd
=============================

Purpose
-------
This README is a practical user guide for the Quarto workflow:
`1_Quality_Control.qmd`.

Path portability
----------------
This stage defaults to `project_root: "."` and performs a 200-character path-portability audit before creating outputs. Review the rendered audit when working in Dropbox, OneDrive, or another deeply nested location. Generated diagnostic filenames may be shortened with a deterministic hash; required stage-contract filenames are preserved exactly.
Terminology used in this document:
- **Lab worksheet = LWS = Individual Readout Group file(s)**.
- Digital count conversion (DCC) files are NanoString-processed count files, not raw FASTQ files.
- Probe kit configuration (PKC) files provide probe annotation used when constructing the GeoMx object.
- This stage consumes the merged output created by stage 0 (`0_Clean_Up_Merge_LWS_Metadata.qmd`).

The workflow performs these core tasks:
1) Resolves and validates GeoMx inputs (DCC, PKC, merged LWS+metadata),
2) Builds a `NanoStringGeoMxSet` object,
3) Applies segment-level and probe-level QC,
4) Applies LOQ and detection-rate filtering,
5) Writes QC outputs (tables, figures, and filtered RDS objects) into `Outputs/1_QC`.

This document explains what to provide, how to configure YAML, what outputs to expect, and how users/reviewers should run and validate the step.


1) Expected Inputs
------------------
The workflow is parameter-driven and expects a project folder structure derived from YAML.

Default expected structure:
- `<project_root>/Data/DCC_Files/`                        (required; DCC sources)
- `<project_root>/Data/PKC_Files/`                        (required; PKC sources)
- `<project_root>/Data/rawdata/`                          (created/used for prepared DCC files)
- `<project_root>/Outputs/0_Clean_And_Merge/`             (required stage-0 output location)
- `<project_root>/Outputs/0_Clean_And_Merge/Complete_LWS_Metadata.xlsx` (required stage-0 file)

### Required input from stage 0
File expected:
- `Complete_LWS_Metadata.xlsx` (name configurable via YAML)

What the `.qmd` does:
- Loads the merged LWS+metadata workbook,
- Standardises column names,
- Harmonises sample ID to internal `sample_id`,
- Audits `slide_name` before GeoMx object construction so likely template-control rows can be identified,
- Writes the cleaned, combined metadata used to build the GeoMx object.

Slide metadata note:
- The pipeline uses snake_case metadata names internally, including `slide_name`.
- Template-control rows are identified from the internal `slide_name` column (a case-insensitive match on the word "template") and are removed before the GeoMx object is built.
- `GeomxTools::readNanoStringGeoMxSet()` expects a column named `slide name` to identify the slide for each sample, so when `slide_name` is available the notebook adds a copy of it under that name while building the object, and keeps `combinedMetadata$slide_name` for later stages.
- If `slide_name` is missing, the notebook keeps all rows, warns that template controls cannot be identified from slide metadata, and records this in `template_control_audit.csv`.

### PKC input (required)
Provide one of the following in the configured PKC folder:
- `.pkc` file directly, or
- `.zip` containing PKC, or
- `.pkc.gz` / `.gz` archive.

What the `.qmd` does:
- Uses explicit PKC filename if configured,
- Otherwise auto-detects existing `.pkc`,
- Otherwise extracts from archive and then selects `.pkc`.

### DCC input (required)
Place one or more `.zip` archives in:
`<project_root>/Data/DCC_Files/`

Inside each selected zip archive, the notebook supports either raw `.dcc` files or compressed `.dcc.gz` files.

What the `.qmd` does:
- Uses `dcc_zip_name` when one explicit zip archive should be selected.
- Uses `dcc_zip_names.value` when several zip archives should be included in one run.
- Auto-detects the DCC input only when exactly one `.zip` file is present.
- Extracts selected zip archives into the prepared raw-data folder.
- Aligns DCC files to metadata sample IDs before building `NanoStringGeoMxSet`.

If several DCC zip archives are present, select the intended input explicitly in YAML. This avoids mixing unrelated sequencing runs by accident.


2) YAML Parameters and What They Do
-----------------------------------
Edit the `params:` block at the top of `1_Quality_Control.qmd`.

Important Quarto structure note:
- List/object parameters must be nested under `value:`.
- In this file, `dcc_zip_names`, `qc`, and `save` use that structure.

### Path and folder parameters
- `project_root`
  - Absolute project root path.
  - If blank/`.` the workflow attempts root auto-detection from working directory.
- `dir_data`, `dir_outputs`, `dir_src`
  - Core project folders used to resolve input, output, and project-level helper paths.
- `dir_src`
  - Source/helper folder under `project_root`; the default is `<project_root>/src`.
- `dir_dcc`, `dir_pkc`, `dir_rawdata`
  - Input locations for DCC, PKC, and prepared raw DCC files.
- `dir_clean_merge_output`
  - Stage-0 output folder under `Outputs`.

### Merged-metadata parameters from stage 0
- `merged_lws_metadata_file`
  - Name of merged file produced by stage 0 (default: `Complete_LWS_Metadata.xlsx`).
- `sample_id_column`
  - Name of the sample ID column in the merged metadata.
  - This must be the identifier that matches the DCC filenames (the DSP/library ID, for example `DSP-1001660011751-A-A02`), not the patient ID.
  - Workflow copies this column to internal `sample_id` and uses `sample_id` in later stages. If the merged metadata already contains a different `sample_id` column (for example a patient code carried over from the stage-0 merge), it is replaced and the notebook warns. Keep the DSP/library ID and the patient ID in distinctly named columns (for example `library_name` and `patient_id`) to avoid this.

### Optional explicit file-pick parameters
- `pkc_zip_name`
  - Optional explicit PKC archive filename.
- `pkc_file_name`
  - Optional explicit PKC file name.
- `dcc_zip_name`
  - Optional explicit single DCC zip filename, for example `run_12_dcc.zip`.
- `dcc_zip_names.value`
  - Optional explicit list of DCC zip filenames.
  - Leave both DCC fields empty only when exactly one `.zip` file is present in `Data/DCC_Files`.

### QC threshold parameters (`qc.value`)
These values control QC flagging/filtering logic, including:
- Segment read/sequencing thresholds:
  - `minSegmentReads`, `percentTrimmed`, `percentStitched`, `percentAligned`, `percentSaturation`
- Control/count thresholds:
  - `minNegativeCount`, `maxNTCCount`
- Segment morphology thresholds:
  - `minNuclei`, `minArea`
- Plot cut-lines:
  - `cutline_saturation`, `cutline_trimmed`, `cutline_stitched`, `cutline_aligned`, `cutline_area`
- Probe QC controls:
  - `minProbeRatio`, `percentFailGrubbs`, `removeLocalOutliers`
- LOQ controls:
  - `loq_cutoff_sd`, `loq_min`
- Detection-rate filters:
  - `min_gene_detection_rate_per_segment`, `min_gene_detection_rate_across_segments`

### Segment QC pass/fail and missing values
- Segment-level QC flags each segment against the `qc.value` thresholds, then only segments with an overall `PASS` status are retained.
- A segment whose QC status cannot be determined is treated as a **failure** and removed, never silently kept. This happens, for example, when a segment has a missing nuclei count: the nuclei flag becomes undefined (`NA`), so the overall status is undefined.
- When this occurs the notebook prints a clear count and lists the affected segments (one warning where nuclei are read, and again at the segment QC filter). If those segments should be retained, correct the missing nuclei counts in the metadata; setting `minNuclei` to `0` does **not** rescue a missing (NA) count.
- After filtering, the notebook verifies the object is internally consistent (sample names intact, expression/annotation aligned) before probe QC, so a corrupted filter fails fast and clearly instead of surfacing later as an opaque probe-QC error.

### QC plot colors
QC histograms and segment-level QC plots are intentionally colored by the `segment` metadata column.
The workflow automatically assigns segment colors from the Okabe-Ito palette after reading the observed segment levels.
No project-specific palette file or YAML color mapping is required.
If a dataset contains more segment classes than the base Okabe-Ito palette provides, the notebook extends the palette deterministically so plotting does not fail.

### Save behavior parameters (`save.value`)
- `save_plots` (TRUE/FALSE)
  - Controls whether figure files are written to the stage figures folder.
- `save_rds` (TRUE/FALSE)
  - Controls whether filtered/intermediate RDS objects are written.

### Stage output naming parameters
- `out_stage` (default: `1_QC`)
  - Stage output root under `Outputs`.
- `out_results`, `out_tables`, `out_figures`
  - Subfolder names created under `Outputs/<out_stage>/`.


3) What the Workflow Outputs
----------------------------
Outputs are written to deterministic stage paths under:
`<project_root>/Outputs/<out_stage>/`

Default root:
`<project_root>/Outputs/1_QC/`

### Tables
Default path:
`<project_root>/Outputs/1_QC/tables/`

Common outputs include:
- `completeMetadata.xlsx` (the cleaned, combined metadata),
- `detected_segments.xlsx`,
- `template_control_audit.csv`,
- rendered QC flag tables showing per-metric flag counts and samples with one or more QC flags,
- additional QC summary/support tables produced by workflow helpers.

### Figures (if `save_plots: true`)
Default path:
`<project_root>/Outputs/1_QC/figures/`

Examples:
- `saturatedQC.png`
- `trimmedQC.png`
- `stitchedQC.png`
- `alignedQC.png`
- `areaQC.png`
- `area_vs_alignment.png`
- `geneDetectionRatePerSegment.png`
- `geneDetection.png`

### Results objects (if `save_rds: true`)
Default path:
`<project_root>/Outputs/1_QC/results/`

Examples:
- `QC_pass_spatial_data.RDS`
- `filtered_spatial_data.RDS`


4) How to Run the Workflow
--------------------------
Run from R using Quarto rendering.

Example command:

```r
quarto::quarto_render("1_Quality_Control.qmd")
```

or via CLI:

```bash
quarto render 1_Quality_Control.qmd
```

Before running:
1) Confirm stage 0 has completed and merged file exists.
2) Confirm PKC and DCC inputs are available in configured folders.
3) Confirm `sample_id_column` matches the merged metadata file.
4) Confirm `qc.value` thresholds reflect your project requirements.
5) Confirm `save.value` options match whether you want plots and RDS outputs.


5) Practical YAML Editing Guidance
----------------------------------
Use these practices when editing YAML parameters:

- Start by validating paths and folder names before tuning QC thresholds.
- Keep `qc.value` in one block so threshold changes are auditable and reviewable.
- Use explicit file picks (`pkc_file_name`, `pkc_zip_name`, `dcc_zip_names.value`) when multiple candidate inputs exist.
- Keep `sample_id_column` aligned to your merged metadata schema from stage 0.
- Only disable plot/RDS saving intentionally (e.g., quick dry runs).
- Avoid changing both path parameters and threshold parameters in one commit when possible; this makes review simpler.

Recommended review checklist for YAML:
- [ ] `project_root` exists and is correct for current environment
- [ ] Stage-0 merged file path/name is correct
- [ ] DCC/PKC folders and filenames are correct
- [ ] `sample_id_column` exists in merged metadata
- [ ] QC thresholds are intentional and documented
- [ ] Save flags (`save_plots`, `save_rds`) are intentional
- [ ] Output subfolder naming is intentional


6) User Notes (for people reviewing this README + QMD)
------------------------------------------------------
What this workflow does for you as a user/reviewer:
- Provides a reproducible, parameterized QC stage from raw GeoMx inputs to QC-filtered outputs.
- Harmonises metadata/sample IDs so input matching is explicit and easier to troubleshoot.
- Applies configurable segment/probe/LOQ/detection filters in a transparent YAML-driven way.
- Generates review-ready files (tables, figures, RDS) that support QC decisions and reruns.
- Supports practical rerun behavior by reusing prepared files where possible.

How to use this during review:
1) Review YAML first (paths, stage-0 file, sample ID column, QC/save settings).
2) Verify required inputs are in the configured folders.
3) Run the QMD and check that stage folders are populated.
4) Inspect QC figures/tables for expected threshold behavior.
5) Review the `Samples with QC flags under the current thresholds` table.
   This table is focused on samples with one or more QC flags, sorted by `TOTAL_FLAGS`.
   If no samples are flagged, the notebook renders a one-row message stating that no samples had QC flags under the current thresholds.
6) Confirm RDS outputs for later stages were produced when enabled.

In short: this README + QMD pairing is intended to let users/reviewers independently execute and validate the QC stage without needing a verbal walkthrough.
