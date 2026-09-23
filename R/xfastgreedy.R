# Fast greedy and label propagation, on igraph.
#
# UCINET has both (Network | Subgroups | FastGreedy, uc_FastGreedy.pas; ...
# | Label Propagation, uc_LabelPropagation.pas; repository
# StephenBorgatti/ucinet at commit c7b4956), but the chapter 11 prompt and
# design answer G1 put these two on igraph: igraph::cluster_fast_greedy (the
# Clauset-Newman-Moore agglomeration) and igraph::cluster_label_prop. Where the
# results differ from UCINET's the ledger says why (entry 28): UCINET's
# FastGreedy starts from a clique-based partition by default (Initial
# Partition = Clique-based) rather than from singletons, and switches to a
# Louvain variant above 100 nodes; label propagation is random in both, with
# different generators.
#
# Both work on the undirected graph: a tie in either direction, the larger
# value as its weight, missing cells and the diagonal ignored, which is what
# UCINET's FastGreedy does to its input (`clean`: max-symmetrize, zero the
# diagonal).

#' Fast greedy community detection
#'
#' Clauset, Newman and Moore's agglomerative method: every node starts in its
#' own group, and the pair of groups whose merger raises modularity most is
#' merged, until no merger raises it. The partition with the highest
#' modularity is returned.
#'
#' Computed by `igraph::cluster_fast_greedy()`. UCINET's own FastGreedy
#' (Network | Subgroups | FastGreedy) starts by default from a partition built
#' from cliques rather than from single nodes, so its answer can differ; see
#' the differences ledger.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | FastGreedy, with *Initial Partition* set to Identity.
#'
#' @param net A network (any accepted form). 1-mode. Directed data are
#'   symmetrized by maximum; tie values are used as weights.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An object of class `c("xfastgreedy", "xucinet_output")` with
#'   `Cluster` in `$nodes` and the number of clusters and modularity in
#'   `$summary`.
#' @seealso [xcommunities()], [xlouvain()].
#' @examples
#' xfastgreedy(campnet)
#' @export
xfastgreedy <- function(net, relation = NULL) {
  net <- xnet(net, substitute(net))
  rel <- ego_relation(net, relation, "xfastgreedy()")
  m <- rel$m
  g <- community_igraph(m)
  part <- if (igraph::ecount(g) > 0) {
    renumber_first(as.integer(igraph::membership(igraph::cluster_fast_greedy(g))))
  } else seq_len(nrow(m))
  community_output("FastGreedy Community Detection", net, m, part, rel$note,
                   "xfastgreedy", match.call())
}

#' Label propagation
#'
#' Every node starts with its own label and repeatedly adopts the label most
#' common among its neighbours, until each node holds a label at least as
#' common around it as any other. Groups are the nodes sharing a label.
#'
#' Computed by `igraph::cluster_label_prop()`. The method is random: it visits
#' the nodes in a random order and breaks ties at random, so different seeds can
#' give different partitions. UCINET's Label Propagation is random too, with its
#' own generator, so the two agree only by chance on networks without clear
#' groups.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Label Propagation.
#'
#' @inheritParams xfastgreedy
#' @param seed A random seed, for a repeatable result. `NULL` uses R's current
#'   random state. R's global random state is left as it was either way.
#' @return An object of class `c("xlabelpropagation", "xucinet_output")` with
#'   `Cluster` in `$nodes` and the number of clusters and modularity in
#'   `$summary`.
#' @seealso [xcommunities()].
#' @examples
#' xlabelpropagation(campnet, seed = 1)
#' @export
xlabelpropagation <- function(net, seed = NULL, relation = NULL) {
  net <- xnet(net, substitute(net))
  rel <- ego_relation(net, relation, "xlabelpropagation()")
  m <- rel$m
  g <- community_igraph(m)
  part <- with_seed(seed, {
    if (igraph::ecount(g) > 0) {
      as.integer(igraph::membership(igraph::cluster_label_prop(g)))
    } else seq_len(nrow(m))
  })
  community_output("Label Propagation", net, m, renumber_first(part),
                   c(rel$note, if (!is.null(seed)) paste0("Random seed: ", seed, ".")),
                   "xlabelpropagation", match.call())
}

# The undirected weighted graph both routines run on.
community_igraph <- function(m) {
  w <- community_matrix(m)
  w[w < 0] <- 0
  igraph::graph_from_adjacency_matrix(w, mode = "undirected",
                                      weighted = TRUE, diag = FALSE)
}

# Run code under a seed without disturbing the caller's random state.
with_seed <- function(seed, code) {
  if (is.null(seed)) return(code)
  had <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had) old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  on.exit({
    if (had) assign(".Random.seed", old, envir = globalenv())
    else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  })
  set.seed(seed)
  code
}

# The report every partition-only routine shares: `Cluster` in the node table,
# clusters and modularity in the summary, and the groups listed as UCINET
# lists them.
community_output <- function(routine, net, m, part, assumptions, subclass, call) {
  labels <- rownames(m)
  groups <- vapply(sort(unique(part)), function(g) {
    paste0(formatC(g, width = 5), ":  ", paste(labels[part == g], collapse = " "))
  }, character(1))
  new_xucinet_output(
    routine, net,
    nodes = community_nodes(part, labels),
    summary = community_summary(m, part),
    assumptions = assumptions,
    preamble = c("Group Assignments:", "", groups),
    print_nodes = FALSE,
    subclass = subclass, call = call)
}
