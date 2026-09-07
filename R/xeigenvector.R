#' Eigenvector centrality
#'
#' UCINET: Network | Centrality | Eigenvector Centrality. Importance defined
#' recursively: a node is central to the extent that its neighbours are.
#'
#' Ported from `runeigencent` in `Xdpmat.pas`. The data are symmetrized by
#' maximum first, as UCINET does, and it says so in the printed report.
#'
#' On a **connected** graph this is the principal eigenvector, scaled to unit
#' length and with its sign flipped positive; the principal eigenvalue is
#' reported beside it.
#'
#' On a **disconnected** graph UCINET switches method, and so do we. A principal
#' eigenvector is only defined up to a component, so running one on a
#' disconnected graph gives everything to a single component and zero to the
#' rest, which is arithmetic rather than a finding. UCINET falls back to the
#' Everett-Borgatti lambda-squared score, `lambda^2 * sum(v) * v(i)` computed
#' within each component, which puts the components on a common footing. The
#' switch happens when more than one component has more than one node, so
#' isolates alone do not trigger it.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An `xucinet_output`. `$nodes` has one `Eigenvector` column;
#'   `$summary` carries the principal eigenvalue, or the component count when
#'   the lambda-squared method was used instead.
#' @examples
#' xeigenvector(campnet)
#' @export
xeigenvector <- function(net, relation = NULL) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Eigenvector centrality needs a square matrix; this one is ", nrow(m),
         " x ", ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  if (!isSymmetric(unname(m))) {
    assumptions <- c(assumptions, "Data automatically symmetrized by maximum.")
  }
  s <- symmetrize_max(m)
  s[is.na(s)] <- 0
  a <- adjacency(s)

  comp <- components_of(a)
  nontrivial <- n_nontrivial(comp)

  if (nontrivial > 1) {
    v <- eb_lambda_squared(a)
    if (sum(v) < 0) v <- -v
    assumptions <- c(
      assumptions,
      sprintf("Network is disconnected (%d components, %d non-trivial).",
              length(unique(comp)), nontrivial),
      "Using Everett-Borgatti lambda-squared method.")
    summary <- list(Components = length(unique(comp)),
                    `Non-trivial components` = nontrivial)
  } else {
    # UCINET runs eigen() on the symmetrized VALUED matrix here, not on the
    # dichotomized one - only the component test uses the graph.
    e <- principal_eigen(s)
    v <- e$vector
    summary <- list(`Principal eigenvalue` = e$value)
  }

  nodes <- data.frame(Eigenvector = v, row.names = rownames(m),
                      check.names = FALSE)

  out <- new_xucinet_output(
    "Eigenvector centrality", net,
    nodes = nodes, summary = summary, assumptions = assumptions,
    nodes_title = paste0("Eigenvector centrality of ", net$title),
    stats_block = FALSE,
    subclass = "xeigenvector", call = match.call())
  out$primary <- "Eigenvector"
  out
}
