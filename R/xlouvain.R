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
# 2-mode data: UCINET's 2-mode Louvain (uc_2modelouvain.pas) maximizes
# Barber's bipartite modularity, which is not the dual projection the 13.5.1
# text describes. Refused until Steve decides (issue #18).
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
#' and `Cluster` in the node table is the last. The search is deterministic, as
#' UCINET's is, so there is no seed.
#'
#' Tie values are used as weights. Directed data are symmetrized by maximum
#' first unless `symmetrize` says otherwise; negative values are dropped.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Louvain Method. *Max partitions* is `maxlevels`;
#' *For directed data* is `symmetrize`.
#'
#' @param net A network (any accepted form). 1-mode; 2-mode data wait on a
#'   decision (issue #18).
#' @param symmetrize What to do with directed data: `"max"` (the default),
#'   `"min"`, `"average"`, `"sum"`, or `"none"`.
#' @param maxlevels The most levels to run. `NULL`, the default, runs until
#'   nothing merges.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An object of class `c("xlouvain", "xucinet_output")`.
#' @seealso [xcommunities()], [xgirvannewman()].
#' @examples
#' xlouvain(campnet)
#' @export
xlouvain <- function(net, symmetrize = c("max", "min", "average", "sum", "none"),
                     maxlevels = NULL, relation = NULL) {
  net <- xnet(net, substitute(net))
  symmetrize <- match.arg(symmetrize)
  if (identical(net$mode, "2-mode")) {
    stop("xlouvain() does not take 2-mode data yet.\n",
         "  UCINET's 2-mode Louvain maximizes Barber's bipartite modularity, ",
         "not the dual projection the book describes;\n",
         "  which to follow is open (GitHub issue #18).", call. = FALSE)
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

  res <- louvain_levels(w, if (is.null(maxlevels)) nrow(w) else maxlevels)
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
louvain_levels <- function(w, maxpart) {
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
      for (ego in seq_len(n)) {
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
