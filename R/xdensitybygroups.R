# Density and mixing by groups.
#
# UCINET: Network | Mixing Tables w/ Expected Values (uc_MixingTables.pas,
# repository StephenBorgatti/ucinet at commit c7b4956), which design question
# 10.6(a) names as the model for this routine. The engines are
# G2Tools/unetmixingmodels.pas and, for the density table,
# G2Tools/uAggregate.pas - `getdensitymatrix` is nothing but
# `aggbygroups(y, x, p, p, ng, ng)` with its default mean, which is the same
# call xcombinenodes() makes.
#
# The routine writes four tables: the observed mixing matrix, an expected one
# under a chosen model, the density table, and the ratio of observed to
# expected. Three expected-value models are offered (ExpectedModel.ItemIndex
# = 0, so Density is the default); only that one is ported so far, because it
# is the default and the one the chapter uses. The other two stop with a
# message rather than guess.
#
# `test =` belongs to chapter 14: the permutation engine arrives with it.

#' Density and mixing by groups
#'
#' UCINET: Network | Mixing Tables w/ Expected Values. How densely each group
#' ties to each other group, and how that compares with chance.
#'
#' Four tables come back. `Density` is the mean tie strength in each block, the
#' same figure [xcombinenodes()] gives. `Observed` sums the ties in each block.
#' `Expected` is what a model predicts for those group sizes, and `Ratio` is
#' observed over expected, so 1 is exactly as expected and 2 is twice as much.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data` (G3).
#' @param directed `NULL` (detect), `TRUE` or `FALSE`. Undirected data count
#'   each edge once.
#' @param model The expected-value model. `"density"` (the dialog's default)
#'   spreads the observed density over the group sizes. `"configuration"` and
#'   `"fixedout"` are UCINET's other two and are not ported yet.
#' @param test Run the permutation test? Not yet: it arrives with chapter 14,
#'   which brings the permutation engine.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xdensitybygroups", "xucinet_output")` whose
#'   `$matrices` holds `Density`, `Observed`, `Expected` and `Ratio`.
#' @seealso [xcombinenodes()] for the density table on its own, and
#'   [xhomophily()] for the summary measures built on the same mixing.
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' xdensitybygroups(campnet, gender)
#' @export
xdensitybygroups <- function(net, attribute, directed = NULL,
                             model = c("density", "configuration", "fixedout"),
                             test = FALSE, data = NULL) {
  net <- xnet(net, substitute(net))
  model <- match.arg(model)
  require_1mode(net, "xdensitybygroups()")

  if (!isFALSE(test)) {
    stop("test = TRUE arrives with chapter 14.\n",
         "  The density models are a permutation test, and the permutation ",
         "engine is written with the chapter 14 routines.\n",
         "  Until then the tables come back without a p-value.",
         call. = FALSE)
  }
  if (!identical(model, "density")) {
    stop("model = \"", model, "\" is not ported yet.\n",
         "  UCINET offers Density, Configuration and Fixed outdegree; only ",
         "Density, its default, is implemented.\n",
         "  The other two are on the issue list.", call. = FALSE)
  }

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  groups <- res$values
  m <- pick_relation(net, NULL)
  if (length(groups) != nrow(m)) {
    stop("the partition has ", length(groups), " values but the network has ",
         nrow(m), " nodes.", call. = FALSE)
  }

  assumptions <- character(0)
  if (is.null(directed)) directed <- !isTRUE(isSymmetric(unname(m)))
  if (!directed) {
    # UCINET reaches its undirected branch only when the matrix is already
    # symmetric (`directed := not x.IsSymmetric`), and that branch walks the
    # upper triangle. Reading half of an asymmetric matrix would silently
    # discard the other half, so asking for undirected symmetrizes first.
    if (!isTRUE(isSymmetric(unname(m)))) {
      m <- pmax(m, t(m))
      assumptions <- c(assumptions, "Symmetrized with the maximum.")
    }
    assumptions <- c(assumptions, "Ties counted once each.")
  }

  keys <- sort(unique(groups[!is.na(groups)]))
  g <- match(groups, keys)
  labs <- as.character(keys)

  obs <- mixing_observed(m, g, length(keys), directed)
  exp <- mixing_expected(m, g, length(keys), directed)
  dens <- aggregate_blocks(m, groups, "mean", diagonal = FALSE)
  ratio <- ifelse(exp > 0, obs / exp, NA_real_)
  for (mat in list(obs, exp, ratio)) dimnames(mat) <- list(labs, labs)
  dimnames(obs) <- dimnames(exp) <- dimnames(ratio) <- list(labs, labs)

  new_xucinet_output(
    "Mixing Tables", net,
    matrices = list(Density = dens, Observed = obs, Expected = exp,
                    Ratio = ratio),
    assumptions = assumptions, subclass = "xdensitybygroups")
}

# CalculateObservedMixingMatrix. Directed sums every ordered pair into the
# sender's row; undirected walks the upper triangle so each edge is counted
# once, and mirrors the off-diagonal blocks.
mixing_observed <- function(m, g, np, directed) {
  out <- matrix(0, np, np)
  n <- nrow(m)
  for (i in seq_len(n)) {
    r <- g[i]
    if (is.na(r)) next
    js <- if (directed) seq_len(n) else i:n
    for (j in js) {
      s <- g[j]
      if (is.na(s) || is.na(m[i, j])) next
      val <- m[i, j]
      if (directed) {
        out[r, s] <- out[r, s] + val
      } else if (i == j) {
        out[r, r] <- out[r, r] + val
      } else {
        out[r, s] <- out[r, s] + val
        if (r != s) out[s, r] <- out[s, r] + val
      }
    }
  }
  out
}

# CalculateExpectedMM_Model1: the observed density spread over the group
# sizes. The undirected form halves the pair count and adds a separate
# diagonal term, because a self-loop is not one of the n(n-1)/2 pairs.
mixing_expected <- function(m, g, np, directed) {
  n <- nrow(m)
  sizes <- as.vector(table(factor(g, levels = seq_len(np))))
  out <- matrix(0, np, np)
  if (n < 2) return(out)

  off <- row(m) != col(m)
  vals <- m[off]
  total_off <- sum(vals[!is.na(vals)])

  if (directed) {
    d <- total_off / (n * (n - 1))
    for (r in seq_len(np)) {
      for (s in seq_len(np)) {
        out[r, s] <- if (r == s) d * sizes[r] * max(0, sizes[r] - 1)
                     else d * sizes[r] * sizes[s]
      }
    }
    return(out)
  }

  # Undirected: the off-diagonal total is over unordered pairs.
  up <- upper.tri(m)
  uvals <- m[up]
  total_pairs <- sum(uvals[!is.na(uvals)])
  d_off <- total_pairs / (n * (n - 1) / 2)
  diag_vals <- diag(m)
  d_diag <- sum(diag_vals[!is.na(diag_vals)]) / n
  for (r in seq_len(np)) {
    for (s in r:np) {
      if (r == s) {
        out[r, r] <- d_off * sizes[r] * max(0, sizes[r] - 1) / 2 +
          d_diag * sizes[r]
      } else {
        out[r, s] <- d_off * sizes[r] * sizes[s]
        out[s, r] <- out[r, s]
      }
    }
  }
  out
}
