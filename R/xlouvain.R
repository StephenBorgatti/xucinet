# Louvain.
#
# UCINET: Network | Subgroups | Louvain Method (uc_Louvain.pas,
# tLouvainMethod.run; repository StephenBorgatti/ucinet at commit c7b4956),
# with the algorithm tlouvain in G2Tools/utlouvain.pas (run, movenodes,
# getbestmove, getq, storepart, aggregate; repository StephenBorgatti/tools at
# commit 207958a).
#
# Ported natively rather than run on igraph::cluster_louvain, because UCINET's
# version is deterministic and igraph's is not: nodes are visited in index
# order, every candidate move is scored by the Q it would give (UCINET
# recomputes Q in full; here the change in Q is computed directly, which is the
# same number, issue #19), and a node moves to the neighbouring cluster with
# the highest Q if that raises Q. Each
# level's partition is stored; the network is then aggregated (clusters
# become nodes, renumbered by sorted id, with their internal weight on the
# diagonal) and the process repeats until a level merges nothing.
#
# Two departures, both UCINET issue 26 (Steve, 23 Sep 2026: port it, but
# without these bugs). UCINET's getbestmove compares each move with the Q from
# before the pass rather than with the Q of leaving the node where it is, so it
# can make a move that lowers Q; here a move must raise the current Q. And
# UCINET reports, for each level, the Q from the last node it evaluated; here
# each level's Q is recomputed from its final partition.
#
# Dialog defaults: Max partitions blank (all levels); "For directed data" =
# Maximum/union (ItemIndex 1; the others are Do not symmetrize, Minimum,
# Average, Sum); negative values removed with a note; no starting partition.
#
# 2-mode data: UCINET's 2-Mode Bipartite Communities (Louvain) dialog
# (uc_2modelouvain.pas, ucinet commit c7b4956) with the engine TwoModeLouvain in
# G2Tools/u2modelouvain.pas (tools commit 207958a), ported in louvain_2mode()
# below. It maximizes Barber's (2007) bipartite modularity Q_b; each community
# can hold row and column nodes. One level of local moving, nodes visited in an
# order shuffled each sweep with Delphi's Random, so the seed reproduces
# UCINET's run. The book's dual projection is not offered (Steve, 26 Sep 2026,
# issue #18).
#
# Missing cells are 0 here; UCINET sums them into Q as 1e38 (UCINET issue 27).

#' Louvain community detection
#'
#' UCINET: Network | Subgroups | Louvain Method. Finds groups by maximizing
#' modularity: nodes move one at a time to whichever neighbouring group
#' raises modularity most, groups then become nodes, and the process repeats
#' on the smaller network until nothing more merges.
#'
#' Each level of that process is a partition; `$matrices$Levels` has them all,
#' headed with the number of clusters and the modularity as UCINET heads them,
#' and `Cluster` in the node table is the last. For 1-mode data the search is
#' deterministic by default, as UCINET's is: nodes are visited in their order.
#' `order = "random"` visits them in a random order instead, drawn afresh on
#' every pass, so that runs with different seeds show how robust a partition
#' is (book, 11.4.2). UCINET has no such option.
#'
#' **2-mode data** are UCINET's 2-Mode Bipartite Communities (Louvain): one
#' partition of the row and column nodes together that maximizes Barber's
#' bipartite modularity
#' \deqn{Q_b = \frac{1}{m}\sum_{i,j} \left(a_{ij} - \frac{r_i c_j}{m}\right)
#' \delta(g_i, g_j),}
#' the sum over row node \eqn{i} and column node \eqn{j}, with \eqn{r_i} and
#' \eqn{c_j} their weighted degrees and \eqn{m} the total weight. A community
#' may hold women and events together. Nodes are visited in a random order, so
#' the result depends on `seed`; the same seed gives UCINET's result. The node
#' table lists the rows, then the columns, with a `Mode` column, and the report
#' ends with the blocked matrix. `symmetrize` and `maxlevels` do not apply.
#'
#' Tie values are used as weights. Directed data are symmetrized by maximum
#' first unless `symmetrize` says otherwise; negative values are dropped.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Louvain Method. *Max partitions* is `maxlevels`;
#' *For directed data* is `symmetrize`.
#'
#' @param net A network (any accepted form), 1-mode or 2-mode.
#' @param symmetrize What to do with directed data: `"max"` (the default),
#'   `"min"`, `"average"`, `"sum"`, or `"none"`.
#' @param maxlevels The most levels to run. `NULL`, the default, runs until
#'   nothing merges.
#' @param relation Which relation of a multi-relation dataset, by name (in any case) or
#'   position. Defaults to the first.
#' @param order 1-mode data: `"fixed"` (the default, UCINET's) visits nodes in
#'   their order; `"random"` in a random order under `seed`.
#' @param seed For 2-mode data, and for `order = "random"`: the random seed, a
#'   whole number. `NULL` picks one between 1 and 1000 and reports it, so the
#'   run can be repeated.
#' @return An object of class `c("xlouvain", "xucinet_output")`.
#' @seealso [xcommunities()], [xgirvannewman()].
#' @examples
#' xlouvain(campnet)
#' xlouvain(zachary, order = "random", seed = 2)
#' xlouvain(davis, seed = 1)
#' @export
xlouvain <- function(net, symmetrize = c("max", "min", "average", "sum", "none"),
                     maxlevels = NULL, relation = NULL, seed = NULL,
                     order = c("fixed", "random")) {
  net <- xnet(net, substitute(net))
  symmetrize <- match.arg(symmetrize)
  order <- match.arg(order)
  if (identical(net$mode, "2-mode")) {
    return(xlouvain_2mode(net, relation, seed, match.call()))
  }
  rel <- ego_relation(net, relation, "xlouvain()")
  m <- rel$m
  labels <- rownames(m)
  assumptions <- rel$note

  w <- m
  w[is.na(w)] <- 0                           # UCINET issue 27
  if (any(w < 0)) {
    w[w < 0] <- 0
    assumptions <- c(assumptions, "Negative values removed.")
  }
  if (symmetrize != "none" && !isSymmetric(unname(w))) {
    w <- switch(symmetrize,
                max = pmax(w, t(w)),
                min = pmin(w, t(w)),
                average = (w + t(w)) / 2,
                sum = w + t(w))
    assumptions <- c(assumptions, paste0("Data symmetrized by ", symmetrize, "."))
  }

  if (order == "random") {
    if (is.null(seed)) seed <- sample.int(1000, 1)
    seed <- as.integer(seed)
    res <- with_seed(seed, louvain_levels(w, if (is.null(maxlevels)) nrow(w) else maxlevels,
                                          random = TRUE))
    assumptions <- c(assumptions, sprintf(
      "Nodes visited in a random order (seed %d); UCINET's order is fixed.", seed))
  } else {
    res <- louvain_levels(w, if (is.null(maxlevels)) nrow(w) else maxlevels)
  }
  levels <- res$hier
  rownames(levels) <- labels
  part <- levels[, ncol(levels)]

  new_xucinet_output(
    "Louvain Community Detection", net,
    nodes = community_nodes(part, labels),
    summary = community_summary(m, part),
    matrices = list(Levels = levels),
    assumptions = assumptions,
    fields = c("For directed data:" = c(max = "Maximum/union",
                                        min = "Minimum/intersection",
                                        average = "Average", sum = "Sum",
                                        none = "Do not symmetrize")[[symmetrize]]),
    print_nodes = FALSE,
    subclass = "xlouvain", call = match.call())
}

# tlouvain.run with the identity start and method 0 (every node, in order).
#
# Scored by the change in modularity rather than a full recomputation
# (issue #19). With S the total weight inside clusters, K_c a cluster's total
# row sum and m the total weight, Q = (S - sum K_c^2 / m) / m, and moving node
# i from cluster a to cluster b changes it by
#
#   (w_ib - w_ia) / m  -  ((K_a - d_i)^2 + (K_b + d_i)^2 - K_a^2 - K_b^2) / m^2
#
# where w_ic is the weight between i and the rest of c, both directions, and
# d_i is i's row sum. That is exactly the difference getq would compute; only
# the arithmetic is shorter. A move is made only if it raises Q by more than
# 1e-12, so that two routes to the same Q are a tie (first candidate wins, as
# in UCINET) rather than a coin toss decided by rounding.
louvain_levels <- function(w, maxpart, random = FALSE) {
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
  m <- sumofties

  getq <- function(part, net, deg) {
    same <- outer(part, part, "==")
    k <- tapply(deg, part, sum)
    (sum(net[same]) - sum(k^2) / m) / m
  }

  n <- noriginal
  part <- seq_len(n)
  currentq <- NA_real_
  for (it in seq_len(maxpart)) {
    deg <- rowSums(net)
    neighbors <- lapply(seq_len(n), function(i) which(net[i, ] > 0))
    both <- net + t(net)
    kc <- numeric(n)
    kc[seq_len(n)] <- tapply(deg, factor(part, levels = seq_len(n)), sum)
    kc[is.na(kc)] <- 0
    # movenodes
    anymoved <- TRUE
    while (anymoved) {
      anymoved <- FALSE
      # order = "random" (Steve, 26 Sep 2026, T11): a fresh order each pass.
      for (ego in if (random) sample.int(n) else seq_len(n)) {
        cands <- unique(part[neighbors[[ego]]])
        a <- part[ego]
        cands <- cands[cands != a]
        if (!length(cands)) next
        s <- both[ego, ]
        s[ego] <- 0
        d <- deg[ego]
        w_a <- sum(s[part == a])
        best_cluster <- a
        best_gain <- 0
        for (cl in cands) {
          gain <- (sum(s[part == cl]) - w_a) / m -
            ((kc[a] - d)^2 + (kc[cl] + d)^2 - kc[a]^2 - kc[cl]^2) / m^2
          if (gain > best_gain + 1e-12) {
            best_cluster <- cl
            best_gain <- gain
          }
        }
        if (best_cluster != a) {
          kc[a] <- kc[a] - d
          kc[best_cluster] <- kc[best_cluster] + d
          part[ego] <- best_cluster
          anymoved <- TRUE
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
    # aggregate: clusters become nodes, within-cluster weight on the diagonal.
    oldn <- n
    net <- t(rowsum(t(rowsum(net, part)), part))
    dimnames(net) <- NULL
    n <- nclus
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
# ---- 2-mode: uc_2modelouvain.pas / TwoModeLouvain --------------------------------

xlouvain_2mode <- function(net, relation, seed, call) {
  m <- pick_relation(net, relation)
  nr <- nrow(m); nc <- ncol(m)
  if (nr < 1 || nc < 1) stop("xlouvain(): the 2-mode matrix is empty.", call. = FALSE)
  if (is.null(seed)) seed <- sample.int(1000, 1)
  seed <- as.integer(seed)
  if (is.na(seed) || seed == 0) {
    stop("xlouvain(): seed must be a whole number other than 0.", call. = FALSE)
  }
  res <- louvain_2mode(m, seed)
  rlabs <- rownames(m); if (is.null(rlabs)) rlabs <- paste0("r", seq_len(nr))
  clabs <- colnames(m); if (is.null(clabs)) clabs <- paste0("c", seq_len(nc))
  labels <- c(rlabs, clabs)
  if (anyDuplicated(labels)) labels <- make.unique(labels)
  nodes <- data.frame(Cluster = res$part,
                      Mode = rep(c("row", "col"), c(nr, nc)),
                      row.names = labels, check.names = FALSE)
  rpart <- res$part[seq_len(nr)]; cpart <- res$part[nr + seq_len(nc)]
  mm <- m; mm[is.na(mm)] <- 0
  new_xucinet_output(
    "2-Mode Bipartite Communities (Louvain)", net,
    nodes = nodes,
    summary = list(Clusters = res$k,
                   `Row clusters` = length(unique(rpart)),
                   `Col clusters` = length(unique(cpart)),
                   Modularity = res$q,
                   Sweeps = res$sweeps, Moves = res$moves),
    assumptions = if (anyNA(m)) "Missing cells treated as 0, as UCINET does." else character(0),
    fields = c("Seed:" = format(seed)),
    epilogue = c("Blocked adjacency matrix:", "",
                 format_blocked_matrix(mm, rpart, cpart)),
    print_nodes = FALSE,
    subclass = "xlouvain", call = call)
}

# TwoModeLouvain, step for step. Node ids: rows 1..nr, columns nr + 1..nr + nc.
# Every node starts alone. Each sweep shuffles the visiting order (ShuffleArray:
# for i from n - 1 down to 1, swap order[i] with order[Random(i + 1)], 0-based)
# and moves each node to the neighbouring community that raises Q_b most, the
# first of equal gains winning, by more than 1e-12. Sweeps stop when nothing
# moves or after 201. Communities are then numbered by first appearance, rows
# first; Q_b is computed from the final partition.
louvain_2mode <- function(m, seed) {
  nr <- nrow(m); nc <- ncol(m); n <- nr + nc
  a <- unname(m); a[is.na(a)] <- 0
  nbr <- vector("list", n); wt <- vector("list", n)
  for (i in seq_len(nr)) { j <- which(a[i, ] != 0); nbr[[i]] <- nr + j; wt[[i]] <- a[i, j] }
  for (j in seq_len(nc)) { i <- which(a[, j] != 0); nbr[[nr + j]] <- i; wt[[nr + j]] <- a[i, j] }
  deg <- c(rowSums(a), colSums(a))
  tot <- sum(a)
  g <- seq_len(n)
  srow <- numeric(n); scol <- numeric(n)
  srow[seq_len(nr)] <- deg[seq_len(nr)]
  scol[nr + seq_len(nc)] <- deg[nr + seq_len(nc)]
  ord <- seq_len(n)
  rng <- delphi_rng(seed)
  sweeps <- 0L; moves <- 0L
  if (tot > 0) {
    repeat {
      moved <- FALSE
      sweeps <- sweeps + 1L
      for (i in (n - 1):1) {
        if (i < 1) break
        k <- delphi_random(rng, i + 1)
        tmp <- ord[i + 1]; ord[i + 1] <- ord[k + 1]; ord[k + 1] <- tmp
      }
      for (u in ord) {
        du <- deg[u]
        if (du == 0) next
        cur_c <- g[u]
        cs <- g[nbr[[u]]]
        cand <- unique(cs)
        e <- vapply(cand, function(cc) sum(wt[[u]][cs == cc]), numeric(1))
        opp <- if (u <= nr) scol else srow
        e_cur <- if (cur_c %in% cand) e[cand == cur_c] else 0
        cur <- e_cur - du * opp[cur_c] / tot
        best <- cur_c; best_gain <- 0
        for (h in seq_along(cand)) {
          if (cand[h] == cur_c) next
          gain <- (e[h] - du * opp[cand[h]] / tot) - cur
          if (gain > best_gain + 1e-12) { best_gain <- gain; best <- cand[h] }
        }
        if (best != cur_c) {
          if (u <= nr) {
            srow[cur_c] <- srow[cur_c] - du; srow[best] <- srow[best] + du
          } else {
            scol[cur_c] <- scol[cur_c] - du; scol[best] <- scol[best] + du
          }
          g[u] <- best
          moves <- moves + 1L
          moved <- TRUE
        }
      }
      if (!moved || sweeps > 200L) break
    }
  }
  part <- match(g, unique(g))
  list(part = part, k = max(part), q = bipartite_modularity(a, part[seq_len(nr)],
                                                            part[nr + seq_len(nc)]),
       sweeps = sweeps, moves = moves)
}

# Barber's Q_b (ComputeModularity).
bipartite_modularity <- function(a, rpart, cpart) {
  tot <- sum(a)
  if (tot <= 0) return(0)
  same <- outer(rpart, cpart, "==")
  (sum(a[same]) - sum(outer(rowSums(a), colSums(a))[same]) / tot) / tot
}

