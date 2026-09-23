# Node-level reciprocity.
#
# UCINET: Network | Ego Networks | Egonet Reciprocity, which opens the same
# dialog as Network | Cohesion | Reciprocity (uc_reciprocitydlg.pas,
# runindividuals; repository StephenBorgatti/ucinet at commit c7b4956). Its
# node-level table used to be part of xreciprocity(); since 23 Sep 2026 it is
# a function of its own, because a whole-network function has no node table
# (SPEC addendum 23 Sep, level of analysis; Steve's answer on where it goes).
# xegonet() carries the Symmetric column.
#
# The table does not dichotomize: a pair is symmetric when the two values are
# equal, so on valued data x[i,j] = 3 and x[j,i] = 2 are not symmetric although
# xreciprocity() counts them as reciprocated. Ledger entry 16.

#' Node-level reciprocity
#'
#' UCINET: Network | Ego Networks | Egonet Reciprocity. For each node, how its
#' ties with its contacts (everyone it has a tie with, either way) split into
#' symmetric and non-symmetric pairs, and which way the non-symmetric ones run.
#'
#' The six columns, UCINET's, all proportions:
#'
#' \describe{
#'   \item{Symmetric}{Contacts whose tie with the node has the same value both
#'     ways.}
#'   \item{Non-Symmetric}{The rest of the contacts.}
#'   \item{Out/NonSym}{Of the non-symmetric pairs, the share where the node
#'     sends a tie.}
#'   \item{In/NonSym}{Of the non-symmetric pairs, the share where it receives
#'     one.}
#'   \item{Sym/Out}{Of the node's outgoing ties, the share that are symmetric.}
#'   \item{Sym/In}{Of its incoming ties, the share that are symmetric.}
#' }
#'
#' A pair is symmetric when the two values are equal, not merely both present,
#' as in UCINET; on binary data the two are the same thing.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Egonet Reciprocity (the node-level table of
#' Network | Cohesion | Reciprocity).
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An object of class `c("xegoreciprocity", "xucinet_output")` with
#'   the six columns in `$nodes`, in original node order.
#' @seealso [xreciprocity()] for the whole network, [xegonet()].
#' @examples
#' xegoreciprocity(campnet)
#' @export
xegoreciprocity <- function(net, relation = NULL) {
  net <- xnet(net, substitute(net))
  rel <- ego_relation(net, relation, "xegoreciprocity()")
  m <- rel$m
  assumptions <- rel$note
  if (is_valued(m)) {
    assumptions <- c(assumptions, paste0(
      "Data are valued. A pair is symmetric only when the two values are ",
      "equal, so x[i,j] = 3 does not match x[j,i] = 2."))
  }
  a <- m
  a[is.na(a)] <- 0
  diag(a) <- 0
  new_xucinet_output(
    "Reciprocity", net, nodes = reciprocity_nodes(a, m),
    assumptions = assumptions,
    nodes_title = "Node-level Reciprocity Statistics -- All values are Proportions",
    subclass = "xegoreciprocity", call = match.call())
}

# runindividuals: six proportions per node, over the alters ego has any tie
# with in either direction. Asymmetry is inequality of the two values, not of
# their presence.
reciprocity_nodes <- function(a, m) {
  n <- nrow(a)
  labs <- rownames(a)
  out <- data.frame(row.names = labs)
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
