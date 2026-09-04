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
#'   holding density, average degree, standard deviation of ties, and number
#'   of ties; one section per relation for multi-relation data.
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
  valued <- any(m != 0 & m != 1, na.rm = TRUE)
  if (isFALSE(weighted) && valued) {
    m <- (m > 0) * 1
    assumptions <- c(assumptions, "Data dichotomized at > 0.")
  }
  if (!diagonal) diag(m) <- NA
  n <- nrow(m)
  cells <- if (diagonal) m else m[row(m) != col(m)]
  cells <- cells[!is.na(cells)]
  density <- mean(cells)
  ties <- sum(cells != 0)
  avg_degree <- sum(m, na.rm = TRUE) / n
  # UCINET's Std Dev is the population form: uestimator.calc in ustats.pas sets
  # variance := mcssq/n, not mcssq/(n-1). stats::sd() would be slightly high.
  summary <- list("Density" = density,
                  "Avg Degree" = avg_degree,
                  "Std Dev" = uci_stats(cells)[["Std Dev"]],
                  "No. of Ties" = ties)
  new_xucinet_output("Density", net, summary = summary, assumptions = assumptions,
                     subclass = "xdensity", call = match.call())
}
