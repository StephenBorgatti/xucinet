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
#' @param duplicates For an edge list, what to do when the same pair is listed
#'   more than once. See [xfromedgelist()]; `"sum"` by default.
#' @param ... Reserved.
#' @return An `xucinet` object.
#' @section Shipped datasets:
#' If `file` names no file on disk but does name one of the datasets the package
#' ships, that dataset is used. So `xdensity("campnet")` works the way the
#' UCINET command line does, without a `data(campnet)` first. A real file always
#' wins over a dataset of the same name.
#' @export
xread <- function(file, filetype = NULL, layout = NULL, sheet = 1, labels = TRUE,
                  directed = NULL, mode = NULL, title = NULL,
                  duplicates = c("sum", "last", "error"), ...) {
  duplicates <- match.arg(duplicates)
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
                             duplicates = duplicates, mode = mode, title = title),
    nodelist = xfromnodelist(grid_to_nodelist(g, has_header), directed = directed,
                             mode = mode, title = title)
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
  # UCINET's own datasets ship DL files under .txt, so the extension alone
  # cannot decide: look at the first token instead. Every DL file starts with
  # one, which is the only thing the format guarantees.
  if (ext == "txt" && looks_like_dl(file)) return("dl")
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

# Is the first token of the file "DL"? Cheap enough to ask, and the only thing
# that separates a DL file from any other text under a .txt extension.
looks_like_dl <- function(file) {
  if (!file.exists(file)) return(FALSE)
  con <- file(file, "rt")
  on.exit(close(con))
  first <- tryCatch(readLines(con, n = 1L, warn = FALSE), error = function(e) "")
  length(first) > 0L && grepl("^\\s*dl\\b", first[1], ignore.case = TRUE)
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
#' @param mode `"1-mode"`, `"2-mode"`, or `NULL` (default) to decide from the
#'   data: two columns sharing no values are taken to be two node sets, and
#'   the result is a rectangle rather than a square over their union. That is
#'   evidence rather than proof - a strict hierarchy has disjoint columns and
#'   is still 1-mode - so pass `mode` to settle it either way.
#' @param duplicates What to do when the same pair is listed more than once:
#'   `"sum"` (the default) adds the values up, as the chapter 5 text says;
#'   `"last"` keeps the last one, which is what the reader did before; and
#'   `"error"` refuses. The count is reported and recorded in the result's
#'   `history` attribute.
#' @param title Dataset name.
#' @return An `xucinet` object.
#' @export
xfromedgelist <- function(df, from = 1, to = 2, weight = NULL, directed = NULL,
                          duplicates = c("sum", "last", "error"),
                          mode = NULL, title = NULL) {
  if (is.null(title)) title <- deparse1(substitute(df))
  s <- as.character(df[[from]]); r <- as.character(df[[to]])
  twomode <- detect_two_mode(s, r, mode)
  if (twomode) {
    rlab <- unique(s); clab <- unique(r)
  } else {
    rlab <- clab <- unique(c(s, r))
  }
  duplicates <- match.arg(duplicates)
  dups <- 0L
  build <- function(w, rows = rep(TRUE, nrow(df))) {
    m <- matrix(0, length(rlab), length(clab), dimnames = list(rlab, clab))
    si <- match(s[rows], rlab); ri <- match(r[rows], clab)
    # One linear index per edge, so that a pair listed twice is visible.
    lin <- si + (ri - 1L) * nrow(m)
    w <- rep_len(w, length(lin))
    repeated <- sum(duplicated(lin))
    if (repeated) {
      dups <<- dups + repeated
      if (identical(duplicates, "error")) {
        bad <- unique(paste0(s[rows][duplicated(lin)], " -> ",
                             r[rows][duplicated(lin)]))
        stop(repeated, " pair", if (repeated == 1) " is" else "s are",
             " listed more than once in the edge list, and duplicates = ",
             "\"error\".\n  First: ", paste(utils::head(bad, 3), collapse = ", "),
             "\n  Use duplicates = \"sum\" to add them up, or \"last\" to keep ",
             "the last value.", call. = FALSE)
      }
    }
    if (identical(duplicates, "sum")) {
      # The ch05 text says duplicates are summed; the accumulation has to be
      # explicit, because m[idx] <- w keeps only the last value written.
      acc <- tapply(w, lin, sum)
      m[as.integer(names(acc))] <- acc
    } else {
      m[cbind(si, ri)] <- w
    }
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
  # The ch05 text says duplicates are summed, so say when it happened rather
  # than let a silently doubled tie value look like data.
  note <- function(net) {
    if (dups) {
      message("xfromedgelist(): ", dups, " duplicated pair",
              if (dups == 1) "" else "s",
              switch(duplicates, sum = " summed", last = " overwritten"))
      attr(net, "history") <- c(
        attr(net, "history"),
        paste0(dups, " duplicated pair", if (dups == 1) "" else "s",
               switch(duplicates, sum = " summed", last = " overwritten")))
    }
    net
  }

  if (twomode) {
    # Directedness has no meaning across two node sets, and symmetrising a
    # rectangle is not defined.
    return(note(new_xucinet(if (length(mats) == 1L) mats[[1L]] else mats,
                            mode = "2-mode", directed = NA, title = title)))
  }
  if (is.null(directed)) {
    directed <- any(vapply(mats, function(m) !isTRUE(isSymmetric(unname(m))), logical(1)))
  }
  if (!directed) mats <- lapply(mats, function(m) pmax(m, t(m)))
  note(new_xucinet(if (length(mats) == 1L) mats[[1L]] else mats,
                   mode = "1-mode", directed = directed, title = title))
}

# Two columns that share no values are almost always two node sets: actors and
# films, women and events. Almost, not always - a strict hierarchy is 1-mode and
# disjoint too, since nobody supervises themselves - so this is evidence, not
# proof, and mode= overrides it either way.
detect_two_mode <- function(s, r, mode = NULL) {
  if (!is.null(mode)) return(identical(match_mode(mode), "2-mode"))
  s <- s[nzchar(s)]; r <- r[nzchar(r)]
  length(s) > 0L && length(r) > 0L && !length(intersect(s, r))
}

#' Build a network from a node list
#'
#' A node list has one row per ego: the first column is ego, the remaining
#' columns are the alters ego names (blank or `NA` where unused).
#'
#' @param df A data frame.
#' @param ego Column name or position of the ego column.
#' @param directed Logical; node lists are directed by default.
#' @param mode `"1-mode"`, `"2-mode"`, or `NULL` (default) to decide from the
#'   data: two columns sharing no values are taken to be two node sets, and
#'   the result is a rectangle rather than a square over their union. That is
#'   evidence rather than proof - a strict hierarchy has disjoint columns and
#'   is still 1-mode - so pass `mode` to settle it either way.
#' @param title Dataset name.
#' @return An `xucinet` object.
#' @export
xfromnodelist <- function(df, ego = 1, directed = TRUE, mode = NULL, title = NULL) {
  if (is.null(title)) title <- deparse1(substitute(df))
  # NULL means "not specified", which xread() passes whenever the caller has not
  # said. A node list is directed by default: ego names its alters, and the
  # alters were not asked.
  if (is.null(directed)) directed <- TRUE
  egos <- as.character(df[[ego]])
  alters <- df[-ego]
  s <- rep(egos, ncol(alters)); r <- as.character(unlist(alters, use.names = FALSE))
  keep <- !is.na(r) & nzchar(r)
  s <- s[keep]; r <- r[keep]

  # Egos naming a set nobody in it belongs to - women naming events - is 2-mode.
  if (detect_two_mode(egos, r, mode)) {
    m <- matrix(0, length(egos), length(unique(r)),
                dimnames = list(egos, unique(r)))
    m[cbind(s, r)] <- 1
    return(new_xucinet(m, mode = "2-mode", directed = NA, title = title))
  }
  # Egos with no alters stay as isolates.
  nodes <- unique(c(egos, r))
  m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
  m[cbind(s, r)] <- 1
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
