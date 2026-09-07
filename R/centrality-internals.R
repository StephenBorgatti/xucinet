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
