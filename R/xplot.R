# Network drawing: xlayout() and xplot().
#
# Book chapter 7; design answers G1 and 7.1-7.3 (remaining-chapters-questions)
# and SPEC D13 as narrowed on 18 Sep 2026: base graphics, igraph layouts, no
# new dependency. Steve on 7.2 (24 Sep 2026): no underscores, so the drawing
# arguments are nodecolor, nodesize, nodeshape, labelsize, edgewidth,
# edgecolor, edgestyle, arrowsize.
#
# NetDraw is not the oracle: its layout (an MDS start polished by a
# three-part energy function) is not reproduced, and nothing here is
# golden-tested. "spring" is igraph's Fruchterman-Reingold, "kk" Kamada-Kawai,
# "mds" and "nmds" classical and non-metric scaling of geodesic distances,
# each as chapter 7 describes it.

layout_methods <- c("spring", "kk", "mds", "nmds", "circle", "random", "groups",
                    "bipartite")

#' Node coordinates for a network drawing
#'
#' Computes where [xplot()] puts the nodes, so that a layout can be kept and
#' reused: for the same network drawn at several cut-offs (book, 7.4.1), for a
#' subset of its nodes (7.5), or for the network at a later time (7.6),
#' `xplot(net2, layout = xlayout(net1))`.
#'
#' The layout is computed on the underlying graph: every tie in any of the
#' chosen relations, symmetrized, values ignored.
#'
#' * `"spring"`: Fruchterman and Reingold's force-directed layout (book,
#'   7.2.3), from igraph.
#' * `"kk"`: Kamada and Kawai's layout, whose springs have the lengths of the
#'   geodesic distances (7.2.3).
#' * `"mds"`, `"nmds"`: classical or non-metric multidimensional scaling of the
#'   geodesic distances, unreachable pairs set to one more than the largest
#'   distance (7.2.2).
#' * `"circle"`: the nodes on a circle, in their order (7.2).
#' * `"random"`: uniformly at random (7.2, Figure 7.1).
#' * `"groups"`: the nodes of each category of `attribute` together, the
#'   categories around a circle (7.2.1, Figure 7.6).
#' * `"bipartite"`: for 2-mode data, the row nodes in one line and the column
#'   nodes in another.
#'
#' A layout by attributes (7.2.1) needs no function: pass the attribute columns
#' themselves to `xplot(layout =)`.
#'
#' @param net A network (any accepted form). 2-mode data are laid out as the
#'   bipartite graph, row nodes first.
#' @param layout One of the methods above.
#' @param attribute For `"groups"`: the grouping, a vector or the name of an
#'   attribute (looked up in `net`, then `data`).
#' @param data A data frame to look `attribute` up in.
#' @param relation Which relations the layout is computed on; all of them by
#'   default.
#' @param seed Random seed for `"spring"`, `"kk"` and `"random"`. The default
#'   is fixed, so the same call always gives the same picture; `NULL` draws a
#'   new one each time.
#' @return A two-column matrix of coordinates with the node labels as row
#'   names, and the method in attribute `"xlayout"`.
#' @seealso [xplot()].
#' @examples
#' xy <- xlayout(campnet)
#' head(xy)
#' xplot(campnet, layout = xy)
#' @export
xlayout <- function(net, layout = "spring", attribute = NULL, data = NULL,
                    relation = NULL, seed = 1) {
  net <- xnet(net, substitute(net))
  layout <- match.arg(tolower(layout), layout_methods)
  g <- plot_graph(net, relation)
  adj <- g$any
  n <- nrow(adj)
  groups <- NULL
  if (layout == "groups") {
    if (is.null(attribute)) {
      stop('layout = "groups" needs an attribute to group by.', call. = FALSE)
    }
    groups <- node_values(attribute, net, data, g$labels,
                          deparse1(substitute(attribute)), "attribute")
  }
  if (layout == "bipartite" && is.null(g$mode)) {
    stop('layout = "bipartite" is for 2-mode data.', call. = FALSE)
  }
  xy <- layout_coords(adj, layout, seed, groups, g$mode)
  dimnames(xy) <- list(g$labels, c("x", "y"))
  attr(xy, "xlayout") <- layout
  xy
}

# The drawn graph: one n x n matrix of values per chosen relation, with 2-mode
# data turned into the bipartite graph; `any` is the underlying graph.
plot_graph <- function(net, relation, all = TRUE) {
  rels <- xrelations(net)
  if (is.null(relation)) {
    relation <- if (all) seq_along(rels) else 1L
  }
  if (is.character(relation)) {
    bad <- setdiff(relation, rels)
    if (length(bad)) {
      stop("no relation called \"", bad[1], "\".\n  Available: ",
           paste(rels, collapse = ", "), call. = FALSE)
    }
    relation <- match(relation, rels)
  }
  mats <- lapply(relation, function(r) pick_relation(net, r))
  names(mats) <- rels[relation]
  mode <- NULL
  m1 <- mats[[1]]
  labels <- rownames(m1)
  if (identical(net$mode, "2-mode")) {
    r <- nrow(m1); k <- ncol(m1)
    labels <- c(rownames(m1), colnames(m1))
    if (is.null(labels)) labels <- c(paste0("r", seq_len(r)), paste0("c", seq_len(k)))
    mats <- lapply(mats, function(m) {
      b <- matrix(0, r + k, r + k)
      b[seq_len(r), r + seq_len(k)] <- m
      b[r + seq_len(k), seq_len(r)] <- t(m)
      b
    })
    mode <- rep(c("Rows", "Columns"), c(r, k))
  }
  if (is.null(labels)) labels <- as.character(seq_len(nrow(mats[[1]])))
  mats <- lapply(mats, function(m) { m <- unname(m); diag(m) <- 0; m })
  any <- Reduce(`|`, lapply(mats, function(m) !is.na(m) & m != 0))
  any <- any | t(any)
  list(mats = mats, any = any, labels = labels, mode = mode)
}

layout_coords <- function(adj, layout, seed, groups = NULL, mode = NULL) {
  n <- nrow(adj)
  if (n == 1) return(matrix(0, 1, 2))
  if (layout %in% c("spring", "kk")) {
    g <- igraph::graph_from_adjacency_matrix(adj * 1, mode = "undirected")
    return(with_seed(seed, if (layout == "spring") igraph::layout_with_fr(g)
                           else igraph::layout_with_kk(g)))
  }
  switch(layout,
    circle = {
      a <- pi / 2 - 2 * pi * (seq_len(n) - 1) / n
      cbind(cos(a), sin(a))
    },
    random = with_seed(seed, matrix(stats::runif(2 * n), n, 2)),
    mds = , nmds = {
      d <- unname(geodesic_matrix(adj * 1, directed = FALSE, reciprocal = FALSE,
                                  unreachable = "max+1", diagonal = 0)$m)
      xy <- stats::cmdscale(d, k = 2)
      if (ncol(xy) < 2) xy <- cbind(xy, 0)
      if (layout == "nmds" && n > 2) {
        xy <- MASS::isoMDS(d, y = xy + stats::rnorm(length(xy), sd = 1e-6),
                           k = 2, trace = FALSE)$points
      }
      xy
    },
    groups = {
      g <- as.factor(groups)
      ng <- nlevels(g)
      a <- pi / 2 - 2 * pi * (seq_len(ng) - 1) / ng
      centres <- if (ng == 1) matrix(0, 1, 2) else cbind(cos(a), sin(a))
      size <- tabulate(g, ng)
      r <- 0.45 * sin(pi / max(ng, 2)) * sqrt(size / max(size))
      xy <- matrix(0, n, 2)
      for (k in seq_len(ng)) {
        who <- which(g == levels(g)[k])
        m <- length(who)
        b <- pi / 2 - 2 * pi * (seq_len(m) - 1) / m
        rr <- if (m == 1) 0 else r[k]
        xy[who, ] <- cbind(centres[k, 1] + rr * cos(b), centres[k, 2] + rr * sin(b))
      }
      xy[is.na(g), ] <- 0
      xy
    },
    bipartite = {
      top <- mode == "Rows"
      xy <- matrix(0, n, 2)
      xy[top, 1] <- seq(0, 1, length.out = sum(top) + 2)[-c(1, sum(top) + 2)]
      xy[!top, 1] <- seq(0, 1, length.out = sum(!top) + 2)[-c(1, sum(!top) + 2)]
      xy[top, 2] <- 1
      xy
    })
}

# A per-node value from what the user gave: NULL, the name of an attribute
# (in `net`, then `data`), a node-level result (its first numeric column), or a
# vector, named by node label or in node order. Returns NULL for NULL.
node_values <- function(x, net, data, labels, expr, what) {
  if (is.null(x)) return(NULL)
  n <- length(labels)
  if (inherits(x, "xucinet_output")) {
    tab <- x$nodes
    num <- vapply(tab, is.numeric, logical(1))
    if (is.null(tab) || !any(num)) {
      stop(what, ": that result has no numeric node-level column.", call. = FALSE)
    }
    v <- tab[[which(num)[1]]]
    names(v) <- rownames(tab)
    x <- v
  } else if (is.character(x) && length(x) == 1 && n != 1) {
    res <- resolve_attribute(x, net, data, expr)
    x <- res$values
    names(x) <- res$labels
  }
  if (is.factor(x)) x <- droplevels(x)
  if (!is.null(names(x)) && all(labels %in% names(x))) {
    return(x[match(labels, names(x))])
  }
  if (length(x) == 1) return(rep(x, n))
  if (length(x) != n) {
    stop(what, " has ", length(x), " values but there are ", n, " nodes.",
         call. = FALSE)
  }
  unname(x)
}

# Is this attribute drawn as categories? Text, factors and logicals are; so are
# numbers with at most six distinct whole values, such as codes 1, 2, 3.
is_categorical <- function(v) {
  if (is.character(v) || is.factor(v) || is.logical(v)) return(TRUE)
  u <- unique(v[!is.na(v)])
  length(u) <= 6 && all(u == round(u))
}

rescale <- function(v, lo, hi) {
  r <- range(v, na.rm = TRUE)
  out <- if (diff(r) == 0) rep((lo + hi) / 2, length(v))
         else lo + (hi - lo) * (v - r[1]) / diff(r)
  out[is.na(out)] <- lo
  out
}

plot_palette <- function(k) {
  p <- c("#56B4E9", "#E69F00", "#009E73", "#F0E442", "#0072B2", "#D55E00",
         "#CC79A7", "#999999")
  p[(seq_len(k) - 1L) %% length(p) + 1L]
}

shape_pch <- c(circle = 21L, square = 22L, diamond = 23L, triangle = 24L,
               downtriangle = 25L)

is_colour <- function(x) {
  is.character(x) && all(vapply(x, function(z) {
    !inherits(try(grDevices::col2rgb(z), silent = TRUE), "try-error")
  }, logical(1)))
}

#' Draw a network
#'
#' The network drawing of book chapter 7, in base graphics. Nodes are drawn as
#' symbols whose colour, size and shape can show attributes (7.3), ties as
#' lines whose width, darkness and style can show tie values and relations
#' (7.4), and any subset of nodes or ties can be left out while the rest keep
#' their places (7.5).
#'
#' @section How attributes are drawn:
#' `nodecolor`, `nodesize`, `nodeshape` and `labelsize` each take the name of
#' an attribute (looked up in `net`, then in `data`), a vector with one value
#' per node (named by node label, or in node order), or a node-level result
#' such as `xdegree(net)`, whose first numeric column is used.
#'
#' * Colour: categories get distinct colours and a legend; a continuous
#'   attribute gets shades of grey, darker for larger values (Figure 7.15). A
#'   colour name, such as `"white"`, colours every node.
#' * Size: the symbol's diameter runs linearly from 1 to 3 times the default
#'   between the smallest and the largest value.
#' * Shape: categories get circle, square, diamond, triangle, down-triangle,
#'   in that order. A shape name gives every node that shape.
#' * Label size: from 0.6 to 1.6 times the default, linearly.
#'
#' Text, factors, logicals and numbers with at most six distinct whole values
#' are treated as categories; wrap a variable in [factor()] to force it.
#'
#' Tie values: when the drawn ties are valued and `edgewidth` is not given,
#' line width (1 to 4) and darkness follow the value (Figures 7.5, 7.7).
#'
#' Several relations (`relation = c("Marriage", "Business")`) are drawn
#' together, one colour and line style per relation, and ties present in more
#' than one relation as thicker lines in the last colour (Figure 7.20).
#'
#' @section UCINET equivalent:
#' NetDraw. The drawing is not NetDraw's: its layout is not reproduced.
#'
#' @param net A network (any accepted form). 2-mode data are drawn as the
#'   bipartite graph, row nodes as circles and column nodes as squares.
#' @param layout A method name for [xlayout()], or coordinates: the result of
#'   [xlayout()] or of an earlier `xplot()`, or any two-column matrix or data
#'   frame (for instance two attribute columns, Figure 7.5) with the node
#'   labels as row names or in node order. Coordinates are matched by label, so
#'   a layout of a larger network serves a subset of its nodes.
#' @param relation Which relations to draw: the first by default, or several
#'   by name or position.
#' @param nodecolor,nodesize,nodeshape,labelsize Node attributes to draw; see
#'   "How attributes are drawn".
#' @param label `TRUE` (node labels), `FALSE`, or a character vector of labels.
#' @param edgewidth Line width: a number, or an n by n matrix. `NULL` follows
#'   the tie values when they are not all equal.
#' @param edgecolor Line colour; one per relation when several are drawn,
#'   plus one for ties in several relations.
#' @param edgestyle Line style (`"solid"`, `"dashed"`, `"dotted"`,
#'   `"dotdash"`, ...), one per relation when several are drawn.
#' @param arrows Draw arrowheads? `NULL` draws them when a drawn relation is
#'   not symmetric.
#' @param arrowsize Size of the arrowheads: a number (1 is the default size),
#'   an n by n matrix, or `TRUE` to make them follow the tie values
#'   (Figure 7.19).
#' @param cutoff Draw only ties whose value is greater than this (7.4.1).
#' @param keep The nodes to draw: a logical vector, a vector of labels, or
#'   `NULL` for all (7.5.2).
#' @param ego Draw only the ego network of this node: it, the nodes it is tied
#'   to in either direction, and the ties among them (7.5.3).
#' @param isolates `FALSE` leaves out the nodes that have no drawn tie, after
#'   the layout is made, so the others keep their places (7.5.1).
#' @param legend Draw legends for categorical colours and shapes and for
#'   relations?
#' @param data A data frame in which attribute names are looked up.
#' @param seed Random seed for the layout; see [xlayout()].
#' @param main A title.
#' @param file Write the drawing to this file instead of the screen: `.png`,
#'   `.jpg`, `.tiff`, `.pdf` or `.svg`, by the extension (7.7).
#' @param width,height Size of the file in inches.
#' @param dpi Resolution of a bitmap file.
#' @param ... Passed to [xlayout()] when `layout` is a method name, such as
#'   `attribute` for `layout = "groups"`.
#' @return The coordinates of the drawn nodes, invisibly, in the form
#'   [xlayout()] returns, so that the next drawing can reuse them.
#' @seealso [xlayout()].
#' @examples
#' xplot(campnet)
#' xplot(hightech, relation = "Friendship", nodesize = "Tenure",
#'       nodecolor = "Level", nodeshape = "Level", data = hightech_attr)
#' xplot(padgett, relation = c("Marriage", "Business"),
#'       edgecolor = c("darkgreen", "blue", "black"))
#' xy <- xplot(zachary, relation = "Strength", nodecolor = "Club", data = zachary_attr)
#' xplot(zachary, relation = "Strength", layout = xy, cutoff = 3, isolates = FALSE)
#' @export
xplot <- function(net, layout = "spring", relation = NULL, nodecolor = NULL,
                  nodesize = NULL, nodeshape = NULL, label = TRUE,
                  labelsize = NULL, edgewidth = NULL, edgecolor = NULL,
                  edgestyle = NULL, arrows = NULL, arrowsize = NULL,
                  cutoff = NULL, keep = NULL, ego = NULL, isolates = TRUE,
                  legend = TRUE, data = NULL, seed = 1, main = NULL,
                  file = NULL, width = 7, height = 7, dpi = 300, ...) {
  net <- xnet(net, substitute(net))
  g <- plot_graph(net, relation, all = FALSE)
  labels <- g$labels
  n <- length(labels)
  nrel <- length(g$mats)

  # Ties drawn: present, and above the cutoff.
  tie <- lapply(g$mats, function(m) {
    t <- !is.na(m) & m != 0
    if (!is.null(cutoff)) t <- t & !is.na(m) & m > cutoff
    t
  })
  drawn <- Reduce(`|`, tie)

  # Node values, taken on every node before any are left out.
  val <- function(x, what) node_values(x, net, data, labels, "", what)
  col_v <- if (is_colour(nodecolor) && !(length(nodecolor) == 1 &&
               has_attribute(nodecolor, net, data))) NULL else val(nodecolor, "nodecolor")
  shape_v <- if (is.character(nodeshape) && all(nodeshape %in% names(shape_pch)))
               NULL else val(nodeshape, "nodeshape")
  size_v <- val(nodesize, "nodesize")
  lsize_v <- val(labelsize, "labelsize")
  if (isTRUE(label)) lab <- labels
  else if (isFALSE(label)) lab <- rep("", n)
  else lab <- node_values(label, net, data, labels, "", "label")

  # Which nodes: keep, then ego.
  show <- rep(TRUE, n)
  if (!is.null(keep)) {
    show <- if (is.logical(keep)) rep_len(keep, n) & !is.na(rep_len(keep, n))
            else labels %in% as.character(keep)
  }
  if (!is.null(ego)) {
    e <- match(as.character(ego), labels)
    if (anyNA(e)) stop("no node called \"", ego[is.na(e)][1], "\".", call. = FALSE)
    near <- drawn[e, , drop = FALSE] | t(drawn[, e, drop = FALSE])
    show <- show & (seq_len(n) %in% e | colSums(near) > 0)
  }

  # Coordinates: computed on what is shown, before isolates are dropped.
  if (is.character(layout) && length(layout) == 1) {
    sub <- which(show)
    groups <- NULL
    extra <- list(...)
    if (tolower(layout) == "groups") {
      if (is.null(extra$attribute)) {
        stop('layout = "groups" needs attribute =.', call. = FALSE)
      }
      groups <- node_values(extra$attribute, net, data, labels, "", "attribute")[sub]
    }
    method <- match.arg(tolower(layout), layout_methods)
    adj <- (drawn | t(drawn))[sub, sub, drop = FALSE]
    xy <- matrix(NA_real_, n, 2)
    xy[sub, ] <- layout_coords(adj, method, seed, groups, g$mode[sub])
    axes <- NULL
  } else {
    xy <- coords_by_label(layout, labels, show)
    method <- attr(layout, "xlayout")
    axes <- if (is.null(method)) colnames(layout) else NULL
    if (is.null(method)) method <- "given"
  }

  if (!isTRUE(isolates)) {
    sub <- drawn[show, show, drop = FALSE]
    iso <- which(show)[rowSums(sub) + colSums(sub) == 0]
    if (length(iso)) {
      message(length(iso), if (length(iso) == 1) " isolate" else " isolates",
              " not drawn.")
      show[iso] <- FALSE
    }
  }

  if (!is.null(file)) open_plot_file(file, width, height, dpi)
  if (!is.null(file)) on.exit(grDevices::dev.off(), add = TRUE)

  # Node appearance.
  cat_col <- !is.null(col_v) && is_categorical(col_v)
  cat_shape <- !is.null(shape_v)
  fill <- if (!is.null(nodecolor) && is.null(col_v)) rep_len(nodecolor, n)
          else if (is.null(col_v)) {
            if (is.null(g$mode)) rep("#9ECAE1", n)
            else ifelse(g$mode == "Rows", "#9ECAE1", "#FDAE6B")
          } else if (cat_col) {
            f <- as.factor(col_v)
            plot_palette(nlevels(f))[as.integer(f)]
          } else grDevices::grey(rescale(-as.numeric(col_v), 0.1, 0.95))
  fill[is.na(fill)] <- "white"
  pch <- if (!is.null(nodeshape) && is.null(shape_v)) rep_len(shape_pch[nodeshape], n)
         else if (is.null(shape_v)) {
           if (is.null(g$mode)) rep(21L, n) else ifelse(g$mode == "Rows", 21L, 22L)
         } else {
           f <- as.factor(shape_v)
           shape_pch[(as.integer(f) - 1L) %% 5L + 1L]
         }
  pch[is.na(pch)] <- 21L
  cex <- if (is.null(size_v)) rep(1.5, n) else 1.5 * rescale(as.numeric(size_v), 1, 3)
  lcex <- if (is.null(lsize_v)) rep(0.7, n) else rescale(as.numeric(lsize_v), 0.6, 1.6)

  # Edge list: one row per drawn ordered pair (i, j), i != j, both shown.
  directed <- !all(vapply(tie, function(t) isSymmetric(unname(t)), logical(1)))
  if (is.null(arrows)) arrows <- directed
  el <- edge_table(g$mats, tie, show, arrows)

  # Legend space on the right.
  leg <- list()
  if (isTRUE(legend)) {
    if (cat_col || cat_shape) leg$nodes <- TRUE
    if (nrel > 1) leg$ties <- TRUE
    if (!is.null(g$mode) && is.null(col_v) && is.null(shape_v) && is.null(nodecolor)) {
      leg$modes <- TRUE
    }
  }
  op <- graphics::par(mar = c(if (is.null(axes)) 1 else 4, if (is.null(axes)) 1 else 4,
                              if (is.null(main)) 1 else 3, if (length(leg)) 9 else 1))
  on.exit(graphics::par(op), add = TRUE, after = FALSE)

  shown <- which(show)
  pts <- xy[shown, , drop = FALSE]
  xr <- range(pts[, 1], na.rm = TRUE); yr <- range(pts[, 2], na.rm = TRUE)
  pad <- 0.08 * max(diff(xr), diff(yr), 1e-9)
  graphics::plot.new()
  graphics::plot.window(xlim = xr + c(-pad, pad), ylim = yr + c(-pad, pad),
                        asp = if (is.null(axes)) 1 else NA)
  if (!is.null(axes)) {
    graphics::axis(1); graphics::axis(2); graphics::box()
    graphics::title(xlab = axes[1], ylab = axes[2])
  }
  if (!is.null(main)) graphics::title(main = main)

  draw_edges(el, xy, cex, g$mats, nrel, arrows, edgewidth, edgecolor, edgestyle,
             arrowsize, names(g$mats))
  graphics::points(pts[, 1], pts[, 2], pch = pch[shown], bg = fill[shown],
                   col = "black", cex = cex[shown])
  if (any(nzchar(lab[shown]))) {
    rad <- 0.375 * graphics::par("cin")[2] * cex[shown] + 0.03
    graphics::text(pts[, 1] + rad * graphics::xinch(1), pts[, 2], labels = lab[shown],
                   cex = lcex[shown], adj = c(0, 0.5))
  }
  if (length(leg)) draw_legends(leg, col_v, shape_v, cat_col, cat_shape,
                                names(g$mats), edgecolor, edgestyle, g$mode,
                                arg_title(nodecolor, substitute(nodecolor)),
                                arg_title(nodeshape, substitute(nodeshape)))

  out <- xy[shown, , drop = FALSE]
  dimnames(out) <- list(labels[shown], c("x", "y"))
  attr(out, "xlayout") <- method
  invisible(out)
}

# The legend title for an attribute argument: its name, or the expression.
arg_title <- function(x, expr) {
  if (is.character(x) && length(x) == 1) return(x)
  if (inherits(x, "xucinet_output")) return(names(x$nodes)[vapply(x$nodes, is.numeric, logical(1))][1])
  e <- deparse1(expr)
  if (grepl("[$]", e)) sub("^.*[$]", "", e) else e
}

has_attribute <- function(name, net, data) {
  a <- xattributes(net)
  (!is.null(a) && name %in% names(a)) || (!is.null(data) && name %in% names(data))
}

coords_by_label <- function(layout, labels, show) {
  m <- as.matrix(layout)
  if (ncol(m) < 2) stop("a layout needs two columns of coordinates.", call. = FALSE)
  storage.mode(m) <- "double"
  xy <- matrix(NA_real_, length(labels), 2)
  rn <- rownames(m)
  if (!is.null(rn) && !all(grepl("^[0-9]+$", rn))) {
    miss <- labels[show & !labels %in% rn]
    if (length(miss)) {
      stop("the layout has no coordinates for ", length(miss), " node",
           if (length(miss) > 1) "s", ": ", paste(utils::head(miss, 5), collapse = ", "),
           if (length(miss) > 5) ", ...", call. = FALSE)
    }
    hit <- match(labels, rn)
    xy[!is.na(hit), ] <- m[hit[!is.na(hit)], 1:2]
  } else {
    if (nrow(m) != length(labels)) {
      stop("the layout has ", nrow(m), " rows and no node labels, but there are ",
           length(labels), " nodes.", call. = FALSE)
    }
    xy[] <- m[, 1:2]
  }
  if (anyNA(xy[show, ])) stop("the layout has missing coordinates.", call. = FALSE)
  xy
}

open_plot_file <- function(file, width, height, dpi) {
  ext <- tolower(sub("^.*[.]", "", basename(file)))
  switch(ext,
    png = grDevices::png(file, width = width, height = height, units = "in", res = dpi),
    jpg = , jpeg = grDevices::jpeg(file, width = width, height = height, units = "in",
                                   res = dpi, quality = 95),
    tif = , tiff = grDevices::tiff(file, width = width, height = height, units = "in",
                                   res = dpi, compression = "lzw"),
    pdf = grDevices::pdf(file, width = width, height = height),
    svg = grDevices::svg(file, width = width, height = height),
    stop("file = must end in .png, .jpg, .tiff, .pdf or .svg.", call. = FALSE))
}

# One row per drawn pair. For a symmetric drawing a pair is one line; for a
# directed one, each direction is a row, and a reciprocated pair shares a line.
edge_table <- function(mats, tie, show, arrows) {
  nrel <- length(mats)
  any <- Reduce(`|`, tie)
  ok <- outer(show, show, `&`) & any
  if (!arrows) ok <- (ok | t(ok)) & upper.tri(ok)
  idx <- which(ok, arr.ind = TRUE)
  if (!nrow(idx)) return(data.frame(i = integer(0), j = integer(0)))
  el <- data.frame(i = idx[, 1], j = idx[, 2])
  inrel <- vapply(tie, function(t) {
    if (arrows) t[idx] else (t | t(t))[idx]
  }, logical(nrow(idx)))
  inrel <- matrix(inrel, ncol = nrel)
  el$nrel <- rowSums(inrel)
  el$rel <- apply(inrel, 1, function(r) if (sum(r) == 1) which(r) else 0L)
  el$value <- vapply(seq_len(nrow(el)), function(k) {
    v <- vapply(seq_len(nrel), function(r) {
      m <- mats[[r]]
      x <- if (arrows) m[el$i[k], el$j[k]] else max(m[el$i[k], el$j[k]], m[el$j[k], el$i[k]], na.rm = TRUE)
      if (inrel[k, r]) x else NA_real_
    }, numeric(1))
    max(v, na.rm = TRUE)
  }, numeric(1))
  el
}

draw_edges <- function(el, xy, cex, mats, nrel, arrows, edgewidth, edgecolor,
                       edgestyle, arrowsize, relnames) {
  if (!nrow(el)) return(invisible())
  n <- nrow(xy)
  valued <- length(unique(el$value)) > 1
  lwd <- if (is.matrix(edgewidth)) edgewidth[cbind(el$i, el$j)]
         else if (!is.null(edgewidth)) rep_len(edgewidth, nrow(el))
         else if (valued && nrel == 1) rescale(el$value, 1, 4)
         else rep(1, nrow(el))
  ltys <- if (is.null(edgestyle)) rep("solid", nrel) else rep_len(edgestyle, nrel)
  if (nrel == 1) {
    col <- if (!is.null(edgecolor)) rep_len(edgecolor, nrow(el))
           else if (valued) grDevices::grey(rescale(-el$value, 0.05, 0.6))
           else rep("grey35", nrow(el))
    lty <- rep(ltys[1], nrow(el))
  } else {
    cols <- if (is.null(edgecolor)) c(plot_palette(nrel + 1)[-1][seq_len(nrel)], "black")
            else rep_len(edgecolor, nrel + 1)
    col <- ifelse(el$rel > 0, cols[pmax(el$rel, 1)], cols[nrel + 1])
    lty <- ifelse(el$rel > 0, ltys[pmax(el$rel, 1)], "solid")
    lwd <- ifelse(el$nrel > 1, 2 * lwd, lwd)
  }

  # Work in inches so that lines stop at the symbol's edge and arrowheads keep
  # their shape whatever the scale of the axes.
  ux <- graphics::xinch(1); uy <- graphics::yinch(1)
  rad <- 0.375 * graphics::par("cin")[2] * cex
  asz <- if (is.matrix(arrowsize)) arrowsize[cbind(el$i, el$j)]
         else if (isTRUE(arrowsize)) rescale(el$value, 0.6, 1.8)
         else if (is.numeric(arrowsize)) rep_len(arrowsize, nrow(el))
         else rep(1, nrow(el))
  recip <- if (arrows) {
    key <- paste(el$i, el$j); rkey <- paste(el$j, el$i)
    rkey %in% key
  } else rep(FALSE, nrow(el))

  heads <- list()
  for (k in seq_len(nrow(el))) {
    i <- el$i[k]; j <- el$j[k]
    p1 <- c(xy[i, 1] / ux, xy[i, 2] / uy); p2 <- c(xy[j, 1] / ux, xy[j, 2] / uy)
    d <- p2 - p1; len <- sqrt(sum(d^2))
    if (len <= rad[i] + rad[j]) next
    u <- d / len
    a <- p1 + u * rad[i]; b <- p2 - u * (rad[j] + 0.01)
    # A reciprocated pair shares one line, drawn with its first row.
    if (!(recip[k] && i > j)) {
      graphics::segments(a[1] * ux, a[2] * uy, b[1] * ux, b[2] * uy,
                         col = col[k], lwd = lwd[k], lty = lty[k])
    }
    if (arrows) {
      h <- 0.09 * asz[k]; w <- 0.035 * asz[k]
      base <- b - u * h; nrm <- c(-u[2], u[1])
      px <- c(b[1], base[1] + nrm[1] * w, base[1] - nrm[1] * w) * ux
      py <- c(b[2], base[2] + nrm[2] * w, base[2] - nrm[2] * w) * uy
      heads[[length(heads) + 1]] <- list(px = px, py = py, col = col[k])
    }
  }
  for (h in heads) graphics::polygon(h$px, h$py, col = h$col, border = h$col)
  invisible()
}

draw_legends <- function(leg, col_v, shape_v, cat_col, cat_shape, relnames,
                         edgecolor, edgestyle, mode, col_title, shape_title) {
  usr <- graphics::par("usr")
  x <- usr[2] + 0.02 * diff(usr[1:2])
  y <- usr[4]
  add <- function(...) {
    r <- graphics::legend(x, y, xpd = NA, bty = "n", cex = 0.75, title.adj = 0, ...)
    y <<- r$rect$top - r$rect$h - 0.02 * diff(usr[3:4])
  }
  if (isTRUE(leg$nodes)) {
    if (cat_col && cat_shape && identical(as.character(col_v), as.character(shape_v))) {
      f <- as.factor(col_v)
      add(legend = levels(f), pch = shape_pch[(seq_len(nlevels(f)) - 1L) %% 5L + 1L],
          pt.bg = plot_palette(nlevels(f)), pt.cex = 1.3, title = col_title)
    } else {
      if (cat_col) {
        f <- as.factor(col_v)
        add(legend = levels(f), pch = 21, pt.bg = plot_palette(nlevels(f)), pt.cex = 1.3,
            title = col_title)
      }
      if (cat_shape) {
        f <- as.factor(shape_v)
        add(legend = levels(f), pch = shape_pch[(seq_len(nlevels(f)) - 1L) %% 5L + 1L],
            pt.bg = "white", pt.cex = 1.3, title = shape_title)
      }
    }
  }
  if (isTRUE(leg$modes)) {
    add(legend = c("Rows", "Columns"), pch = c(21, 22),
        pt.bg = c("#9ECAE1", "#FDAE6B"), pt.cex = 1.3)
  }
  if (isTRUE(leg$ties)) {
    nrel <- length(relnames)
    cols <- if (is.null(edgecolor)) c(plot_palette(nrel + 1)[-1][seq_len(nrel)], "black")
            else rep_len(edgecolor, nrel + 1)
    ltys <- if (is.null(edgestyle)) rep("solid", nrel) else rep_len(edgestyle, nrel)
    add(legend = c(relnames, "Several"), col = cols, lty = c(ltys, "solid"),
        lwd = c(rep(1.5, nrel), 3))
  }
  invisible()
}
