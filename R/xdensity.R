#' Density and average degree
#'
#' UCINET: Network | Whole Networks | Density | Density Overall. Phase 0 pilot
#' routine: the first function golden-tested against UCINET output, and the
#' template every later routine follows.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position (SPEC D4). Defaults to the first. Reporting every relation as its
#'   own section is still to come.
#' @param directed `NULL` (detect), `TRUE` or `FALSE`. Detection is reported as
#'   an assumption in the printed output.
#' @param weighted `NULL` (use values if the matrix is valued), `TRUE` or
#'   `FALSE` (dichotomize at > 0 first).
#' @param diagonal Logical; include the diagonal? UCINET's default is `FALSE`.
#' @return An object of class `c("xdensity", "xucinet_output")` with `$summary`
#'   holding density, number of ties, standard deviation and average degree;
#'   one section per relation for multi-relation data.
#'
#'   For 2-mode data average degree is reported twice, as
#'   `Avg Degree (rows)` and `Avg Degree (cols)`, because neither margin is
#'   "the" node set. UCINET reports the column figure alone; see the
#'   differences vignette.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
#' xdensity(m)
#'
#' # a dataset name works too, as it does on UCINET's command line
#' xdensity("campnet")
#' xdensity(hightech, relation = "Friendship")
#' @export
xdensity <- function(net, relation = NULL, directed = NULL, weighted = NULL,
                     diagonal = FALSE) {
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else
                               xrelations(net)[if (is.character(relation))
                                 match(relation, xrelations(net)) else relation],
                             xnrelations(net)))
  }
  if (is.null(directed)) {
    assumptions <- c(assumptions, sprintf("Data treated as %s (detected from symmetry).",
                                          if (isTRUE(net$directed)) "directed" else "undirected"))
  }
  # A 2-mode matrix has no diagonal to leave out: cell (i,i) is row-node i tied
  # to column-node i, two different things. UCINET counts every cell, and says
  # so in its own log ("Dataset DAVIS treated as 2-mode because it is not
  # square"). Excluding a pseudo-diagonal put our davis density at 0.324 against
  # UCINET's 0.353.
  twomode <- identical(net$mode, "2-mode")
  valued <- any(m != 0 & m != 1, na.rm = TRUE)
  if (isFALSE(weighted) && valued) {
    m <- dichotomize(m, twomode = twomode)
    assumptions <- c(assumptions, "Data dichotomized at > 0.")
  }
  cells <- if (diagonal || twomode) as.vector(m) else m[row(m) != col(m)]
  cells <- cells[!is.na(cells)]
  density <- mean(cells)
  ties <- sum(cells != 0)
  # UCINET divides the total by the number of COLUMNS, so davis reports 89/14
  # rather than 89/18. Every square network agrees either way, so only 2-mode
  # data tells the denominators apart.
  #
  # RESOLVED (Steve, 6 Sep 2026): for a 2-mode network neither margin is "the"
  # node set, so we report both rather than pick the one UCINET picked. A square
  # network is unaffected - nrow and ncol are the same number - so this is the
  # single "Avg Degree" line everywhere except 2-mode data. See ledger entry 2.
  total <- sum(cells)
  avg_degree <- if (twomode) {
    list("Avg Degree (rows)" = total / nrow(m),
         "Avg Degree (cols)" = total / ncol(m))
  } else {
    list("Avg Degree" = total / ncol(m))
  }
  # Column order is UCINET's own, from its Density report: Density, No. of Ties,
  # Std Dev, Avg Degree. Std Dev is the population form - uestimator.calc in
  # ustats.pas sets variance := mcssq/n, not mcssq/(n-1), and UCINET's report
  # for campnet prints 0.381 where stats::sd() would give 0.382.
  summary <- c(list("Density" = density,
                    "No. of Ties" = ties,
                    "Std Dev" = uci_stats(cells)[["Std Dev"]]),
               avg_degree)
  new_xucinet_output("Density / Average Matrix Value", net, summary = summary,
                     assumptions = assumptions, subclass = "xdensity",
                     call = match.call())
}
