# Components.
#
# UCINET: Network | Regions | Components (uc_Components.pas / .dfm, repository
# StephenBorgatti/ucinet at commit c7b4956), with the heterogeneity measures
# from G2Tools/utfrequencies5.pas, tfrequencies.getheterogeneity (repository
# StephenBorgatti/tools at commit 207958a).
#
# The dialog's "For directed data" group defaults to Weak Components
# (Method.ItemIndex = 0), and the two branches differ in what they hand to the
# component finder:
#
#   weak    d.symmetrize, then getcomponents
#   strong  d.getreachabilities, then r.symmetrize(sy_inter) - the mutual
#           reachability matrix - then getcomponents
#
# The five figures under the size table come from getheterogeneity, and the
# call passes the NODE count as `ncat`, so the normalizations are against
# "every node in its own component" rather than against the number of
# components observed. That is also why UCINET's closing note - "Normalized
# heterogeneity equals fragmentation in undirected graphs" - is exactly true:
# iqv works out to (n^2 - sum s_k^2)/(n(n-1)), which is the proportion of
# ordered pairs in different components.

#' Components
#'
#' UCINET: Network | Regions | Components. The pieces a network falls into,
#' with the membership per node and UCINET's heterogeneity figures.
#'
#' A **weak** component ignores the direction of ties; a **strong** one
#' requires each node to reach every other and be reached back. Isolates are
#' components of size 1, as in UCINET.
#'
#' `Normalized heterogeneity` is the fragmentation of the network - the
#' proportion of ordered pairs that fall in different components - which is
#' the identity UCINET's own log points out.
#'
#' @param net A network (any accepted form). For 2-mode data the bipartite
#'   graph is used, so a component may contain nodes of both modes.
#' @param type `"weak"` (the dialog's default) or `"strong"`.
#' @param min Report only components of at least this size. Nodes in smaller
#'   ones come back `NA`. UCINET's dialog has no such option; this is an
#'   addition, and `min = 1` is the behaviour it has.
#' @param sortby Order the size table by `"size"` (the dialog's default) or by
#'   `"id"`.
#' @return An object of class `c("xcomponents", "xucinet_output")`. `$nodes`
#'   holds the component of each node in the original order; `$summary` the
#'   count and the five heterogeneity figures; `$matrices$Sizes` the size
#'   table.
#' @seealso [xcohesion()], whose `Components` is the strong count, and
#'   [xgeodesic()].
#' @examples
#' xcomponents(campnet)
#' xcomponents(campnet, type = "strong")
#' @export
xcomponents <- function(net, type = c("weak", "strong"), min = 1,
                        sortby = c("size", "id")) {
  net <- xnet(net, substitute(net))
  type <- match.arg(type)
  sortby <- match.arg(sortby)

  m <- pick_relation(net, NULL)
  assumptions <- character(0)
  if (is_valued(m)) assumptions <- c(assumptions, "Data dichotomized at > 0.")

  # A 2-mode dataset becomes its bipartite graph, so that rows and columns can
  # share a component.
  if (identical(net$mode, "2-mode")) {
    a <- bipartite(binary_offdiag_rect(m))
    labs <- c(rownames(m), colnames(m))
    assumptions <- c(assumptions,
                     "2-mode data treated as the bipartite graph.")
  } else {
    a <- binary_offdiag(m)
    labs <- rownames(m)
  }
  dimnames(a) <- list(labs, labs)

  comp <- if (identical(type, "weak")) {
    components_of(symmetrize_max(a))
  } else {
    strong_components(a)
  }

  sizes <- table(comp)
  small <- as.integer(names(sizes)[sizes < min])
  if (length(small)) {
    comp[comp %in% small] <- NA_integer_
    assumptions <- c(assumptions,
                     paste0(length(small), " component",
                            if (length(small) == 1) "" else "s",
                            " below min = ", min, " dropped."))
  }
  # Renumber what is left so the ids run 1..k without gaps, as UCINET's do.
  keep <- sort(unique(comp[!is.na(comp)]))
  comp <- match(comp, keep)

  n <- length(labs)
  het <- heterogeneity(comp, n)
  tab <- table(comp)
  ord <- if (identical(sortby, "size")) order(-as.vector(tab), as.integer(names(tab)))
         else order(as.integer(names(tab)))
  size_mat <- matrix(as.vector(tab)[ord], ncol = 1,
                     dimnames = list(names(tab)[ord], "Size"))

  new_xucinet_output(
    "Components", net,
    nodes = data.frame(Node = labs, Component = comp,
                       stringsAsFactors = FALSE),
    summary = c(list(Components = length(keep)), het),
    matrices = list(Sizes = size_mat),
    assumptions = assumptions, subclass = "xcomponents",
    nodes_title = "Component membership",
    summary_title = "Component statistics")
}

# A rectangular incidence matrix, dichotomized, with no diagonal to remove.
binary_offdiag_rect <- function(m) {
  a <- (m > 0) * 1
  a[is.na(a)] <- 0
  storage.mode(a) <- "double"
  a
}

# getheterogeneity, with ncat = the number of nodes, which is how
# uc_Components calls it.
heterogeneity <- function(comp, n) {
  obs <- comp[!is.na(comp)]
  k <- length(unique(obs))
  if (!length(obs) || k == 0) {
    return(list("Component ratio" = NA_real_, "Heterogeneity" = NA_real_,
                "Normalized heterogeneity" = NA_real_, "Entropy" = NA_real_,
                "Normalized entropy" = NA_real_))
  }
  tot <- length(obs)
  p <- as.vector(table(obs)) / tot
  het <- 1 - sum(p^2)
  list(
    "Component ratio" = (k - 1) / (tot - 1),
    "Heterogeneity" = het,
    # ncat is n, so the ceiling is one component per node.
    "Normalized heterogeneity" = if (k > 1) het / (1 - 1 / n) else 0,
    "Entropy" = -sum(p * log(p)),
    "Normalized entropy" = -sum(p * log(p)) / log(n))
}
