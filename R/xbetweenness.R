#' Freeman betweenness centrality
#'
#' UCINET: Network | Centrality | Freeman Betweenness | Node Betweenness. How
#' often a node lies on the shortest path between two others.
#'
#' Ported from `XFreeBet.pas`. The data are dichotomized at `> 0` and the
#' diagonal ignored before anything else happens, which is what UCINET's
#' `copyfromtmat` does, so a valued matrix is treated as the graph underneath it.
#'
#' Two conventions here are worth stating because they are easy to get subtly
#' wrong. UCINET computes the directed count and halves it for symmetric data,
#' but normalizes the **un-halved** count by `(n-1)(n-2)`, which comes to the
#' same thing as the usual undirected formula and differs from it by a factor of
#' two if you take the halved value by mistake. And the normalized column is a
#' percentage, not a proportion, unlike the centralization figure `xdegree()`
#' reports.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param directed `NULL` (detect from symmetry), `TRUE` or `FALSE`.
#' @param normalize Selects which column [summary()] reports as the headline.
#'   Both are always in `$nodes`.
#' @return An `xucinet_output`. `$nodes` has `Betweenness` and `nBetweenness`;
#'   `$summary` has the un-normalized centralization and the network
#'   centralization index, as UCINET prints both.
#' @examples
#' xbetweenness(campnet)
#' @export
xbetweenness <- function(net, relation = NULL, directed = NULL,
                         normalize = FALSE) {
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Betweenness needs a square matrix; this one is ", nrow(m), " x ",
         ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  a <- adjacency(m)
  if (any(m > 1, na.rm = TRUE)) {
    assumptions <- c(assumptions, "Data dichotomized at > 0.")
  }
  sym <- if (is.null(directed)) isSymmetric(unname(a)) else !directed
  if (!is.null(directed) && !directed) a <- adjacency(symmetrize_max(a))

  n <- nrow(a)
  cb <- brandes(a)
  bet <- if (sym) cb / 2 else cb

  # 100 * cb / (n-1)(n-2) - the UN-halved count, deliberately.
  den <- if (n > 2) (n - 1) * (n - 2) else 0
  nbet <- if (den > 0) 100 * cb / den else rep(NA_real_, n)

  # netcent := sum(maxb - bet); then 200*netcent/((n-1)^2 (n-2)), halved again
  # when the data are directed.
  raw_cent <- sum(max(bet) - bet)
  d2 <- (n - 1)^2 * (n - 2)
  index <- if (d2 > 0) 200 * raw_cent / d2 else NA_real_
  if (!sym) index <- index / 2

  nodes <- data.frame(Betweenness = bet, nBetweenness = nbet,
                      row.names = rownames(m), check.names = FALSE)

  out <- new_xucinet_output(
    "Freeman betweenness centrality", net,
    nodes = nodes,
    summary = list(`Un-normalized centralization` = raw_cent,
                   `Network Centralization Index (%)` = index),
    assumptions = assumptions,
    nodes_title = "Betweenness Measures",
    stats_block = TRUE,           # XFreeBet.pas prints one
    subclass = "xbetweenness", call = match.call())
  out$primary <- if (isTRUE(normalize)) "nBetweenness" else "Betweenness"
  out
}
