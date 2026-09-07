#' Degree centrality
#'
#' UCINET: Network | Centrality | Degree. The number of ties each node has, or
#' the sum of their values when the data are valued.
#'
#' Ported from `uc_DegreeCentrality.pas` rather than from a description, so the
#' column headings, the normalization denominator and the graph centralization
#' formula are UCINET's own. Directed data gives four columns, `Outdeg`, `Indeg`,
#' `nOutdeg` and `nIndeg`; symmetric data gives `Degree` and `nDegree`. UCINET
#' can be made to print fewer by unticking boxes in its dialog; we always print
#' all of them (see the differences vignette).
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param directed `NULL` (detect from symmetry, as UCINET's *Auto-detect*),
#'   `TRUE` or `FALSE`. `FALSE` symmetrizes by union first, as UCINET does.
#' @param weighted `NULL` or `TRUE` to use tie values, `FALSE` to dichotomize at
#'   `> 0` first. UCINET's *Allow edge weights*, which defaults to on.
#' @param normalize Divide by the maximum possible degree. Both raw and
#'   normalized columns are always returned; this selects which is reported as
#'   the primary value by [summary()] and by `sort =`.
#' @param diagonal Include the diagonal? UCINET's *Exclude diagonal* defaults to
#'   on, so this defaults to `FALSE`.
#' @return An `xucinet_output`. `$nodes` holds the degree columns in original
#'   node order; `$summary` holds graph centralization, as a proportion rather
#'   than a percentage, which is what UCINET reports.
#' @examples
#' xdegree(campnet)
#'
#' # UCINET's sorted view is a printing choice, not an argument of the routine:
#' print(xdegree(campnet), sort = "Indeg")
#' @export
xdegree <- function(net, relation = NULL, directed = NULL, weighted = NULL,
                    normalize = FALSE, diagonal = FALSE) {
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Degree centrality needs a square matrix; this one is ", nrow(m), " x ",
         ncol(m), ".\n  For 2-mode data use xdegree(net, mode = ) once 2-mode ",
         "centrality lands.", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }

  # UCINET's graphtype has three settings. Auto-detect, the default, is
  # `directed := not m.issymmetric` and prints what it decided.
  if (is.null(directed)) {
    directed <- !isSymmetric(unname(m))
    assumptions <- c(assumptions,
                     sprintf("Network is directed? %s (auto-detected).",
                             if (directed) "YES" else "NO"))
  } else if (!directed) {
    m <- pmax(m, t(m))                       # sy_union, as UCINET symmetrizes
    assumptions <- c(assumptions, "Data symmetrized by union.")
  }

  # `if edgeweights.checked then maxval := summarizematrix(m).max
  #                        else begin m.dichotomize(opgt,0); maxval := 1 end`
  if (isFALSE(weighted)) {
    m <- dichotomize(m)
    maxval <- 1
    assumptions <- c(assumptions, "Data dichotomized at > 0.")
  } else {
    maxval <- max(m, na.rm = TRUE)
  }

  n <- nrow(m)
  keep <- if (diagonal) matrix(TRUE, n, n) else row(m) != col(m)
  vals <- ifelse(keep, m, 0)
  vals[is.na(vals)] <- 0
  rv <- rowSums(vals)
  cv <- colSums(vals)

  # Weighted normalization is on by default, so the denominator is
  # maxval * (n - 1); on binary data maxval is 1 and it reduces to n - 1.
  den <- maxval * (n - 1)

  # getcentralization(): (n*max - sum) / (wt * (n-1)^2)   for directed
  #                      (n*max - sum) / (wt * (n-1)(n-2)) for symmetric
  centralization <- function(v) {
    diff <- n * max(v) - sum(v)
    d <- if (directed) maxval * (n - 1) * (n - 1) else maxval * (n - 1) * (n - 2)
    if (d > 0) diff / d else NA_real_
  }

  labels <- rownames(m)
  if (directed) {
    nodes <- data.frame(Outdeg = rv, Indeg = cv,
                        nOutdeg = rv / den, nIndeg = cv / den,
                        row.names = labels, check.names = FALSE)
    summary <- list(`Out-Centralization` = centralization(rv),
                    `In-Centralization`  = centralization(cv))
  } else {
    nodes <- data.frame(Degree = rv, nDegree = rv / den,
                        row.names = labels, check.names = FALSE)
    summary <- list(Centralization = centralization(rv))
  }

  out <- new_xucinet_output(
    "Freeman degree centrality", net,
    nodes = nodes, summary = summary, assumptions = assumptions,
    nodes_title = "Degree Measures",
    summary_title = "Graph Centralization -- as proportion, not percentage",
    stats_block = FALSE,          # uc_DegreeCentrality.pas prints none
    subclass = "xdegree", call = match.call())
  # Which column summary() reports as "the" degree. Both are always in $nodes;
  # normalize picks the headline, it does not change the table (ledger entry 4).
  out$primary <- if (isTRUE(normalize)) {
    if (directed) "nOutdeg" else "nDegree"
  } else {
    if (directed) "Outdeg" else "Degree"
  }
  out
}
