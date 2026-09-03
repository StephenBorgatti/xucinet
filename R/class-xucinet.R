#' Create or coerce to an xucinet network object
#'
#' An `xucinet` object mirrors a UCINET dataset: one or more matrices with node
#' labels, a mode (1-mode or 2-mode), a directedness flag and a title used in
#' printed output. Every analysis function in the package calls `as_xucinet()`
#' on its first argument, so plain matrices and data frames can be passed
#' directly to any routine.
#'
#' A dataset with several relations (UCINET's multi-relation stack, as in
#' Sampson or the hightech advice/friendship/reports data) is built from a 3-D
#' array whose third dimension is the relation, or from a named list of
#' matrices. All relations must have the same dimensions and the same labels.
#' `$data` is then a named list of matrices; see [xrelations()].
#'
#' @param x A matrix, a 3-D array (rows x columns x relations), a named list of
#'   matrices, a data frame holding an adjacency matrix or an edge list
#'   (detected by shape), an `igraph` object, a statnet `network` object, a
#'   tidygraph `tbl_graph`, an existing `xucinet` object, or the name of a file
#'   readable by [xread()].
#' @param directed `TRUE`, `FALSE`, or `NULL` (default) to detect from the
#'   symmetry of the matrix. For a multi-relation dataset the data are treated
#'   as directed if any relation is asymmetric. The result of detection is
#'   recorded and reported by routines as an assumption, as UCINET does.
#' @param mode `"1-mode"`, `"2-mode"`, or `NULL` (default) to detect: square
#'   with matching row and column labels is 1-mode, otherwise 2-mode.
#' @param title Dataset name used in printed reports. Defaults to the name of
#'   the object passed in.
#' @param ... Passed to methods.
#' @return An object of class `xucinet`: a list with elements `data` (a matrix,
#'   or a named list of matrices for a multi-relation dataset), `mode`,
#'   `directed`, and `title`.
#' @seealso [xrelations()] for the relation names, [as_igraph()] and friends to
#'   convert the other way, and `[.xucinet` to subset nodes.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3,
#'             dimnames = list(c("a","b","c"), c("a","b","c")))
#' net <- as_xucinet(m)
#' net
#'
#' # a two-relation stack
#' both <- as_xucinet(list(liking = m, advice = t(m)))
#' xrelations(both)
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
  x <- as_numeric_matrix(x)
  x <- ensure_dimnames(x)
  if (is.null(mode)) mode <- detect_mode(x) else mode <- match_mode(mode)
  if (is.null(directed)) directed <- detect_directed(list(x), mode)
  new_xucinet(x, mode = mode, directed = directed, title = title)
}

#' @export
as_xucinet.array <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  nd <- length(dim(x))
  if (nd == 2L) {
    return(as_xucinet(as.matrix(x), directed = directed, mode = mode, title = title))
  }
  if (nd != 3L) {
    stop("A network array must have 2 dimensions (rows x columns) or 3 ",
         "(rows x columns x relations); this one has ", nd, ".", call. = FALSE)
  }
  dn <- dimnames(x)
  mats <- lapply(seq_len(dim(x)[3L]), function(k) {
    m <- x[, , k, drop = FALSE]
    dim(m) <- dim(x)[1:2]
    dimnames(m) <- if (is.null(dn)) NULL else dn[1:2]
    m
  })
  names(mats) <- if (is.null(dn)) NULL else dn[[3L]]
  as_xucinet(mats, directed = directed, mode = mode, title = title)
}

#' @export
as_xucinet.list <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  mats <- name_relations(harmonize_relations(x))
  if (is.null(mode)) mode <- detect_mode(mats[[1L]]) else mode <- match_mode(mode)
  if (is.null(directed)) directed <- detect_directed(mats, mode)
  new_xucinet(mats, mode = mode, directed = directed, title = title)
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
  as_xucinet(as.matrix(x), directed = directed, mode = mode, title = title)
}

#' @export
as_xucinet.character <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  xread(x, directed = directed, mode = mode, title = title, ...)
}

#' @export
as_xucinet.igraph <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  need_pkg("igraph", "Converting an igraph object")
  wt <- edge_weight_attr(x)
  # A bipartite igraph carries a logical vertex attribute "type"; UCINET calls
  # that 2-mode, with the FALSE vertices as rows.
  bipartite <- "type" %in% igraph::vertex_attr_names(x)
  if (bipartite && (is.null(mode) || match_mode(mode) == "2-mode")) {
    m <- igraph_biadjacency(x, wt)
    return(as_xucinet(m, directed = directed, mode = "2-mode", title = title))
  }
  m <- igraph::as_adjacency_matrix(x, sparse = FALSE, attr = wt)
  as_xucinet(m,
             directed = if (is.null(directed)) igraph::is_directed(x) else directed,
             mode = mode, title = title)
}

#' @export
as_xucinet.tbl_graph <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  class(x) <- setdiff(class(x), "tbl_graph")
  as_xucinet(x, directed = directed, mode = mode, title = title, ...)
}

#' @export
as_xucinet.network <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  need_pkg("network", "Converting a network object")
  wt <- if ("weight" %in% network::list.edge.attributes(x)) "weight" else NULL
  m <- network::as.matrix.network(x, matrix.type = "adjacency", attrname = wt)
  as_xucinet(m,
             directed = if (is.null(directed)) network::is.directed(x) else directed,
             mode = if (is.null(mode) && network::is.bipartite(x)) "2-mode" else mode,
             title = title)
}

#' @export
as_xucinet.default <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  stop("Don't know how to turn an object of class '", class(x)[1], "' into a network.\n",
       "  Accepted: matrix, 3-D array, named list of matrices, data.frame ",
       "(adjacency or edge list), igraph, network, tbl_graph, xucinet, or a file name.",
       call. = FALSE)
}

# ---- relations --------------------------------------------------------------

#' Relations in a dataset
#'
#' UCINET datasets may hold several relations in one stack (advice, friendship,
#' reports). `xrelations()` gives their names and `xnrelations()` how many there
#' are; `length(xrelations(net))` is always `xnrelations(net)`. A dataset with a
#' single unnamed relation reports its own title as the relation name.
#'
#' @param net A network (any accepted form).
#' @return `xrelations()` a character vector of relation names; `xnrelations()`
#'   an integer.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
#' xrelations(as_xucinet(list(liking = m, advice = t(m))))
#' xnrelations(m)
#' @export
xrelations <- function(net) {
  net <- as_xucinet(net)
  if (is.list(net$data)) names(net$data) else net$title
}

#' @rdname xrelations
#' @export
xnrelations <- function(net) {
  net <- as_xucinet(net)
  if (is.list(net$data)) length(net$data) else 1L
}

# Pull one relation out of an xucinet, by position or by name. Errors list what
# is actually available (SPEC D14: error messages that teach).
pick_relation <- function(x, relation = NULL) {
  d <- x$data
  if (!is.list(d)) {
    if (is.null(relation)) return(d)
    ok <- (is.numeric(relation) && length(relation) == 1L && relation == 1) ||
          identical(as.character(relation), x$title)
    if (!ok) {
      stop("'", paste(as.character(relation), collapse = ", "),
           "' is not a relation in this dataset.\n",
           "  It has one relation: ", x$title, call. = FALSE)
    }
    return(d)
  }
  nm <- names(d)
  if (is.null(relation)) return(d[[1L]])
  if (length(relation) != 1L) {
    stop("relation must name a single relation; got ", length(relation), ".",
         call. = FALSE)
  }
  if (is.character(relation)) {
    i <- match(relation, nm)
    if (is.na(i)) {
      stop("'", relation, "' is not a relation in this dataset.\n",
           "  Available: ", paste(nm, collapse = ", "), call. = FALSE)
    }
    return(d[[i]])
  }
  i <- as.integer(relation)
  if (is.na(i) || i < 1L || i > length(d)) {
    stop("relation ", relation, " is out of range; the dataset has ", length(d),
         " relations: ", paste(nm, collapse = ", "), call. = FALSE)
  }
  d[[i]]
}

# ---- subsetting -------------------------------------------------------------

#' Subset the nodes of a network
#'
#' `net[i]` keeps nodes `i` of a 1-mode network, taking the same rows and
#' columns so the result stays square. `net[i, j]` keeps rows `i` and columns
#' `j`, which is what 2-mode data needs. Indices may be positions, negative
#' positions to drop nodes, a logical vector, or node labels. Labels, mode,
#' directedness, the dataset title and every relation of a multi-relation stack
#' are carried through.
#'
#' @param x An `xucinet` object.
#' @param i Rows (and, for a 1-mode network with `j` missing, columns) to keep.
#' @param j Columns to keep.
#' @param ... Unused.
#' @param drop If `TRUE`, return the plain matrix (or, for a multi-relation
#'   dataset, the named list of matrices) instead of an `xucinet` object.
#'   Defaults to `FALSE`, unlike matrix subsetting.
#' @return An `xucinet` object, or a matrix if `drop = TRUE`.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3,
#'             dimnames = list(c("a","b","c"), c("a","b","c")))
#' net <- as_xucinet(m)
#' net[c("a", "b")]
#' net[-1]
#' @export
`[.xucinet` <- function(x, i, j, ..., drop = FALSE) {
  mats <- if (is.list(x$data)) x$data else list(x$data)
  proto <- mats[[1L]]
  square <- nrow(proto) == ncol(proto)
  if (missing(i)) i <- seq_len(nrow(proto))
  # net[i] on a 1-mode network means "keep these nodes": same rows and columns.
  if (missing(j)) j <- if (x$mode == "1-mode" && square) i else seq_len(ncol(proto))
  ii <- resolve_index(i, rownames(proto), "row")
  jj <- resolve_index(j, colnames(proto), "column")
  sub <- lapply(mats, function(m) m[ii, jj, drop = FALSE])
  if (isTRUE(drop)) return(if (is.list(x$data)) sub else sub[[1L]])
  newmode <- if (x$mode == "2-mode") "2-mode" else detect_mode(sub[[1L]])
  # Symmetry survives only when the same nodes were taken on both margins.
  newdirected <- if (newmode == "1-mode" && identical(ii, jj)) x$directed else
    detect_directed(sub, newmode)
  new_xucinet(if (is.list(x$data)) sub else sub[[1L]],
              mode = newmode, directed = newdirected, title = x$title)
}

# Turn positions / negative positions / logicals / labels into positions.
resolve_index <- function(idx, labels, what) {
  if (is.character(idx)) {
    k <- match(idx, labels)
    if (anyNA(k)) {
      stop("unknown ", what, " label", if (sum(is.na(k)) > 1) "s" else "", ": ",
           paste(idx[is.na(k)], collapse = ", "), "\n",
           "  Available: ", paste(labels, collapse = ", "), call. = FALSE)
    }
    return(k)
  }
  if (is.logical(idx)) {
    if (length(idx) != length(labels)) {
      stop("a logical ", what, " index must have one entry per ", what, " (",
           length(labels), "); got ", length(idx), ".", call. = FALSE)
    }
    return(which(idx))
  }
  idx <- as.integer(idx)
  if (anyNA(idx)) stop("missing values are not allowed in a ", what, " index.", call. = FALSE)
  if (any(idx < 0L)) {
    if (any(idx > 0L)) {
      stop("cannot mix positive and negative ", what, " indices.", call. = FALSE)
    }
    return(seq_along(labels)[idx])
  }
  idx <- idx[idx != 0L]
  if (any(idx > length(labels))) {
    stop(what, " index out of bounds: the network has ", length(labels), " ",
         what, "s.", call. = FALSE)
  }
  idx
}

# ---- exporters --------------------------------------------------------------

#' Convert a network to igraph, statnet or tidygraph form
#'
#' The way out of xucinet and into the rest of the R network ecosystem. Node
#' labels, directedness, edge values and 2-mode structure are carried across.
#' A multi-relation dataset has no single-graph equivalent, so pick one with
#' `relation`; the first is used by default.
#'
#' These also work through the ecosystem's own generics, so `igraph::as.igraph(net)`,
#' `network::as.network(net)` and `tidygraph::as_tbl_graph(net)` all understand
#' an `xucinet` object.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An `igraph`, `network` or `tbl_graph` object.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3,
#'             dimnames = list(c("a","b","c"), c("a","b","c")))
#' if (requireNamespace("igraph", quietly = TRUE)) {
#'   g <- as_igraph(m)
#'   as_xucinet(g)
#' }
#' @export
as_igraph <- function(net, relation = NULL) {
  need_pkg("igraph", "as_igraph()")
  net <- as_xucinet(net)
  m <- export_matrix(net, relation, "igraph")
  if (net$mode == "2-mode") {
    fn <- if ("graph_from_biadjacency_matrix" %in% getNamespaceExports("igraph")) {
      igraph::graph_from_biadjacency_matrix
    } else {
      igraph::graph_from_incidence_matrix
    }
    return(fn(m, weighted = if (is_valued(m)) TRUE else NULL))
  }
  igraph::graph_from_adjacency_matrix(
    m,
    mode = if (isTRUE(net$directed)) "directed" else "undirected",
    weighted = if (is_valued(m)) TRUE else NULL,
    diag = TRUE
  )
}

#' @rdname as_igraph
#' @export
as_network <- function(net, relation = NULL) {
  need_pkg("network", "as_network()")
  net <- as_xucinet(net)
  m <- export_matrix(net, relation, "network")
  valued <- is_valued(m)
  twomode <- net$mode == "2-mode"
  network::network(
    m,
    directed  = if (twomode) FALSE else isTRUE(net$directed),
    bipartite = if (twomode) nrow(m) else FALSE,
    loops     = nrow(m) == ncol(m) && any(diag(m) != 0),
    ignore.eval = !valued,
    names.eval  = if (valued) "weight" else NULL
  )
}

#' @rdname as_igraph
#' @export
as_tbl_graph <- function(net, relation = NULL) {
  need_pkg("tidygraph", "as_tbl_graph()")
  tidygraph::as_tbl_graph(as_igraph(net, relation = relation))
}

# The matrix to hand to another package, with the checks those packages cannot
# make for themselves.
export_matrix <- function(net, relation, target) {
  m <- pick_relation(net, relation)
  if (anyNA(m)) {
    stop(target, " has no concept of a missing tie, so a network with NAs ",
         "cannot be converted.\n",
         "  Recode them first, e.g. m[is.na(m)] <- 0.", call. = FALSE)
  }
  m
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

# UCINET holds everything as doubles; matching that keeps values stable through
# a round trip to igraph and back, and turns a character matrix (nearly always
# labels that should have been dimnames) into an error that says so.
as_numeric_matrix <- function(m) {
  if (is.logical(m) || is.integer(m)) storage.mode(m) <- "double"
  if (!is.numeric(m)) {
    stop("A network matrix must hold numbers; this one holds ", typeof(m), " values.\n",
         "  If the node labels are in the first row or column, read the file with ",
         "xread(), which takes them off for you.", call. = FALSE)
  }
  m
}

detect_mode <- function(m) {
  if (nrow(m) == ncol(m) && identical(rownames(m), colnames(m))) "1-mode" else "2-mode"
}

# Directed unless every relation is symmetric. isSymmetric() can return NA on
# matrices with missing values, so anything not provably symmetric counts as
# directed, which is also the safer assumption for a routine to report.
detect_directed <- function(mats, mode) {
  if (mode == "2-mode") return(NA)
  any(vapply(mats, function(m) !isTRUE(isSymmetric(unname(m))), logical(1)))
}

ensure_dimnames <- function(m) {
  if (is.null(rownames(m))) rownames(m) <- as.character(seq_len(nrow(m)))
  if (is.null(colnames(m))) colnames(m) <- if (ncol(m) == nrow(m)) rownames(m) else as.character(seq_len(ncol(m)))
  m
}

# Coerce every element to a numeric matrix and check that the stack is
# rectangular and consistently labelled.
harmonize_relations <- function(mats) {
  if (!length(mats)) {
    stop("A multi-relation dataset needs at least one matrix.", call. = FALSE)
  }
  nms <- names(mats)
  mats <- lapply(seq_along(mats), function(k) {
    m <- mats[[k]]
    if (inherits(m, "xucinet")) m <- as.matrix(m)
    if (is.data.frame(m)) m <- as.matrix(m)
    if (!is.matrix(m)) {
      stop("Relation ", k, " is a ", class(m)[1], "; every relation must be a matrix.",
           call. = FALSE)
    }
    as_numeric_matrix(m)
  })
  names(mats) <- nms
  dims <- lapply(mats, dim)
  if (!all(vapply(dims, identical, logical(1), dims[[1L]]))) {
    stop("All relations must have the same dimensions; got ",
         paste(vapply(dims, function(d) paste(d, collapse = "x"), ""), collapse = ", "),
         ".", call. = FALSE)
  }
  for (side in c("row", "col")) {
    get <- if (side == "row") rownames else colnames
    labs <- unique(Filter(Negate(is.null), lapply(mats, get)))
    if (length(labs) > 1L) {
      stop("Relations have different ", side, " labels; a multi-relation dataset ",
           "must describe the same nodes.", call. = FALSE)
    }
  }
  proto <- ensure_dimnames(mats[[1L]])
  out <- lapply(mats, function(m) { dimnames(m) <- dimnames(proto); m })
  names(out) <- nms
  out
}

name_relations <- function(mats) {
  nm <- names(mats)
  if (is.null(nm)) nm <- rep("", length(mats))
  nm[is.na(nm)] <- ""
  blank <- !nzchar(nm)
  nm[blank] <- paste0("relation", seq_along(nm))[blank]
  if (anyDuplicated(nm)) {
    stop("Relation names must be unique; '", nm[anyDuplicated(nm)], "' is repeated.",
         call. = FALSE)
  }
  names(mats) <- nm
  mats
}

is_valued <- function(m) any(m != 0 & m != 1, na.rm = TRUE)

edge_weight_attr <- function(g) {
  if ("weight" %in% igraph::edge_attr_names(g)) "weight" else NULL
}

igraph_biadjacency <- function(g, wt) {
  fn <- if ("as_biadjacency_matrix" %in% getNamespaceExports("igraph")) {
    igraph::as_biadjacency_matrix
  } else {
    igraph::as_incidence_matrix
  }
  fn(g, sparse = FALSE, attr = wt)
}

need_pkg <- function(pkg, what) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(what, " needs the '", pkg, "' package: install.packages(\"", pkg, "\")",
         call. = FALSE)
  }
  invisible(TRUE)
}

#' @export
as.matrix.xucinet <- function(x, relation = NULL, ...) {
  pick_relation(x, relation)
}

#' @export
dim.xucinet <- function(x) {
  d <- dim(as.matrix(x))
  if (xnrelations(x) > 1L) c(d, xnrelations(x)) else d
}
