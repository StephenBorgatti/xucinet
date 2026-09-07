#' Beta centrality (Bonacich power)
#'
#' UCINET: Network | Centrality | Beta Centrality (Bonacich Power). Degree-like
#' when beta is zero, eigenvector-like as beta approaches its limit, and
#' something else when beta is negative: being connected to well-connected
#' others becomes a disadvantage, which is Bonacich's point about bargaining.
#'
#' Ported from `runbetacent` in `Xdpmat.pas`. The score is
#' `(I - beta*A)^-1 * A * 1`, rescaled so that the sum of squares equals the
#' number of nodes, which is UCINET's *ssq = n* normalization and its dialog
#' default.
#'
#' UCINET computes **in** centrality by default -- it transposes the matrix
#' first, so the score is comparable to indegree -- and says so in its log. That
#' is reproduced here rather than quietly changed.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param beta The attenuation parameter. `NULL`, the default, is UCINET's
#'   automatic choice: `0.999` divided by the largest eigenvalue, which is just
#'   inside the value where the series stops converging.
#' @param direction `"in"` (default, comparable to indegree, as UCINET) or
#'   `"out"`.
#' @param normalize Rescale so the sum of squares equals `n`? UCINET's default,
#'   and on by default here.
#' @return An `xucinet_output` whose `$nodes` has one column, named for the beta
#'   used, as UCINET names it: `B0.10000`.
#' @examples
#' xbeta(campnet, beta = 0.1)
#' @export
xbeta <- function(net, relation = NULL, beta = NULL,
                  direction = c("in", "out"), normalize = TRUE) {
  direction <- match.arg(direction)
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Beta centrality needs a square matrix; this one is ", nrow(m), " x ",
         ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  a <- m
  a[is.na(a)] <- 0
  if (direction == "in") a <- t(a)
  assumptions <- c(assumptions,
                   if (direction == "in")
                     "In beta centrality selected. Comparable to indegree."
                   else
                     "Out beta centrality selected. Comparable to outdegree.")

  n <- nrow(a)
  if (is.null(beta)) {
    # getbetala(net, 0.999): just inside the radius of convergence. Confirmed
    # against UCINET's own mcent log - 0.999/3 = 0.333 for campnet, and
    # 0.999/2.34292 = 0.42639 for g9_iso, both printed there to the digit.
    lambda <- max(Re(eigen(a, only.values = TRUE)$values))
    beta <- if (lambda > 0) 0.999 / lambda else 0
  }

  v <- as.vector(solve(diag(n) - beta * a) %*% a %*% rep(1, n))
  if (isTRUE(normalize)) {
    ssq <- sum(v^2)
    if (ssq > 0) v <- v * sqrt(n / ssq)
    assumptions <- c(assumptions, "Normalization method = ssq = n")
  }

  nodes <- data.frame(v, row.names = rownames(m), check.names = FALSE)
  names(nodes) <- paste0("B", formatC(beta, format = "f", digits = 5))

  out <- new_xucinet_output(
    "Beta centrality", net,
    nodes = nodes, summary = list(Beta = beta),
    assumptions = assumptions,
    nodes_title = paste0("Beta centrality for dataset ", net$title),
    stats_block = FALSE,
    subclass = "xbeta", call = match.call())
  out$primary <- names(nodes)[1]
  out
}
