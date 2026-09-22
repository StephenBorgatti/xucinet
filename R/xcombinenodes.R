# Aggregate a network by a node partition.
#
# Ported from uc_blockmatrix.pas, Transform | Aggregate | Block - Aggregate by
# Partitions (repository StephenBorgatti/ucinet at commit c7b4956), with the
# aggregation itself in G2Tools/uAggregate.pas, procedure aggbygroups
# (repository StephenBorgatti/tools at commit 207958a).
#
# aggbygroups collects every cell (i,j) into the accumulator for block
# (rp[i], cp[j]) and then asks it for one statistic. Two details matter:
#
#   for i := 1 to m.nr do
#     for j := 1 to m.nc do if (i<>j) or diagok then
#       s[rp[i],cp[j]].addcase(m.cell[i,j]);
#
# the test is `i <> j`, the matrix diagonal, not the block diagonal - so a
# within-group block keeps every cell except the self-ties; and
# `if m.is2mode then diagok := true`, matching `diagok := (m.nr <> m.nc) or
# diagonal.checked` in the form.
#
# Question 5.6: the crosswalk's xcombinenodes is this routine rather than
# Transform | Aggregate | Collapse, whose typed instruction format ("ROWS 1 2
# 3") a partition vector covers. UCINET's "density" here is the mean of the
# cells, which is what its own output calls "Density (prop of ties or average
# tie strength)".

# method.ItemIndex -> the statistic aggbygroups asks for.
agg_stats <- c(mean = "mean", count = "numpos", max = "max", min = "min",
               sd = "sd", sum = "sum")

#' Aggregate a network by a node attribute
#'
#' UCINET: Transform | Aggregate | Block - Aggregate by Partitions. Collapses
#' the network to one row and column per group, holding a summary of the ties
#' between each pair of groups.
#'
#' Self-ties are left out unless `diagonal = TRUE`. That is the *matrix*
#' diagonal, not the block diagonal: the within-group cells are all still
#' there, it is only cell `(i,i)` that goes. Missing cells take no part in the
#' summary.
#'
#' @param net A network (any accepted form). 1-mode only; see the note below.
#' @param attribute The partition: a vector (named, or in node order), or the
#'   name of a column, looked up first in `net`'s attribute table and then in
#'   `data`. One group per distinct value.
#' @param method The summary: `"mean"` (the dialog's default, and what UCINET
#'   calls the density), `"sum"`, `"count"` (how many ties are above zero),
#'   `"max"`, `"min"` or `"sd"` (the population form).
#' @param diagonal Include the self-ties? `FALSE` by default, as the dialog's
#'   "utilize diagonal (reflexive ties)" checkbox is. Forced on for 2-mode
#'   data, where the diagonal is an ordinary cell.
#' @param data A data frame to look `attribute` up in.
#' @return An `xucinet` object with one row and column per group, labelled by
#'   the attribute's values and titled `<name>-blk`. A group pair with no
#'   usable cells comes back missing.
#' @seealso [xattributetomatrix()], which goes the other way.
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' as.matrix(xcombinenodes(campnet, gender))
#' as.matrix(xcombinenodes(campnet, gender, method = "sum"))
#' @export
xcombinenodes <- function(net, attribute,
                          method = c("mean", "sum", "count", "max", "min", "sd"),
                          diagonal = FALSE, data = NULL) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)

  if (identical(net$mode, "2-mode")) {
    stop("xcombinenodes() aggregates a 1-mode network by one partition; this ",
         "dataset is 2-mode.\n",
         "  UCINET's dialog takes a separate partition for the rows and the ",
         "columns there, which this function does not yet accept.", call. = FALSE)
  }

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  groups <- res$values
  if (length(groups) != nrow(as.matrix(net))) {
    stop("the partition has ", length(groups), " values but the network has ",
         nrow(as.matrix(net)), " nodes.", call. = FALSE)
  }

  out <- map_relations(net, function(m) aggregate_blocks(m, groups, method, diagonal))
  transformed(out, "-blk",
              paste0("aggregated by ",
                     if (nzchar(res$name)) res$name else expr,
                     " (", method, ", ", length(unique(groups[!is.na(groups)])),
                     " groups)"))
}

aggregate_blocks <- function(m, groups, method, diagonal) {
  keys <- sort(unique(groups[!is.na(groups)]))
  labs <- as.character(keys)
  g <- match(groups, keys)

  out <- matrix(NA_real_, length(keys), length(keys), dimnames = list(labs, labs))
  # `(i <> j) or diagok`: the matrix diagonal, not the block diagonal.
  usable <- !is.na(m)
  if (!diagonal) usable[row(m) == col(m)] <- FALSE
  usable[is.na(g), ] <- FALSE
  usable[, is.na(g)] <- FALSE

  for (bi in seq_along(keys)) {
    for (bj in seq_along(keys)) {
      take <- usable & outer(g == bi, g == bj, "&")
      take[is.na(take)] <- FALSE
      cells <- m[take]
      out[bi, bj] <- block_stat(cells, method)
    }
  }
  out
}

block_stat <- function(cells, method) {
  if (!length(cells)) return(NA_real_)
  switch(method,
         mean  = mean(cells),
         sum   = sum(cells),
         count = sum(cells > 0),
         max   = max(cells),
         min   = min(cells),
         # tunivariate's sd is sqrt(mcssq/sumwt), the population form.
         sd    = sqrt(mean((cells - mean(cells))^2)))
}
