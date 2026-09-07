# 2-mode centrality against UCINET 6.849.
#
# Every one of the five measures needed its convention established rather than
# assumed, so the tests check the conventions as well as the numbers.

tol <- 1e-5

test_that("both margins match UCINET on davis", {
  for (case in list(list("g9m_2mode_davis", "rows"),
                    list("davis-colcent",   "cols"))) {
    skip_if_no_golden(case[[1]], "centrality")
    gold <- golden_matrix(case[[1]], "centrality")
    ours <- xcentrality(davis, mode = case[[2]])$nodes
    expect_identical(names(ours), colnames(gold))
    for (cn in colnames(gold)) {
      # abs() on the golden: UCINET returns 2-mode eigenvector scores negative
      # and we report them positive, which is UCINET issue 2.
      expect_equal(ours[[cn]], abs(unname(gold[, cn])), tolerance = tol,
                   info = paste(case[[2]], cn))
    }
  }
})

test_that("every normalization uses the opposite mode", {
  m <- as.matrix(davis)
  nr <- nrow(m); nc <- ncol(m)
  expect_equal(xcentrality(davis)$nodes$Degree,
               unname(rowSums(m)) / nc, tolerance = tol)
  expect_equal(xcentrality(davis, mode = "cols")$nodes$Degree,
               unname(colSums(m)) / nr, tolerance = tol)
})

test_that("closeness is the minimum possible distance sum over the actual", {
  # For a node whose own set has n_o members and the other n_i, the minimum is
  # n_i + 2(n_o - 1): one step to everything opposite, two to its own kind.
  m <- as.matrix(davis); nr <- nrow(m); nc <- ncol(m)
  d <- geodesics(bipartite((m > 0) * 1))
  expect_equal(xcentrality(davis)$nodes$Closeness,
               (nc + 2 * (nr - 1)) / rowSums(d)[seq_len(nr)],
               tolerance = tol, ignore_attr = TRUE)
})

test_that("betweenness follows UCINET's getmax, not the 1997 paper", {
  # Borgatti and Everett (1997) p. 256 give 2(n_o - 1)(n_i - 1) for n_o > n_i,
  # which for davis rows is 2*17*13 = 442. UCINET's getmax gives 890, i.e. a
  # denominator of 445, and 445 is what reproduces the fixture. The paper's
  # other branch does agree: for the columns both give 452.
  expect_equal(bipartite_max_betweenness(18, 14), 890)
  expect_equal(bipartite_max_betweenness(14, 18), 904)
  expect_false(bipartite_max_betweenness(18, 14) / 2 == 2 * 17 * 13)

  # The paper's n_o <= n_i branch is this same function at s = 0, so it agrees
  # wherever it applies.
  paper_branch <- function(n_o, n_i) {
    0.5 * n_i * (n_i - 1) + 0.5 * (n_o - 1) * (n_o - 2) + (n_o - 1) * (n_i - 1)
  }
  for (n_o in 2:8) for (n_i in n_o:10) {
    expect_equal(bipartite_max_betweenness(n_o, n_i) / 2,
                 paper_branch(n_o, n_i), info = paste(n_o, n_i))
  }
})

test_that("the eigenvector is scaled per mode, not across the whole vector", {
  r <- xcentrality(davis)$nodes$Eigenvector
  c2 <- xcentrality(davis, mode = "cols")$nodes$Eigenvector
  expect_equal(sum(r^2), 1, tolerance = tol)
  expect_equal(sum(c2^2), 1, tolerance = tol)
  # so the two halves together come to 2, which is what the fixture shows
  expect_true(all(r >= 0), info = "reported positive, unlike UCINET")
})

test_that("a square matrix still goes to the 1-mode suite", {
  res <- xcentrality(campnet)
  expect_false(inherits(res, "x2modecentrality"))
  expect_true("OutDegree" %in% names(res$nodes))
})

test_that("the report says which margin and what was binarized", {
  out <- capture.output(print(xcentrality(davis)))
  expect_true(any(grepl("2-Mode Centrality Measures for ROWS", out)))
  expect_true(any(grepl("binarized data", out)))
  expect_true(any(grepl("Eigenvector scores are reported positive", out)))
})
