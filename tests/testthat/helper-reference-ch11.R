# Reference implementations for the chapter 11 speed-ups (issue #19).
#
# These are the straightforward versions the package shipped before the
# optimisation: every candidate scored by a full recomputation. The tests
# require the fast versions to give the same partitions.

ref_factions_tabu <- function(bestp, fitof, nb, maxit, nban) {
  if (nb < 2) return(bestp)
  n <- length(bestp)
  p <- bestp
  dok <- matrix(0L, n, nb)
  currentcost <- fitof(p)
  bestf <- currentcost
  sentinel <- 2 * abs(currentcost) + 1

  delta_all <- function() {
    sizes <- tabulate(p, nb)
    dl <- matrix(0, n, nb)
    for (i in seq_len(n)) {
      oldg <- p[i]
      for (g in seq_len(nb)) {
        if (g == oldg) next
        if (sizes[oldg] < 2) { dl[i, g] <- sentinel; next }
        q <- p; q[i] <- g
        dl[i, g] <- fitof(q) - currentcost
      }
    }
    dl
  }

  delta <- delta_all()
  changed <- FALSE
  r <- maxit
  while (r > 0) {
    # getnext: the eligible move with the smallest delta, the last such on ties.
    bd <- .Machine$double.xmax; bi <- 1L; oj <- p[1]; bj <- p[1]
    for (i in seq_len(n)) for (g in seq_len(nb)) {
      if (dok[i, g] == 0 && p[i] != g && delta[i, g] <= bd) {
        bd <- delta[i, g]; bi <- i; oj <- p[i]; bj <- g
      }
    }
    if (bd >= 0) dok[bi, oj] <- nban
    if (tabulate(p, nb)[oj] > 1) p[bi] <- bj
    currentcost <- fitof(p)
    delta <- delta_all()
    if (currentcost < bestf) {
      bestf <- currentcost
      bestp <- p
      changed <- TRUE
    }
    r <- r - 1
    dok[dok > 0] <- dok[dok > 0] - 1L
    if (r == 0 && changed) {
      changed <- FALSE
      r <- maxit
    }
  }
  bestp
}

ref_louvain_levels <- function(w, maxpart) {
  noriginal <- nrow(w)
  net <- w
  sumofties <- sum(net)
  hier <- matrix(0L, noriginal, 0)
  heads <- character(0)
  if (sumofties <= 0 || noriginal < 2) {
    hier <- matrix(seq_len(noriginal), noriginal, 1)
    colnames(hier) <- paste0(noriginal, "|NA")
    return(list(hier = hier))
  }

  getq <- function(part, net, deg) {
    same <- outer(part, part, "==")
    k <- tapply(deg, part, sum)
    (sum(net[same]) - sum(k^2) / sumofties) / sumofties
  }

  part <- seq_len(noriginal)
  deg <- rowSums(net)
  currentq <- getq(part, net, deg)
  n <- noriginal
  for (it in seq_len(maxpart)) {
    neighbors <- lapply(seq_len(n), function(i) which(net[i, ] > 0))
    # movenodes. The move must beat the Q of leaving the node where it is
    # (UCINET issue 26: UCINET compares with the Q from before the pass).
    anymoved <- TRUE
    while (anymoved) {
      anymoved <- FALSE
      for (ego in seq_len(n)) {
        best_cluster <- part[ego]
        best_q <- getq(part, net, deg)
        for (cl in unique(part[neighbors[[ego]]])) {
          old <- part[ego]
          part[ego] <- cl
          temp <- getq(part, net, deg)
          part[ego] <- old
          if (temp > best_q) {
            best_cluster <- cl
            best_q <- temp
          }
        }
        if (part[ego] != best_cluster) {
          anymoved <- TRUE
          part[ego] <- best_cluster
        }
      }
    }
    # The level's own Q (UCINET issue 26: UCINET keeps the last node's value).
    currentq <- getq(part, net, deg)
    # storepart: renumber by sorted id, map the original nodes through.
    part <- match(part, sort(unique(part)))
    nclus <- max(part)
    prev <- if (ncol(hier) == 0) seq_len(noriginal) else hier[, ncol(hier)]
    hier <- cbind(hier, part[prev])
    heads <- c(heads, paste0(nclus, "|", formatC(currentq, format = "f", digits = 3)))
    # aggregate
    oldn <- n
    agg <- matrix(0, nclus, nclus)
    for (i in seq_len(n)) for (j in seq_len(n)) {
      agg[part[i], part[j]] <- agg[part[i], part[j]] + net[i, j]
    }
    net <- agg
    n <- nclus
    deg <- rowSums(net)
    if (n == oldn) {
      hier <- hier[, -ncol(hier), drop = FALSE]
      heads <- heads[-length(heads)]
      break
    }
    if (n <= 2) break
    part <- seq_len(n)
  }
  if (ncol(hier) == 0) {
    hier <- matrix(seq_len(noriginal), noriginal, 1)
    heads <- paste0(noriginal, "|", formatC(currentq, format = "f", digits = 3))
  }
  colnames(hier) <- heads
  list(hier = hier)
}

ref_girvan_newman_partitions <- function(a, maxc) {
  n <- nrow(a)
  cols <- list()
  seen <- integer(0)
  maxit <- n * (n - 1) / 2
  it <- 0
  repeat {
    it <- it + 1
    eb <- brandes_edges(a)$edge
    low <- lower.tri(eb)
    vals <- round(eb[low], 4)
    maxval <- if (length(vals)) max(vals) else 0
    if (!(maxval > 0)) break
    cut <- which(low & round(eb, 4) >= maxval, arr.ind = TRUE)
    a[cut] <- 0
    a[cut[, 2:1, drop = FALSE]] <- 0
    part <- components_of(a)
    nclus <- length(unique(part))
    if (!nclus %in% seen) {
      seen <- c(seen, nclus)
      cols[[paste0("C", nclus)]] <- renumber_first(part)
    }
    if (nclus >= maxc || it >= maxit) break
  }
  if (!length(cols)) return(matrix(integer(0), n, 0))
  do.call(cbind, cols)
}
