# Shared machinery for the chapter 9 centrality routines.
#
# Implemented natively rather than delegated. SPEC D7 names closeness on
# disconnected graphs, betweenness normalization and eigenvector scaling as
# danger zones where igraph and UCINET differ in conventions rather than in
# arithmetic, and four of the chapter's routines have no igraph equivalent at
# all. Getting the same numbers by accident is not the same as agreeing.

# Adjacency as UCINET's routines see it: dichotomised at > 0, diagonal and
# missing values ignored. `copyfromtmat` in the Delphi does exactly this, and
# every routine that calls it inherits the behaviour, which is why it is here
# rather than repeated.
adjacency <- function(m) {
  a <- (m > 0) * 1
  a[is.na(a)] <- 0
  diag(a) <- 0
  storage.mode(a) <- "double"
  a
}

# Geodesic distances by breadth-first search from every node.
#
# Unreachable pairs come back NA rather than Inf, which is what UCINET's geo()
# writes into a dataset and what its own log calls "Undefined:NA / Graph is
# disconnected. Undefined distances were assigned missing values." Every
# convention for handling them is then a substitution on top of this, which
# keeps the substitution visible instead of buried in the search.
geodesics <- function(a) {
  n <- nrow(a)
  out <- matrix(NA_real_, n, n, dimnames = dimnames(a))
  nbr <- lapply(seq_len(n), function(i) which(a[i, ] > 0))
  for (s in seq_len(n)) {
    d <- rep(NA_real_, n)
    d[s] <- 0
    frontier <- s
    step <- 0
    while (length(frontier)) {
      step <- step + 1
      nxt <- unique(unlist(nbr[frontier], use.names = FALSE))
      nxt <- nxt[is.na(d[nxt])]
      d[nxt] <- step
      frontier <- nxt
    }
    out[s, ] <- d
  }
  out
}

# Brandes betweenness, the directed form: every ordered pair counted once.
#
# UCINET calls `getbetweenness(cb, false)` and then halves the result when the
# data are symmetric, rather than running a symmetric variant, so that is the
# shape reproduced here - one function, halved by the caller.
brandes <- function(a) {
  n <- nrow(a)
  cb <- numeric(n)
  nbr <- lapply(seq_len(n), function(i) which(a[i, ] > 0))
  for (s in seq_len(n)) {
    sigma <- numeric(n); sigma[s] <- 1
    d <- rep(-1, n);     d[s] <- 0
    pred <- vector("list", n)
    order_seen <- integer(0)
    queue <- s
    while (length(queue)) {
      v <- queue[1L]; queue <- queue[-1L]
      order_seen <- c(order_seen, v)
      for (w in nbr[[v]]) {
        if (d[w] < 0) {
          d[w] <- d[v] + 1
          queue <- c(queue, w)
        }
        if (d[w] == d[v] + 1) {
          sigma[w] <- sigma[w] + sigma[v]
          pred[[w]] <- c(pred[[w]], v)
        }
      }
    }
    delta <- numeric(n)
    for (w in rev(order_seen)) {
      for (v in pred[[w]]) {
        delta[v] <- delta[v] + (sigma[v] / sigma[w]) * (1 + delta[w])
      }
      if (w != s) cb[w] <- cb[w] + delta[w]
    }
  }
  cb
}

# The principal eigenvector, scaled UCINET's way.
#
# `runeigencent` in Xdpmat.pas symmetrizes by maximum first and says so in the
# log ("Note: Data automatically symmetrized by maximum"), reports the principal
# eigenvalue, and returns a vector whose sign is flipped positive. UCINET's
# 2-mode routine forgets that last step and returns negatives, which is issue 2
# on the UCINET list; we do it everywhere.
principal_eigen <- function(a) {
  e <- eigen(a, symmetric = isSymmetric(unname(a)))
  k <- which.max(Re(e$values))
  v <- Re(e$vectors[, k])
  if (sum(v) < 0) v <- -v
  list(value = Re(e$values[k]), vector = v)
}

# Symmetrize by maximum, which is what UCINET does before any measure that
# needs an undirected graph, and record it the way UCINET records it.
symmetrize_max <- function(m) pmax(m, t(m))

# Connected components of a symmetric adjacency matrix, as a vector of labels.
components_of <- function(a) {
  n <- nrow(a)
  comp <- integer(n)
  k <- 0L
  for (s in seq_len(n)) {
    if (comp[s] != 0L) next
    k <- k + 1L
    frontier <- s
    comp[s] <- k
    while (length(frontier)) {
      nxt <- unique(unlist(lapply(frontier, function(i) which(a[i, ] > 0)),
                           use.names = FALSE))
      nxt <- nxt[comp[nxt] == 0L]
      comp[nxt] <- k
      frontier <- nxt
    }
  }
  comp
}

# The Everett-Borgatti lambda-squared score, which is what UCINET falls back to
# when the graph is disconnected.
#
# A principal eigenvector is only defined up to a component: run it on a
# disconnected graph and one component takes everything while the rest come back
# zero, which is an artefact of the arithmetic and not a statement about the
# network. utDisconnectedEigenvector.pas scores each component separately and
# puts them on a common footing. Column 11 of its table, "BetaMatch2", is the
# one runeigencent uses:
#
#   score(i) = lambda_k^2 * sum(v_k) * v_k(i)
#
# for node i in component k, where v_k is the unit principal eigenvector of that
# component and lambda_k its principal eigenvalue.
#
# Checked by hand against g9_disc before it was written: the four-leaf star has
# lambda 2 and eigenvector sum 2.1213, giving the hub 4 * 2.1213 * 0.7071 = 6
# and each leaf 3; the triangle gives 4; the four-path gives 1.894. Those are
# UCINET's numbers to every digit it prints.
eb_lambda_squared <- function(a) {
  comp <- components_of(a)
  out <- numeric(nrow(a))
  for (k in unique(comp)) {
    idx <- which(comp == k)
    if (length(idx) == 1L) { out[idx] <- 0; next }
    e <- principal_eigen(a[idx, idx, drop = FALSE])
    out[idx] <- e$value^2 * sum(e$vector) * e$vector
  }
  out
}

# How many components have more than one node. UCINET switches method on this
# rather than on the raw component count, so a graph that is connected apart
# from a few isolates still takes the ordinary eigenvector path.
n_nontrivial <- function(comp) sum(table(comp) > 1)

# The maximum betweenness a node can reach in a bipartite graph, given the size
# of its own vertex set and of the other one. Ported from getmax() in
# uc_twomodecentrality.pas:
#
#   s = (n1 - 1) div n2 ;  t = (n1 - 1) mod n2
#   n2^2 (s+1)^2 + n2 (s+1)(2t - s - 1) - t(2s - t + 3)
#
# This is NOT the formula in Borgatti and Everett (1997), Social Networks 19,
# p. 256, which gives two branches. Its n_o <= n_i branch is the same function -
# it is this one with s = 0, which the algebra confirms - but its n_o > n_i
# branch, 2(n_o - 1)(n_i - 1), disagrees. For davis rows, own set 18 and other
# set 14, the paper gives 442 where this gives 890/2 = 445, and 445 is what
# UCINET reports. The paper says a proof "will be the subject of a separate
# paper", so this is presumably the corrected general result; either way the
# fixture agrees with the code and not with the published branch.
bipartite_max_betweenness <- function(n_own, n_other) {
  s <- (n_own - 1) %/% n_other
  t <- (n_own - 1) %% n_other
  n_other^2 * (s + 1)^2 + n_other * (s + 1) * (2 * t - s - 1) -
    t * (2 * s - t + 3)
}

# The bipartite graph behind a 2-mode matrix: rows first, then columns.
bipartite <- function(m) {
  nr <- nrow(m); nc <- ncol(m)
  b <- matrix(0, nr + nc, nr + nc)
  b[seq_len(nr), nr + seq_len(nc)] <- m
  b[nr + seq_len(nc), seq_len(nr)] <- t(m)
  b
}

# Brandes again, returning edge betweenness beside node betweenness. The edge
# figure is a by-product of the same dependency accumulation: the share of a
# pair's shortest paths that uses edge (v, w) is exactly the term added to
# delta[v] on w's behalf. Induced centrality is the only routine that needs it,
# which is why it is separate from brandes() rather than always computed.
brandes_edges <- function(a) {
  n <- nrow(a)
  cb <- numeric(n)
  eb <- matrix(0, n, n)
  nbr <- lapply(seq_len(n), function(i) which(a[i, ] > 0))
  for (s in seq_len(n)) {
    sigma <- numeric(n); sigma[s] <- 1
    d <- rep(-1, n);     d[s] <- 0
    pred <- vector("list", n)
    seen <- integer(0)
    queue <- s
    while (length(queue)) {
      v <- queue[1L]; queue <- queue[-1L]
      seen <- c(seen, v)
      for (w in nbr[[v]]) {
        if (d[w] < 0) { d[w] <- d[v] + 1; queue <- c(queue, w) }
        if (d[w] == d[v] + 1) {
          sigma[w] <- sigma[w] + sigma[v]
          pred[[w]] <- c(pred[[w]], v)
        }
      }
    }
    delta <- numeric(n)
    for (w in rev(seen)) {
      for (v in pred[[w]]) {
        c_ <- (sigma[v] / sigma[w]) * (1 + delta[w])
        delta[v] <- delta[v] + c_
        eb[v, w] <- eb[v, w] + c_
      }
      if (w != s) cb[w] <- cb[w] + delta[w]
    }
  }
  list(node = cb, edge = eb)
}

# The whole-network statistics induced centrality differences.
#
# From uc_ContributionCentrality.pas. Two things there are easy to get wrong and
# both were got wrong before the source was read:
#
#   - unreachable distances are set to n, not skipped, so removing a cut vertex
#     RAISES the distance total rather than lowering it;
#   - `ignore` excludes a node from the sums but the node stays in the graph.
#     buildnet() calls isolatenode(), which strips a node's edges and leaves it
#     in place, so n is the same on both sides of the subtraction.
#
# The comparison is deliberately asymmetric: the full-graph figures are computed
# once with nothing ignored, and each isolated-graph figure ignores the node
# that was isolated.
induced_stats <- function(a, ignore = 0L, k = 3L) {
  n <- nrow(a)
  d <- geodesics(a)
  nmiss <- sum(is.na(d) & row(d) != col(d))
  d[is.na(d)] <- n                     # bfsdistance's substitute for unreachable

  keep <- if (ignore > 0L) setdiff(seq_len(n), ignore) else seq_len(n)
  dk <- d[keep, keep, drop = FALSE]
  off <- row(dk) != col(dk)

  x <- (a > 0) * 1
  a2 <- x %*% x
  diag_paths <- x * a2                 # ordered i->j->k closed by i->k, i != k
  transtriples <- sum(diag_paths) - sum(diag(x) * diag(a2))

  # common alters, over unordered pairs, counted both ways round
  outc <- x %*% t(x)
  inc  <- t(x) %*% x
  ov <- outc + inc
  diag(ov) <- 0
  sumoverlap <- sum(ov[upper.tri(ov)])

  b <- brandes_edges(a)
  ebk <- b$edge[keep, keep, drop = FALSE]

  list(
    within_k   = sum(dk[off] <= k),
    sumdist    = sum(dk[off]),
    sumrdist   = sum(1 / dk[off][dk[off] > 0]),
    sumoverlap = sumoverlap,
    transtriples = transtriples,
    frag       = nmiss,
    sumbet     = sum(b$node[keep]),
    sumebet    = sum(ebk[row(ebk) != col(ebk)]),
    sumrevdist = sum(n - dk[off])
  )
}
