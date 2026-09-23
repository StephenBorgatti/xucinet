# Structural holes.
#
# UCINET: Network | Ego Networks | Structural Holes. The form is
# uc_structuralholes.pas (TStructuralHolesDlg: OKBtnClick, runegonetworksingle,
# identifyegonet, and for the whole-network model runwholenetwork with the
# unit-level getpm, getredundancy and getconstraint), repository
# StephenBorgatti/ucinet at commit c7b4956. The ego-network model's arithmetic
# is tegonetstructuralholes in G1Tools/uEgonetStructuralHoles.pas (getpm,
# getdensity, getconstraint), ego betweenness is brandesbetweenness in
# G1Tools/ucentralitymeasures.pas, and the egonet definitions are whichegometh
# in G2Tools/uEgonet.pas, repository StephenBorgatti/tools at commit 207958a.
#
# Dialog defaults (uc_structuralholes.dfm):
#   Method                    Ego network model -- ties beyond egonet have no
#                             effect (pMethod.ItemIndex = 1)
#   How to define ego net     Union - either kind (ItemIndex = 2)
#   Diagonal valid            unchecked
#   Symmetrize by sum ala Burt  checked
#   Constraint: isolates / pendants set to      NA / NA
#   Effective size: isolates / pendants set to  0 / 1
#   Normalization             blank and hidden, so no custom normalization
#
# SPEC D7 lists constraint as a danger zone: igraph's constraint() is Burt's
# whole-network form on the raw (not summed) weights. See ledger entry 17.

#' Structural holes
#'
#' UCINET: Network | Ego Networks | Structural Holes. Burt's measures of how
#' far a node's contacts are redundant with one another: effective size,
#' efficiency, constraint and hierarchy, with the dyadic redundancy and
#' dyadic constraint matrices they are built from.
#'
#' Tie values are used as they are. With `symmetrize = TRUE` (the default, "ala
#' Burt") the strength of the relation between `i` and `j` is `z(i,j) + z(j,i)`;
#' `p(i,j)` is that strength as a share of `i`'s total, and `m(i,j)` as a share
#' of `i`'s strongest.
#'
#' * **Effective size** is the number of alters less their redundancy:
#'   the sum over alters `j` of `1 - sum_q p(i,q) m(j,q)`.
#' * **Efficiency** is effective size over the number of alters.
#' * **Constraint** sums, over alters `j`, `(p(i,j) + sum_q p(i,q) p(q,j))^2`,
#'   the dyadic constraint.
#' * **Hierarchy** is how unevenly constraint is spread across the alters
#'   (Burt's Coleman-Theil index), 1 for an ego with a single alter.
#'
#' Two models, as in the dialog. The **ego-network model** (the default)
#' computes everything inside each node's ego network, so ties from an alter to
#' someone outside it have no effect; it also reports ego betweenness,
#' log constraint, indirect constraint and the alters' density. The
#' **whole-network model** computes the proportions over the whole network, as
#' Burt's formulas are usually written, and prints the first four measures
#' plus indirect constraint, as UCINET does. Both models return the same eleven
#' columns: under the whole model, Degree and Ln(Constraint) follow its own
#' counts, and ego betweenness, density, average degree and open pairs, which
#' describe the ego network itself, are the same as under the ego model.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Structural Holes. *Method* is `method`, *How to
#' define ego net* is `ties`, *Symmetrize by sum ala Burt* is
#' `symmetrize`, *Diagonal valid* is `diagonal`, and the *Set isolates to* and
#' *Set pendants to* boxes are `isolate` and `pendant`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param method `"ego"` (the default, UCINET's ego network model) or
#'   `"whole"` (the whole network model).
#' @param ties Who counts as an alter in the ego-network model:
#'   `"any"` (the default, UCINET's *Union*), `"out"`, `"in"` or
#'   `"reciprocated"` (*Intersection*). The whole-network model uses it only
#'   for the ego-network columns.
#' @param symmetrize Add `z(i,j)` and `z(j,i)` before computing proportions,
#'   as Burt does? `TRUE` by default.
#' @param diagonal Keep the diagonal? `FALSE` by default.
#' @param isolate,pendant What to report for an ego with no alters, and for one
#'   with a single alter, in the ego-network model: a pair of values, effective
#'   size then constraint. UCINET's defaults are `c(0, NA)` and `c(1, NA)`.
#' @return An object of class `c("xstructuralholes", "xucinet_output")`.
#'   `$nodes` holds the measures in original node order under UCINET's
#'   headings; `$matrices` holds `Dyadic Redundancy` and `Dyadic Constraint`,
#'   ego by alter.
#' @seealso [xegonet()].
#' @examples
#' xstructuralholes(campnet)
#' xstructuralholes(campnet, method = "whole")
#' @export
xstructuralholes <- function(net, relation = NULL, method = c("ego", "whole"),
                             ties = c("any", "out", "in",
                                           "reciprocated"),
                             symmetrize = TRUE, diagonal = FALSE,
                             isolate = c(0, NA), pendant = c(1, NA)) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  ties <- match_ties(ties,
                     c("any", "out", "in", "reciprocated"),
                     "xstructuralholes()")
  if (length(isolate) != 2L || length(pendant) != 2L) {
    stop("xstructuralholes(): isolate and pendant are each a pair of values, ",
         "effective size then constraint, e.g. isolate = c(0, NA).", call. = FALSE)
  }
  rel <- ego_relation(net, relation, "xstructuralholes()")
  z <- rel$m
  # `net.recodena(0)`, then the diagonal zeroed unless it is valid.
  z[is.na(z)] <- 0
  if (!diagonal) diag(z) <- 0
  labels <- rownames(z)

  ego <- holes_ego(z, ties, symmetrize, isolate, pendant)
  res <- if (method == "ego") {
    ego
  } else {
    # The same eleven columns in both models (SPEC addendum, 23 Sep 2026,
    # item 5; `method` changes values, not columns). UCINET's whole-network
    # model prints five; the other six describe the ego network itself and do
    # not depend on how the proportions are taken, so they are the ego
    # model's, apart from Degree and Ln(Constraint), which follow the whole
    # model's own counts.
    w <- holes_whole(z, symmetrize)
    nodes <- ego$nodes
    nodes$Degree <- w$degree
    for (col in names(w$nodes)) nodes[[col]] <- w$nodes[[col]]
    nodes[["Ln(Constraint)"]] <- ifelse(!is.na(w$nodes$Constraint) &
                                          w$nodes$Constraint > 0,
                                        log(w$nodes$Constraint), NA_real_)
    list(nodes = nodes, dyred = w$dyred, dycon = w$dycon)
  }
  dimnames(res$dyred) <- dimnames(res$dycon) <- list(labels, labels)
  rownames(res$nodes) <- labels

  fields <- if (method == "ego") {
    c("Method:" = "Ego Network -- connections 2 links beyond ego are ignored",
      "Egonet definition:" = unname(c(any = "Union - either kind",
                                      out = "Outgoing ties only",
                                      `in` = "Incoming ties only",
                                      reciprocated = "Intersection - Reciprocated"
                                      )[ties]),
      "Constraint: isolates set to " = format(isolate[2]),
      "Constraint: pendants set to " = format(pendant[2]),
      "Effective size: isolates set to " = format(isolate[1]),
      "Effective size: pendants set to " = format(pendant[1]),
      "Diagonal valid?" = if (diagonal) "YES" else "NO",
      "Symmetrize (by sum):" = if (symmetrize) "YES" else "NO")
  } else {
    c("Method:" = "Whole Network",
      "Diagonal valid?" = if (diagonal) "YES" else "NO")
  }

  new_xucinet_output(
    "Structural Holes", net,
    nodes = res$nodes,
    matrices = list(`Dyadic Redundancy` = res$dyred,
                    `Dyadic Constraint` = res$dycon),
    assumptions = rel$note, fields = fields,
    nodes_title = "Structural Hole Measures",
    show_columns = if (method == "whole") c("EffSize", "Efficiency", "Constraint",
                                            "Hierarchy", "Indirects"),
    subclass = "xstructuralholes", call = match.call())
}

# ---- the ego-network model: tegonetstructuralholes ---------------------------

holes_ego <- function(z, ties, symmetrize, isolate, pendant) {
  n <- nrow(z)
  cols <- c("Degree", "EffSize", "Efficiency", "Constraint", "Hierarchy",
            "EgoBet", "Ln(Constraint)", "Indirects", "Density", "AvgDeg",
            "Open Pairs")
  meas <- matrix(NA_real_, n, length(cols), dimnames = list(NULL, cols))
  dyred <- matrix(0, n, n)
  dycon <- matrix(0, n, n)

  for (k in seq_len(n)) {
    # identifyegonet: ego first, then its alters in node order.
    alters <- switch(ties,
                     out = which(z[k, ] > 0),
                     `in` = which(z[, k] > 0),
                     any = which(z[k, ] > 0 | z[, k] > 0),
                     reciprocated = which(z[k, ] > 0 & z[, k] > 0))
    alters <- setdiff(alters, k)
    idx <- c(k, alters)
    h <- ego_holes(z[idx, idx, drop = FALSE], symmetrize)

    # `if holes.degree <= 1 then` the dialog's isolate and pendant values.
    if (h$degree <= 1) {
      special <- if (h$degree < 1) isolate else pendant
      h$effsize <- special[1]
      h$constraint <- special[2]
    }
    dyred[k, idx[-1]] <- h$pm[-1]
    dycon[k, idx[-1]] <- h$dc[-1]

    # EgoBet: brandesbetweenness on the ego network's arcs, as they are, ego
    # being node 1. Ordered pairs, not halved.
    egobet <- brandes((z[idx, idx, drop = FALSE] > 0) * 1)[1]
    lncon <- if (!is.na(h$constraint) && h$constraint > 0) log(h$constraint)
             else NA_real_
    meas[k, ] <- c(h$degree, h$effsize, h$efficiency, h$constraint,
                   h$hierarchy, egobet, lncon, h$indirect, h$density,
                   h$avgdeg, h$numholes)
  }
  list(nodes = as.data.frame(meas, check.names = FALSE),
       dyred = dyred, dycon = dycon)
}

# One ego network, ego in position 1. Returns everything run() computes.
ego_holes <- function(z, symmetrize) {
  n <- nrow(z)
  ego <- 1L
  zp <- if (symmetrize) z + t(z) else z
  diag(zp) <- 0
  p <- matrix(0, n, n)
  m <- matrix(0, n, n)
  degree <- 0
  for (i in seq_len(n)) {
    row <- zp[i, -i]
    s <- sum(row)
    mx <- if (length(row)) max(row) else -1e38
    deg <- sum(row > 0)
    if (s != 0 && mx != 0 && deg > 0) {
      p[i, -i] <- row / s
      m[i, -i] <- row / mx
    }
    if (i == ego) degree <- deg
  }

  # Effective size: sum over alters j with p(ego,j) > 0 of 1 - pm(j), where
  # pm(j) = sum over q != j of p(ego,q) m(j,q).
  pm <- numeric(n)
  effsize <- 0
  for (j in seq_len(n)[-ego]) {
    if (p[ego, j] > 0) {
      q <- seq_len(n)[-j]
      pm[j] <- sum(p[ego, q] * m[j, q])
      effsize <- effsize + 1 - pm[j]
    }
  }
  if (degree < 1) effsize <- 0
  efficiency <- if (degree > 0) effsize / degree else NA_real_

  # getdensity: ties among the alters, directed and dichotomized.
  alt <- seq_len(n)[-ego]
  nn <- n - 1
  a <- z[alt, alt, drop = FALSE]
  diag(a) <- 0
  ties <- sum(a > 0)
  if (nn > 1) {
    density <- ties / (nn * (nn - 1))
    avgdeg <- ties / nn
  } else {
    density <- NA_real_
    avgdeg <- 0
  }
  numholes <- nn * (nn - 1) - ties

  # getconstraint: dc(j) = (p(ego,j) + sum over q != ego, j of p(ego,q) p(q,j))^2
  dc <- numeric(n)
  indirect <- 0
  for (j in alt) {
    q <- setdiff(alt, j)
    ind <- sum(p[ego, q] * p[q, j])
    indirect <- indirect + ind
    dc[j] <- (ind + p[ego, j])^2
  }
  constraint <- sum(dc[alt])
  if (degree < 2) constraint <- NA_real_
  hierarchy <- if (!is.na(constraint) && constraint > 0 && degree > 1) {
    js <- alt[p[ego, alt] > 0]
    rel <- dc[js] * degree / constraint
    rel <- rel[rel > 1e-6]                     # `relij > singletolerance`
    sum(rel * log(rel)) / (degree * log(degree))
  } else if (degree == 1) 1 else NA_real_

  list(degree = degree, effsize = effsize, efficiency = efficiency,
       constraint = constraint, hierarchy = hierarchy, indirect = indirect,
       density = density, avgdeg = avgdeg, numholes = numholes,
       pm = pm, dc = dc)
}

# ---- the whole-network model: runwholenetwork --------------------------------

holes_whole <- function(z, symmetrize) {
  n <- nrow(z)
  zp <- if (symmetrize) z + t(z) else z
  diag(zp) <- 0
  zsum <- z + t(z)
  diag(zsum) <- 0
  si <- rowSums(zp)
  zmax <- apply(zp, 1, max)
  deg <- rowSums(zp > 0)

  # getpm: p always takes z(i,q) + z(q,i) over i's total, whatever
  # `symmetrize` says; m takes the (possibly unsymmetrized) value over i's
  # largest. Reproduced as written.
  p <- matrix(0, n, n)
  m <- matrix(0, n, n)
  for (i in seq_len(n)) {
    if (si[i] > 0) p[i, -i] <- zsum[i, -i] / si[i]
    if (zmax[i] > 0) m[i, -i] <- zp[i, -i] / zmax[i]
  }

  # getredundancy
  r <- matrix(0, n, n)
  effsize <- numeric(n)
  effic <- numeric(n)
  for (i in seq_len(n)) {
    js <- which(p[i, ] > 0 & seq_len(n) != i)
    for (j in js) {
      q <- setdiff(seq_len(n), c(i, j))
      r[i, j] <- sum(p[i, q] * m[j, q])
    }
    effsize[i] <- sum(1 - r[i, js])
    if (deg[i] > 0) effic[i] <- effsize[i] / deg[i]
  }

  # getconstraint
  con <- matrix(0, n, n)
  agcon <- numeric(n)
  ind <- numeric(n)
  hier <- rep(NA_real_, n)
  for (i in seq_len(n)) {
    js <- which(p[i, ] > 0 & seq_len(n) != i)
    for (j in js) {
      q <- setdiff(seq_len(n), c(i, j))
      isum <- sum(p[i, q] * p[q, j])
      ind[i] <- ind[i] + isum
      con[i, j] <- (p[i, j] + isum)^2
      agcon[i] <- agcon[i] + con[i, j]
    }
    if (agcon[i] > 0 && deg[i] > 1) {
      rel <- con[i, js] * deg[i] / agcon[i]
      rel <- rel[rel > 1e-6]
      hier[i] <- sum(rel * log(rel)) / (deg[i] * log(deg[i]))
    }
    if (deg[i] == 1) hier[i] <- 1
  }

  nodes <- data.frame(EffSize = effsize, Efficiency = effic,
                      Constraint = agcon, Hierarchy = hier, Indirects = ind,
                      check.names = FALSE)
  list(nodes = nodes, dyred = r, dycon = con, degree = deg)
}
