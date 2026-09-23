# Reciprocity.
#
# UCINET: Network | Cohesion | Reciprocity (uc_reciprocitydlg.pas, repository
# StephenBorgatti/ucinet at commit c7b4956), with the whole-network ratios from
# tnodelist.getreciprocity in G2Tools/utnodelist.pas (repository
# StephenBorgatti/tools at commit 207958a).
#
# The dialog offers Dyad-based, Arc-based and Hybrid, and defaults to Hybrid
# (pMethod.ItemIndex = 2). Hybrid only differs from dyad-based for the
# group-level table, which this function does not produce: UCINET's own log
# says "in the hybrid method, the overall and node-level reciprocity values are
# the same as in the dyad-based model", so at the whole-network level there are
# two numbers, not three, and both are always reported.
#
# The routine does NOT dichotomize. It prints "Data are valued. Remember that
# xij = 3 will not match xji = 2" and then compares values, which matters
# because the two halves of its own report then disagree: the whole-network
# ratios test presence (isarc, i.e. > 0) while the node-level table tests
# equality of values. Ledger entry 16. Since 23 Sep 2026 the node-level table
# is xegoreciprocity()'s, and xegonet() carries its Symmetric column (SPEC
# addendum 23 Sep: a whole-network function has no node table).

#' Reciprocity
#'
#' UCINET: Network | Cohesion | Reciprocity. How much of a directed network is
#' returned in kind, as a proportion of dyads and as a proportion of arcs.
#'
#' Both ratios are always reported, because they answer different questions and
#' neither is a substitute for the other:
#'
#' * the **dyad** ratio is mutual dyads over the dyads with any tie at all,
#'   `M/(M+A)`, which is what "reciprocity" usually means for a whole network;
#' * the **arc** ratio is reciprocated arcs over all arcs, which runs higher
#'   because each mutual dyad contributes two arcs.
#'
#' UCINET's Hybrid method is the dyad ratio at this level; it differs only for
#' the group-by-group table, which this function does not produce.
#'
#' Valued data are **not** dichotomized, which follows the routine: a tie is
#' any positive value. UCINET's node-level reciprocity, which compares the two
#' values themselves, is [xegoreciprocity()], and its Symmetric proportion is a
#' column of [xegonet()]; see the differences ledger for why the two can
#' disagree on valued data.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param method Which ratio to print first: `"dyad"` (the default), `"arc"`,
#'   or `"hybrid"`, which is the dyad ratio. Both are always computed.
#' @return An object of class `c("xreciprocity", "xucinet_output")`.
#'   `$summary` holds both ratios, dyad then arc.
#' @seealso [xcohesion()], which reports the same two ratios among its 33
#'   measures; [xegoreciprocity()] for node-level reciprocity; and
#'   [xtransitivity()].
#' @examples
#' xreciprocity(campnet)
#' @export
xreciprocity <- function(net, method = c("dyad", "arc", "hybrid")) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  require_1mode(net, "xreciprocity()")

  m <- pick_relation(net, NULL)
  assumptions <- character(0)
  if (is_valued(m)) {
    assumptions <- c(
      assumptions,
      paste0("Data are valued and have not been dichotomized. The dyad and ",
             "arc ratios count a tie as any positive value."))
  }

  a <- m
  a[is.na(a)] <- 0
  diag(a) <- 0

  rec <- reciprocity_pair((a > 0) * 1)
  # Both ratios always; `method` chooses which is printed first (SPEC addendum,
  # 23 Sep 2026, item 5).
  summ <- list("Dyad Reciprocity" = rec[["dyad"]], "Arc Reciprocity" = rec[["arc"]])
  shown <- if (identical(method, "arc")) c("Arc Reciprocity", "Dyad Reciprocity")
           else c("Dyad Reciprocity", "Arc Reciprocity")

  new_xucinet_output("Reciprocity", net, summary = summ,
                     assumptions = assumptions, show_summary = shown,
                     subclass = "xreciprocity", call = match.call())
}

