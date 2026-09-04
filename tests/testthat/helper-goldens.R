# Helpers for reading the UCINET-generated golden fixtures.
#
# inst/goldens/density/make_goldens.txt writes each result as a UCINET dataset
# rather than as text, so reading a golden is just xreaducinet() and the numbers
# arrive at full stored precision. A text parser is kept below for the log,
# which is what issue #6 compares the printed report against.

goldens_dir <- function(family = "density") {
  system.file("goldens", family, package = "xucinet")
}

# UCINET upper-cases the dataset names it writes, so a script asking for
# g_campnet_den produces G_CAMPNET_DEN.##h. Windows would not care; Linux CI
# would. Resolve by scanning the folder rather than trusting either spelling.
golden_path <- function(name, family = "density") {
  d <- goldens_dir(family)
  if (!nzchar(d)) return(NA_character_)
  files <- list.files(d, pattern = "[hH]$")
  hit <- match(tolower(paste0(name, ".##h")), tolower(files))
  if (is.na(hit)) return(NA_character_)
  file.path(d, sub("\\.##[hH]$", "", files[hit]))
}

golden_exists <- function(name, family = "density") {
  !is.na(golden_path(name, family))
}

# Skip rather than fail when the batch has not been run yet: the harness is
# committed before the fixtures exist, and CI must stay green in between.
skip_if_no_golden <- function(name, family = "density") {
  if (!golden_exists(name, family)) {
    testthat::skip(paste0("golden '", name, "' not generated yet - run ",
                          "inst/goldens/", family, "/make_goldens.txt in UCINET"))
  }
}

# The golden as a plain matrix, labels and all.
golden_matrix <- function(name, family = "density") {
  as.matrix(xreaducinet(golden_path(name, family)))
}

# One labelled value out of a golden. UCINET writes these small result datasets
# with the measure names as labels, so ask by name rather than by position:
# a row order that changes between UCINET builds would otherwise pass silently.
golden_value <- function(name, label, family = "density") {
  m <- golden_matrix(name, family)
  hit <- match(tolower(label), tolower(rownames(m)))
  if (!is.na(hit)) return(unname(m[hit, 1]))
  hit <- match(tolower(label), tolower(colnames(m)))
  if (!is.na(hit)) return(unname(m[1, hit]))
  stop("'", label, "' is not a row or column of golden '", name, "'.\n",
       "  rows: ", paste(rownames(m), collapse = ", "), "\n",
       "  cols: ", paste(colnames(m), collapse = ", "), call. = FALSE)
}

# Pull the numbers out of a UCINET log. Used for the printed-report comparison,
# and as a fallback for any routine whose CLI form will not write a dataset.
# Returns a named numeric vector: every "Label   1.234" line in the block.
parse_golden_log <- function(path) {
  lines <- readLines(path, warn = FALSE)
  hits <- regmatches(lines, regexec(
    "^\\s*([A-Za-z][A-Za-z0-9 .#/_-]*?)\\s{2,}(-?[0-9]+\\.?[0-9]*(?:[eE][-+]?[0-9]+)?)\\s*$",
    lines))
  hits <- Filter(function(h) length(h) == 3L, hits)
  if (!length(hits)) return(stats::setNames(numeric(0), character(0)))
  stats::setNames(as.numeric(vapply(hits, `[`, character(1), 3)),
                  trimws(vapply(hits, `[`, character(1), 2)))
}
