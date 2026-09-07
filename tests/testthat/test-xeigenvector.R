# xeigenvector against UCINET 6.849's eigencent().

tol <- 1e-5

disc <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_disc"))
iso  <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))

test_that("eigenvector matches UCINET on connected graphs", {
  cases <- list(list("G9_EIGC_CAMPNET", campnet),
                list("G9_EIGC_ISO",     iso()),
                list("G9_EIGC_BAKER",   baker_journals))
  for (case in cases) {
    skip_if_no_golden(case[[1]], "centrality")
    gold <- as.vector(golden_matrix(case[[1]], "centrality"))
    expect_equal(xeigenvector(case[[2]])$nodes$Eigenvector, gold,
                 tolerance = tol, info = case[[1]])
  }
})

test_that("a disconnected graph takes the Everett-Borgatti method", {
  skip_if_no_golden("G9_EIGC_DISC", "centrality")
  gold <- as.vector(golden_matrix("G9_EIGC_DISC", "centrality"))
  res <- xeigenvector(disc())

  expect_equal(res$nodes$Eigenvector, gold, tolerance = tol)
  expect_true(any(grepl("Everett-Borgatti", res$assumptions)))
  expect_equal(res$summary$`Non-trivial components`, 3)
  expect_null(res$summary$`Principal eigenvalue`)

  # The point of the method: every component scores, rather than one taking
  # everything. A plain principal eigenvector would zero two of the three.
  expect_true(all(tapply(res$nodes$Eigenvector,
                         rep(1:3, times = c(5, 4, 3)), max) > 0))
})

test_that("the lambda-squared score is what the Delphi says it is", {
  # score = lambda^2 * sum(v) * v(i), per component. The four-leaf star has
  # lambda 2, unit eigenvector (0.7071, 0.3536 x 4) summing to 2.1213, so the
  # hub scores 4 * 2.1213 * 0.7071 = 6 exactly.
  res <- xeigenvector(disc())
  expect_equal(res$nodes$Eigenvector[1], 6, tolerance = tol)
  expect_equal(res$nodes$Eigenvector[2], 3, tolerance = tol)
  # the triangle, lambda 2, v = 0.5774 each, sum 1.7321 -> 4
  expect_equal(res$nodes$Eigenvector[10], 4, tolerance = tol)
})

test_that("isolates alone do not trigger the switch", {
  # g9_iso is a seven-node core plus three isolates: four components, but only
  # one non-trivial, so UCINET takes the ordinary path and so do we.
  res <- xeigenvector(iso())
  expect_false(any(grepl("Everett-Borgatti", res$assumptions)))
  expect_false(is.null(res$summary$`Principal eigenvalue`))
  expect_equal(res$nodes$Eigenvector[8:10], c(0, 0, 0), tolerance = tol)
})

test_that("the connected result is unit length with a positive sign", {
  v <- xeigenvector(campnet)$nodes$Eigenvector
  expect_equal(sum(v^2), 1, tolerance = tol)
  expect_true(all(v >= 0))
})

test_that("asymmetric input is symmetrized by maximum, and says so", {
  res <- xeigenvector(campnet)
  expect_true(any(grepl("symmetrized by maximum", res$assumptions)))
  expect_equal(res$nodes$Eigenvector,
               xeigenvector(pmax(as.matrix(campnet),
                                 t(as.matrix(campnet))))$nodes$Eigenvector,
               tolerance = tol)
})

test_that("every relation of sampson matches", {
  skip_if_no_golden("G9_EIGC_SAMPSON", "centrality")
  gold <- golden_matrix("G9_EIGC_SAMPSON", "centrality")
  for (k in seq_len(ncol(gold))) {
    expect_equal(xeigenvector(sampson, relation = k)$nodes$Eigenvector,
                 unname(gold[, k]), tolerance = tol)
  }
})
