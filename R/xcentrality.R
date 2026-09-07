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
#' @param mode For 2-mode data, which margin to report: `"rows"` (default) or
#'   `"cols"`. Ignored for square matrices.
#' @return An `xucinet_output` whose `$nodes` holds one column per measure.
#' @section 2-mode data:
#' A rectangular matrix is answered by UCINET's *Network | 2-Mode networks |
#' 2-Mode Centrality*, which is a different set of five measures -- `Degree`,
#' `2-Local`, `Closeness`, `Betweenness`, `Eigenvector` -- computed on the
#' bipartite graph and reported for each margin in turn. `mode` picks the
#' margin. Every normalization uses the size of the opposite mode, which is
#' chapter 9 decision 6.
#'
#' Closeness and betweenness are computed on binarized data and the rest on the
#' values, which is UCINET's own division and is printed in its report.
#' @examples
#' xcentrality(campnet)
#' xcentrality(davis)                    # 2-mode: the women
#' xcentrality(davis, mode = "cols")     # the events
#' @export
xcentrality <- function(net, relation = NULL, directed = NULL,
                        mode = c("rows", "cols")) {
  mode <- match.arg(mode)
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    return(twomode_centrality(net, m, mode, match.call()))
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


# UCINET's 2-Mode Centrality. Five measures on the bipartite graph, reported one
# margin at a time.
#
# Every one of them is checked against g9m_2mode_davis and davis-colcent, and
# every one needed its convention established rather than assumed:
#
#   Degree      raw degree over the size of the OPPOSITE mode.
#   2-Local     the normalized sum of the normalized degrees of a node's alters,
#               itself divided by the opposite mode size. UCINET says as much in
#               a footnote to its own report.
#   Closeness   the theoretical minimum distance sum over the actual one. For a
#               node whose own set has n_o members and the other n_i, the
#               minimum is n_i + 2(n_o - 1): one step to every node opposite,
#               two to every other node of its own kind. Borgatti and Everett
#               (1997) p. 256.
#   Betweenness raw betweenness over the bipartite maximum, which is where the
#               published formula and UCINET disagree - see
#               bipartite_max_betweenness().
#   Eigenvector the principal eigenvector of the bipartite VALUED matrix, with
#               each mode scaled to unit length separately rather than the
#               vector as a whole. UCINET returns it negative; we flip it
#               positive, as its own 1-mode routines do (UCINET issue 2).
twomode_centrality <- function(net, m, mode, call) {
  nr <- nrow(m); nc <- ncol(m)
  own   <- if (mode == "rows") nr else nc
  other <- if (mode == "rows") nc else nr
  idx   <- if (mode == "rows") seq_len(nr) else nr + seq_len(nc)

  bin <- bipartite((m > 0) * 1)
  val <- bipartite(replace(m, is.na(m), 0))
  n <- nrow(bin)

  deg <- (if (mode == "rows") rowSums(m, na.rm = TRUE)
          else colSums(m, na.rm = TRUE)) / other

  ndeg <- c(rowSums(m, na.rm = TRUE) / nc, colSums(m, na.rm = TRUE) / nr)
  two_local <- as.vector(bin %*% ndeg)[idx] / other

  d <- geodesics(bin)
  closeness <- (other + 2 * (own - 1)) / rowSums(d)[idx]

  betweenness <- brandes(bin)[idx] / bipartite_max_betweenness(own, other)

  e <- principal_eigen(val)$vector
  half <- e[idx]
  ssq <- sum(half^2)
  eigenvector <- if (ssq > 0) half / sqrt(ssq) else half
  if (sum(eigenvector) < 0) eigenvector <- -eigenvector

  labels <- if (mode == "rows") rownames(m) else colnames(m)
  nodes <- data.frame(Degree = deg, `2-Local` = two_local,
                      Closeness = closeness, Betweenness = betweenness,
                      Eigenvector = eigenvector,
                      row.names = labels, check.names = FALSE)

  out <- new_xucinet_output(
    "2-mode centrality", net,
    nodes = nodes,
    assumptions = c(
      sprintf("Data treated as 2-mode: %d rows by %d columns.", nr, nc),
      sprintf("Reporting the %s. Normalization uses the opposite mode, size %d.",
              if (mode == "rows") "row nodes" else "column nodes", other),
      paste("Closeness and betweenness are calculated on binarized data.",
            "The other measures use valued data."),
      paste("The 2-local measure is the normalized sum of normalized degree",
            "of a node's alters."),
      paste("Eigenvector scores are reported positive. UCINET returns them",
            "negative for 2-mode data, which its 1-mode routines do not.")),
    nodes_title = sprintf("2-Mode Centrality Measures for %s of %s",
                          toupper(mode), net$title),
    stats_block = FALSE,
    subclass = c("x2modecentrality", "xcentrality"), call = call)
  out$primary <- "Degree"
  out
}
