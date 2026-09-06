# Ship the crosswalk's routine table inside the package.
#
# The vignette and xhelp() both need it, and neither can reach into the book
# repo: a vignette has to build on a machine that has only the package, and
# xhelp() has to work for an installed user. So the table is extracted here and
# committed as csv.
#
# Implemented-or-planned is deliberately NOT recorded. It changes every time a
# routine lands, and a status frozen into a csv would start lying immediately;
# both readers work it out at run time from what the package actually exports.
#
#   source("data-raw/make-crosswalk.R")

crosswalk <- "C:/Users/sborg2/GitHub/asnr2e/crosswalk/ASNR2e_routine_crosswalk_v1.xlsx"
sheet <- readxl::read_excel(crosswalk, sheet = "Routines", .name_repair = "minimal")

pick <- function(x) {
  x <- as.character(x)
  x[is.na(x)] <- ""
  trimws(x)
}

# The 2.0 column is prose in places - "xdegree etc. with mode=", "xjoin,
# xunpack" - so the primary function name is pulled out for looking up and
# printing, and the cell is kept as written for the vignette.
primary <- function(x) {
  vapply(x, function(cell) {
    hits <- regmatches(cell, gregexpr("\\b[a-z_][a-z0-9_.]*\\b", cell))[[1]]
    hits <- setdiff(hits, c("none", "data", "print", "load", "or", "and", "the",
                            "etc", "with", "as", "via", "on", "by", "to"))
    if (length(hits)) hits[1] else ""
  }, character(1), USE.NAMES = FALSE)
}

raw_2 <- pick(sheet[["Proposed xucinet 2.0 name"]])
tbl <- data.frame(
  chapter    = pick(sheet[["Ch"]]),
  section    = pick(sheet[["3e section"]]),
  topic      = pick(sheet[["Topic"]]),
  menu       = pick(sheet[["UCINET routine (3e menu path)"]]),
  name_1e    = pick(sheet[["xUCINET 0.x name (ASNR 1e)"]]),
  name_2     = primary(raw_2),
  name_2_raw = raw_2,
  signature  = pick(sheet[["Proposed signature"]]),
  stringsAsFactors = FALSE
)

# Rows with no 2.0 name are notes to ourselves, not routines a reader can look
# up. The chapter-0 rows are the 0.x-only exports, which belong to the alias
# layer rather than to the menu crosswalk.
tbl <- tbl[nzchar(tbl$name_2) & tbl$chapter != "0", ]
tbl <- tbl[order(suppressWarnings(as.numeric(tbl$chapter)), tbl$section), ]

dir.create("inst/extdata", showWarnings = FALSE, recursive = TRUE)
utils::write.csv(tbl, "inst/extdata/crosswalk-routines.csv", row.names = FALSE)
cat("wrote inst/extdata/crosswalk-routines.csv:", nrow(tbl), "routines,",
    length(unique(tbl$chapter)), "chapters\n")
