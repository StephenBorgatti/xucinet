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
  g <- stats::glm((m$Advice[off] > 0) ~ m$Friendship[off] + m$ReportTo[off],
                  family = stats::binomial)
  tab <- r$matrices[[1]]
  expect_equal(unname(tab[, "Coef"]), unname(stats::coef(g)), tolerance = 1e-6)
  expect_equal(unname(tab[, "T"]), unname(summary(g)$coefficients[, 3]), tolerance = 1e-6)
  expect_equal(r$summary$LL, as.numeric(stats::logLik(g)), tolerance = 1e-6)
  g0 <- stats::glm((m$Advice[off] > 0) ~ 1, family = stats::binomial)
  expect_equal(r$summary[["R-Sqr"]],
               1 - as.numeric(stats::logLik(g)) / as.numeric(stats::logLik(g0)),
               tolerance = 1e-6)
})

test_that("LR-QAP p-values come from permuting Y", {
  r <- xlrqap(Advice ~ Friendship + ReportTo, hightech, nperm = 300, seed = 1)
  tab <- r$matrices[[1]]
  expect_true(is.na(tab["Intercept", "Sig"]))
  expect_lt(tab["ReportTo", "Sig"], 0.05)
  expect_equal(r$summary$Perms, 300)
})

test_that("symmetric = TRUE uses one triangle; a constant Y is refused", {
  u <- list(A = xsymmetrize(as.matrix(hightech, relation = 1))$data,
            B = xsymmetrize(as.matrix(hightech, relation = 2))$data)
  r <- xlrqap(A ~ B, u, nperm = 0, symmetric = TRUE)
  expect_equal(r$summary$Obs, 210)
  z <- list(A = matrix(0, 4, 4), B = matrix(1, 4, 4))
  expect_error(xlrqap(A ~ B, z, nperm = 0), "constant")
})

# ---- ANOVA density models -----------------------------------------------------------

test_that("the density models' coefficients are differences of densities", {
  g <- camp92_attr$Gender
  r <- xdensitybygroups(campnet, g)
  dens <- r$matrices$Density
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

test_that("test = TRUE adds the permutation p-values", {
  expect_differs_from_ucinet(33)
  r <- xdensitybygroups(campnet, camp92_attr$Gender, test = TRUE, nperm = 500,
                        seed = 1)
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
  expect_snapshot(xdensitybygroups(campnet, camp92_attr$Gender, test = TRUE,
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
