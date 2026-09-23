# One entry point for the community-detection routines of chapter 11.
#
# Steve, 23 Sep 2026 (crosswalk annotation; issue #21): "include this function.
# The output consists [of] a node by method categorical matrix indicating
# cluster membership." So it runs every method, not one, and the node table
# has a column per method. It reads each routine's Cluster column rather than
# recomputing anything, as xcentralization() reads the centrality routines.

# Column label, and the routine that provides it.
community_methods <- list(
  Louvain            = "xlouvain",
  FastGreedy         = "xfastgreedy",
  GirvanNewman       = "xgirvannewman",
  LabelProp          = "xlabelpropagation",
  Factions           = "xfactions")

#' Community detection
#'
#' Runs all five of the chapter's community-detection methods and puts their
#' partitions side by side: `$nodes` has one column per method, the cluster each
#' node is in, and `$summary` one row per method with the number of clusters and
#' the modularity. Modularity is computed the same way for every method, so the
#' partitions can be compared on it directly.
#'
#' Each column is the `Cluster` column of the routine's own result: the
#' partition of the top level for Louvain, the highest-modularity partition for
#' fast greedy and Girvan-Newman, and the partition found for label propagation
#' and factions. Cluster numbers are labels, so the same group can carry
#' different numbers in different columns. For each method's own report, with
#' its extra tables, call the routine itself.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param ... Passed to every routine that takes the argument: `k` (the number
#'   of factions; it also sets what [xgirvannewman()] would print, which does
#'   not matter here), `seed` (label propagation and factions), `relation`, and
#'   so on. A method that fails is reported as missing, with the reason in
#'   `$assumptions`.
#' @return An object of class `c("xcommunities", "xucinet_output")`.
#' @seealso [xlouvain()], [xfastgreedy()], [xgirvannewman()],
#'   [xlabelpropagation()], [xfactions()].
#' @examples
#' xcommunities(campnet, seed = 1)
#' @export
xcommunities <- function(net, ...) {
  net <- xnet(net, substitute(net))
  dots <- list(...)
  m <- pick_relation(net, dots$relation)
  n <- nrow(m)

  nodes <- data.frame(row.names = rownames(m))
  summ <- data.frame(Clusters = rep(NA_integer_, length(community_methods)),
                     Modularity = NA_real_,
                     row.names = names(community_methods), check.names = FALSE)
  assumptions <- character()
  for (lab in names(community_methods)) {
    fn <- get(community_methods[[lab]], envir = asNamespace("xucinet"),
              mode = "function")
    args <- dots[names(dots) %in% names(formals(fn))]
    res <- tryCatch(do.call(fn, c(list(net), args)), error = function(e) e)
    if (inherits(res, "error")) {
      nodes[[lab]] <- rep(NA_integer_, n)
      assumptions <- c(assumptions, sprintf("%s: %s", lab, conditionMessage(res)))
      next
    }
    part <- res$nodes$Cluster
    nodes[[lab]] <- part
    summ[lab, ] <- community_summary(m, part)[c("Clusters", "Modularity")]
    assumptions <- c(assumptions, setdiff(res$assumptions, assumptions))
  }

  new_xucinet_output(
    "Community Detection", net,
    nodes = nodes, summary = summ,
    assumptions = assumptions,
    nodes_title = "Cluster membership by method",
    subclass = "xcommunities", call = match.call())
}
