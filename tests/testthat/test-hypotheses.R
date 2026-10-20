# Chapter 14: testing hypotheses.

tol <- 1e-8

all_perms <- function(n) {
  if (n == 1) return(list(1L))
  out <- list()
  for (p in all_perms(n - 1)) for (i in 0:(n - 1)) {
    out[[length(out) + 1]] <- as.integer(append(p, n, after = i))
  }
  out
}

# ---- the permutation engine ------------------------------------------------------

test_that("with every permutation of 5, the proportions are the exact ones", {
  x <- c(1, 4, 2, 5, 3); y <- c(2, 5, 1, 4, 3)
  stat <- function(p) cor(x, y[p])
  perms <- all_perms(5)
  expect_length(perms, 120)
  r <- perm_test(stat, 5, length(perms), perms = perms)
  obs <- cor(x, y)
  all_r <- vapply(perms, stat, numeric(1))
  expect_equal(r$ge, (1 + sum(all_r >= obs - 1e-12)) / 121)
  expect_equal(r$le, (1 + sum(all_r <= obs + 1e-12)) / 121)
  expect_equal(r$ext, (1 + sum(abs(all_r) >= abs(obs) - 1e-12)) / 121)
  expect_equal(r$mean, mean(all_r))
  # random permutations converge on the exact proportion
  rr <- perm_test(stat, 5, 20000, seed = 1)
  expect_lt(abs(rr$ge - mean(all_r >= obs - 1e-12)), 0.01)
})

test_that("one-tailed significance follows the sign of the observed statistic", {
  obs <- c(0.5, -0.5)
  draws <- rbind(c(-1, 0, 1), c(-1, 0, 1))
  s <- perm_summary(obs, draws, tails = 1)
  expect_equal(s$sig, c(s$ge[1], s$le[2]))
  s2 <- perm_summary(obs, draws, tails = 2)
  expect_equal(s2$sig, s2$ext)
})

test_that("a permutation that gives no value is not counted", {
  s <- perm_summary(1, matrix(c(2, NA, 0), 1), tails = 2)
  expect_equal(s$n, 2L)
  expect_equal(s$ge, (1 + 1) / 3)
})

test_that("nperm = 0 returns the observed value and no proportions", {
  r <- perm_test(function(p) 1, 3, 0)
  expect_true(is.na(r$sig))
})

# ---- xregression and xcorrelation ------------------------------------------------

node_df <- function() {
  set.seed(2)
  d <- data.frame(x1 = rnorm(20), x2 = rnorm(20))
  d$y <- 1 + 2 * d$x1 + rnorm(20)
  rownames(d) <- paste0("n", 1:20)
  d
}

test_that("the regression is lm()'s, with UCINET's table", {
  d <- node_df()
  r <- xregression(y ~ x1 + x2, d, nperm = 0)
  l <- summary(stats::lm(y ~ x1 + x2, d))
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[, "Coef"]), unname(stats::coef(l)[, 1]), tolerance = tol)
  expect_equal(unname(tab[-1, "SE"]), unname(stats::coef(l)[-1, 2]), tolerance = tol)
  expect_equal(unname(tab[-1, "c.Sig"]), unname(stats::coef(l)[-1, 4]), tolerance = tol)
  expect_equal(r$summary[["R-Square"]], l$r.squared, tolerance = tol)
  expect_equal(r$summary[["Adj R-square"]], l$adj.r.squared, tolerance = tol)
  expect_equal(r$summary$F, unname(l$fstatistic[1]), tolerance = tol)
  expect_true(is.na(tab["Intercept", "T"]))
  expect_true(all(is.na(tab[, "p.Sig"])))          # classical only
  beta <- tab["x1", "Beta"]
  sdp <- function(v) sqrt(mean((v - mean(v))^2))
  expect_equal(beta, tab["x1", "Coef"] * sdp(d$x1) / sdp(d$y), tolerance = tol)
})

test_that("the permutation test finds a strong effect and not a null one", {
  r <- xregression(y ~ x1 + x2, node_df(), nperm = 2000, seed = 1)
  tab <- r$matrices[[1]]
  expect_lt(tab["x1", "p.Sig"], 0.01)
  expect_gt(tab["x2", "p.Sig"], 0.05)
  expect_lt(r$summary[["Sig (perm)"]], 0.01)
  expect_equal(nrow(r$nodes), 20)
})

test_that("cases with missing values are dropped and reported", {
  d <- node_df(); d$x2[3] <- NA
  r <- xregression(y ~ x1 + x2, d, nperm = 0)
  expect_equal(r$summary$Nobs, 19)
  expect_true(is.na(r$nodes["n3", "Residuals"]))
})

test_that("a predictor with no variance is refused, as UCINET does", {
  d <- node_df(); d$x2 <- 1
  expect_error(xregression(y ~ x1 + x2, d), "no variance")
})

test_that("data can be a node-level result", {
  res <- xdegree(campnet)
  res$nodes$y <- res$nodes$Outdeg + res$nodes$Indeg
  r <- xregression(y ~ Indeg, res, nperm = 0)
  expect_equal(unname(r$matrices[[1]]["Indeg", "Coef"]), 1)
})

test_that("xcorrelation is Pearson's r with a permutation p", {
  d <- node_df()
  r <- xcorrelation(d$x1, d$y, nperm = 2000, seed = 1)
  expect_equal(r$summary$Correlation, cor(d$x1, d$y), tolerance = tol)
  expect_lt(r$summary[["Sig (perm)"]], 0.01)
  expect_equal(xcorrelation("x1", "y", data = d, nperm = 0)$summary$Correlation,
               cor(d$x1, d$y), tolerance = tol)
})

# ---- xqap -------------------------------------------------------------------------

test_that("Padgett marriage and business correlate 0.372 over 120 dyads, as 14.5.1", {
  q <- xqap(as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2),
            nperm = 5000, seed = 1)
  tab <- q$matrices[[1]]
  expect_equal(round(tab["Pearson Correlation", "Obs Value"], 3), 0.372)
  expect_equal(tab["Pearson Correlation", "N Obs"], 120)
  # the book: mean 0.001, sd 0.092 over 20000 permutations
  expect_lt(abs(tab["Pearson Correlation", "Average"] - 0.001), 0.005)
  expect_lt(abs(tab["Pearson Correlation", "Std Dev"] - 0.092), 0.005)
  expect_lt(tab["Pearson Correlation", "Significance"], 0.005)
})

test_that("the seven measures are tsim's", {
  x <- c(1, 0, 1, 1, 0, 0); y <- c(1, 1, 0, 1, 0, 0)
  m <- qap_measures(x, y)
  expect_equal(m[1], cor(x, y), tolerance = tol)
  expect_equal(m[2], sqrt(2))
  expect_equal(m[3], 2 / 6)
  expect_equal(m[4], 4 / 6)
  expect_equal(m[5], 2 / 4)
  expect_equal(m[6], (2 * 2 - 1 * 1) / (2 * 2 + 1 * 1))
  expect_equal(m[7], 2)
})

test_that("distances are tested in the lower tail", {
  q <- xqap(as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2),
            nperm = 200, seed = 1)
  tab <- q$matrices[[1]]
  expect_equal(tab["Euclidean Distance", "Significance"],
               tab["Euclidean Distance", "Prop <= Obs"])
})

test_that("asymmetric data use both triangles; missing cells are dropped", {
  a <- as.matrix(campnet); b <- t(a)
  q <- xqap(a, b, nperm = 10, seed = 1)
  expect_equal(q$matrices[[1]][1, "N Obs"], 18 * 17)
  b[1, 2] <- NA
  expect_equal(xqap(a, b, nperm = 10, seed = 1)$matrices[[1]][1, "N Obs"], 18 * 17 - 1)
})

test_that("QAP agrees with sna's gcor and qaptest", {
  skip_if_not_installed("sna")
  a <- as.matrix(padgett, relation = 1); b <- as.matrix(padgett, relation = 2)
  expect_equal(xqap(a, b, nperm = 0)$matrices[[1]][1, "Obs Value"],
               sna::gcor(a, b, mode = "graph"), tolerance = 1e-6)
  set.seed(5)
  s <- sna::qaptest(list(a, b), sna::gcor, g1 = 1, g2 = 2, reps = 5000,
                    mode = "graph")
  q <- xqap(a, b, nperm = 5000, seed = 5)$matrices[[1]]
  # two independent samples of 5000: their means and sds agree within 0.01
  expect_lt(abs(q[1, "Average"] - mean(s$dist)), 0.01)
  expect_lt(abs(q[1, "Std Dev"] - stats::sd(s$dist)), 0.01)
})

# ---- xmrqap -----------------------------------------------------------------------

test_that("the coefficients are lm()'s on the off-diagonal cells", {
  r <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 0)
  m <- relation_list(hightech)
  off <- row(m$Advice) != col(m$Advice)
  l <- stats::lm(m$Advice[off] ~ m$Friendship[off] + m$ReportTo[off])
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[c("Friendship", "ReportTo", "Intercept"), "Un-Stdized"]),
               unname(stats::coef(l)[c(2, 3, 1)]), tolerance = tol)
  expect_equal(r$summary[["R-Square"]], summary(l)$r.squared, tolerance = tol)
  # HC0 robust standard errors
  X <- stats::model.matrix(l); e <- stats::residuals(l)
  b <- solve(crossprod(X))
  hc0 <- sqrt(diag(b %*% crossprod(X * e) %*% b))
  expect_equal(unname(tab[c("Intercept", "Friendship", "ReportTo"), "Robust SE"]),
               unname(hc0), tolerance = 1e-8)
})

test_that("hightech advice: R-square 6.3% and reports-to significant, as 14.5.2", {
  r <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 2000, seed = 1)
  expect_equal(round(r$summary[["R-Square"]], 3), 0.063)
  tab <- r$matrices[[1]]
  expect_lt(tab["ReportTo", "P-value"], 0.01)
  expect_gt(tab["Friendship", "P-value"], 0.05)
})

test_that("the double semi-partialling statistic is t, not b / SE^2 (issue 31)", {
  expect_differs_from_ucinet(31)
  m <- relation_list(hightech)
  d <- qap_design(Advice ~ Friendship + ReportTo, m)
  # the observed statistic dsp_one compares is lm()'s classical t for the term
  off <- row(m$Advice) != col(m$Advice)
  l <- summary(stats::lm(m$Advice[off] ~ m$Friendship[off] + m$ReportTo[off]))
  r <- dsp_one(d, 2, list(seq_len(21)), 2)
  expect_equal(r$ext, 1)       # the identity permutation is as extreme as itself
  tt <- stats::coef(l)[3, 3]
  one <- dsp_one(d, 2, list(sample.int(21)), 2)
  expect_true(one$ext %in% c(0.5, 1))
  expect_gt(abs(tt), 3)
})

test_that("both methods give one table; Y permutation compares coefficients", {
  a <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 200, seed = 1)
  b <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 200, seed = 1,
              method = "yperm")
  expect_identical(colnames(a$matrices[[1]]), colnames(b$matrices[[1]]))
  expect_equal(a$matrices[[1]][, "Un-Stdized"], b$matrices[[1]][, "Un-Stdized"])
  expect_false(is.na(b$matrices[[1]]["Intercept", "P-value"]))
  expect_true(is.na(a$matrices[[1]]["Intercept", "P-value"]))
})

test_that("an asymmetric Y is used whole even when the X's are symmetric (issue 32)", {
  expect_differs_from_ucinet(32)
  m <- relation_list(hightech)
  f <- pmax(m$Friendship, t(m$Friendship))
  d <- qap_design(Advice ~ F, list(Advice = m$Advice, F = f))
  expect_false(d$sym)
  expect_length(d$cells, 21 * 20)
})

test_that("symmetric data: the DSP R-square test permutes the whole fitted matrix", {
  # A 6-cycle against a function of the distance in it: 12 of the 720
  # permutations reach the observed |r|, so the exact p is 1/60. The fitted
  # values were stored in one triangle only, so a permutation that moved a
  # cell into the other read NA there and the test ran on a random subset of
  # the dyads (p about 0.045). UCINET's Y-permutation MRQAP does the same
  # (issue 50); its DSP R-square test does not.
  expect_differs_from_ucinet(50)
  n <- 6
  d <- outer(1:n, 1:n, function(i, j) pmin(abs(i - j), n - abs(i - j)))
  y <- (d == 1) * 1
  x <- matrix(c(0, 0.1, 0.7, 0.3)[d + 1], n)
  for (m in c("dsp", "yperm")) {
    p <- xmrqap(Y ~ X, list(Y = y, X = x), nperm = 5000, seed = 1, method = m)$summary$`P(R-Sqr)`
    expect_lt(abs(p - 1 / 60), 3 * sqrt((1 / 60) * (59 / 60) / 5000) + 2 / 5000)
  }
})

test_that("a partition keeps permutations within groups", {
  g <- rep(1:3, 7)
  ps <- qap_perms(21, 50, 1, g)
  expect_true(all(vapply(ps, function(p) all(g[p] == g), logical(1))))
})

test_that("the formula must name relations of nets", {
  expect_error(xmrqap(Advice ~ Nope, hightech, nperm = 0), "Available")
})

test_that("coefficients agree with sna's netlm", {
  skip_if_not_installed("sna")
  m <- relation_list(hightech)
  s <- sna::netlm(m$Advice, list(m$Friendship, m$ReportTo), nullhyp = "classical")
  r <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 0)
  expect_equal(unname(r$matrices[[1]][c("Intercept", "Friendship", "ReportTo"), 1]),
               unname(s$coefficients), tolerance = 1e-8)
})

# ---- xlrqap -----------------------------------------------------------------------

test_that("the logistic coefficients are glm()'s", {
  r <- xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 0)
  m <- relation_list(hightech)
  off <- row(m$Advice) != col(m$Advice)
  # glm() run to full convergence: its default stops a step early for the SE
  g <- stats::glm((m$Advice[off] > 0) ~ m$Friendship[off] + m$ReportTo[off],
                  family = stats::binomial,
                  control = stats::glm.control(epsilon = 1e-14, maxit = 100))
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[, "Coef"]), unname(stats::coef(g)), tolerance = 1e-6)
  expect_equal(unname(tab[, "T"]), unname(summary(g)$coefficients[, 3]), tolerance = 1e-6)
  expect_equal(r$summary$LL, as.numeric(stats::logLik(g)), tolerance = 1e-6)
  g0 <- stats::glm((m$Advice[off] > 0) ~ 1, family = stats::binomial)
  expect_equal(r$summary[["R-Sqr"]],
               1 - as.numeric(stats::logLik(g)) / as.numeric(stats::logLik(g0)),
               tolerance = 1e-6)
})

test_that("LR-QAP: double semi-partialling is the default, Y permutation on request (#38)", {
  a <- xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 300, seed = 1)
  b <- xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 300, seed = 1,
              method = "yperm")
  expect_equal(a$fields[["Method:"]], "Double Dekker semi-partialling")
  expect_equal(b$fields[["Method:"]], "Y-permutation")
  # the same slots and observed values whichever method (SPEC, level of analysis 5)
  expect_identical(names(a$summary), names(b$summary))
  expect_identical(dimnames(a$matrices[[1]]), dimnames(b$matrices[[1]]))
  expect_equal(a$matrices[[1]][, c("Coef", "T")], b$matrices[[1]][, c("Coef", "T")])
  # the model's significance is by Y permutation under both
  expect_equal(a$summary$Sig, b$summary$Sig)
  for (r in list(a, b)) {
    tab <- r$matrices[[1]]
    expect_true(is.na(tab["Intercept", "Sig"]))
    expect_lt(tab["ReportTo", "Sig"], 0.05)
    expect_equal(r$summary$Perms, 300)
    expect_equal(r$summary$Failed, 0)
  }
  expect_false(isTRUE(all.equal(a$matrices[[1]][, "Sig"], b$matrices[[1]][, "Sig"])))
})

test_that("method = 'yperm' reproduces the Y-permutation results of before #38", {
  # Values printed by xlrqap() at xucinet 82c9ed3, when Y permutation was the
  # only method. The p-values are identical; T and the permuted coefficients'
  # summaries move by up to 2e-4 because the fit is now Newton-Raphson to
  # convergence (glm.fit's default stopped a step early for the SE).
  r <- xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 300, seed = 1,
              method = "yperm")
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[-1, "Sig"]), c(41 / 301, 2 / 301))
  expect_equal(unname(tab[-1, "P(ge)"]), c(19 / 301, 2 / 301))
  expect_equal(unname(tab[-1, "Avg"]), c(-0.022552492, -0.001518157), tolerance = 1e-6)
  top3 <- function(p) (p > 0 & p < 4) * 1
  p0 <- top3(as.matrix(newfrat, relation = "PreferenceT00"))
  nets <- list(week1 = top3(as.matrix(newfrat, relation = "PreferenceT01")),
               week0 = p0, week0t = t(p0), twopaths = p0 %*% p0)
  r <- xlrqap(week1 ~ week0 + week0t + twopaths, nets, nperm = 200, seed = 1,
              method = "yperm")
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[-1, "Sig"]), c(1, 3, 23) / 201)
  expect_equal(unname(tab[-1, "Avg"]), c(-0.03667286, -0.04166641, -0.01362706),
               tolerance = 1e-6)
  expect_equal(r$summary$Sig, 1 / 201)
})

test_that("the DSP statistic: the residual's z equals the predictor's", {
  # replacing X_k by its residual on the other X's reparameterizes the model,
  # so the identity permutation reproduces the observed z exactly
  m <- relation_list(hightech)
  d <- qap_design(Advice ~ Friendship + ReportTo, m, sym = FALSE)
  X <- cbind(Intercept = 1, d$xmat)
  yobs <- (d$y > 0)[d$cells] * 1
  obs <- lr_fit(X, yobs, d$xok)
  r <- lr_dsp_one(d, X, yobs, 3, obs, list(seq_len(21)), 2)
  expect_equal(r$b$mean, obs$b[["ReportTo"]], tolerance = 1e-6)
  expect_equal(r$t$ext, 1)
})

test_that("a permuted fit that separates is left out and counted (#39)", {
  # 5 nodes. Y's three ties: two on X = 1 cells, one on an X = 0 cell, so the
  # observed fit converges; a permutation that puts all three on X = 1 cells
  # separates the data (quasi-complete) and cannot converge.
  x <- matrix(0, 5, 5); x[1, 2:5] <- 1; x[2, 3:4] <- 1
  y <- matrix(0, 5, 5); y[1, 2] <- y[2, 3] <- y[4, 5] <- 1
  sep <- lr_fit(cbind(1, c(1, 1, 0, 0)), c(1, 1, 0, 0), rep(TRUE, 4))
  expect_true(sep$failed)
  for (meth in c("dsp", "yperm")) {
    r <- xlrqap(Y ~ X, list(Y = y, X = x), nperm = 300, seed = 2, method = meth)
    expect_gt(r$summary$Failed, 0)
    expect_true(any(grepl("did not converge", r$epilogue)))
  }
  # a separated observed model is an error
  y2 <- y; y2[4, 5] <- 0
  expect_error(xlrqap(Y ~ X, list(Y = y2, X = x), nperm = 0), "does not converge")
})

test_that("failed permuted fits give two p-values, checked by hand (#39)", {
  # The 5-node case above. Every draw is refitted here with lr_fit() from the
  # same permutations, and both bounds are computed from the counts:
  # lower (1 + count) / (1 + converged), upper (1 + count + failed) / (1 + nperm).
  x <- matrix(0, 5, 5); x[1, 2:5] <- 1; x[2, 3:4] <- 1
  y <- matrix(0, 5, 5); y[1, 2] <- y[2, 3] <- y[4, 5] <- 1
  nperm <- 300
  perms <- qap_perms(5, nperm, 2, NULL)
  cells <- which(row(x) != col(x))
  X <- cbind(1, x[cells])
  yobs <- y[cells]
  ok <- rep(TRUE, length(cells))
  obs <- lr_fit(X, yobs, ok)
  tol <- 1e-6 * max(1, abs(obs$t[2]))
  bounds <- function(z, o, ext) {
    f <- sum(is.na(z)); z <- z[!is.na(z)]
    k <- if (ext) sum(abs(z) >= abs(o) - tol) else sum(z >= o - 1e-6 * max(1, abs(o)))
    c(lower = (1 + k) / (1 + nperm - f), upper = (1 + k + f) / (1 + nperm), failed = f)
  }
  # Y permutation: z of X and the log-likelihood, one set of draws for both
  yp <- vapply(perms, function(p) {
    f <- lr_fit(X, y[p, p][cells], ok)
    if (is.null(f) || f$failed) c(NA, NA) else c(f$t[2], f$ll)
  }, numeric(2))
  hz <- bounds(yp[1, ], obs$t[2], TRUE)
  hm <- bounds(yp[2, ], obs$ll, FALSE)
  expect_gt(hz[["failed"]], 0)
  r <- xlrqap(Y ~ X, list(Y = y, X = x), nperm = nperm, seed = 2, method = "yperm")
  tab <- r$matrices[[1]]
  expect_equal(unname(tab["X", c("Sig", "Sig.Upper", "Failed")]), unname(hz))
  expect_equal(c(r$summary$Sig, r$summary$Sig.Upper, r$summary$Failed), unname(hm))
  # DSP: the residual of X on the intercept is X minus its mean
  e <- x - mean(x[cells]); diag(e) <- NA
  dp <- vapply(perms, function(p) {
    Xp <- X; Xp[, 2] <- e[p, p][cells]
    f <- lr_fit(Xp, yobs, ok)
    if (is.null(f) || f$failed) NA_real_ else f$t[2]
  }, numeric(1))
  hd <- bounds(dp, obs$t[2], TRUE)
  expect_gt(hd[["failed"]], 0)
  r <- xlrqap(Y ~ X, list(Y = y, X = x), nperm = nperm, seed = 2)
  tab <- r$matrices[[1]]
  expect_equal(unname(tab["X", c("Sig", "Sig.Upper", "Failed")]), unname(hd))
  # the model's test is the Y permutation under DSP too
  expect_equal(c(r$summary$Sig, r$summary$Sig.Upper, r$summary$Failed), unname(hm))
  # the report: both columns, and the note with the counts per test
  out <- paste(utils::capture.output(print(r)), collapse = " ")
  expect_match(out, "Sig.Up", fixed = TRUE)
  expect_match(out, sprintf("%d of the %d permuted fits did not converge (%d per test: the model %d, X",
                            hm[["failed"]] + hd[["failed"]], 2 * nperm, nperm, hm[["failed"]]),
               fixed = TRUE)
  expect_true(is.na(tab["Intercept", "Sig.Upper"]) && is.na(tab["Intercept", "Failed"]))
})

test_that("no failed fits: one p column printed, both equal in the object (#39)", {
  top3 <- function(p) (p > 0 & p < 4) * 1
  p0 <- top3(as.matrix(newfrat, relation = "PreferenceT00"))
  nets <- list(week1 = top3(as.matrix(newfrat, relation = "PreferenceT01")),
               week0 = p0, week0t = t(p0), twopaths = p0 %*% p0)
  for (meth in c("dsp", "yperm")) {
    r <- xlrqap(week1 ~ week0 + week0t + twopaths, nets, nperm = 200, seed = 1,
                method = meth)
    tab <- r$matrices[[1]]
    expect_equal(r$summary$Failed, 0)
    expect_equal(unname(tab[-1, "Failed"]), c(0, 0, 0))
    expect_identical(tab[, "Sig.Upper"], tab[, "Sig"])
    expect_identical(r$summary$Sig.Upper, r$summary$Sig)
    out <- utils::capture.output(print(r))
    expect_false(any(grepl("Sig.Up|did not converge", out)))
    expect_null(r$epilogue)
  }
})

test_that("LR-QAP DSP: missing cells are dropped listwise, the diagonal ignored", {
  m <- relation_list(hightech)
  y <- m$Advice; f <- m$Friendship
  y[1, 2] <- NA; f[3, 4] <- NA
  diag(y) <- 1; diag(f) <- 5
  r <- xlrqap(Y ~ F + R, list(Y = y, F = f, R = m$ReportTo), nperm = 50, seed = 1)
  expect_equal(r$summary$Obs, 21 * 20 - 2)
  expect_false(anyNA(r$matrices[[1]][-1, "Sig"]))
  off <- row(y) != col(y) & !is.na(y) & !is.na(f)
  g <- stats::glm((y[off] > 0) ~ f[off] + m$ReportTo[off], family = stats::binomial,
                  control = stats::glm.control(epsilon = 1e-14, maxit = 100))
  expect_equal(unname(r$matrices[[1]][, "Coef"]), unname(stats::coef(g)), tolerance = 1e-6)
})

test_that("LR-QAP DSP agrees with sna's netlogit(nullhyp = 'qapspp')", {
  skip_if_not_installed("sna")
  skip_on_cran()
  # sna's "qap"/"qapspp" is double semi-partialling: each X regressed on the
  # others by OLS, the residual permuted and refitted, z compared (Step 1 of
  # #38). Two independent samples of 2000 permutations: |difference| < 0.03.
  # Table 14.4's model:
  top3 <- function(p) (p > 0 & p < 4) * 1
  p0 <- top3(as.matrix(newfrat, relation = "PreferenceT00"))
  nets <- list(week1 = top3(as.matrix(newfrat, relation = "PreferenceT01")),
               week0 = p0, week0t = t(p0), twopaths = p0 %*% p0)
  r <- xlrqap(week1 ~ week0 + week0t + twopaths, nets, nperm = 2000, seed = 1)
  set.seed(1)
  s <- sna::netlogit(nets$week1, list(nets$week0, nets$week0t, nets$twopaths),
                     reps = 2000, nullhyp = "qapspp")
  expect_equal(unname(r$matrices[[1]][, "T"]), s$tstat, tolerance = 1e-6)
  expect_lt(max(abs(r$matrices[[1]][-1, "Sig"] - s$pgreqabs[-1])), 0.03)
  # strongly collinear predictors (r about 0.9), Y driven by X1 alone
  set.seed(7)
  n <- 20
  x1 <- matrix(stats::rnorm(n * n), n); x1 <- x1 + outer(stats::rnorm(n), stats::rnorm(n), "+")
  x2 <- x1 + matrix(stats::rnorm(n * n, sd = 0.5), n)
  y <- matrix(stats::rbinom(n * n, 1, stats::plogis(-1 + 0.4 * x1)), n)
  diag(x1) <- diag(x2) <- diag(y) <- 0
  r <- xlrqap(Y ~ X1 + X2, list(Y = y, X1 = x1, X2 = x2), nperm = 2000, seed = 3)
  set.seed(3)
  s <- sna::netlogit(y, list(x1, x2), reps = 2000, nullhyp = "qapspp")
  expect_lt(max(abs(r$matrices[[1]][-1, "Sig"] - s$pgreqabs[-1])), 0.03)
})

test_that("MRQAP DSP agrees with sna's netlm(nullhyp = 'qapspp')", {
  skip_if_not_installed("sna")
  skip_on_cran()
  # Table 14.3's model; netlm's t is the classical t, which xmrqap permutes
  m <- relation_list(hightech)
  r <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 2000, seed = 1)
  set.seed(1)
  s <- sna::netlm(m$Advice, list(m$Friendship, m$ReportTo), reps = 2000,
                  nullhyp = "qapspp")
  p <- r$matrices[[1]][c("Friendship", "ReportTo"), "P-value"]
  expect_lt(max(abs(p - s$pgreqabs[-1])), 0.03)
  # strongly collinear predictors
  set.seed(7)
  n <- 20
  x1 <- matrix(stats::rnorm(n * n), n); x1 <- x1 + outer(stats::rnorm(n), stats::rnorm(n), "+")
  x2 <- x1 + matrix(stats::rnorm(n * n, sd = 0.5), n)
  y <- 0.3 * x1 + matrix(stats::rnorm(n * n), n)
  diag(x1) <- diag(x2) <- diag(y) <- 0
  r <- xmrqap(Y ~ X1 + X2, list(Y = y, X1 = x1, X2 = x2), nperm = 2000, seed = 3)
  set.seed(3)
  s <- sna::netlm(y, list(x1, x2), reps = 2000, nullhyp = "qapspp")
  p <- r$matrices[[1]][c("X1", "X2"), "P-value"]
  expect_lt(max(abs(p - s$pgreqabs[-1])), 0.03)
})

test_that("symmetric = TRUE uses one triangle; a constant Y is refused", {
  u <- list(A = xsymmetrize(as.matrix(hightech, relation = 1))$data,
            B = xsymmetrize(as.matrix(hightech, relation = 2))$data)
  r <- xlrqap(A ~ B, u, nperm = 0, symmetric = TRUE)
  expect_equal(r$summary$Obs, 210)
  z <- list(A = matrix(0, 4, 4), B = matrix(1, 4, 4))
  expect_error(xlrqap(A ~ B, z, nperm = 0), "constant")
})

test_that("Newcomb's fraternity reproduces Table 14.4 (14.5.2)", {
  # The book's model, from the 1e practice (WebsitePractices, ASNR CHAPTER 14
  # Practice Update 2 May 2022.Rmd, lines 266-270; issue #29): week 1 top-three
  # choices on week 0's top-three choices, their transpose and the count of
  # 2-paths among them (not dichotomized), diagonal excluded. It was fitted with
  # sna::netlogit; the coefficients and log likelihood do not depend on the
  # permutations.
  top3 <- function(p) (p > 0 & p < 4) * 1
  p0 <- top3(as.matrix(newfrat, relation = "PreferenceT00"))
  nets <- list(week1 = top3(as.matrix(newfrat, relation = "PreferenceT01")),
               week0 = p0, week0t = t(p0), twopaths = p0 %*% p0)
  r <- xlrqap(week1 ~ week0 + week0t + twopaths, nets, nperm = 0)
  expect_equal(round(unname(r$matrices[[1]][, "Coef"]), 3),
               c(-2.642, 2.258, 0.829, 0.510))
  expect_equal(round(r$summary$LL, 2), -100.08)
  expect_equal(r$summary$Obs, 272)
})

# ---- ANOVA density models -----------------------------------------------------------

test_that("the density models' coefficients are differences of densities", {
  g <- camp92_attr$Gender
  r <- xmixing(campnet, g)
  dens <- xdensitybygroups(campnet, g)$matrices$Density
  ch <- r$matrices[["Constant Homophily"]]
  m <- as.matrix(campnet); off <- row(m) != col(m)
  same <- outer(g, g, "==")
  expect_equal(ch["Intercept", 1], mean(m[off & !same]), tolerance = tol)
  expect_equal(ch["In-group", 1], mean(m[off & same]) - mean(m[off & !same]),
               tolerance = tol)
  sbm <- r$matrices[["Structural Blockmodel"]]
  expect_equal(sbm["Intercept", 1], dens[2, 2], tolerance = tol)
  expect_equal(sbm["1-1", 1], dens[1, 1] - dens[2, 2], tolerance = tol)
  expect_equal(sbm["2-1", 1], dens[2, 1] - dens[2, 2], tolerance = tol)
  vh <- r$matrices[["Variable Homophily"]]
  expect_equal(nrow(vh), 3)
  expect_true(all(is.na(r$matrices[["Constant Homophily"]][, "Significance"])))
})

test_that("xmixing(test = TRUE) adds the permutation p-values (#33)", {
  expect_differs_from_ucinet(33)
  r <- xmixing(campnet, camp92_attr$Gender, test = TRUE, nperm = 500, seed = 1)
  ch <- r$matrices[["Constant Homophily"]]
  expect_lt(ch["In-group", "Significance"], 0.05)
  expect_equal(rownames(r$summary), c("Constant Homophily", "Variable Homophily",
                                      "Structural Blockmodel"))
  expect_false(anyNA(r$summary[["P(R-Sqr)"]]))
})

# ---- reports and goldens -------------------------------------------------------------

test_that("the reports print", {
  d <- node_df()
  expect_snapshot(xregression(y ~ x1 + x2, d, nperm = 100, seed = 1))
  expect_snapshot(xcorrelation(d$x1, d$y, nperm = 100, seed = 1))
  expect_snapshot(xqap(as.matrix(padgett, relation = 1),
                       as.matrix(padgett, relation = 2), nperm = 100, seed = 1))
  expect_snapshot(xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 100,
                         seed = 1))
  expect_snapshot(xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 50,
                         seed = 1))
  x <- matrix(0, 5, 5); x[1, 2:5] <- 1; x[2, 3:4] <- 1
  y <- matrix(0, 5, 5); y[1, 2] <- y[2, 3] <- y[4, 5] <- 1
  expect_snapshot(xlrqap(Y ~ X, list(Y = y, X = x), nperm = 300, seed = 2))
  expect_snapshot(xmixing(campnet, camp92_attr$Gender, test = TRUE,
                          nperm = 100, seed = 1))
})

test_that("observed statistics match UCINET", {
  skip_if_no_golden("g14_qap_padgett", "hypotheses")
  skip_if_no_golden("g14_mrqap_hightech", "hypotheses")
  q <- xqap(as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2),
            nperm = 0)
  expect_equal(q$matrices[[1]][1, "Obs Value"],
               golden_matrix("g14_qap_padgett", "hypotheses")[1, 1], tolerance = 1e-4)
  r <- xmrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 0)
  expect_equal(unname(r$matrices[[1]][, 1]),
               unname(golden_matrix("g14_mrqap_hightech", "hypotheses")[, 1]),
               tolerance = 1e-4)
})
