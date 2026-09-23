# Whole-network measures: the 33-measure block.
#
# UCINET: Network | Whole-Network Measures | Multiple Whole-Network Measures
# (menu item Multiplecohesionmeasures1, dialog uc_CohesionDlg.pas, repository
# StephenBorgatti/ucinet at commit c7b4956). The measures themselves are
# G1Tools/ucohesion.pas, function getcohesion, with the per-measure helpers in
# G2Tools/utnodelist.pas, G1Tools/usmallworld.pas and G1Tools/ukcores.pas
# (repository StephenBorgatti/tools at commit 207958a).
#
# Design question 10.4 named this routine, and the chapter 10 prompt named the
# cohesion block of the Density form instead. They are the same thing: both
# call ucohesion.getcohesion, which is why the Phase 0 density goldens hold 33
# values for a one-relation dataset.
#
# Two things in getcohesion are easy to get wrong and are worth naming here.
#
# "Components" is Tarjan's algorithm - tnodelist.getcomponents is commented as
# such and computes **strongly** connected components, not weak ones. For a
# symmetric network the two agree; for a directed one they do not, and the
# Small Worldness measure is suppressed on `ncomp > 1`, so it is the strong
# count that decides whether it is reported.
#
# The last two measures are computed after the network has been symmetrized -
# the Delphi says `//must be last` - so K-core index and Deg Centralization
# always describe the underlying graph, whatever the direction of the ties.
# UCINET's own log says so for the K-core index.

# The 33 measures, in the order getcohesion builds its row labels, with
# UCINET's own headings. The order is part of the output, because the block is
# printed and golden-tested as a matrix.
cohesion_measures <- c(
  "# of nodes", "# of ties",
  "Avg Degree", "Indeg H-Index", "K-core index", "Deg Centralization",
  "Out-Centralization", "In-Centralization",
  "Indeg Corr", "Outdeg Corr",
  "Density", "Components", "Largest Component",
  "Component Ratio", "Connectedness", "Fragmentation",
  "Transitivity/Closure", "Transitivity Index", "Avg Distance",
  "Prop within 3",
  "SD Distance", "Diameter", "Wiener Index", "Dependency Sum", "Breadth",
  "Compactness", "Small Worldness",
  "Mutuals", "Asymmetrics", "Nulls",
  "Arc Reciprocity", "Dyad Reciprocity", "Reciprocity Index")

#' Whole-network measures
#'
#' UCINET: Network | Whole-Network Measures | Multiple Whole-Network Measures.
#' Thirty-three measures of the network as a whole, in UCINET's order and under
#' UCINET's headings.
#'
#' Valued data are dichotomized at `> 0` and self-ties are removed, both as the
#' routine does. The K-core index and `Deg Centralization` are always computed
#' on the underlying undirected graph, whatever `directed` says, because
#' `getcohesion` symmetrizes before computing them.
#'
#' `Components` counts **strongly** connected components: the Delphi uses
#' Tarjan's algorithm. `Connectedness` is a different idea - the proportion of
#' ordered pairs that can reach each other at all - so the two need not agree
#' about whether a network is in one piece.
#'
#' `Small Worldness` is reported only when the network is strongly connected,
#' and the distance measures of a disconnected network are computed over the
#' reachable pairs only. UCINET prints the same two caveats.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param directed `NULL` (detect), `TRUE`, or `FALSE` to ignore the direction
#'   of ties, which is the dialog's "Ignore direction of ties" box. UCINET
#'   leaves it unchecked, so `NULL` matches the default.
#' @return An object of class `c("xcohesion", "xucinet_output")`. `$summary` is
#'   a data frame of the 33 measures, one row each, with one column per
#'   relation - the shape UCINET prints and saves.
#' @seealso [xdensity()] for the density block alone, [xcomponents()] for the
#'   membership rather than the count, and [xgeodesic()] for the distances the
#'   distance measures are built on.
#' @examples
#' xcohesion(campnet)
#'
#' # ignoring direction changes most of the block
#' xcohesion(campnet, directed = FALSE)
#' @export
xcohesion <- function(net, directed = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xcohesion()")

  mats <- relation_matrices(net)
  rels <- xrelations(net)
  assumptions <- character(0)

  cols <- lapply(seq_along(mats), function(k) {
    m <- mats[[k]]
    if (is_valued(m)) {
      assumptions <<- c(assumptions,
                        paste0("Relation ", rels[k], " was valued and has been ",
                               "dichotomized."))
    }
    a <- adjacency(m)
    if (isFALSE(directed)) {
      a <- symmetrize_max(a)
    }
    cohesion_column(a)
  })

  out <- as.data.frame(cols, optional = TRUE)
  # d.cdvn: the dataset's own name for one relation, the relation names for a
  # stack.
  names(out) <- if (length(mats) == 1L) net$title else rels
  rownames(out) <- cohesion_measures

  if (isFALSE(directed)) {
    assumptions <- c(assumptions, "Direction of ties ignored.")
  }
  assumptions <- c(assumptions, "Self-ties removed.")
  if (any(vapply(cols, function(v) v[["Components"]] > 1, logical(1)))) {
    assumptions <- c(
      assumptions,
      paste0("Network is disconnected: distance measures are computed over ",
             "the reachable pairs only, and Small Worldness is not reported."))
  }

  new_xucinet_output("Network Cohesion", net, summary = out,
                     assumptions = assumptions, subclass = "xcohesion",
                     summary_title = "Whole network measures")
}

# One column of the block, for one relation's adjacency matrix.
cohesion_column <- function(a) {
  n <- nrow(a)
  v <- stats::setNames(rep(NA_real_, length(cohesion_measures)),
                       cohesion_measures)
  if (n <= 1) {
    stop("xcohesion() needs more than one node; this network has ", n, ".",
         call. = FALSE)
  }

  outdeg <- rowSums(a)
  indeg <- colSums(a)
  ties <- sum(outdeg)                      # getnumties: the arc count
  avgdeg <- ties / n                       # getavgdegree

  v[["# of nodes"]] <- n
  v[["# of ties"]] <- ties
  v[["Avg Degree"]] <- avgdeg
  v[["Indeg H-Index"]] <- h_index(indeg)
  # getdirdegcentralization divides by (n-1)^2, unlike the symmetric form
  # below, which divides by (n-1)(n-2).
  v[["Out-Centralization"]] <- (max(outdeg) * n - ties) / (n - 1)^2
  v[["In-Centralization"]] <- (max(indeg) * n - ties) / (n - 1)^2
  v[["Indeg Corr"]] <- degree_correlation(a, indeg)
  v[["Outdeg Corr"]] <- degree_correlation(a, outdeg)

  # componentmeasures, on the strong components.
  comp <- strong_components(a)
  ncomp <- length(unique(comp))
  v[["Components"]] <- ncomp
  v[["Largest Component"]] <- max(table(comp))
  v[["Component Ratio"]] <- (ncomp - 1) / (n - 1)

  # Everything from here to the dyad census sits behind `if avgdeg > 0`.
  if (avgdeg > 0) {
    density <- avgdeg / (n - 1)
    v[["Density"]] <- density
    transit <- closure(a)
    v[["Transitivity/Closure"]] <- transit
    v[["Transitivity Index"]] <- if (density < 1) (transit - density) / (1 - density)
                                 else NA_real_
    dists <- cohesion_distances(a)
    v[names(dists)] <- dists
    v[["Small Worldness"]] <- if (ncomp == 1) {
      small_worldness(transit, density, v[["Avg Distance"]], n)
    } else NA_real_

    dc <- dyad_census(a)
    total <- sum(dc)
    v[["Mutuals"]] <- dc[["mutual"]] / total
    v[["Asymmetrics"]] <- dc[["asymmetric"]] / total
    v[["Nulls"]] <- dc[["null"]] / total
  } else {
    density <- 0
  }

  rec <- reciprocity_pair(a)
  v[["Arc Reciprocity"]] <- rec[["arc"]]
  v[["Dyad Reciprocity"]] <- rec[["dyad"]]
  v[["Reciprocity Index"]] <- if (avgdeg > 0 && density < 1 && !is.na(rec[["arc"]])) {
    (rec[["arc"]] - density) / (1 - density)
  } else NA_real_

  # `//must be last`: both of these describe the underlying graph.
  u <- symmetrize_max(a)
  v[["K-core index"]] <- max(kcore_numbers(u))
  # getoutdegcentralization: (maxdeg * n - sum) / (n^2 - 3n + 2).
  udeg <- rowSums(u)
  v[["Deg Centralization"]] <- (max(udeg) * n - sum(udeg)) / (n^2 - 3 * n + 2)
  v
}

cohesion_distance_names <- function() {
  c("Avg Distance", "Prop within 3", "Wiener Index", "Dependency Sum",
    "SD Distance", "Breadth", "Compactness", "Diameter", "Connectedness",
    "Fragmentation")
}

# getdistmeasures. `s` collects the reachable distances; `sr` collects their
# reciprocals over *every* ordered pair, with 0 where there is no path, which
# is what makes Compactness a proportion rather than an average over the
# reachable pairs.
cohesion_distances <- function(a) {
  n <- nrow(a)
  d <- geodesics(a)
  off <- row(d) != col(d)
  reachable <- off & !is.na(d)
  s <- d[reachable]
  npairs <- n * (n - 1)

  # sr takes 1/d for a reachable pair and 0 for an unreachable one, over all
  # n(n-1) ordered pairs, so its mean is the reciprocal sum over that total.
  compactness <- sum(1 / s) / npairs
  le3 <- sum(s > 0 & s < 4)

  c("Avg Distance"   = mean(s),
    "Prop within 3"  = le3 / npairs,
    "Wiener Index"   = sum(s),
    # s.sum - s.n, the sum of (distance - 1) over the reachable pairs.
    "Dependency Sum" = sum(s) - length(s),
    "SD Distance"    = sqrt(mean((s - mean(s))^2)),
    "Breadth"        = 1 - compactness,
    "Compactness"    = compactness,
    "Diameter"       = max(s),
    "Connectedness"  = length(s) / npairs,
    "Fragmentation"  = 1 - length(s) / npairs)
}

# getdegreeh: the h-index of the indegree sequence.
h_index <- function(deg) {
  d <- sort(deg, decreasing = TRUE)
  hit <- which(d >= seq_along(d))
  if (!length(hit)) 0 else max(hit)
}

# getdegreecorrelation: correlate the tie indicator with the absolute degree
# difference, over every ordered pair of distinct nodes.
degree_correlation <- function(a, deg) {
  off <- row(a) != col(a)
  x <- a[off]
  y <- abs(outer(deg, deg, "-"))[off]
  if (stats::sd(x) == 0 || stats::sd(y) == 0) return(NA_real_)
  stats::cor(x, y)
}

# countclosure: the proportion of directed two-paths a -> b -> c, with a, b and
# c distinct, that are closed by an arc a -> c.
closure <- function(a) {
  n <- nrow(a)
  twos <- 0
  threes <- 0
  for (b in seq_len(n)) {
    into <- which(a[, b] > 0)
    outof <- which(a[b, ] > 0)
    into <- into[into != b]
    outof <- outof[outof != b]
    if (!length(into) || !length(outof)) next
    for (i in into) {
      cs <- outof[outof != i]
      if (!length(cs)) next
      twos <- twos + length(cs)
      threes <- threes + sum(a[i, cs] > 0)
    }
  }
  if (twos > 0) threes / twos else NA_real_
}

# getdyadcensus, over the unordered pairs: 2 is a mutual dyad, 1 asymmetric,
# 0 null.
dyad_census <- function(a) {
  up <- upper.tri(a)
  x <- a[up] > 0
  y <- t(a)[up] > 0
  c(mutual = sum(x & y), asymmetric = sum(xor(x, y)), null = sum(!x & !y))
}

# getreciprocity. `ra` counts reciprocated arcs and `ua` unreciprocated ones,
# so the dyad form's ra/(ra + 2*ua) is mutual dyads over non-null dyads.
reciprocity_pair <- function(a) {
  arcs <- which(a > 0 & row(a) != col(a), arr.ind = TRUE)
  if (!nrow(arcs)) return(c(arc = NA_real_, dyad = NA_real_))
  back <- a[cbind(arcs[, 2], arcs[, 1])] > 0
  ra <- sum(back)
  ua <- sum(!back)
  c(arc = ra / (ra + ua), dyad = ra / (ra + 2 * ua))
}

# Batagelj and Zaversnik's peeling, which is what ukcores.cores implements;
# the reported index is the largest core number in the graph.
kcore_numbers <- function(u) {
  n <- nrow(u)
  deg <- rowSums(u)
  alive <- rep(TRUE, n)
  core <- integer(n)
  k <- 0
  for (step in seq_len(n)) {
    live <- which(alive)
    v <- live[which.min(deg[live])]
    k <- max(k, deg[v])
    core[v] <- k
    alive[v] <- FALSE
    nb <- which(u[v, ] > 0 & alive)
    deg[nb] <- deg[nb] - 1
  }
  core
}

# getswiprecalc. The observed clustering and path length against what a random
# graph of the same size and density would give.
small_worldness <- function(cc, density, apl, n) {
  euler <- 0.5772156649
  avgdeg <- density * (n - 1)
  if (avgdeg <= 1 || is.na(apl) || density <= 0) return(NA_real_)
  aplrand <- (log(n) - euler) / log(avgdeg) + 0.5
  (cc * aplrand) / (density * apl)
}

# Strongly connected components. tnodelist.getcomponents is Tarjan's; with the
# geodesic matrix already to hand, mutual reachability gives the same classes
# without a second traversal.
strong_components <- function(a) {
  d <- geodesics(a)
  reach <- !is.na(d)
  diag(reach) <- TRUE
  mutual <- reach & t(reach)
  n <- nrow(a)
  comp <- integer(n)
  k <- 0L
  for (i in seq_len(n)) {
    if (comp[i] != 0L) next
    k <- k + 1L
    comp[which(mutual[i, ] & comp == 0L)] <- k
  }
  comp
}
