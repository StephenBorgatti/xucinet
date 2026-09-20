# xcorrespondence: against borgworld (the port's source), against the
# textbook decomposition written out by hand, and against UCINET's
# Correspondence Analysis goldens (skipped until they are generated).

fx <- readRDS(test_path("fixtures", "borgworld-ch06.rds"))
tol <- 1e-12

test_that("scores, contributions and cos2 reproduce borgworld at full rank", {
  # bcorresp's default ncp is the full rank, where its truncated-inertia bug
  # does not bite, so everything should agree to floating point.
  bw <- fx$ca_doctorates
  res <- xcorrespondence(doctorates, dim = bw$n.dim, plot = FALSE)
  expect_equal(as.matrix(res$nodes), bw$row.coords, tolerance = tol)
  expect_equal(res$matrices[["Column Scores"]], bw$col.coords, tolerance = tol)
  expect_equal(unname(res$matrices[["Singular Values"]][, "Inertia"]), bw$eigenvalues, tolerance = tol)
  expect_equal(unname(res$matrices[["Singular Values"]][, "Percent"]), bw$variance.explained, tolerance = tol)
  expect_equal(res$matrices[["Row Contributions"]], bw$row.contrib, tolerance = tol)
  expect_equal(res$matrices[["Column Contributions"]], bw$col.contrib, tolerance = tol)
  expect_equal(res$cos2$rows, bw$row.cos2, tolerance = tol)
  expect_equal(res$cos2$columns, bw$col.cos2, tolerance = tol)
  expect_equal(res$summary[["Total inertia"]], bw$total.inertia, tolerance = tol)
  expect_equal(res$summary[["Chi-square"]], bw$chi2$statistic, tolerance = tol)
  expect_equal(res$summary[["df"]], bw$chi2$df)
  expect_equal(res$summary[["p-value"]], bw$chi2$p.value, tolerance = 1e-10)
})

test_that("with dim < rank the inertia, percentages and chi-square use the full spectrum", {
  full <- xcorrespondence(doctorates, dim = 7, plot = FALSE)
  two <- xcorrespondence(doctorates, dim = 2, plot = FALSE)
  expect_equal(two$summary[["Total inertia"]], full$summary[["Total inertia"]])
  expect_equal(two$summary[["Chi-square"]], full$summary[["Chi-square"]])
  expect_identical(two$matrices[["Singular Values"]], full$matrices[["Singular Values"]])
  expect_lt(two$matrices[["Singular Values"]][2, "Cumulative"], 100)
  expect_equal(as.matrix(two$nodes), as.matrix(full$nodes)[, 1:2])
  # and this is exactly where bcorresp(ncp = 2) goes wrong: its total inertia
  # would be the first two eigenvalues only, and its percentages sum to 100.
  bw <- fx$ca_doctorates
  expect_gt(bw$total.inertia, sum(bw$eigenvalues[1:2]))
})

test_that("the decomposition is the textbook one, written out by hand", {
  m <- as.matrix(doctorates)
  N <- sum(m); P <- m / N
  r <- rowSums(P); cc <- colSums(P)
  S <- diag(1 / sqrt(r)) %*% (P - outer(r, cc)) %*% diag(1 / sqrt(cc))
  s <- svd(S)
  res <- xcorrespondence(doctorates, dim = 2, plot = FALSE)
  expect_equal(unname(res$matrices[["Singular Values"]][1:2, "Singular value"]), s$d[1:2], tolerance = tol)
  rows <- diag(1 / sqrt(r)) %*% s$u[, 1:2] %*% diag(s$d[1:2])
  expect_equal_up_to_sign(as.matrix(res$nodes), rows, tolerance = tol)
  expect_equal(res$summary[["Chi-square"]],
               unname(suppressWarnings(chisq.test(m))$statistic), tolerance = 1e-8)
  # principal coordinates on both margins: the row points are the weighted
  # average of the column points scaled by 1/d (the transition formula)
  cols <- res$matrices[["Column Scores"]]
  profiles <- sweep(m, 1, rowSums(m), "/")
  expect_equal(as.matrix(res$nodes), (profiles %*% cols) %*% diag(1 / s$d[1:2]),
               tolerance = 1e-10, ignore_attr = TRUE)
})

test_that("a 2-mode dataset and a square table both work; more columns than rows is fine", {
  res <- xcorrespondence(davis, plot = FALSE)
  expect_equal(nrow(res$nodes), 18)
  expect_equal(nrow(res$matrices[["Column Scores"]]), 14)
  expect_equal(nrow(res$matrices[["Singular Values"]]), 13)
  bw <- fx$ca_davis
  expect_equal(as.matrix(xcorrespondence(davis, dim = bw$n.dim, plot = FALSE)$nodes),
               bw$row.coords, tolerance = tol)
  wide <- xcorrespondence(t(as.matrix(davis)), plot = FALSE)
  expect_equal(nrow(wide$nodes), 14)
  expect_equal(wide$summary[["Total inertia"]], res$summary[["Total inertia"]], tolerance = tol)
})

test_that("input rules: negatives refused, NA to the mean, zero margins dropped and named", {
  m <- as.matrix(doctorates)
  bad <- m; bad[1, 1] <- -1
  expect_error(xcorrespondence(bad, plot = FALSE), "non-negative")
  na <- m; na[2, 3] <- NA
  res <- xcorrespondence(na, plot = FALSE)
  expect_true(any(grepl("replaced by the overall mean", res$assumptions)))
  filled <- m; filled[2, 3] <- mean(m[-which(is.na(na))])
  expect_equal(res$summary[["Total inertia"]],
               xcorrespondence(filled, plot = FALSE)$summary[["Total inertia"]], tolerance = tol)
  z <- cbind(m, Empty = 0); z <- rbind(z, Nothing = 0)
  res <- xcorrespondence(z, plot = FALSE)
  expect_true(any(grepl("All-zero rows dropped: Nothing", res$assumptions)))
  expect_true(any(grepl("All-zero columns dropped: Empty", res$assumptions)))
  expect_equal(as.matrix(res$nodes), as.matrix(xcorrespondence(m, plot = FALSE)$nodes), tolerance = tol)
})

test_that("dim is capped at the rank and says so; a 2 x 2 table has one dimension", {
  res <- xcorrespondence(doctorates, dim = 10, plot = FALSE)
  expect_equal(ncol(res$nodes), 7)
  expect_true(any(grepl("dim reduced from 10 to 7", res$assumptions)))
  m <- matrix(c(10, 2, 3, 12), 2, 2, dimnames = list(c("a", "b"), c("x", "y")))
  res <- xcorrespondence(m, plot = FALSE)
  expect_equal(ncol(res$nodes), 1)
  expect_equal(res$summary[["df"]], 1)
  expect_error(xcorrespondence(matrix(1:3, 1, 3), plot = FALSE), "at least two rows")
})

test_that("the printed report snapshot", {
  expect_snapshot(print(xcorrespondence(doctorates, plot = FALSE)))
})

test_that("plot = TRUE draws two groups on a null device and returns invisibly", {
  pdf(NULL); on.exit(dev.off())
  expect_invisible(xcorrespondence(doctorates))
  expect_message(xcorrespondence(doctorates, dim = 1), "nothing to plot")
})

# ---- UCINET goldens (skip until inst/goldens/multivariate is generated) -----

test_that("row and column scores match UCINET's up to the sign of each axis", {
  skip_if_no_golden("g6_ca_doctorates_r", "multivariate")
  rs <- golden_matrix("g6_ca_doctorates_r", "multivariate")
  cs <- golden_matrix("g6_ca_doctorates_c", "multivariate")
  res <- xcorrespondence(doctorates, dim = ncol(rs), plot = FALSE)
  expect_equal_up_to_sign(as.matrix(res$nodes), rs[rownames(res$nodes), , drop = FALSE],
                          tolerance = 1e-5, info = "row scores")
  expect_equal_up_to_sign(res$matrices[["Column Scores"]], cs[rownames(res$matrices[["Column Scores"]]), , drop = FALSE],
                          tolerance = 1e-5, info = "column scores")
})

test_that("inertias match UCINET's squared singular values", {
  skip_if_no_golden("g6_ca_doctorates_e", "multivariate")
  e <- golden_matrix("g6_ca_doctorates_e", "multivariate")
  res <- xcorrespondence(doctorates, plot = FALSE)
  # UCINET's table holds the singular values d, not d^2: square before comparing.
  sv <- as.numeric(e[, 1])
  sv <- sv[seq_len(nrow(res$matrices[["Singular Values"]]))]
  expect_equal(unname(res$matrices[["Singular Values"]][, "Inertia"]), sv^2, tolerance = 1e-6)
})

test_that("the davis 2-mode goldens agree up to sign", {
  skip_if_no_golden("g6_ca_davis_r", "multivariate")
  rs <- golden_matrix("g6_ca_davis_r", "multivariate")
  res <- xcorrespondence(davis, dim = ncol(rs), plot = FALSE)
  expect_equal_up_to_sign(as.matrix(res$nodes), rs[rownames(res$nodes), , drop = FALSE],
                          tolerance = 1e-5)
})
