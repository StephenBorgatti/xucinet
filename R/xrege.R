# REGE: regular equivalence.
#
# UCINET: Network | Roles & Positions | Maximal Regular Equivalence | REGE
# (Xrege.pas, rege; repository StephenBorgatti/ucinet at commit c7b4956), with
# the algorithm in G1Tools/Urege.pas (sStdrege; repository
# StephenBorgatti/tools at commit 207958a). White and Reitz's algorithm.
#
# Dialog defaults: 3 iterations, convert to geodesics No. The routine is 1-mode
# only (it refuses a non-square matrix), so there is no 2-mode REGE; it refuses
# negative values; every relation of the dataset is used. In the current build
# it raises "not available in the 64-bit version", so its golden has to come
# from the 32-bit UCINET.
#
# sStdrege, for relations x_r:
#   sum[i, k] = sum_r x_r[i, k] + x_r[k, i]            (i != k)
#   deg[i]    = sum_k sum[i, k]
#   start: e = 1, except 0 where exactly one of the pair has deg > 0
#   each iteration, for every pair i < j with both degrees positive,
#     e[i, j] = (CM(i, j) + CM(j, i)) / (deg[i] + deg[j]), where CM(i, j) sums,
#     over i's neighbours k, the best match among j's neighbours m of
#     e_old[k, m] * sum_r min(x[j, m], x[i, k]) + min(x[m, j], x[k, i]).
# CM reads only the lower triangle, which is refreshed after the pass, so the
# update is simultaneous (Jacobi), not in place. The early exit in XMax cannot
# change the maximum, since a match never exceeds sum[i, k].
#
# UCINET displays the similarities times 100 with no decimals and saves them
# on 0-1; $matrices holds the saved form. The clustering is runclusternew with
# averagelink, which is wtdaveragelink, UPGMA: xhclust(method = "average").

#' Regular equivalence (REGE)
#'
#' UCINET: Network | Roles & Positions | Maximal Regular Equivalence | REGE.
#' White and Reitz's algorithm: two nodes are regularly equivalent when they
#' are tied to equivalent others, not necessarily the same others. The
#' similarities start at 1 and are refined for `iterations` rounds; each round
#' matches every tie of one node with the best-matching tie of the other,
#' weighting the match by how equivalent the two alters were in the round
#' before.
#'
#' The similarity matrix is clustered as UCINET does, with its weighted-average
#' linkage ([xhclust()]'s `"average"`). The book (12.7) clusters it by single
#' link instead: pass `$matrices[[1]]` to [xhclust()].
#'
#' UCINET's REGE takes square data only, so there is no 2-mode REGE.
#'
#' @section UCINET equivalent:
#' Network | Roles & Positions | Maximal Regular Equivalence | REGE. *Max # of
#' iterations* is `iterations`, *Convert to geodesics* is `geodesics`.
#'
#' @param net A network (any accepted form). 1-mode; no negative values.
#' @param iterations Number of rounds. UCINET's default is 3.
#' @param relations Which relations to use, by name or position. `NULL`, the
#'   default, uses all of them, as UCINET does.
#' @param geodesics Replace each relation by its geodesic distances first
#'   (dichotomized, unreachable pairs at `n`)?
#' @param k Optional number of clusters: fills the `Cluster` column.
#' @return An object of class `c("xrege", "xucinet_output")`. `$matrices`
#'   holds the REGE similarities on 0-1 (UCINET prints them times 100);
#'   `$nodes` the partitions of the clustering and `Cluster`; `$hclust` the
#'   tree.
#' @seealso [xstructuralequivalence()], [xhclust()].
#' @examples
#' xrege(campnet)
#' @export
xrege <- function(net, iterations = 3, relations = NULL, geodesics = FALSE,
                  k = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xrege()")
  mats <- relation_list(net)
  if (!is.null(relations)) {
    idx <- if (is.character(relations)) match(relations, names(mats)) else
      as.integer(relations)
    if (anyNA(idx) || any(idx < 1 | idx > length(mats))) {
      stop("xrege(): relations must name relations of the dataset.\n",
           "  Available: ", paste(names(mats), collapse = ", "), call. = FALSE)
    }
    mats <- mats[idx]
  }
  assumptions <- character()
  if (any(vapply(mats, anyNA, logical(1)))) {
    assumptions <- c(assumptions, "Missing values are treated as 0.")
    mats <- lapply(mats, function(m) { m[is.na(m)] <- 0; m })
  }
  if (any(vapply(mats, function(m) any(m[row(m) != col(m)] < 0), logical(1)))) {
    stop("xrege(): this routine assumes the data contain no negative values.",
         call. = FALSE)
  }
  if (isTRUE(geodesics)) {
    mats <- lapply(mats, function(m) se_floyd((m > 0) * 1))
  }
  if (length(mats) > 1) {
    assumptions <- c(assumptions, sprintf("Relations used: %s.",
                                          paste(names(mats), collapse = ", ")))
  }
  iterations <- as.integer(iterations)
  labels <- rownames(mats[[1]])

  e <- rege_iterate(mats, iterations)
  dimnames(e) <- list(labels, labels)

  cl <- xhclust(e, type = "similarities", method = "average", k = k,
                plot = FALSE)
  title <- sprintf("REGE similarities (%d iterations)", iterations)
  shown <- c(title, "", format_uci_matrix(round(e * 100), 0, by_column = FALSE),
             "")

  out <- new_xucinet_output(
    "Regular Equivalence via White/Reitz Rege Algorithm", net,
    nodes = cl$nodes, summary = cl$summary,
    matrices = stats::setNames(list(e), title),
    assumptions = assumptions,
    fields = c("Iterations:" = format(iterations),
               "Convert to geodesics:" = if (isTRUE(geodesics)) "YES" else "NO"),
    preamble = c(shown, cl$preamble),
    hide = title,
    print_nodes = FALSE,
    show_summary = c("Cophenetic", "Levels", if (!is.null(k)) "Clusters requested"),
    nodes_title = "Partition indicator matrix",
    subclass = "xrege", call = match.call())
  out$hclust <- cl$hclust
  out
}

# sStdrege's arithmetic; see the file header.
rege_iterate <- function(mats, iterations) {
  n <- nrow(mats[[1]])
  off <- row(mats[[1]]) != col(mats[[1]])
  sum_ <- Reduce(`+`, lapply(mats, function(x) (x + t(x)) * off))
  deg <- rowSums(sum_)
  e <- matrix(1, n, n)
  pos <- deg > 0
  e[outer(pos, pos, xor)] <- 0
  diag(e) <- 1

  # best[i, j]: sum over i's neighbours k of the best match among j's
  # neighbours m. For a fixed (i, j) the match matrix over (k, m) is
  # e_old[k, m] * sum_r (pmin(x[i, k], x[j, m]) + pmin(x[k, i], x[m, j])).
  cm <- function(i, j, eold) {
    ks <- which(sum_[i, ] > 0)
    ms <- which(sum_[j, ] > 0)
    if (!length(ks) || !length(ms)) return(0)
    tot <- matrix(0, length(ks), length(ms))
    for (x in mats) {
      tot <- tot + outer(x[i, ks], x[j, ms], pmin) + outer(x[ks, i], x[ms, j], pmin)
    }
    sum(apply(eold[ks, ms, drop = FALSE] * tot, 1, max))
  }
  for (it in seq_len(iterations)) {
    eold <- e
    for (i in seq_len(n - 1)) {
      if (deg[i] <= 0) next
      for (j in (i + 1):n) {
        if (deg[j] <= 0) next
        v <- (cm(i, j, eold) + cm(j, i, eold)) / (deg[i] + deg[j])
        e[i, j] <- v
        e[j, i] <- v
      }
    }
  }
  e
}
