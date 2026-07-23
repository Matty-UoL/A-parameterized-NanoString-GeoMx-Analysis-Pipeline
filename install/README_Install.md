# Installation Guide

Run the dependency installer before rendering the protocol notebooks in a new R environment.

## Recommended Setup

1. Open R from the repository root.
2. Run:

```r
source("install/install.R")
```

The script installs CRAN packages with `install.packages()` and Bioconductor packages with `BiocManager::install()`. It skips packages that are already installed.

The package lists in `install/install.R` were audited against the active stage 0-8 notebooks and shared R helpers in `src/`.


## Notes

- Run the installer from the repository root so relative paths resolve consistently.
- The installer assumes internet access to CRAN, Bioconductor, and optionally GitHub.
- If a package fails to install, read the first package-specific error carefully; compiled packages may require system tools such as Rtools on Windows.
- After installation, render the notebooks in stage order from `0_Clean_Up_Merge_LWS_Metadata.qmd` through `8_Spatial_Deconvolution.qmd`.
