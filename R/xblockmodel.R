# Blockmodel of a given partition.
#
# UCINET: Transform | Aggregate | Block - Aggregate by Partitions
# (uc_blockmatrix.pas, Tblockmatrix.run; repository StephenBorgatti/ucinet at
# commit c7b4956), the report: for each relation the blocked matrix
# (blockdisplay in G2Tools/ug2display.pas), the aggregated matrix
# (aggbygroups in G2Tools/uAggregate.pas; tools commit 207958a) and the
# "autocorrelation", the correlation over the cells between each cell's value
# and its block's value. xcombinenodes() is the same dialog as a
# transformation, returning only the aggregated network, and the aggregation
# here is its aggregate_blocks().
#
# Dialog defaults (uc_blockmatrix.dfm): Method Average, "Utilize diagonal"
# unchecked. The image matrix is an addition (design question 12.2): each
# block's value against a cutoff, by default the relation's density, the
# alpha criterion. UCINET's dialog prints no image; the book's Figure 12.5
# shows one. Ledger entry 34.
#
# Answer to Steve's question on 12.2: this routine does not search for
# anything. It takes a partition you already have and summarizes the network
# by it, so it is a few matrix sums and runs instantly. The search for the
# best partition is xblockoptimize() (issue #24).

blockmodel_methods <- c(average = "Average", count = "Count > 0",
                        maximum = "Maximum", minimum = "Minimum",
                        sd = "Std Deviation", sum = "Sum")

#' Blockmodel
#'
#' UCINET: Transform | Aggregate | Block - Aggregate by Partitions. Summarizes
#' a network by a partition of its nodes: the matrix rearranged so that each
#' group's rows and columns are together, the density (or other summary) of
#' every block, the image matrix, and how well the blocks fit the data.
#'
#' The partition is given, not found: an attribute, a clustering, or any
#' routine's result with a `Cluster` column. To search for the best partition,
#' see `xblockoptimize()` (not yet written; issue #24).
#'
#' For each relation the report shows the blocked matrix and the table of
#' block values, and `$summary` holds the *autocorrelation*, UCINET's fit: the
#' correlation, over all cells, between a cell's value and its block's value.
#' The image matrix sets a block to 1 when its value reaches `cutoff`; by
#' default the cutoff is the relation's density (the alpha criterion), so a
#' 1-block is one denser than the network as a whole.
#'
#' @section UCINET equivalent:
#' Transform | Aggregate | Block - Aggregate by Partitions. *Method* is
#' `method`, *Utilize diagonal* is `diagonal`. UCINET prints no image matrix;
#' it is added here (ledger entry 34).
#'
#' @param net A network (any accepted form). 1-mode.
#' @param partition The groups: a vector with one value per node, the name of
#'   an attribute (looked up in `net`'s attributes and then in `data`), or a
#'   result object whose `$nodes` has a `Cluster` column.
#' @param relations Which relations to block, by name or position. `NULL`, the
#'   default, blocks every relation, as UCINET does.
#' @param method The block summary: `"average"` (UCINET's default, the density
#'   for binary data), `"count"`, `"maximum"`, `"minimum"`, `"sd"` or `"sum"`.
#' @param diagonal Include the diagonal (self-ties)? `FALSE` by default.
#' @param cutoff Where the image matrix puts a 1: a block value at or above
#'   it. `NULL`, the default, uses each relation's density.
#' @param data A data frame to look `partition` up in.
#' @return An object of class `c("xblockmodel", "xucinet_output")`.
#'   `$nodes` holds `Block`, the group of each node; `$matrices` a table of
#'   block values and an image matrix per relation; `$summary` the
#'   autocorrelation and the cutoff per relation.
#' @seealso [xcombinenodes()], [xdensitybygroups()], [xstructuralequivalence()].
#' @examples
#' xblockmodel(campnet, camp92_attr$Gender)
#' @export
xblockmodel <- function(net, partition, relations = NULL,
                        method = c("average", "count", "maximum", "minimum",
                                   "sd", "sum"),
                        diagonal = FALSE, cutoff = NULL, data = NULL) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  require_1mode(net, "xblockmodel()")

  if (inherits(partition, "xucinet_output")) {
    if (is.null(partition$nodes$Cluster) || all(is.na(partition$nodes$Cluster))) {
      stop("xblockmodel(): that result has no Cluster column to block by.",
           call. = FALSE)
    }
    groups <- partition$nodes$Cluster
  } else {
    expr <- deparse1(substitute(partition))
    groups <- resolve_attribute(partition, net, data, expr)$values
  }

  mats <- relation_list(net)
  if (!is.null(relations)) {
    idx <- if (is.character(relations)) match(relations, names(mats)) else
      as.integer(relations)
    if (anyNA(idx) || any(idx < 1 | idx > length(mats))) {
      stop("xblockmodel(): relations must name relations of the dataset.\n",
           "  Available: ", paste(names(mats), collapse = ", "), call. = FALSE)
    }
    mats <- mats[idx]
  }
  n <- nrow(mats[[1]])
  if (length(groups) != n) {
    stop("xblockmodel(): the partition has ", length(groups),
         " values but the network has ", n, " nodes.", call. = FALSE)
  }

  keys <- sort(unique(groups[!is.na(groups)]))
  block <- match(groups, keys)
  stat <- c(average = "mean", count = "count", maximum = "max",
            minimum = "min", sd = "sd", sum = "sum")[[method]]

  matrices <- list()
  summary <- list()
  display <- character()
  multi <- length(mats) > 1
  for (rel in names(mats)) {
    m <- mats[[rel]]
    agg <- aggregate_blocks(m, groups, stat, diagonal)
    dens <- blockmodel_density(m, diagonal)
    cut <- if (is.null(cutoff)) dens else cutoff
    img <- (agg >= cut) * 1
    img[is.na(agg)] <- NA
    fit <- blockmodel_autocorrelation(m, agg, block, diagonal)

    suffix <- if (multi) paste0(" (", rel, ")") else ""
    matrices[[paste0("Aggregated matrix", suffix)]] <- agg
    matrices[[paste0("Image", suffix)]] <- img
    summary[[paste0("Autocorrelation", suffix)]] <- fit
    summary[[paste0("Cutoff", suffix)]] <- cut
    if (multi) display <- c(display, paste0("Relation: ", rel), "")
    display <- c(display, format_blocked_matrix(m, block), "")
  }

  nodes <- data.frame(Block = groups, row.names = rownames(mats[[1]]),
                      check.names = FALSE)

  out <- new_xucinet_output(
    "Densities or Average Tie Strengths Within/Between Groups", net,
    nodes = nodes, summary = summary, matrices = matrices,
    fields = c("Method:" = blockmodel_methods[[method]],
               "Diagonal valid?" = if (isTRUE(diagonal)) "YES" else "NO",
               "Image cutoff:" = if (is.null(cutoff)) "density of each relation"
                                 else format(cutoff)),
    preamble = display,
    print_nodes = FALSE,
    subclass = "xblockmodel", call = match.call())
  out
}

# The relation's density: the mean off the diagonal (on it too if asked).
blockmodel_density <- function(m, diagonal) {
  keep <- !is.na(m)
  if (!diagonal) keep[row(m) == col(m)] <- FALSE
  mean(m[keep])
}

# getautocorr: correlation, over the cells, between each cell's value and its
# block's aggregated value.
blockmodel_autocorrelation <- function(m, agg, block, diagonal) {
  bv <- agg[cbind(rep(block, times = ncol(m)), rep(block, each = nrow(m)))]
  bv <- matrix(bv, nrow(m), ncol(m))
  keep <- !is.na(m) & !is.na(bv)
  if (!diagonal) keep[row(m) == col(m)] <- FALSE
  x <- bv[keep]; y <- m[keep]
  if (length(x) < 2 || stats::sd(x) == 0 || stats::sd(y) == 0) return(NA_real_)
  stats::cor(x, y)
}

# blockdisplay (the tstreamwriter version in ug2display.pas) with the arguments
# uc_blockmatrix passes: width and decimals chosen from the data, zeros shown
# blank. Rows and columns are sorted by block; within a block, original order.
format_blocked_matrix <- function(m, block) {
  n <- nrow(m)
  ord <- order(block, seq_len(n))
  bl <- block[ord]
  labs <- rownames(m); if (is.null(labs)) labs <- as.character(seq_len(n))
  vals <- m[ord, ord, drop = FALSE]
  ok <- vals[!is.na(vals)]
  whole <- all(ok == round(ok))
  d <- if (whole) 0L else 3L
  minw1 <- function(x) {
    k <- if (x < 0) 1L else 0L
    k <- if (abs(x) < 1) k + 1L else k + floor(log10(abs(x))) + 1L
    if (d > 0) k <- k + d + 1L
    min(20L, k + 1L)
  }
  w <- if (length(ok)) max(minw1(max(ok)), minw1(min(ok))) else 2L
  lw <- max(nchar(labs)) + 2L
  left2 <- 4L + lw + 1L
  brk <- c(bl[-1] != bl[-n], TRUE)      # a block ends after this column/row

  cell <- function(x) {
    if (is.na(x)) return(formatC(".", width = w))
    if (abs(x) < 1e-7) return(strrep(" ", w))
    formatC(x, width = w, format = "f", digits = d)
  }
  sep <- function(j, end, mid) if (j == n) end else if (brk[j]) mid else ""

  out <- character()
  # Column numbers: written downwards, one digit per line, when they do not
  # fit the cell width (FancyColHead), otherwise on one line.
  idx <- as.character(ord)
  if (w < minw1(n) || w < max(nchar(idx))) {
    nd <- max(nchar(idx))
    for (i in seq_len(nd)) {
      line <- strrep(" ", left2)
      for (j in seq_len(n)) {
        s <- idx[j]
        pos <- nchar(s) - (nd - i)
        ch <- if (pos >= 1) substr(s, pos, pos) else " "
        line <- paste0(line, formatC(ch, width = w), sep(j, "  ", "  "))
      }
      out <- c(out, line)
    }
  } else {
    line <- strrep(" ", left2)
    for (j in seq_len(n)) line <- paste0(line, formatC(idx[j], width = w), sep(j, "  ", "  "))
    out <- c(out, line)
  }
  line <- strrep(" ", left2)
  for (j in seq_len(n)) {
    line <- paste0(line, formatC(substr(labs[ord[j]], 1, w - 1), width = w),
                   sep(j, "  ", "  "))
  }
  out <- c(out, line)
  rule <- function(lead) {
    line <- lead
    for (j in seq_len(n)) line <- paste0(line, strrep("-", w), sep(j, "--", "--"))
    line
  }
  out <- c(out, sub("--$", "- ", rule(strrep(" ", left2))))
  for (i in seq_len(n)) {
    line <- paste0(formatC(as.character(ord[i]), width = 4),
                   formatC(paste0(labs[ord[i]], " |"), width = lw + 1))
    for (j in seq_len(n)) line <- paste0(line, cell(vals[i, j]), sep(j, " |", " |"))
    out <- c(out, line)
    if (i == n) {
      out <- c(out, rule(strrep(" ", 3L + lw + 1L)))
    } else if (brk[i]) {
      out <- c(out, rule(paste0(strrep(" ", 4L + lw), "-")))
    }
  }
  out
}
