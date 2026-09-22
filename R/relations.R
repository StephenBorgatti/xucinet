# Building, splitting and collapsing multi-relation datasets.
#
# Ported from the UCINET Delphi, repository StephenBorgatti/ucinet at commit
# c7b4956:
#
#   xjoin       Data | Join | Join Matrices (uc_JoinMatrices.pas), with
#               Join Rows and Join Columns (uc_JoinRows, uc_JoinColumns) as
#               the other two modes
#   xunpack     Data | Unpack (uc_UnPack.pas)
#   xcombine    Transform | Matrix Operations | Within dataset | Aggregations
#               (xwithindatasetaggregations.pas) and its between-datasets
#               twin (xbetweendatasetaggregations.pas)
#   xmultiplex  Transform | Graph Theoretic | Multiplex (uc_MultiplexCoder.pas)

#' Join datasets into one
#'
#' UCINET: Data | Join. Puts several datasets together, either side by side,
#' one above the other, or as the relations of one multi-relation dataset.
#'
#' @param ... The datasets, or a single list of them. Names given here name
#'   the relations.
#' @param mode `"col"` (the default) appends columns, so a 50 x 3 and a
#'   50 x 4 make a 50 x 7; `"row"` appends rows; `"mat"` stacks the datasets
#'   as the relations of one dataset, which is UCINET's Join Matrices and
#'   needs them all the same shape.
#' @param names Relation names for `mode = "mat"`, if the argument names and
#'   the titles are not what is wanted.
#' @return An `xucinet` object. For `"mat"`, a multi-relation dataset; for the
#'   other two, a single matrix.
#' @seealso [xunpack()] to take one apart, [xcombine()] to collapse the
#'   relations into one matrix, and [xmatch()] to line up datasets whose node
#'   sets differ before joining them - which together are what UCINET's
#'   Transform | Time Stack does.
#' @examples
#' a <- matrix(1, 3, 2, dimnames = list(c("x","y","z"), c("p","q")))
#' b <- matrix(2, 3, 1, dimnames = list(c("x","y","z"), "r"))
#' as.matrix(xjoin(a, b))
#'
#' # as relations instead
#' xrelations(xjoin(advice = campnet, friends = campnet, mode = "mat"))
#' @export
xjoin <- function(..., mode = c("col", "row", "mat"), names = NULL) {
  mode <- match.arg(mode)
  sets <- list(...)
  # Captured before any unwrapping, so that a bare matrix is titled with what
  # the caller wrote rather than with lapply's loop variable.
  exprs <- match.call(expand.dots = FALSE)$...
  if (length(sets) == 1 && is.list(sets[[1]]) && !inherits(sets[[1]], "xucinet")) {
    sets <- sets[[1]]
    exprs <- NULL
  }
  if (length(sets) < 2) {
    stop("xjoin() joins two or more datasets; it was given ", length(sets),
         ".", call. = FALSE)
  }
  nets <- lapply(seq_along(sets), function(i) {
    if (inherits(sets[[i]], "xucinet") || is.null(exprs)) as_xucinet(sets[[i]])
    else as_xucinet(sets[[i]], title = deparse1(exprs[[i]]))
  })
  labs <- join_labels(nets, sets, names)

  if (identical(mode, "mat")) return(join_stack(nets, labs))
  join_bind(nets, labs, mode)
}

join_labels <- function(nets, sets, names) {
  if (!is.null(names)) {
    if (length(names) != length(nets)) {
      stop("names has ", length(names), " entries for ", length(nets),
           " datasets.", call. = FALSE)
    }
    return(names)
  }
  given <- base::names(sets)
  vapply(seq_along(nets), function(i) {
    if (!is.null(given) && nzchar(given[i])) given[i] else nets[[i]]$title
  }, character(1))
}

# Join Matrices: one relation per dataset, all the same shape and labels.
join_stack <- function(nets, labs) {
  mats <- lapply(nets, function(n) as.matrix(n))
  dims <- vapply(mats, function(m) paste(dim(m), collapse = "x"), character(1))
  if (length(unique(dims)) > 1) {
    stop("mode = \"mat\" stacks datasets as relations, so they must be the ",
         "same shape.\n  Got ", paste(unique(dims), collapse = " and "),
         ".\n  Line them up with xmatch() first.", call. = FALSE)
  }
  same <- vapply(mats, function(m) identical(rownames(m), rownames(mats[[1]])),
                 logical(1))
  if (!all(same)) {
    stop("mode = \"mat\" needs the same node labels in the same order.\n",
         "  Line them up with xmatch() first.", call. = FALSE)
  }
  base::names(mats) <- make.unique(labs)
  out <- as_xucinet(mats)
  out$title <- paste(labs, collapse = "+")
  attr(out, "history") <- paste0("joined ", length(mats), " datasets as relations")
  out
}

# Join Rows / Join Columns: append, and keep every label distinct.
join_bind <- function(nets, labs, mode) {
  mats <- lapply(nets, as.matrix)
  if (identical(mode, "col")) {
    rows <- lapply(mats, rownames)
    if (length(unique(vapply(mats, nrow, integer(1)))) > 1) {
      stop("mode = \"col\" appends columns, so every dataset needs the same ",
           "number of rows.\n  Got ",
           paste(vapply(mats, nrow, integer(1)), collapse = ", "),
           ".\n  Line them up with xmatch() first.", call. = FALSE)
    }
    if (!all(vapply(rows, identical, logical(1), rows[[1]]))) {
      stop("mode = \"col\" needs the same row labels in the same order.\n",
           "  Line them up with xmatch() first.", call. = FALSE)
    }
    out <- do.call(cbind, mats)
    colnames(out) <- make.unique(unlist(lapply(mats, colnames), use.names = FALSE))
  } else {
    cols <- lapply(mats, colnames)
    if (!all(vapply(cols, identical, logical(1), cols[[1]]))) {
      stop("mode = \"row\" needs the same column labels in the same order.\n",
           "  Line them up with xmatch() first.", call. = FALSE)
    }
    out <- do.call(rbind, mats)
    rownames(out) <- make.unique(unlist(lapply(mats, rownames), use.names = FALSE))
  }
  res <- as_xucinet(out)
  res$title <- paste(labs, collapse = "+")
  attr(res, "history") <- paste0("joined ", length(mats), " datasets by ", mode)
  res
}

#' Split a multi-relation dataset into single relations
#'
#' UCINET: Data | Unpack. The other half of [xjoin()].
#'
#' @param net A multi-relation network.
#' @param relation Which relation, by name or position. `NULL`, the default,
#'   returns every one.
#' @param prefix Put in front of each relation's name to title the dataset it
#'   becomes. UCINET's dialog offers the same.
#' @return A named list of one-relation `xucinet` objects, or a single one
#'   when `relation` is given.
#' @seealso [xjoin()], [xcombine()].
#' @examples
#' parts <- xunpack(hightech)
#' names(parts)
#' xunpack(hightech, "Advice")
#' @export
xunpack <- function(net, relation = NULL, prefix = "") {
  net <- xnet(net, substitute(net))
  rels <- xrelations(net)
  mats <- relation_matrices(net)

  one <- function(i) {
    out <- new_xucinet(mats[[i]], mode = net$mode, directed = net$directed,
                       title = paste0(prefix, rels[i]))
    attr(out, "history") <- paste0("unpacked from ", net$title)
    out
  }
  if (!is.null(relation)) {
    i <- if (is.character(relation)) match(relation, rels) else as.integer(relation)
    if (is.na(i) || i < 1 || i > length(mats)) {
      stop("no relation \"", relation, "\".\n  Available: ",
           paste(rels, collapse = ", "), call. = FALSE)
    }
    return(one(i))
  }
  out <- lapply(seq_along(mats), one)
  names(out) <- rels
  out
}

#' Collapse the relations of a dataset into one matrix
#'
#' UCINET: Transform | Matrix Operations | Within dataset | Aggregations, and
#' the between-datasets form of the same thing.
#'
#' @param net A multi-relation network, or a list of separate networks with
#'   matching labels.
#' @param relations Which relations to use, by name or position. `NULL`, the
#'   default, uses all of them.
#' @param method `"sum"` (the dialog's default), `"mean"`, `"min"`, `"max"`,
#'   `"sd"` (the population form) or `"product"` (UCINET's elementwise
#'   multiplication).
#' @param diagonal Include the diagonal? `FALSE` by default, as the dialog's
#'   "diagonal valid" is; when `FALSE` the diagonal of a square result comes
#'   back missing rather than summarised.
#' @return A single-relation `xucinet` object.
#' @seealso [xjoin()], [xunpack()], [xmultiplex()].
#' @examples
#' as.matrix(xcombine(hightech))[1:4, 1:4]
#' as.matrix(xcombine(hightech, method = "max"))[1:4, 1:4]
#' @export
xcombine <- function(net, relations = NULL,
                     method = c("sum", "mean", "min", "max", "sd", "product"),
                     diagonal = FALSE) {
  method <- match.arg(method)
  if (is.list(net) && !inherits(net, "xucinet")) net <- xjoin(net, mode = "mat")
  net <- xnet(net, substitute(net))
  mats <- relation_matrices(net)
  rels <- xrelations(net)

  if (!is.null(relations)) {
    i <- if (is.character(relations)) match(relations, rels) else as.integer(relations)
    if (anyNA(i)) {
      stop("no relation \"", relations[is.na(i)][1], "\".\n  Available: ",
           paste(rels, collapse = ", "), call. = FALSE)
    }
    mats <- mats[i]; rels <- rels[i]
  }
  if (length(mats) < 2) {
    stop("xcombine() collapses two or more relations; this dataset has ",
         length(mats), ".", call. = FALSE)
  }

  cube <- array(unlist(mats), dim = c(dim(mats[[1]]), length(mats)))
  out <- apply(cube, c(1, 2), function(v) combine_stat(v, method))
  if (!diagonal && nrow(out) == ncol(out)) diag(out) <- NA_real_
  dimnames(out) <- dimnames(mats[[1]])

  res <- new_xucinet(out, mode = net$mode, directed = net$directed,
                     title = net$title)
  transformed(res, "-agg",
              paste0("combined ", length(mats), " relations (", method, "): ",
                     paste(rels, collapse = ", ")))
}

combine_stat <- function(v, method) {
  v <- v[!is.na(v)]
  if (!length(v)) return(NA_real_)
  switch(method,
         sum     = sum(v),
         mean    = mean(v),
         min     = min(v),
         max     = max(v),
         product = prod(v),
         sd      = sqrt(mean((v - mean(v))^2)))
}

#' Code which relations hold each tie
#'
#' UCINET: Transform | Graph Theoretic | Multiplex. Replaces a stack of
#' relations with one matrix whose value in each cell says *which* of them
#' have a tie there.
#'
#' Relation *k* contributes `2^(k-1)`, so the code read as binary has one
#' digit per relation. A cell of 5 in a three-relation dataset means relations
#' 1 and 3 and not 2.
#'
#' @param net A multi-relation network.
#' @return A single-relation `xucinet` object of codes, with the legend - each
#'   code against the relations it stands for - in its `history` attribute.
#' @seealso [xcombine()] to summarise the relations numerically instead.
#' @examples
#' m <- xmultiplex(hightech)
#' as.matrix(m)[1:4, 1:4]
#' cat(attr(m, "history"), sep = "\n")
#' @export
xmultiplex <- function(net) {
  net <- xnet(net, substitute(net))
  mats <- relation_matrices(net)
  rels <- xrelations(net)
  if (length(mats) < 2) {
    stop("xmultiplex() codes which of several relations hold each tie; this ",
         "dataset has ", length(mats), ".", call. = FALSE)
  }

  out <- matrix(0, nrow(mats[[1]]), ncol(mats[[1]]),
                dimnames = dimnames(mats[[1]]))
  for (k in seq_along(mats)) {
    # `if (d.cell[k,i,j] > 0) and (d.cell[k,i,j] < na)` - positive and present.
    hit <- !is.na(mats[[k]]) & mats[[k]] > 0
    out[hit] <- out[hit] + 2^(k - 1)
  }

  res <- new_xucinet(out, mode = net$mode, directed = net$directed,
                     title = net$title)
  transformed(res, "-mpx",
              c("multiplex codes", multiplex_legend(out, rels)))
}

# The legend the log prints: every code that occurs, and what it stands for.
multiplex_legend <- function(out, rels) {
  codes <- sort(unique(as.vector(out)))
  vapply(codes, function(code) {
    bits <- which(bitwAnd(as.integer(code), 2L^(seq_along(rels) - 1)) > 0)
    paste0("  ", code, " = ",
           if (!length(bits)) "none" else paste(rels[bits], collapse = " + "))
  }, character(1))
}
