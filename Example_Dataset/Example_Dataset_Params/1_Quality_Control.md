# Notebook 1 — Quality control

Exact `params:` used for the **GSE226829** exemplar render. This stage builds the
`NanoStringGeoMxSet`, applies segment- and probe-level QC, and performs LOQ-based
detection filtering.

> **These QC thresholds match the original published GSE226829 analysis.** The critical
> choice is `percentSaturation: 0`: the NanoString default of 50 removed the normal-pancreas
> Healthy segments (high reads but only ~40–46 % sequencing saturation), collapsing
> `Duct_Healthy`/`PanIN_Healthy` to n=1. At 0, all **277** segments pass segment QC and every
> Healthy group is retained.

## Key analysis parameters — segment QC (`qc:`)

| Parameter | Value | Notes |
|---|---|---|
| `minSegmentReads` | `1000` | |
| `percentTrimmed` | `80` | |
| `percentStitched` | `80` | |
| `percentAligned` | `75` | Published value (NanoString default is 80). |
| `percentSaturation` | `0` | Published value — no saturation gate (see note above). |
| `minNegativeCount` | `1` | |
| `maxNTCCount` | `9000` | |
| `minNuclei` | `20` | |
| `nuclei_column` | `""` | No nuclei column in this dataset → `minNuclei` is skipped (no segments removed by nuclei count). |
| `minArea` | `1000` | Published value (default 500; no segments fall in 500–1000 here, so a no-op for this dataset). |

## Key analysis parameters — probe QC & detection

| Parameter | Value | Notes |
|---|---|---|
| `minProbeRatio` | `0.1` | |
| `percentFailGrubbs` | `20` | |
| `removeLocalOutliers` | `true` | |
| `loq_cutoff_sd` | `2` | LOQ = mean + 2 SD of negatives. |
| `loq_min` | `2` | Floor for LOQ. |
| `min_gene_detection_rate_per_segment` | `0.10` | Segment kept if it detects ≥10 % of genes → **253** segments pass into DE. |
| `min_gene_detection_rate_across_segments` | `0.10` | Gene kept if detected in ≥10 % of segments → **7,792** targets. |

The `cutline_*` values (`cutline_saturation: 50`, `cutline_trimmed: 80`, `cutline_stitched: 50`,
`cutline_aligned: 40`, `cutline_area: 1000`) are **visual reference lines on the QC histograms only**
and do not filter data.

## Dataset-specific inputs

| Parameter | Value | Notes |
|---|---|---|
| `sample_id_column` | `library_name` | Metadata ID column; renamed to internal `sample_id` for later stages. |
| `key_annotation_column` | `disease_status` | Group used in the optional post-LOQ QC audit. |
| `key_annotation_min_segments_per_group` | `3` | Minimum segments per group for that audit. |
| `pkc_zip_name` | `GSE226829_Hs_R_NGS_WTA_v1.0.pkc.gz` | In `Data/PKC_Files/`. |
| `pkc_file_name` | `""` | Auto-detect after unzip. |
| `dcc_zip_name` | `GSE226829_RAW.zip` | In `Data/DCC_Files/`. |
| `dcc_zip_names` | `value: []` | Unused (single zip). |
| `merged_lws_metadata_file` | `Complete_LWS_Metadata.xlsx` | Output from stage 0. |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `240` |
| `dir_data` / `dir_outputs` / `dir_src` | `Data` / `Outputs` / `src` |
| `dir_dcc` / `dir_pkc` / `dir_rawdata` | `DCC_Files` / `PKC_Files` / `rawdata` |
| `dir_clean_merge_output` | `0_Clean_And_Merge` |
| `out_stage` | `1_QC` |
| `out_results` / `out_tables` / `out_figures` | `results` / `tables` / `figures` |
| `save:` `save_plots` / `save_rds` | `true` / `true` |
