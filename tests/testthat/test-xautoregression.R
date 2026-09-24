# xautoregression wraps sna::lnam (issue #28, Steve 24 Sep 2026). There is no
# UCINET routine, so no golden: the reference is an independent maximum
# likelihood fit in base R, by the concentrated log-likelihood.

skip_if_not_installed("sna")
skip_if_not_installed("numDeriv")

ar_data <- function() {
  deg <- xdegree(campnet)$nodes
  data.frame(indeg = deg[["Indeg"]],
             btw = xbetweenness(campnet)$nodes[["Betweenness"]],
             row.names = rownames(deg))
}

row_norm <- function(w) {
  w <- unname(w); diag(w) <- 0
  rs <- rowSums(w); w[rs > 0, ] <- w[rs > 0, ] / rs[rs > 0]; w
}

# Concentrated log-likelihood: for a given rho (lag) or lambda (error), beta
# and sigma^2 have closed forms; maximize over the network parameter.
ml_fit <- function(y, X, W, model) {
  n <- length(y); I <- diag(n)
  prof <- function(p) {
    A <- I - p * W
    if (model == "lag") { yy <- A %*% y; XX <- X } else { yy <- A %*% y; XX <- A %*% X }
    b <- qr.coef(qr(XX), yy)
    e <- yy - XX %*% b
    s2 <- sum(e^2) / n
    list(ll = as.numeric(determinant(A)$modulus) - n / 2 * log(2 * pi * s2) - n / 2,
         b = as.vector(b), s2 = s2)
  }
  r <- stats::optimize(function(p) prof(p)$ll, c(-0.99, 0.99), maximum = TRUE,
                       tol = 1e-10)
  c(list(p = r$maximum), prof(r$maximum))
}

test_that("the lag model agrees with an independent ML fit", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d)
  ref <- ml_fit(d$indeg, cbind(1, d$btw), row_norm(as.matrix(campnet)), "lag")
  co <- a$matrices[[1]]
  expect_lt(abs(co["Rho", "Coef"] - ref$p), 1e-4)
  expect_lt(max(abs(co[1:2, "Coef"] - ref$b)), 1e-3)
  expect_lt(abs(a$summary$LogLik - ref$ll), 1e-6)
  expect_lt(abs(a$summary$Sigma - sqrt(ref$s2)), 1e-4)
})

test_that("the error model agrees with an independent ML fit", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d, model = "error")
  ref <- ml_fit(d$indeg, cbind(1, d$btw), row_norm(as.matrix(campnet)), "error")
  co <- a$matrices[[1]]
  expect_equal(rownames(co), c("Intercept", "btw", "Lambda"))
  expect_lt(abs(co["Lambda", "Coef"] - ref$p), 1e-4)
  expect_lt(max(abs(co[1:2, "Coef"] - ref$b)), 1e-3)
  expect_lt(abs(a$summary$LogLik - ref$ll), 1e-6)
})

test_that("it is sna::lnam on the row-normalized network", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d)
  f <- sna::lnam(d$indeg, cbind(1, d$btw), W1 = row_norm(as.matrix(campnet)))
  expect_equal(unname(a$matrices[[1]][, "Coef"]),
               c(as.vector(f$beta), f$rho1), ignore_attr = TRUE)
  expect_equal(unname(a$matrices[[1]][, "SE"]),
               c(as.vector(f$beta.se), f$rho1.se), ignore_attr = TRUE)
  expect_true("W row-normalized." %in% a$assumptions)
})

test_that("normalize = FALSE uses W as it is", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d, normalize = FALSE)
  f <- sna::lnam(d$indeg, cbind(1, d$btw), W1 = unname(as.matrix(campnet)))
  expect_equal(a$matrices[[1]]["Rho", "Coef"], unname(f$rho1),
               ignore_attr = TRUE)
})

test_that("the same slots whatever the model", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d)
  b <- xautoregression(campnet, indeg ~ btw, d, model = "error")
  expect_equal(names(a$summary), names(b$summary))
  expect_equal(colnames(a$matrices[[1]]), colnames(b$matrices[[1]]))
  expect_equal(names(a$nodes), c("Y-Hat", "Residuals"))
  expect_equal(rownames(a$nodes), rownames(as.matrix(campnet)))
})

test_that("data are aligned to the node order by row name", {
  d <- ar_data()
  a <- xautoregression(campnet, indeg ~ btw, d)
  b <- xautoregression(campnet, indeg ~ btw, d[rev(seq_len(nrow(d))), ])
  expect_equal(a$matrices[[1]], b$matrices[[1]])
})

test_that("missing data are refused, not dropped", {
  d <- ar_data(); d$btw[3] <- NA
  expect_error(xautoregression(campnet, indeg ~ btw, d), "complete data")
})

test_that("the 1e names reach it", {
  d <- ar_data()
  expect_message(xAutoRegression(campnet, indeg ~ btw, d), "xautoregression")
})

test_that("the report prints", {
  expect_snapshot(xautoregression(campnet, indeg ~ btw, ar_data()))
})
