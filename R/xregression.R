# Node-level regression and correlation with permutation tests.
#
# UCINET: Tools | Testing Hypotheses | Node-level | Regression
# (uc_NodeLevelRegression.pas, TNodeLevelRegression.run; repository
# StephenBorgatti/ucinet at commit c7b4956), with the regression in
# G2Tools/uMtxvecRegression.pas (tregression.calc and getypermsig; repository
# StephenBorgatti/tools at commit 207958a).
#
# Dialog defaults: 10000 permutations, 2-tailed, method Y-perm. Cases with a
# missing value on any variable are dropped (addcase). The coefficient table
# is Coef, Beta (b * sd(x) / sd(y)), SE, T, c.Sig (classical) and p.Sig
# (permutation); the intercept has no beta, t or p. The permutation test
# shuffles y against the fixed X and compares each coefficient's t, and the
# model's F, with the observed ones; for a one-tailed test the direction is
# the sign of the observed t. The dialog's seed box is never read: the unit
# passes Delphi's global RandSeed (ledger entry 40). The p-value convention is
# the engine's (R/permute-internals.R).
#
# UCINET has no separate node-level correlation routine. xcorrelation() is the
# same Y-permutation test with one predictor: the correlation is the
# standardized coefficient, and permuting y and comparing t is the same test
# as comparing r.

#' Node-level regression with a permutation test
#'
#' UCINET: Tools | Testing Hypotheses | Node-level | Regression. Ordinary least
#' squares regression of one node attribute on others, with p-values from
#' permuting the dependent variable: the observed t of each coefficient is
#' compared with the t's obtained when the values of the dependent variable
#' are shuffled across the nodes. This asks whether the relationship could
#' have arisen by chance among these nodes, without assuming they are a
#' sample from a population (book, 14.3-14.4).
#'
#' `nperm = 0` gives the classical test only.
#'
#' @section UCINET equivalent:
#' Tools | Testing Hypotheses | Node-level | Regression. *No. of random
#' permutations* is `nperm`, *p-values* is `tails`, *Method* Classical is
#' `nperm = 0`.
#'
#' @param formula A model formula, `y ~ x1 + x2`.
#' @param data Where the variables are: a data frame, a node-level result (its
#'   `$nodes` is used), or a network with attributes. `NULL` looks the names
#'   up where the formula was written.
#' @param nperm Number of random permutations. UCINET's default is 10000.
#' @param seed Random seed for the permutations.
#' @param tails 2 (the default) or 1. A one-tailed test takes its direction
#'   from the sign of the observed statistic.
#' @return An object of class `c("xregression", "xucinet_output")`.
#'   `$matrices` has the coefficient table: `Coef`, `Beta`, `SE`, `T`,
#'   `c.Sig` (classical), `p.Sig` (permutation) and the three proportions
#'   `As Large`, `As Small`, `As Extreme`. `$summary` has the number of
#'   cases, R-square, adjusted R-square, F and its classical and permutation
#'   significance. `$nodes` has the predicted values and residuals.
#' @seealso [xcorrelation()], [xmrqap()].
#' @examples
#' d <- data.frame(y = c(1, 3, 2, 5, 4, 6), x = c(1, 2, 3, 4, 5, 7),
#'                 row.names = letters[1:6])
#' xregression(y ~ x, d, nperm = 1000, seed = 1)
#' @export
xregression <- function(formula, data = NULL, nperm = 10000, seed = NULL,
                        tails = 2) {
  tails <- check_tails(tails)
  mf <- node_model_frame(formula, data, parent.frame())
  fit <- node_regression(mf$y, mf$x, nperm, seed, tails)

  coef <- fit$coef
  summary <- list(
    Nobs = fit$n, `R-Square` = fit$r2, `Adj R-square` = fit$adjr2,
    F = fit$f, `F df` = sprintf("%d, %d", fit$df1, fit$df2),
    `Sig (classical)` = fit$fp, `Sig (perm)` = fit$fperm)
  nodes <- data.frame(`Y-Hat` = rep(NA_real_, nrow(mf$data)),
                      Residuals = NA_real_, row.names = rownames(mf$data),
                      check.names = FALSE)
  nodes[mf$complete, "Y-Hat"] <- fit$yhat
  nodes[mf$complete, "Residuals"] <- fit$resid

  new_xucinet_output(
    "Node level regression", list(title = mf$yname),
    nodes = nodes, summary = summary,
    matrices = stats::setNames(list(coef),
                               paste("Regression coefficients - predicting", mf$yname)),
    assumptions = c(
      if (mf$dropped > 0) sprintf("%d cases with missing values dropped.", mf$dropped),
      if (nperm > 0) sprintf("%d permutations; p-values are %d-tailed.", nperm, tails)
      else "Classical significance only (nperm = 0).",
      "c.Sig is classical significance test. p.Sig is permutation test."),
    fields = c("Method:" = if (nperm > 0) "Y-perm" else "Classical",
               "# of permutations:" = format(nperm),
               "Random seed:" = if (is.null(seed)) "(R session)" else format(seed),
               "Dependent variable:" = mf$yname),
    summary_title = "Overall Regression Fit Statistics",
    print_nodes = FALSE,
    subclass = "xregression", call = match.call())
}

#' Node-level correlation with a permutation test
#'
#' The correlation between two node attributes, with a p-value from permuting
#' one of them across the nodes (book, 14.4). UCINET has no separate routine:
#' this is its Node-level Regression with one predictor, whose standardized
#' coefficient is the correlation.
#'
#' @param x,y Two numeric vectors, one value per node, or names of columns of
#'   `data`.
#' @param data Optional: a data frame, node-level result or network with
#'   attributes in which `x` and `y` are looked up.
#' @param nperm Number of random permutations, 10000 by default.
#' @param seed Random seed.
#' @param tails 2 (the default) or 1.
#' @return An object of class `c("xcorrelation", "xucinet_output")` whose
#'   `$summary` holds the correlation, the number of cases, the classical and
#'   permutation significance and the three proportions.
#' @seealso [xregression()], [xqap()] for two networks.
#' @examples
#' xcorrelation(c(1, 3, 2, 5, 4, 6), c(1, 2, 3, 4, 5, 7), nperm = 1000, seed = 1)
#' @export
xcorrelation <- function(x, y, data = NULL, nperm = 10000, seed = NULL,
                         tails = 2) {
  tails <- check_tails(tails)
  xname <- deparse1(substitute(x)); yname <- deparse1(substitute(y))
  if (!is.null(data)) {
    d <- node_data(data)
    if (is.character(x) && length(x) == 1) { xname <- x; x <- d[[x]] }
    if (is.character(y) && length(y) == 1) { yname <- y; y <- d[[y]] }
  }
  if (length(x) != length(y)) {
    stop("xcorrelation(): x and y have ", length(x), " and ", length(y),
         " values.", call. = FALSE)
  }
  ok <- !is.na(x) & !is.na(y)
  fit <- node_regression(as.numeric(y[ok]), cbind(x = as.numeric(x[ok])),
                         nperm, seed, tails)
  r <- fit$coef["x", "Beta"]
  summary <- list(Correlation = r, Nobs = fit$n,
                  `Sig (classical)` = fit$coef["x", "c.Sig"],
                  `Sig (perm)` = fit$coef["x", "p.Sig"],
                  `As Large` = fit$coef["x", "As Large"],
                  `As Small` = fit$coef["x", "As Small"],
                  `As Extreme` = fit$coef["x", "As Extreme"])
  new_xucinet_output(
    "Node-level correlation", list(title = paste(xname, "and", yname)),
    summary = summary,
    assumptions = c(
      if (any(!ok)) sprintf("%d cases with missing values dropped.", sum(!ok)),
      if (nperm > 0) sprintf("%d permutations; p-values are %d-tailed.", nperm, tails)),
    fields = c("Variables:" = paste(xname, "and", yname)),
    subclass = "xcorrelation", call = match.call())
}

# ---- shared machinery ----------------------------------------------------------

# Where node-level variables live: a data frame, a result's $nodes, or a
# network's attributes.
node_data <- function(data) {
  if (inherits(data, "xucinet_output")) return(data$nodes)
  if (inherits(data, "xucinet")) return(xattributes(data))
  as.data.frame(data)
}

node_model_frame <- function(formula, data, env) {
  d <- if (is.null(data)) NULL else node_data(data)
  mf <- stats::model.frame(formula, data = d, na.action = stats::na.pass)
  if (is.null(d)) d <- mf
  y <- stats::model.response(mf)
  x <- stats::model.matrix(formula, mf)
  x <- x[, colnames(x) != "(Intercept)", drop = FALSE]
  complete <- !is.na(y) & stats::complete.cases(x)
  for (j in seq_len(ncol(x))) {
    v <- x[complete, j]
    if (length(v) > 1 && stats::var(v) == 0) {
      stop("Variable ", colnames(x)[j], " has no variance.", call. = FALSE)
    }
  }
  list(y = as.numeric(y[complete]), x = x[complete, , drop = FALSE],
       complete = complete, dropped = sum(!complete), data = d,
       yname = deparse1(formula[[2]]))
}

# tregression.calc and getypermsig: OLS by QR, t per coefficient, and the
# permutation of y against fixed X.
node_regression <- function(y, x, nperm, seed, tails) {
  n <- length(y)
  X <- cbind(Intercept = 1, x)
  k <- ncol(X)
  q <- qr(X)
  if (q$rank < k) stop("The predictors are collinear.", call. = FALSE)
  xtxi <- chol2inv(qr.R(q))
  df2 <- n - k
  fitstats <- function(yv) {
    b <- qr.coef(q, yv)
    e <- yv - drop(X %*% b)
    s2 <- sum(e^2) / df2
    se <- sqrt(s2 * diag(xtxi))
    t <- b / se
    sst <- sum((yv - mean(yv))^2)
    r2 <- 1 - sum(e^2) / sst
    f <- (r2 / (k - 1)) / ((1 - r2) / df2)
    list(b = b, se = se, t = t, e = e, r2 = r2, f = f)
  }
  obs <- fitstats(y)

  sdy <- sqrt(mean((y - mean(y))^2))
  sdx <- apply(X, 2, function(v) sqrt(mean((v - mean(v))^2)))
  beta <- obs$b * sdx / sdy
  cp <- 2 * stats::pt(-abs(obs$t), df2)
  if (tails == 1) cp <- cp / 2

  if (nperm > 0) {
    pt_ <- perm_test(function(p) { s <- fitstats(y[p]); c(s$t[-1], s$f) },
                     n, nperm, seed, tails)
    kk <- k - 1
    ge <- pt_$ge[seq_len(kk)]; le <- pt_$le[seq_len(kk)]
    ext <- pt_$ext[seq_len(kk)]; sig <- pt_$sig[seq_len(kk)]
    fperm <- pt_$ge[kk + 1]
  } else {
    ge <- le <- ext <- sig <- rep(NA_real_, k - 1)
    fperm <- NA_real_
  }
  coef <- cbind(Coef = obs$b, Beta = c(NA, beta[-1]), SE = obs$se,
                T = c(NA, obs$t[-1]), c.Sig = c(NA, cp[-1]),
                p.Sig = c(NA, sig), `As Large` = c(NA, ge),
                `As Small` = c(NA, le), `As Extreme` = c(NA, ext))
  rownames(coef) <- colnames(X)
  f <- obs$f
  list(coef = coef, n = n, r2 = obs$r2,
       adjr2 = 1 - (1 - obs$r2) * (n - 1) / df2,
       f = f, df1 = k - 1L, df2 = df2,
       fp = stats::pf(f, k - 1, df2, lower.tail = FALSE), fperm = fperm,
       yhat = y - obs$e, resid = obs$e)
}
