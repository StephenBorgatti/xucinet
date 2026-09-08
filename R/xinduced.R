#' Induced centrality
#'
#' UCINET: Network | Centrality | Induced Centrality. How much of a
#' whole-network property a node is responsible for, measured by taking the node
#' out and seeing what changes.
#'
#' Nine measures, each the difference in a whole-network statistic between the
#' network as it is and the network with this node's ties stripped away. The
#' unit behind the menu item is `uc_ContributionCentrality.pas`, and three of
#' its conventions are worth stating because none is the obvious choice:
#'
#' * **The node is isolated, not deleted.** Its ties go; it stays in the graph.
#'   So `n` is the same on both sides of every subtraction, and the distance
#'   substitutions below mean the same thing on both sides.
#' * **Unreachable pairs count as `n`**, they are not skipped. That is what makes
#'   removing a cut vertex *raise* the distance total rather than lower it.
#' * **The comparison is deliberately asymmetric.** The intact figures are
#'   computed once with every node counted; each stripped figure leaves the
#'   stripped node out of the sums. Comparing like with like instead gives
#'   different numbers, and they are not UCINET's.
#'
#' `SumDist` and `Fragmentation` are reported the other way round from the rest,
#' since for those two an increase is the damage.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param k The cutoff for the "pairs within k links" column. UCINET's dialog
#'   defaults to 3, and the column is named for whatever is used: `W'in3`.
#' @return An `xucinet_output` whose `$nodes` holds the nine measures.
#' @examples
#' xinduced(campnet)
#' @export
xinduced <- function(net, relation = NULL, k = 3) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Induced centrality needs a square matrix; this one is ", nrow(m),
         " x ", ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  a <- adjacency(m)
  n <- nrow(a)

  fields <- c("within_k", "sumdist", "sumrdist", "sumoverlap", "transtriples",
              "frag", "sumbet", "sumebet", "sumrevdist")
  # SumDist and Fragmentation the other way round: for those, more is worse.
  reversed <- c(FALSE, TRUE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE, FALSE)

  intact <- induced_stats(a, ignore = 0L, k = k)
  out <- matrix(NA_real_, n, length(fields))
  for (i in seq_len(n)) {
    stripped <- a
    stripped[i, ] <- 0
    stripped[, i] <- 0
    v <- induced_stats(stripped, ignore = i, k = k)
    for (j in seq_along(fields)) {
      out[i, j] <- if (reversed[j]) v[[fields[j]]] - intact[[fields[j]]]
                   else             intact[[fields[j]]] - v[[fields[j]]]
    }
  }

  nodes <- as.data.frame(out)
  names(nodes) <- c(paste0("W'in", k), "SumDist", "Sum_iDist", "SumOverlap",
                    "Transtriples", "Fragmentation", "SumBetweenness",
                    "SumEdgeBetween", "SumRevDist")
  rownames(nodes) <- rownames(m)

  out <- new_xucinet_output(
    "Induced centrality", net,
    nodes = nodes,
    assumptions = c(
      assumptions,
      sprintf("No. of pairs within %d links of each other.", k),
      "Sum of all-pairs geodesic distances, unreachable pairs counted as n.",
      "Sum of reciprocal distances.",
      "Sum of no. of alters in common, across all pairs.",
      "No. of transitive triples.",
      "No. of pairs that cannot reach each other.",
      "Sum of every node's betweenness.",
      "Sum of every edge's betweenness.",
      "Sum of reverse distances (N - D(i,j)).",
      "SumDist and Fragmentation are calculated in reverse: X(G-k) - X(G)."),
    nodes_title = "Induced Centrality Measures",
    stats_block = FALSE,
    subclass = "xinduced", call = match.call())
  out$primary <- "SumBetweenness"
  out
}
