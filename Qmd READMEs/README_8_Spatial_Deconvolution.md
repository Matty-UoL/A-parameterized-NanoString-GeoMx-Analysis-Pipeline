# 8 Spatial Deconvolution

`8_Spatial_Deconvolution.qmd` estimates reference cell-type abundance from a normalized GeoMx expression object using SpatialDecon.

## When to Run

Run this notebook after normalization outputs from stage 3 are available. It is an optional interpretation step and does not change DE results from earlier stages.

## Path Portability

Stage 8 writes to `Outputs/8_Deconvolution/` with result and figure files under a compact `decon/` subfolder. Reference-cache filenames and other generated files are shortened deterministically when necessary, while the selected Stage 3 input file name is kept unchanged.
GeoDiff-filtered count data is not required for Stage 8. The recommended default is the Q3/negative-probe object from stage 3:

- `norm_object_file: "normalised_spatial_data.RDS"`
- `norm_assay: "q_norm"`

If GeoDiff was intentionally skipped earlier in the workflow, keep those defaults. Only select `GeoDiff_normalised_spatial_data.RDS` with `norm_assay: "normmat"` when that GeoDiff-normalized object exists and you specifically want to run the optional GeoDiff consistency check.

## Key YAML Decisions

- `norm_object_file` and `norm_assay`: choose the normalized expression object and assay.
- Default when GeoDiff outputs are absent: use `normalised_spatial_data.RDS` with `q_norm`. The filename uses `normalised` because it is the current pipeline filename.
- Optional GeoDiff consistency check: use `GeoDiff_normalised_spatial_data.RDS` with GeoDiff-normalized `normmat` only if the GeoDiff-normalized object exists.
- `reference_source`: choose `local_file`, `cell_profile_library`, or `spatialdecon_builtin`.
- `reference_file`, `reference_matrix_name`, and cache settings: define the reference matrix used for deconvolution. With the default settings, local and cached CellProfileLibrary matrices are read from `Data/Spatial_Deconvolution_References/`.
- `min_reference_gene_overlap` and `stop_on_low_gene_overlap`: control reference compatibility checks.
- `metadata_context_columns`: metadata columns carried into output tables.
- `heatmap_annotation_columns`: metadata columns drawn as annotation bars on beta and proportion heatmaps when present.
- `heatmap_annotation_color_overrides`: optional fixed colors for known annotation levels such as CD45, PanCK, and Stroma.
- `show_heatmap_sample_labels`: enable only when sample labels remain readable.

## Outputs to Check

- `Outputs/8_Deconvolution/tables/stage8_input_file_status.csv`, which records whether the selected input, default Q3 object, and optional GeoDiff-normalized object were found.
- Reference matrix provenance and cell-type inventory tables.
- Gene-overlap and reference compatibility audit tables.
- Reference profile heatmap.
- SpatialDecon beta and proportion heatmaps with configured sample metadata annotation bars.
- `Outputs/8_Deconvolution/tables/stage8_output_list.csv`.

## Decision Before Continuing

Interpret cell-type abundance only if the reference matrix is biologically appropriate and the gene-overlap audit passes the configured threshold. Low overlap usually means the reference or gene identifiers need to be changed before biological conclusions are made.
