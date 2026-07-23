


# Accessible colour system for protocol figures
# -----------------------------------------------------------------------------
# Every figure in the pipeline draws from one colourblind-safe colour system,
# applied according to the type of data being shown:
#   * Categorical groups (segments, conditions, methods, patients, ...) use the
#     Okabe-Ito qualitative palette via protocol_discrete_palette(). Fixed,
#     two/three-class semantic scales (e.g. probe class, DE direction) use named
#     Okabe-Ito colours from protocol_okabe_ito().
#   * Sequential single-direction magnitudes (detection rate, abundance,
#     proportions, -log10 FDR, ...) use viridis option "C", applied directly via
#     ggplot2::scale_*_viridis_c(option = "C") or a circlize viridis ramp.
#   * Genuinely divergent / bidirectional values (correlation, signed scores)
#     use protocol_divergent_palette(): Okabe-Ito blue -> near-white -> vermillion.
# Okabe-Ito is a categorical palette, so continuous figures cannot literally use
# it; viridis and the Okabe-Ito-derived divergent ramp keep continuous figures in
# the same accessible system.

# Named Okabe-Ito colours: single source of truth for fixed/semantic colour roles.
protocol_okabe_ito <- function() {
  c(
    black          = "#000000",
    orange         = "#E69F00",
    sky_blue       = "#56B4E9",
    bluish_green   = "#009E73",
    yellow         = "#F0E442",
    blue           = "#0072B2",
    vermillion     = "#D55E00",
    reddish_purple = "#CC79A7",
    grey           = "#999999"
  )
}

# Accessible divergent endpoints for genuinely bidirectional continuous data.
# Returns a named vector usable with ggplot2::scale_*_gradient2(low, mid, high).
protocol_divergent_palette <- function() {
  oi <- protocol_okabe_ito()
  c(low = unname(oi[["blue"]]), mid = "#F7F7F7", high = unname(oi[["vermillion"]]))
}

# Ordered categorical colour sequence for protocol figures. This is the Okabe-Ito
# palette with black reserved (black is kept for text, reference lines, and
# outlines, not used as a data category colour because it reads as "default" and
# uncoloured) and the two lowest-contrast colours on white (yellow, grey) moved to
# the end so small category sets receive the strongest, most distinct colours first.
protocol_categorical_colours <- function() {
  oi <- protocol_okabe_ito()
  unname(oi[c("orange", "sky_blue", "bluish_green", "blue",
              "vermillion", "reddish_purple", "yellow", "grey")])
}

# Shared colorblind-accessible discrete palette for protocol figures.
protocol_discrete_palette <- function(levels,
                                      palette = "Okabe-Ito",
                                      fallback_level = "Not recorded") {
  clean_levels <- unique(trimws(as.character(levels)))
  clean_levels <- clean_levels[!is.na(clean_levels) & nzchar(clean_levels)]

  if (length(clean_levels) == 0) {
    clean_levels <- fallback_level
  }

  # Default Okabe-Ito uses the black-reserved categorical sequence; any other
  # named palette falls back to grDevices::palette.colors().
  base_palette <- if (identical(palette, "Okabe-Ito")) {
    protocol_categorical_colours()
  } else {
    tryCatch(
      unname(grDevices::palette.colors(palette = palette)),
      error = function(e) protocol_categorical_colours()
    )
  }

  n_levels <- length(clean_levels)
  if (n_levels <= length(base_palette)) {
    colors <- base_palette[seq_len(n_levels)]
  } else {
    colors <- grDevices::colorRampPalette(base_palette)(n_levels)
  }

  stats::setNames(colors, clean_levels)
}


# DCC input reader for protocol workflows.
# Policy: accept one or more zip archives containing either:
# - raw `.dcc` files, or
# - compressed `.dcc.gz` files
# The function extracts to a deterministic staging folder and returns `.dcc`
# paths for downstream matching.
read_dcc_files <- function(dir_dcc,
                           dir_rawdata,
                           dcc_zip_name = "",
                           dcc_zip_names = NULL,
                           clean_stage = FALSE,
                           path_limit = 200L) {

  # Ensure staging directories exist for deterministic downstream behavior.
  fs::dir_create(dir_dcc, recurse = TRUE)
  fs::dir_create(dir_rawdata, recurse = TRUE)

  explicit_name <- as.character(dcc_zip_name)[1]
  if (is.na(explicit_name)) explicit_name <- ""
  explicit_name <- trimws(explicit_name)

  explicit_names <- as.character(unlist(dcc_zip_names))
  explicit_names <- trimws(explicit_names)
  explicit_names <- explicit_names[!is.na(explicit_names) & nzchar(explicit_names)]

  # Guardrail for novice users: dcc_zip_name accepts one filename only.
  if (grepl("[,;]", explicit_name)) {
    stop(
      "`dcc_zip_name` accepts one filename only.\n",
      "If you want multiple zip files, use `dcc_zip_names` in YAML.\n",
      "Example:\n",
      "dcc_zip_names:\n",
      "  value: [\"run_01.zip\", \"run_02.zip\"]"
    )
  }

  # Conflict guard: choose either singular or plural parameter, not both.
  if (nzchar(explicit_name) && length(explicit_names) > 0) {
    stop(
      "Use either `dcc_zip_name` (single zip) OR `dcc_zip_names` (multiple zips), not both."
    )
  }

  all_zip_candidates <- fs::dir_ls(dir_dcc, regexp = "(?i)\\.zip$", type = "file")
  if (length(all_zip_candidates) == 0) {
    stop(
      "No DCC zip archive was found in: ", dir_dcc, "\n",
      "Add one or more `.zip` files containing `.dcc` files, then rerun."
    )
  }

  # Selection logic:
  # 1) dcc_zip_names -> user-selected multiple zips
  # 2) dcc_zip_name  -> user-selected single zip
  # 3) auto-detect only when exactly one zip exists
  if (length(explicit_names) > 0) {
    invalid_ext <- explicit_names[!grepl("(?i)\\.zip$", explicit_names)]
    if (length(invalid_ext) > 0) {
      stop("All `dcc_zip_names` entries must end with `.zip`:\n", paste(invalid_ext, collapse = "\n"))
    }
    zip_files <- fs::path(dir_dcc, explicit_names)
  } else if (nzchar(explicit_name)) {
    if (!grepl("(?i)\\.zip$", explicit_name)) {
      stop(
        "`dcc_zip_name` must end with `.zip`.\n",
        "Example: dcc_zip_name: \"my_run_dcc.zip\""
      )
    }
    zip_files <- fs::path(dir_dcc, explicit_name)
  } else if (length(all_zip_candidates) == 1) {
    zip_files <- all_zip_candidates
  } else {
    stop(
      "Multiple DCC zip files were found in: ", dir_dcc, "\n",
      "Choose one zip with `dcc_zip_name`, or choose several with `dcc_zip_names`.\n",
      "Found:\n", paste(all_zip_candidates, collapse = "\n")
    )
  }

  missing <- zip_files[!fs::file_exists(zip_files)]
  if (length(missing) > 0) {
    stop("Configured DCC zip file(s) not found:\n", paste(missing, collapse = "\n"))
  }

  # Keep the extraction tree deliberately shallow. Archive-internal directory
  # names can otherwise consume most of the Windows path budget before the DCC
  # filename is reached.
  dcc_stage_dir <- fs::path(dir_rawdata, "dcc")

  if (isTRUE(clean_stage) && fs::dir_exists(dcc_stage_dir)) {
    fs::dir_delete(dcc_stage_dir)
  }
  fs::dir_create(dcc_stage_dir, recurse = TRUE)

  for (zip_file in zip_files) {
    archive_inventory <- utils::unzip(zipfile = zip_file, list = TRUE)
    member_names <- archive_inventory$Name[
      grepl("(?i)\\.dcc(?:\\.gz)?$", archive_inventory$Name, perl = TRUE)
    ]

    if (length(member_names) == 0L) {
      stop(
        "The selected archive contains no `.dcc` or `.dcc.gz` files: ",
        zip_file,
        call. = FALSE
      )
    }

    member_basenames <- basename(member_names)
    # Normalise a trailing .gz before the collision check so a raw `sample.dcc` and
    # its gzipped twin `sample.dcc.gz` (which decompresses to the same `sample.dcc`)
    # are detected as a duplicate rather than silently overwriting after extraction.
    collision_basenames <- sub("(?i)\\.gz$", "", member_basenames, perl = TRUE)
    duplicate_basenames <- unique(collision_basenames[
      duplicated(tolower(collision_basenames)) |
        duplicated(tolower(collision_basenames), fromLast = TRUE)
    ])
    if (length(duplicate_basenames) > 0L) {
      stop(
        "The DCC archive contains duplicate filenames in different internal folders. ",
        "Flattening them would overwrite data. Rename or separate these files before rerunning:\n- ",
        paste(duplicate_basenames, collapse = "\n- "),
        call. = FALSE
      )
    }

    archive_stem <- tools::file_path_sans_ext(basename(zip_file))
    archive_component <- if (exists("protocol_sanitize_file_stem", mode = "function")) {
      paste0(
        protocol_sanitize_file_stem(archive_stem, fallback = "archive"),
        "_",
        protocol_file_hash(basename(zip_file))
      )
    } else {
      gsub("[^A-Za-z0-9_.-]+", "_", archive_stem)
    }
    archive_dir <- if (exists("protocol_safe_directory", mode = "function")) {
      protocol_safe_directory(
        dcc_stage_dir,
        archive_component,
        path_limit = path_limit,
        filename_reserve = max(nchar(member_basenames)) + 1L
      )
    } else {
      fs::path(dcc_stage_dir, archive_component)
    }
    fs::dir_create(archive_dir, recurse = TRUE)

    utils::unzip(
      zipfile = zip_file,
      files = member_names,
      exdir = archive_dir,
      junkpaths = TRUE
    )
  }

  # Some providers distribute DCC as `.dcc.gz` members inside the selected zip.
  # Decompress those files in-place so downstream logic can always read `.dcc`.
  dcc_gz_files <- fs::dir_ls(
    dcc_stage_dir,
    recurse = TRUE,
    regexp = "(?i)\\.dcc\\.gz$",
    type = "file"
  )
  if (length(dcc_gz_files) > 0) {
    for (gz_file in dcc_gz_files) {
      output_name <- sub("(?i)\\.gz$", "", basename(gz_file), perl = TRUE)
      out_file <- if (exists("protocol_contract_path", mode = "function")) {
        protocol_contract_path(
          dirname(gz_file),
          output_name,
          path_limit = path_limit,
          label = "Extracted DCC filename"
        )
      } else {
        fs::path(dirname(gz_file), output_name)
      }
      in_con <- gzfile(gz_file, open = "rb")
      out_con <- file(out_file, open = "wb")
      on.exit({
        try(close(in_con), silent = TRUE)
        try(close(out_con), silent = TRUE)
      }, add = TRUE)

      repeat {
        bytes <- readBin(in_con, what = raw(), n = 65536)
        if (length(bytes) == 0) break
        writeBin(bytes, out_con)
      }

      try(close(in_con), silent = TRUE)
      try(close(out_con), silent = TRUE)
    }
  }

  dcc_files <- fs::dir_ls(dcc_stage_dir, recurse = TRUE, regexp = "(?i)\\.dcc$", type = "file")
  if (length(dcc_files) == 0) {
    stop(
      "DCC extraction completed, but no `.dcc` files were detected in: ", dcc_stage_dir, "\n",
      "Confirm the selected zip contains `.dcc` or `.dcc.gz` members (not only folders/logs)."
    )
  }

  sort(unique(dcc_files))
}

# Utility function to summary the QC flags for a NanoStringGeoMxSet
QCSummary <- function(object) {
  # Collate QC Results
  QCResults <- protocolData(object)[["QCFlags"]]
  flag_columns <- colnames(QCResults)
  # drop = FALSE keeps a single-flag-column QC object a data.frame (otherwise it
  # collapses to a vector and colSums() errors).
  flag_matrix <- as.matrix(QCResults[, flag_columns, drop = FALSE])

  # A QC flag can be NA when its underlying metric is undefined (for example, a
  # segment with a missing nuclei count yields NA for the nuclei flag). Treat an
  # NA flag as a failure for both the summary counts and the per-segment status:
  # an NA flag must never be counted as a pass, and QCStatus must never itself be
  # NA. A downstream filter of the form `object[, QCStatus == "PASS"]` indexes the
  # GeoMxSet columns with that logical vector; an NA in it silently corrupts
  # sample names (they collapse to "NA", "NA.1", ...) and later breaks probe QC
  # (setBioProbeQCFlags) with an opaque "no non-missing arguments to min" error.
  QC_Summary <- data.frame(
    Pass    = colSums(!flag_matrix & !is.na(flag_matrix)),
    Warning = colSums(flag_matrix | is.na(flag_matrix))
  )

  QCResults$QCStatus <- apply(flag_matrix, 1L, function(x) {
    # Any undefined (NA) or raised (TRUE) flag fails the segment.
    if (anyNA(x) || sum(x) > 0L) "WARNING" else "PASS"
  })

  QC_Summary["TOTAL FLAGS", ] <-
    c(sum(QCResults[, "QCStatus"] == "PASS"),
      sum(QCResults[, "QCStatus"] == "WARNING"))
  
  
  warn_formatter <- formatter("span", 
                              style = x ~ style( "background-color" = ifelse(x > 0 , "yellow", "white")))
  
  pass_formatter <- formatter("span", 
                              style = x ~ style( "background-color" = ifelse(x > 0 , "lightgreen", "white")))
  
  QCTable <- formattable(QC_Summary, list(Pass=pass_formatter,Warning=warn_formatter),caption = "Summary of QC flags")
  
  return(list(QCResults=QCResults,QCTable=QCTable))
}


# Graphical summaries of QC statistics plot function- taken from the GeoMxWorkflows vignette
QC_histogram <- function(assay_data = NULL,
                         annotation = NULL,
                         fill_by = "segment",
                         thr = NULL,
                         scale_trans = NULL,
                         fill_cols=NULL,
                         font_family = "Segoe UI") {
  if (is.null(assay_data)) {
    stop("QC_histogram requires an assay_data object.", call. = FALSE)
  }
  assay_data <- as.data.frame(assay_data)

  if (is.null(annotation) || length(annotation) != 1L || !nzchar(annotation)) {
    stop("QC_histogram requires one non-empty annotation column name.", call. = FALSE)
  }
  if (is.null(fill_by) || length(fill_by) != 1L || !nzchar(fill_by)) {
    stop("QC_histogram requires one non-empty fill_by column name.", call. = FALSE)
  }

  required_columns <- c(annotation, fill_by)
  missing_columns <- setdiff(required_columns, colnames(assay_data))
  if (length(missing_columns) > 0) {
    stop(
      "QC_histogram could not find required column(s): ",
      paste(missing_columns, collapse = ", "),
      ". Available columns are: ",
      paste(colnames(assay_data), collapse = ", "),
      call. = FALSE
    )
  }

  flatten_qc_column <- function(column, column_name, expected_rows) {
    if (is.data.frame(column)) {
      if (ncol(column) != 1L) {
        stop(
          "QC_histogram expected column '", column_name,
          "' to be a vector or one-column data frame, but found ",
          ncol(column), " columns.",
          call. = FALSE
        )
      }
      column <- column[[1L]]
    }

    if (is.list(column)) {
      column <- unlist(column, use.names = FALSE)
    }

    if (length(column) != expected_rows) {
      stop(
        "QC_histogram could not flatten column '", column_name,
        "' safely. Expected ", expected_rows, " values but found ",
        length(column), " after flattening.",
        call. = FALSE
      )
    }

    column
  }

  assay_data[[annotation]] <- flatten_qc_column(
    assay_data[[annotation]],
    annotation,
    nrow(assay_data)
  )
  assay_data[[fill_by]] <- flatten_qc_column(
    assay_data[[fill_by]],
    fill_by,
    nrow(assay_data)
  )

  annotation_values <- assay_data[[annotation]]
  annotation_numeric <- suppressWarnings(as.numeric(as.character(annotation_values)))
  invalid_annotation <- !is.na(annotation_values) & is.na(annotation_numeric)
  if (any(invalid_annotation)) {
    stop(
      "QC_histogram could not coerce annotation column '", annotation,
      "' to numeric values for histogram plotting.",
      call. = FALSE
    )
  }
  assay_data[[annotation]] <- annotation_numeric

  fill_values <- trimws(as.character(assay_data[[fill_by]]))
  fill_levels <- unique(fill_values[!is.na(fill_values) & nzchar(fill_values)])
  if (!is.null(fill_cols) && !is.null(names(fill_cols))) {
    fill_levels <- unique(c(names(fill_cols), fill_levels))
  }
  assay_data[[fill_by]] <- factor(fill_values, levels = fill_levels)

  if (.Platform$OS.type == "windows" && !is.null(font_family) && nzchar(font_family)) {
    try(
      do.call(
        grDevices::windowsFonts,
        stats::setNames(
          list(grDevices::windowsFont(font_family)),
          font_family
        )
      ),
      silent = TRUE
    )
  }

  plt <- ggplot(assay_data,
                aes(x = .data[[annotation]],
                    fill = .data[[fill_by]])) +
    geom_histogram(bins = 50) +
    geom_vline(xintercept = thr, lty = "dashed", color = "black") +
    theme_bw(base_family = font_family) + guides(fill = "none") +
    facet_wrap(vars(.data[[fill_by]]), nrow = 4) +
    labs(x = annotation, y = "Segments, #", title = annotation)
  if(!is.null(scale_trans)) {
    plt <- plt +
      scale_x_continuous(trans = scale_trans)
  }
  if(!is.null(fill_cols)) {
    plt <- plt +
      scale_fill_manual(values=fill_cols)
  }
  plt
}

# Function to get the results table for a limma contrast
getResultsDataFrame <- function(fit2, contrast, numerator, 
                                denominator) {
  data <- topTable(fit2, coef = contrast, number = Inf, 
                   sort.by = "P")
  #data <- independentFiltering(data, filter = data$AveExpr, objectType = "limma")
  #colnames(data) <- paste(paste(numerator, denominator, sep = "vs"), colnames(data), sep = "_")
  return(data)
}




# Function for PCA correlation plot 

library(PCAtools)

eigencorplotPCA <- function(x, metavars = "", main = "") {
  
  # Wrapper around the PCAtools eigencorplot to use preferred aesthetics
  # Takes as input PCA object from PCAtools and a vector of metavars to measure correlation with
  # The metavars have to be present in the original metadata provided to the PCA object
  
  use_cex <- 16/16
  
  corplot <- PCAtools::eigencorplot(x,
                                    metavars = metavars,
                                    col = c( "blue2", "blue1", "black", "red1", "red2"),
                                    colCorval = "white",
                                    scale = TRUE,
                                    main = main,
                                    plotRsquared = FALSE,
                                    cexTitleX= use_cex,
                                    cexTitleY= use_cex,
                                    cexLabX = use_cex,
                                    cexLabY = use_cex,
                                    cexMain = use_cex,
                                    cexLabColKey = use_cex,
                                    cexCorval = use_cex)
  
  return(corplot)
  
}



#Function to create PCA plot #

library(PCAtools)
library(viridis)
library(ggrepel)

plotPCA <- function(x, PCs="", colours=NULL, colour.data=NULL, shape.data=NULL, sample.lab=F, colour.lab="", shape.lab="", borderWidth = 0.8) {
  
  df_out <- data.frame(PC1=x$rotated[,PCs[1]], PC2=x$rotated[,PCs[2]])
  row.names(df_out) <- row.names(x$rotated)

  # Dynamic shape assignment so PCA plotting works with any number of groups.
  # ggplot has a finite set of clearly distinct point shapes; we recycle a broad
  # base set when there are more levels than symbols.
  shape_values <- NULL
  if (!is.null(shape.data)) {
    shape_levels <- levels(factor(shape.data))
    base_shapes <- c(19, 15, 17, 18, 1, 2, 0, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14)
    shape_values <- rep(base_shapes, length.out = length(shape_levels))
    names(shape_values) <- shape_levels
  }
  
  
  if(!is.null(colour.data) & !is.null(shape.data)){
    
    if(!is.null(colours)){
      
      if(is.factor(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data, shape=shape.data)) +
          geom_point(size = 3.5) +
          scale_color_manual(values=colours) +
          scale_shape_manual(values=shape_values) +
          labs(colour = colour.lab, shape = shape.lab)
        
        
      } else if(is.numeric(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data, shape=shape.data)) +
          geom_point(size = 3.5) +
          scale_color_gradientn(colours = colours) +
          scale_shape_manual(values=shape_values) +
          labs(colour = colour.lab, shape = shape.lab)
        
      } else {
        
        stop("Error: Colour data must be type 'numeric' or 'factor'.")
        
      }
      
    } else {
      
      if(is.factor(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data, shape=shape.data)) +
          geom_point(size = 3.5) +
          scale_color_manual(values = protocol_discrete_palette(levels(factor(colour.data)))) +
          scale_shape_manual(values=shape_values) +
          labs(colour = colour.lab, shape = shape.lab)
        
      } else if(is.numeric(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data, shape=shape.data)) +
          geom_point(size = 3.5) +
          scale_color_viridis(option = "plasma") +
          scale_shape_manual(values=shape_values) +
          labs(colour = colour.lab, shape = shape.lab)
        
      } else {
        
        stop("Error: Colour data must be type 'numeric' or 'factor'.")
        
      }
      
    }
    
    
    
  } else if(!is.null(colour.data) & is.null(shape.data)) {
    
    if(!is.null(colours)){
      
      if(is.factor(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data)) +
          geom_point(size = 3.5) +
          scale_color_manual(values=colours) +
          labs(colour = colour.lab)
        
      } else if(is.numeric(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data)) +
          geom_point(size = 3.5) +
          scale_color_gradientn(colours = colours) +
          labs(colour = colour.lab)
        
      } else {
        
        stop("Error: Colour data must be type 'numeric' or 'factor'.")
        
      }
      
    } else {
      
      if(is.factor(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data)) +
          geom_point(size = 3.5) +
          scale_color_manual(values = protocol_discrete_palette(levels(factor(colour.data)))) +
          labs(colour = colour.lab)
        
      } else if(is.numeric(colour.data)){
        
        pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2, colour = colour.data)) +
          geom_point(size = 3.5) +
          scale_color_viridis(option = "plasma") +
          labs(colour = colour.lab)
        
      } else {
        
        stop("Error: Colour data must be type 'numeric' or 'factor'.")
        
      }
      
    }
    
    
    
  } else {
    
    pca_plot <- ggplot(df_out, aes(x=PC1, y=PC2)) +
      geom_point(size = 3.5)
    
  }
  
  
  pca_plot <- pca_plot +
    xlab(paste0('PC', PCs[1], ': ', round(as.numeric(x$variance[PCs[1]])), '% expl.var')) +
    ylab(paste0('PC', PCs[2], ': ', round(as.numeric(x$variance[PCs[2]])), '% expl.var')) +
    #lims(x= c(min(df_out[,"PC1"])-20, max(df_out[,"PC1"])+20), y = c(min(df_out[,"PC2"])-20, max(df_out[,"PC2"])+20)) +
    theme_cowplot()
  
  
  if(sample.lab){
    
    pca_plot <- pca_plot + geom_text_repel(aes(label = row.names(df_out), size = NULL, color = NULL),
                                           check_overlap = T,
                                           size = 3.0
    )
    
  }
  
  return(pca_plot)
  
}






# Function to create volcano plot

plotVolcano <- function(x,
                        title = "",
                        top.genes = NULL,
                        point.size = 0.9,
                        lab.size = 3,
                        quadrants = FALSE,
                        foldChangeColumn = "logFC",
                        FDRColumn = "adj.P.Val",
                        adj.p.cutoff = 0.05,
                        logFC.cutoff = 0.5) {

  if (!is.numeric(adj.p.cutoff) || length(adj.p.cutoff) != 1L ||
      !is.finite(adj.p.cutoff) || adj.p.cutoff <= 0 || adj.p.cutoff >= 1) {
    stop("adj.p.cutoff must be one finite number between 0 and 1.")
  }

  if (!is.numeric(logFC.cutoff) || length(logFC.cutoff) != 1L ||
      !is.finite(logFC.cutoff) || logFC.cutoff < 0) {
    stop("logFC.cutoff must be one finite, non-negative number.")
  }
  
  x <- x %>%
    rownames_to_column(var = "Genes") %>%
    # Rename columns to be consistent
    rename("logFC" = all_of(foldChangeColumn), "adj.P.Val" = all_of(FDRColumn)) %>%
    # Apply one threshold definition to point colors, labels, and guide lines.
    mutate(
      Expression = case_when(logFC > logFC.cutoff & adj.P.Val < adj.p.cutoff ~ "Up-regulated",
                             logFC < -logFC.cutoff & adj.P.Val < adj.p.cutoff ~ "Down-regulated",
                             TRUE ~ "Unchanged")
    )
  
  x$Expression <- factor(x$Expression, levels=c("Down-regulated", "Unchanged", "Up-regulated"))
  # Accessible DE-direction colours (Okabe-Ito): blue = down, grey = unchanged,
  # vermillion = up. Matches the factor level order above and keeps the volcano
  # consistent with the DE summary bars (DEResPlot) and the divergent heatmap ramp.
  myColors <- unname(protocol_okabe_ito()[c("blue", "grey", "vermillion")])
  names(myColors) <- levels(x$Expression)

  
  
  volcano_plot <- ggplot(x, aes(logFC, -log(adj.P.Val, 10))) + # -log10 conversion
    geom_point(aes(color = Expression), size = point.size) +
    xlab(expression("log"[2]*"FC")) +
    ylab(expression("-log"[10]*"FDR")) + 
    scale_color_manual(name = "Expression",values = myColors) +
    theme_cowplot() + 
    ggtitle(title) + 
    theme(legend.position="none")
  
  
  if(quadrants){
    
    volcano_plot <- volcano_plot +
      geom_hline(yintercept = -log10(adj.p.cutoff),
                 linetype = "dashed") + 
      geom_vline(xintercept = unique(c(-logFC.cutoff, logFC.cutoff)),
                 linetype = "dashed")  
    
  }

  if(!is.null(top.genes)){
    
    top_genes <- bind_rows(
      x %>% 
        filter(Expression == 'Up-regulated') %>% 
        arrange(adj.P.Val, desc(abs(logFC))) %>% 
        head(top.genes),
      x %>% 
        filter(Expression == 'Down-regulated') %>% 
        arrange(adj.P.Val, desc(abs(logFC))) %>% 
        head(top.genes)
    )
    
    
    volcano_plot <- volcano_plot +
      #geom_label_repel(data = top_genes, mapping = aes(logFC, -log(adj.P.Val,10), label = Genes), size = lab.size, force = 1,
      #                 nudge_y = 0.2)
      geom_text_repel(
        data = top_genes,
        aes(label = Genes),
        size = lab.size,
        max.overlaps = Inf,
        min.segment.length = 0,
        seed = 42
      )
    
  }
  
  
  return(volcano_plot)
  
  
}




# Function to create barplot and table of # of DE genes per contrast 
# Partially adapted from code provided by Lauren Mee (CBF)
# res_list is a list of results generated from a series of contrasts of interest
# 'foldChangeColumn' and 'FDRColumn' are the relevant columns containing the log2FC and adjusted p.values for each object in the results list
# stains is a character vector relevant for spatial transcriptomics experiments
#   It contains the stains you want to facet the plot by
#   Each stain must be seperated by "|" e.g. "CD45|CD31|PanCK|Stroma"
# Example:
#   DEResPlot(limma_GeoDiff_results_table, foldChangeColumn="logFC", FDRColumn="adj.P.Val", stains=c("CD45|CD31|PanCK|Stroma"))

DEResPlot <- function(res_list, foldChangeColumn="logFC", FDRColumn="adj.P.Val", stains=NULL, title="", adj.p.cutoff=0.05, logfc.cutoff=0){

  # Create dataframe from results list
  for (i in seq_along(res_list)){
    contrast <- names(res_list)[[i]]
    
    res_list[[i]] <- res_list[[i]] %>%
      # Rename columns to be consistent
      rename("logFC" = all_of(foldChangeColumn), "adj.P.Val" = all_of(FDRColumn)) %>%
      # Record whether genes are up or down regulated. Direction is a factor with
      # both levels so the Up/Down columns always exist after table(), even when a
      # contrast has significant genes in only one direction.
      mutate(Direction = factor(ifelse(logFC > 0, "Up", "Down"), levels = c("Up", "Down")), Contrast = contrast) %>%
      rownames_to_column(var = "Genes")
  }
  
  # Combine all results
  res <- bind_rows(res_list) %>%
    # Convert contrast to factor so any cases of there being no sig genes
    # Are not lost once genes are filtered by significance
    mutate(Contrast = as.factor(Contrast)) %>%
    # Filter by significance using the configured thresholds (adjusted P AND
    # absolute logFC), so the bars match the count tables and figure captions.
    filter(adj.P.Val < adj.p.cutoff, abs(logFC) > logfc.cutoff) %>%
    # Make note of numbers of DEGs per contrast per direction of expression
    select(Contrast, Direction) %>%
    table(.)

  # Make a dataframe from the above information. as.data.frame.matrix preserves the
  # contrast row names even when only one contrast survives (data.frame(res[,"Up"])
  # would drop them to "1" and mislabel the figure).
  results <- as.data.frame.matrix(res) %>%
    tibble::rownames_to_column(var = "Contrast")
  
  
  # Create barplots from the dataframe containing number of DE genes
  # If no stain information is provided all contrasts will be plotted together
  if(is.null(stains)){
    
    plotdf <- suppressMessages(reshape2::melt(results))
    for (i in seq_len(nrow(plotdf))){
      if(plotdf$variable[i] == "Down"){
        if(plotdf$value[i] > 0){
          plotdf$value[i] <- plotdf$value[i] * -1
        }
      }
    }
    
    p <- ggplot(plotdf, aes(x = Contrast, y = value)) +
      geom_bar(stat = "identity", aes(fill = variable)) +
      theme_bw(base_size = 13) +
      labs(y = "Number Significantly DE Genes",
           fill = "Expression Direction") +
      scale_fill_manual(values = c("Up" = unname(protocol_okabe_ito()[["vermillion"]]),
                                   "Down" = unname(protocol_okabe_ito()[["blue"]]))) +
      theme(legend.position = "bottom") +
      ggtitle(title)
  }
  
  # If stain information is provided the plots will be faceted depending on the stain
  else{
    
    # Add new column based off stain
    plotdf <- results %>% 
      mutate("Stain" = str_extract(.$Contrast, stains)) 
    
    # Remove rows that don't have any genes up/down regulated or don't have a matching stain
    plotdf <- suppressMessages(reshape2::melt(plotdf)) %>%
      filter(!is.na(Stain))

    # Make number of down-regulated genes negative in value
    for (i in seq_len(nrow(plotdf))){
      if(plotdf$variable[i] == "Down"){
        if(plotdf$value[i] > 0){
          plotdf$value[i] <- plotdf$value[i] * -1
        }
      }
    }
    
    # Tidy contrasts
    plotdf$Contrast <- str_remove_all(plotdf$Contrast, paste0(stains, "|_"))
    
    # Create plot
    p <- ggplot(plotdf, aes(x = Contrast, y = value)) +
      geom_bar(stat = "identity", aes(fill = variable)) +
      theme_bw(base_size = 13) +
      labs(y = "Number Significantly DE Genes",
           fill = "Expression Direction",
           x = "") +
      scale_fill_manual(values = c("Up" = unname(protocol_okabe_ito()[["vermillion"]]),
                                   "Down" = unname(protocol_okabe_ito()[["blue"]]))) +
      #theme(legend.position = "bottom",
      #      axis.text.x = element_text(angle = 15, vjust = 0.7)) +
      theme(legend.position = "bottom") +
      facet_wrap(~ Stain, ncol = 1, scales="free")
  }
  
  return(list(DEplot = p, DEtable = results))
  
}



