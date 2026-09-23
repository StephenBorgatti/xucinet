# Factions.
#
# UCINET: Network | Subgroups | Factions, the current menu item: runfactions
# and factionsoptimize in uc_factions.pas (the 64-bit rewrite of XFaction.pas,
# which is now "Factions (legacy)"), with the dialog uc_factionsdlg; the
# starting partition from floyd in G2Tools/ufloyd.pas and km1 in
# G2Tools/ukm1.pas. Repositories StephenBorgatti/ucinet at commit c7b4956 and
# StephenBorgatti/tools at commit 207958a.
#
# Dialog defaults: 2 factions; measure of fit Hamming (the others are Phi,
# Modularity and Entailment); 3 random starts; 20 iterations in series; 15
# steps in the penalty box; a random seed between 1 and 1000, shown in the
# dialog. The randomness is Delphi's System.Random, ported in
# community-internals.R, so the same seed gives UCINET's partition.
#
# The algorithm: dichotomize (any value above 1 becomes 1); a starting
# partition from km1 on geodesic distances; then, for each random start, a
# random partition improved by tabu search (the move that most improves the
# fit, or least worsens it, is made; a node may not return to the group it
# just left for `penalty` steps; the search runs `maxit` steps past the last
# improvement); the best of the starting partition and the searched ones is
# kept. On symmetric data every node with one tie is then put in its
# neighbour's group.
#
# One departure, UCINET issue 27: UCINET's dichotomize turns a missing cell
# (stored as 1e38) into a tie. Here a missing cell is no tie.

#' Factions
#'
#' UCINET: Network | Subgroups | Factions. Divides the nodes into `k` groups
#' so that ties fall inside groups and not between them, as nearly as
#' possible: the ideal is a network of `k` complete subgraphs with nothing
#' between them.
#'
#' How near is measured by `method`:
#'
#' * `"hamming"` (the default): the number of cells that disagree with the
#'   ideal, reported as the proportion that agree ("proportion correct").
#' * `"phi"`: the correlation between the network and the ideal.
#' * `"modularity"`: Newman's modularity.
#' * `"entailment"`: the proportion of ties that stay inside a group.
#'
#' The search is heuristic and starts from random partitions, so a different
#' `seed` can give a different answer on a network without clear factions. The
#' same seed gives the same answer, and the same answer as UCINET given the
#' seed UCINET's dialog shows.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Factions. *Number of blocks* is `k`, *Measure of fit*
#' is `method`, *Number of random starts* is `restarts`, *Max # of iterations
#' in series* is `maxit`, *Length of time in penalty box* is `penalty`, and
#' *Random number seed* is `seed`.
#'
#' @param net A network (any accepted form). 1-mode. Valued data are
#'   dichotomized.
#' @param k The number of factions. UCINET's default is 2.
#' @param method `"hamming"` (the default), `"phi"`, `"modularity"` or
#'   `"entailment"`.
#' @param restarts Number of random starts; UCINET's default is 3.
#' @param maxit Steps the search runs past its last improvement; default 20.
#' @param penalty Steps a node is barred from returning to the group it left;
#'   default 15.
#' @param seed The random seed, a whole number. `NULL` picks one between 1 and
#'   1000, as the dialog does, and the report says which.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An object of class `c("xfactions", "xucinet_output")`. `$nodes`
#'   has `Cluster`, the faction of each node; `$summary` the fit under UCINET's
#'   label, the number of factions and the modularity; `$matrices` the block
#'   densities.
#' @seealso [xcommunities()], [xcliques()].
#' @examples
#' xfactions(campnet, k = 2, seed = 1)
#' @export
xfactions <- function(net, k = 2,
                      method = c("hamming", "phi", "modularity", "entailment"),
                      restarts = 3, maxit = 20, penalty = 15, seed = NULL,
                      relation = NULL) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  rel <- ego_relation(net, relation, "xfactions()")
  m <- rel$m
  n <- nrow(m)
  labels <- rownames(m)
  k <- as.integer(k)
  if (is.na(k) || k < 1 || k > n) {
    stop("xfactions(): k must be between 1 and the number of nodes (", n, ").",
         call. = FALSE)
  }
  if (is.null(seed)) seed <- sample.int(1000, 1)
  seed <- as.integer(seed)

  assumptions <- rel$note
  vals <- m[!is.na(m) & row(m) != col(m)]
  if (any(vals != 0 & vals != 1)) {
    assumptions <- c(assumptions,
                     "This version of Factions is intended for binary data.")
  }

  res <- factions_optimize(m, k, method, restarts, maxit, penalty, seed)
  part <- res$part

  ncells <- n * (n - 1)
  fit_label <- c(hamming = "Final proportion \"correct\"",
                 phi = "Final correlation (phi)",
                 modularity = "Final modularity",
                 entailment = "Final entailment")[[method]]
  fit_value <- if (method == "hamming") 1 - res$cost / ncells else 1 - res$cost
  summary <- c(stats::setNames(list(fit_value), fit_label),
               community_summary(m, part))

  groups <- vapply(seq_len(k), function(g) {
    paste0(formatC(g, width = 5), ":  ", paste(labels[part == g], collapse = " "))
  }, character(1))

  dens <- faction_block_density(res$a, part, k)
  dimnames(dens) <- list(as.character(seq_len(k)), as.character(seq_len(k)))

  new_xucinet_output(
    "Factions", net,
    nodes = community_nodes(part, labels),
    summary = summary,
    matrices = list(`Block densities` = dens),
    assumptions = assumptions,
    fields = c("Number of factions:" = format(k),
               "Measure of fit:" = c(hamming = "Hamming", phi = "Phi",
                                     modularity = "Modularity",
                                     entailment = "Entailment")[[method]],
               "Random number seed:" = format(seed)),
    preamble = c("Group Assignments:", "", groups),
    print_nodes = FALSE,
    subclass = "xfactions", call = match.call())
}

# factionsoptimize. Returns the partition, its cost (lower is better, as the
# Delphi minimizes), and the dichotomized matrix.
factions_optimize <- function(m, nb, method, nstarts, maxit, nban, seed) {
  n <- nrow(m)
  a <- m
  a[is.na(a)] <- 0                            # UCINET issue 27
  off <- row(a) != col(a)
  a[off & a > 1] <- 1                         # dichotomize: > 1 becomes 1
  ties <- which(off & a > 0, arr.ind = TRUE)
  ties <- ties[order(ties[, 1], ties[, 2]), , drop = FALSE]
  ei <- ties[, 1]; ej <- ties[, 2]
  numedges <- length(ei)

  fitof <- factions_fit(method, ei, ej, numedges, n, nb)

  if (method == "modularity" && numedges == 0) {
    return(list(part = rep(1L, n), cost = 1, a = a))
  }

  rng <- delphi_rng(seed)
  best <- factions_start(a, nb)
  bestcost <- fitof(best)
  for (s in seq_len(nstarts)) {
    delphi_addseed(rng, 31)
    p <- vapply(seq_len(n), function(i) delphi_random(rng, nb) + 1, numeric(1))
    p <- factions_tabu(as.integer(p), fitof, nb, maxit, nban)
    fit <- fitof(p)
    if (fit < bestcost) {
      bestcost <- fit
      best <- p
    }
  }
  if (isSymmetric(unname(a))) best <- factions_pendants(a, best)
  list(part = as.integer(best), cost = bestcost, a = a)
}

# The four fit functions of uc_factions.pas, each a cost to minimize, over the
# directed off-diagonal ties (ei -> ej).
factions_fit <- function(method, ei, ej, numedges, n, nb) {
  force(method)
  switch(method,
    hamming = function(p) {
      s <- tabulate(p, nb)
      intra_p <- sum(s * (s - 1))
      intra_e <- sum(p[ei] == p[ej])
      intra_p + numedges - 2 * intra_e
    },
    phi = function(p) {
      s <- tabulate(p, nb)
      intra_p <- sum(s * (s - 1))
      intra_e <- sum(p[ei] == p[ej])
      total <- n * (n - 1)
      a <- intra_e; b <- intra_p - intra_e
      c <- numedges - intra_e; d <- total - intra_p - c
      den <- sqrt((a + b) * (c + d) * (a + c) * (b + d))
      if (den <= 0) 1 else 1 - (a * d - b * c) / den
    },
    entailment = function(p) {
      if (numedges == 0) return(0)
      (numedges - sum(p[ei] == p[ej])) / numedges
    },
    modularity = function(p) {
      e <- matrix(0, nb, nb)
      tab <- table(factor(p[ei], levels = seq_len(nb)),
                   factor(p[ej], levels = seq_len(nb)))
      e[] <- tab
      ai <- rowSums(e)
      1 - sum(diag(e) / numedges - (ai / numedges)^2)
    })
}

# getstartingpartition: floyd on the dichotomized matrix (tie values as
# lengths, unreachable pairs 1e38), then km1 with distances.
factions_start <- function(a, nb) {
  n <- nrow(a)
  d <- binary_floyd(a)
  d[row(d) != col(d) & d == 0] <- 1e38
  diag(d) <- 0
  km1(d, nb)
}

# binaryfloyd in ufloyd.pas: 0 means no path, so the relaxation skips it.
binary_floyd <- function(a) {
  d <- a
  n <- nrow(d)
  diag(d) <- 0
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      if (d[j, i] > 0) {
        for (k in seq_len(n)) {
          if (d[i, k] > 0) {
            s <- d[j, i] + d[i, k]
            if (d[j, k] == 0 || s < d[j, k]) d[j, k] <- s
          }
        }
      }
    }
  }
  d
}

# km1 in ukm1.pas with sim = false: seed the k clusters with the farthest
# pair and then, one at a time, the item farthest from the seeds so far; put
# every other item, in node order, into the cluster it is closest to on
# average (clusters growing as items join).
km1 <- function(d, nb) {
  n <- nrow(d)
  # One cluster is everyone. (The Delphi seeds two items and builds one
  # cluster, leaving the second seed unassigned.)
  if (nb < 2 || n < 2) return(rep(1L, n))
  subsumed <- logical(n)
  ref <- d[1, 2]; ni <- 1L; nj <- 2L
  for (i in 2:n) for (j in seq_len(i - 1)) {
    if (d[i, j] > ref) { ni <- i; nj <- j; ref <- d[i, j] }
  }
  dsl <- c(ni, nj)
  subsumed[c(ni, nj)] <- TRUE
  while (length(dsl) < nb) {
    cand <- which(!subsumed)
    best <- cand[1]
    besttot <- sum(d[dsl, best])
    for (j in cand) {
      tot <- sum(d[dsl, j])
      if (tot > besttot) { besttot <- tot; best <- j }
    }
    dsl <- c(dsl, best)
    subsumed[best] <- TRUE
  }
  clusters <- as.list(dsl[seq_len(nb)])
  for (i in seq_len(n)) {
    if (subsumed[i]) next
    avg <- vapply(clusters, function(items) mean(d[i, items]), numeric(1))
    bestc <- 1L
    for (c in seq_len(nb)[-1]) if (avg[c] < avg[bestc]) bestc <- c
    clusters[[bestc]] <- c(clusters[[bestc]], i)
    subsumed[i] <- TRUE
  }
  p <- integer(n)
  for (c in seq_len(nb)) p[clusters[[c]]] <- c
  p
}

# tabuoptimize. Returns the best partition the search visited.
factions_tabu <- function(bestp, fitof, nb, maxit, nban) {
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

# adjustpendants: a node with exactly one tie joins its neighbour's group.
factions_pendants <- function(a, p) {
  n <- nrow(a)
  for (i in seq_len(n)) {
    nb <- which(a[i, ] > 0 & seq_len(n) != i)
    if (length(nb) == 1) p[i] <- p[nb]
  }
  p
}

# makeblockdensity_data: ties over possible off-diagonal cells, block by block.
faction_block_density <- function(a, p, k) {
  n <- nrow(a)
  count <- matrix(0, k, k)
  possible <- matrix(0, k, k)
  for (i in seq_len(n)) for (j in seq_len(n)) {
    if (i == j) next
    possible[p[i], p[j]] <- possible[p[i], p[j]] + 1
    if (a[i, j] > 0) count[p[i], p[j]] <- count[p[i], p[j]] + 1
  }
  ifelse(possible > 0, count / possible, 0)
}
