# Transitivity and cyclicality.
#
# xtransitivity() follows UCINET's command-line function transitivity()
# (runtransitivity in Xdpmat.pas, repository StephenBorgatti/ucinet), which
# loops over every matrix of the dataset, dichotomizes it at > 0, and fills one
# row per matrix with the twelve measures of TripletTransitivity. The engine is
# G2Tools/utransitivity.pas (TripletTransitivity and FinalizeTransitivity,
# where the centred measures of Dekker, Krackhardt and Snijders 2019 are
# derived), repository StephenBorgatti/tools.
#
# Changed 18 Nov 2026 (Steve): xtransitivity() used to follow the menu dialog,
# Network | Cohesion | Transitivity, with a `method` argument for its Triads
# alternative, and carried the overall clustering coefficient in its summary
# (design question 10.2). It now does what the command-line function does: the
# twelve triplet measures for every relation, nothing else. The clustering
# coefficient is xclusteringcoefficient().
#
# xcyclicality() is UCINET: Network | Cohesion | Cyclicality (uc_cyclicity.pas;
# engine G2Tools/ucyclicity.pas, TripletCyclicity). Both routines count the
# same ordered two-paths and differ only in what closes them: transitivity
# wants the shortcut i -> j, cyclicality wants the return arc j -> i.

# The twelve columns of the command-line table, in its order and under its
# headings (y.cdvn.fillwith in runtransitivity).
transitivity_measures <- c(
  "Threes", "Twos", "Transitivity", "Density", "Ratio", "Transitivity Index",
  "TP Covariance", "Transitivity Phi", "Transitivity Phi Beta",
  "T Covariance", "Transitivity Correlation", "Transitivity Beta")

#' Transitivity
#'
#' UCINET command line: `transitivity()`. The proportion of two-step paths
#' i -> k -> j that are closed by a direct tie i -> j, with the eleven related
#' measures UCINET reports beside it, for every relation in the dataset.
#'
#' Each relation is dichotomized at `> 0`, as UCINET does. Missing cells count
#' as no tie and the diagonal takes no part.
#'
#' The twelve columns are:
#'
#' - `Threes`: the number of transitive triples, that is, ordered two-paths
#'   i -> k -> j that are closed by the tie i -> j.
#' - `Twos`: the number of ordered two-paths i -> k -> j (k different from i
#'   and j), closed or not.
#' - `Transitivity`: `Threes / Twos`.
#' - `Density`: the density of the relation.
#' - `Ratio`: `Transitivity / Density`. If there is no tendency toward
#'   transitivity, it is about 1.
#' - `Transitivity Index`: `(Transitivity - Density) / (1 - Density)`.
#' - `TP Covariance`, `Transitivity Phi`, `Transitivity Phi Beta`: the centred
#'   measures of Dekker, Krackhardt and Snijders (2019) under their triadic
#'   probability model (a random ordered triple).
#' - `T Covariance`, `Transitivity Correlation`, `Transitivity Beta`: the
#'   same under their dyadic probability model (a random ordered pair).
#'   Values near 0 mean no increased tendency toward transitive triples.
#'
#' For undirected data `Transitivity` equals the weighted overall clustering
#' coefficient. The clustering coefficients themselves are
#' [xclusteringcoefficient()].
#'
#' @param net A network (any accepted form). 1-mode only.
#' @return An object of class `c("xtransitivity", "xucinet_output")`.
#'   `$summary` is a data frame with one row per relation and the twelve
#'   columns above.
#' @references Dekker, D., Krackhardt, D. and Snijders, T. A. B. (2019).
#'   Transitivity correlation: A descriptive measure of network transitivity.
#'   *Network Science* 7(3), 353-375.
#' @seealso [xclusteringcoefficient()] for the clustering coefficients,
#'   [xcyclicality()] for the same two-paths closed the other way, and
#'   [xcohesion()], whose `Transitivity/Closure` is this routine's
#'   `Transitivity`.
#' @examples
#' xtransitivity(campnet)
#'
#' # one row for each of the three relations
#' xtransitivity(hightech)
#' @export
xtransitivity <- function(net) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xtransitivity()")

  mats <- relation_matrices(net)
  rels <- if (length(mats) == 1L) net$title else xrelations(net)
  valued <- vapply(mats, is_valued, logical(1))
  assumptions <- character(0)
  if (any(valued)) {
    assumptions <- if (length(mats) == 1L) {
      "Data dichotomized at > 0."
    } else {
      paste0("Relation ", rels[valued], " dichotomized at > 0.")
    }
  }

  rows <- lapply(mats, function(m) unlist(triplet_summary(binary_offdiag(m))))
  out <- as.data.frame(do.call(rbind, rows), optional = TRUE)
  names(out) <- transitivity_measures
  rownames(out) <- rels

  new_xucinet_output(
    "Transitivity", net, summary = out, assumptions = assumptions,
    subclass = "xtransitivity", call = match.call(),
    epilogue = c(
      paste0("If there were no particular tendency toward transitivity, the ",
             "ratio of transitivity to density would be 1.0"),
      paste0("TPhi/TC are centred (Dekker, Krackhardt & Snijders 2019): ~0 ",
             "means no increased propensity toward transitive triples.")))
}

#' Cyclicality
#'
#' UCINET: Network | Cohesion | Cyclicality. How often a two-step path returns
#' to where it started, for every relation in the dataset.
#'
#' The same ordered two-paths [xtransitivity()] counts, closed by the arc that
#' completes a three-cycle rather than by the shortcut. Each relation is
#' dichotomized at `> 0`, as UCINET does; missing cells count as no tie and
#' the diagonal takes no part.
#'
#' The six columns are `Threes` (the number of cyclic triples: two-paths
#' i -> k -> j closed by j -> i), `Twos` (the number of two-paths),
#' `Cyclicality` (`Threes / Twos`), `Density`, `Ratio` (`Cyclicality /
#' Density`) and `Cyclicity Index` (`(Cyclicality - Density) / (1 - Density)`).
#'
#' UCINET prints the measures as rows and the relations as columns; here, as
#' in [xtransitivity()], each relation is a row.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @return An object of class `c("xcyclicality", "xucinet_output")`.
#'   `$summary` is a data frame with one row per relation and the six columns
#'   above.
#' @seealso [xtransitivity()].
#' @examples
#' xcyclicality(campnet)
#'
#' # one row for each of the three relations
#' xcyclicality(hightech)
#' @export
xcyclicality <- function(net) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xcyclicality()")

  # uc_cyclicity.pas loops over every matrix of the dataset (net.nm), one
  # column of its output each. Until 19 Nov 2026 this function read only the
  # first relation.
  mats <- relation_matrices(net)
  rels <- if (length(mats) == 1L) net$title else xrelations(net)
  valued <- vapply(mats, is_valued, logical(1))
  assumptions <- character(0)
  if (any(valued)) {
    assumptions <- if (length(mats) == 1L) {
      "Data dichotomized at > 0."
    } else {
      paste0("Relation ", rels[valued], " dichotomized at > 0.")
    }
  }

  rows <- lapply(mats, function(m) cyclicity_summary(binary_offdiag(m)))
  out <- as.data.frame(do.call(rbind, rows), optional = TRUE)
  names(out) <- c("Threes", "Twos", "Cyclicality", "Density", "Ratio",
                  "Cyclicity Index")
  rownames(out) <- rels

  new_xucinet_output(
    "Cyclicality", net, summary = out, assumptions = assumptions,
    subclass = "xcyclicality", call = match.call(),
    summary_title = "Triplet Cyclicality")
}

# TripletCyclicity (G2Tools/ucyclicity.pas) for one dichotomized relation.
cyclicity_summary <- function(a) {
  cnt <- triplet_counts(a)
  n <- nrow(a)
  cyc <- if (cnt$twos > 0) cnt$cycles / cnt$twos else NA_real_
  density <- cnt$ties / (n * (n - 1))
  c(cnt$cycles, cnt$twos, cyc, density,
    if (cnt$twos > 0 && density > 0) cyc / density else NA_real_,
    if (cnt$twos > 0 && density < 1) (cyc - density) / (1 - density) else NA_real_)
}

# Missing counts as no tie and the diagonal takes no part, which is what both
# engines do before they count anything.
binary_offdiag <- function(m) {
  a <- (m > 0) * 1
  a[is.na(a)] <- 0
  diag(a) <- 0
  storage.mode(a) <- "double"
  a
}

# One pass over the ordered pairs, gathering everything both routines need:
#   twos    ordered two-paths i -> k -> j, k not i or j
#   threes  those closed by i -> j        (transitivity)
#   cycles  those closed by j -> i        (cyclicality)
#   sumS2   sum of the squared per-pair two-path counts, for the centred
#           measures' variance term
triplet_counts <- function(a) {
  n <- nrow(a)
  ties <- sum(a > 0)
  # S[i,j] is the number of two-paths from i to j; the matrix product counts
  # them, and the k <> i, j exclusions are the two corrections.
  s <- a %*% a
  diag(s) <- 0
  # k = j would need a[j,j], and k = i would need a[i,i]; both are zero on a
  # diagonal-free adjacency, so no correction is required.
  off <- row(a) != col(a)
  twos <- sum(s[off])
  threes <- sum(s[off] * (a[off] > 0))
  cycles <- sum(s[off] * (t(a)[off] > 0))
  list(ties = ties, twos = twos, threes = threes, cycles = cycles,
       sumS2 = sum(s[off]^2))
}

# FinalizeTransitivity, in its own order: the four classic measures and then
# the six centred ones.
triplet_summary <- function(a) {
  n <- nrow(a)
  cnt <- triplet_counts(a)
  n2 <- n * (n - 1)
  n3 <- n2 * (n - 2)

  transitivity <- if (cnt$twos > 0) cnt$threes / cnt$twos else NA_real_
  d <- if (n2 > 0) cnt$ties / n2 else NA_real_
  varxij <- d * (1 - d)

  # Triadic probability model: the tie indicator against the two-path
  # indicator, over random ordered triples.
  tpcov <- if (n3 > 0) (cnt$threes - d * cnt$twos) / n3 else NA_real_
  p2 <- if (n3 > 0) cnt$twos / n3 else NA_real_
  varxx <- p2 * (1 - p2)

  # Dyadic probability model: the tie indicator against the two-path count,
  # over random ordered pairs.
  tcov <- if (n2 > 0) (cnt$threes - d * cnt$twos) / n2 else NA_real_
  meanS <- if (n2 > 0) cnt$twos / n2 else NA_real_
  varS <- if (n2 > 0) cnt$sumS2 / n2 - meanS^2 else NA_real_

  ratio <- function(num, den) if (!is.na(den) && den > 0) num / den else NA_real_

  list(
    "Threes" = cnt$threes,
    "Twos" = cnt$twos,
    "Transitivity" = transitivity,
    "Density" = d,
    "Ratio" = if (cnt$twos > 0 && !is.na(d) && d > 0) transitivity / d else NA_real_,
    "Transitivity Index" = if (cnt$twos > 0 && !is.na(d) && d < 1)
      (transitivity - d) / (1 - d) else NA_real_,
    "TP Covariance" = tpcov,
    "Transitivity Phi" = if (!is.na(varxij) && varxij > 0 && !is.na(varxx) && varxx > 0)
      tpcov / sqrt(varxij * varxx) else NA_real_,
    "Transitivity Phi Beta" = ratio(tpcov, varxx),
    "T Covariance" = tcov,
    "Transitivity Correlation" = if (!is.na(varxij) && varxij > 0 && !is.na(varS) && varS > 0)
      tcov / sqrt(varxij * varS) else NA_real_,
    "Transitivity Beta" = ratio(tcov, varS))
}
