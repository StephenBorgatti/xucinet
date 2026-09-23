# Whole-network homophily.
#
# UCINET: Network | Whole Networks | Homophily/Influence | Categorical
# (uc_NetworkHomophily.pas, repository StephenBorgatti/ucinet at commit
# c7b4956), with the measures in G2Tools/uhomophilywhole.pas, function
# calcwhomophily, and the modularity in G2Tools/umodularity3.pas (repository
# StephenBorgatti/tools at commit 207958a).
#
# Design question 10.6(b) described UCINET's E-I Index routine instead -
# whole-network E-I with a permutation p-value and group and node tables - and
# recommended `nperm` and `seed`. Steve's answer named this routine, which
# reports seven measures and runs no permutation test, so there is no `nperm`
# here. The E-I index is one of the seven.
#
# Dialog defaults, from uc_NetworkHomophily.dfm: TypeOfData.ItemIndex = 1, so
# the data are treated as **valued** unless told otherwise, and "Ignore tie
# direction" is unchecked.

#' Whole-network homophily
#'
#' UCINET: Network | Whole Networks | Homophily/Influence | Categorical. Seven
#' ways of asking whether ties fall within groups more than between them.
#'
#' * `H` is the share of tie strength that stays inside a group, and
#'   `h-star` subtracts what the group sizes would give by chance.
#' * `E-I Index` runs the other way: external minus internal over the total,
#'   so it is +1 when every tie crosses a boundary and -1 when none does.
#' * `Corr` correlates the tie value with whether the pair share a group;
#'   `Yules Q` does the same on the two-by-two table of tie against sameness.
#' * `Modul Q` is Newman modularity and `Assort` his categorical
#'   assortativity, both computed on the mixing matrix.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data` (G3).
#' @param directed `NULL` (detect), `TRUE`, or `FALSE` to ignore the direction
#'   of ties, which is the dialog's checkbox.
#' @param weighted Treat the data as valued? `TRUE`, as the dialog does
#'   (`TypeOfData.ItemIndex = 1`). `FALSE` dichotomizes at > 0 before every
#'   measure. UCINET's `calcwhomophily` applies the choice to the mixing
#'   matrix only, leaving `H`, `h-star`, `Corr`, `Yules Q` and `E-I Index`
#'   on the raw values either way; that is UCINET issue 21, fix pending, and
#'   xucinet does what the dialog says.
#' @param diagonal Allow reflexive ties? `FALSE` by default.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xhomophily", "xucinet_output")`, with the
#'   seven measures in `$summary` under UCINET's headings and the
#'   within/between mixing matrix in `$matrices`.
#' @seealso [xdensitybygroups()] for the densities the mixing matrix implies,
#'   and [xattributetomatrix()].
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' xhomophily(campnet, gender)
#' @export
xhomophily <- function(net, attribute, directed = NULL, weighted = TRUE,
                       diagonal = FALSE, data = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xhomophily()")

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  groups <- res$values
  m <- pick_relation(net, NULL)
  if (length(groups) != nrow(m)) {
    stop("the partition has ", length(groups), " values but the network has ",
         nrow(m), " nodes.", call. = FALSE)
  }

  assumptions <- character(0)
  if (isFALSE(directed)) {
    # m.symmetrize(sy_union): a tie either way is a tie.
    m <- pmax(m, t(m))
    assumptions <- c(assumptions, "Direction of ties ignored.")
  }
  if (!diagonal) assumptions <- c(assumptions, "Reflexive ties not counted.")
  if (!weighted) {
    # UCINET issue 21: binary treatment applies to every measure, not only to
    # the mixing matrix as in calcwhomophily.
    m <- ifelse(is.na(m), NA_real_, (m > 0) * 1)
    assumptions <- c(assumptions, "Data treated as binary.")
  }

  undirected <- isFALSE(directed) || isTRUE(isSymmetric(unname(m)))
  hom <- homophily_measures(m, groups, weighted, diagonal, undirected)

  new_xucinet_output(
    "Whole-Network Alter-Ego Similarity Measures", net,
    summary = hom$summary, matrices = list(Mixing = hom$mixing),
    assumptions = assumptions, subclass = "xhomophily",
    summary_title = "Whole Network Ego-Alter Similarity Measures")
}

# calcwhomophily. Everything is accumulated over the ordered pairs that have a
# valid cell and two valid groups.
homophily_measures <- function(m, groups, weighted, diagonal, undirected) {
  keys <- sort(unique(groups[!is.na(groups)]))
  g <- match(groups, keys)
  np <- length(keys)
  n <- nrow(m)

  use <- outer(!is.na(g), !is.na(g), "&") & !is.na(m)
  if (!diagonal) use[row(m) == col(m)] <- FALSE

  same <- outer(g, g, "==")
  same[is.na(same)] <- FALSE
  wt <- m
  wt[is.na(wt)] <- 0
  tie <- wt > 0

  internal <- sum(wt[use & same])
  external <- sum(wt[use & !same])
  total <- internal + external

  # The mixing matrix: summed strengths when valued, counted ties when not.
  mixing <- matrix(0, np, np, dimnames = list(as.character(keys),
                                              as.character(keys)))
  for (r in seq_len(np)) {
    for (s in seq_len(np)) {
      cells <- use & outer(g == r, g == s, "&")
      cells[is.na(cells)] <- FALSE
      mixing[r, s] <- if (weighted) sum(wt[cells]) else sum(tie[cells])
    }
  }

  # e_expected: what the group sizes alone would give.
  sizes <- as.vector(table(g))
  nvalid <- sum(!is.na(g))
  e_expected <- if (diagonal) {
    if (nvalid > 0) sum(sizes^2) / nvalid^2 else NA_real_
  } else {
    if (nvalid > 1) sum(sizes * (sizes - 1)) / (nvalid * (nvalid - 1)) else NA_real_
  }

  h <- if (total > 0) internal / total else NA_real_
  ei <- if (total > 0) (external - internal) / total else NA_real_

  x <- wt[use]
  y <- as.numeric(same[use])
  corr <- if (stats::sd(x) > 0 && stats::sd(y) > 0) stats::cor(x, y) else NA_real_

  # Yule's Q on tie against sameness.
  a <- sum(tie[use] & same[use]); b <- sum(tie[use] & !same[use])
  cc <- sum(!tie[use] & same[use]); d <- sum(!tie[use] & !same[use])
  yq <- if ((a * d + b * cc) != 0) (a * d - b * cc) / (a * d + b * cc) else NA_real_

  list(summary = list(
         "H" = h,
         "h-star" = if (!is.na(h) && !is.na(e_expected)) h - e_expected else NA_real_,
         "Corr" = corr,
         "Modul Q" = modularity_q(wt, g, undirected),
         "Assort" = assortativity(mixing),
         "Yules Q" = yq,
         "E-I Index" = ei),
       mixing = mixing)
}

# Newman's categorical assortativity on the mixing matrix:
# (sum e_rr - sum a_r b_r) / (1 - sum a_r b_r).
assortativity <- function(mixing) {
  tot <- sum(mixing)
  if (tot <= 0) return(NA_real_)
  e <- mixing / tot
  ar <- rowSums(e)
  br <- colSums(e)
  sumab <- sum(ar * br)
  if (1 - sumab > 0) (sum(diag(e)) - sumab) / (1 - sumab) else NA_real_
}

# umodularity3: the diagonal is included in both forms, and `tot` is the sum
# of every cell.
modularity_q <- function(w, g, undirected) {
  keep <- !is.na(g)
  w <- w[keep, keep, drop = FALSE]
  g <- g[keep]
  tot <- sum(w)
  if (tot <= 0) return(NA_real_)
  outdeg <- rowSums(w)
  indeg <- colSums(w)

  if (undirected) {
    # within_k/tot - (sum of degrees in k / tot)^2
    sum(vapply(unique(g), function(k) {
      idx <- which(g == k)
      sum(w[idx, idx]) / tot - (sum(outdeg[idx]) / tot)^2
    }, numeric(1)))
  } else {
    sum(vapply(unique(g), function(k) {
      idx <- which(g == k)
      sum(w[idx, idx]) - sum(outer(outdeg[idx], indeg[idx], "*")) / tot
    }, numeric(1))) / tot
  }
}
