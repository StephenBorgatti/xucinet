#' Closeness centrality
#'
#' UCINET: Network | Centrality | Closeness. How near a node is to all the
#' others.
#'
#' UCINET's dialog has no method selector: it reports **three** measures at once,
#' each with its own options, and prints which options it used. This function
#' does the same, and its defaults are UCINET's defaults, confirmed from the
#' golden run rather than chosen here:
#'
#' \describe{
#'   \item{`FreeClo`}{Freeman closeness. Unreachable pairs are set to the
#'     maximum observed distance plus one, then the score is `(n - 1) / sum(d)`.}
#'   \item{`ValClo`}{Valente-Forman reverse distance. `diameter + 1 - d`, zero
#'     where unreachable, averaged over `n - 1`, then divided by the diameter.}
#'   \item{`RecipClo`}{Reciprocal distance. `1/d`, zero where unreachable,
#'     averaged over `n - 1`.}
#' }
#'
#' Directed data gives six columns, an out and an in version of each, and
#' UCINET's naming is not quite parallel: the Freeman pair are `OutClose` and
#' `InClose`, not `OutFreeClo`.
#'
#' `undefined` covers the case SPEC D7 flags as a danger zone. The four values
#' are UCINET's four, in its own words: `"max1"` is *max observed distance plus
#' 1*, `"n"` is *N (number of nodes)*, `"zero"` is *ignore unreachables* and
#' computes closeness within components, `"avg"` substitutes the mean observed
#' distance. They apply to the Freeman measure; the other two have their own
#' fixed conventions, as UCINET's dialog does.
#'
#' @param net A network (any accepted form).
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param directed `NULL` (detect from symmetry), `TRUE` or `FALSE`.
#' @param undefined What to do with unreachable pairs: `"max1"` (default),
#'   `"n"`, `"zero"` or `"avg"`.
#' @return An `xucinet_output` whose `$nodes` holds the three measures, or six
#'   for directed data.
#' @examples
#' xcloseness(campnet)
#' @export
xcloseness <- function(net, relation = NULL, directed = NULL,
                       undefined = c("max1", "n", "zero", "avg")) {
  undefined <- match.arg(undefined)
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net, relation = relation)
  if (nrow(m) != ncol(m)) {
    stop("Closeness needs a square matrix; this one is ", nrow(m), " x ",
         ncol(m), ".", call. = FALSE)
  }
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- c(assumptions,
                     sprintf("Relation: %s (of %d).",
                             if (is.null(relation)) xrelations(net)[1] else relation,
                             xnrelations(net)))
  }
  a <- adjacency(m)
  sym <- if (is.null(directed)) isSymmetric(unname(a)) else !directed
  if (!is.null(directed) && !directed) a <- adjacency(symmetrize_max(a))

  n <- nrow(a)
  d <- geodesics(a)
  maxobs <- suppressWarnings(max(d, na.rm = TRUE))
  if (!is.finite(maxobs)) maxobs <- 0
  diameter <- maxobs

  substitute_for <- switch(undefined,
                           max1 = maxobs + 1,
                           n    = n,
                           zero = 0,
                           avg  = { obs <- d[!is.na(d) & d > 0]
                                    if (length(obs)) mean(obs) else 0 })

  # Freeman: substitute, sum, divide N-1 by the total.
  freeman <- function(dm) {
    dd <- dm; dd[is.na(dd)] <- substitute_for
    tot <- rowSums(dd)
    ifelse(tot > 0, (n - 1) / tot, NA_real_)
  }
  # Valente-Forman: reverse distance, zero where unreachable, averaged, then
  # divided by the diameter.
  valente <- function(dm) {
    rd <- diameter + 1 - dm
    rd[is.na(rd)] <- 0
    diag(rd) <- 0
    if (diameter > 0) (rowSums(rd) / (n - 1)) / diameter else rep(NA_real_, n)
  }
  # Reciprocal distance: 1/d, zero where unreachable, averaged over n - 1.
  reciprocal <- function(dm) {
    rr <- 1 / dm
    rr[!is.finite(rr)] <- 0
    rowSums(rr) / (n - 1)
  }

  labels <- rownames(m)
  if (sym) {
    nodes <- data.frame(FreeClo = freeman(d), ValClo = valente(d),
                        RecipClo = reciprocal(d),
                        row.names = labels, check.names = FALSE)
  } else {
    # "Out" reads along the rows, "In" along the columns.
    td <- t(d)
    nodes <- data.frame(OutClose = freeman(d),    InClose = freeman(td),
                        OutValClo = valente(d),   InValClo = valente(td),
                        OutRecipClo = reciprocal(d),
                        InRecipClo = reciprocal(td),
                        row.names = labels, check.names = FALSE)
  }

  assumptions <- c(
    assumptions,
    sprintf("(Freeman) Set undefined distances to: %s",
            switch(undefined,
                   max1 = "Max observed distance plus 1",
                   n    = "N (number of nodes)",
                   zero = "Missing (ignore unreachables)",
                   avg  = "Mean observed distance")),
    "(Freeman) Output options: Divide totals into N-1 (Freeman normalization)",
    "(Valente-Forman) Handle undefined distances: Set reverse distance to zero",
    "(Valente-Forman) Output options: Divide averages by diameter",
    "(Reciprocal) Handle undefined distances: Set reciprocal distance to zero",
    "(Reciprocal) Output options: Averages")

  out <- new_xucinet_output(
    "Closeness centrality measures", net,
    nodes = nodes, assumptions = assumptions,
    nodes_title = NULL,
    stats_block = FALSE,          # uc_ClosenessMeasures.pas prints none
    subclass = "xcloseness", call = match.call())
  out$primary <- if (sym) "FreeClo" else "OutClose"
  out
}
