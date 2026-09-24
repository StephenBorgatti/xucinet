# Density by groups.
#
# The density table of UCINET's Network | Mixing Tables (uc_MixingTables.pas,
# repository StephenBorgatti/ucinet at commit c7b4956): `getdensitymatrix` in
# G2Tools/unetmixingmodels.pas is nothing but `aggbygroups(y, x, p, p, ng, ng)`
# from G2Tools/uAggregate.pas with its default mean, which is the same call
# xcombinenodes() makes (tools commit 207958a).
#
# Division of work with xmixing() (Steve, 23 Sep 2026, STATUS Next 0(e)): this
# routine returns the density table and nothing else, as its name says; the
# observed mixing table and the expected values and ratios under UCINET's three
# models are xmixing()'s. UCINET prints all of them in one report: ledger
# entry 26.
#
# `test =` belongs to chapter 14: the permutation engine arrives with it.

#' Density by groups
#'
#' How densely each group ties to each other group: the mean tie value in each
#' block of the network, blocks being defined by a partition of the nodes. The
#' same table [xcombinenodes()] gives, and the one UCINET's Mixing Tables
#' prints as its density table.
#'
#' The observed mixing table, and what baseline models expect of it, are
#' [xmixing()]'s.
#'
#' @section UCINET equivalent:
#' Network | Mixing Tables, the density table.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data` (G3).
#' @param directed `NULL` (use the data as they are), `TRUE`, or `FALSE` to
#'   symmetrize by the maximum first.
#' @param test Test the ANOVA density models by permutation? `FALSE` by
#'   default: the models are fitted either way, and `test = TRUE` adds their
#'   p-values.
#' @param nperm Number of random permutations for the test. UCINET's default
#'   is 5000.
#' @param seed Random seed for the permutations.
#' @param tails 2 (the default) or 1.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xdensitybygroups", "xucinet_output")` whose
#'   `$matrices` holds `Density` and the coefficients of the three ANOVA density
#'   models, and whose `$summary` holds each model's fit (one row per model).
#' @seealso [xmixing()] for observed and expected mixing, [xcombinenodes()],
#'   and [xhomophily()].
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' xdensitybygroups(campnet, gender)
#' @export
xdensitybygroups <- function(net, attribute, directed = NULL, test = FALSE,
                             data = NULL, nperm = 5000, seed = NULL, tails = 2) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xdensitybygroups()")

  tails <- check_tails(tails)

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  groups <- res$values
  m <- pick_relation(net, NULL)
  if (length(groups) != nrow(m)) {
    stop("the partition has ", length(groups), " values but the network has ",
         nrow(m), " nodes.", call. = FALSE)
  }

  assumptions <- character(0)
  if (isFALSE(directed) && !isTRUE(isSymmetric(unname(m)))) {
    m <- pmax(m, t(m))
    assumptions <- c(assumptions, "Symmetrized with the maximum.")
  }

  keys <- sort(unique(groups[!is.na(groups)]))
  labs <- as.character(keys)
  dens <- aggregate_blocks(m, groups, "mean", diagonal = FALSE)
  dimnames(dens) <- list(labs, labs)

  models <- anova_density(m, match(groups, keys), labs,
                          if (isTRUE(test)) nperm else 0, seed, tails)
  if (isTRUE(test)) {
    assumptions <- c(assumptions, sprintf(
      "ANOVA density models tested by Y permutation: %d permutations, %d-tailed.",
      as.integer(nperm), tails))
  }

  new_xucinet_output(
    "Density by groups", net,
    matrices = c(list(Density = dens), models$tables),
    summary = models$fit,
    show_summary = if (isTRUE(test)) NULL else character(0),
    hide = if (isTRUE(test)) character(0) else names(models$tables),
    summary_title = "ANOVA density models: MODEL FIT",
    assumptions = assumptions, subclass = "xdensitybygroups",
    call = match.call())
}

# ---- ANOVA density models: XCatC2.pas, autocorranova ----------------------------
#
# UCINET: Tools | Testing Hypotheses | Mixed Dyadic/Nodal | Categorical
# attributes | Anova Density models (XCatC2.pas; ucinet commit c7b4956). Each
# model regresses the off-diagonal cells (both triangles) on dummies built
# from the partition:
#   Constant Homophily     one dummy: i and j in the same group
#   Variable Homophily     one dummy per group: i and j both in group k
#   Structural Blockmodel  one dummy per block (a, b) except the last
# and the coefficients are tested by permuting Y (rows and columns together),
# as the Y-permutation MRQAP does; that engine is used, so nothing is computed
# twice. UCINET's default model is the blockmodel; all three are fitted here
# (SPEC addendum, 23 Sep 2026, item 5). UCINET issue 33: the unit's adjusted
# R-square is off by one; the standard one is reported. Missing cells, which
# the unit reads as values, are dropped (ledger entry 42).
anova_density <- function(m, g, labs, nperm, seed, tails) {
  n <- nrow(m)
  cells <- qap_cells(n, FALSE)
  ri <- row(m)[cells]; ci <- col(m)[cells]
  gi <- g[ri]; gj <- g[ci]
  nb <- length(labs)
  build <- list(
    `Constant Homophily` = function() cbind(`In-group` = (gi == gj) * 1),
    `Variable Homophily` = function() {
      x <- vapply(seq_len(nb), function(k) (gi == k & gj == k) * 1, numeric(length(cells)))
      x <- matrix(x, ncol = nb); colnames(x) <- paste("Group", labs); x
    },
    `Structural Blockmodel` = function() {
      blk <- nb * (gi - 1) + gj
      x <- vapply(seq_len(nb * nb - 1), function(k) (blk == k) * 1, numeric(length(cells)))
      x <- matrix(x, ncol = nb * nb - 1)
      colnames(x) <- as.vector(t(outer(labs, labs, paste, sep = "-")))[seq_len(nb * nb - 1)]
      x
    })
  perms <- if (nperm > 0) qap_perms(n, nperm, seed, NULL) else list()
  tables <- list()
  fit <- data.frame(`R-Square` = numeric(0), `Adj R-Sqr` = numeric(0),
                    `P(R-Sqr)` = numeric(0), Obs = numeric(0), check.names = FALSE)
  for (nm in names(build)) {
    xmat <- build[[nm]]()
    xok <- stats::complete.cases(xmat)
    d <- list(y = m, xmat = xmat, xok = xok, cells = cells, n = n, sym = FALSE,
              xnames = colnames(xmat))
    obs <- mrqap_observed(d)
    k <- ncol(xmat)
    yp <- if (nperm > 0) mrqap_yperm(d, obs, perms, tails) else
      list(pvals = matrix(NA_real_, k + 1, 3), sig = rep(NA_real_, k + 1),
           fitp = NA_real_)
    tab <- cbind(`Un-stdized Coefficient` = obs$coef,
                 `Stdized Coefficient` = obs$beta, Significance = yp$sig,
                 `Proportion As Large` = yp$pvals[, 1],
                 `Proportion As Small` = yp$pvals[, 2],
                 `Proportion As Extreme` = yp$pvals[, 3])
    rownames(tab) <- c(colnames(xmat), "Intercept")
    tables[[nm]] <- tab
    fit[nm, ] <- c(obs$r2, obs$adjr2, yp$fitp, obs$nobs)
  }
  list(tables = tables, fit = fit)
}

