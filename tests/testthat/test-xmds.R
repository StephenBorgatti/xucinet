# xmds: classical against stats::cmdscale, a known exact configuration and
# borgworld; non-metric against borgworld and (when generated) UCINET's
# non-metric MDS goldens under Procrustes.

fx <- readRDS(test_path("fixtures", "borgworld-ch06.rds"))
tol <- 1e-12

test_that("classical MDS of cities is cmdscale, and reproduces borgworld exactly", {
  res <- xmds(cities, type = "d", plot = FALSE)
  ref <- cmdscale(as.matrix(cities), k = 2, eig = TRUE)
  expect_equal(as.matrix(res$nodes), ref$points, tolerance = 1e-10, ignore_attr = TRUE)
  expect_equal(res$eig, ref$eig, tolerance = 1e-10)
  bw <- fx$cmds_cities
  expect_equal(as.matrix(res$nodes), bw$points, tolerance = tol)
  expect_equal(res$eig, bw$eig, tolerance = tol)
  expect_equal(res$summary$Stress, bw$stress, tolerance = tol)
  expect_equal(res$summary$GOF1, unname(bw$GOF["GOF1"]), tolerance = tol)
  expect_equal(res$summary$GOF2, unname(bw$GOF["GOF2"]), tolerance = tol)
  ev <- res$matrices$Eigenvalues
  expect_equal(unname(ev[, "Value"]), bw$eig[bw$eig > 0], tolerance = tol)
  expect_equal(sum(ev[, "Prop"]), 1, tolerance = tol)
})

test_that("a Euclidean distance matrix recovers its configuration exactly", {
  set.seed(3)
  conf <- matrix(rnorm(24), 12, 2, dimnames = list(letters[1:12], NULL))
  d <- as.matrix(dist(conf))
  res <- xmds(d, type = "d", plot = FALSE)
  expect_procrustes_equal(as.matrix(res$nodes), conf, tolerance = 1e-10)
  expect_lt(abs(res$eig[3]), 1e-8)
  expect_lt(res$summary$Stress, 1e-8)
  expect_equal(res$summary$GOF1, 1, tolerance = 1e-8)
})

test_that("stress is Kruskal formula 1 with the data in the denominator", {
  res <- xmds(cities, type = "d", plot = FALSE)
  d <- res$dissimilarities
  dhat <- as.matrix(dist(as.matrix(res$nodes)))
  expect_equal(res$summary$Stress, sqrt(sum((d - dhat)^2) / sum(d^2)), tolerance = tol)
})

test_that("similarity input: off-diagonal max; equals borgworld when the diagonal is not the max", {
  m <- as.matrix(campnet); m <- (m + t(m)) / 2
  res <- xmds(m, type = "s", plot = FALSE)
  expect_true(any(grepl("converted to dissimilarities as 1 - x", res$assumptions)))
  expect_equal(as.matrix(res$nodes), fx$cmds_campnet$points, tolerance = tol)
  # A co-membership matrix has each woman's number of events on the diagonal
  # (up to 8) and a smaller off-diagonal maximum (7), so here the two rules
  # differ by a constant on every distance, and the maps differ (question 9).
  co <- as.matrix(davis) %*% t(as.matrix(davis))
  ours <- xmds(co, type = "s", plot = FALSE)
  whole <- max(co) - co; diag(whole) <- 0           # borgworld's rule
  expect_gt(procrustes_rss(as.matrix(ours$nodes), cmdscale(whole, k = 2)), 1e-4)
  off <- max(co[row(co) != col(co)]) - co; diag(off) <- 0
  expect_equal(as.matrix(ours$nodes), cmdscale(off, k = 2), tolerance = 1e-10, ignore_attr = TRUE)
  expect_true(any(grepl("as 7 - x", ours$assumptions)))
})

test_that("non-metric MDS of cities reproduces borgworld, with no seed", {
  res <- xmds(cities, type = "d", method = "nonmetric", plot = FALSE)
  bw <- fx$nmds_cities
  expect_equal(as.matrix(res$nodes), bw$points, tolerance = tol)
  expect_equal(res$summary$Stress, bw$stress, tolerance = tol)
  again <- xmds(cities, type = "d", method = "nonmetric", plot = FALSE)
  expect_identical(res$nodes, again$nodes)
  expect_identical(names(res$shepard), c("Pair", "Dissimilarity", "Distance", "Disparity"))
  expect_equal(nrow(res$shepard), 36)
  expect_equal(res$shepard$Dissimilarity, sort(as.dist(as.matrix(cities))))
  # the disparities are monotone in the dissimilarities
  expect_true(all(diff(res$shepard$Disparity) >= -1e-12))
  expect_equal(res$shepard$Pair[1], "BOSTON-NY")
})

test_that("non-metric MDS on a binary network nudges zero dissimilarities and says so", {
  m <- as.matrix(campnet); m <- (m + t(m)) / 2
  res <- xmds(m, type = "s", method = "nonmetric", plot = FALSE)
  expect_true(any(grepl("pairs at zero dissimilarity set to", res$assumptions)))
  expect_true(is.finite(res$summary$Stress))
  expect_equal(dim(res$nodes), c(18, 2))
})

test_that("dim = 1 and dim = 3 work; dim >= n is refused", {
  one <- xmds(cities, type = "d", dim = 1, plot = FALSE)
  expect_equal(ncol(one$nodes), 1)
  three <- xmds(cities, type = "d", dim = 3, plot = FALSE)
  expect_equal(names(three$nodes), c("Dim1", "Dim2", "Dim3"))
  expect_error(xmds(cities, type = "d", dim = 9, plot = FALSE), "at most 8")
  expect_error(xmds(cities, type = "d", dim = 0, plot = FALSE), "at least 1")
  m <- matrix(c(0, 3, 3, 0), 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  expect_error(xmds(m, type = "d", plot = FALSE), "at most 1")
  expect_equal(abs(diff(xmds(m, type = "d", dim = 1, plot = FALSE)$nodes$Dim1)), 3)
})

test_that("type is required; dist, xucinet and labels are accepted; NA and Inf are refused", {
  expect_error(xmds(cities, plot = FALSE), 'xmds\\(cities, type = "dissimilarities"\\)')
  d <- as.dist(as.matrix(cities))
  expect_equal(xmds(d, type = "d", plot = FALSE)$nodes, xmds(cities, type = "d", plot = FALSE)$nodes)
  lab <- xmds(cities, type = "d", plot = FALSE, labels = letters[1:9])
  expect_identical(rownames(lab$nodes), letters[1:9])
  expect_error(xmds(cities, type = "d", plot = FALSE, labels = "a"), "one entry per object")
  g <- as.matrix(cities); g[1, 9] <- g[9, 1] <- Inf
  expect_error(xmds(g, type = "d", plot = FALSE), "disconnected network")
  g[1, 9] <- g[9, 1] <- NA
  expect_error(xmds(g, type = "d", plot = FALSE), "missing or infinite")
  expect_error(xmds(davis, type = "s", plot = FALSE), "square")
})

test_that("an asymmetric matrix is averaged and reported", {
  res <- xmds(campnet, type = "s", plot = FALSE)
  expect_true(any(grepl("symmetrized by averaging", res$assumptions)))
})

test_that("the printed report prints every row, never head()", {
  res <- xmds(campnet, type = "s", plot = FALSE)
  out <- capture.output(print(res))
  expect_true(any(grepl("BRAZEY", out)))
  expect_true(any(grepl("^Type of Data: +Similarities", out)))
  expect_true(any(grepl("^Dimensions: +2", out)))
  expect_false(any(grepl("Showing first", out)))
  expect_snapshot(print(xmds(cities, type = "d", plot = FALSE)))
})

test_that("plots draw on a null device; xshepard needs a non-metric result", {
  pdf(NULL); on.exit(dev.off())
  expect_invisible(xmds(cities, type = "d"))
  expect_invisible(xmds(cities, type = "d", dim = 1))
  nm <- xmds(cities, type = "d", method = "nonmetric")
  expect_invisible(xshepard(nm))
  expect_error(xshepard(xmds(cities, type = "d", plot = FALSE)), "nonmetric")
})

# ---- UCINET goldens (skip until inst/goldens/multivariate is generated) -----

test_that("non-metric configuration of cities matches UCINET's under Procrustes, stress within 0.02", {
  skip_if_no_golden("g6_nmds_cities", "multivariate")
  gold <- golden_matrix("g6_nmds_cities", "multivariate")
  res <- xmds(cities, type = "d", method = "nonmetric", plot = FALSE)
  expect_procrustes_equal(as.matrix(res$nodes), gold[rownames(res$nodes), 1:2], tolerance = 0.05)
  if (golden_exists("g6_nmds_cities_stress", "multivariate")) {
    theirs <- as.numeric(golden_matrix("g6_nmds_cities_stress", "multivariate"))[1]
    # one-sided: a lower stress is a better fit, not a failure
    expect_lte(res$summary$Stress, theirs + 0.02)
  }
})
