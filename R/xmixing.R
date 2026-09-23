# Mixing tables.
#
# UCINET: Network | Mixing Tables (uc_MixingTables.pas, TMixingTables.run,
# repository StephenBorgatti/ucinet at commit c7b4956), with the engine
# G2Tools/unetmixingmodels.pas (getobsmixingmatrix, getexpmixingmatrix and the
# six CalculateExpectedMM_Model* procedures) and, for the density table,
# G2Tools/uAggregate.pas aggbygroups; repository StephenBorgatti/tools at
# commit 207958a. Added 23 Sep 2026 at Steve's request (question 10 of that
# day): xdensitybygroups() is left as it is, and this routine imitates UCINET's
# own, all three expected-value models included.
#
# Dialog defaults (uc_MixingTables.dfm): Model for expected values = Density
# (ExpectedModel.ItemIndex = 0); "For undirected networks, treat ties as" =
# Directed (TreatTies.ItemIndex = 0). The second applies only to symmetric
# data: `directed := not x.IsSymmetric; if not directed then directed :=
# treatties.ItemIndex = 0`, so an asymmetric matrix is always directed.
#
# One departure, UCINET issue 25: the engine tests `val <> ucommon.na`, and a
# missing cell is stored as bna = 1e38, not na = 1e37, so missing cells are
# summed into every table as 1e38. Here they are skipped.
#
# A group-level routine under the 23 Sep level-of-analysis rule: four
# group-by-group matrices and nothing at the node level.

#' Mixing tables
#'
#' UCINET: Network | Mixing Tables. How the ties of a network fall within and
#' between the groups of a partition, and how that compares with what a
#' baseline model expects.
#'
#' Four group-by-group tables come back, in UCINET's order:
#'
#' * `Observed`: the total tie value from each group to each other group.
#' * `Expected`: what the chosen model predicts for the same cells.
#' * `Density`: the mean tie value in each block, the same figure
#'   [xcombinenodes()] gives.
#' * `Ratio`: observed over expected, missing where the expectation is 0.
#'
#' The three models for the expected values:
#'
#' * `"density"` (the default): the network's overall density spread over the
#'   group sizes, so a block's expectation is density times the number of
#'   pairs in it.
#' * `"configuration"`: groups keep their total outgoing and incoming tie
#'   value (their total strength, for undirected data) and send it in
#'   proportion to the other groups' totals.
#' * `"fixedout"`: groups keep their total outgoing tie value and send it to
#'   other nodes in proportion to group size.
#'
#' Symmetric data are treated as directed unless `directed = FALSE`, as in the
#' dialog; asymmetric data are always directed. Undirected data count each
#' edge once.
#'
#' @section UCINET equivalent:
#' Network | Mixing Tables. *Model for expected values* is `model`; *For
#' undirected networks, treat ties as* is `directed`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data`. Numbers are rounded
#'   to whole numbers, as UCINET does.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param model `"density"` (the default), `"configuration"` or `"fixedout"`.
#' @param directed Treat symmetric data as directed? `TRUE`, as the dialog
#'   does. Has no effect on asymmetric data.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xmixing", "xucinet_output")` whose
#'   `$matrices` holds `Observed`, `Expected`, `Density` and `Ratio`.
#' @seealso [xdensitybygroups()], [xhomophily()] for summary measures of the
#'   same mixing, and [xcombinenodes()].
#' @examples
#' xmixing(campnet, camp92_attr$Gender)
#' xmixing(campnet, camp92_attr$Gender, model = "configuration")
#' @export
xmixing <- function(net, attribute, relation = NULL,
                    model = c("density", "configuration", "fixedout"),
                    directed = TRUE, data = NULL) {
  net <- xnet(net, substitute(net))
  model <- match.arg(model)
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
  exp <- switch(model,
                density = mixing_expected(m, g, ng, is_dir),
                configuration = mixing_expected_config(m, g, ng, is_dir),
                fixedout = mixing_expected_fixedout(m, g, ng, is_dir))
  dens <- aggregate_blocks(m, values, "mean", diagonal = FALSE)
  ratio <- ifelse(exp > 0, obs / exp, NA_real_)
  dimnames(obs) <- dimnames(exp) <- dimnames(ratio) <- list(labs, labs)
  dimnames(dens) <- list(labs, labs)

  model_label <- c(density = "Density", configuration = "Configuration",
                   fixedout = "Fixed outdegree")[[model]]
  new_xucinet_output(
    "Mixing Tables", net,
    matrices = list(Observed = obs, Expected = exp, Density = dens,
                    Ratio = ratio),
    assumptions = assumptions,
    fields = c("Input Attribute:" = att$name,
               "(for undirected data) Treat ties as:" =
                 if (isTRUE(directed)) "Directed" else "Undirected",
               "Model for expected values:" = model_label),
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
