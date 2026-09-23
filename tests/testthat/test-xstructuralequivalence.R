# Profile structural equivalence (chapter 12, sections 12.2-12.3).

tol <- 1e-8

# a and b are structurally equivalent: both send to c and d and receive from
# e. They are not tied to each other.
equiv <- function() {
  m <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  m[c("a", "b"), c("c", "d")] <- 1
  m["e", c("a", "b")] <- 1
  m
}

# ---- layer (a): hand-computed ------------------------------------------------

test_that("structurally equivalent nodes are at distance 0 and correlate 1", {
  expect_equal(xstructuralequivalence(equiv())$matrices[[1]]["a", "b"], 0)
  expect_equal(xstructuralequivalence(equiv(), method = "correlation")$matrices[[1]]["a", "b"], 1)
})

test_that("reciprocal swapping makes a mutual pair equivalent", {
  # a <-> b and nothing else: a's tie to b is compared with b's tie to a.
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["b", "a"] <- 1
  expect_equal(xstructuralequivalence(m)$matrices[[1]]["a", "b"], 0)
  # retained as they stand, a's row (0,1,0) and b's (1,0,0) differ in two
  # cells, and so do their columns
  expect_equal(xstructuralequivalence(m, diagonal = "retain")$matrices[[1]]["a", "b"],
               sqrt(2))
  expect_equal(xstructuralequivalence(m, diagonal = "retain2")$matrices[[1]]["a", "b"],
               sqrt(4))
})

test_that("the profile has the cells sesim2 builds", {
  m <- matrix(1:16, 4, 4)
  diag(m) <- 0
  len <- function(b, tr) length(se_profiles(list(m), 1, 2, b, tr)$x)
  expect_equal(len("ignore", TRUE), 2 * 2)          # the other two, both halves
  expect_equal(len("retain", TRUE), 4 + 2)          # whole row, column without i, j
  expect_equal(len("retain2", TRUE), 4 + 4)
  expect_equal(len("reciprocal", TRUE), 4 + 2)
  expect_equal(len("reciprocal2", TRUE), 4 + 4)
  expect_equal(len("reciprocal", FALSE), 4)
  # reciprocal: cell j of i's row is i -> j, set against j -> i
  p <- se_profiles(list(m), 1, 2, "reciprocal", FALSE)
  expect_equal(p$x[2], m[1, 2])
  expect_equal(p$y[2], m[2, 1])
})

test_that("relations are stacked into one profile", {
  a <- equiv(); b <- t(equiv())
  both <- xstructuralequivalence(list(r1 = a, r2 = b), transpose = FALSE)$matrices[[1]]
  one <- xstructuralequivalence(a, transpose = FALSE)$matrices[[1]]
  two <- xstructuralequivalence(b, transpose = FALSE)$matrices[[1]]
  expect_equal(both^2, one^2 + two^2, tolerance = tol)
})

test_that("euclidean distance is rescaled for missing cells, as ug2sim does", {
  x <- c(1, 0, NA, 1); y <- c(0, 0, 1, 1)
  expect_equal(se_pair(x, y, "euclidean"), 4 * 1 / 3)
})

test_that("a constant profile correlates 0, two constant profiles 1", {
  expect_equal(se_pair(c(1, 1, 1), c(0, 1, 0), "correlation"), 0)
  expect_equal(se_pair(c(1, 1, 1), c(0, 0, 0), "correlation"), 1)
})

test_that("coverage is asymmetric and is not clustered", {
  r <- xstructuralequivalence(campnet, method = "coverage")
  expect_null(r$nodes)
  expect_null(r$hclust)
  expect_false(isSymmetric(unname(r$matrices[[1]])))
})

test_that("the clustering is xhclust's weighted average, UCINET's WTD_AVERAGE", {
  r <- xstructuralequivalence(campnet, k = 3)
  h <- xhclust(r$matrices[[1]], type = "dissimilarities", method = "average",
               k = 3, plot = FALSE)
  expect_equal(r$nodes$Cluster, h$nodes$Cluster)
  s <- xstructuralequivalence(campnet, method = "correlation")
  expect_equal(s$hclust$merge,
               xhclust(s$matrices[[1]], type = "similarities", plot = FALSE)$hclust$merge)
})

test_that("geodesics replace the adjacency matrix, unreachable pairs at n", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["b", "c"] <- 1
  g <- se_floyd(m)
  expect_equal(g["a", "c"], 2)
  expect_equal(g["c", "a"], 3)
})

test_that("2-mode data are refused", {
  expect_error(xstructuralequivalence(davis), "1-mode")
})

test_that("the book's Sampson distances come from Reciprocal2", {
  # 12.3, Matrix 12.3: four pairs at 5.1 and Peter-Mark at 13.4. UCINET's
  # current default, Reciprocal1, gives 4.69 to 5.10 and 13.23 (text-changes).
  m <- xstructuralequivalence(sampson, relations = c("Esteem", "Disesteem"),
                              diagonal = "reciprocal2")$matrices[[1]]
  for (p in list(c("BONAVENTURE", "AMBROSE"), c("ALBERT", "BONIFACE"),
                 c("ROMUALD", "WINFRID"), c("ELIAS", "SIMPLICIUS"))) {
    expect_equal(round(m[p[1], p[2]], 1), 5.1, info = paste(p, collapse = "-"))
  }
  expect_equal(round(m["PETER", "MARK"], 1), 13.4)
})

test_that("the report prints", {
  expect_snapshot(xstructuralequivalence(campnet))
})

# ---- layer (b): cross-check ---------------------------------------------------

test_that("with the diagonal ignored, correlation is Pearson's r of the trimmed profiles", {
  # Ignore leaves out the cells for the pair, in both halves; nothing else is
  # special, so base cor() on the rebuilt profiles must agree.
  m <- as.matrix(campnet)
  r <- xstructuralequivalence(campnet, method = "correlation",
                              diagonal = "ignore")$matrices[[1]]
  i <- 1; j <- 2; k <- setdiff(seq_len(nrow(m)), c(i, j))
  expect_equal(r[i, j], cor(c(m[i, k], m[k, i]), c(m[j, k], m[k, j])),
               tolerance = tol)
})

# ---- layer (c): goldens ---------------------------------------------------------

test_that("campnet profile similarity matches UCINET", {
  skip_if_no_golden("g12_se_campnet_euc", "equivalence")
  skip_if_no_golden("g12_se_campnet_cor", "equivalence")
  expect_equal(unname(xstructuralequivalence(campnet)$matrices[[1]]),
               unname(golden_matrix("g12_se_campnet_euc", "equivalence")),
               tolerance = 1e-4)
  expect_equal(unname(xstructuralequivalence(campnet, method = "correlation")$matrices[[1]]),
               unname(golden_matrix("g12_se_campnet_cor", "equivalence")),
               tolerance = 1e-4)
})

test_that("sampson esteem and disesteem match UCINET", {
  skip_if_no_golden("g12_se_sampson", "equivalence")
  r <- xstructuralequivalence(sampson, relations = c("Esteem", "Disesteem"))
  expect_equal(unname(r$matrices[[1]]),
               unname(golden_matrix("g12_se_sampson", "equivalence")),
               tolerance = 1e-4)
})

test_that("hightech advice, directed, matches UCINET", {
  skip_if_no_golden("g12_se_hightech", "equivalence")
  r <- xstructuralequivalence(hightech, relations = "Advice")
  expect_equal(unname(r$matrices[[1]]),
               unname(golden_matrix("g12_se_hightech", "equivalence")),
               tolerance = 1e-4)
})
