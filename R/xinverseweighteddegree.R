#' Inverse-weighted degree centrality
#'
#' UCINET: Network | Centrality | Inverse-Weighted Degree. Degree in which each
#' tie is weighted by the inverse of the other node's degree, so a tie to a
#' node with few ties counts for more than a tie to one with many.
#'
#' Ported from `Tiwdcentrality.run` in `uc_iwdcentrality.pas` (repository
#' StephenBorgatti/ucinet at commit c7b4956). With row totals `r` and column
#' totals `c`,
#'
#' \describe{
#'   \item{`OutIWD`}{`sum_j x[i,j] / c[j]`: i's ties, each weighted by the
#'     inverse of the alter's indegree.}
#'   \item{`InIWD`}{`sum_i x[i,j] / r[i]`: the column sums of the
#'     row-stochastic matrix.}
#' }
#'
#' For symmetric data the two are the same and only one is reported, as `IWD`.
#' The normalized scores divide by `n - 1`, the largest possible raw score,
#' since every term is at most 1. Both versions are always in `$nodes`;
#' `normalize` chooses which is printed first. UCINET's own output is the
#' normalized one.
#'
#' Three things differ from UCINET 6.849, which has faults here (UCINET issue
#' 28, ledger entry 33): the diagonal is always excluded, the totals are
#' computed for the relation analysed, and the normalized score is `raw/(n-1)`
#' for valued data as well as binary.
#'
#' @param net A network (any accepted form). 1-mode. Missing cells count as 0.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param normalize Print the normalized scores first? `TRUE`, the default,
#'   as UCINET's dialog.
#' @return An object of class `c("xinverseweighteddegree", "xucinet_output")`
#'   whose `$nodes` holds `OutIWD`, `InIWD`, `nOutIWD` and `nInIWD`, or `IWD`
#'   and `nIWD` for symmetric data.
#' @seealso [xdegree()].
#' @examples
#' xinverseweighteddegree(campnet)
#' @export
xinverseweighteddegree <- function(net, relation = NULL, normalize = TRUE) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Inverse-weighted degree needs a square matrix; this one is ", nrow(m),
         " x ", ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }

  n <- nrow(m)
  sym <- isSymmetric(unname(m))
  x <- m
  x[is.na(x)] <- 0                   # recodena
  diag(x) <- 0                       # UCINET issue 28(1): diagok is never set
  r <- rowSums(x)                    # issue 28(2): per relation
  cc <- colSums(x)
  inv_c <- ifelse(cc != 0, 1 / cc, 0)
  inv_r <- ifelse(r != 0, 1 / r, 0)
  out_iwd <- as.vector(x %*% inv_c)
  in_iwd <- as.vector(crossprod(x, inv_r))
  den <- n - 1                       # issue 28(3): no maxval factor

  labels <- rownames(m)
  if (sym) {
    nodes <- data.frame(IWD = out_iwd, nIWD = out_iwd / den,
                        row.names = labels, check.names = FALSE)
    shown <- if (isTRUE(normalize)) c("nIWD", "IWD") else c("IWD", "nIWD")
  } else {
    nodes <- data.frame(OutIWD = out_iwd, InIWD = in_iwd,
                        nOutIWD = out_iwd / den, nInIWD = in_iwd / den,
                        row.names = labels, check.names = FALSE)
    shown <- if (isTRUE(normalize)) {
      c("nOutIWD", "nInIWD", "OutIWD", "InIWD")
    } else {
      c("OutIWD", "InIWD", "nOutIWD", "nInIWD")
    }
  }

  out <- new_xucinet_output(
    "Inverse-Weighted Degree Centrality", net,
    nodes = nodes, assumptions = assumptions,
    nodes_title = if (isTRUE(normalize)) {
      "Normalized Inverse-Weighted Degree Centrality"
    } else {
      "Inverse-Weighted Degree Centrality"
    },
    show_columns = shown,
    subclass = "xinverseweighteddegree", call = match.call())
  out$primary <- shown[1]
  out
}
