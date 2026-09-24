# MRQAP and LR-QAP.
#
# UCINET: Tools | Testing Hypotheses | Dyadic (QAP) | MR-QAP Linear Regression
# | Double Dekker Semi-Partialling MRQAP (uc_QaPDekkerRegression.pas, engine
# G1Tools/umrqapdekker.pas) and | Original (Y permutation) method
# (xmrqapna.pas, networkregressionNA); | LR-QAP Logistic Regression
# (uc_lrqap.pas, engine G1Tools/ulrqap.pas with ulogisticregressionnr).
# Repositories StephenBorgatti/ucinet at commit c7b4956 and
# StephenBorgatti/tools at commit 207958a.
#
# Double Dekker semi-partialling (the default, as in UCINET and the book):
#   1. the observed OLS regression of Y on the X's, over the off-diagonal cells
#      (one triangle when Y and every X are symmetric) where nothing is
#      missing; coefficients, standardized coefficients (population sd), HC0
#      robust standard errors and their t, R-square, adjusted R-square;
#   2. R-square's significance: QAP correlation of Y with the fitted values,
#      the proportion as large;
#   3. for each X_k: regress X_k on the other X's, keep the residual matrix,
#      permute its rows and columns together, regress Y on the other X's and
#      the permuted residuals, and compare the classical t of that term with
#      the observed classical t (the same as X_k's, by Frisch-Waugh-Lovell).
#   UCINET issue 31: with no missing data the unit's fast path divides the
#   coefficient by its variance (b / SE^2) instead of its standard error, so
#   its statistic is not t and its p-values differ from the path it takes when
#   data are missing. Here it is t on both. UCINET issue 32 (Y-permutation):
#   the unit decides symmetry from the X matrices only; here Y counts too.
#   Where cells are missing, the unit's Dekker path fills the permuted column
#   out of step with the other columns; here each permutation keeps the cells
#   present in Y, the other X's and the permuted residual (ledger entry 41).
# Y permutation: Y's rows and columns are permuted together against the fixed
#   X's and the coefficients themselves are compared (xmrqapna); R-square's
#   significance is the proportion of permuted R-squares as large.
# Both methods return the same table; `method` changes only how its p-values
# are obtained. Defaults: 2000 permutations, 2-tailed, t-statistics tracked.
#
# LR-QAP: logistic regression of the dichotomized Y (> 0) on the X's by
# maximum likelihood, Y permuted against the fixed X's, each coefficient's
# Wald t compared with the observed; the model's significance is the
# proportion of permuted log-likelihoods as large. McFadden's pseudo R-square.
# Defaults: 1000 permutations, 2-tailed, data treated as non-symmetric (both
# triangles), as the dialog.

#' Multiple regression QAP
#'
#' UCINET: Tools | Testing Hypotheses | Dyadic (QAP) | MR-QAP Linear
#' Regression. Ordinary least squares regression of one network on others,
#' cell by cell, with p-values from QAP permutations, so that the dependence
#' among the dyads does not invalidate the test (book, 14.5.2).
#'
#' `method = "dsp"`, the default, is Dekker, Krackhardt and Snijders'
#' double semi-partialling: each predictor is residualized on the others, the
#' residuals are permuted, and the predictor's t-statistic is compared with its
#' permutation distribution. It is robust to collinearity and to network
#' autocorrelation. `method = "yperm"` permutes the dependent network instead
#' and compares the coefficients.
#'
#' The reported standard errors and t are robust (Huber-White), as UCINET
#' reports them; conventional standard errors play no part in the p-values.
#'
#' @section UCINET equivalent:
#' Tools | Testing Hypotheses | Dyadic (QAP) | MR-QAP Linear Regression |
#' Double Dekker Semi-Partialling MRQAP (`method = "dsp"`) or Original (Y
#' permutation) method (`"yperm"`). *Number of permutations* is `nperm`,
#' *P-values* is `tails`, the partition file is `partition`.
#'
#' @param formula `y ~ x1 + x2`, where the names are relations of `nets`.
#' @param nets The networks: a named list of matrices or networks, or a
#'   multi-relation network whose relations the formula names.
#' @param nperm Number of random permutations. UCINET's default is 2000.
#' @param method `"dsp"` (the default) or `"yperm"`.
#' @param seed Random seed.
#' @param tails 2 (the default) or 1.
#' @param partition Optional group of each node: nodes are then permuted only
#'   within their group (UCINET's partition file, Double Dekker only).
#' @return An object of class `c("xmrqap", "xucinet_output")`. `$summary`:
#'   R-square, adjusted R-square, the significance of R-square, the number of
#'   observations and permutations. `$matrices`: the coefficient table with
#'   unstandardized and standardized coefficients, robust SE, t, the p-value,
#'   the three proportions, the mean and sd of the permuted coefficients and
#'   the collinearity diagnostics.
#' @seealso [xqap()], [xlrqap()].
#' @examples
#' xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 200, seed = 1)
#' @export
xmrqap <- function(formula, nets, nperm = 2000, method = c("dsp", "yperm"),
                   seed = NULL, tails = 2, partition = NULL) {
  method <- match.arg(method)
  tails <- check_tails(tails)
  d <- qap_design(formula, nets)
  n <- d$n
  if (!is.null(partition) && length(partition) != n) {
    stop("xmrqap(): the partition has ", length(partition), " values for ",
         n, " nodes.", call. = FALSE)
  }
  perms <- qap_perms(n, nperm, seed, partition)

  obs <- mrqap_observed(d)
  fitp <- NA_real_
  k <- length(d$xnames)
  pvals <- matrix(NA_real_, k + 1, 3); avg <- sdv <- rep(NA_real_, k + 1)
  sig <- rep(NA_real_, k + 1)

  if (method == "dsp") {
    # R-square: QAP correlation of Y with the fitted values, as large
    yhat <- matrix(NA_real_, n, n); yhat[d$cells[obs$use]] <- obs$fitted
    rq <- perm_test(function(p) qap_r(d$y, yhat[p, p], d$cells), n, nperm,
                    perms = perms)
    fitp <- rq$ge
    for (j in seq_len(k)) {
      r <- dsp_one(d, j, perms, tails)
      pvals[j, ] <- c(r$ge, r$le, r$ext); sig[j] <- r$sig
      avg[j] <- r$bmean; sdv[j] <- r$bsd
    }
  } else {
    yp <- mrqap_yperm(d, obs, perms, tails)
    pvals <- yp$pvals; sig <- yp$sig; avg <- yp$avg; sdv <- yp$sd
    fitp <- yp$fitp
  }

  tab <- cbind(`Un-Stdized` = obs$coef, `Stdized Coef` = obs$beta,
               `Robust SE` = obs$rse, `T-stat` = obs$rt, `P-value` = sig,
               `As Large` = pvals[, 1], `As Small` = pvals[, 2],
               `As Extreme` = pvals[, 3], `Perm Avg` = avg, `Perm SD` = sdv,
               `Collin R-Sqr` = c(obs$collin, NA),
               Tolerance = c(1 - obs$collin, NA),
               VIF = c(1 / (1 - obs$collin), NA))
  rownames(tab) <- c(d$xnames, "Intercept")

  new_xucinet_output(
    if (method == "dsp") "MRQAP Dekker semi-partialling" else
      "Multiple Regression QAP via Permutation Method",
    list(title = d$yname),
    summary = list(`R-Square` = obs$r2, `Adj R-Sqr` = obs$adjr2,
                   `P(R-Sqr)` = fitp, Obs = obs$nobs, Perms = nperm),
    matrices = list(`REGRESSION COEFFICIENTS` = tab),
    assumptions = c(
      if (d$sym) "Y and every X are symmetric: one triangle is used.",
      if (obs$nobs < length(d$cells)) sprintf(
        "%d cells with a missing value dropped.", length(d$cells) - obs$nobs),
      sprintf("%d permutations; p-values are %d-tailed%s.", nperm, tails,
              if (method == "dsp") ", from the t-statistics" else
                ", from the coefficients"),
      if (!is.null(partition)) "Permutations are within the groups of the partition."),
    fields = c("Dependent variable:" = d$yname,
               "Independent variables:" = paste(d$xnames, collapse = ", "),
               "Method:" = if (method == "dsp") "Double Dekker semi-partialling"
                           else "Y permutation",
               "Random seed:" = if (is.null(seed)) "(R session)" else format(seed)),
    summary_title = "MODEL FIT",
    subclass = "xmrqap", call = match.call())
}

#' Logistic regression QAP
#'
#' UCINET: Tools | Testing Hypotheses | Dyadic (QAP) | LR-QAP Logistic
#' Regression. Logistic regression of a binary network on others, cell by
#' cell, with p-values from permuting the dependent network's rows and columns
#' together (book, 14.5.2). The dependent network is dichotomized (values
#' above 0 are ties).
#'
#' @section UCINET equivalent:
#' Tools | Testing Hypotheses | Dyadic (QAP) | LR-QAP Logistic Regression.
#' *Number of permutations* is `nperm`, *P-values* is `tails`, *Data are*
#' symmetric is `symmetric = TRUE`.
#'
#' @inheritParams xmrqap
#' @param nperm Number of random permutations. UCINET's default is 1000.
#' @param symmetric Use only one triangle? `FALSE` by default, as the dialog.
#' @return An object of class `c("xlrqap", "xucinet_output")`. `$summary`:
#'   log-likelihood, McFadden's pseudo R-square, the significance of the
#'   model, the number of observations and permutations. `$matrices`: the
#'   coefficients, odds ratios, t, the p-value, the mean, minimum, maximum and
#'   sd of the permuted coefficients and the three proportions.
#' @seealso [xmrqap()].
#' @examples
#' xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 100, seed = 1)
#' @export
xlrqap <- function(formula, nets, nperm = 1000, seed = NULL, tails = 2,
                   symmetric = FALSE) {
  tails <- check_tails(tails)
  d <- qap_design(formula, nets, sym = isTRUE(symmetric))
  n <- d$n
  y01 <- (d$y > 0) * 1
  X <- cbind(Intercept = 1, d$xmat)
  fit <- function(yv) {
    use <- d$xok & !is.na(yv)
    if (length(unique(yv[use])) < 2) return(NULL)
    g <- suppressWarnings(stats::glm.fit(X[use, , drop = FALSE], yv[use],
                                         family = stats::binomial()))
    b <- g$coefficients
    se <- tryCatch(sqrt(diag(chol2inv(qr.R(g$qr)))), error = function(e) rep(NA, length(b)))
    ll <- sum(stats::dbinom(yv[use], 1, g$fitted.values, log = TRUE))
    p0 <- mean(yv[use])
    ll0 <- sum(stats::dbinom(yv[use], 1, p0, log = TRUE))
    list(b = b, t = b / se, ll = ll, r2 = 1 - ll / ll0, nobs = sum(use))
  }
  yobs <- y01[d$cells]
  if (length(unique(yobs[d$xok & !is.na(yobs)])) < 2) {
    stop("xlrqap(): the dependent variable is a constant.", call. = FALSE)
  }
  obs <- fit(yobs)
  perms <- qap_perms(n, nperm, seed, NULL)
  hasmiss <- obs$nobs < length(d$cells)
  stat <- function(p) {
    f <- fit(y01[p, p][d$cells])
    if (is.null(f)) return(rep(NA_real_, 2 * ncol(X) + 1))
    c(f$t, f$b, if (hasmiss) f$r2 else f$ll)
  }
  k1 <- ncol(X)
  res <- perm_test(stat, n, nperm, tails = tails, perms = perms,
                   observed = c(obs$t, obs$b, if (hasmiss) obs$r2 else obs$ll))
  ti <- seq_len(k1); bi <- k1 + ti
  blank <- function(v) { v[1] <- NA; v }
  tab <- cbind(Coef = obs$b, OddsRat = exp(obs$b), T = obs$t,
               Sig = blank(res$sig[ti]), Avg = blank(res$mean[bi]),
               Min = blank(res$min[bi]), Max = blank(res$max[bi]),
               SD = blank(res$sd[bi]), `P(ge)` = blank(res$ge[ti]),
               `P(le)` = blank(res$le[ti]), `P(ext)` = blank(res$ext[ti]))
  rownames(tab) <- c("Intercept", d$xnames)

  new_xucinet_output(
    "Logistic Regression QAP", list(title = d$yname),
    summary = list(LL = obs$ll, `R-Sqr` = obs$r2, Sig = res$ge[2 * k1 + 1],
                   Obs = obs$nobs, Perms = nperm),
    matrices = list(
      `LR Coefficients & Permutation Results (T-stats used in permutations)` = tab),
    assumptions = c(
      "Dependent variable dichotomized: values above 0 are ties.",
      "The r-squared shown is McFadden's pseudo r-squared.",
      if (hasmiss) "Your data have missing values; the model's significance compares pseudo r-squares.",
      sprintf("%d permutations; p-values are %d-tailed.", nperm, tails)),
    fields = c("Dependent variable:" = d$yname,
               "Independent variables:" = paste(d$xnames, collapse = ", "),
               "Data are:" = if (isTRUE(symmetric)) "Symmetric" else "Non-symmetric",
               "Random seed:" = if (is.null(seed)) "(R session)" else format(seed)),
    summary_title = "Overall fit of the logistic regression model",
    subclass = "xlrqap", call = match.call())
}

# ---- shared machinery -----------------------------------------------------------

# The dependent and independent matrices named in the formula, the cells used
# and the design matrix over them. `sym` NULL: one triangle when Y and every X
# are symmetric (the Dekker unit's rule).
qap_design <- function(formula, nets, sym = NULL) {
  if (inherits(nets, "xucinet")) {
    mats <- relation_list(nets)
  } else if (is.list(nets) && !is.null(names(nets))) {
    mats <- lapply(nets, function(z) as.matrix(xnet(z, quote(z))))
  } else {
    stop("nets must be a named list of networks or a multi-relation network.",
         call. = FALSE)
  }
  yname <- all.vars(formula[[2]])
  xnames <- attr(stats::terms(formula), "term.labels")
  need <- c(yname, xnames)
  miss <- setdiff(need, names(mats))
  if (length(miss)) {
    stop("Not relations of nets: ", paste(miss, collapse = ", "), ".\n",
         "  Available: ", paste(names(mats), collapse = ", "), call. = FALSE)
  }
  y <- mats[[yname]]
  n <- nrow(y)
  if (n != ncol(y)) stop("QAP needs square matrices.", call. = FALSE)
  for (nm in xnames) {
    if (!identical(dim(mats[[nm]]), dim(y))) {
      stop("Matrix ", nm, " is not the same size as ", yname, ".", call. = FALSE)
    }
  }
  if (is.null(sym)) {
    sym <- isSymmetric(unname(y)) &&
      all(vapply(xnames, function(nm) isSymmetric(unname(mats[[nm]])), logical(1)))
  }
  cells <- qap_cells(n, sym)
  xmat <- vapply(xnames, function(nm) mats[[nm]][cells], numeric(length(cells)))
  xmat <- matrix(xmat, ncol = length(xnames), dimnames = list(NULL, xnames))
  list(y = y, mats = mats[xnames], xmat = xmat, xok = stats::complete.cases(xmat),
       cells = cells, n = n, sym = sym, yname = yname, xnames = xnames)
}

# The permutations, drawn once so every term of a model sees the same ones;
# within groups when a partition is given.
qap_perms <- function(n, nperm, seed, partition) {
  with_seed(seed, lapply(seq_len(nperm), function(i) {
    if (is.null(partition)) return(sample.int(n))
    p <- seq_len(n)
    for (g in unique(partition)) {
      idx <- which(partition == g)
      p[idx] <- if (length(idx) > 1) sample(idx) else idx
    }
    p
  }))
}

qap_r <- function(y, x, cells) {
  a <- y[cells]; b <- x[cells]
  ok <- !is.na(a) & !is.na(b)
  suppressWarnings(stats::cor(a[ok], b[ok]))
}

# The observed regression of runobservedregression.
mrqap_observed <- function(d) {
  yv <- d$y[d$cells]
  use <- d$xok & !is.na(yv)
  X <- cbind(d$xmat[use, , drop = FALSE], Intercept = 1)
  yy <- yv[use]
  nobs <- length(yy)
  f <- stats::lm.fit(X, yy)
  b <- f$coefficients
  e <- f$residuals
  xtxi <- chol2inv(qr.R(f$qr))
  meat <- crossprod(X * e)
  rse <- sqrt(diag(xtxi %*% meat %*% xtxi))
  k <- ncol(d$xmat)
  r2 <- 1 - sum(e^2) / sum((yy - mean(yy))^2)
  sd_pop <- function(v) sqrt(mean((v - mean(v))^2))
  beta <- c(b[seq_len(k)] * apply(X[, seq_len(k), drop = FALSE], 2, sd_pop) / sd_pop(yy), NA)
  collin <- vapply(seq_len(k), function(j) {
    if (k == 1) return(0)
    Z <- cbind(X[, -c(j, k + 1), drop = FALSE], 1)
    ej <- stats::lm.fit(Z, X[, j])$residuals
    1 - sum(ej^2) / sum((X[, j] - mean(X[, j]))^2)
  }, numeric(1))
  list(coef = unname(b), beta = unname(beta), rse = unname(rse),
       rt = unname(b / rse), r2 = r2,
       adjr2 = 1 - (1 - r2) * (nobs - 1) / (nobs - k - 1), nobs = nobs,
       fitted = drop(X %*% b), use = use, collin = collin)
}

# Y permutation (xmrqapna): permute Y against the fixed X's and compare the
# coefficients, and R-square.
mrqap_yperm <- function(d, obs, perms, tails) {
  k <- ncol(d$xmat)
  X <- cbind(d$xmat, Intercept = 1)
  stat <- function(p) {
    yv <- d$y[p, p][d$cells]
    use <- d$xok & !is.na(yv)
    if (sum(use) <= ncol(X)) return(rep(NA_real_, ncol(X) + 1))
    f <- stats::.lm.fit(X[use, , drop = FALSE], yv[use])
    e <- f$residuals
    yy <- yv[use]
    c(f$coefficients, 1 - sum(e^2) / sum((yy - mean(yy))^2))
  }
  res <- perm_test(stat, d$n, length(perms), tails = tails, perms = perms,
                   observed = c(obs$coef, obs$r2))
  idx <- seq_len(k + 1)
  list(pvals = cbind(res$ge, res$le, res$ext)[idx, , drop = FALSE],
       sig = res$sig[idx], avg = res$mean[idx], sd = res$sd[idx],
       fitp = res$ge[k + 2])
}

# Double semi-partialling for predictor j: residualize, permute, compare t.
dsp_one <- function(d, j, perms, tails) {
  n <- d$n; k <- ncol(d$xmat)
  yv <- d$y[d$cells]
  use0 <- d$xok & !is.na(yv)
  others <- d$xmat[, -j, drop = FALSE]
  Z <- cbind(others, 1)
  # the residual matrix of X_j on the other X's, over the cells used
  rj <- stats::lm.fit(Z[use0, , drop = FALSE], d$xmat[use0, j])$residuals
  R <- matrix(NA_real_, n, n); R[d$cells[use0]] <- rj
  if (d$sym) R[upper.tri(R)] <- t(R)[upper.tri(R)]
  tstat <- function(xk, use) {
    X <- cbind(xk[use], others[use, , drop = FALSE], 1)
    f <- stats::lm.fit(X, yv[use])
    if (f$rank < ncol(X)) return(c(NA_real_, NA_real_))
    e <- f$residuals
    s2 <- sum(e^2) / (length(e) - ncol(X))
    se <- sqrt(s2 * chol2inv(qr.R(f$qr))[1, 1])
    c(f$coefficients[1], f$coefficients[1] / se)
  }
  obs <- tstat(R[d$cells], use0)
  draws <- vapply(perms, function(p) {
    xk <- R[p, p][d$cells]
    tstat(xk, use0 & !is.na(xk))
  }, numeric(2))
  tt <- perm_summary(obs[2], draws[2, , drop = FALSE], tails)
  bb <- draws[1, ]; bb <- bb[!is.na(bb)]
  list(ge = tt$ge, le = tt$le, ext = tt$ext, sig = tt$sig,
       bmean = mean(bb), bsd = if (length(bb) > 1) stats::sd(bb) else NA)
}
