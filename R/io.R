#' Read a network from a file
#'
#' One importer for every file type the book uses. The *file type* (the
#' container) is detected from the extension; the *layout* (how the data are
#' arranged inside it) is detected from the shape of what is read. Both can be
#' overridden.
#'
#' @param file Path to the file. For UCINET datasets give either the `.##h` file
#'   or the name without extension.
#' @param filetype One of `"ucinet"` (`.##h`/`.##d`), `"uci"` (JSON), `"dl"`,
#'   `"csv"`, `"xlsx"`, `"vna"`; `NULL` detects from the extension.
#' @param layout One of `"matrix"`, `"edgelist"`, `"nodelist"`; `NULL` detects
#'   from the shape of the data (only relevant for csv/xlsx).
#' @param sheet Sheet name or number for `.xlsx` files.
#' @param labels Logical; does the first row/column hold node labels? (csv/xlsx)
#' @param directed,mode,title Passed to [as_xucinet()].
#' @param ... Reserved.
#' @return An `xucinet` object.
#' @export
xread <- function(file, filetype = NULL, layout = NULL, sheet = 1, labels = TRUE,
                  directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(filetype)) filetype <- detect_filetype(file)
  filetype <- match.arg(tolower(filetype), c("ucinet", "uci", "dl", "csv", "xlsx", "vna"))
  if (is.null(title)) title <- tools::file_path_sans_ext(basename(file))
  raw <- switch(filetype,
    csv    = utils::read.csv(file, header = labels, row.names = if (labels) 1 else NULL,
                             check.names = FALSE, stringsAsFactors = FALSE),
    xlsx   = read_xlsx_df(file, sheet, labels),
    ucinet = stop("xreaducinet() is not implemented yet (Phase 0, issue #3).", call. = FALSE),
    uci    = stop(".uci reader is not implemented yet (Phase 0, issue #4).", call. = FALSE),
    dl     = stop("DL reader is not implemented yet (Phase 0, issue #5).", call. = FALSE),
    vna    = stop("VNA reader is not implemented yet (Phase 0, issue #5).", call. = FALSE)
  )
  if (is.null(layout)) layout <- detect_layout(raw)
  layout <- match.arg(tolower(layout), c("matrix", "edgelist", "nodelist"))
  switch(layout,
    matrix   = as_xucinet(as.matrix(raw), directed = directed, mode = mode, title = title),
    edgelist = xfromedgelist(raw, directed = directed, title = title),
    nodelist = xfromnodelist(raw, directed = directed, title = title)
  )
}

detect_filetype <- function(file) {
  ext <- tolower(tools::file_ext(file))
  if (ext %in% c("##h", "##d") || file.exists(paste0(file, ".##h"))) return("ucinet")
  if (ext == "") stop("Cannot detect the file type of '", file, "'; give filetype=.", call. = FALSE)
  switch(ext, csv = "csv", txt = "csv", xlsx = "xlsx", xls = "xlsx", uci = "uci",
         json = "uci", dl = "dl", vna = "vna",
         stop("Unrecognised extension '.", ext, "'; give filetype=.", call. = FALSE))
}

# A data frame read from csv/xlsx: square numeric with matching names -> matrix;
# 2-3 columns with many rows -> edgelist; otherwise nodelist.
detect_layout <- function(df) {
  numeric_cols <- vapply(df, is.numeric, logical(1))
  if (ncol(df) >= 3 && all(numeric_cols) && nrow(df) == ncol(df)) return("matrix")
  if (ncol(df) %in% 2:3) return("edgelist")
  if (all(numeric_cols) && nrow(df) == ncol(df)) return("matrix")
  "nodelist"
}

read_xlsx_df <- function(file, sheet, labels) {
  if (!requireNamespace("readxl", quietly = TRUE))
    stop("Reading .xlsx files needs the 'readxl' package: install.packages(\"readxl\")", call. = FALSE)
  df <- as.data.frame(readxl::read_excel(file, sheet = sheet, col_names = labels))
  if (labels) { rownames(df) <- df[[1]]; df <- df[-1] }
  df
}

#' Build a network from an edge list
#'
#' @param df A data frame with sender and receiver columns and an optional
#'   weight column.
#' @param from,to,weight Column names or positions.
#' @param directed Logical; `NULL` detects (an edge list is treated as directed
#'   unless every tie appears in both directions).
#' @param title Dataset name.
#' @return An `xucinet` object.
#' @export
xfromedgelist <- function(df, from = 1, to = 2, weight = NULL, directed = NULL, title = NULL) {
  if (is.null(title)) title <- deparse1(substitute(df))
  if (is.null(weight) && ncol(df) >= 3) weight <- 3
  s <- as.character(df[[from]]); r <- as.character(df[[to]])
  w <- if (is.null(weight)) rep(1, nrow(df)) else as.numeric(df[[weight]])
  nodes <- unique(c(s, r))
  m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
  m[cbind(s, r)] <- w
  if (is.null(directed)) directed <- !isSymmetric(unname(m))
  if (!directed) m <- pmax(m, t(m))
  new_xucinet(m, mode = "1-mode", directed = directed, title = title)
}

#' Build a network from a node list
#'
#' A node list has one row per ego: the first column is ego, the remaining
#' columns are the alters ego names (blank or `NA` where unused).
#'
#' @param df A data frame.
#' @param ego Column name or position of the ego column.
#' @param directed Logical; node lists are directed by default.
#' @param title Dataset name.
#' @return An `xucinet` object.
#' @export
xfromnodelist <- function(df, ego = 1, directed = TRUE, title = NULL) {
  if (is.null(title)) title <- deparse1(substitute(df))
  egos <- as.character(df[[ego]])
  alters <- df[-ego]
  s <- rep(egos, ncol(alters)); r <- as.character(unlist(alters, use.names = FALSE))
  keep <- !is.na(r) & nzchar(r)
  el <- data.frame(from = s[keep], to = r[keep], stringsAsFactors = FALSE)
  # keep egos that have no alters as isolates
  nodes <- unique(c(egos, el$to))
  m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
  m[cbind(el$from, el$to)] <- 1
  if (!directed) m <- pmax(m, t(m))
  new_xucinet(m, mode = "1-mode", directed = directed, title = title)
}

#' Save a network to a file
#'
#' @param net A network (any accepted form).
#' @param file Output path. The extension sets the file type unless `filetype`
#'   is given; `.uci` is the default.
#' @param filetype One of `"uci"`, `"ucinet"`, `"dl"`, `"csv"`, `"xlsx"`, `"vna"`.
#' @param ... Reserved.
#' @return `file`, invisibly.
#' @export
xsave <- function(net, file, filetype = NULL, ...) {
  net <- as_xucinet(net)
  if (is.null(filetype)) {
    ext <- tolower(tools::file_ext(file))
    filetype <- if (ext == "") "uci" else detect_filetype(file)
    if (ext == "") file <- paste0(file, ".uci")
  }
  filetype <- match.arg(tolower(filetype), c("uci", "ucinet", "dl", "csv", "xlsx", "vna"))
  switch(filetype,
    csv = utils::write.csv(as.matrix(net), file),
    stop("xsave() for filetype '", filetype, "' is not implemented yet (Phase 0).", call. = FALSE)
  )
  invisible(file)
}
