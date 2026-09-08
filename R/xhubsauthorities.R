#' Hubs and authorities
#'
#' UCINET: Network | Centrality | Hubs & Authorities. Kleinberg's HITS. A good
#' authority is pointed to by good hubs; a good hub points to good authorities.
#'
#' The hub scores are the principal eigenvector of `A A'` and the authority
#' scores that of `A' A`, each scaled to unit length. The measure only says
#' anything on directed data: on a symmetric matrix the two coincide and both
#' reduce to eigenvector centrality, and a note says so.
#'
#' UCINET returns both columns **negative**, which its 1-mode eigenvector
#' routine does not; the sign of an eigenvector is arbitrary but the convention
#' is to report centrality positive. We flip it, as `runeigencent` does. That is
#' issue 2 on the UCINET list, and the reason the golden test compares against
#' the absolute values of the fixture.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An `xucinet_output` whose `$nodes` has `Hub` and `Authority`.
#' @examples
#' xhubsauthorities(campnet)
#' @export
xhubsauthorities <- function(net, relation = NULL) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Hubs and authorities needs a square matrix; this one is ", nrow(m),
         " x ", ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  a <- m
  a[is.na(a)] <- 0
  if (isSymmetric(unname(a))) {
    assumptions <- c(
      assumptions,
      paste("Data are symmetric, so hubs and authorities coincide and both",
            "reduce to eigenvector centrality."))
  }

  hub <- principal_eigen(a %*% t(a))$vector
  aut <- principal_eigen(t(a) %*% a)$vector

  nodes <- data.frame(Hub = hub, Authority = aut,
                      row.names = rownames(m), check.names = FALSE)

  out <- new_xucinet_output(
    "Hubs and authorities", net,
    nodes = nodes,
    summary = list(`No. of dimensions` = 1),
    assumptions = c(assumptions,
                    paste("Scores are reported positive. UCINET returns them",
                          "negative, which its eigenvector routine does not.")),
    nodes_title = NULL,
    stats_block = FALSE,
    subclass = "xhubsauthorities", call = match.call())
  out$primary <- "Authority"
  out
}
