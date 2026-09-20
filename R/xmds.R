# Ported from borgworld::bclassicalmds() (R/b_classicalmds.R, commit d9ca8bc,
# 14 October 2025) and borgworld::bnonmetricmds() (R/b_nonmetricmds.R, commit
# d95ccf2, 8 October 2025). borgworld::bmds(), the dispatcher, is replaced by
# match.arg(). The vendored sources are in inst/reference/borgworld/.
#
# Departures from borgworld, decided by Steve on 18 September 2026
# (dev/design/ch06-questions.md):
#   - similarities are converted with the OFF-DIAGONAL maximum, as bhiclus does
#     and the two MDS functions do not (question 9); for similarity input the
#     coordinates therefore differ from bclassicalmds/bnonmetricmds by the
#     constant this adds to every dissimilarity;
#   - the whole coordinate table is printed, never head() (SPEC D5);
#   - the one-word stress verdict is not printed (question 4b);
#   - the map is drawn with asp = 1 (question 5);
#   - plot = TRUE draws the configuration only; xshepard() draws the Shepard
#     diagram from the stored result (question 10).

#' Multidimensional scaling
#'
#' UCINET: Tools | Scaling/Decomposition | Non-metric MDS (and Classic MDS).
#' Places the objects of a proximity matrix in `dim` dimensions so that the
#' distances between points reproduce the proximities: exactly as possible,
#' by classical (Torgerson) scaling, or in rank order, by Kruskal's non-metric
#' scaling. Book section 6.2.
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
#' `method = "classical"` is `stats::cmdscale()` on the dissimilarities.
#' `method = "nonmetric"` is `MASS::isoMDS()`, Kruskal's algorithm with
#' monotone regression, started from the classical solution and stopped after
#' 100 iterations or when stress improves by less than 0.001. Because the
#' start is the classical solution there is no randomness, and the result is
#' reproducible without a seed.
#'
#' Stress is Kruskal's stress formula 1, `sqrt(sum((d - dhat)^2) / sum(d^2))`,
#' on a 0-1 scale. For the classical solution `dhat` is the raw dissimilarity;
#' for the non-metric solution it is the monotone-regression disparity. UCINET
#' reports its metric stress with the configuration distances in the
#' denominator, so the two agree only at perfect fit (differences vignette).
#' `GOF1` and `GOF2` for the classical solution are the shares of the summed
#' absolute eigenvalues and of the summed squared positive eigenvalues carried
#' by the first `dim` dimensions.
#'
#' An MDS configuration is determined only up to rotation, reflection and
#' translation. A map that looks rotated or mirror-imaged against UCINET's, or
#' against a map drawn from a different start, is the same map.
#'
#' UCINET's *Metric MDS* (iterative stress minimization on the raw
#' proximities) has no counterpart here; see the differences vignette for why.
#'
#' @param x A square proximity matrix: a matrix, `dist` object, data frame,
#'   `xucinet` object or file name. An asymmetric matrix is symmetrized by
#'   averaging and the report says so.
#' @param type `"similarities"` or `"dissimilarities"` (or `"s"` / `"d"`).
#'   Required; see Details.
#' @param method `"classical"` or `"nonmetric"`.
#' @param dim Number of dimensions, at least 1 and less than the number of
#'   objects.
#' @param plot Draw the map of the first two dimensions with base graphics.
#'   With `dim = 1` a one-dimensional strip is drawn.
#' @param labels Optional character vector of point labels; defaults to the
#'   row names of `x`.
#' @return An `xucinet_output` of subclass `xmds`. `$nodes` holds the
#'   coordinates (`Dim1 ... Dimk`, original object order). `$summary` holds
#'   `Stress` and, for the classical solution, `GOF1` and `GOF2`. For the
#'   classical solution `$matrices$Eigenvalues` holds each positive eigenvalue
#'   and its proportion of the positive total, and `$eig` the full eigenvalue
#'   vector. For the non-metric solution `$shepard` is a data frame with one
#'   row per pair (`Dissimilarity`, `Distance`, `Disparity`), which
#'   [xshepard()] draws. `$dissimilarities` is the matrix that was scaled,
#'   after conversion.
#' @references Kruskal, J. B. (1964). Multidimensional scaling by optimizing
#'   goodness of fit to a nonmetric hypothesis. *Psychometrika*, 29, 1-27.
#'   Torgerson, W. S. (1952). Multidimensional scaling: I. Theory and method.
#'   *Psychometrika*, 17, 401-419.
#' @seealso [xshepard()], [xcorrespondence()], [xhclust()]
#' @examples
#' xmds(cities, type = "dissimilarities", plot = FALSE)
#' xmds(cities, type = "d", method = "nonmetric", plot = FALSE)
#' @export
xmds <- function(x, type, method = c("classical", "nonmetric"), dim = 2,
                 plot = TRUE, labels = NULL) {
  px <- xprox(x, substitute(x), "xmds()")
  type <- match_type(type, "xmds")
  method <- match.arg(tolower(method), c("classical", "nonmetric"))
  m <- check_proximities(px$m, "xmds")
  n <- nrow(m)
  assumptions <- px$assumptions
  dim <- as.integer(dim)
  if (is.na(dim) || dim < 1L) stop("dim must be at least 1.", call. = FALSE)
  if (dim >= n) {
    stop("dim must be less than the number of objects; this matrix has ", n,
         " objects, so dim can be at most ", n - 1L, ".", call. = FALSE)
  }
  if (is.null(labels)) {
    labels <- rownames(m)
  } else if (length(labels) != n) {
    stop("labels must have one entry per object (", n, "); got ", length(labels), ".",
         call. = FALSE)
  }

  sym <- symmetrize_average(m)
  assumptions <- c(assumptions, sym$notes)
  conv <- to_dissimilarity(sym$m, type, "xmds")
  assumptions <- c(assumptions, conv$notes)
  d <- conv$d
  dimnames(d) <- list(labels, labels)
  dn <- paste0("Dim", seq_len(dim))

  summary <- list(); matrices <- list(); extra <- list()

  if (method == "classical") {
    # bclassicalmds: cmdscale, then GOF1/GOF2 and stress formula 1 with the
    # raw dissimilarities as disparities, summed over all n^2 cells.
    fit <- stats::cmdscale(d, k = dim, eig = TRUE, add = FALSE)
    coords <- fit$points
    eig <- fit$eig
    pos <- eig[eig > 0]
    if (length(pos) >= dim) {
      gof1 <- sum(abs(eig[seq_len(dim)])) / sum(abs(eig))
      gof2 <- sum(pos[seq_len(dim)]^2) / sum(pos^2)
    } else {
      gof1 <- NA_real_; gof2 <- NA_real_
      assumptions <- c(assumptions, sprintf(
        "Only %d positive eigenvalues; dimensions beyond that are not meaningful.", length(pos)))
    }
    dhat <- as.matrix(stats::dist(coords))
    stress <- sqrt(sum((d - dhat)^2) / sum(d^2))
    summary <- list("Stress" = stress, "GOF1" = gof1, "GOF2" = gof2)
    ev <- cbind("Value" = pos, "Prop" = pos / sum(pos))
    rownames(ev) <- as.character(seq_along(pos))
    matrices <- list("Eigenvalues" = ev)
    extra$eig <- eig
    method_label <- "Classical (Torgerson) scaling"
  } else {
    # bnonmetricmds: isoMDS from the classical start. isoMDS refuses a zero
    # distance between distinct objects, which any pair at the maximum
    # similarity produces, so those are nudged to half the smallest positive
    # dissimilarity and the report says so (SPEC D10).
    off <- row(d) != col(d)
    if (any(d[off] <= 0)) {
      eps <- min(d[off][d[off] > 0]) / 2
      nz <- sum(d[off] <= 0) / 2
      d[off & d <= 0] <- eps
      assumptions <- c(assumptions, sprintf(
        "%d pairs at zero dissimilarity set to %s (half the smallest positive value) for non-metric scaling.",
        as.integer(nz), format_number(eps)))
    }
    dd <- stats::as.dist(d)
    init <- stats::cmdscale(dd, k = dim)
    fit <- MASS::isoMDS(dd, y = init, k = dim, maxit = 100, trace = FALSE, tol = 1e-3)
    coords <- fit$points
    stress <- fit$stress / 100
    summary <- list("Stress" = stress)
    sh <- MASS::Shepard(dd, coords)
    pairs <- which(lower.tri(d), arr.ind = TRUE)
    # Shepard() sorts by dissimilarity; recover the pair labels by matching the
    # sorted order of the input distances.
    ord <- order(dd)
    extra$shepard <- data.frame(
      Pair = paste(labels[pairs[ord, 2]], labels[pairs[ord, 1]], sep = "-"),
      Dissimilarity = sh$x, Distance = sh$y, Disparity = sh$yf,
      stringsAsFactors = FALSE)
    method_label <- "Non-metric (Kruskal) scaling"
  }
  dimnames(coords) <- list(labels, dn)

  if (isTRUE(plot)) {
    if (dim >= 2L) {
      plot_coords(coords, labels = labels,
                  main = if (method == "classical") "Classical MDS" else "Non-metric MDS",
                  sub = sprintf("Stress = %.3f", stress))
    } else {
      graphics::plot(coords[, 1], rep(0, n), yaxt = "n", ylab = "", pch = 19,
                     xlab = "Dimension 1",
                     main = if (method == "classical") "Classical MDS" else "Non-metric MDS",
                     sub = sprintf("Stress = %.3f", stress))
      graphics::text(coords[, 1], rep(0, n), labels = labels, pos = 3, cex = 0.8)
    }
  }

  out <- new_xucinet_output(
    "Multidimensional scaling", px$net,
    nodes = as.data.frame(coords, check.names = FALSE),
    summary = summary, matrices = matrices, assumptions = assumptions,
    fields = c("Method:" = method_label, "Type of Data:" = type_label(type),
               "Dimensions:" = as.character(dim)),
    nodes_title = "MDS Coordinates",
    stats_block = FALSE,
    subclass = "xmds", call = match.call())
  out$method <- method
  out$type <- type
  out$dissimilarities <- d
  out[names(extra)] <- extra
  if (isTRUE(plot)) invisible(out) else out
}

#' Shepard diagram of a non-metric MDS solution
#'
#' Plots the configuration distances against the input dissimilarities, with
#' the monotone-regression disparities as a step line. Points close to the
#' line are pairs the map reproduces well; the vertical scatter around it is
#' what stress measures. Ported from borgworld's `shepard.bnmds()`, drawn from
#' the data [xmds()] stores rather than from the original matrix.
#'
#' @param res The result of `xmds(method = "nonmetric")`.
#' @return `res$shepard`, invisibly.
#' @examples
#' res <- xmds(cities, type = "d", method = "nonmetric", plot = FALSE)
#' xshepard(res)
#' @export
xshepard <- function(res) {
  if (!inherits(res, "xmds") || is.null(res$shepard)) {
    stop("xshepard() needs the result of xmds(method = \"nonmetric\").", call. = FALSE)
  }
  sh <- res$shepard
  graphics::plot(sh$Dissimilarity, sh$Distance, pch = 16, col = "grey40",
                 xlab = "Input dissimilarity", ylab = "Configuration distance",
                 main = "Shepard diagram",
                 sub = sprintf("Stress = %.3f", res$summary$Stress))
  graphics::lines(sh$Dissimilarity, sh$Disparity, type = "S", col = "firebrick", lwd = 2)
  invisible(sh)
}
