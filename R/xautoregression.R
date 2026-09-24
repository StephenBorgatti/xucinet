# Network autoregression.
#
# UCINET has no routine for this model: the menu item the first edition of the
# book named (Tools | Testing Hypotheses | Node-level | Autoregressive Model) is
# not in the current source, and uc_AutoCorrelation.pas, which measures
# autocorrelation rather than fitting a model, is not reachable from any menu
# (xucinet issue #28). Steve decided on 24 Sep 2026 to wrap sna::lnam (Butts),
# the maximum-likelihood network autocorrelation model of Doreian (1980) and
# Ord (1975), rather than port or write one. sna stays in Suggests; lnam itself
# needs numDeriv for the standard errors. Ledger entry 43.
#
# What xucinet adds to lnam: the network in any accepted form, the variables
# looked up in the network's attribute table, the weight matrix row-normalized
# by default (the usual convention, so rho is the effect of the mean of one's
# alters), the diagonal cleared, and the report in the package's layout.

#' Network autoregression
#'
#' Regression of a node attribute on others when the nodes' values depend on
#' one another through the network (book, 14.4). The **lag** model (network
#' effects) is
#' \deqn{y = \rho W y + X\beta + \epsilon,}
#' in which each node's value is pulled toward the values of the nodes it is
#' tied to; the **error** model (network disturbances) is
#' \deqn{y = X\beta + u, \quad u = \lambda W u + \epsilon,}
#' in which the unexplained parts are correlated along the ties. \eqn{W} is the
#' network, row-normalized by default. The model is fitted by maximum
#' likelihood with [sna::lnam()], which this function wraps; the `sna` and
#' `numDeriv` packages must be installed.
#'
#' @section UCINET equivalent:
#' None. UCINET has no network autoregression routine (see the differences
#' ledger).
#'
#' @param net A network (any accepted form), 1-mode: the weight matrix \eqn{W}.
#'   Row \eqn{i} says whose values influence node \eqn{i}.
#' @param formula A model formula, `y ~ x1 + x2`.
#' @param data Where the variables are: a data frame (rows named by node
#'   label, or in node order), a node-level result, or a network with
#'   attributes. `NULL` uses `net`'s own attribute table, then the place the
#'   formula was written.
#' @param model `"lag"` (the default) or `"error"`.
#' @param normalize Row-normalize \eqn{W}? `TRUE` by default. Rows of isolates
#'   stay zero.
#' @param relation Which relation of a multirelational network is \eqn{W}.
#' @return An object of class `c("xautoregression", "xucinet_output")`.
#'   `$matrices` has the coefficient table (`Coef`, `SE`, `Z`, `Sig`),
#'   the network parameter (`Rho` or `Lambda`) in its last row. `$summary` has
#'   the number of nodes, sigma, the log-likelihood of the model and of the
#'   intercept-only null model, and the AIC and BIC. `$nodes` has the fitted
#'   values and residuals.
#' @seealso [xregression()] for the same regression without the network term.
#' @examples
#' \donttest{
#' if (requireNamespace("sna", quietly = TRUE) &&
#'     requireNamespace("numDeriv", quietly = TRUE)) {
#'   deg <- xdegree(campnet)$nodes
#'   d <- data.frame(indeg = deg[["Indeg"]], btw = xbetweenness(campnet)$nodes[[1]],
#'                   row.names = rownames(deg))
#'   xautoregression(campnet, indeg ~ btw, d)
#' }
#' }
#' @export
xautoregression <- function(net, formula, data = NULL, model = c("lag", "error"),
                            normalize = TRUE, relation = NULL) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xautoregression()")
  model <- match.arg(model)
  need_pkg("sna", "xautoregression()")
  need_pkg("numDeriv", "xautoregression()")

  w <- pick_relation(net, relation)
  labs <- rownames(w)
  n <- nrow(w)
  if (anyNA(w)) {
    stop("xautoregression() needs a complete network: W has missing cells.",
         call. = FALSE)
  }

  d <- if (!is.null(data)) node_data(data) else xattributes(net)
  if (!is.null(d)) {
    if (!is.null(labs) && all(labs %in% rownames(d))) {
      d <- d[labs, , drop = FALSE]
    } else if (nrow(d) != n) {
      stop("the data have ", nrow(d), " rows but the network has ", n,
           " nodes, and the row names are not the node labels.", call. = FALSE)
    }
  }
  mf <- stats::model.frame(formula, data = d, na.action = stats::na.pass)
  y <- as.numeric(stats::model.response(mf))
  x <- stats::model.matrix(formula, mf)
  if (length(y) != n) {
    stop("the dependent variable has ", length(y), " values but the network has ",
         n, " nodes.", call. = FALSE)
  }
  if (anyNA(y) || anyNA(x)) {
    stop("xautoregression() needs complete data: dropping a node would change ",
         "the network the model is about.", call. = FALSE)
  }
  yname <- deparse1(formula[[2]])

  assumptions <- character(0)
  w <- unname(w)
  if (any(diag(w) != 0)) {
    diag(w) <- 0
    assumptions <- c(assumptions, "Diagonal of W set to zero.")
  }
  if (isTRUE(normalize)) {
    rs <- rowSums(w)
    w[rs != 0, ] <- w[rs != 0, , drop = FALSE] / rs[rs != 0]
    assumptions <- c(assumptions, "W row-normalized.")
  }

  fit <- if (model == "lag") sna::lnam(y, x, W1 = w) else sna::lnam(y, x, W2 = w)

  pname <- if (model == "lag") "Rho" else "Lambda"
  est <- c(as.vector(fit$beta), if (model == "lag") fit$rho1 else fit$rho2)
  se <- c(as.vector(fit$beta.se), if (model == "lag") fit$rho1.se else fit$rho2.se)
  z <- est / se
  coef <- cbind(Coef = est, SE = se, Z = z, Sig = 2 * stats::pnorm(-abs(z)))
  rownames(coef) <- c(sub("^\\(Intercept\\)$", "Intercept", colnames(x)), pname)

  ll <- as.numeric(fit$lnlik.model)
  k <- as.numeric(fit$df.model)
  summary <- list(
    Nobs = n, Sigma = as.numeric(fit$sigma), LogLik = ll,
    `Null LL` = as.numeric(fit$lnlik.null),
    AIC = -2 * ll + 2 * k, BIC = -2 * ll + log(n) * k)
  nodes <- data.frame(`Y-Hat` = as.vector(fit$fitted.values),
                      Residuals = as.vector(fit$residuals),
                      row.names = if (is.null(labs)) seq_len(n) else labs,
                      check.names = FALSE)

  new_xucinet_output(
    "Network autoregression", net,
    nodes = nodes, summary = summary,
    matrices = stats::setNames(list(coef),
                               paste("Coefficients - predicting", yname)),
    assumptions = c(assumptions,
                    "Maximum likelihood by sna::lnam; Sig is from the normal distribution."),
    fields = c("Model:" = if (model == "lag") "Network effects (lag)"
                          else "Network disturbances (error)",
               "Dependent variable:" = yname),
    summary_title = "Model fit",
    print_nodes = FALSE,
    subclass = "xautoregression", call = match.call())
}
