# Portable path helpers for the staged GeoMx protocol pipeline.
#
# These functions intentionally use base R only so every notebook can source
# them before loading analysis-specific packages. The default 200-character
# budget leaves a small margin below the traditional Windows MAX_PATH limit for
# R packages and graphics devices that do not consistently support long paths.

protocol_validate_path_limit <- function(path_limit = 200L) {
  path_limit <- suppressWarnings(as.integer(path_limit))
  if (length(path_limit) != 1L || is.na(path_limit) || path_limit < 120L) {
    stop("`portable_path_limit` must be one integer of at least 120.", call. = FALSE)
  }
  path_limit
}

protocol_path_length <- function(path) {
  path <- as.character(path)
  nchar(enc2utf8(path), type = "chars", allowNA = TRUE)
}

protocol_file_hash <- function(...) {
  key <- paste(vapply(list(...), as.character, character(1)), collapse = "|")
  values <- utf8ToInt(enc2utf8(key))
  if (length(values) == 0L) {
    return("000000000000000000")
  }

  # Two independent base-R polynomial (Horner) rolling hashes, concatenated into
  # 18 digits. A Horner hash weights each character by base^position, so it mixes
  # far better than a linear weighted sum: structured filenames that differ only
  # in a few characters (e.g. "contrast_0001..." vs "contrast_0002...") no longer
  # collapse to the same value. Each step stays well within double precision
  # (mod < 1e9, base <= 257, so h * base < 2.6e11), keeping the helper dependency
  # -free since it is sourced before analysis packages load.
  horner_hash <- function(vals, base, modulus) {
    h <- 0
    for (v in vals) {
      h <- (h * base + v + 1) %% modulus
    }
    h
  }
  checksum1 <- horner_hash(values, base = 257, modulus = 999999937)
  checksum2 <- horner_hash(values, base = 131, modulus = 999999733)
  sprintf("%09.0f%09.0f", checksum1, checksum2)
}

protocol_sanitize_file_stem <- function(stem, fallback = "file") {
  stem <- enc2utf8(as.character(stem)[1])
  stem <- gsub("[^A-Za-z0-9_.-]+", "_", stem, perl = TRUE)
  stem <- gsub("_+", "_", stem, perl = TRUE)
  stem <- gsub("^[_.-]+|[_.-]+$", "", stem, perl = TRUE)
  if (!nzchar(stem)) fallback else stem
}

protocol_path_resolution <- function(path) {
  data.frame(
    original_path = attr(path, "protocol_original_path", exact = TRUE) %||% as.character(path),
    resolved_path = as.character(path),
    shortened = isTRUE(attr(path, "protocol_shortened", exact = TRUE)),
    stringsAsFactors = FALSE
  )
}

`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0L) y else x
}

protocol_output_path <- function(directory,
                                 filename,
                                 path_limit = 200L,
                                 minimum_prefix_chars = 3L,
                                 announce = TRUE) {
  path_limit <- protocol_validate_path_limit(path_limit)
  directory <- as.character(directory)[1]
  filename <- basename(as.character(filename)[1])
  original_path <- file.path(directory, filename)

  if (protocol_path_length(original_path) <= path_limit) {
    attr(original_path, "protocol_original_path") <- original_path
    attr(original_path, "protocol_shortened") <- FALSE
    return(original_path)
  }

  extension <- tools::file_ext(filename)
  extension_suffix <- if (nzchar(extension)) paste0(".", extension) else ""
  stem <- if (nzchar(extension)) tools::file_path_sans_ext(filename) else filename
  clean_stem <- protocol_sanitize_file_stem(stem)
  hash_suffix <- paste0("_", protocol_file_hash(filename))
  available_filename_chars <- path_limit - protocol_path_length(directory) - 1L
  available_stem_chars <- available_filename_chars - nchar(hash_suffix) - nchar(extension_suffix)

  if (available_stem_chars < minimum_prefix_chars) {
    excess <- minimum_prefix_chars - available_stem_chars
    stop(
      sprintf(
        paste0(
          "The output directory is too long for a portable hashed filename.\n",
          "Directory: %s\nPortable limit: %d characters\n",
          "Shorten `project_root` or the configured output folders by at least %d character(s)."
        ),
        directory,
        path_limit,
        excess
      ),
      call. = FALSE
    )
  }

  shortened_filename <- paste0(
    substr(clean_stem, 1L, available_stem_chars),
    hash_suffix,
    extension_suffix
  )
  resolved_path <- file.path(directory, shortened_filename)
  attr(resolved_path, "protocol_original_path") <- original_path
  attr(resolved_path, "protocol_shortened") <- TRUE

  if (isTRUE(announce)) {
    message(
      "Shortened an output filename for portable path handling: ",
      basename(original_path), " -> ", basename(resolved_path)
    )
  }
  resolved_path
}

protocol_contract_path <- function(directory,
                                   filename,
                                   path_limit = 200L,
                                   label = "Pipeline contract file") {
  path_limit <- protocol_validate_path_limit(path_limit)
  contract_path <- file.path(as.character(directory)[1], basename(as.character(filename)[1]))
  path_chars <- protocol_path_length(contract_path)

  if (path_chars > path_limit) {
    stop(
      sprintf(
        paste0(
          "%s exceeds the portable path budget.\nPath: %s\n",
          "Path length: %d characters; portable limit: %d characters.\n",
          "This filename is a stage contract and will not be renamed automatically. ",
          "Shorten `project_root` or the configured folder names by at least %d character(s)."
        ),
        label,
        contract_path,
        path_chars,
        path_limit,
        path_chars - path_limit
      ),
      call. = FALSE
    )
  }
  contract_path
}

protocol_safe_directory <- function(parent,
                                    component,
                                    path_limit = 200L,
                                    filename_reserve = 24L) {
  path_limit <- protocol_validate_path_limit(path_limit)
  parent <- as.character(parent)[1]
  component <- protocol_sanitize_file_stem(component, fallback = "output")
  original_path <- file.path(parent, component)
  maximum_directory_chars <- path_limit - as.integer(filename_reserve) - 1L

  if (protocol_path_length(original_path) <= maximum_directory_chars) {
    return(original_path)
  }

  hash_suffix <- paste0("_", protocol_file_hash(component))
  available_component_chars <- maximum_directory_chars - protocol_path_length(parent) - 1L - nchar(hash_suffix)
  if (available_component_chars < 3L) {
    stop(
      "The parent output directory leaves insufficient room for a portable subdirectory and filename: ",
      parent,
      call. = FALSE
    )
  }

  file.path(parent, paste0(substr(component, 1L, available_component_chars), hash_suffix))
}

protocol_path_audit <- function(paths,
                                path_limit = 200L,
                                filename_reserve = 24L) {
  path_limit <- protocol_validate_path_limit(path_limit)
  labels <- names(paths)
  paths <- as.character(paths)
  if (is.null(labels)) labels <- rep("Path", length(paths))
  labels[!nzchar(labels)] <- "Path"
  path_chars <- protocol_path_length(paths)
  remaining <- path_limit - path_chars

  data.frame(
    path_role = labels,
    resolved_path = paths,
    path_characters = path_chars,
    remaining_characters = remaining,
    status = ifelse(
      remaining < 0L,
      "Blocked",
      ifelse(remaining < filename_reserve, "Limited headroom", "Portable")
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

protocol_assert_audit <- function(audit_table, path_limit = 200L) {
  blocked <- audit_table[audit_table$status == "Blocked", , drop = FALSE]
  if (nrow(blocked) == 0L) return(invisible(audit_table))

  worst <- blocked[which.max(blocked$path_characters), , drop = FALSE]
  stop(
    sprintf(
      paste0(
        "A required pipeline path exceeds the portable path budget.\n",
        "Path: %s\nPath length: %d; portable limit: %d.\n",
        "Shorten `project_root` or the configured folder names before continuing."
      ),
      worst$resolved_path[[1]],
      worst$path_characters[[1]],
      protocol_validate_path_limit(path_limit)
    ),
    call. = FALSE
  )
}

protocol_resolve_input_dir <- function(preferred,
                                       legacy = character(),
                                       label = "input directory",
                                       must_exist = TRUE) {
  candidates <- unique(c(as.character(preferred)[1], as.character(legacy)))
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  existing <- candidates[dir.exists(candidates)]

  if (length(existing) > 0L) {
    selected <- existing[[1]]
    source_type <- if (identical(selected, candidates[[1]])) "configured" else "legacy"
    attr(selected, "protocol_source") <- source_type
    if (identical(source_type, "legacy")) {
      message("Using legacy ", label, ": ", selected)
    }
    return(selected)
  }

  if (isTRUE(must_exist)) {
    stop(
      "Could not find the ", label, ". Checked:\n- ",
      paste(candidates, collapse = "\n- "),
      call. = FALSE
    )
  }

  selected <- candidates[[1]]
  attr(selected, "protocol_source") <- "configured_missing"
  selected
}

protocol_resolve_existing_file <- function(preferred, legacy = character()) {
  candidates <- unique(c(as.character(preferred)[1], as.character(legacy)))
  candidates <- candidates[!is.na(candidates) & nzchar(candidates)]
  existing <- candidates[file.exists(candidates)]
  if (length(existing) > 0L) existing[[1]] else candidates[[1]]
}
