# Geodesic distances.
#
# Ported from uc_geodesicdistances.pas / .dfm (repository StephenBorgatti/ucinet
# at commit c7b4956), procedures cleanup0, cleanup1 and setdiagonalvalues. The
# search itself is the shared `geodesics()` in R/centrality-internals.R, which
# the chapter 9 routines already use; there is one breadth-first search in this
# package, not two.
#
# The dialog's defaults move with the transformation, which the .dfm alone does
# not show. TransformationOptionsClick sets them:
#
#   no transformation   undefined.ItemIndex  := 0  (missing values)
#                       setdiagonal.ItemIndex := 1  (zero)
#   reciprocal          rundefined.ItemIndex := 3  (zero)
#                       setdiagonal.ItemIndex := 0  (missing value)
#
# Design question G2 rule (a) makes this a dataset rather than a report: a
# distance matrix is something you save and feed to the next routine, and
# `xmds(xgeodesic(net), type = "d")` has to work.

#' Geodesic distances
#'
#' UCINET: Network | Cohesion | Geodesic Distances. The number of steps in the
#' shortest path between every pair of nodes.
#'
#' The dialog takes a non-valued adjacency matrix, so valued data are
#' dichotomized at `> 0` first and the history says so. Unreachable pairs and
#' the diagonal are filled in afterwards, exactly as `cleanup0`, `cleanup1`
#' and `setdiagonalvalues` do, and the defaults follow the transformation the
#' way the dialog's own defaults do.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param directed `NULL` (detect), `TRUE` or `FALSE`. An undirected network is
#'   symmetrized with the maximum first, so a tie either way is a step.
#' @param reciprocal Return `1 / distance` instead of the distance, UCINET's
#'   "Reciprocal distances" transformation. Nearness rather than farness, so
#'   unreachable pairs sit at the bottom of the scale rather than the top.
#' @param unreachable What to put where there is no path. `"missing"`, `"n"`
#'   (the number of nodes) or `"max+1"` (one more than the longest distance
#'   found); with `reciprocal = TRUE` those become `NA`, `1/n` and
#'   `1/(max+1)`, and `"zero"` is offered as well. `NULL`, the default, takes
#'   the dialog's: `"missing"` without the transformation and `"zero"` with
#'   it.
#' @param diagonal What to put on the diagonal: `0`, `1` or `NA`. `NULL`, the
#'   default, takes the dialog's: `0` without the transformation and `NA` with
#'   it.
#' @return An `xucinet` object titled `<name>-geo`, with a `history` attribute
#'   carrying the average and standard deviation of the off-diagonal
#'   distances and the frequency table of distance values, which is what
#'   UCINET's log prints beneath the matrix.
#' @seealso [xbetweenness()], which counts geodesics rather than measuring
#'   them, and [xmds()], which will scale the result.
#' @examples
#' g <- xgeodesic(campnet)
#' as.matrix(g)[1:4, 1:4]
#' attr(g, "history")
#'
#' # nearness instead of farness
#' as.matrix(xgeodesic(campnet, reciprocal = TRUE))[1:4, 1:4]
#' @export
xgeodesic <- function(net, directed = NULL, reciprocal = FALSE,
                      unreachable = NULL, diagonal = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xgeodesic()")

  # TransformationOptionsClick: the two defaults that move with the transform.
  if (is.null(unreachable)) unreachable <- if (reciprocal) "zero" else "missing"
  unreachable <- match.arg(unreachable, c("missing", "n", "max+1", "zero"))
  if (identical(unreachable, "zero") && !reciprocal) {
    stop("unreachable = \"zero\" is only offered with reciprocal = TRUE.\n",
         "  Without the transformation a distance of zero would mean the ",
         "closest possible pair, not the furthest.\n",
         "  Use \"missing\", \"n\" or \"max+1\".", call. = FALSE)
  }
  if (is.null(diagonal)) diagonal <- if (reciprocal) NA_real_ else 0
  if (!(length(diagonal) == 1 && (is.na(diagonal) || diagonal %in% c(0, 1)))) {
    stop("diagonal must be 0, 1 or NA, the three the dialog offers.",
         call. = FALSE)
  }

  notes <- character(0)
  out <- map_relations(net, function(m) {
    res <- geodesic_matrix(m, directed, reciprocal, unreachable, diagonal)
    notes <<- c(notes, res$note)
    res$m
  })
  transformed(out, "-geo", paste(notes, collapse = "; "))
}

geodesic_matrix <- function(m, directed, reciprocal, unreachable, diagonal) {
  note <- character(0)
  if (is_valued(m)) note <- c(note, "data dichotomized at > 0")
  a <- adjacency(m)
  if (is.null(directed)) directed <- !isTRUE(isSymmetric(unname(a)))
  if (!directed) {
    a <- symmetrize_max(a)
    note <- c(note, "treated as undirected")
  }

  d <- geodesics(a)
  off <- row(d) != col(d)
  gone <- off & is.na(d)
  # s.max: the longest distance actually found, used by "max+1".
  longest <- suppressWarnings(max(d[off & !is.na(d)]))
  if (!is.finite(longest)) longest <- 0

  # cleanup0 / cleanup1, off-diagonal cells only.
  fill <- switch(unreachable,
                 missing = NA_real_,
                 n       = nrow(d),
                 "max+1" = longest + 1,
                 zero    = 0)
  if (reciprocal) {
    d[off & !is.na(d)] <- 1 / d[off & !is.na(d)]
    d[gone] <- switch(unreachable,
                      missing = NA_real_,
                      n       = 1 / nrow(d),
                      "max+1" = 1 / (longest + 1),
                      zero    = 0)
  } else {
    d[gone] <- fill
  }
  diag(d) <- diagonal

  note <- c(note, geodesic_stats(d, off))
  if (any(gone)) {
    note <- c(note, paste0(sum(gone), " unreachable pair",
                           if (sum(gone) == 1) "" else "s", " set to ",
                           unreachable))
  }
  dimnames(d) <- dimnames(m)
  list(m = d, note = paste(note, collapse = "; "))
}

# What the log prints under the matrix: the average and standard deviation of
# the off-diagonal distances, and their frequency table.
geodesic_stats <- function(d, off) {
  v <- d[off]
  v <- v[!is.na(v)]
  if (!length(v)) return("no defined distances")
  tab <- table(v)
  paste0("average ", format(round(mean(v), 4)),
         ", sd ", format(round(sqrt(mean((v - mean(v))^2)), 4)),
         ", distances ",
         paste(names(tab), tab, sep = ":", collapse = " "))
}
