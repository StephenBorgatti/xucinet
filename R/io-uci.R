# Reader and writer for the .uci single-file JSON format (SPEC D6).
#
# The schema is inst/schema/uci-1.0.json, with a worked example beside it. It is
# a joint UCINET/xucinet format, so the structure is kept shallow and its arrays
# homogeneous: whatever is easy here has to be easy in Delphi XE7's System.JSON
# too.
#
# Two details that decide whether a round trip is exact:
#   - numbers are written with 17 significant digits, which is what a double
#     needs to survive the trip. jsonlite's default of 4 decimal places would
#     turn 1/3 into 0.3333, and even digits = NA only gives 15;
#   - a matrix of whole numbers reads back as integer storage, so it is forced
#     to double, which is what UCINET holds and what every routine expects.

uci_schema_version <- "1.0"

need_jsonlite <- function() {
  need_pkg("jsonlite", "Reading and writing .uci files")
}

#' Read a .uci dataset
#'
#' Reads the single-file JSON format described in
#' `system.file("schema/uci-1.0.json", package = "xucinet")`: matrices, labels,
#' mode, directedness, relation names and, if the file carries them, node
#' attributes.
#'
#' @param file Path to the `.uci` file.
#' @param directed,mode,title Override what the file says. `title` defaults to
#'   the file's own title, or the file name when it has none.
#' @param ... Reserved.
#' @return An `xucinet` object. When the file carries node attributes they are
#'   attached as `$attributes`, a plain data frame keyed by node label; it is
#'   `NULL` otherwise and no routine reads it (SPEC D1).
#' @seealso [xsaveuci()], and [xreaducinet()] for the older `##h`/`##d` pair.
#' @examples
#' f <- system.file("schema", "campnet-example.uci", package = "xucinet")
#' xreaduci(f)
#' @export
xreaduci <- function(file, directed = NULL, mode = NULL, title = NULL, ...) {
  need_jsonlite()
  if (!file.exists(file)) {
    stop("No .uci file at '", file, "'.", call. = FALSE)
  }
  doc <- jsonlite::fromJSON(file, simplifyVector = TRUE, simplifyMatrix = TRUE)
  uci_check_version(doc, file)

  nr <- as.integer(doc$nrows)
  nc <- as.integer(doc$ncols)
  rowlab <- if (is.null(doc$rowlabels)) NULL else as.character(doc$rowlabels)
  collab <- if (is.null(doc$collabels)) NULL else as.character(doc$collabels)
  uci_check_labels(rowlab, nr, "row", file)
  uci_check_labels(collab, nc, "column", file)

  rels <- uci_relations(doc, nr, nc, rowlab, collab, file)
  if (is.null(title)) {
    title <- if (!is.null(doc$title) && nzchar(doc$title)) doc$title else
      sub("\\.uci$", "", basename(file))
  }
  if (is.null(mode)) mode <- doc$mode
  if (is.null(directed) && !is.null(doc$directed) && !is.na(doc$directed)) {
    directed <- as.logical(doc$directed)
  }

  net <- if (length(rels) == 1L) {
    as_xucinet(rels[[1L]], directed = directed, mode = mode, title = title)
  } else {
    as_xucinet(rels, directed = directed, mode = mode, title = title)
  }
  net$attributes <- uci_attributes(doc)
  net
}

#' Write a .uci dataset
#'
#' Writes the single-file JSON format that replaces the `##h`/`##d` pair. This
#' is what [xsave()] uses when no other type is asked for.
#'
#' @param net A network (any accepted form).
#' @param file Output path. `.uci` is appended if it has no extension.
#' @param layout `"matrix"` for a dense payload, `"edgelist"` for a sparse one,
#'   or `NULL` (default) to pick whichever is smaller. The words are the ones
#'   [xread()] already uses, so there is one vocabulary rather than two.
#' @param attributes Optional data frame of node attributes, keyed by node
#'   label. Defaults to `net$attributes` when the network carries one.
#' @param title Dataset title stored in the file. Defaults to the network's.
#' @param datatype Advisory hint for a reader converting back to `##h`/`##d`,
#'   which has to choose a fixed cell width. Ignored when reading.
#' @param pretty Indent the JSON? Readable but larger.
#' @return The path written, invisibly.
#' @seealso [xreaduci()]
#' @examples
#' f <- file.path(tempdir(), "demo.uci")
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
#' xsaveuci(m, f)
#' xreaduci(f)
#' @export
xsaveuci <- function(net, file, layout = NULL, attributes = NULL, title = NULL,
                     datatype = "single", pretty = TRUE) {
  need_jsonlite()
  net <- as_xucinet(net)
  if (!grepl("\\.[A-Za-z0-9]+$", file) && !grepl("\\.uci$", file)) {
    file <- paste0(file, ".uci")
  }
  if (is.null(title)) title <- net$title
  if (is.null(attributes)) attributes <- net$attributes

  mats <- if (is.list(net$data)) net$data else list(net$data)
  names(mats) <- xrelations(net)
  proto <- mats[[1L]]

  doc <- list(
    uci = uci_schema_version,
    title = jsonlite::unbox(as.character(title)),
    mode = jsonlite::unbox(net$mode),
    directed = if (is.na(net$directed)) NULL else jsonlite::unbox(as.logical(net$directed)),
    nrows = jsonlite::unbox(nrow(proto)),
    ncols = jsonlite::unbox(ncol(proto)),
    rowlabels = rownames(proto),
    collabels = colnames(proto),
    datatype = jsonlite::unbox(datatype),
    relations = lapply(names(mats), function(nm) uci_relation(mats[[nm]], nm, layout)),
    provenance = list(
      written_by = jsonlite::unbox(paste("xucinet", utils::packageVersion("xucinet"))),
      written_at = jsonlite::unbox(format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"))
    )
  )
  if (!is.null(attributes)) doc$attributes <- uci_attribute_block(attributes)
  doc$uci <- jsonlite::unbox(uci_schema_version)

  # 17 significant digits: fewer and a double does not survive the round trip.
  json <- jsonlite::toJSON(doc, digits = I(17), na = "null", null = "null",
                           pretty = pretty, auto_unbox = FALSE)
  writeLines(json, file, useBytes = TRUE)
  invisible(file)
}

# ---- internals --------------------------------------------------------------

uci_check_version <- function(doc, file) {
  v <- doc$uci
  if (is.null(v)) {
    stop("'", basename(file), "' has no \"uci\" version key, so it is not a ",
         ".uci dataset.\n  A .uci file starts with {\"uci\": \"1.0\", ...}.",
         call. = FALSE)
  }
  major <- as.integer(sub("\\..*$", "", v))
  ours <- as.integer(sub("\\..*$", "", uci_schema_version))
  if (is.na(major) || major > ours) {
    stop("'", basename(file), "' is .uci schema version ", v, ", which this ",
         "version of xucinet does not read (it knows ", uci_schema_version, ").\n",
         "  Upgrade xucinet, or ask whoever wrote the file for an older version.",
         call. = FALSE)
  }
  invisible(TRUE)
}

uci_check_labels <- function(lab, n, what, file) {
  if (is.null(lab)) return(invisible(TRUE))
  if (length(lab) != n) {
    stop("'", basename(file), "' lists ", length(lab), " ", what, " labels but ",
         "declares ", n, " ", what, "s.", call. = FALSE)
  }
  invisible(TRUE)
}

# Turn one relation from the file into a labelled numeric matrix.
uci_relation_matrix <- function(rel, nr, nc, rowlab, collab, file) {
  layout <- rel$layout
  if (is.null(layout)) layout <- "matrix"
  if (identical(layout, "matrix")) {
    v <- rel$values
    m <- if (is.matrix(v)) v else matrix(unlist(v), nrow = nr, ncol = nc, byrow = TRUE)
    if (!identical(dim(m), c(nr, nc))) {
      stop("Relation '", rel$name, "' in '", basename(file), "' is ",
           paste(dim(m), collapse = " x "), " but the file declares ",
           nr, " x ", nc, ".", call. = FALSE)
    }
  } else if (identical(layout, "edgelist")) {
    i <- as.integer(rel$i); j <- as.integer(rel$j)
    v <- if (is.null(rel$values)) rep(1, length(i)) else as.numeric(rel$values)
    if (length(i) != length(j) || length(i) != length(v)) {
      stop("Relation '", rel$name, "' in '", basename(file), "' has ", length(i),
           " row indices, ", length(j), " column indices and ", length(v),
           " values; the three must match.", call. = FALSE)
    }
    if (length(i) && (max(i) > nr || max(j) > nc)) {
      stop("Relation '", rel$name, "' in '", basename(file), "' indexes outside ",
           "the declared ", nr, " x ", nc, ".", call. = FALSE)
    }
    m <- matrix(0, nr, nc)
    if (length(i)) m[cbind(i, j)] <- v
  } else {
    stop("Relation '", rel$name, "' in '", basename(file), "' has layout '",
         layout, "'; expected \"matrix\" or \"edgelist\".", call. = FALSE)
  }
  # JSON integers arrive as integer storage; UCINET holds doubles and so do we.
  storage.mode(m) <- "double"
  dimnames(m) <- list(rowlab, collab)
  m
}

uci_relations <- function(doc, nr, nc, rowlab, collab, file) {
  rels <- doc$relations
  if (is.null(rels) || !length(rels)) {
    stop("'", basename(file), "' declares no relations.", call. = FALSE)
  }
  # jsonlite simplifies a list of same-shaped objects into a data frame; index
  # it row-wise so both shapes are handled.
  n <- if (is.data.frame(rels)) nrow(rels) else length(rels)
  one <- function(k) if (is.data.frame(rels)) lapply(rels, function(col) col[[k]]) else rels[[k]]
  out <- lapply(seq_len(n), function(k) {
    uci_relation_matrix(one(k), nr, nc, rowlab, collab, file)
  })
  nms <- vapply(seq_len(n), function(k) {
    nm <- one(k)$name
    if (is.null(nm) || !nzchar(nm)) paste0("relation", k) else as.character(nm)
  }, character(1))
  names(out) <- nms
  out
}

uci_attributes <- function(doc) {
  a <- doc$attributes
  if (is.null(a) || is.null(a$variables)) return(NULL)
  vars <- a$variables
  n <- if (is.data.frame(vars)) nrow(vars) else length(vars)
  if (!n) return(NULL)
  one <- function(k) if (is.data.frame(vars)) lapply(vars, function(col) col[[k]]) else vars[[k]]
  cols <- lapply(seq_len(n), function(k) {
    v <- one(k)$values
    if (is.list(v)) v <- unlist(lapply(v, function(x) if (is.null(x)) NA else x))
    v
  })
  names(cols) <- vapply(seq_len(n), function(k) as.character(one(k)$name), character(1))
  df <- as.data.frame(cols, stringsAsFactors = FALSE, check.names = FALSE)
  if (!is.null(a$rows)) rownames(df) <- as.character(a$rows)
  df
}

# Dense unless the matrix is big enough for sparsity to be worth having, and
# sparse enough to pay for itself. A sparse entry costs three numbers, so it
# only wins below about a third density; and below the size threshold the saving
# is a few hundred bytes, which is not worth making the file harder to read.
# SPEC D6 puts it as "dense, or sparse edge-list for large networks".
uci_sparse_threshold <- 10000L

uci_relation <- function(m, name, layout) {
  if (is.null(layout)) {
    nz <- sum(m != 0, na.rm = TRUE) + sum(is.na(m))
    layout <- if (length(m) > uci_sparse_threshold && nz * 3 < length(m))
      "edgelist" else "matrix"
  }
  layout <- match.arg(layout, c("matrix", "edgelist"))
  rel <- list(name = jsonlite::unbox(name), layout = jsonlite::unbox(layout))
  if (layout == "matrix") {
    rel$values <- unname(m)
  } else {
    idx <- which(m != 0 | is.na(m), arr.ind = TRUE)
    rel$i <- as.integer(idx[, 1])
    rel$j <- as.integer(idx[, 2])
    rel$values <- as.numeric(m[idx])
  }
  rel
}

uci_attribute_block <- function(df) {
  df <- as.data.frame(df, stringsAsFactors = FALSE, check.names = FALSE)
  list(
    rows = rownames(df),
    variables = lapply(names(df), function(nm) {
      list(name = jsonlite::unbox(nm), values = df[[nm]])
    })
  )
}
