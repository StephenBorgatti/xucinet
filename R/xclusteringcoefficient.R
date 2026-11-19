# Whole-network clustering coefficients.
#
# UCINET: Network | Whole-Network Measures | Clustering Coefficient
# (runclusteringcoefficient in xclusteringcoefficient.pas) and the command-line
# function cc() (runclusteringcoefficient in Xdpmat.pas, engine
# OpsahlPanzarosaCC in G2Tools/uclusteringcoefficient.pas), repositories
# StephenBorgatti/ucinet and StephenBorgatti/tools.
#
# What is reported follows Steve's decisions of 2 October 2026 on
# dev/UCINET-ISSUES.md issue 41, which UCINET 6.850 is to follow too: three
# coefficients side by side, each as an overall value (the mean of the node
# values) and a weighted overall value (each node weighted by the number of
# two-paths or neighbor pairs centred on it):
#
#   - the underlying graph, direction ignored (the coefficient of Watts and
#     Strogatz 1998, and what igraph reports);
#   - Fagiolo (2007), the "total" directed coefficient;
#   - Opsahl and Panzarasa (2009), whose weighted overall value on binary data
#     is triplet transitivity.
#
# On symmetric binary data the three are the same number. The node values are
# computed and averaged here but not returned: this is a whole-network routine
# (SPEC addendum, 23 September 2026), and the node-level coefficient is the
# density of ego's neighborhood, available from the ego-network routines.
#
# Created 18 Nov 2026 (Steve): the overall coefficient used to sit in
# xtransitivity()'s summary (design question 10.2); xtransitivity() now
# follows UCINET's command-line transitivity(), which has no clustering
# coefficient, so the coefficient has its own function.

cc_measures <- c(
  "Overall CC", "Weighted Overall CC",
  "Fagiolo Overall CC", "Fagiolo Weighted CC",
  "O-P Overall CC", "O-P Weighted CC",
  "Density")

#' Clustering coefficients
#'
#' UCINET: Network | Whole-Network Measures | Clustering Coefficient. The
#' clustering coefficient of a node is the density of ties among its
#' neighbors. The overall clustering coefficient of the network is the
#' average of the node values (Watts and Strogatz 1998), taken over the nodes
#' that have at least two neighbors. The weighted overall clustering
#' coefficient is the same average with each node weighted by its number of
#' pairs of neighbors; for undirected binary data it equals transitivity, as
#' reported by [xtransitivity()].
#'
#' For directed data there is more than one way to define the node value, and
#' three are reported side by side, each as an overall and a weighted overall
#' value:
#'
#' - `Overall CC`, `Weighted Overall CC`: the underlying graph. The direction
#'   of ties is ignored, so i and j are neighbors if either chooses the other.
#'   This is the definition igraph uses.
#' - `Fagiolo Overall CC`, `Fagiolo Weighted CC`: Fagiolo's (2007) coefficient
#'   for directed networks, which counts every directed triangle that a node
#'   is part of, against the number it could be part of given its in-, out-
#'   and reciprocated ties.
#' - `O-P Overall CC`, `O-P Weighted CC`: Opsahl and Panzarasa's (2009)
#'   coefficient. For node i it is the proportion of two-paths j -> i -> k
#'   that are closed by a tie j -> k. The weighted overall value is the
#'   transitivity of the network, the same number as `Transitivity` in
#'   [xtransitivity()].
#'
#' On undirected binary data the three definitions give the same values, and
#' the report prints only the first pair (all three are in `$summary`).
#' `Density` is the density of the relation, dichotomized at `> 0`.
#'
#' Missing cells count as no tie, values at or below 0 count as no tie, and the
#' diagonal takes no part. Nodes with fewer than two neighbors (for the
#' underlying graph), or with no two-path through them (for the other two), have
#' no node value and are left out of the overall averages.
#'
#' **Valued data.** By default (`weighted = NULL`) each coefficient uses its own
#' canonical treatment of tie values: the Opsahl-Panzarasa coefficient weights
#' each two-path by a summary of its two tie values (chosen with `omega`); the
#' Fagiolo coefficient uses his weighted form, in which each tie value is
#' divided by the largest value and replaced by its cube root; the underlying
#' graph coefficient is computed on the dichotomized data. `weighted = FALSE`
#' dichotomizes the data at `> 0` for all three. `weighted = TRUE` uses the tie
#' values in all three, and the underlying-graph coefficient becomes the
#' average tie value among a node's neighbors, with each pair taking the
#' larger of its two values; it can then exceed 1.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param weighted `NULL` (each coefficient's canonical treatment of tie
#'   values), `TRUE` (use tie values in all three) or `FALSE` (dichotomize at
#'   `> 0` first). Has no effect on binary data.
#' @param omega For valued data, how the Opsahl-Panzarasa coefficient values a
#'   two-path from its two tie values: `"am"` (arithmetic mean, the default),
#'   `"gm"` (geometric mean), `"min"` or `"max"`.
#' @return An object of class `c("xclusteringcoefficient", "xucinet_output")`.
#'   `$summary` is a data frame with one row per relation and the seven
#'   columns named above.
#' @references
#' Fagiolo, G. (2007). Clustering in complex directed networks. *Physical
#' Review E* 76, 026107.
#'
#' Opsahl, T. and Panzarasa, P. (2009). Clustering in weighted networks.
#' *Social Networks* 31(2), 155-163.
#'
#' Watts, D. J. and Strogatz, S. H. (1998). Collective dynamics of
#' 'small-world' networks. *Nature* 393, 440-442.
#' @seealso [xtransitivity()] for transitivity, and [xegonet()] for the
#'   density of each node's ego network, which for binary data is the
#'   node-level clustering coefficient.
#' @examples
#' xclusteringcoefficient(padgett)
#'
#' # directed data: the three definitions differ
#' xclusteringcoefficient(campnet)
#' @export
xclusteringcoefficient <- function(net, weighted = NULL,
                                   omega = c("am", "gm", "min", "max")) {
  net <- xnet(net, substitute(net))
  omega <- match.arg(omega)
  require_1mode(net, "xclusteringcoefficient()")
  if (!is.null(weighted) && !(isTRUE(weighted) || isFALSE(weighted))) {
    stop("weighted must be NULL, TRUE or FALSE.", call. = FALSE)
  }

  mats <- relation_matrices(net)
  rels <- if (length(mats) == 1L) net$title else xrelations(net)
  valued <- vapply(mats, is_valued, logical(1))

  rows <- lapply(mats, function(m) {
    w <- cc_weights(m)
    a <- (w > 0) * 1
    use_values <- is_valued(m) && !isFALSE(weighted)
    und <- cc_underlying(if (use_values && isTRUE(weighted)) w else a)
    fag <- cc_fagiolo(a, if (use_values) w else NULL)
    op <- cc_opsahl(if (use_values) w else a, omega)
    n <- nrow(a)
    c(und, fag, op, if (n > 1) sum(a) / (n * (n - 1)) else NA_real_)
  })
  out <- as.data.frame(do.call(rbind, rows), optional = TRUE)
  names(out) <- cc_measures
  rownames(out) <- rels

  assumptions <- character(0)
  if (any(valued)) {
    which_rel <- if (length(mats) == 1L) "Data" else
      paste0("Relation ", paste(rels[valued], collapse = ", "))
    assumptions <- c(assumptions, if (isFALSE(weighted)) {
      paste0(which_rel, " dichotomized at > 0.")
    } else if (isTRUE(weighted)) {
      paste0(which_rel, " valued: all three coefficients use tie values ",
             "(omega = ", omega, "); values can exceed 1.")
    } else {
      paste0(which_rel, " valued: Fagiolo and O-P use tie values (omega = ",
             omega, "); the underlying graph is dichotomized at > 0.")
    })
  }

  # The three definitions agree on symmetric binary data, and then only the
  # first pair is printed. A choice of what to print, made from the data; the
  # object holds all seven columns either way.
  m6 <- unname(as.matrix(out[, 1:6, drop = FALSE]))
  same <- all(abs(m6[, c(1, 2)] - m6[, c(3, 4)]) < 1e-12, na.rm = TRUE) &&
    all(abs(m6[, c(1, 2)] - m6[, c(5, 6)]) < 1e-12, na.rm = TRUE) &&
    identical(is.na(m6[, 1:2]), is.na(m6[, 3:4])) &&
    identical(is.na(m6[, 1:2]), is.na(m6[, 5:6]))
  shown <- if (same) cc_measures[c(1, 2, 7)] else cc_measures

  epilogue <- c(
    paste0("Overall CC is the mean of the node-level clustering coefficients, ",
           "over nodes with at least two neighbors."),
    paste0("Weighted Overall CC weights each node by its number of pairs of ",
           "neighbors; on binary data it equals the transitivity of the ",
           "network with the direction of ties ignored."))
  if (same) {
    epilogue <- c(epilogue, paste0(
      "The Fagiolo and O-P coefficients equal these on symmetric binary data ",
      "and are in $summary."))
  } else {
    epilogue <- c(epilogue, paste0(
      "On binary data, O-P Weighted CC equals the Transitivity reported by ",
      "xtransitivity()."))
  }

  new_xucinet_output("Clustering Coefficient", net, summary = out,
                     assumptions = assumptions,
                     subclass = "xclusteringcoefficient", call = match.call(),
                     summary_title = "Overall Clustering Coefficients",
                     show_summary = shown, epilogue = epilogue)
}

# Tie values with no tie as 0: missing cells, values at or below 0 and the
# diagonal, as OpsahlPanzarosaCC reads them.
cc_weights <- function(m) {
  w <- m
  w[is.na(w) | w < 0] <- 0
  diag(w) <- 0
  storage.mode(w) <- "double"
  w
}

# Overall and weighted overall from node numerators and denominators. A node
# with a zero denominator has no value and is left out of both.
cc_overall <- function(num, den) {
  ok <- den > 0
  if (!any(ok)) return(c(NA_real_, NA_real_))
  c(mean(num[ok] / den[ok]), sum(num[ok]) / sum(den[ok]))
}

# The underlying graph: i and j are neighbors if either has a tie to the
# other. For binary input the node value is the density of ties among the
# neighbors (clusteringcoef in uclusteringcoefficient.pas). For valued input
# it is the average value among them, each pair taking the larger of its two
# values (the menu routine's valued form, symmetrized as issue 41 decides).
cc_underlying <- function(w) {
  s <- pmax(w, t(w))
  nb <- s > 0
  n <- nrow(s)
  num <- den <- numeric(n)
  for (i in seq_len(n)) {
    k <- which(nb[i, ])
    if (length(k) < 2) next
    den[i] <- length(k) * (length(k) - 1) / 2
    sub <- s[k, k, drop = FALSE]
    num[i] <- sum(sub[upper.tri(sub)])
  }
  cc_overall(num, den)
}

# Fagiolo (2007), equation 7 and its weighted version (equation 9): the
# number of directed triangles at i, [(A + A')^3]_ii / 2, against
# d_tot (d_tot - 1) - 2 d_bi, where d_tot is in-degree plus out-degree and
# d_bi the number of reciprocated ties. The weighted form replaces A in the
# numerator by the cube roots of the values divided by the largest value; the
# denominator stays binary.
cc_fagiolo <- function(a, w = NULL) {
  x <- if (is.null(w)) a else (w / max(w))^(1 / 3)
  s <- x + t(x)
  num <- diag(s %*% s %*% s) / 2
  dtot <- rowSums(a) + colSums(a)
  dbi <- diag(a %*% a)
  den <- dtot * (dtot - 1) - 2 * dbi
  cc_overall(num, den)
}

# Opsahl and Panzarasa (2009): the triplets centred on i are the two-paths
# j -> i -> k with j and k different, each valued by omega of its two ties;
# it is closed if j -> k is a tie. OpsahlPanzarosaCC also scales the values by
# the largest one first, which cancels in every ratio, so it is not done here.
cc_opsahl <- function(w, omega = "am") {
  f <- switch(omega,
              am = function(x, y) (x + y) / 2,
              gm = function(x, y) sqrt(x * y),
              min = pmin,
              max = pmax)
  closed <- w > 0
  n <- nrow(w)
  num <- den <- numeric(n)
  for (i in seq_len(n)) {
    j <- which(w[, i] > 0)
    k <- which(w[i, ] > 0)
    if (!length(j) || !length(k)) next
    val <- outer(w[j, i], w[i, k], f)
    keep <- outer(j, k, "!=")
    den[i] <- sum(val[keep])
    num[i] <- sum((val * closed[j, k, drop = FALSE])[keep])
  }
  cc_overall(num, den)
}
