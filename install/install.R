# GeoMx DSP protocol dependency installer
#
# Run from the repository root before rendering the notebooks:
# source("install/install.R")
#
# Package groups were audited from the active stage 0-8 notebooks and src/*.R.
#
# Optional dry run:
# options(geomx.install_dry_run = TRUE)
# source("install/install.R")

options(repos = c(CRAN = "https://cloud.r-project.org"))

dry_run <- isTRUE(getOption("geomx.install_dry_run", FALSE))
install_optional_github <- isTRUE(getOption("geomx.install_optional_github", FALSE))
ncpus <- getOption(
  "Ncpus",
  max(1L, min(6L, parallel::detectCores(logical = TRUE) - 1L))
)
options(Ncpus = ncpus)

message(sprintf("GeoMx protocol dependency installer"))
message(sprintf("R version: %s", getRversion()))
message(sprintf("Parallel install workers: %s", getOption("Ncpus")))
if (dry_run) {
  message("Dry-run mode enabled: packages will be reported but not installed.")
}

cran_packages <- sort(unique(c(
  "BiocManager",
  "circlize",
  "cowplot",
  "doParallel",
  "dplyr",
  "DT",
  "factoextra",
  "formattable",
  "fs",
  "generics",
  "ggcorrplot",
  "ggforce",
  "ggplot2",
  "ggrepel",
  "glue",
  "gplots",
  "here",
  "htmltools",
  "janitor",
  "knitr",
  "lme4",
  "lmerTest",
  "magrittr",
  "matrixStats",
  "performance",
  "pheatmap",
  "purrr",
  "randomcoloR",
  "RColorBrewer",
  "readr",
  "readxl",
  "reshape2",
  "rlang",
  "rmarkdown",
  "rstudioapi",
  "scales",
  "smplot2",
  "statmod",
  "stringr",
  "testthat",
  "tibble",
  "tidyr",
  "tidyverse",
  "VennDiagram",
  "viridis",
  "wesanderson",
  "writexl",
  "xfun"
)))

bioc_packages <- sort(unique(c(
  "Biobase",
  "BiocParallel",
  "clusterProfiler",
  "ComplexHeatmap",
  "DESeq2",
  "edgeR",
  "GeoDiff",
  "GeomxTools",
  "GeoMxWorkflows",
  "limma",
  "NanoStringNCTools",
  "org.Hs.eg.db",
  "PCAtools",
  "RUVSeq",
  "S4Vectors",
  "SpatialDecon",
  "standR",
  "SummarizedExperiment",
  "variancePartition"
)))

optional_github_packages <- c(
  nichenetr = "saeyslab/nichenetr"
)

missing_packages <- function(packages) {
  packages[!vapply(packages, requireNamespace, logical(1), quietly = TRUE)]
}

install_cran <- function(packages) {
  missing <- missing_packages(packages)
  if (length(missing) == 0) {
    message("CRAN packages already installed.")
    return(invisible(character()))
  }

  message("Missing CRAN packages: ", paste(missing, collapse = ", "))
  if (!dry_run) {
    install.packages(missing, Ncpus = getOption("Ncpus"))
  }
  invisible(missing)
}

install_bioc <- function(packages) {
  missing <- missing_packages(packages)
  if (length(missing) == 0) {
    message("Bioconductor packages already installed.")
    return(invisible(character()))
  }

  message("Missing Bioconductor packages: ", paste(missing, collapse = ", "))
  if (!dry_run) {
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      stop("BiocManager is required before installing Bioconductor packages.", call. = FALSE)
    }
    BiocManager::install(missing, ask = FALSE, update = FALSE, Ncpus = getOption("Ncpus"))
  }
  invisible(missing)
}

install_github <- function(packages) {
  if (length(packages) == 0) {
    return(invisible(character()))
  }

  package_names <- names(packages)
  missing <- package_names[!vapply(package_names, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing) == 0) {
    message("Optional GitHub packages already installed.")
    return(invisible(character()))
  }

  message("Missing optional GitHub packages: ", paste(missing, collapse = ", "))
  if (!dry_run) {
    if (!requireNamespace("remotes", quietly = TRUE)) {
      install.packages("remotes", Ncpus = getOption("Ncpus"))
    }
    for (pkg in missing) {
      remotes::install_github(packages[[pkg]], upgrade = "never")
    }
  }
  invisible(missing)
}

install_cran(cran_packages)
install_bioc(bioc_packages)

if (install_optional_github) {
  install_github(optional_github_packages)
} else {
  message(
    "Skipping optional GitHub packages. Set ",
    "options(geomx.install_optional_github = TRUE) before sourcing this script ",
    "to install optional NicheNet helper dependencies."
  )
}

if (!dry_run) {
  required_missing <- c(missing_packages(cran_packages), missing_packages(bioc_packages))
  if (length(required_missing) > 0) {
    stop(
      "Dependency installation finished, but these required packages are still unavailable: ",
      paste(required_missing, collapse = ", "),
      call. = FALSE
    )
  }
  message("Required protocol dependencies are installed.")
}
