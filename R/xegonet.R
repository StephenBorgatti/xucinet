# Egonet basic measures.
#
# UCINET: Network | Ego Networks | Egonet Basic Measures. The menu item calls
# EgoNetwork in Xegonet.pas (procedures askparameters, densitydsl and
# EgoNetwork), with the dialog in EgoNetDlg.dfm, repository
# StephenBorgatti/ucinet at commit c7b4956. Ego betweenness is
# calculatebrandesbetweenness in G1Tools/ubetween.pas and the alter geodesics
# bFloyd in G1Tools/ugeodist.pas, repository StephenBorgatti/tools at commit
# 207958a.
#
# The dialog has one option, the "Ego network type" combo (IN-NEIGHBORHOOD,
# OUT-NEIGHBORHOOD, UNDIRECTED; default UNDIRECTED). It has no include-ego and
# no directed option, although the crosswalk signature gave both; the function
# follows the dialog (issue #14).
#
# One departure, UCINET issue 17: densitydsl sets the undefined measures of an
# ego with no alters to missing and then jumps past the lines that store them,
# so UCINET reports zeros for isolates. Here they are missing. The same issue
# covers AvgRecipDist for an ego with one alter, which UCINET reports as 0 over
# no pairs at all.

#' Egonet basic measures
#'
#' UCINET: Network | Ego Networks | Egonet Basic Measures. Sixteen descriptions
#' of each node's ego network - its size, how densely the alters are tied to
#' each other, how far ego reaches in two steps, and how much ego brokers
#' between alters who are not tied.
#'
#' The ego network of a node is its alters and the ties among them. Which nodes
#' count as alters is `ties`: anyone ego is tied to in either direction
#' (the default), only those ego sends ties to, or only those ego receives them
#' from. The data are dichotomized at > 0, as UCINET does.
#'
#' The columns, with UCINET's headings, for an ego with `k` alters in a
#' network of `N` nodes:
#'
#' \describe{
#'   \item{Size}{`k`.}
#'   \item{Ties}{Ties among the alters, counted directionally.}
#'   \item{Pairs}{Ordered pairs of alters, `k(k-1)`.}
#'   \item{Density}{Ties divided by Pairs, as a percentage.}
#'   \item{AvgRecipDist}{Average of the reciprocal of the geodesic distance
#'     between alters, counting only paths among the alters; 0 for a pair that
#'     cannot reach each other.}
#'   \item{Diameter}{Longest geodesic among the alters; missing when some pair
#'     cannot reach the other.}
#'   \item{nWeakComp}{Number of weak components among the alters.}
#'   \item{CompRatio}{`(nWeakComp - 1)/(Size - 1)`, as a percentage.}
#'   \item{2StepReach}{Nodes within two steps of ego (ego excluded).}
#'   \item{2StepPct}{2StepReach divided by `N - 1`, as a percentage.}
#'   \item{ReachEffic}{2StepReach divided by the most it could be given the
#'     alters' degrees, as a percentage.}
#'   \item{Broker}{Pairs of alters not directly connected.}
#'   \item{nBroker}{Broker divided by the number of (unordered) pairs.}
#'   \item{nClosed}{UCINET's column: the number of ties among alters, the same
#'     number as Ties. UCINET's footnote calls it the number of closed triads
#'     ego is in, which on symmetric data is half of it.}
#'   \item{EgoBetween}{Betweenness of ego within its own ego network.}
#'   \item{nEgoBetween}{EgoBetween normalized, as a percentage.}
#'   \item{Symmetric}{The proportion of ego's contacts (either direction) whose
#'     tie with ego has the same value both ways: UCINET's node-level
#'     reciprocity, computed on the values before dichotomizing. The other five
#'     node-level reciprocity proportions are [xegoreciprocity()]'s.}
#' }
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Egonet Basic Measures. The combo box *Ego network
#' type* is `ties`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param ties `"any"` (UCINET's default, UNDIRECTED), `"out"`
#'   (OUT-NEIGHBORHOOD) or `"in"` (IN-NEIGHBORHOOD).
#' @return An object of class `c("xegonet", "xucinet_output")`. `$nodes` has
#'   one row per ego in original node order and the seventeen columns above.
#' @seealso [xstructuralholes()] for effective size and constraint.
#' @examples
#' xegonet(campnet)
#' xegonet(campnet, ties = "out")
#' @export
xegonet <- function(net, relation = NULL,
                    ties = c("any", "out", "in")) {
  net <- xnet(net, substitute(net))
  ties <- match_ties(ties, c("any", "out", "in"), "xegonet()")
  rel <- ego_relation(net, relation, "xegonet()")
  m <- rel$m
  assumptions <- rel$note

  # `if m.cell[i,j] > 1 then begin m.cell[i,j] := 1; bin := false end`. A
  # missing cell is no tie.
  m[is.na(m)] <- 0
  # Node-level reciprocity (Steve, 23 Sep 2026): UCINET's Symmetric proportion,
  # on the values, before they are dichotomized.
  a0 <- m
  diag(a0) <- 0
  symmetric <- reciprocity_nodes(a0, m)$Symmetric
  if (any(m != 0 & m != 1)) {
    assumptions <- c(assumptions, "Data matrix was dichotomized.")
  }
  b <- (m > 0) * 1
  n <- nrow(b)
  cols <- c("Size", "Ties", "Pairs", "Density", "AvgRecipDist", "Diameter",
            "nWeakComp", "CompRatio", "2StepReach", "2StepPct", "ReachEffic",
            "Broker", "nBroker", "nClosed", "EgoBetween", "nEgoBetween")
  x <- matrix(NA_real_, n, length(cols), dimnames = list(rownames(m), cols))

  for (i in seq_len(n)) {
    others <- setdiff(seq_len(n), i)
    alters <- switch(ties,
                     out = others[b[i, others] > 0],
                     `in` = others[b[others, i] > 0],
                     any = others[b[i, others] > 0 | b[others, i] > 0])
    x[i, ] <- egonet_row(b, i, alters)
  }

  new_xucinet_output(
    "Ego Networks: Basic Measures", net,
    nodes = data.frame(as.data.frame(x, check.names = FALSE),
                       Symmetric = symmetric, check.names = FALSE),
    assumptions = assumptions,
    fields = c("Ego network type:" = toupper(switch(ties,
                                                   any = "undirected",
                                                   out = "out-neighborhood",
                                                   `in` = "in-neighborhood"))),
    nodes_title = "Density Measures",
    subclass = "xegonet", call = match.call())
}

# densitydsl for one ego. `b` is the dichotomized network, `alters` ego's
# neighbourhood in node order.
egonet_row <- function(b, ego, alters) {
  n <- nrow(b)
  k <- length(alters)
  if (k == 0L) {
    # What densitydsl meant to store (UCINET issue 17): counts are zero, every
    # ratio over no pairs is missing.
    return(c(0, 0, 0, NA, NA, NA, 0, NA, 0, 0, NA, 0, NA, 0, 0, NA))
  }
  t <- b[alters, alters, drop = FALSE]
  diag(t) <- 0
  nties <- sum(t)
  npairs <- k * (k - 1)
  density <- if (npairs > 0) 100 * nties / npairs else NA_real_
  offdiag <- row(t) != col(t)
  broker <- sum(t[offdiag] == 0) / 2

  # The two-step list and each alter's degree: every j other than ego tied to
  # the alter in either direction. A self-loop on the alter counts in its
  # degree, as it does in the Delphi loop.
  notego <- setdiff(seq_len(n), ego)
  reached <- alters
  degsum <- 0
  for (ii in alters) {
    nb <- notego[b[ii, notego] > 0 | b[notego, ii] > 0]
    degsum <- degsum + length(nb)
    reached <- union(reached, nb)
  }
  twostep <- length(reached)
  reach <- 100 * twostep / (n - 1)
  efficiency <- if (degsum > 0) 100 * twostep / (degsum + k) else NA_real_

  numweak <- length(unique(components_of(pmax(t, t(t)))))
  cratio <- if (k > 1) 100 * (numweak - 1) / (k - 1) else NA_real_

  # Ego betweenness: alters then ego, directed ties as they are. Brandes over
  # ordered pairs, halved when that network is symmetric; the normalized value
  # is taken from the unhalved sum over (N-1)(N-2), N = k + 1.
  enet <- matrix(0, k + 1, k + 1)
  enet[seq_len(k), seq_len(k)] <- t
  enet[k + 1, seq_len(k)] <- b[ego, alters]
  enet[seq_len(k), k + 1] <- b[alters, ego]
  cb <- brandes(enet)[k + 1]
  sym <- isSymmetric(enet)
  egobet <- if (sym) cb / 2 else cb
  nn <- k + 1
  den <- (nn - 1) * (nn - 2)
  negobet <- if (den > 0) 100 * cb / den else NA_real_

  # bFloyd on the alters alone, directed. Unreachable pairs are set to k and
  # skipped by `if d < n then avgrdist += 1/d`.
  d <- geodesics(t)
  nmiss <- sum(is.na(d[offdiag]))
  if (npairs > 0) {
    dd <- d[offdiag]
    avgrdist <- sum(1 / dd[!is.na(dd)]) / npairs
    diam <- if (nmiss > 0) NA_real_ else max(dd)
  } else {
    avgrdist <- NA_real_                       # UCINET issue 17: it reports 0
    diam <- 0
  }

  c(k, nties, npairs, density, avgrdist, diam, numweak, cratio, twostep, reach,
    efficiency, broker, if (npairs > 0) 2 * broker / npairs else NA_real_,
    nties, egobet, negobet)
}
