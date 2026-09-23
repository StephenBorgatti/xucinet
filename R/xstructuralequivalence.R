# Profile structural equivalence.
#
# UCINET: Network | Roles & Positions | Structural Equivalence | Profile.
# Ported from Xse.pas (LilStructuralEquivalence2; repository
# StephenBorgatti/ucinet at commit c7b4956) and its engine, sesim2 with the
# similarity functions of G2Tools/ug2sim.pas (repository StephenBorgatti/tools
# at commit 207958a).
#
# Dialog defaults (Xse.pas constants): measure Euclidean distance (meas = 1),
# include transpose YES, diagonal Reciprocal1 (diag = 4, the design answer to
# 12.1 as well), use geodesics NO. Every relation of the dataset is stacked
# into one profile, as sesim2 loops over d.nm; the book (12.3) does exactly
# this with Sampson's esteem and disesteem.
#
# The measures are ug2sim's, not utsimilarity's, and the two units differ at
# the edges, so this file does not simply call xsimilarities():
#   euclid       sqrt(ssd) * n / num, rescaled when cells are missing
#   correlation  0 when one profile is constant, 1 when both are (utsimilarity
#                and xsimilarities() give missing)
#   overlaps, coverage   exist only here
# Where the definitions coincide (matches, positive matches = Jaccard, sum of
# cross-products) the shared sim_pair() is used, so those cannot drift apart.
#
# Clustering: JohnsonHiclus(d, p, meas > 1, wtdaveragelink). UCINET's
# "weighted average" is (x*s1 + y*s2)/(s1 + s2), the size-weighted mean, which
# is UPGMA: xhclust(method = "average"). The chapter 12 prompt asked for WPGMA
# (hclust's "mcquitty"); that would not be UCINET's clustering, so it was not
# added (issue #23). Coverage is asymmetric and is not clustered, as in UCINET.

se_measures <- list(
  euclidean       = list(label = "Euclidean Distance",           kind = "dissimilarities"),
  correlation     = list(label = "Pearson Correlation",          kind = "similarities"),
  matches         = list(label = "Percent of Exact Matches",     kind = "similarities"),
  positivematches = list(label = "Percent of Positive Matches",  kind = "similarities"),
  overlaps        = list(label = "Number of Overlaps",           kind = "similarities"),
  crossproducts   = list(label = "Sum of Cross-Products",        kind = "similarities"),
  coverage        = list(label = "Coverage",                     kind = NA_character_))

se_diagonal <- c(ignore = "Ignore",
                 retain = "Retain1 (single count)",
                 retain2 = "Retain2 (double count)",
                 reciprocal = "Reciprocal1 (single count)",
                 reciprocal2 = "Reciprocal2 (double count)")

#' Structural equivalence (profile similarity)
#'
#' UCINET: Network | Roles & Positions | Structural Equivalence | Profile.
#' Compares every pair of nodes on their profiles, the ties they send and
#' receive, and clusters the result. Two nodes are structurally equivalent
#' when their profiles are the same.
#'
#' A node's profile is its row of the adjacency matrix, followed by its column
#' when `transpose = TRUE` (UCINET's default), for every relation of the
#' dataset in turn. How the cells that refer to the pair itself are handled is
#' `diagonal`:
#'
#' \describe{
#'   \item{`"reciprocal"`}{(the default) *reciprocal swapping*: i's tie to j is
#'     compared with j's tie to i, and i's self-loop with j's (UCINET's
#'     Reciprocal1, single count).}
#'   \item{`"reciprocal2"`}{the same, with the swapped cells counted again in
#'     the column half of the profile (Reciprocal2, double count).}
#'   \item{`"ignore"`}{the cells for i and j are left out.}
#'   \item{`"retain"`, `"retain2"`}{the cells are compared as they stand,
#'     once or twice (Retain1, Retain2).}
#' }
#'
#' Without the transpose the single and double counts are the same, as in
#' UCINET.
#'
#' The similarity matrix is clustered by Johnson's method with weighted-average
#' linkage, as UCINET does: its "weighted average" weights by cluster size,
#' which is [xhclust()]'s `"average"`. For other linkages pass
#' `$matrices[[1]]` to [xhclust()] yourself. Coverage is asymmetric and is not
#' clustered.
#'
#' @section UCINET equivalent:
#' Network | Roles & Positions | Structural Equivalence | Profile. *Measure* is
#' `method`, *Include transpose* is `transpose`, *Diagonal* is `diagonal`,
#' *Use geodesics* is `geodesics`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param method `"euclidean"` (UCINET's default), `"correlation"`,
#'   `"matches"`, `"positivematches"`, `"overlaps"`, `"crossproducts"` or
#'   `"coverage"`.
#' @param relations Which relations make up the profile, by name or position.
#'   `NULL`, the default, uses all of them, as UCINET does.
#' @param diagonal How the cells for the pair itself are treated; see Details.
#' @param transpose Add each node's column to its row? `TRUE` by default.
#' @param geodesics Compare rows of the geodesic distance matrix instead of the
#'   adjacency matrix? Unreachable pairs are set to `n`, as UCINET does.
#' @param k Optional number of clusters: fills the `Cluster` column.
#' @return An object of class `c("xstructuralequivalence", "xucinet_output")`.
#'   `$matrices` holds the structural equivalence matrix; `$nodes` holds the
#'   partition at each level of the clustering and `Cluster`; `$hclust` the
#'   tree.
#' @seealso [xhclust()], [xsimilarities()], [xblockmodel()].
#' @examples
#' xstructuralequivalence(sampson, relations = c("Esteem", "Disesteem"))
#' @export
xstructuralequivalence <- function(net, method = c("euclidean", "correlation",
                                                  "matches", "positivematches",
                                                  "overlaps", "crossproducts",
                                                  "coverage"),
                                   relations = NULL,
                                   diagonal = c("reciprocal", "reciprocal2",
                                                "ignore", "retain", "retain2"),
                                   transpose = TRUE, geodesics = FALSE,
                                   k = NULL) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  diagonal <- match.arg(diagonal)
  require_1mode(net, "xstructuralequivalence()")

  mats <- relation_list(net)
  if (!is.null(relations)) {
    idx <- if (is.character(relations)) match(relations, names(mats)) else
      as.integer(relations)
    if (anyNA(idx) || any(idx < 1 | idx > length(mats))) {
      stop("xstructuralequivalence(): relations must name relations of the ",
           "dataset.\n  Available: ", paste(names(mats), collapse = ", "),
           call. = FALSE)
    }
    mats <- mats[idx]
  }
  if (isTRUE(geodesics)) mats <- lapply(mats, se_floyd)
  labels <- rownames(mats[[1]])
  n <- length(labels)

  # Without the transpose, the double counts reduce to the single ones
  # (askparameters: diag 2,3 -> 6 and 4,5 -> 7).
  build <- diagonal
  if (!isTRUE(transpose)) build <- sub("2$", "", build)

  sym <- method != "coverage"
  r <- matrix(NA_real_, n, n, dimnames = list(labels, labels))
  for (i in seq_len(n)) {
    for (j in if (sym) seq_len(i) else seq_len(n)) {
      p <- se_profiles(mats, i, j, build, transpose)
      r[i, j] <- se_pair(p$x, p$y, method)
      if (sym) r[j, i] <- r[i, j]
    }
  }

  assumptions <- character()
  if (length(mats) > 1) {
    assumptions <- sprintf("Profiles stack %d relations: %s.", length(mats),
                           paste(names(mats), collapse = ", "))
  }

  nodes <- NULL
  hc <- NULL
  summary <- NULL
  preamble <- NULL
  kind <- se_measures[[method]]$kind
  if (!is.na(kind)) {
    cl <- xhclust(r, type = kind, method = "average", k = k, plot = FALSE)
    nodes <- cl$nodes
    hc <- cl$hclust
    summary <- cl$summary
    preamble <- cl$preamble
  } else if (!is.null(k)) {
    assumptions <- c(assumptions, "Coverage is asymmetric and is not clustered; k is ignored.")
  }

  out <- new_xucinet_output(
    "Profile Structural Equivalence", net,
    nodes = nodes, summary = summary,
    matrices = list(`Structural Equivalence Matrix` = r),
    assumptions = assumptions,
    fields = c("Measure:" = se_measures[[method]]$label,
               "Include transpose" = if (isTRUE(transpose)) "YES" else "NO",
               "Diagonal:" = se_diagonal[[diagonal]],
               "Use geodesics?" = if (isTRUE(geodesics)) "YES" else "NO"),
    # UCINET prints the matrix, then the dendrogram, and saves the partition
    # indicator matrix without printing it.
    epilogue = preamble,
    print_nodes = FALSE,
    show_summary = if (!is.null(summary)) {
      c("Cophenetic", "Levels", if (!is.null(k)) "Clusters requested")
    },
    nodes_title = "Partition indicator matrix",
    subclass = "xstructuralequivalence", call = match.call())
  out$hclust <- hc
  out
}

# The two profiles sesim2 compares for nodes i and j: one pass per relation,
# the row half and then, with the transpose, the column half. `build` is the
# sesim2 procedure: ignore (buildignore), retain / retain2 (buildcountsingle /
# buildcountdouble), reciprocal / reciprocal2 (buildreciprocalsingle /
# buildreciprocaldouble).
se_profiles <- function(mats, i, j, build, transpose) {
  x <- numeric(0); y <- numeric(0)
  for (d in mats) {
    n <- nrow(d)
    ks <- seq_len(n)
    others <- ks[ks != i & ks != j]
    if (build == "ignore") {
      x <- c(x, d[i, others]); y <- c(y, d[j, others])
      if (transpose) { x <- c(x, d[others, i]); y <- c(y, d[others, j]) }
      next
    }
    swap <- build %in% c("reciprocal", "reciprocal2")
    rx <- d[i, ]; ry <- d[j, ]
    if (swap) {
      # k = i: the two self-loops; k = j: i's tie to j against j's tie to i.
      # Assigned in this order so that i = j gives d[i, i] against d[i, i].
      rx[j] <- d[i, j]; ry[j] <- d[j, i]
      rx[i] <- d[i, i]; ry[i] <- d[j, j]
    }
    x <- c(x, rx); y <- c(y, ry)
    if (!transpose) next
    if (build %in% c("retain", "reciprocal")) {
      x <- c(x, d[others, i]); y <- c(y, d[others, j])
    } else if (build == "retain2") {
      x <- c(x, d[, i]); y <- c(y, d[, j])
    } else {
      cx <- d[, i]; cy <- d[, j]
      cx[j] <- d[j, i]; cy[j] <- d[i, j]
      cx[i] <- d[i, i]; cy[i] <- d[j, j]
      x <- c(x, cx); y <- c(y, cy)
    }
  }
  list(x = unname(x), y = unname(y))
}

# One measure on one pair, as ug2sim computes it. Missing cells are skipped.
se_pair <- function(x, y, method) {
  total <- length(x)
  ok <- !is.na(x) & !is.na(y)
  num <- sum(ok)
  if (num == 0) return(NA_real_)
  x <- x[ok]; y <- y[ok]
  switch(method,
    euclidean = total * sqrt(sum((x - y)^2)) / num,
    correlation = {
      sx <- sum((x - mean(x))^2); sy <- sum((y - mean(y))^2)
      tiny <- 1e-7                     # singleprecision (ucommon.pas)
      if (xor(sx < tiny, sy < tiny)) 0
      else if (sx < tiny && sy < tiny) 1
      else sum((x - mean(x)) * (y - mean(y))) / sqrt(sx * sy)
    },
    matches = sim_pair(x, y, "matches"),
    positivematches = sim_pair(x, y, "jaccard"),
    overlaps = sum(x > 0 & y > 0) / num,
    crossproducts = sim_pair(x, y, "crossproducts"),
    # x covers y to the extent that y's ties are x's too
    coverage = if (any(y > 0)) sum(x > 0 & y > 0) / sum(y > 0) else NA_real_)
}

# runfloyd in sesim2: geodesic distances on the values, the diagonal 0 and
# unreachable pairs n.
se_floyd <- function(d) {
  n <- nrow(d)
  d[is.na(d)] <- 0
  diag(d) <- 0
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      if (d[j, i] > 0) {
        for (k in seq_len(n)) {
          if (d[i, k] > 0) {
            s <- d[j, i] + d[i, k]
            if (d[j, k] == 0 || s < d[j, k]) d[j, k] <- s
          }
        }
      }
    }
  }
  off <- row(d) != col(d)
  d[off & d == 0] <- n
  diag(d) <- 0
  d
}
