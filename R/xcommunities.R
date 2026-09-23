# One entry point for the community-detection routines of chapter 11.

#' Community detection
#'
#' Runs one of the chapter's community-detection methods and returns the same
#' shape whatever the method: `Cluster` in `$nodes`, and `Clusters` and
#' `Modularity` in `$summary`, with the method in `$method`. Modularity is computed the same way
#' for every method, so partitions found by different methods can be compared
#' on it directly.
#'
#' For each method's own report, with its extra tables, call the routine
#' itself: [xlouvain()], [xfastgreedy()], [xgirvannewman()],
#' [xlabelpropagation()] or [xfactions()].
#'
#' @param net A network (any accepted form). 1-mode.
#' @param method `"louvain"` (the default), `"fastgreedy"`, `"girvannewman"`,
#'   `"labelpropagation"` or `"factions"`.
#' @param ... Passed to the routine: `k` for factions, `seed` for label
#'   propagation and factions, and so on.
#' @return An object of class `c("xcommunities", "xucinet_output")`.
#' @examples
#' xcommunities(campnet)
#' xcommunities(campnet, method = "fastgreedy")
#' @export
xcommunities <- function(net, method = c("louvain", "fastgreedy",
                                         "girvannewman", "labelpropagation",
                                         "factions"), ...) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  fn <- switch(method,
               louvain = xlouvain, fastgreedy = xfastgreedy,
               girvannewman = xgirvannewman,
               labelpropagation = xlabelpropagation, factions = xfactions)
  res <- fn(net, ...)
  m <- pick_relation(net, list(...)$relation)
  part <- res$nodes$Cluster
  labels <- rownames(res$nodes)
  label <- c(louvain = "Louvain", fastgreedy = "Fast greedy",
             girvannewman = "Girvan-Newman",
             labelpropagation = "Label propagation", factions = "Factions")[[method]]
  groups <- vapply(sort(unique(part)), function(g) {
    paste0(formatC(g, width = 5), ":  ", paste(labels[part == g], collapse = " "))
  }, character(1))
  out <- new_xucinet_output(
    "Community Detection", net,
    nodes = res$nodes,
    summary = community_summary(m, part),
    assumptions = res$assumptions,
    fields = c("Method:" = label),
    preamble = c("Group Assignments:", "", groups),
    print_nodes = FALSE,
    subclass = "xcommunities", call = match.call())
  out$method <- method
  out
}
