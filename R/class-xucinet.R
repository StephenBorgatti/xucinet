#' Create or coerce to an xucinet network object
#'
#' An `xucinet` object mirrors a UCINET dataset: one or more matrices with node
#' labels, a mode (1-mode or 2-mode), a directedness flag and a title used in
#' printed output. Every analysis function in the package calls `as_xucinet()`
#' on its first argument, so plain matrices and data frames can be passed
#' directly to any routine.
#'
#' @param x A matrix, a data frame holding an adjacency matrix or an edge list
#'   (detected by shape), an `igraph` object, a statnet `network` object, an
#'   existing `xucinet` object, or the name of a file readable by [xread()].
#' @param directed `TRUE`, `FALSE`, or `NULL` (default) to detect from the
#'   symmetry of the matrix. The result of detection is recorded and reported
#'   by routines as an assumption, as UCINET does.
#' @param mode `"1-mode"`, `"2-mode"`, or `NULL` (default) to detect: square
#'   with matching row and column labels is 1-mode, otherwise 2-mode.
#' @param title Dataset name used in printed reports. Defaults to the name of
#'   the object passed in.
#' @param ... Passed to methods.
#' @return An object of class `xucinet`: a list with elements `data` (a matrix,
#'   or a named list of matrices for a multi-relation dataset), `mode`,
#'   `directed`, and `title`.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3,
#'             dimnames = list(c("a","b","c"), c("a","b","c")))
#' net <- as_xucinet(m)
#' net
#' @export
as_xucinet <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  UseMethod("as_xucinet")
}

#' @export
as_xucinet.xucinet <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (!is.null(directed)) x$directed <- directed
  if (!is.null(mode))     x$mode     <- match_mode(mode)
  if (!is.null(title))    x$title    <- title
  x
}

#' @export
as_xucinet.matrix <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  x <- ensure_dimnames(x)
  if (is.null(mode)) {
    mode <- if (nrow(x) == ncol(x) && identical(rownames(x), colnames(x))) "1-mode" else "2-mode"
  }
  mode <- match_mode(mode)
  if (is.null(directed)) {
    directed <- if (mode == "1-mode") !isSymmetric(unname(x)) else NA
  }
  new_xucinet(x, mode = mode, directed = directed, title = title)
}

#' @export
as_xucinet.data.frame <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  # Edge list: 2 or 3 columns, first two not all numeric-with-many-distinct... keep the
  # rule simple and overridable: a data frame with 2-3 columns whose first column has
  # repeated values is treated as an edge list; anything else as an adjacency matrix.
  looks_like_edgelist <- ncol(x) %in% 2:3 && nrow(x) > ncol(x)
  if (looks_like_edgelist) {
    return(xfromedgelist(x, directed = directed, title = title))
  }
  m <- as.matrix(x)
  if (!is.numeric(m)) storage.mode(m) <- "numeric"
  as_xucinet(m, directed = directed, mode = mode, title = title)
}

#' @export
as_xucinet.character <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  xread(x, directed = directed, mode = mode, title = title, ...)
}

#' @export
as_xucinet.default <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  cls <- class(x)[1]
  if (cls == "igraph" && requireNamespace("igraph", quietly = TRUE)) {
    m <- igraph::as_adjacency_matrix(x, sparse = FALSE, attr = edge_weight_attr(x))
    if (is.null(title)) title <- deparse1(substitute(x))
    return(as_xucinet(m, directed = if (is.null(directed)) igraph::is_directed(x) else directed,
                      mode = mode, title = title))
  }
  if (cls == "network" && requireNamespace("network", quietly = TRUE)) {
    m <- network::as.matrix.network(x)
    if (is.null(title)) title <- deparse1(substitute(x))
    return(as_xucinet(m, directed = if (is.null(directed)) network::is.directed(x) else directed,
                      mode = mode, title = title))
  }
  stop("Don't know how to turn an object of class '", cls, "' into a network.\n",
       "  Accepted: matrix, data.frame (adjacency or edge list), igraph, network, ",
       "xucinet, or a file name.", call. = FALSE)
}

# ---- internal helpers -------------------------------------------------------

# Called at the top of every routine: coerce `net` and, when it is not already an
# xucinet object or a file name, use the caller's expression as the dataset title
# so that printed reports say "Input dataset: hightech" rather than "net".
xnet <- function(net, expr, ...) {
  if (inherits(net, "xucinet") || is.character(net)) return(as_xucinet(net, ...))
  as_xucinet(net, title = deparse1(expr), ...)
}

new_xucinet <- function(data, mode, directed, title) {
  structure(list(data = data, mode = mode, directed = directed, title = title),
            class = "xucinet")
}

match_mode <- function(mode) {
  mode <- tolower(mode)
  if (mode %in% c("1", "1-mode", "one", "onemode", "1mode")) return("1-mode")
  if (mode %in% c("2", "2-mode", "two", "twomode", "2mode")) return("2-mode")
  stop("mode must be \"1-mode\" or \"2-mode\".", call. = FALSE)
}

ensure_dimnames <- function(m) {
  if (is.null(rownames(m))) rownames(m) <- as.character(seq_len(nrow(m)))
  if (is.null(colnames(m))) colnames(m) <- if (ncol(m) == nrow(m)) rownames(m) else as.character(seq_len(ncol(m)))
  m
}

edge_weight_attr <- function(g) {
  if ("weight" %in% igraph::edge_attr_names(g)) "weight" else NULL
}

#' @export
as.matrix.xucinet <- function(x, relation = NULL, ...) {
  d <- x$data
  if (is.list(d)) {
    if (is.null(relation)) relation <- 1
    d <- d[[relation]]
  }
  d
}

#' @export
dim.xucinet <- function(x) dim(as.matrix(x))

#' Number of relations in a dataset
#' @param net A network (any accepted form).
#' @return An integer.
#' @export
xnrelations <- function(net) {
  net <- as_xucinet(net)
  if (is.list(net$data)) length(net$data) else 1L
}
