# Transitivity and cyclicality.
#
# UCINET: Network | Cohesion | Transitivity (uc_Transitivity.pas) and
# Cyclicality (uc_cyclicity.pas), repository StephenBorgatti/ucinet at commit
# c7b4956. The engines are G2Tools/utransitivity.pas (TripletTransitivity and
# FinalizeTransitivity, which is where the centred measures of Dekker,
# Krackhardt and Snijders 2019 are derived), G2Tools/ucyclicity.pas
# (TripletCyclicity) and G2Tools/utriadcountsnl.pas (triadtransitivity), all
# repository StephenBorgatti/tools at commit 207958a.
#
# The Transitivity dialog has two methods, Triads and Triplets, and defaults to
# Triplets (Method.ItemIndex = 1). Design question 10.2 described a `type =
# c("adjacency","weak","strong")` argument instead; the dialog has no such
# thing, so the argument here follows the dialog. See dev/STATUS.md.
#
# Both routines count the same ordered two-paths and differ only in what closes
# them: transitivity wants the shortcut i -> j, cyclicality wants the return
# arc k -> i. One pass gathers both.
#
# Question 10.2 also folds the overall clustering coefficient into this report
# and drops the node-level one.

#' Transitivity
#'
#' UCINET: Network | Cohesion | Transitivity. How often a two-step path is
#' closed by a direct tie.
#'
#' `method = "triplets"`, the dialog's default, counts ordered two-paths and
#' the transitive triples among them, and reports the twelve measures UCINET
#' derives from those counts - including the centred measures of Dekker,
#' Krackhardt and Snijders (2019), which correct the plain proportion for
#' density. `method = "triads"` classifies the triad census instead and reports
#' the transitive count, the transitive-plus-intransitive count, and their
#' ratio.
#'
#' The overall clustering coefficient is reported alongside, per design
#' question 10.2. The node-level coefficient is deliberately not computed.
#'
#' Missing cells count as no tie, and the diagonal takes no part, both as the
#' engine does.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param method `"triplets"` (the dialog's default) or `"triads"`.
#' @return An object of class `c("xtransitivity", "xucinet_output")`, with the
#'   measures in `$summary` under UCINET's headings.
#' @seealso [xcyclicality()] for the same counts closed the other way, and
#'   [xcohesion()], whose `Transitivity/Closure` is this routine's
#'   `Transitivity`.
#' @examples
#' xtransitivity(campnet)
#' xtransitivity(campnet, method = "triads")
#' @export
xtransitivity <- function(net, method = c("triplets", "triads")) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  require_1mode(net, "xtransitivity()")

  m <- pick_relation(net, NULL)
  a <- binary_offdiag(m)
  assumptions <- if (is_valued(m)) "Data dichotomized at > 0." else character(0)

  summ <- if (identical(method, "triads")) triad_summary(a) else triplet_summary(a)
  # Question 10.2: the overall clustering coefficient belongs in this report.
  summ[["Clustering Coefficient"]] <- clustering_overall(a)

  new_xucinet_output("Transitivity", net, summary = summ,
                     assumptions = assumptions, subclass = "xtransitivity",
                     summary_title = if (identical(method, "triads"))
                       "Triad Transitivity" else "Triplet Transitivity")
}

#' Cyclicality
#'
#' UCINET: Network | Cohesion | Cyclicality. How often a two-step path returns
#' to where it started.
#'
#' The same ordered two-paths [xtransitivity()] counts, closed by the arc that
#' completes a three-cycle rather than by the shortcut.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @return An object of class `c("xcyclicality", "xucinet_output")`, with
#'   UCINET's six measures in `$summary`.
#' @seealso [xtransitivity()].
#' @examples
#' xcyclicality(campnet)
#' @export
xcyclicality <- function(net) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xcyclicality()")

  m <- pick_relation(net, NULL)
  a <- binary_offdiag(m)
  assumptions <- if (is_valued(m)) "Data dichotomized at > 0." else character(0)
  cnt <- triplet_counts(a)
  n <- nrow(a)

  cyc <- if (cnt$twos > 0) cnt$cycles / cnt$twos else NA_real_
  density <- cnt$ties / (n * (n - 1))
  new_xucinet_output(
    "Cyclicality", net,
    summary = list(
      "Threes" = cnt$cycles,
      "Twos" = cnt$twos,
      "Cyclicality" = cyc,
      "Density" = density,
      "Ratio" = if (cnt$twos > 0 && density > 0) cyc / density else NA_real_,
      "Cyclicity Index" = if (cnt$twos > 0 && density < 1)
        (cyc - density) / (1 - density) else NA_real_),
    assumptions = assumptions, subclass = "xcyclicality",
    summary_title = "Triplet Cyclicality")
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

# triadtransitivity: the census, split into the transitive types, the
# intransitive ones, and the vacuous remainder.
#
#   transitive   030T, 120D, 120U, 300      (census 9, 12, 13, 16)
#   intransitive 021C, 111D, 111U, 030C,
#                201, 120C, 210             (census 6, 7, 8, 10, 11, 14, 15)
#   vacuous      003, 012, 102, 021D, 021U  (census 1 to 5)
triad_summary <- function(a) {
  census <- triad_census(a)
  transitive <- sum(census[c(9, 12, 13, 16)])
  intransitive <- sum(census[c(6, 7, 8, 10, 11, 14, 15)])
  den <- transitive + intransitive
  list("Trans" = transitive,
       "Trans+InTrans" = den,
       "Transitivity" = if (den > 0) transitive / den else NA_real_)
}

# The sixteen Holland-Leinhardt triad types, in the census's order.
triad_names <- c("003", "012", "102", "021D", "021U", "021C", "111D", "111U",
                 "030T", "030C", "201", "120D", "120U", "120C", "210", "300")

# The census is internal: UCINET's Triad Census is its own routine and is not
# a chapter 10 row of the crosswalk, so exporting it here would add a function
# the book does not name. `xtransitivity(method = "triads")` is what needs it.
triad_census <- function(a) {
  n <- nrow(a)
  census <- integer(16)
  if (n < 3) return(census)
  for (i in seq_len(n - 2)) {
    for (j in (i + 1):(n - 1)) {
      for (k in (j + 1):n) {
        code <- triad_code(a, i, j, k)
        census[code] <- census[code] + 1L
      }
    }
  }
  census
}

# Classify one triple. The M-A-N counts fix the type except where several types
# share them, and those are separated by whether the asymmetric arcs share a
# source (down), share a target (up), or do neither (cyclic).
triad_code <- function(a, i, j, k) {
  idx <- c(i, j, k)
  pairs <- rbind(c(1, 2), c(1, 3), c(2, 3))
  fwd <- a[cbind(idx[pairs[, 1]], idx[pairs[, 2]])] > 0
  bwd <- a[cbind(idx[pairs[, 2]], idx[pairs[, 1]])] > 0

  mut <- sum(fwd & bwd)
  asym <- sum(xor(fwd, bwd))

  if (mut == 0 && asym == 0) return(1L)    # 003
  if (mut == 0 && asym == 1) return(2L)    # 012
  if (mut == 1 && asym == 0) return(3L)    # 102
  if (mut == 2 && asym == 0) return(11L)   # 201
  if (mut == 3) return(16L)                # 300
  if (mut == 2 && asym == 1) return(15L)   # 210

  arcs <- asym_arcs(idx, fwd, bwd, pairs)
  from <- arcs$from
  to <- arcs$to

  if (mut == 1 && asym == 1) {
    # The asymmetric arc either points into the mutual dyad (111D) or out of
    # it (111U). Both are intransitive, so the split does not change the
    # counts, but a census that reported one of them as always zero would be
    # wrong on its own terms.
    inmut <- idx[unique(as.vector(pairs[which(fwd & bwd), ]))]
    return(if (to %in% inmut) 7L else 8L)
  }

  if (mut == 0 && asym == 2) {
    # Two arcs: a common source is the out-star, a common target the in-star,
    # and anything else a path.
    if (from[1] == from[2]) return(4L)                       # 021D
    if (to[1] == to[2]) return(5L)                           # 021U
    return(6L)                                               # 021C
  }
  if (mut == 0 && asym == 3) {
    # Three arcs and no mutual dyad: a directed cycle gives every node one
    # arc out and one in, and a transitive triple gives one node two out.
    # A common source or target never occurs here, which is why this case
    # cannot be decided the way the two-arc ones are.
    return(if (length(unique(from)) == 3) 10L else 9L)       # 030C / 030T
  }
  # mut == 1 && asym == 2
  if (from[1] == from[2]) return(12L)                        # 120D
  if (to[1] == to[2]) return(13L)                            # 120U
  14L                                                        # 120C
}

# The asymmetric arcs of a triple, as sources and targets in node terms.
asym_arcs <- function(idx, fwd, bwd, pairs) {
  one <- which(xor(fwd, bwd))
  from <- integer(length(one)); to <- integer(length(one))
  for (s in seq_along(one)) {
    p <- one[s]
    u <- idx[pairs[p, 1]]; v <- idx[pairs[p, 2]]
    if (fwd[p]) { from[s] <- u; to[s] <- v } else { from[s] <- v; to[s] <- u }
  }
  list(from = from, to = to)
}

# The overall clustering coefficient: the mean of the ego-network densities,
# which is what usmallworld.getunwtdcc averages. Question 10.2 keeps this one
# and drops the node-level version.
clustering_overall <- function(a) {
  u <- pmax(a, t(a))
  n <- nrow(u)
  per_node <- vapply(seq_len(n), function(i) {
    nb <- which(u[i, ] > 0)
    nb <- nb[nb != i]
    if (length(nb) < 2) return(NA_real_)
    sub <- u[nb, nb, drop = FALSE]
    sum(sub > 0) / (length(nb) * (length(nb) - 1))
  }, numeric(1))
  mean(per_node, na.rm = TRUE)
}
