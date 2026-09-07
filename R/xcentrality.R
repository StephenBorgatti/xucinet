#' Multiple centrality measures at once
#'
#' UCINET: Network | Centrality | Multiple Measures Suite, and `mcent()` on its
#' command line. One table, one column per measure, so that measures can be
#' compared without running and joining a dozen routines.
#'
#' Every column is computed by the individual routine rather than reimplemented
#' here, so the suite and the single-measure functions cannot drift apart. A
#' measure whose routine is not written yet comes back as an `NA` column with a
#' line in `$assumptions` naming what is missing -- the table keeps its shape
#' and its headings, and fills in as the routines land.
#'
#' Column names and their order are UCINET's, from its own output: directed data
#' gives paired Out/In columns and no eigenvector, symmetric data gives single
#' columns and does include one.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param directed `NULL` (detect from symmetry), `TRUE` or `FALSE`.
#' @return An `xucinet_output` whose `$nodes` holds one column per measure.
#' @examples
#' xcentrality(campnet)
#' @export
xcentrality <- function(net, relation = NULL, directed = NULL) {
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("The centrality suite needs a square matrix; this one is ", nrow(m),
         " x ", ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  if (is.null(directed)) directed <- !isSymmetric(unname(m))

  n <- nrow(m)
  na_col <- rep(NA_real_, n)

  deg <- xdegree(m, directed = directed)$nodes
  bet <- xbetweenness(m, directed = directed)$nodes
  clo <- xcloseness(m, directed = directed)$nodes
  bc_in  <- xbeta(m, direction = "in")$nodes[[1]]
  bc_out <- xbeta(m, direction = "out")$nodes[[1]]

  # Not written yet. Named individually rather than as "some measures are
  # missing", so the report says what to go and write.
  missing <- c("two-local", "ARD", "two-step betweenness", "two-step reach",
               "k-coreness", "fragmentation", "distance-weighted fragmentation")

  if (directed) {
    nodes <- data.frame(
      OutDegree = deg$Outdeg,     InDegree = deg$Indeg,
      OutTwoLocal = na_col,       InTwoLocal = na_col,
      OutBetaCent = bc_out,       InBetaCent = bc_in,
      OutCloseness = clo$OutClose, InCloseness = clo$InClose,
      OutARD = na_col,            InARD = na_col,
      Betweenness = bet$Betweenness,
      TwoStepBet = na_col,
      Out2Step = na_col,          In2Step = na_col,
      InKCore = na_col,           OutKCore = na_col,
      Frag = na_col,              DwFrag = na_col,
      row.names = rownames(m), check.names = FALSE)
  } else {
    eig <- xeigenvector(m)$nodes$Eigenvector
    nodes <- data.frame(
      Degree = deg$Degree,
      Eigenvector = eig,
      TwoLocal = na_col,
      BetaCent = bc_in,
      Closeness = clo$FreeClo,
      ARD = na_col,
      Betweenness = bet$Betweenness,
      TwoStepBet = na_col,
      `2StepReach` = na_col,
      kCoreness = na_col,
      Frag = na_col,
      DwFrag = na_col,
      row.names = rownames(m), check.names = FALSE)
  }

  assumptions <- c(
    assumptions,
    sprintf("Data treated as %s.", if (directed) "directed" else "undirected"),
    paste0("Not written yet, returned as NA: ",
           paste(missing, collapse = ", "), "."),
    paste("Each column is computed by its own routine, so the suite and the",
          "single-measure functions cannot disagree."),
    paste("Closeness and BetaCent differ from UCINET's own mcent(): its",
          "Closeness column holds total distance, which is farness rather than",
          "closeness, and its BetaCent uses a different normalization from the",
          "Beta Centrality dialog. See the differences vignette."))

  out <- new_xucinet_output(
    "Multiple centrality measures", net,
    nodes = nodes, assumptions = assumptions,
    nodes_title = "Centrality Measures",
    stats_block = TRUE,           # xcentrality.pas prints one
    subclass = "xcentrality", call = match.call())
  out$primary <- if (directed) "OutDegree" else "Degree"
  out
}
