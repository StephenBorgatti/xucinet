#' Reach centrality
#'
#' UCINET: Network | Centrality | Reach Centrality. How much of the network a
#' node can get to, and how quickly.
#'
#' Three things are reported. `$nodes` holds the two summary measures UCINET
#' calls `dwr` and `ard`: distance-weighted reach, the sum of the reciprocals of
#' a node's geodesic distances, and average reciprocal distance, the same figure
#' divided by `n - 1`. `$matrices$ReachProp` holds the wide table -- the
#' proportion of the network a node reaches within one step, two steps, and so
#' on to `n - 1`.
#'
#' Unreachable pairs contribute nothing, so a node in a small component simply
#' plateaus early: on a disconnected graph the row stops rising at the size of
#' its own component. That is the natural reading and it is what UCINET does.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param directed `NULL` (detect from symmetry), `TRUE` or `FALSE`. Directed
#'   data is reported out-wards; use `direction = "in"` for the other.
#' @param direction `"out"` (default) or `"in"`. UCINET reports both for
#'   directed data, in separate tables.
#' @return An `xucinet_output`.
#' @examples
#' xreach(campnet)
#' @export
xreach <- function(net, relation = NULL, directed = NULL,
                   direction = c("out", "in")) {
  direction <- match.arg(direction)
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Reach centrality needs a square matrix; this one is ", nrow(m), " x ",
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
  sym <- if (is.null(directed)) isSymmetric(unname(a)) else !directed
  if (!is.null(directed) && !directed) a <- adjacency(symmetrize_max(a))

  n <- nrow(a)
  d <- geodesics(a)
  if (direction == "in") d <- t(d)

  reached <- function(k) rowSums(d <= k & d > 0, na.rm = TRUE) / (n - 1)
  prop <- vapply(seq_len(n - 1), reached, numeric(n))
  dim(prop) <- c(n, n - 1)
  dimnames(prop) <- list(rownames(m), paste0("Dist", seq_len(n - 1)))

  rr <- 1 / d
  rr[!is.finite(rr)] <- 0
  dwr <- rowSums(rr)

  nodes <- data.frame(dwr = dwr, ard = dwr / (n - 1),
                      row.names = rownames(m), check.names = FALSE)

  if (!sym) {
    assumptions <- c(assumptions,
                     sprintf("Directed data; reporting %s-bound reach.", direction))
  }

  out <- new_xucinet_output(
    "Reach centrality", net,
    nodes = nodes,
    matrices = stats::setNames(
      list(prop),
      "ReachProp: Proportion of nodes that ego can reach in D steps"),
    assumptions = assumptions,
    nodes_title = "ReachSummary: Distance-weighted Reach & Avg Reciprocal Distance",
    stats_block = FALSE,
    subclass = "xreach", call = match.call())
  out$primary <- "ard"
  out
}


#' Beta reach centrality
#'
#' UCINET: Network | Centrality | Beta Reach Centrality. Reach with distance
#' discounted rather than ignored: a node two steps away counts `beta` as much
#' as one a single step away, three steps `beta` squared, and so on.
#'
#' The score is `sum(beta^(d - 1)) / (n - 1)` over the nodes a node can reach.
#' At `beta = 1` it is the plain proportion reachable; at `beta = 0` it is
#' degree over `n - 1`. UCINET's dialog defaults to 0.8 and so does this.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param beta The distance discount, between 0 and 1. UCINET's default is 0.8.
#' @param directed `NULL` (detect from symmetry), `TRUE` or `FALSE`.
#' @param direction `"out"` (default) or `"in"`.
#' @return An `xucinet_output` whose `$nodes` has one `Beta Reach` column.
#' @examples
#' xbetareach(campnet)
#' @export
xbetareach <- function(net, relation = NULL, beta = 0.8, directed = NULL,
                       direction = c("out", "in")) {
  direction <- match.arg(direction)
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Beta reach needs a square matrix; this one is ", nrow(m), " x ",
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
  sym <- if (is.null(directed)) isSymmetric(unname(a)) else !directed
  if (!is.null(directed) && !directed) a <- adjacency(symmetrize_max(a))

  n <- nrow(a)
  d <- geodesics(a)
  if (direction == "in") d <- t(d)

  w <- beta^(d - 1)
  w[is.na(d) | d == 0] <- 0
  v <- rowSums(w) / (n - 1)

  nodes <- data.frame(`Beta Reach` = v, row.names = rownames(m),
                      check.names = FALSE)

  out <- new_xucinet_output(
    "Beta reach", net,
    nodes = nodes, summary = list(Beta = beta),
    assumptions = c(assumptions,
                    sprintf("Type of data: %s.",
                            if (sym) "Undirected" else "Directed")),
    nodes_title = "Beta Reach Scores",
    stats_block = FALSE,
    subclass = "xbetareach", call = match.call())
  out$primary <- "Beta Reach"
  out
}
