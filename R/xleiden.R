# Leiden.
#
# Traag, Waltman and van Eck (2019), Algorithm A.2, implemented natively for
# xucinet #41 and UCINET (ucinet #46; tools G2Tools/uleiden.pas). Both follow
# dev/design/leiden.md step for step: the order nodes are visited in, every tie
# rule and every random draw, which is Delphi's System.Random (delphi_rng() in
# community-internals.R). One seed therefore gives one partition in both
# programs. Decisions (Steve, 23 Oct 2026): modularity with a resolution
# parameter, no CPM; seeded; 1-mode only; xcommunities() gets a Leiden column.

#' Leiden community detection
#'
#' UCINET: Network | Subgroups | Leiden Method. Finds groups by maximizing
#' modularity with the Leiden algorithm (Traag, Waltman and van Eck, 2019), a
#' refinement of Louvain ([xlouvain()]). Nodes move to whichever neighbouring
#' group raises modularity most; before groups are merged into single nodes,
#' each group is split into well-connected subgroups, which are what get
#' merged. That step is what guarantees that every group found is connected,
#' which Louvain does not. The whole procedure is repeated from its own result
#' until it no longer changes the partition.
#'
#' The search is random: nodes are visited in a random order, and the
#' refinement step chooses among good merges at random, strongly favouring the
#' best (randomness 0.01, as in igraph). The same `seed` always gives the same
#' partition, and the same partition as UCINET with that seed. Different seeds
#' can give different partitions of about the same modularity; comparing a
#' few is a check on how robust a partition is.
#'
#' `resolution` is the \eqn{\gamma} of
#' \deqn{Q_\gamma = \sum_c \left(\frac{W_c}{2m} - \gamma \left(\frac{K_c}{2m}\right)^2\right),}
#' with \eqn{W_c} the tie weight inside group \eqn{c} (both directions),
#' \eqn{K_c} the total degree of its members and \eqn{2m} the total weight.
#' Values above 1 give more and smaller groups, values below 1 fewer and
#' larger ones. The summary reports `Quality`, \eqn{Q_\gamma} of the
#' partition found, and `Modularity`, ordinary modularity (\eqn{\gamma = 1})
#' computed as every community routine computes it, so that partitions from
#' different routines can be compared.
#'
#' Tie values are used as weights. Directed data are symmetrized by maximum
#' unless `symmetrize` says otherwise; negative values are dropped and the
#' diagonal is ignored.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Leiden Method. *Resolution* is `resolution`,
#' *Random number seed* is `seed`, *For directed data* is `symmetrize`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param resolution The resolution parameter \eqn{\gamma}, a positive number.
#'   1, the default, is ordinary modularity.
#' @param symmetrize What to do with directed data: `"max"` (the default),
#'   `"min"`, `"average"` or `"sum"`.
#' @param relation Which relation of a multi-relation dataset, by name (in any
#'   case) or position. Defaults to the first.
#' @param seed The random seed, a whole number. `NULL` picks one between 1 and
#'   1000 and reports it, so the run can be repeated.
#' @return An object of class `c("xleiden", "xucinet_output")`. `$nodes` has
#'   `Cluster`; `$summary` has `Clusters`, `Modularity`, `Quality` and
#'   `Iterations`.
#' @references Traag, V. A., Waltman, L., & van Eck, N. J. (2019). From Louvain
#'   to Leiden: guaranteeing well-connected communities. *Scientific Reports*,
#'   9, 5233.
#' @seealso [xlouvain()], [xcommunities()].
#' @examples
#' xleiden(zachary, seed = 1)
#' xleiden(campnet, resolution = 1.5, seed = 1)
#' @export
xleiden <- function(net, resolution = 1,
                    symmetrize = c("max", "min", "average", "sum"),
                    relation = NULL, seed = NULL) {
  net <- xnet(net, substitute(net))
  symmetrize <- match.arg(symmetrize)
  if (identical(net$mode, "2-mode")) {
    stop("xleiden() works on 1-mode data only.", call. = FALSE)
  }
  if (!is.numeric(resolution) || length(resolution) != 1L || is.na(resolution) ||
      resolution <= 0) {
    stop("xleiden(): resolution must be a positive number.", call. = FALSE)
  }
  if (is.null(seed)) seed <- sample.int(1000, 1)
  seed <- suppressWarnings(as.numeric(seed))
  if (length(seed) != 1L || is.na(seed) || seed != round(seed)) {
    stop("xleiden(): seed must be a whole number.", call. = FALSE)
  }
  rel <- ego_relation(net, relation, "xleiden()")
  m <- rel$m
  labels <- rownames(m)
  assumptions <- rel$note

  w <- m
  w[is.na(w)] <- 0
  if (any(w < 0)) {
    w[w < 0] <- 0
    assumptions <- c(assumptions, "Negative values removed.")
  }
  if (!isSymmetric(unname(w))) {
    w <- switch(symmetrize,
                max = pmax(w, t(w)),
                min = pmin(w, t(w)),
                average = (w + t(w)) / 2,
                sum = w + t(w))
    assumptions <- c(assumptions, paste0("Data symmetrized by ", symmetrize, "."))
  }
  diag(w) <- 0
  w <- unname(w)

  res <- leiden_run(w, resolution, seed)
  if (!res$converged) {
    assumptions <- c(assumptions, "Stopped after 50 iterations without converging.")
  }
  part <- res$part

  new_xucinet_output(
    "Leiden Community Detection", net,
    nodes = community_nodes(part, labels),
    summary = community_summary(m, part, list(
      Quality = leiden_quality(w, part, resolution),
      Iterations = res$iterations)),
    assumptions = assumptions,
    fields = c("Resolution:" = format(resolution),
               "Random number seed:" = format(seed),
               "For directed data:" = c(max = "Maximum/union",
                                        min = "Minimum/intersection",
                                        average = "Average", sum = "Sum")[[symmetrize]]),
    nodes_title = "Leiden partition",
    subclass = "xleiden", call = match.call())
}

# Modularity at resolution gamma on the matrix the algorithm ran on.
leiden_quality <- function(w, part, gamma) {
  tw <- sum(w)
  if (tw <= 0) return(NA_real_)
  k <- rowSums(w)
  q <- 0
  for (c in unique(part)) {
    inc <- part == c
    q <- q + sum(w[inc, inc]) / tw - gamma * (sum(k[inc]) / tw)^2
  }
  q
}

# ---- the algorithm (dev/design/leiden.md) -------------------------------------

leiden_run <- function(w, gamma, seed, maxit = 50L) {
  n <- nrow(w)
  tw <- sum(w)
  if (n < 2L || tw <= 0) {
    return(list(part = seq_len(n), iterations = 0L, converged = TRUE))
  }
  rng <- delphi_rng(seed)
  p <- seq_len(n)
  converged <- FALSE
  for (it in seq_len(maxit)) {
    pnew <- leiden_iteration(w, p, gamma, tw, rng)
    same <- identical(renumber_first(pnew), renumber_first(p))
    p <- pnew
    if (same) { converged <- TRUE; break }
  }
  list(part = renumber_first(p), iterations = it, converged = converged)
}

# Random: a real in [0, 1).
delphi_random_real <- function(rng) {
  rng$state <- (delphi_mulmod(rng$state) + 1) %% 2^32
  rng$state / 2^32
}

# Shuffle(a): for i from len down to 2, swap a[i] with a[1 + Random(i)].
leiden_shuffle <- function(a, rng) {
  len <- length(a)
  if (len < 2L) return(a)
  for (i in seq(len, 2L)) {
    j <- 1L + delphi_random(rng, i)
    tmp <- a[i]; a[i] <- a[j]; a[j] <- tmp
  }
  a
}

leiden_iteration <- function(w, p, gamma, tw, rng) {
  g <- w
  pg <- p
  map <- seq_len(nrow(w))
  repeat {
    pg <- leiden_move(g, pg, gamma, tw, rng)
    ng <- nrow(g)
    if (length(unique(pg)) == ng) break
    r <- leiden_refine(g, pg, gamma, tw, rng)
    if (length(unique(r)) == ng) break
    r <- renumber_first(r)
    nr <- max(r)
    g <- rowsum(t(rowsum(g, r, reorder = TRUE)), r, reorder = TRUE)
    dimnames(g) <- NULL
    first <- match(seq_len(nr), r)
    pg <- renumber_first(pg[first])
    map <- r[map]
  }
  renumber_first(pg[map])
}

leiden_move <- function(g, p, gamma, tw, rng) {
  n <- nrow(g)
  eps <- 1e-12 * tw
  k <- rowSums(g)
  nb <- lapply(seq_len(n), function(v) {
    u <- which(g[v, ] > 0)
    u[u != v]
  })
  kc <- numeric(n); size <- integer(n)
  for (v in seq_len(n)) {
    kc[p[v]] <- kc[p[v]] + k[v]
    size[p[v]] <- size[p[v]] + 1L
  }
  queue <- leiden_shuffle(seq_len(n), rng)
  inq <- rep(TRUE, n)
  head <- 1L
  while (head <= length(queue)) {
    v <- queue[head]; head <- head + 1L
    inq[v] <- FALSE
    a <- p[v]
    u <- nb[[v]]
    cl <- p[u]
    wv <- g[v, u]
    cands <- unique(cl)
    wc <- vapply(cands, function(c) sum(wv[cl == c]), numeric(1))
    wa <- if (any(cands == a)) wc[cands == a] else 0
    ga <- wa - gamma * k[v] * (kc[a] - k[v]) / tw
    best <- a; bestgain <- 0
    for (j in seq_along(cands)) {
      c <- cands[j]
      if (c == a) next
      delta <- (wc[j] - gamma * k[v] * kc[c] / tw) - ga
      if (delta > bestgain + eps) { best <- c; bestgain <- delta }
    }
    if (size[a] > 1L) {
      delta <- 0 - ga
      if (delta > bestgain + eps) { best <- which(size == 0L)[1]; bestgain <- delta }
    }
    if (best != a) {
      kc[a] <- kc[a] - k[v]; size[a] <- size[a] - 1L
      kc[best] <- kc[best] + k[v]; size[best] <- size[best] + 1L
      p[v] <- best
      for (x in u) {
        if (p[x] != best && !inq[x]) {
          queue <- c(queue, x); inq[x] <- TRUE
        }
      }
    }
  }
  p
}

leiden_refine <- function(g, p, gamma, tw, rng, theta = 0.01) {
  n <- nrow(g)
  eps <- 1e-12 * tw
  k <- rowSums(g)
  r <- seq_len(n)
  kr <- k; size <- rep(1L, n); e <- numeric(n)
  for (s in unique(p)) {                     # communities by smallest member
    members <- which(p == s)
    ks <- sum(k[members])
    sub <- g[members, members, drop = FALSE]
    diag(sub) <- 0
    ws <- rowSums(sub)
    e[members] <- ws
    well <- ws - gamma * k[members] * (ks - k[members]) / tw >= -eps
    cand <- leiden_shuffle(members[well], rng)
    for (v in cand) {
      r0 <- r[v]
      if (size[r0] > 1L) next
      u <- members[members != v & g[v, members] > 0]
      rl <- r[u]
      wv <- g[v, u]
      targets <- unique(rl)
      opt_r <- r0; opt_d <- 0
      wsv <- ws[match(v, members)]
      wtar <- numeric(0)
      for (t in targets) {
        if (t == r0) next
        if (e[t] - gamma * kr[t] * (ks - kr[t]) / tw >= -eps) {
          wvt <- sum(wv[rl == t])
          delta <- wvt - gamma * k[v] * kr[t] / tw
          if (delta >= -eps) {
            opt_r <- c(opt_r, t); opt_d <- c(opt_d, delta)
            wtar <- c(wtar, wvt)
          }
        }
      }
      if (length(opt_r) == 1L) next
      wt <- exp((opt_d - max(opt_d)) / theta)
      x <- delphi_random_real(rng) * sum(wt)
      pick <- which(cumsum(wt) > x)[1]
      if (is.na(pick)) pick <- length(wt)
      t <- opt_r[pick]
      if (t != r0) {
        e[t] <- e[t] + wsv - 2 * wtar[pick - 1L]
        kr[t] <- kr[t] + k[v]
        size[t] <- size[t] + 1L
        size[r0] <- 0L
        r[v] <- t
      }
    }
  }
  r
}
