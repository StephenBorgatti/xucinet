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
# equality of values. Ledger entry 16.

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
#' Valued data are **not** dichotomized, which follows the routine. Its two
#' halves then use different tests, and that is UCINET's behaviour rather than
#' an oversight here: see the differences ledger.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param method Which ratio to put first in the report: `"dyad"` (the
#'   default), `"arc"`, or `"hybrid"`, which is the dyad ratio.
#' @return An object of class `c("xreciprocity", "xucinet_output")`.
#'   `$summary` holds both ratios; `$nodes` holds UCINET's six node-level
#'   proportions, in its order and under its headings.
#' @seealso [xcohesion()], which reports the same two ratios among its 33
#'   measures, and [xtransitivity()].
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
             "arc ratios count a tie as any positive value, while the ",
             "node-level table counts a pair as symmetric only when the two ",
             "values are equal, so x[i,j] = 3 does not match x[j,i] = 2."))
  }

  a <- m
  a[is.na(a)] <- 0
  diag(a) <- 0

  rec <- reciprocity_pair((a > 0) * 1)
  dyad <- rec[["dyad"]]
  arc <- rec[["arc"]]
  # `method` chooses the order, not the content.
  summ <- if (identical(method, "arc")) {
    list("Arc Reciprocity" = arc, "Dyad Reciprocity" = dyad)
  } else {
    list("Dyad Reciprocity" = dyad, "Arc Reciprocity" = arc)
  }

  new_xucinet_output("Reciprocity", net, nodes = reciprocity_nodes(a, m),
                     summary = summ, assumptions = assumptions,
                     subclass = "xreciprocity",
                     nodes_title = paste0("Node-level Reciprocity Statistics ",
                                          "-- All values are Proportions"))
}

# runindividuals: six proportions per node, over the alters ego has any tie
# with in either direction. Asymmetry is inequality of the two values, not of
# their presence.
reciprocity_nodes <- function(a, m) {
  n <- nrow(a)
  labs <- rownames(a)
  out <- data.frame(Node = labs, stringsAsFactors = FALSE)
  cols <- matrix(NA_real_, n, 6)

  vals <- m
  vals[is.na(vals)] <- 0
  for (i in seq_len(n)) {
    j <- setdiff(seq_len(n), i)
    contact <- a[i, j] > 0 | a[j, i] > 0
    j <- j[contact]
    if (!length(j)) next

    deg <- length(j)
    out_tie <- a[i, j] > 0
    in_tie <- a[j, i] > 0
    uneven <- vals[i, j] != vals[cbind(j, rep(i, length(j)))]

    asym <- sum(uneven)
    cols[i, 2] <- asym / deg                       # Non-Symmetric
    cols[i, 1] <- 1 - cols[i, 2]                   # Symmetric
    if (asym > 0) {
      cols[i, 3] <- sum(uneven & out_tie) / asym   # Out/NonSym
      cols[i, 4] <- sum(uneven & in_tie) / asym    # In/NonSym
    }
    if (sum(out_tie) > 0) {
      cols[i, 5] <- 1 - sum(uneven & out_tie) / sum(out_tie)   # Sym/Out
    }
    if (sum(in_tie) > 0) {
      cols[i, 6] <- 1 - sum(uneven & in_tie) / sum(in_tie)     # Sym/In
    }
  }

  out[["Symmetric"]] <- cols[, 1]
  out[["Non-Symmetric"]] <- cols[, 2]
  out[["Out/NonSym"]] <- cols[, 3]
  out[["In/NonSym"]] <- cols[, 4]
  out[["Sym/Out"]] <- cols[, 5]
  out[["Sym/In"]] <- cols[, 6]
  out
}
