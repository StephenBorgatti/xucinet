# Shared machinery for the chapter 11 subgroup routines.

# ---- modularity --------------------------------------------------------------
#
# UCINET's formula, the one tlouvain.getq (G2Tools/utlouvain.pas), the factions
# modularity fit (uc_factions.pas) and xhclust's MOCA block all compute:
#
#   Q = sum over groups b of  W_b / o  -  (K_b / o)^2
#
# with W_b the total tie value inside b (both directions, diagonal included),
# K_b the total of b's row sums and o the total of the matrix. On a symmetric
# matrix that is Newman's Q.
modularity_uci <- function(a, part) {
  a[is.na(a)] <- 0
  keep <- !is.na(part)
  a <- a[keep, keep, drop = FALSE]
  part <- part[keep]
  o <- sum(a)
  if (o <= 0) return(NA_real_)
  k <- rowSums(a)
  q <- 0
  for (b in unique(part)) {
    inb <- part == b
    q <- q + sum(a[inb, inb]) / o - (sum(k[inb]) / o)^2
  }
  q
}

# The matrix every community routine reports its `Modularity` on, so that the
# same partition gets the same Q whichever routine found it: symmetrized by
# maximum, missing cells as 0, the diagonal ignored, tie values kept.
community_matrix <- function(m) {
  m[is.na(m)] <- 0
  m <- pmax(m, t(m))
  diag(m) <- 0
  m
}

community_modularity <- function(m, part) {
  modularity_uci(community_matrix(m), part)
}

# ---- Delphi's Random ------------------------------------------------------------
#
# Delphi's System.Random is a documented linear congruential generator:
#
#   RandSeed := RandSeed * $08088405 + 1         (mod 2^32)
#   Random(n) := (UInt32(RandSeed) * n) shr 32
#
# UCINET's Factions seeds it from the dialog's "Random number seed" box, so
# porting the generator lets `seed =` reproduce UCINET's run exactly. The
# state is kept as a double in [0, 2^32); the multiplication is split into
# 16-bit halves so no intermediate exceeds 2^53.
delphi_rng <- function(seed) {
  env <- new.env(parent = emptyenv())
  env$state <- as.numeric(seed) %% 2^32
  env
}

delphi_mulmod <- function(s) {
  a_lo <- 134775813 %% 65536
  a_hi <- 134775813 %/% 65536
  s_lo <- s %% 65536
  s_hi <- s %/% 65536
  lo <- a_lo * s_lo
  mid <- ((a_hi * s_lo) %% 65536 + (a_lo * s_hi) %% 65536) %% 65536
  (lo + mid * 65536) %% 2^32
}

# Random(n): an integer in 0 .. n - 1.
delphi_random <- function(rng, n) {
  rng$state <- (delphi_mulmod(rng$state) + 1) %% 2^32
  floor(rng$state * n / 2^32)
}

# `RandSeed := RandSeed + k`, as factionsoptimize does between starts.
delphi_addseed <- function(rng, k) {
  rng$state <- (rng$state + k) %% 2^32
  invisible(rng)
}

# ---- shared output ----------------------------------------------------------------

# Renumber a partition 1..k in order of first appearance.
renumber_first <- function(p) {
  match(p, unique(p))
}

# The part of the report every community routine shares: a node table with
# `Cluster`, and a summary with the number of clusters and the modularity.
community_nodes <- function(part, labels) {
  data.frame(Cluster = as.integer(part), row.names = labels, check.names = FALSE)
}

community_summary <- function(m, part, extra = list()) {
  c(list(Clusters = length(unique(part[!is.na(part)])),
         Modularity = community_modularity(m, part)),
    extra)
}

# Undirected, binary adjacency for the routines that need a graph: a tie in
# either direction, missing cells absent, no diagonal.
community_adjacency <- function(m) {
  a <- (m > 0) * 1
  a[is.na(a)] <- 0
  a <- pmax(a, t(a))
  diag(a) <- 0
  a
}
