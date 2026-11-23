# The measures of the centrality suite that have no single-measure routine of
# their own yet: 2-local eigenvector, ARD, 2-step betweenness, k-step reach,
# k-coreness and fragmentation centrality. Ported from UCINET's suite engine,
# G2Tools/umulticent.pas (tmccalc.computeLocal2, computeArd, compute2StepBet,
# computeKstep, computeKcore, computeFrag), tools repo commit 6b6a335, and
# G2Tools/ug2centralitymeasures.pas (getOutK_LocalEigenvector).
#
# As in umulticent, the 2-local eigenvector uses the tie values and everything
# else is computed on the dichotomized graph (value > 0 is a tie, diagonal
# ignored). All scores are raw, which is what mcent writes by default and what
# xcentrality() reports.

# k-local eigenvector: iterated degree, A^k 1 (out) or (A')^k 1 (in). With k = 2
# a node's score is the sum, over its alters, of the alters' degrees, weighted by
# the tie values.
mc_local2 <- function(x, direction = c("out", "in")) {
  direction <- match.arg(direction)
  x[is.na(x)] <- 0
  diag(x) <- 0
  if (direction == "in") x <- t(x)
  v <- rep(1, nrow(x))
  for (it in 1:2) v <- as.vector(x %*% v)
  v
}

# Average reciprocal distance: the mean, over the n - 1 others, of 1/d.
# Unreachable nodes contribute 0. `d` is geodesics() output (NA = unreachable).
mc_ard <- function(d, direction = c("out", "in")) {
  direction <- match.arg(direction)
  n <- nrow(d)
  r <- 1 / d
  r[is.na(r) | !is.finite(r)] <- 0
  diag(r) <- 0
  s <- if (direction == "out") rowSums(r) else colSums(r)
  if (n > 1) s / (n - 1) else s
}

# Number of nodes reachable in at most k steps (out: from the node; in: to it).
mc_kstep <- function(d, k = 2, direction = c("out", "in")) {
  direction <- match.arg(direction)
  hit <- !is.na(d) & d > 0 & d <= k
  diag(hit) <- FALSE
  if (direction == "out") rowSums(hit) else colSums(hit)
}

# Betweenness restricted to geodesics of length 2. A pair (i, j) at distance 2
# is joined by exactly the paths i -> w -> j through their common neighbours, so
# each such w receives 1 / (number of common neighbours). Ordered pairs; halved
# for undirected data, as compute2StepBet does.
mc_twostepbet <- function(a, d, directed) {
  n <- nrow(a)
  b <- numeric(n)
  pairs <- which(!is.na(d) & d == 2, arr.ind = TRUE)
  for (p in seq_len(nrow(pairs))) {
    i <- pairs[p, 1]; j <- pairs[p, 2]
    w <- which(a[i, ] > 0 & a[, j] > 0)
    w <- w[w != i & w != j]
    if (length(w)) b[w] <- b[w] + 1 / length(w)
  }
  if (!directed) b <- b / 2
  b
}

# Core numbers by peeling (Batagelj and Zaversnik). `deg` is the degree to peel
# by; removing node v lowers by one the degree of every node in `upd[[v]]`.
#   undirected: deg = degree,    upd = neighbours
#   in-core:    deg = indegree,  upd = v's out-neighbours
#   out-core:   deg = outdegree, upd = v's in-neighbours
# The result does not depend on which minimum-degree node is peeled first.
mc_peel <- function(deg, upd) {
  n <- length(deg)
  alive <- rep(TRUE, n)
  core <- numeric(n)
  k <- 0
  for (step in seq_len(n)) {
    live <- which(alive)
    v <- live[which.min(deg[live])]
    k <- max(k, deg[v])
    core[v] <- k
    alive[v] <- FALSE
    nb <- upd[[v]]
    nb <- nb[alive[nb]]
    deg[nb] <- deg[nb] - 1
  }
  core
}

mc_kcore <- function(a, type = c("undirected", "in", "out")) {
  type <- match.arg(type)
  n <- nrow(a)
  if (type == "undirected") {
    return(mc_peel(rowSums(a), lapply(seq_len(n), function(v) which(a[v, ] > 0))))
  }
  if (type == "in") {
    mc_peel(colSums(a), lapply(seq_len(n), function(v) which(a[v, ] > 0)))
  } else {
    mc_peel(rowSums(a), lapply(seq_len(n), function(v) which(a[, v] > 0)))
  }
}

# Fragmentation centrality (Borgatti's KeyPlayer, KPP-Neg): how much more
# fragmented the network becomes when the node is removed.
#   Frag   = change in the proportion of ordered pairs that cannot reach each
#            other;
#   DwFrag = change in distance-weighted fragmentation, 1 - mean(1/d).
# Both are over ordered pairs, n(n - 1) before removal and (n - 1)(n - 2)
# after, so they can be negative: removing a peripheral node removes pairs that
# were connected and leaves the rest no worse off.
#
# As in computeFrag, a node with zero betweenness lies on no geodesic, so
# removing it changes no distance among the others: its scores come from the
# baseline less its own row and column, without a new search.
mc_frag <- function(a, d, betweenness = NULL) {
  n <- nrow(a)
  if (n < 3) return(list(Frag = rep(NA_real_, n), DwFrag = rep(NA_real_, n)))
  frag_parts <- function(dd) {
    off <- row(dd) != col(dd)
    reach <- !is.na(dd) & off
    c(unreach = sum(is.na(dd) & off), recip = sum(1 / dd[reach]))
  }
  base <- frag_parts(d)
  np <- n * (n - 1); np2 <- (n - 1) * (n - 2)
  f0 <- base[["unreach"]] / np
  dw0 <- 1 - base[["recip"]] / np
  rd <- 1 / d
  rd[is.na(rd) | !is.finite(rd)] <- 0
  diag(rd) <- 0
  un <- is.na(d)
  diag(un) <- FALSE
  fr <- dw <- numeric(n)
  for (u in seq_len(n)) {
    p <- if (!is.null(betweenness) && betweenness[u] == 0) {
      c(unreach = base[["unreach"]] - sum(un[u, ]) - sum(un[, u]),
        recip = base[["recip"]] - sum(rd[u, ]) - sum(rd[, u]))
    } else {
      frag_parts(geodesics(a[-u, -u, drop = FALSE]))
    }
    fr[u] <- p[["unreach"]] / np2 - f0
    dw[u] <- (1 - p[["recip"]] / np2) - dw0
  }
  list(Frag = fr, DwFrag = dw)
}
