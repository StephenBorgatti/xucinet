# Local Sparsification (L-Spar), as UCINET 6.850's Transform > Local
# Sparsification after UCINET-ISSUES 45 (Steve, 3 Oct 2026): tools
# G2Tools/ulspar.pas (procedure LSpar) at tools commit 50ee85b, dialog
# uc_lspar.pas at ucinet commit a0db97f. Principle (Steve): xsparsify() does
# what the fixed UCINET routine does, no more and no less.

#' Sparsify a network: local sparsification (L-Spar) or strongest ties
#'
#' UCINET: Transform | Local Sparsification. Each node keeps its
#' \eqn{\lceil d^e \rceil}{ceiling(d^e)} best ties, where \eqn{d} is its
#' degree, and a tie is kept if either of its two nodes keeps it. Because
#' \eqn{d^e} grows more slowly than \eqn{d}, nodes with many ties lose a larger
#' share of them: with `e = 0.5` a node with 100 ties keeps 10 and a node with
#' 4 keeps 2. Every node that had ties keeps at least one.
#'
#' With `method = "lspar"` (the default) a tie is scored by the Jaccard
#' similarity of the two nodes' neighborhoods (the number of nodes tied to
#' both divided by the number tied to either), the method of Satuluri,
#' Parthasarathy and Ruan (2011); equal scores are broken by the larger tie
#' value, then by node order. With `method = "value"` a tie is scored by its
#' value, so each node keeps its strongest ties; equal values are broken by
#' node order, and on data whose ties all have the same value (binary data)
#' the result depends only on the order of the nodes, so there is a warning.
#'
#' L-Spar is defined for undirected networks. Degrees, neighborhoods, scores
#' and the keep decisions use the symmetrized network: a tie between `i` and
#' `j` if either cell is non-zero, scored by the larger of the two values,
#' the diagonal ignored. A pair that is kept keeps both of its original cells,
#' so directed values survive; a pair that is dropped becomes 0. A missing
#' cell counts as no tie and stays missing. `e = 1` returns the network
#' unchanged.
#'
#' @param net A network (any accepted form), 1-mode. Each relation of a
#'   multi-relation dataset is sparsified on its own.
#' @param e The exponent, greater than 0 and at most 1; 0.5 by default.
#'   Smaller values give sparser networks.
#' @param method `"lspar"` (rank ties by neighborhood overlap, the default)
#'   or `"value"` (rank them by tie value).
#' @return An `xucinet` object titled as UCINET names it (`campnet-lspar`),
#'   with a `history` attribute giving `e`, the ranking, and the numbers of
#'   original and retained ties (pairs of the symmetrized network) with the
#'   percentage retained.
#' @references Satuluri, V., Parthasarathy, S. and Ruan, Y. (2011). Local
#'   graph sparsification for scalable clustering. *Proceedings of the 2011
#'   ACM SIGMOD International Conference on Management of Data*, 721-732.
#' @seealso [xdichotomize()] for a single cut-off for every node;
#'   [xaffiliations()] with `method = "sdsm"` for the backbone of a 2-mode
#'   projection.
#' @examples
#' s <- xsparsify(campnet)
#' attr(s, "history")
#' xsparsify(campnet, e = 0.3)
#' @export
xsparsify <- function(net, e = 0.5, method = c("lspar", "value")) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  if (identical(net$mode, "2-mode")) {
    stop("xsparsify() needs a 1-mode network; this dataset is 2-mode (",
         nrow(as.matrix(net)), " rows by ", ncol(as.matrix(net)), " columns).\n",
         "  For the projection of a 2-mode network, xaffiliations(net, method = \"sdsm\")\n",
         "  keeps only the ties stronger than expected (the backbone).", call. = FALSE)
  }
  if (!is.numeric(e) || length(e) != 1 || is.na(e) || e <= 0 || e > 1) {
    stop("e must be one number greater than 0 and at most 1.", call. = FALSE)
  }

  notes <- character(0)
  out <- map_relations(net, function(m) {
    r <- sparsify_matrix(m, e, method)
    if (method == "value" && r$equal) {
      warning("all ties have the same value, so ranking by value keeps ties by ",
              "node order only.\n  For binary data use method = \"lspar\".", call. = FALSE)
    }
    notes <<- c(notes, sparsify_note(r, e, method))
    r$net
  })
  transformed(out, "-lspar", paste(notes, collapse = "; "))
}

# The keep count: ceiling(d^e), with a small tolerance so that a whole power
# such as 4^0.5 is not pushed up by rounding (ulspar.LSparKeep).
sparsify_keep <- function(d, e) {
  pmin(d, pmax(1, ceiling(d^e - 1e-9)))
}

sparsify_matrix <- function(m, e, method) {
  present <- !is.na(m) & m != 0
  diag(present) <- FALSE
  adj <- present | t(present)
  cl <- m; cl[is.na(cl)] <- 0
  w <- pmax(cl, t(cl))
  tiev <- w[upper.tri(w) & adj]
  retain <- matrix(FALSE, nrow(m), ncol(m))
  for (i in seq_len(nrow(m))) {
    nb <- which(adj[i, ])
    d <- length(nb)
    if (!d) next
    if (method == "value") {
      ord <- order(-w[i, nb], nb)
    } else {
      score <- vapply(nb, function(j) {
        sum(adj[i, ] & adj[j, ]) / sum(adj[i, ] | adj[j, ])
      }, numeric(1))
      ord <- order(-score, -w[i, nb], nb)
    }
    retain[i, nb[ord[seq_len(sparsify_keep(d, e))]]] <- TRUE
  }
  kept <- (retain | t(retain)) & adj
  y <- m
  y[!kept & !is.na(m)] <- 0
  diag(y) <- diag(m)
  list(net = y, original = sum(adj[upper.tri(adj)]), retained = sum(kept[upper.tri(kept)]),
       symmetric = isSymmetric(unname(cl)),
       equal = length(tiev) > 0 && all(tiev == tiev[1]))
}

# What UCINET's log reports: e, the ranking, the counts and the percentage,
# and that the ranking used the symmetrized network when the input is not
# symmetric.
sparsify_note <- function(r, e, method) {
  pct <- if (r$original > 0) 100 * r$retained / r$original else 0
  paste0("sparsified (", if (method == "lspar") "L-Spar, neighborhood overlap" else "tie value",
         ", e = ", format(e), "): ", r$retained, " of ", r$original, " ties kept (",
         formatC(pct, format = "f", digits = 1), "%)",
         if (!r$symmetric) ", ranked on the symmetrized network")
}
