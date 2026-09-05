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
#' @section Shipped datasets:
#' If `file` names no file on disk but does name one of the datasets the package
#' ships, that dataset is used. So `xdensity("campnet")` works the way the
#' UCINET command line does, without a `data(campnet)` first. A real file always
#' wins over a dataset of the same name.
#' @export
xread <- function(file, filetype = NULL, layout = NULL, sheet = 1, labels = TRUE,
                  directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(filetype)) {
    shipped <- shipped_dataset(file)
    if (!is.null(shipped)) {
      return(as_xucinet(shipped, directed = directed, mode = mode, title = title))
    }
    filetype <- detect_filetype(file)
  }
  filetype <- match.arg(tolower(filetype), c("ucinet", "uci", "dl", "csv", "xlsx", "vna"))
  # These carry their own labels, shape and title, so they do not go through the
  # layout detection below.
  if (filetype == "ucinet") {
    return(xreaducinet(file, directed = directed, mode = mode, title = title))
  }
  if (filetype == "uci") {
    return(xreaduci(file, directed = directed, mode = mode, title = title))
  }
  if (filetype == "dl") {
    return(xreaddl(file, directed = directed, mode = mode, title = title))
  }
  if (filetype == "vna") {
    return(xreadvna(file, directed = directed, mode = mode, title = title))
  }
  if (is.null(title)) title <- tools::file_path_sans_ext(basename(file))
  g <- switch(filetype,
    csv  = read_delim_raw(file),
    xlsx = read_xlsx_grid(file, sheet)
  )
  has_header <- if (is.null(labels) || isTRUE(labels)) detect_header(g) else FALSE
  if (is.null(layout)) layout <- detect_layout_grid(g, has_header)
  layout <- match.arg(tolower(layout), c("matrix", "edgelist", "nodelist"))
  switch(layout,
    matrix   = as_xucinet(grid_to_matrix(g, has_header), directed = directed,
                          mode = mode, title = title),
    edgelist = xfromedgelist(grid_to_edgelist(g, has_header), directed = directed,
                             title = title),
    nodelist = xfromnodelist(grid_to_nodelist(g, has_header), directed = directed,
                             title = title)
  )
}

detect_filetype <- function(file) {
  # tools::file_ext() only matches alphanumeric extensions, so it never sees
  # "##h"; test for UCINET's pair by hand before falling back to it.
  if (is_ucinet_path(file)) return("ucinet")
  if (file.exists(paste0(file, ".##h")) || file.exists(paste0(file, ".##H"))) {
    return("ucinet")
  }
  ext <- tolower(tools::file_ext(file))
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

# The UCINET command line takes a dataset name, so xdensity("campnet") should
# too. Only consulted when nothing of that name exists on disk: a real file
# always wins. Dataset names are lowercase (D3), which also keeps this from
# firing on paths.
shipped_dataset <- function(file) {
  if (!is.character(file) || length(file) != 1L) return(NULL)
  if (!grepl("^[a-z][a-z0-9_]*$", file)) return(NULL)
  if (file.exists(file) || file.exists(paste0(file, ".##h")) ||
      file.exists(paste0(file, ".##H"))) {
    return(NULL)
  }
  env <- new.env(parent = emptyenv())
  found <- tryCatch({
    suppressWarnings(utils::data(list = file, package = "xucinet", envir = env))
    exists(file, envir = env, inherits = FALSE)
  }, error = function(e) FALSE)
  if (!found) return(NULL)
  get(file, envir = env, inherits = FALSE)
}

is_ucinet_path <- function(file) {
  is.character(file) && length(file) == 1L && grepl("\\.##[hHdD]$", file)
}

# A worksheet as raw cells, so that a spreadsheet goes through exactly the same
# header and layout detection a csv does.
read_xlsx_grid <- function(file, sheet = 1) {
  need_pkg("readxl", "Reading .xlsx files")
  df <- readxl::read_excel(file, sheet = sheet, col_names = FALSE,
                           col_types = "text", .name_repair = "minimal",
                           progress = FALSE)
  g <- as_raw_grid(as.data.frame(df, stringsAsFactors = FALSE))
  # Excel keeps trailing blank rows and columns; they are not data.
  keep_col <- apply(g, 2, function(x) any(nzchar(x)))
  keep_row <- apply(g, 1, function(x) any(nzchar(x)))
  g[keep_row, keep_col, drop = FALSE]
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
  s <- as.character(df[[from]]); r <- as.character(df[[to]])
  nodes <- unique(c(s, r))
  build <- function(w, rows = rep(TRUE, nrow(df))) {
    m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
    m[cbind(s[rows], r[rows])] <- w
    m
  }
  extra <- if (is.null(weight)) setdiff(seq_along(df), c(from, to)) else weight

  if (!length(extra)) {
    mats <- stats::setNames(list(build(rep(1, nrow(df)))), title)
  } else if (length(extra) == 1L && !is_numericish(as.character(df[[extra]]))) {
    # from, to, relation-name: each row says which network its tie belongs to,
    # so the column is split into one matrix per name rather than coerced to
    # numbers, which would make every cell NA.
    lab <- as.character(df[[extra]])
    lv <- unique(lab[nzchar(lab)])
    mats <- stats::setNames(lapply(lv, function(v) build(1, lab == v)), lv)
  } else {
    # Every remaining column is a relation over the same nodes: an edge list of
    # FROM, TO, PADGM, PADGB carries two networks, and taking only the first
    # would drop one without saying so.
    mats <- stats::setNames(
      lapply(extra, function(k) build(suppressWarnings(as.numeric(df[[k]])))),
      names(df)[extra])
  }
  if (is.null(directed)) {
    directed <- any(vapply(mats, function(m) !isTRUE(isSymmetric(unname(m))), logical(1)))
  }
  if (!directed) mats <- lapply(mats, function(m) pmax(m, t(m)))
  new_xucinet(if (length(mats) == 1L) mats[[1L]] else mats,
              mode = "1-mode", directed = directed, title = title)
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
  # NULL means "not specified", which xread() passes whenever the caller has not
  # said. A node list is directed by default: ego names its alters, and the
  # alters were not asked.
  if (is.null(directed)) directed <- TRUE
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
    if (is_ucinet_path(file)) {
      filetype <- "ucinet"
    } else {
      ext <- tolower(tools::file_ext(file))
      filetype <- if (ext == "") "uci" else detect_filetype(file)
      if (ext == "") file <- paste0(file, ".uci")
    }
  }
  filetype <- match.arg(tolower(filetype), c("uci", "ucinet", "dl", "csv", "xlsx", "vna"))
  switch(filetype,
    csv    = utils::write.csv(as.matrix(net), file),
    uci    = return(invisible(xsaveuci(net, file, ...))),
    ucinet = return(invisible(xsaveucinet(net, file, ...))),
    dl     = return(invisible(xsavedl(net, file, ...))),
    vna    = return(invisible(xsavevna(net, file, ...))),
    stop("xsave() for filetype '", filetype, "' is not implemented yet (Phase 0).", call. = FALSE)
  )
  invisible(file)
}
