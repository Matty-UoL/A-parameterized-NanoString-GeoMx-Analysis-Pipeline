# Notebook 0 — Standardise & merge metadata / LWS

Exact `params:` used for the **GSE226829** exemplar render. This stage cleans the Lab
Worksheet (LWS) / segment-annotation file, optionally merges metadata, and writes the
merged workbook (`Complete_LWS_Metadata.xlsx`) consumed by stage 1.

For GSE226829 there is a single LWS/annotation file and no separate metadata file, so the
merge step degrades gracefully to an LWS-only output.

## Dataset-specific

| Parameter | Value | Notes |
|---|---|---|
| `lws_input_file` | `GSE226829_PreQC_segments_annotation.xlsx` | The segment annotation workbook placed in `Data/Individual_Readout_Groups/`. |
| `lws_input_files` | `value: []` | Unused (single input file). |
| `metadata_input_file` | `""` | No separate metadata file for this dataset. |
| `lws_link_column` | `AUTO` | No merge needed (LWS-only); AUTO is a no-op here. |
| `metadata_link_column` | `AUTO` | As above. |
| `segment_column_name` | `segment` | Column checked by the segment-naming QA. |

## Analysis / QA parameters

| Parameter | Value | Notes |
|---|---|---|
| `check_segment_naming` | `true` | Emit warnings for non-canonical / case-variant segment labels. |
| `warn_on_case_variants` | `true` | Flag case-only segment label variants. |

## I/O & structural

| Parameter | Value |
|---|---|
| `project_root` | `.` |
| `portable_path_limit` | `200` |
| `dir_src` | `src` |
| `data_dir_name` | `Data` |
| `individual_readout_group_dir_name` | `Individual_Readout_Groups` |
| `metadata_dir_name` | `Metadata` |
| `outputs_dir_name` | `Outputs` |
| `clean_merge_output_dir_name` | `0_Clean_And_Merge` |
| `cleaned_output_dir_name` | `Cleaned` |
| `final_merged_filename` | `Complete_LWS_Metadata.xlsx` |
