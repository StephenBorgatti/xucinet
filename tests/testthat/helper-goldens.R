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
  check_golden_version(family)
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

# ---- the reference UCINET version -------------------------------------------
#
# The package tracks one UCINET build at a time, declared in DESCRIPTION as
# Config/ucinet/reference. Every family of fixtures records the build that
# produced it in a UCINET-VERSION file beside them, and the two have to agree:
# a fixture from another build is not evidence about the build we claim to
# match. When UCINET fixes something, the reference is bumped and the affected
# fixtures are regenerated - which is one `run make_goldens.txt` per family,
# and the reason the batch files are kept runnable.
#
# The build number cannot live inside the fixture itself. UCINET's ##h header
# records the file-format version (4010 ... 6405) and nothing about the program
# that wrote it, and it leaves the title of a result dataset empty. Recording it
# per folder is the nearest thing available; a header field for it is UCINET
# feature request 9.

reference_ucinet_version <- function() {
  v <- utils::packageDescription("xucinet", fields = "Config/ucinet/reference")
  if (is.na(v)) {
    d <- read.dcf("../../DESCRIPTION")              # source tree, not installed
    v <- if ("Config/ucinet/reference" %in% colnames(d)) {
      d[1, "Config/ucinet/reference"]
    } else NA_character_
  }
  unname(trimws(v))
}

# The build a family of fixtures came from, or NA when the family is exempt.
golden_ucinet_version <- function(family = "density") {
  d <- goldens_dir(family)
  f <- file.path(d, "UCINET-VERSION")
  if (!nzchar(d) || !file.exists(f)) return(NA_character_)
  # read.dcf() returns a named character; the name would defeat identical().
  v <- unname(trimws(read.dcf(f)[1, "UCINET"]))
  if (identical(tolower(v), "n/a")) NA_character_ else v
}

# Fail loudly rather than skip: a fixture family at the wrong build is a stale
# expectation, and skipping would hide it behind a green run.
check_golden_version <- function(family, want = reference_ucinet_version()) {
  got <- golden_ucinet_version(family)
  if (is.na(got)) return(invisible(NULL))          # exempt
  if (!identical(got, want)) {
    stop("goldens in '", family, "' were produced by UCINET ", got,
         " but DESCRIPTION declares ", want, ".\n",
         "  Either regenerate them (run inst/goldens/", family,
         "/make_goldens.txt) or correct Config/ucinet/reference.",
         call. = FALSE)
  }
  invisible(NULL)
}

# ---- tests that deliberately differ from UCINET ------------------------------
#
# Where dev/UCINET-ISSUES.md records a bug UCINET has agreed to fix, xucinet
# implements the correct behaviour rather than reproducing the bug, and the test
# that covers it says so by calling this.
#
# It does two things. It documents, in the test, which issue the difference
# belongs to. And when the reference build is bumped past the build that fixed
# the issue, it fails - naming the issue, the test and the ledger entry that all
# need updating together. Without that, bumping the reference would quietly
# leave a stale ledger entry describing a difference that no longer exists.
expect_differs_from_ucinet <- function(issue, fixed_in = NA_character_) {
  ref <- reference_ucinet_version()
  if (!is.na(fixed_in) &&
      utils::compareVersion(ref, fixed_in) >= 0) {
    testthat::fail(paste0(
      "UCINET issue ", issue, " is marked fixed in ", fixed_in,
      " and the reference build is now ", ref, ".\n",
      "  Regenerate the affected fixtures, move the issue to 'fixed in UCINET ",
      fixed_in, "',\n",
      "  remove its inst/DIFFERENCES.md entry, and drop this call."))
  }
  testthat::succeed()
  invisible(TRUE)
}
