# Blockmodel optimization.
#
# UCINET: Network | Roles & Positions | Structural Equivalence | Optimization |
# Binary and | Valued (xsbmb.pas, runsbmbinary; xsbmv.pas, runsbmvalued), and
# Network | Roles & Positions | Maximal Regular Equivalence | Optimization
# (xrbm.pas, rbm); repository StephenBorgatti/ucinet at commit c7b4956. Shared
# engines from StephenBorgatti/tools at commit 207958a: tabus (the ivector
# overload) in G1Tools/utabu.pas, km1 in G1Tools/Uclus.pas, sStdrege in
# G1Tools/Urege.pas, blockdensity in G1Tools/uag.pas. Steve, 26 Sep 2026
# (issue #24): a native port of UCINET's routines.
#
# Structural (binary): the cost is the number of cells that differ from the
# nearest ideal block, all 0s or all 1s: sum over block pairs of
# min(ones, cells - ones), the diagonal left out. R-square is the squared
# correlation between the data and the block densities.
# Structural (valued): the cost is 2 - r, r the correlation between the data
# and the block means; R-square is r^2.
# Regular: the data are dichotomized; for each block pair, a regular block has
# every row node with a tie into the column block and every column node with a
# tie from the row block, a null block none; the cost counts the nodes that
# break the nearer of the two, rows and columns.
#
# Search, both: Delphi's RandSeed := seed; a start; then random starts, each
# RandSeed := RandSeed + 31 and a uniform random partition, improved by the tabu
# search and then by a pass of simple moves; the best is kept.
#   Structural start: n draws of Random(nb) (overwritten), then km1 on a
#   profile distance, then pairwise swaps. starts - 1 random starts follow.
#   Regular start: n draws of Random(nb), then REGE (3 iterations) and a tabu
#   search (15 steps, penalty 7) on 1 - similarity within blocks plus
#   similarity between them, then single-node moves. `starts` random starts
#   follow.
# Dialog defaults: 2 blocks, diagonal not valid, penalty 25; structural 50
# iterations and 5 random starts, regular 30 and 30; the seed a random number
# from 1 to 1000, shown in the dialog. Randomness is Delphi's System.Random,
# ported in community-internals.R, so the seed UCINET shows gives its search.
#
# UCINET issue 35, corrected here (ledger 46): the start's profile distance
# adds d[k,i]^4 where (d[k,i] - d[k,j])^2 is meant; the valued routine scores
# each random start on the old best partition and keeps a start only when its
# R-square is lower, so no random start is ever used; the regular routine's
# simple moves never try the last block; and "Diagonal valid" does not reach
# the binary or the regular cost. Missing cells are left out of every count
# rather than read as values.

#' Blockmodel optimization
#'
#' UCINET: Network | Roles & Positions | Structural Equivalence | Optimization
#' and Maximal Regular Equivalence | Optimization. Searches for the partition of
#' the nodes into `k` blocks that best fits an ideal blockmodel (book, 12.5 and
#' 12.6), where [xblockmodel()] only describes a partition you already have.
#'
#' * `type = "structural"`: blocks of structurally equivalent nodes, so every
#'   block of the blocked matrix should be all ties or all non-ties. For binary
#'   data the fit is the number of errors, cells that break the nearer of the
#'   two; for valued data (`weighted`) it is the correlation between the data
#'   and the block means, reported as R-square.
#' * `type = "regular"`: blocks of regularly equivalent nodes, so in every block
#'   of the blocked matrix either each row and each column has at least one tie
#'   or none has. The data are dichotomized. The fit is the number of rows and
#'   columns that break the pattern.
#'
#' The search is UCINET's: a start (a profile-based clustering for structural,
#' REGE similarities for regular), then random starts, each improved by a tabu
#' search and a pass of simple moves. The same `seed` gives the same result,
#' and the same result as UCINET with the seed its dialog shows, except where
#' UCINET's code has the defects listed in the differences ledger.
#'
#' @section UCINET equivalent:
#' Network | Roles & Positions | Structural Equivalence | Optimization |
#' Binary or Valued, and Maximal Regular Equivalence | Optimization. *Number of
#' blocks* is `k`, *Diagonal valid?* is `diagonal`, *Iterations/series* is
#' `maxit`, *Penalty iterations* is `penalty`, *Random starts* is `starts`,
#' *Random seed* is `seed`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param k Number of blocks.
#' @param type `"structural"` (the default) or `"regular"`.
#' @param weighted Structural only: use the Valued routine? `NULL` decides from
#'   the data (valued if any tie value other than 0 or 1).
#' @param relation Which relation of a multi-relation dataset, by name (in any case) or
#'   position. Defaults to the first.
#' @param starts Random starts. `NULL` uses UCINET's defaults: 5 for
#'   structural (the start counts as the first), 30 for regular (after the
#'   start).
#' @param maxit Steps of the tabu search past the last improvement, and the
#'   most passes of simple moves. `NULL`: 50 structural, 30 regular.
#' @param penalty Steps a node may not return to the block it left.
#' @param seed The random seed, a whole number. `NULL` picks one from 1 to
#'   1000 and reports it.
#' @param diagonal Count the diagonal (self-ties)? `FALSE` by default.
#' @return An object of class `c("xblockoptimize", "xucinet_output")`.
#'   `$nodes`: `Block`. `$summary`: `Errors` (binary structural and regular)
#'   and `R-square` (structural). `$matrices`: `Density matrix` and `Errors per
#'   block`. What does not apply to the model is `NA` and not printed.
#' @seealso [xblockmodel()] to describe a given partition,
#'   [xstructuralequivalence()], [xrege()].
#' @examples
#' xblockoptimize(campnet, k = 3, seed = 1)
#' xblockoptimize(campnet, k = 2, type = "regular", seed = 1)
#' @export
xblockoptimize <- function(net, k = 2, type = c("structural", "regular"),
                           weighted = NULL, relation = NULL, starts = NULL,
                           maxit = NULL, penalty = 25, seed = NULL,
                           diagonal = FALSE) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xblockoptimize()")
  type <- match.arg(type)
  m <- as.matrix(net, relation = relation)
  n <- nrow(m)
  labels <- rownames(m); if (is.null(labels)) labels <- as.character(seq_len(n))
  k <- as.integer(k)
  if (is.na(k) || k < 2 || k >= n) {
    stop("xblockoptimize(): k must be at least 2 and less than the number of nodes (",
         n, ").", call. = FALSE)
  }
  if (is.null(seed)) seed <- sample.int(1000, 1)
  seed <- as.integer(seed)
  penalty <- as.integer(penalty)
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- sprintf("Relation: %s (of %d).",
                           relation_label(net, relation),
                           xnrelations(net))
  }
  if (anyNA(m)) assumptions <- c(assumptions, "Missing cells are left out of every count.")
  off <- diagonal | (row(m) != col(m))

  if (type == "structural") {
    vals <- m[off & !is.na(m)]
    if (is.null(weighted)) weighted <- any(vals != 0 & vals != 1)
    if (is.null(starts)) starts <- 5L
    if (is.null(maxit)) maxit <- 50L
    res <- sbm_run(unname(m), k, isTRUE(weighted), as.integer(starts), as.integer(maxit),
                   penalty, seed, diagonal)
    title <- "Structural Blockmodels"
  } else {
    weighted <- FALSE
    if (is.null(starts)) starts <- 30L
    if (is.null(maxit)) maxit <- 30L
    b <- unname(m)
    if (any(b[off & !is.na(b)] > 1)) {
      assumptions <- c(assumptions,
                       "Data binarized by recoding all values greater than zero to 1.")
    }
    res <- rbm_run(b, k, as.integer(starts), as.integer(maxit), penalty, seed, diagonal)
    title <- "Regular Blockmodels via Tabu Search"
  }
  p <- res$part
  dens <- blockopt_density(m, p, k, diagonal)
  errs <- res$errors_per_block
  dimnames(errs) <- dimnames(dens) <- list(seq_len(k), seq_len(k))
  assumptions <- c(assumptions, sprintf("Random number seed: %d.", seed))
  mm <- m; mm[is.na(mm)] <- 0; dimnames(mm) <- list(labels, labels)
  blocks <- vapply(seq_len(k), function(b)
    sprintf("%5d:  %s", b, paste(labels[p == b], collapse = " ")), character(1))

  new_xucinet_output(
    title, net,
    nodes = data.frame(Block = p, row.names = labels, check.names = FALSE),
    summary = list(Errors = res$errors, `R-square` = res$rsq),
    matrices = list(`Density matrix` = dens, `Errors per block` = errs),
    assumptions = assumptions,
    fields = c("Model:" = if (type == "regular") "Regular" else
                 if (weighted) "Structural, valued" else "Structural, binary",
               "Number of blocks:" = format(k),
               "Diagonal valid?" = if (diagonal) "YES" else "NO",
               "Iterations/series:" = format(maxit),
               "Penalty iterations:" = format(penalty),
               "Random starts:" = format(starts),
               "Random # seed:" = format(seed)),
    preamble = c(res$log, "", "RESULTS:",
                 if (!is.na(res$errors)) sprintf("  Number of errors: %d", as.integer(res$errors)),
                 if (!is.na(res$rsq)) sprintf("  R-square = %.3f", res$rsq),
                 "", "Block Assignments:", "", blocks, "",
                 "Blocked Adjacency Matrix", "", format_blocked_matrix(mm, p), ""),
    show_summary = character(0),
    # What UCINET prints: binary structural, errors per block and densities;
    # valued, densities; regular, neither.
    hide = c(if (type == "regular") c("Density matrix", "Errors per block"),
             if (type == "structural" && weighted) "Errors per block"),
    print_nodes = FALSE,
    subclass = "xblockoptimize", call = match.call())
}

# blockdensity, with the diagonal left out unless valid and missing cells
# skipped.
blockopt_density <- function(m, p, k, diagonal) {
  off <- diagonal | (row(m) != col(m))
  out <- matrix(NA_real_, k, k)
  for (a in seq_len(k)) for (b in seq_len(k)) {
    cells <- m[p == a, p == b, drop = FALSE][off[p == a, p == b, drop = FALSE]]
    cells <- cells[!is.na(cells)]
    if (length(cells)) out[a, b] <- mean(cells)
  }
  out
}

# ---- costs -------------------------------------------------------------------------

# Block pair index of every cell: (p[i] - 1) * nb + p[j].
pair_index <- function(p, nb) outer((p - 1L) * nb, p, `+`)

# hammingdistance (xsbmb): sum over block pairs of min(ones, cells - ones).
sbm_counts <- function(tie, use, p, nb) {
  bp <- pair_index(p, nb)
  list(ones = tabulate(bp[use & tie], nb * nb), cells = tabulate(bp[use], nb * nb))
}
sbm_hamming <- function(tie, use, p, nb) {
  cc <- sbm_counts(tie, use, p, nb)
  sum(pmin(cc$ones, cc$cells - cc$ones))
}

# corr (xsbmv, and rsquare in xsbmb): the correlation between the data and the
# mean of the cell's block, over the cells in use; 0 when undefined.
sbm_corr <- function(x, use, p, nb) {
  bp <- pair_index(p, nb)[use]
  xv <- x[use]
  sums <- numeric(nb * nb); cnt <- tabulate(bp, nb * nb)
  s <- rowsum(xv, bp)
  sums[as.integer(rownames(s))] <- s[, 1]
  means <- ifelse(cnt > 0, sums / pmax(cnt, 1), 0)
  y <- means[bp]
  if (stats::sd(xv) == 0 || stats::sd(y) == 0) return(0)
  stats::cor(xv, y)
}

# hamming (xrbm): for each block pair, rows of the row block with a tie into the
# column block, and columns of the column block with a tie from the row block;
# min(count, size - count) each. An empty block costs n^2.
# Matrix products throughout: the tabu search calls this for every candidate
# move. `tie` is a numeric 0/1 matrix.
rbm_parts <- function(tie, p, nb) {
  n <- length(p)
  ind <- matrix(0, n, nb); ind[cbind(seq_len(n), p)] <- 1
  rowhas <- ((tie %*% ind) > 0) * 1         # [i, b]: i has a tie into block b
  colhas <- (crossprod(tie, ind) > 0) * 1   # [j, a]: j has a tie from block a
  list(num = tabulate(p, nb),
       nrow = crossprod(ind, rowhas),       # [a, b]: rows of a with a tie into b
       ncol = crossprod(colhas, ind))       # [a, b]: columns of b with a tie from a
}
rbm_hamming <- function(tie, p, nb) {
  num <- tabulate(p, nb)
  if (any(num == 0)) return(length(p)^2)
  pr <- rbm_parts(tie, p, nb)
  sum(pmin(pr$nrow, num - pr$nrow)) + sum(pmin(pr$ncol, rep(num, each = nb) - pr$ncol))
}
rbm_errors_per_block <- function(tie, p, nb) {
  pr <- rbm_parts(tie, p, nb)
  num <- pr$num
  # rows of block a against its size; columns of block b against its size
  pmin(pr$nrow, matrix(num, nb, nb) - pr$nrow) +
    pmin(pr$ncol, matrix(num, nb, nb, byrow = TRUE) - pr$ncol)
}

# offdiagonalsum (xrbm's start): 1 - e within blocks plus e between them, i != j.
rbm_offdiag <- function(e, p, nb) {
  if (any(tabulate(p, nb) == 0)) return(length(p)^2)
  same <- outer(p, p, `==`)
  diag(same) <- NA
  sum(1 - e[which(same)]) + sum(e[which(!same)])
}

# ---- tabus (G1Tools/utabu.pas, the ivector overload) ---------------------------------

# Steepest descent with a tabu list. Every step makes the best move (the last of
# equal ones in node, then block, order), from a block with more than one
# member, that is not tabu; a move that does not lower the cost makes the old
# block tabu for that node for `penalty` steps. The search runs `maxit` steps
# past the last improvement. Returns the best partition seen and its cost.
tabus_g1 <- function(p, nv, maxit, penalty, costof, mincost = 1.1920929e-7) {
  n <- length(p)
  if (nv == 1L) return(list(p = p, cost = costof(p)))
  size <- tabulate(p, nv)
  if (any(size == 0) && n > nv) {
    # initializeD: each empty block takes the first node whose block (by the
    # sizes counted before the loop) has more than one member.
    for (j in seq_len(nv)) if (size[j] == 0) {
      for (i in seq_len(n)) if (size[p[i]] > 1) { p[i] <- j; break }
    }
    size <- tabulate(p, nv)
  }
  current <- costof(p)
  bestp <- p; bestf <- Inf
  if (current < mincost) return(list(p = p, cost = current))
  delta <- function() {
    d <- matrix(0, n, nv)
    for (i in seq_len(n)) for (j in seq_len(nv)) {
      if (j == p[i]) next
      if (size[p[i]] < 2) { d[i, j] <- 1e38; next }
      q <- p; q[i] <- j
      d[i, j] <- costof(q) - current
    }
    d
  }
  d <- delta()
  dok <- matrix(0L, n, nv)
  r <- maxit; change <- FALSE
  repeat {
    # getnext
    bd <- .Machine$double.xmax; bi <- 1L; oj <- p[1]; bj <- p[1]
    for (i in seq_len(n)) if (size[p[i]] > 1) for (j in seq_len(nv)) {
      if (dok[i, j] == 0L && p[i] != j && d[i, j] <= bd) {
        bd <- d[i, j]; bi <- i; oj <- p[i]; bj <- j
      }
    }
    if (bd >= 0) dok[bi, oj] <- penalty
    p[bi] <- bj
    current <- costof(p)
    size <- tabulate(p, nv)
    d <- delta()
    if (current < bestf) { bestf <- current; bestp <- p; change <- TRUE }
    if (current < mincost) break
    r <- r - 1L
    dok[dok > 0L] <- dok[dok > 0L] - 1L
    if (r > 0L) next
    if (change) { change <- FALSE; r <- maxit; next }
    break
  }
  list(p = bestp, cost = bestf)
}

# ---- km1 (G1Tools/Uclus.pas, sim = false) --------------------------------------------

# Seeds: the farthest pair (the later node first), then, one at a time, the
# node farthest from any single seed. Every other node joins its nearest seed.
# Strict comparisons, so the first of equals wins.
km1_g1 <- function(d, nb) {
  n <- nrow(d)
  best <- 1.4e-45; ni <- 2L; nj <- 1L
  for (i in 2:n) for (j in seq_len(i - 1)) {
    if (d[i, j] > best) { ni <- i; nj <- j; best <- d[i, j] }
  }
  seeds <- c(ni, nj)
  subsumed <- logical(n); subsumed[seeds] <- TRUE
  while (length(seeds) < nb) {
    best <- 1.4e-45; pick <- which(!subsumed)[1]
    for (s in seeds) for (j in seq_len(n)) {
      if (!subsumed[j] && d[s, j] > best) { pick <- j; best <- d[s, j] }
    }
    seeds <- c(seeds, pick); subsumed[pick] <- TRUE
  }
  p <- integer(n)
  p[seeds] <- seq_along(seeds)
  for (i in which(!subsumed)) {
    best <- .Machine$double.xmax
    for (kk in seq_along(seeds)) {
      if (d[i, seeds[kk]] < best) { p[i] <- kk; best <- d[i, seeds[kk]] }
    }
  }
  p
}

# ---- structural (xsbmb.pas / xsbmv.pas) ----------------------------------------------

sbm_run <- function(m, nb, valued, starts, maxit, penalty, seed, diagonal) {
  n <- nrow(m)
  use <- (diagonal | (row(m) != col(m))) & !is.na(m)
  x <- m; x[is.na(x)] <- 0
  tie <- x > 0
  cost <- if (valued) function(p) 2 - sbm_corr(x, use, p, nb)
          else function(p) sbm_hamming(tie, use, p, nb)
  rsq <- function(p) sbm_corr(x, use, p, nb)^2
  # simpleoptimization: swap the blocks of any two nodes in different blocks,
  # keeping a swap that lowers the cost; up to maxit passes.
  swaps <- function(p) {
    old <- cost(p)
    for (it in seq_len(maxit)) {
      any <- FALSE
      for (i in 2:n) for (j in seq_len(i - 1)) if (p[i] != p[j]) {
        q <- p; q[i] <- p[j]; q[j] <- p[i]
        f <- cost(q)
        if (f < old) { p <- q; old <- f; any <- TRUE }
      }
      if (!any) break
    }
    p
  }
  rng <- delphi_rng(seed)
  # getstartingpartition: n draws of Random(nb), then km1 on the profile
  # distance, rows and columns (UCINET issue 35, item 1: the column term).
  for (i in seq_len(n)) delphi_random(rng, nb)
  dist <- matrix(0, n, n)
  for (i in 2:n) for (j in seq_len(i - 1)) {
    kk <- if (diagonal) seq_len(n) else setdiff(seq_len(n), c(i, j))
    dist[i, j] <- dist[j, i] <- sum((x[i, kk] - x[j, kk])^2) + sum((x[kk, i] - x[kk, j])^2)
  }
  bestp <- swaps(km1_g1(dist, nb))
  if (valued) {
    bestfit <- rsq(bestp)
    log <- c("Initial partition", "", sprintf("R-square = %.3f", bestfit))
  } else {
    bestfit <- cost(bestp)
    log <- c("Initial partition", "", sprintf("Number of errors: %d", as.integer(bestfit)),
             sprintf("R-square = %.3f", rsq(bestp)))
  }
  log <- c(log, "")
  if (starts > 1) for (s in 2:starts) {
    if (!(bestfit > 1.1920929e-7)) break
    delphi_addseed(rng, 31)
    p <- vapply(seq_len(n), function(i) delphi_random(rng, nb), numeric(1)) + 1
    p <- tabus_g1(as.integer(p), nb, maxit, penalty, cost)$p
    p <- swaps(p)
    if (valued) {
      # UCINET issue 35, item 2: the start's own R-square, higher is better.
      fit <- rsq(p)
      log <- c(log, sprintf("Iteration %d R-square = %.3f", s, fit))
      if (fit > bestfit) { bestfit <- fit; bestp <- p }
    } else {
      fit <- cost(p)
      log <- c(log, sprintf("Iteration %d Number of errors: %d", s, as.integer(fit)))
      if (fit < bestfit) { bestfit <- fit; bestp <- p }
    }
  }
  cc <- sbm_counts(tie, use, bestp, nb)
  errs <- matrix(if (valued) NA_real_ else pmin(cc$ones, cc$cells - cc$ones), nb, nb)
  list(part = as.integer(bestp),
       errors = if (valued) NA_real_ else sbm_hamming(tie, use, bestp, nb),
       rsq = rsq(bestp), errors_per_block = errs, log = log)
}

# ---- regular (xrbm.pas) --------------------------------------------------------------

rbm_run <- function(m, nb, starts, maxit, penalty, seed, diagonal) {
  n <- nrow(m)
  raw <- m; raw[is.na(raw)] <- 0
  tie <- (raw > 0) * 1
  if (!diagonal) diag(tie) <- 0        # UCINET issue 35, item 4
  cost <- function(p) rbm_hamming(tie, p, nb)
  # simpleoptimization: each node in turn tries the other blocks and takes the
  # first that lowers the cost (UCINET issue 35, item 3: every other block,
  # not every block but the last); up to 50 passes.
  moves <- function(p) {
    old <- cost(p)
    for (it in 1:50) {
      any <- FALSE
      for (i in seq_len(n)) {
        pi_ <- p[i]
        for (j in seq_len(nb)) if (j != pi_) {
          p[i] <- j
          f <- cost(p)
          if (f < old) { old <- f; any <- TRUE; break }
          p[i] <- pi_
        }
      }
      if (!any) break
    }
    p
  }
  rng <- delphi_rng(seed)
  # getstartingpartition: n draws of Random(nb) as the partition, REGE, and the
  # tabu search on the REGE similarities (15 steps, penalty 7).
  p <- vapply(seq_len(n), function(i) delphi_random(rng, nb), numeric(1)) + 1
  e <- rege_iterate(list(raw), 3)
  bestp <- tabus_g1(as.integer(p), nb, 15L, 7L, function(q) rbm_offdiag(e, q, nb))$p
  log <- c("Initial Partition", sprintf("Number of errors: %d", as.integer(cost(bestp))))
  bestp <- moves(bestp)
  bestfit <- cost(bestp)
  log <- c(log, "Initial Partition", sprintf("Number of errors: %d", as.integer(bestfit)),
           "", "Iterations:")
  for (s in seq_len(starts)) {
    if (!(bestfit > 0)) break
    delphi_addseed(rng, 31)
    p <- vapply(seq_len(n), function(i) delphi_random(rng, nb), numeric(1)) + 1
    p <- tabus_g1(as.integer(p), nb, maxit, penalty, cost)$p
    p <- moves(p)
    fit <- cost(p)
    log <- c(log, sprintf("  No. of errors: %d", as.integer(fit)))
    if (fit < bestfit) { bestfit <- fit; bestp <- p }
  }
  list(part = as.integer(bestp), errors = bestfit, rsq = NA_real_,
       errors_per_block = rbm_errors_per_block(tie, bestp, nb), log = log)
}
