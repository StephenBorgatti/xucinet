# Density by groups.
#
# The density table of UCINET's Network | Mixing Tables (uc_MixingTables.pas,
# repository StephenBorgatti/ucinet at commit c7b4956): `getdensitymatrix` in
# G2Tools/unetmixingmodels.pas is nothing but `aggbygroups(y, x, p, p, ng, ng)`
# from G2Tools/uAggregate.pas with its default mean, which is the same call
# xcombinenodes() makes (tools commit 207958a).
#
# Division of work with xmixing() (Steve, 23 Sep 2026, STATUS Next 0(e)): this
# routine returns the density table and nothing else, as its name says; the
# observed mixing table and the expected values and ratios under UCINET's three
# models are xmixing()'s. UCINET prints all of them in one report: ledger
# entry 26.
#
# `test =` belongs to chapter 14: the permutation engine arrives with it.

#' Density by groups
#'
#' How densely each group ties to each other group: the mean tie value in each
#' block of the network, blocks being defined by a partition of the nodes. The
#' same table [xcombinenodes()] gives, and the one UCINET's Mixing Tables
#' prints as its density table.
#'
#' The observed mixing table, and what baseline models expect of it, are
#' [xmixing()]'s.
#'
#' @section UCINET equivalent:
#' Network | Mixing Tables, the density table.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param attribute The grouping: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data` (G3).
#' @param directed `NULL` (use the data as they are), `TRUE`, or `FALSE` to
#'   symmetrize by the maximum first.
#' @param test Run the permutation test? Not yet: it arrives with chapter 14,
#'   which brings the permutation engine.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xdensitybygroups", "xucinet_output")` whose
#'   `$matrices` holds `Density`.
#' @seealso [xmixing()] for observed and expected mixing, [xcombinenodes()],
#'   and [xhomophily()].
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' xdensitybygroups(campnet, gender)
#' @export
xdensitybygroups <- function(net, attribute, directed = NULL, test = FALSE,
                             data = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xdensitybygroups()")

  if (!isFALSE(test)) {
    stop("test = TRUE arrives with chapter 14.\n",
         "  The density models are a permutation test, and the permutation ",
         "engine is written with the chapter 14 routines.\n",
         "  Until then the table comes back without a p-value.",
         call. = FALSE)
  }

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  groups <- res$values
  m <- pick_relation(net, NULL)
  if (length(groups) != nrow(m)) {
    stop("the partition has ", length(groups), " values but the network has ",
         nrow(m), " nodes.", call. = FALSE)
  }

  assumptions <- character(0)
  if (isFALSE(directed) && !isTRUE(isSymmetric(unname(m)))) {
    m <- pmax(m, t(m))
    assumptions <- c(assumptions, "Symmetrized with the maximum.")
  }

  keys <- sort(unique(groups[!is.na(groups)]))
  labs <- as.character(keys)
  dens <- aggregate_blocks(m, groups, "mean", diagonal = FALSE)
  dimnames(dens) <- list(labs, labs)

  new_xucinet_output(
    "Density by groups", net,
    matrices = list(Density = dens),
    assumptions = assumptions, subclass = "xdensitybygroups",
    call = match.call())
}
