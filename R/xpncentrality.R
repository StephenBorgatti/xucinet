#' PN centrality for signed networks
#'
#' UCINET: Network | Centrality | PN. Everett and Borgatti's measure for
#' networks with both positive and negative ties, where a negative tie is not
#' simply the absence of a positive one.
#'
#' Ported from `runPNcentrality` in `Xdpmat.pas`, which fixes both of its
#' parameters rather than exposing them. The matrix is symmetrized, every
#' negative entry is doubled, and the score is the row sums of
#' `(I + beta*A)^-1` with `beta = -1 / (2(n-1))`. Those two constants -- the
#' negative weight of 2 and that beta -- are UCINET's, printed in its own log,
#' and are not arguments here because they are not arguments there.
#'
#' The measure is designed for a signed matrix. Run on an all-positive network
#' it still computes, and reduces to something close to a beta centrality with a
#' small negative beta, but the interpretation the measure was built for is
#' gone; a note says so.
#'
#' @param net A network (any accepted form), ideally signed.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @return An `xucinet_output` whose `$nodes` has one column, `PN`.
#' @examples
#' # newguinea has an Alliance relation and an Opposition relation; a signed
#' # matrix is the first minus the second.
#' xpncentrality(as.matrix(newguinea, relation = "Alliance") -
#'               as.matrix(newguinea, relation = "Opposition"))
#' @export
xpncentrality <- function(net, relation = NULL) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("PN centrality needs a square matrix; this one is ", nrow(m), " x ",
         ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  if (!any(m < 0, na.rm = TRUE)) {
    assumptions <- c(assumptions,
                     paste("No negative ties in this matrix. PN is defined for",
                           "signed networks; the result is well formed but not",
                           "what the measure was built to say."))
  }

  n <- nrow(m)
  beta <- -1 / (2 * (n - 1))
  negwt <- 2

  a <- symmetrize_max(m)
  a[is.na(a)] <- 0
  a[a < 0] <- a[a < 0] * negwt

  mm <- beta * a
  diag(mm) <- diag(mm) + 1
  v <- rowSums(solve(mm))

  nodes <- data.frame(PN = v, row.names = rownames(m), check.names = FALSE)

  out <- new_xucinet_output(
    "PN centrality", net,
    nodes = nodes,
    summary = list(Beta = beta, `Negative weight` = negwt),
    assumptions = assumptions,
    nodes_title = paste0("PN centrality for dataset ", net$title),
    stats_block = FALSE,
    subclass = "xpncentrality", call = match.call())
  out$primary <- "PN"
  out
}
