README: 0_Clean_Up_Merge_LWS_Metadata.qmd
========================================

Purpose
-------
This README is a practical user guide for the Quarto workflow:
`0_Clean_Up_Merge_LWS_Metadata.qmd`.

Path portability
----------------
This stage defaults to `project_root: "."` and performs a 200-character path-portability audit before creating outputs. Review the rendered audit when working in Dropbox, OneDrive, or another deeply nested location. Generated diagnostic filenames may be shortened with a deterministic hash; required stage-contract filenames are preserved exactly.
Terminology used in this document:
- **Lab worksheet = LWS = Individual Readout Group file(s)** in this pipeline context.
- In other words, when this README says "LWS", it is referring to the file(s) stored in the
  `Individual_Readout_Groups` folder.

The workflow performs three key tasks:
1) Cleans and consolidates GeoMx LWS (lab worksheet / individual readout group) data,
2) Cleans one metadata file if metadata is available, and
3) Optionally merges the combined LWS table with metadata into a final output workbook.

It is designed to run in both:
- **LWS-only mode** (no metadata available), and
- **LWS + metadata merge mode**.


1) Expected Inputs
------------------
The workflow expects a project folder structure controlled by YAML parameters in the `.qmd` header.

Default expected structure:
- `<project_root>/Data/Individual_Readout_Groups/`  (required, this is the LWS/lab worksheet location)
- `<project_root>/Data/Metadata/`                    (optional)
- `<project_root>/Outputs/`                          (created/used for stage outputs)

### LWS input (required)
Place one or more LWS (lab worksheet / individual readout group) files in:
`<project_root>/Data/Individual_Readout_Groups/`

Accepted formats:
- `.txt`
- `.csv`
- `.xlsx`

What the `.qmd` does with LWS input:
- Uses YAML selectors when provided, or auto-detects all raw LWS files when selectors are blank.
- Reads each selected file and standardizes column names to snake_case.
- For `.txt`, `.csv`, and `.xlsx` LWS files, auto-detects the real header row and skips NanoString DSP preamble rows (for example *Experiment Summary*, *Library Prep Summary*) placed above it. You do not need to delete preamble rows by hand. For `.txt` it also auto-detects the delimiter.
- Warns when two raw columns clean to the same name (for example `Sample_ID` and `Sample ID` both become `sample_id`), naming the originals, because this is a common cause of ambiguous/wrong merge keys. `janitor` keeps them distinct as `sample_id`/`sample_id_2`; rename them to distinct, meaningful names before relying on either as a link column.
- Performs QA checks per source file (missing common columns, duplicate rows, empty rows, segment naming warnings).
- Adds two provenance columns before combining files:
  - `lws_source_file`
  - `lws_source_row`
- Combines selected LWS files with `bind_rows()`, so source-specific columns are retained and absent columns are filled with `NA`.
- Writes per-file cleaned LWS workbooks, a combined cleaned LWS workbook, and an LWS input audit workbook.

### Metadata input (optional)
Place zero or more metadata files in:
`<project_root>/Data/Metadata/`

Accepted formats:
- `.txt`
- `.csv`
- `.xlsx`

What the `.qmd` does with metadata input:
- If no metadata file is present, the workflow continues in LWS-only mode.
- If exactly one metadata file is present, that file is cleaned and used for merge.
- If multiple metadata files are present, `metadata_input_file` must be set explicitly.
- The workflow no longer chooses metadata by modification time.
- The selected metadata file is standardized to snake_case columns, checked for duplicate/empty rows, and written to the metadata `Cleaned` subfolder.


2) YAML Parameters and What They Do
-----------------------------------
Edit the `params:` block at the top of `0_Clean_Up_Merge_LWS_Metadata.qmd`.

### Path and output parameters
- `project_root`
  - Absolute path to the project root directory.
  - The workflow builds all other paths from this value.
- `data_dir_name`
  - Name of the data folder under project root (default: `Data`).
  - Used to find both LWS and metadata roots.
- `individual_readout_group_dir_name`
  - Folder name containing raw LWS files (default: `Individual_Readout_Groups`).
  - This is where lab worksheet (LWS) files are expected.
- `metadata_dir_name`
  - Folder name containing raw metadata files (default: `Metadata`).
  - Metadata is optional; if missing, workflow continues in LWS-only mode.
- `outputs_dir_name`
  - Root output folder name (default: `Outputs`).
  - Stage output folders are created beneath this directory.
- `clean_merge_output_dir_name`
  - Stage-specific output subfolder (default: `0_Clean_And_Merge`).
  - Final merged/fallback file and audit workbooks are written here.
- `cleaned_output_dir_name`
  - Name of cleaned subfolder created within LWS and metadata roots (default: `Cleaned`).
  - Used for intermediate cleaned workbooks before merge.
- `final_merged_filename`
  - Filename of final workbook written to stage output folder (default: `Complete_LWS_Metadata.xlsx`).
  - In LWS-only fallback mode, this still receives the combined cleaned LWS data.

### LWS input-selection parameters
- `lws_input_file`
  - Single LWS filename or absolute path.
  - Use this when one specific LWS file should be processed.
- `lws_input_files`
  - List of LWS filenames or absolute paths.
  - Use this when selected LWS files from several slides, TMAs, or runs should be combined.
- Leave both `lws_input_file` and `lws_input_files` blank to auto-detect all raw LWS files in the configured LWS folder.
- Do not set both `lws_input_file` and `lws_input_files` in the same run.

Which selector is used (set at most one; setting both stops the run with an error):
1) `lws_input_files`, when it is non-empty,
2) `lws_input_file`, when it is non-empty,
3) otherwise, auto-detect all raw `.txt`, `.csv`, and `.xlsx` files in `Data/Individual_Readout_Groups`.

Auto-detection notes:
- Files are processed in filename order for reproducibility.
- The `Cleaned` folder and generated cleaned/combined outputs are excluded.
- Auto-detect mode is intended for projects where every raw LWS file in the folder belongs to the analysis.

Example: one selected LWS

```yaml
lws_input_file: "slide_01_lws.xlsx"
lws_input_files:
  value: []
```

Example: multiple selected LWS files

```yaml
lws_input_file: ""
lws_input_files:
  value:
    - "slide_01_lws.xlsx"
    - "slide_02_lws.xlsx"
```

Example: auto-detect all raw LWS files

```yaml
lws_input_file: ""
lws_input_files:
  value: []
```

### Metadata input-selection parameter
- `metadata_input_file`
  - Single metadata filename or absolute path.
  - Leave blank when zero or exactly one raw metadata file is present.
  - Set explicitly when multiple metadata files are present.

Example:

```yaml
metadata_input_file: "complete_project_metadata.xlsx"
```

### Merge-key parameters
- `lws_link_column`
  - LWS column used as merge key.
  - Use `AUTO` to infer from known candidates, or set explicit column name.
- `metadata_link_column`
  - Metadata column used as merge key.
  - Use `AUTO` to infer from known candidates, or set explicit column name.

What the `.qmd` does with these values:
- Candidate columns, in priority order: `histo_number`, `histology_number`, `roi`, `sample_id`, `patient_id`, `roi_number`, `id`.
- **AUTO (both sides):** chooses a candidate column that is present in **both** tables, in the priority order above. A column shared by both tables is always preferred over a higher-priority column that exists in only one of them (so a shared `sample_id` is chosen even when the LWS also has `roi`). The notebook never silently joins two differently named columns (for example LWS `roi` to metadata `patient_id`).
- **Explicit (one or both sides):** the configured cleaned column must exist. Setting the two sides to different names is allowed and reported, for when the same identifier legitimately has different column names in each file.
- If no usable key can be chosen (no shared candidate in AUTO mode, or a configured column is missing), the merge is skipped, a warning explains why, and the combined cleaned LWS is still published as the final output. Set the link columns explicitly to force a specific merge.

Tip: because the merge joins on a shared identifier, make sure the *same* patient/sample code exists as a column in both the LWS and the metadata. If your LWS uses one column for the DSP/library ID (matching DCC filenames) and another for the patient ID, name them distinctly (for example `library_name` and `sample_id`) so AUTO detection picks the patient ID that the metadata also carries.

### QA parameters
- `check_segment_naming` (TRUE/FALSE)
  - Enables segment naming checks during LWS cleaning.
- `segment_column_name`
  - Column inspected for segment naming issues (default: `segment`).
  - Change this if your LWS file uses a different segment column header.
- `warn_on_case_variants` (TRUE/FALSE)
  - Warns when values differ only by case (example: `PanCK` vs `panck`).


3) What the Workflow Outputs
----------------------------
Outputs are written to deterministic locations.

### Cleaned LWS outputs
Per-file cleaned LWS workbooks are written to:
`<project_root>/Data/Individual_Readout_Groups/Cleaned/`

Per-file naming:
`<original_lws_filename>_cleaned.xlsx`

The combined cleaned LWS workbook is written to:
`<project_root>/Data/Individual_Readout_Groups/Cleaned/Combined_LWS_cleaned.xlsx`

The combined workbook contains all selected LWS rows plus:
- `lws_source_file`
- `lws_source_row`

### LWS input audit output
Written to:
`<project_root>/Outputs/0_Clean_And_Merge/LWS_Input_Audit.xlsx`

Contains:
- Selected LWS files and source-level dimensions,
- Combined LWS dimensions,
- Schema inventory showing which columns were present in each source file.

### Cleaned metadata output
Written to:
`<project_root>/Data/Metadata/Cleaned/`

Naming:
`<selected_metadata_filename>_cleaned.xlsx`

### Final stage output
Written to:
`<project_root>/Outputs/0_Clean_And_Merge/<final_merged_filename>`

Default final filename:
`Complete_LWS_Metadata.xlsx`

If merge succeeds, this file contains combined LWS + metadata.
If merge is skipped or fails key inference, this file contains combined cleaned LWS only.

### Merge audit output (only when merge succeeds)
Written to:
`<project_root>/Outputs/0_Clean_And_Merge/Merge_Audit.xlsx`

Contains:
- Merge summary metrics,
- LWS-only keys,
- Metadata-only keys,
- Duplicate metadata keys,
- LWS rows by source file,
- Merged rows by source file,
- LWS rows per key.


4) How to Run the Workflow
--------------------------
Run from R using Quarto rendering.

Example command:

```r
quarto::quarto_render("0_Clean_Up_Merge_LWS_Metadata.qmd")
```

or via CLI:

```bash
quarto render 0_Clean_Up_Merge_LWS_Metadata.qmd
```

Before running:
1) Verify `project_root` is correct for your machine/environment.
2) Confirm required LWS/lab worksheet input exists in the configured readout-group folder.
3) Decide whether to auto-detect all LWS files or set `lws_input_file` / `lws_input_files`.
4) Confirm metadata files are present if you intend to merge.
5) If multiple metadata files are present, set `metadata_input_file`.
6) If merge keys are non-standard, set `lws_link_column` and `metadata_link_column` explicitly.
7) Confirm your expected output filename/path values are intentional.


5) Practical YAML Editing Guidance
----------------------------------
Use these practices when editing YAML parameters:

- Prefer changing folder **names** via parameters before modifying code paths.
- Use auto-detect LWS mode only when every raw LWS file in the configured folder belongs to the current analysis.
- Use `lws_input_files` when a project spans several selected slides, TMAs, batches, or instrument iterations.
- Use `metadata_input_file` when more than one metadata file exists in the metadata folder.
- Keep `AUTO` merge-key detection only if your column names match typical candidates.
- If your team uses custom key columns, set explicit values for:
  - `lws_link_column`
  - `metadata_link_column`
- Keep QA flags enabled initially (`check_segment_naming: true`) to catch naming inconsistencies early.
- If segment column has a different name in your export, update `segment_column_name` accordingly.
- Avoid trailing spaces or typo differences in folder names; parameter values map directly to real directories.

Recommended review checklist for YAML:
- [ ] `project_root` exists
- [ ] Data subfolders are named correctly
- [ ] LWS (lab worksheet / individual readout group) file(s) present in readout folder
- [ ] LWS selector fields match the intended input mode
- [ ] Metadata folder/path correct (if using merge)
- [ ] `metadata_input_file` set when multiple metadata files exist
- [ ] Merge key params validated for your schema
- [ ] Output filename/path choices are intentional


6) User Notes (for people reviewing this README + QMD)
------------------------------------------------------
What this workflow does for you as a user/reviewer:
- Gives a repeatable, parameter-driven way to clean and consolidate one or more LWS tables.
- Supports experiments spread across multiple slides, TMAs, or lab worksheet exports.
- Preserves source-file provenance for every combined LWS row.
- Produces cleaned intermediate files so you can inspect preprocessing outputs directly.
- Supports optional metadata and still completes with useful output in LWS-only mode.
- Requires explicit metadata selection when multiple metadata files are present.
- Attempts merge automatically but avoids hard failure when keys are not inferable.
- Provides LWS input and merge diagnostics in dedicated audit workbooks.
- Standardizes columns and reports common QA warnings to help spot data issues early.

How to use this during review:
1) Check YAML params first (paths, LWS selection, metadata selection, merge keys, QA settings).
2) Check input placement in configured LWS and metadata folders.
3) Run the QMD and verify cleaned outputs were generated.
4) Inspect `LWS_Input_Audit.xlsx` to confirm the intended LWS files were selected and combined.
5) Inspect final output and merge audit (if produced) to confirm expected join behavior.

In short: this README + QMD pairing is intended to let users and reviewers independently run and validate the stage end-to-end without requiring verbal walkthrough.
