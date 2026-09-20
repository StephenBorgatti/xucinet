# Shared machinery for the chapter 6 routines - xmds(), xcorrespondence() and
# xhclust() - whose input is a proximity matrix rather than a network. SPEC D4
# addendum (18 Sep 2026): these name their first argument `x`, because the
# thing passed in is often not a network at all (cities is road mileage), and
# everything else about D4 is unchanged, including the xnet(x, substitute(x))
# first line that keeps the caller's expression as the dataset title.
#
# The similarity-to-dissimilarity conversion and the `type =` error live here
# so that the three routines cannot drift apart on either.

# ---- dist objects ------------------------------------------------------------

#' @export
as_xucinet.dist <- function(x, directed = NULL, mode = NULL, title = NULL, ...) {
  if (is.null(title)) title <- deparse1(substitute(x))
  m <- as.matrix(x)
  # dist() keeps the row names of what it was given; when there were none it
  # gives none back, and ensure_dimnames() then numbers them.
  as_xucinet(m, directed = FALSE, mode = "1-mode", title = title)
}

# ---- coercion ----------------------------------------------------------------

# The first line of every proximity routine. Coerces x (matrix, data frame,
# dist, xucinet, file name, ...) through xnet() and hands back the matrix and
# the xucinet object it came from, checking squareness when the routine needs
# it. `what` names the routine in error messages.
xprox <- function(x, expr, what, square = TRUE, relation = NULL) {
  net <- xnet(x, expr)
  m <- as.matrix(net, relation = relation)
  if (square && nrow(m) != ncol(m)) {
    stop(what, " needs a square matrix; this one is ", nrow(m), " x ", ncol(m),
         ".\n  For a 2-mode matrix use xcorrespondence(), or scale one mode's ",
         "similarities from xsimilarities() once it lands.", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  list(net = net, m = m, assumptions = assumptions)
}

# ---- type = ------------------------------------------------------------------

# `type` has no default (decided 8 Sep 2026): a matrix of 0/1 ties reads as a
# distance matrix under every heuristic and is a similarity under every
# interpretation, and a plausible map that is inside out is worse than an
# error. borgworld prompts interactively; practices and generators run under
# Rscript and knitr, so this stops instead, and the message is the teaching
# (SPEC D14).
match_type <- function(type, fn, example = "cities") {
  if (missing(type) || is.null(type)) {
    stop(fn, "() needs to know what kind of matrix this is.\n",
         "  type = \"similarities\"     larger values mean closer  ",
         "(correlations, co-membership counts, ties)\n",
         "  type = \"dissimilarities\"  larger values mean further ",
         "(distances, geodesics)\n",
         "  e.g. ", fn, "(", example, ", type = \"dissimilarities\")",
         call. = FALSE)
  }
  if (!is.character(type) || length(type) != 1L) {
    stop("type must be \"similarities\" or \"dissimilarities\".", call. = FALSE)
  }
  choices <- c("similarities", "dissimilarities")
  hit <- pmatch(tolower(type), choices)
  if (is.na(hit)) {
    stop("type = \"", type, "\" is not recognised; use \"similarities\" or ",
         "\"dissimilarities\" (or \"s\" / \"d\").", call. = FALSE)
  }
  choices[hit]
}

type_label <- function(type) {
  if (type == "similarities") "Similarities" else "Dissimilarities"
}

# ---- conversion --------------------------------------------------------------

# Missing and infinite values stop the routine rather than propagating into
# cmdscale() or hclust(), which fail with messages about their own internals.
# The likeliest source is the geodesic distance matrix of a disconnected
# network, so the message says what to do about that case.
check_proximities <- function(m, fn) {
  bad <- is.na(m) | !is.finite(m)
  if (any(bad)) {
    stop(fn, "() cannot scale a matrix with missing or infinite values; this ",
         "one has ", sum(bad), ".\n",
         "  If these are geodesic distances of a disconnected network, replace ",
         "the unreachable pairs first,\n  e.g. m[!is.finite(m)] <- max(m[is.finite(m)]) + 1",
         call. = FALSE)
  }
  invisible(m)
}

# Similarities become dissimilarities as max - x, where max is taken over the
# OFF-DIAGONAL cells. borgworld's bhiclus does this; its two MDS functions take
# the max over the whole matrix, diagonal included, so a correlation matrix
# (diagonal 1) gives 1 - r there and max(r_offdiag) - r here. The two differ by
# a constant on every off-diagonal cell, and classical MDS is not invariant to
# that constant. Steve chose the off-diagonal rule for all three routines on
# 18 Sep 2026 (design question 9): a self-similarity is a convention, and a
# convention should not move every point on the map. Port note in
# inst/reference/borgworld/README.md.
#
# Returns the dissimilarity matrix (diagonal 0, no negatives) and the
# assumption lines describing what was done.
to_dissimilarity <- function(m, type, fn) {
  notes <- character()
  d <- m
  if (type == "similarities") {
    off <- d[row(d) != col(d)]
    mx <- max(off)
    d <- mx - d
    notes <- c(notes, sprintf(
      "Similarities converted to dissimilarities as %s - x (largest off-diagonal value).",
      format_number(mx)))
  }
  diag(d) <- 0
  if (any(d < 0)) {
    # borgworld warns and clamps; we do the same and also record it.
    warning(fn, "(): negative dissimilarities set to 0.", call. = FALSE)
    d[d < 0] <- 0
    notes <- c(notes, "Negative dissimilarities set to 0.")
  }
  list(d = d, notes = notes)
}

# UCINET's Johnson's routine (HandleAsymmetry in XCluster.pas) averages Xij and
# Xji before clustering and says so; the same is done here for every proximity
# routine, since none of them is defined on an asymmetric matrix.
symmetrize_average <- function(m) {
  if (isTRUE(all.equal(m, t(m), check.attributes = FALSE))) {
    return(list(m = m, notes = character()))
  }
  s <- (m + t(m)) / 2
  dimnames(s) <- dimnames(m)
  list(m = s, notes = "WARNING: Data not symmetric, so they have been symmetrized by averaging Xij and Xji.")
}

# ---- plotting ----------------------------------------------------------------

# One drawing routine for every coordinate plot in the package, so the MDS map
# and the CA map look alike. A tightened port of borgworld's bplotcoord()
# (R/b_plotcoord.R, commit 2eb26f4): base graphics, labels placed above the
# point except in the top of the plot, a dotted grid. Two changes: asp = 1,
# because in a scaling plot the distances are the result and unequal axis
# scaling draws a wrong picture (UCINET's viewer sets uniform axes too); and a
# second group of points, for the column points of a CA map.
plot_coords <- function(coords, labels = NULL, main = "", sub = "",
                        groups = NULL, xlab = "Dimension 1", ylab = "Dimension 2",
                        cex = 1, cex.text = 0.8) {
  coords <- as.matrix(coords)
  if (ncol(coords) < 2L) {
    stop("plot_coords() needs at least two dimensions.", call. = FALSE)
  }
  if (is.null(labels)) labels <- rownames(coords)
  if (is.null(labels)) labels <- as.character(seq_len(nrow(coords)))
  n <- nrow(coords)
  if (is.null(groups)) {
    col <- rep("black", n)
    pch <- rep(19L, n)
  } else {
    g <- as.factor(groups)
    palette <- c("#1F4E79", "#C0392B", "#2E7D32", "#7B1FA2", "#E67E22",
                 "#00838F", "#6D4C41", "#AD1457")
    col <- palette[(as.integer(g) - 1L) %% length(palette) + 1L]
    pch <- c(19L, 17L, 15L, 18L, 8L, 4L, 3L, 1L)[(as.integer(g) - 1L) %% 8L + 1L]
  }
  x <- coords[, 1]; y <- coords[, 2]
  ytop <- min(y) + 2 * diff(range(y)) / 3
  pos <- ifelse(y > ytop, 1L, 3L)
  xr <- range(x); yr <- range(y)
  xpad <- max(diff(xr), .Machine$double.eps) * 0.08
  ypad <- max(diff(yr), .Machine$double.eps) * 0.12
  graphics::plot(x, y, col = col, pch = pch, cex = cex, asp = 1,
                 xlim = c(xr[1] - xpad, xr[2] + xpad),
                 ylim = c(yr[1] - ypad, yr[2] + ypad),
                 xlab = xlab, ylab = ylab, main = main, sub = sub)
  graphics::text(x, y, labels = labels, col = col, cex = cex.text, pos = pos)
  graphics::abline(h = 0, v = 0, col = "grey70", lty = 2)
  graphics::grid(col = "lightgray", lty = "dotted")
  if (!is.null(groups)) {
    graphics::legend("topright", legend = levels(g),
                     col = palette[(seq_along(levels(g)) - 1L) %% length(palette) + 1L],
                     pch = c(19L, 17L, 15L, 18L, 8L, 4L, 3L, 1L)[(seq_along(levels(g)) - 1L) %% 8L + 1L],
                     bty = "n", cex = 0.8)
  }
  invisible(coords)
}
