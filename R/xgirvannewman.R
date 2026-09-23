# Girvan-Newman.
#
# UCINET: Network | Subgroups | Girvan-Newman (uc_GirvanNewman.pas,
# TGirvanNewman.run; repository StephenBorgatti/ucinet at commit c7b4956), with
# the algorithm in G1Tools/uGirvanNewman.pas (getedgebetweenness,
# getbetweennesspartition, girvannewmanclustering; repository
# StephenBorgatti/tools at commit 207958a).
#
# Ported natively rather than run on igraph::cluster_edge_betweenness, because
# the two remove edges differently. UCINET computes edge betweenness, rounds
# it to four decimals, and removes **every** edge tied for the maximum in one
# step; igraph removes one edge at a time and recomputes. On a network with
# tied edges the sequence of partitions can differ, and UCINET numbers win.
#
# Dialog: "Output partitions with no more than 10 clusters" (MaxClus.Text =
# 10). Directed data are symmetrized by maximum ("Data were symmetrized via
# the maximum method."). A partition is recorded whenever a removal step
# produces a component count not seen before; the loop stops when that count
# reaches the maximum or no edges are left.
#
# UCINET prints the partitions but no modularity for them; the modularity of
# each is added here as a short summary of the partitions (SPEC addendum,
# 23 Sep 2026), and `Cluster` in the node table is the partition where it is
# highest.

#' Girvan-Newman clustering
#'
#' UCINET: Network | Subgroups | Girvan-Newman. Divides the network by
#' repeatedly cutting the ties with the highest edge betweenness, the ones
#' most shortest paths run along, and records the partition into components
#' each time the number of components grows.
#'
#' `$matrices$Partitions` has one column per partition, headed as UCINET heads
#' them (`C2`, `C3`, ...), from fewest clusters to most, and
#' `$matrices$Modularity` the modularity of each. `Cluster` in the node table is
#' the partition with the highest modularity, and `$summary` reports that one.
#'
#' Ties in edge betweenness are removed together, as in UCINET. igraph's
#' `cluster_edge_betweenness()` removes them one at a time, so on networks with
#' such ties the two can pass through different partitions.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Girvan-Newman. *Output partitions with no more than
#' ... clusters* is `k`.
#'
#' @param net A network (any accepted form). 1-mode. Directed data are
#'   symmetrized by maximum; values are ignored.
#' @param k The most clusters to go to. UCINET's default is 10.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An object of class `c("xgirvannewman", "xucinet_output")`.
#' @seealso [xcommunities()], [xlouvain()].
#' @examples
#' xgirvannewman(campnet)
#' @export
xgirvannewman <- function(net, k = 10, relation = NULL) {
  net <- xnet(net, substitute(net))
  rel <- ego_relation(net, relation, "xgirvannewman()")
  m <- rel$m
  labels <- rownames(m)
  assumptions <- rel$note
  if (!isTRUE(isSymmetric(unname(m)))) {
    assumptions <- c(assumptions, "Data were symmetrized via the maximum method.")
  }
  a <- community_adjacency(m)

  parts <- girvan_newman_partitions(a, k)
  if (!ncol(parts)) {
    stop("xgirvannewman(): the network has no ties to remove.", call. = FALSE)
  }
  rownames(parts) <- labels
  q <- apply(parts, 2, function(p) community_modularity(m, p))
  best <- which.max(q)
  qmat <- matrix(q, 1, length(q), dimnames = list("Modularity", colnames(parts)))

  new_xucinet_output(
    "Girvan-Newman", net,
    nodes = community_nodes(parts[, best], labels),
    summary = community_summary(m, parts[, best]),
    matrices = list(Partitions = parts, Modularity = qmat),
    assumptions = assumptions,
    fields = c("Maximum no. of clusters:" = format(k)),
    print_nodes = FALSE,
    summary_title = "Partition with the highest modularity",
    subclass = "xgirvannewman", call = match.call())
}

# girvannewmanclustering: the partitions, one column per new component count,
# in the order they were found (fewest clusters first).
girvan_newman_partitions <- function(a, maxc) {
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
