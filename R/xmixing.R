# Mixing tables.
#
# UCINET: Network | Mixing Tables (uc_MixingTables.pas, TMixingTables.run,
# repository StephenBorgatti/ucinet at commit c7b4956), with the engine
# G2Tools/unetmixingmodels.pas (getobsmixingmatrix, getexpmixingmatrix and the
# six CalculateExpectedMM_Model* procedures); repository StephenBorgatti/tools
# at commit 207958a.
#
# Division of work with xdensitybygroups() (Steve, 23 Sep 2026, STATUS Next
# 0(e)): xdensitybygroups() returns the density table and nothing else; this
# routine returns the observed mixing table and, in one call, the expected
# table and observed/expected ratio under all three of UCINET's models. Two
# departures from UCINET's routine, both ledger entry 26: UCINET runs one model
# per call (ExpectedModel.ItemIndex, Density by default) and also prints the
# density table.
#
# "For undirected networks, treat ties as" = Directed (TreatTies.ItemIndex =
# 0) applies only to symmetric data: `directed := not x.IsSymmetric; if not
# directed then directed := treatties.ItemIndex = 0`, so an asymmetric matrix
# is always directed.
#
# One more departure, UCINET issue 25: the engine tests `val <> ucommon.na`,
# and a missing cell is stored as bna = 1e38, not na = 1e37, so missing cells
# are summed into every table as 1e38. Here they are skipped.
#
# A group-level routine under the 23 Sep level-of-analysis rule: ten
# group-by-group tables, the same ten whatever the arguments: the observed
# table, three expected, three ratios, and the coefficients of UCINET's three
# ANOVA density models (Tools | Testing Hypotheses | Mixed Dyadic/Nodal |
# Categorical attributes | Anova Density models), which Steve moved here from
# xdensitybygroups() on 27 Sep 2026 (issue #33). `test = TRUE` adds their
# permutation p-values and prints them.

# The three models, in the dialog's order, with the heading each table gets.
mixing_models <- c(density = "density", configuration = "configuration",
                   fixedout = "fixed outdegree")

#' Mixing tables
#'
#' UCINET: Network | Mixing Tables. How the ties of a network fall within and
#' between the groups of a partition, and how that compares with what three
#' baseline models expect.
#'
#' Seven group-by-group tables come back, always the same seven:
#'
#' * `Observed`: the total tie value from each group to each other group.
#' * `Expected (density)`, `Expected (configuration)` and
#'   `Expected (fixed outdegree)`: what each model predicts for the same cells.
#' * `Ratio (density)`, `Ratio (configuration)` and `Ratio (fixed outdegree)`:
#'   observed over expected, missing where the expectation is 0.
#'
#' The three models:
#'
#' * **density**: the network's overall density spread over the group sizes,
#'   so a block's expectation is density times the number of pairs in it.
#' * **configuration**: groups keep their total outgoing and incoming tie value
#'   (their total strength, for undirected data) and send it in proportion to
#'   the other groups' totals.
#' * **fixed outdegree**: groups keep their total outgoing tie value and send
#'   it to other nodes in proportion to group size.
#'
#' UCINET computes one model per run, chosen in the dialog, and prints the
#' density table as well. Here all three models come back together, and the
#' density table is [xdensitybygroups()]'s.
#'
#' The result also holds UCINET's three ANOVA density models (book 14.5), each
#' a regression of the tie values on dummies built from the partition:
#' **constant homophily** (one dummy, same group), **variable homophily** (one
#' dummy per group) and the **structural blockmodel** (one dummy per block).
#' They are always fitted; `test = TRUE` tests them by permuting the network's
#' rows and columns together and prints them with their fit. UCINET's dialog
#' fits one of them per run, the blockmodel by default.
#'
#' Symmetric data are treated as directed unless `directed = FALSE`, as in the
#' dialog; asymmetric data are always directed. Undirected data count each
#' edge once.
#'
#' @section UCINET equivalent:
#' Network | Mixing Tables, run once for each *Model for expected values*.
#' *For undirected networks, treat ties as* is `directed`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data`. Numbers are rounded
#'   to whole numbers, as UCINET does.
#' @param relation Which relation of a multi-relation dataset, by name (in any case) or
#'   position. Defaults to the first.
#' @param directed Treat symmetric data as directed? `TRUE`, as the dialog
#'   does. Has no effect on asymmetric data.
#' @param data A data frame to look `attribute` up in.
#' @param test Test the ANOVA density models by permutation, and print them?
#'   `FALSE` by default.
#' @param nperm Number of random permutations for the test. UCINET's default
#'   is 5000.
#' @param seed Random seed for the permutations.
#' @param tails 2 (the default) or 1.
#' @return An object of class `c("xmixing", "xucinet_output")` whose
#'   `$matrices` holds the seven tables above, in that order, then the
#'   coefficients of the three ANOVA density models (`Constant Homophily`,
#'   `Variable Homophily`, `Structural Blockmodel`); `$summary` holds each
#'   model's fit, one row per model.
#' @seealso [xdensitybygroups()] for the density table, [xhomophily()] for
#'   summary measures of the same mixing, and [xcombinenodes()].
#' @examples
#' xmixing(campnet, camp92_attr$Gender)
#' xmixing(campnet, camp92_attr$Gender, test = TRUE, nperm = 1000, seed = 1)
#' @export
xmixing <- function(net, attribute, relation = NULL, directed = TRUE,
                    data = NULL, test = FALSE, nperm = 5000, seed = NULL,
                    tails = 2) {
  net <- xnet(net, substitute(net))
  rel <- ego_relation(net, relation, "xmixing()")
  m <- rel$m
  n <- nrow(m)
  att <- ego_attribute(attribute, net, data, deparse1(substitute(attribute)), n,
                       "xmixing()")

  # getattr: `attr.cell[i] := round(m.cell[i,k])`, then renumbered 1..ng.
  values <- att$values
  if (is.numeric(values)) values <- round(values)
  cats <- category_keys(values)
  g <- cats$codes
  ng <- length(cats$keys)
  labs <- cats$labels

  is_dir <- !isTRUE(isSymmetric(unname(m))) || isTRUE(directed)
  assumptions <- c(rel$note,
                   if (!is_dir) "Ties treated as undirected: each edge counted once.")

  obs <- mixing_observed(m, g, ng, is_dir)
  dimnames(obs) <- list(labs, labs)
  exps <- list(density = mixing_expected(m, g, ng, is_dir),
               configuration = mixing_expected_config(m, g, ng, is_dir),
               fixedout = mixing_expected_fixedout(m, g, ng, is_dir))
  exps <- lapply(exps, function(e) { dimnames(e) <- list(labs, labs); e })
  ratios <- lapply(exps, function(e) ifelse(e > 0, obs / e, NA_real_))

  names(exps) <- paste0("Expected (", mixing_models[names(exps)], ")")
  names(ratios) <- paste0("Ratio (", mixing_models[names(ratios)], ")")

  tails <- check_tails(tails)
  models <- anova_density(m, g, labs, if (isTRUE(test)) nperm else 0, seed, tails)
  if (length(models$failed)) {
    assumptions <- c(assumptions, sprintf(
      "ANOVA density model%s not estimable (collinear group dummies): %s.",
      if (length(models$failed) > 1) "s" else "", paste(models$failed, collapse = ", ")))
  }
  if (isTRUE(test)) {
    assumptions <- c(assumptions, sprintf(
      "ANOVA density models tested by Y permutation: %d permutations, %d-tailed.",
      as.integer(nperm), tails))
  }

  new_xucinet_output(
    "Mixing Tables", net,
    matrices = c(list(Observed = obs), exps, ratios, models$tables),
    summary = models$fit,
    show_summary = if (isTRUE(test)) NULL else character(0),
    hide = if (isTRUE(test)) character(0) else names(models$tables),
    summary_title = "ANOVA density models: MODEL FIT",
    assumptions = assumptions,
    fields = c("Input Attribute:" = att$name,
               "(for undirected data) Treat ties as:" =
                 if (isTRUE(directed)) "Directed" else "Undirected"),
    subclass = "xmixing", call = match.call())
}

# The value of every valid cell whose two nodes both have a group, as the
# engine's loops see it (missing cells skipped: UCINET issue 25).
mixing_cells <- function(m, g) {
  ok <- !is.na(m) & outer(!is.na(g), !is.na(g), "&")
  w <- m
  w[!ok] <- 0
  w
}

# CalculateExpectedMM_Model2. Directed: S_out(r) S_in(s) / W over every cell,
# diagonal included. Undirected: K(r) K(s) / 2W, K a group's total strength
# (row sums over every column) and 2W the sum of every cell.
mixing_expected_config <- function(m, g, np, directed) {
  w <- mixing_cells(m, g)
  gi <- factor(g, levels = seq_len(np))
  out_r <- tapply(rowSums(w), gi, sum)
  out_r[is.na(out_r)] <- 0
  total <- sum(w)
  if (total == 0) return(matrix(0, np, np))
  if (directed) {
    in_s <- tapply(colSums(w), gi, sum)
    in_s[is.na(in_s)] <- 0
    return(outer(as.vector(out_r), as.vector(in_s)) / total)
  }
  outer(as.vector(out_r), as.vector(out_r)) / total
}

# CalculateExpectedMM_Model3. Directed: a group's outgoing total spread over
# the other n - 1 nodes by group size (own group n_r - 1). Undirected: the
# same, averaged over the two directions.
mixing_expected_fixedout <- function(m, g, np, directed) {
  n <- nrow(m)
  if (n <= 1) return(matrix(0, np, np))
  w <- mixing_cells(m, g)
  gi <- factor(g, levels = seq_len(np))
  k <- tapply(rowSums(w), gi, sum)
  k[is.na(k)] <- 0
  k <- as.vector(k)
  sizes <- as.vector(table(gi))
  out <- matrix(0, np, np)
  for (r in seq_len(np)) for (s in seq_len(np)) {
    out[r, s] <- if (directed) {
      if (r == s) k[r] * (sizes[r] - 1) / (n - 1) else k[r] * sizes[s] / (n - 1)
    } else {
      if (r == s) k[r] * (sizes[r] - 1) / (2 * (n - 1))
      else (k[r] * sizes[s] + k[s] * sizes[r]) / (2 * (n - 1))
    }
  }
  out
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
# ---- ANOVA density models: XCatC2.pas, autocorranova (moved from xdensitybygroups.R, #33)
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
  failed <- character(0)
  fit <- data.frame(`R-Square` = numeric(0), `Adj R-Sqr` = numeric(0),
                    `P(R-Sqr)` = numeric(0), Obs = numeric(0), check.names = FALSE)
  for (nm in names(build)) {
    xmat <- build[[nm]]()
    xok <- stats::complete.cases(xmat)
    d <- list(y = m, xmat = xmat, xok = xok, cells = cells, n = n, sym = FALSE,
              xnames = colnames(xmat))
    k <- ncol(xmat)
    # A model whose dummies are collinear (a group of one has an empty
    # same-group dummy; a block with no cells an empty block dummy) cannot be
    # estimated; it comes back as NA rather than stopping xmixing(), which
    # fits all three whether or not they are printed.
    obs <- tryCatch(mrqap_observed(d), error = function(e) NULL)
    if (is.null(obs)) {
      tab <- matrix(NA_real_, k + 1, 6, dimnames = list(c(colnames(xmat), "Intercept"),
        c("Un-stdized Coefficient", "Stdized Coefficient", "Significance",
          "Proportion As Large", "Proportion As Small", "Proportion As Extreme")))
      tables[[nm]] <- tab
      fit[nm, ] <- NA_real_
      failed <- c(failed, nm)
      next
    }
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
  list(tables = tables, fit = fit, failed = failed)
}

