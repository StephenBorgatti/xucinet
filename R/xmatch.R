# Line several datasets up on the same node set.
#
# UCINET has two routines for this and question 5.8 folds them into one, since
# R dispatches on class and does not need the user to say which they have:
#
#   uc_MatchNetAttrib.pas     a network and an attribute dataset. Keep the
#                             network's nodes, the attribute's nodes, the
#                             intersection, or the union (the default); sort
#                             by first occurrence (the default), alphabetically
#                             or numerically; labels are case sensitive.
#   uc_MatchAnyDatasets.pas   any number of datasets. Primary (the default),
#                             intersection or union; sort by the primary's
#                             order, lexicographically or numerically.
#
# Both from repository StephenBorgatti/ucinet at commit c7b4956.
#
# What a cell holds for a node that a dataset did not have: question 5.8 left
# this to be read out of the source, and it is zero. The matrices are built
# with tmat.allocsize, which is `allocate(xnr, xnc, nm, true, true)` - the
# last argument is zfill - and allocate calls zerofill, which is a fillchar
# over the row with 0. So `fill = 0` is the default here. Transform | Time
# Stack is the routine that offers missing instead, and `fill = NA` gets it.

#' Line several datasets up on the same nodes
#'
#' UCINET: Data | Match Datasets. Puts any number of networks and attribute
#' tables on one node set, in one order, so that they can be used together.
#'
#' Labels are matched exactly, including case, as UCINET's are.
#'
#' A node that a network did not have arrives with `fill` in its row and
#' column - zero by default, which is what UCINET's matrices are allocated
#' with. A node that an attribute table did not have arrives as `NA`
#' throughout instead: an unobserved tie is reasonably a zero, but an
#' unobserved attribute is not.
#'
#' @param ... The datasets: networks, attribute data frames, or a mix. Names
#'   given here name the elements of the result.
#' @param nodes Which node set to use: `"first"` (the default, UCINET's
#'   "primary"), `"last"`, `"intersection"` (only nodes every dataset has) or
#'   `"union"` (every node any of them has).
#' @param by For data frames, the column holding the labels, or `"rownames"`
#'   (the default).
#' @param sort The order: `"first"` (the default, the order they appear in),
#'   `"alphabetical"` or `"numerical"`.
#' @param fill What to put in a network cell for a node the network did not
#'   have. `0`, as UCINET allocates; `NA` gives Time Stack's behaviour.
#' @param attach Return the first network with the attribute table attached as
#'   its `$attributes`, instead of the list. Only for a call of one network
#'   and one data frame.
#' @return A named list, in argument order, of the datasets on the common node
#'   set. Networks keep their class, mode, directedness, relation stack and
#'   title; data frames stay data frames.
#' @seealso [xjoin()] to stack the result into one multi-relation dataset,
#'   which is what UCINET's Time Stack does.
#' @examples
#' a <- matrix(1, 3, 3, dimnames = list(c("x","y","z"), c("x","y","z")))
#' b <- matrix(2, 3, 3, dimnames = list(c("y","z","w"), c("y","z","w")))
#' m <- xmatch(a, b, nodes = "union")
#' as.matrix(m[[1]])
#' @export
xmatch <- function(..., nodes = c("first", "intersection", "union", "last"),
                   by = "rownames", sort = c("first", "alphabetical", "numerical"),
                   fill = 0, attach = FALSE) {
  nodes <- match.arg(nodes)
  sort <- match.arg(sort)
  sets <- list(...)
  if (length(sets) < 2) {
    stop("xmatch() lines up two or more datasets; it was given ",
         length(sets), ".", call. = FALSE)
  }
  nms <- match_names(sets, match.call(expand.dots = FALSE)$...)

  labels <- lapply(sets, dataset_labels, by = by)
  keep <- match_nodeset(labels, nodes, sort)
  if (!length(keep)) {
    stop("no nodes are left: the datasets share no labels.\n",
         "  Labels are matched exactly, including case, as UCINET's are.\n",
         "  First dataset has: ", paste(utils::head(labels[[1]], 4), collapse = ", "),
         "\n  Second has: ", paste(utils::head(labels[[2]], 4), collapse = ", "),
         call. = FALSE)
  }

  out <- vector("list", length(sets))
  for (i in seq_along(sets)) {
    dropped <- sum(!labels[[i]] %in% keep)
    added <- sum(!keep %in% labels[[i]])
    if (dropped || added) {
      message("xmatch(): ", nms[i], " - ", dropped, " node",
              if (dropped == 1) "" else "s", " dropped, ", added, " added")
    }
    out[[i]] <- match_one(sets[[i]], keep, by, fill)
  }
  names(out) <- nms

  if (attach) return(match_attach(out, nms))
  out
}

# Element names: what the caller wrote, or the dataset's own title.
match_names <- function(sets, exprs) {
  given <- names(sets)
  vapply(seq_along(sets), function(i) {
    if (!is.null(given) && nzchar(given[i])) return(given[i])
    if (inherits(sets[[i]], "xucinet")) return(sets[[i]]$title)
    deparse1(exprs[[i]])
  }, character(1))
}

dataset_labels <- function(x, by) {
  if (is.data.frame(x)) {
    if (identical(by, "rownames")) return(rownames(x))
    if (!by %in% names(x)) {
      stop("no column called \"", by, "\" to match on.\n",
           "  Available: ", paste(names(x), collapse = ", "), call. = FALSE)
    }
    return(as.character(x[[by]]))
  }
  rownames(as.matrix(as_xucinet(x)))
}

match_nodeset <- function(labels, nodes, sort) {
  keep <- switch(nodes,
                 first        = labels[[1]],
                 last         = labels[[length(labels)]],
                 union        = unique(unlist(labels, use.names = FALSE)),
                 intersection = Reduce(intersect, labels))
  keep <- unique(keep)
  switch(sort,
         first        = keep,
         alphabetical = base::sort(keep),
         numerical    = keep[order(suppressWarnings(as.numeric(keep)), keep)])
}

match_one <- function(x, keep, by, fill) {
  if (is.data.frame(x)) {
    labs <- dataset_labels(x, by)
    idx <- match(keep, labs)
    out <- x[idx, , drop = FALSE]
    rownames(out) <- keep
    return(out)
  }
  net <- as_xucinet(x)
  map_relations(net, function(m) match_matrix(m, keep, fill))
}

# A node the network did not have gets `fill` in its row and column.
match_matrix <- function(m, keep, fill) {
  out <- matrix(fill, length(keep), length(keep),
                dimnames = list(keep, keep))
  have <- intersect(keep, rownames(m))
  if (length(have)) out[have, have] <- m[have, have, drop = FALSE]
  storage.mode(out) <- "double"
  out
}

match_attach <- function(out, nms) {
  isnet <- vapply(out, function(x) inherits(x, "xucinet"), logical(1))
  isdf <- vapply(out, is.data.frame, logical(1))
  if (sum(isnet) != 1 || sum(isdf) != 1 || length(out) != 2) {
    stop("attach = TRUE wants exactly one network and one attribute table; ",
         "this call has ", sum(isnet), " network",
         if (sum(isnet) == 1) "" else "s", " and ", sum(isdf),
         " data frame", if (sum(isdf) == 1) "" else "s", ".\n",
         "  Leave it FALSE and take the list apart yourself.", call. = FALSE)
  }
  net <- out[[which(isnet)]]
  net$attributes <- out[[which(isdf)]]
  net
}
