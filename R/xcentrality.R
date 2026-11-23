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
#' @param relation Which relation of a multi-relation dataset, by name (in any case) or
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
                             relation_label(net, relation),
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
#
# twomode_scores() computes them for one margin, with the raw degree and raw
# betweenness beside the normalized ones; xcentrality() reports the five, and
# xdegree(), xcloseness(), xbetweenness() and xeigenvector() report their own
# measure for 2-mode data (chapter 13: "the centrality functions of Chapter 9
# recognize two-mode data and give the appropriately normalized scores").
twomode_scores <- function(m, mode) {
  nr <- nrow(m); nc <- ncol(m)
  own   <- if (mode == "rows") nr else nc
  other <- if (mode == "rows") nc else nr
  idx   <- if (mode == "rows") seq_len(nr) else nr + seq_len(nc)

  bin <- bipartite((m > 0) * 1)
  val <- bipartite(replace(m, is.na(m), 0))

  rawdeg <- if (mode == "rows") rowSums(m, na.rm = TRUE) else colSums(m, na.rm = TRUE)
  deg <- rawdeg / other

  ndeg <- c(rowSums(m, na.rm = TRUE) / nc, colSums(m, na.rm = TRUE) / nr)
  two_local <- as.vector(bin %*% ndeg)[idx] / other

  d <- geodesics(bin)
  closeness <- (other + 2 * (own - 1)) / rowSums(d)[idx]

  rawbet <- brandes(bin)[idx]
  betweenness <- rawbet / bipartite_max_betweenness(own, other)

  e <- principal_eigen(val)$vector
  half <- e[idx]
  ssq <- sum(half^2)
  eigenvector <- if (ssq > 0) half / sqrt(ssq) else half
  if (sum(eigenvector) < 0) eigenvector <- -eigenvector

  labels <- if (mode == "rows") rownames(m) else colnames(m)
  data.frame(Degree = deg, `2-Local` = two_local,
             Closeness = closeness, Betweenness = betweenness,
             Eigenvector = eigenvector, RawDegree = unname(rawdeg),
             RawBetweenness = rawbet,
             row.names = labels, check.names = FALSE)
}

twomode_centrality <- function(net, m, mode, call) {
  nr <- nrow(m); nc <- ncol(m)
  other <- if (mode == "rows") nc else nr
  nodes <- twomode_scores(m, mode)[, c("Degree", "2-Local", "Closeness",
                                       "Betweenness", "Eigenvector")]

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

# One measure of 2-Mode Centrality, for the single-measure routines. `cols`
# maps the report's column names to twomode_scores() columns; mode "both"
# stacks the rows then the columns and adds a Mode column.
twomode_single <- function(net, m, mode, cols, routine, subclass, call) {
  margins <- if (mode == "both") c("rows", "cols") else mode
  parts <- lapply(margins, function(md) {
    s <- twomode_scores(m, md)[, unname(cols), drop = FALSE]
    names(s) <- names(cols)
    if (mode == "both") s$Mode <- if (md == "rows") "row" else "col"
    s
  })
  nodes <- do.call(rbind, parts)
  # Centralization of each mode (xucinet#56), always both whatever `mode` is,
  # so that the summary does not depend on an argument.
  cz <- twomode_centralization(m, routine)
  fields <- twomode_centralization_fields[[routine]]
  pct <- routine != "Degree"
  summary <- stats::setNames(as.list(unname(cz) * if (pct) 100 else 1), fields)
  cz_note <- paste0(
    "Centralization is computed for each mode separately (UCINET reports none for 2-mode data): ",
    "the sum of differences from the most central node of the mode, divided by its largest ",
    "possible value for a bipartite graph with the same mode sizes",
    if (routine == "Degree") "; degree centralization uses the binarized data" else "",
    if (routine == "Closeness" && anyNA(cz)) "; it is missing because the graph is not connected" else "",
    ".")
  out <- new_xucinet_output(
    routine, net, nodes = nodes, summary = summary,
    assumptions = c(
      sprintf("Data treated as 2-mode: %d rows by %d columns.", nrow(m), ncol(m)),
      "Computed on the bipartite graph; normalized by the size of the opposite mode (Borgatti and Everett 1997), as UCINET's 2-Mode Centrality.",
      cz_note),
    summary_title = if (pct) sprintf("2-Mode %s Centralization (%%)", routine) else
      "2-Mode Degree Centralization -- as proportion, not percentage",
    nodes_title = sprintf("2-Mode %s for %s of %s", routine,
                          switch(mode, both = "ROWS and COLS", toupper(mode)),
                          net$title),
    stats_block = FALSE, subclass = subclass, call = call)
  out$primary <- names(cols)[if (length(cols) > 1) 2 else 1]
  out
}

# 2-mode centralization (xucinet#56; UCINET has none, DIFFERENCES 52). For each
# mode, Freeman's form: the sum over the mode's nodes of (largest score - score),
# divided by the largest that sum can be in a bipartite graph with the same two
# mode sizes, on the normalized scores twomode_scores() reports.
#
#   Degree, Eigenvector  n_own - 1. Every normalized score is at most 1 (the
#       eigenvector half is scaled to unit length), so the sum is at most
#       n_own - 1, and one node tied to the whole other mode with the rest of
#       its mode isolated reaches it. Degree uses the binarized data, as
#       closeness and betweenness do, so that the bound holds for valued data.
#   Betweenness  n_own - 1. Scores are divided by the largest a node can have
#       (bipartite_max_betweenness), so the same bound applies; the bipartite
#       star below reaches it (one node has the maximum, the others are leaves).
#   Closeness  the value of the sum in the bipartite star: one node tied to the
#       whole other mode, and each other node of its mode tied to one node of
#       the other mode, spread as evenly as possible. No closed form is
#       claimed; an exhaustive search of every bipartite graph up to 4 x 4,
#       5 x 3 and 3 x 5 found no larger value (and for betweenness none above
#       n_own - 1). Missing when the graph is not connected, as in 1-mode.
twomode_centralization_fields <- list(
  Degree      = c("Row Centralization", "Column Centralization"),
  Betweenness = c("Row Centralization Index (%)", "Column Centralization Index (%)"),
  Closeness   = c("Row Centralization (%)", "Column Centralization (%)"),
  Eigenvector = c("Row eigenvector centralization (%)",
                  "Column eigenvector centralization (%)"))

bipartite_star <- function(n_own, n_other) {
  s <- matrix(0, n_own, n_other)
  s[1, ] <- 1
  for (i in seq_len(n_own - 1)) s[i + 1, ((i - 1) %% n_other) + 1] <- 1
  s
}

twomode_centralization <- function(m, measure) {
  input <- if (measure == "Degree") (replace(m, is.na(m), 0) > 0) * 1 else m
  sapply(c(rows = "rows", cols = "cols"), function(md) {
    own <- if (md == "rows") nrow(m) else ncol(m)
    other <- if (md == "rows") ncol(m) else nrow(m)
    if (own < 2 || other < 1) return(NA_real_)
    x <- twomode_scores(input, md)[[measure]]
    if (anyNA(x) || !all(is.finite(x))) return(NA_real_)
    num <- sum(max(x) - x)
    den <- if (measure == "Closeness") {
      y <- twomode_scores(bipartite_star(own, other), "rows")$Closeness
      sum(max(y) - y)
    } else own - 1
    num / den
  })
}

# The 2-mode test the single-measure routines share: rectangular, or declared
# 2-mode.
is_twomode <- function(net, m) {
  nrow(m) != ncol(m) || identical(net$mode, "2-mode")
}
