# Ported from borgworld::bhiclus(), bcophenetic() and create_partition_table()
# (R/b_hiclus.R, commit 2eb26f4, 25 October 2025) and bmoca() (R/b_moca.R,
# commit ad1e0ca, 7 October 2025). Numbers are borgworld's where the two agree;
# the report is UCINET's (XCluster.pas, Tools/G1Tools/Udendro.pas and
# Tools/G1Tools/umoca.pas, ucinet and tools repositories, 18 September 2026).
# The vendored borgworld sources are in inst/reference/borgworld/.
#
# Departures from borgworld, each decided by Steve on 18 September 2026 and
# recorded in dev/design/ch06-questions.md:
#   - one partition per DISTINCT merge level, as UCINET's Johnson2 records them,
#     rather than one per merge step (question 4c);
#   - the text cluster diagram is UCINET's, not print_ascii_dendrogram (4c);
#   - Gamma is not reported (question 8); modularity follows UCINET's formula
#     in umoca.pas rather than borgworld's pairwise loop, which leaves the
#     diagonal out of the null model;
#   - k = adds a Cluster column and one summary line (question 12).

#' Johnson's hierarchical clustering
#'
#' UCINET: Tools | Cluster Analysis | Johnson's Hierarchical. Agglomerative
#' clustering of a proximity matrix by single, complete or average linkage
#' (Johnson, 1967), reported as UCINET reports it: a text cluster diagram, the
#' partition at each merge level, measures of cluster adequacy and cluster
#' sizes. Book section 6.4.
#'
#' `type` has no default. A matrix of 0/1 ties, a matrix of geodesic distances
#' and a matrix of co-membership counts all have the same shape, and only the
#' caller knows whether large values mean close or far. Pass `type =
#' "similarities"` when larger values mean closer (correlations, tie strengths,
#' co-memberships) and `type = "dissimilarities"` when larger values mean
#' further apart (distances, geodesics). Similarities are converted to
#' dissimilarities as `max - x`, where the maximum is taken over the
#' off-diagonal cells.
#'
#' UCINET records a new partition only when the merge distance changes, so
#' tied merges collapse into one level; the partition table here does the
#' same, which is why it can have fewer columns than `n - 1`. Where merge
#' distances tie, UCINET merges the first tied pair in original index order and
#' `hclust()` uses its own rule, so the two can produce different (equally
#' correct) merge orders at the same levels; see the differences vignette.
#'
#' On linkage names: UCINET's `WTD_AVERAGE` is the size-weighted average
#' `(x * s1 + y * s2) / (s1 + s2)`, which is UPGMA and `hclust(method =
#' "average")`. Its `SIMPLE_AVERAGE` is `(x + y) / 2`, which R calls
#' `"mcquitty"` and is not offered here. The adjectives run the opposite way
#' from R's, which is why this note exists.
#'
#' @param x A square proximity matrix: a matrix, `dist` object, data frame,
#'   `xucinet` object or file name. An asymmetric matrix is symmetrized by
#'   averaging, as UCINET does, and the report says so.
#' @param type `"similarities"` or `"dissimilarities"` (or `"s"` / `"d"`).
#'   Required; see Details.
#' @param method Linkage: `"average"` (UCINET's default, `WTD_AVERAGE`),
#'   `"single"` or `"complete"`.
#' @param k Optional number of clusters. Adds a `Cluster` column to `$nodes`
#'   holding `cutree(hc, k)`; the level table itself is unchanged.
#' @param plot Draw the dendrogram with base graphics. The text cluster diagram
#'   is printed regardless.
#' @return An `xucinet_output` of subclass `xhclust`. `$nodes` is the
#'   partition indicator matrix as a data frame, one column per distinct merge
#'   level, named as UCINET names them (`1(8)206` is level 1, eight clusters,
#'   merge distance 206), plus `Cluster` when `k` is given. `$summary` holds
#'   the cophenetic correlation and the number of levels. `$matrices` holds
#'   `Measures of cluster adequacy` (`Corr`, `Modularity`, `Silhouette` by
#'   level) and `Cluster sizes` (proportion of items in each cluster, by
#'   level). `$hclust` is the underlying `stats::hclust` object, so `cutree()`
#'   and `as.dendrogram()` work on it directly. `$levels` is the numeric vector
#'   of merge distances.
#'
#'   `Corr` is the correlation between the proximities and a same-cluster
#'   indicator, signed so that higher is better for both input types; for
#'   dissimilarity input UCINET prints it with the opposite sign. `Modularity`
#'   is Newman's Q of the partition on the similarity matrix (for dissimilarity
#'   input, on `1 / (1 + d)`). `Silhouette` is the average silhouette width on
#'   the dissimilarities.
#' @references Johnson, S. C. (1967). Hierarchical clustering schemes.
#'   *Psychometrika*, 32, 241-254.
#' @seealso [xmds()], [xcorrespondence()]
#' @examples
#' xhclust(cities, type = "dissimilarities", method = "single", plot = FALSE)
#'
#' res <- xhclust(cities, type = "d", k = 3, plot = FALSE)
#' res$nodes$Cluster
#' @export
xhclust <- function(x, type, method = c("average", "single", "complete"),
                    k = NULL, plot = TRUE) {
  px <- xprox(x, substitute(x), "xhclust()")
  type <- match_type(type, "xhclust")
  method <- match.arg(tolower(method), c("average", "single", "complete"))
  m <- check_proximities(px$m, "xhclust")
  n <- nrow(m)
  if (n < 2L) stop("xhclust() needs at least two items.", call. = FALSE)
  assumptions <- px$assumptions

  sym <- symmetrize_average(m)
  assumptions <- c(assumptions, sym$notes)
  conv <- to_dissimilarity(sym$m, type, "xhclust")
  assumptions <- c(assumptions, conv$notes)
  d <- conv$d
  labels <- rownames(m)

  hc <- stats::hclust(stats::as.dist(d), method = method)

  # ---- partitions, one per distinct level (Johnson2 in Uclus.pas) ----------
  lv <- collapse_levels(hc, n)
  part <- lv$part                       # n x npart, renumbered 1..k
  ids <- lv$ids                         # n x npart, largest-index ids for the diagram
  levels <- lv$levels
  npart <- length(levels)
  nclus <- apply(part, 2, function(v) length(unique(v)))
  dd <- hclust_decimals(levels)
  level_lab <- formatC(levels, format = "f", digits = dd)
  # handlesavepart: column j is "<j>(<clusters>)<level>".
  colnames(part) <- paste0(seq_len(npart), "(", nclus, ")", level_lab)
  rownames(part) <- labels

  # ---- cophenetic correlation (bcophenetic on the dissimilarities) ---------
  coph <- stats::cophenetic(hc)
  coph_corr <- suppressWarnings(stats::cor(d[lower.tri(d)], as.matrix(coph)[lower.tri(d)]))

  # ---- measures of cluster adequacy and cluster sizes ----------------------
  sim <- if (type == "similarities") sym$m else 1 / (1 + d)
  diag(sim) <- 0
  moca <- moca_table(d, sim, part)
  colnames(moca) <- paste0(seq_len(npart), " (", nclus, ")")
  sizes <- cluster_sizes(part, nclus)
  colnames(sizes) <- colnames(moca)

  nodes <- as.data.frame(part, check.names = FALSE, stringsAsFactors = FALSE)
  summary <- list("Cophenetic" = coph_corr, "Levels" = npart)
  if (!is.null(k)) {
    k <- as.integer(k)
    if (is.na(k) || k < 1L || k > n) {
      stop("k must be between 1 and ", n, " (the number of items).", call. = FALSE)
    }
    nodes$Cluster <- unname(stats::cutree(hc, k = k))
    summary[["Clusters requested"]] <- k
    if (!k %in% nclus) {
      assumptions <- c(assumptions, sprintf(
        "No merge level has exactly %d clusters (tied merges); Cluster cuts the tree between levels.", k))
    }
  }

  method_label <- c(average = "WTD_AVERAGE (average between all pairs)",
                    single = "SINGLE_LINK (minimum)",
                    complete = "COMPLETE_LINK (maximum)")[[method]]
  diagram <- format_uci_dendrogram(part, level_lab, ids, labels)

  if (isTRUE(plot)) {
    old <- graphics::par(mar = c(5, 4, 4, 2) + 0.1)
    on.exit(graphics::par(old), add = TRUE)
    graphics::plot(hc, labels = labels, hang = -1,
                   main = "Hierarchical Clustering Dendrogram",
                   xlab = "", sub = "", ylab = "Level")
  }

  out <- new_xucinet_output(
    "Johnson's hierarchical clustering", px$net,
    nodes = nodes, summary = summary,
    matrices = list("Measures of cluster adequacy" = moca,
                    "Cluster sizes (proportion of items)" = sizes),
    assumptions = assumptions,
    fields = c("Method:" = method_label, "Type of Data:" = type_label(type)),
    preamble = diagram,
    nodes_title = "Partition indicator matrix",
    stats_block = FALSE,
    subclass = "xhclust", call = match.call())
  out$hclust <- hc
  out$levels <- levels
  out$type <- type
  out$method <- method
  if (isTRUE(plot)) invisible(out) else out
}

# Walk hclust's merges and record a partition whenever the merge distance
# changes, as Johnson2 does (`if dist <> lastd then inc(npart)`). Two id
# schemes come back: `part` renumbered 1..k in order of first appearance (what
# UCINET saves and prints), and `ids` where each cluster is labelled by its
# largest original index, which is what Johnson2's own `part` vector holds when
# GetBestPerm sorts the items for the diagram. Sorting on the renumbered ids
# would give a different item order from UCINET's.
collapse_levels <- function(hc, n) {
  memb <- seq_len(n)                    # cluster id = largest member index
  parts <- list(); ids <- list(); levels <- numeric()
  h <- hc$height
  for (step in seq_len(n - 1L)) {
    a <- hc$merge[step, 1]; b <- hc$merge[step, 2]
    members <- c(if (a < 0) -a else which(memb == memb[hc_first_member(hc, a)]),
                 if (b < 0) -b else which(memb == memb[hc_first_member(hc, b)]))
    memb[members] <- max(members)
    last_of_level <- step == n - 1L ||
      abs(h[step + 1L] - h[step]) > 1e-9 * max(1, abs(h[step]))
    if (last_of_level) {
      ids[[length(ids) + 1L]] <- memb
      parts[[length(parts) + 1L]] <- renumber(memb)
      levels <- c(levels, h[step])
    }
  }
  list(part = do.call(cbind, parts), ids = do.call(cbind, ids), levels = levels)
}

# One original item belonging to cluster `cl` of an hclust merge tree.
hc_first_member <- function(hc, cl) {
  a <- hc$merge[cl, 1]
  if (a < 0) -a else hc_first_member(hc, a)
}

# UCINET's renumber(): cluster ids 1..k in order of first appearance.
renumber <- function(v) {
  match(v, unique(v))
}

# getdd() in XCluster.pas: decimals for the level labels from the smallest
# level, none when every level is a whole number.
hclust_decimals <- function(levels) {
  if (all(abs(levels - round(levels)) < 1e-6)) return(0L)
  mn <- min(levels)
  if (mn < 1) 4L else if (mn < 10) 3L else if (mn < 100) 2L else if (mn < 1000) 1L else 0L
}

# Measures of cluster adequacy, measures by level as UCINET lays them out.
#   Corr        cor(proximity, same-cluster) over unordered pairs, signed so
#               that higher is better (bmoca negates for dissimilarities).
#   Modularity  Newman's Q on the similarity matrix, calcmoca() in umoca.pas:
#               Q = sum over clusters of (w_b / o - ((r_b + w_b) / o)^2).
#   Silhouette  mean silhouette width on the dissimilarities; singletons score 0.
# Corr and Modularity are undefined for one cluster; Silhouette also for n.
moca_table <- function(d, sim, part) {
  n <- nrow(d); npart <- ncol(part)
  lower <- lower.tri(d)
  d_lower <- d[lower]
  out <- matrix(NA_real_, 3L, npart,
                dimnames = list(c("Corr", "Modularity", "Silhouette"), NULL))
  o <- sum(sim)
  deg <- rowSums(sim)
  for (p in seq_len(npart)) {
    v <- part[, p]
    nb <- length(unique(v))
    same <- outer(v, v, "==")
    if (nb > 1L) {
      out["Corr", p] <- -suppressWarnings(stats::cor(d_lower, as.numeric(same[lower])))
      if (o > 0) {
        q <- 0
        for (b in unique(v)) {
          inb <- v == b
          w <- sum(sim[inb, inb])
          kb <- sum(deg[inb])
          q <- q + w / o - (kb / o)^2
        }
        out["Modularity", p] <- q
      }
    }
    if (nb > 1L && nb < n) {
      out["Silhouette", p] <- mean(silhouette_widths(d, v))
    }
  }
  out
}

silhouette_widths <- function(d, v) {
  n <- nrow(d)
  s <- numeric(n)
  for (i in seq_len(n)) {
    own <- which(v == v[i] & seq_len(n) != i)
    if (!length(own)) { s[i] <- 0; next }
    a <- mean(d[i, own])
    others <- setdiff(unique(v), v[i])
    b <- min(vapply(others, function(cl) mean(d[i, v == cl]), numeric(1)))
    s[i] <- if (max(a, b) > 0) (b - a) / max(a, b) else 0
  }
  s
}

# handlesizes() in XCluster.pas: rows CL1.., columns levels, cells the share of
# items in that cluster, NA where the level has fewer clusters.
cluster_sizes <- function(part, nclus) {
  n <- nrow(part)
  out <- matrix(NA_real_, max(nclus), ncol(part),
                dimnames = list(paste0("CL", seq_len(max(nclus))), NULL))
  for (p in seq_len(ncol(part))) {
    tab <- tabulate(part[, p], nbins = nclus[p])
    out[seq_len(nclus[p]), p] <- tab / n
  }
  out
}
