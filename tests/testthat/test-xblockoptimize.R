# xblockoptimize (issue #24; Steve, 26 Sep 2026: a native port of UCINET's
# structural and regular optimization). Checked against planted structure,
# against its own cost functions written out independently, and, once the
# goldens are run, against UCINET's fit.

two_cliques <- function() {
  m <- matrix(0, 9, 9, dimnames = list(letters[1:9], letters[1:9]))
  m[1:4, 1:4] <- 1; m[5:9, 5:9] <- 1; diag(m) <- 0
  m
}

# Errors of a structural blockmodel, written out: each block pair costs the
# smaller of its ones and its zeros, the diagonal left out.
sbm_errors <- function(m, p) {
  k <- max(p); e <- 0
  for (a in 1:k) for (b in 1:k) {
    cells <- m[p == a, p == b, drop = FALSE]
    if (a == b) cells <- cells[row(cells) != col(cells)]
    e <- e + min(sum(cells > 0), sum(cells == 0))
  }
  e
}

# Errors of a regular blockmodel, written out: in each block pair, the rows
# with a tie into the column block against those without, and likewise the
# columns; the nearer of all-or-none for each.
rbm_errors <- function(m, p) {
  diag(m) <- 0; k <- max(p); e <- 0
  for (a in 1:k) for (b in 1:k) {
    blk <- m[p == a, p == b, drop = FALSE] > 0
    r <- sum(rowSums(blk) > 0); c <- sum(colSums(blk) > 0)
    e <- e + min(r, sum(p == a) - r) + min(c, sum(p == b) - c)
  }
  e
}

test_that("structural: two cliques are found with no errors", {
  r <- xblockoptimize(two_cliques(), k = 2, seed = 1)
  expect_equal(r$summary$Errors, 0)
  expect_equal(length(unique(r$nodes$Block[1:4])), 1)
  expect_equal(length(unique(r$nodes$Block[5:9])), 1)
  expect_false(r$nodes$Block[1] == r$nodes$Block[5])
})

test_that("structural: the errors and R-square are those of the partition", {
  m <- as.matrix(campnet)
  r <- xblockoptimize(campnet, k = 3, seed = 1)
  p <- r$nodes$Block
  expect_equal(r$summary$Errors, sbm_errors(m, p))
  off <- row(m) != col(m)
  dens <- outer(p, p, function(a, b) r$matrices[["Density matrix"]][cbind(a, b)])
  expect_equal(r$summary[["R-square"]], stats::cor(m[off], dens[off])^2)
})

test_that("structural, valued: R-square of the block means, and the best start is kept", {
  s <- as.matrix(zachary, relation = "Strength")
  r <- xblockoptimize(zachary, k = 2, relation = "Strength", seed = 3)
  p <- r$nodes$Block
  off <- row(s) != col(s)
  means <- outer(p, p, function(a, b) r$matrices[["Density matrix"]][cbind(a, b)])
  expect_equal(r$summary[["R-square"]], stats::cor(s[off], means[off])^2)
  expect_true(is.na(r$summary$Errors))
  # UCINET issue 35, item 2: every start's R-square is logged, and the result
  # is the best of them.
  logged <- as.numeric(sub(".*R-square = ", "",
                           grep("R-square = ", r$preamble, value = TRUE)))
  expect_equal(round(r$summary[["R-square"]], 3), max(logged))
})

test_that("regular: a complete bipartite graph splits into its two sides", {
  m <- matrix(0, 7, 7, dimnames = list(letters[1:7], letters[1:7]))
  m[1:3, 4:7] <- 1; m[4:7, 1:3] <- 1
  r <- xblockoptimize(m, k = 2, type = "regular", seed = 2)
  expect_equal(r$summary$Errors, 0)
  expect_equal(length(unique(r$nodes$Block[1:3])), 1)
  expect_equal(length(unique(r$nodes$Block[4:7])), 1)
  expect_false(r$nodes$Block[1] == r$nodes$Block[4])
})

test_that("regular: the errors are those of the partition", {
  r <- xblockoptimize(campnet, k = 3, type = "regular", seed = 1, starts = 5)
  expect_equal(r$summary$Errors, rbm_errors(as.matrix(campnet), r$nodes$Block))
  expect_true(is.na(r$summary[["R-square"]]))
})

test_that("the diagonal counts only when it is valid", {
  # UCINET issue 35, item 4: UCINET's costs ignore "Diagonal valid?".
  m <- two_cliques(); diag(m) <- 1
  p <- rep(1:2, c(4, 5))
  use_off <- row(m) != col(m)
  expect_equal(sbm_hamming(m > 0, use_off, p, 2), 0)
  expect_equal(sbm_hamming(m > 0, matrix(TRUE, 9, 9), p, 2), 0)
  m[1, 1] <- 0     # one self-tie missing inside a full block
  expect_equal(sbm_hamming(m > 0, use_off, p, 2), 0)
  expect_equal(sbm_hamming(m > 0, matrix(TRUE, 9, 9), p, 2), 1)
})

test_that("km1 seeds with the farthest pair and assigns to the nearest seed", {
  d <- as.matrix(stats::dist(c(0, 1, 10, 11, 20)))
  # The farthest pair is nodes 5 and 1 (20 apart): seed 1 is node 5, seed 2
  # node 1. With two seeds, node 3 is 10 from each and the first of equals
  # wins, so it joins seed 1.
  expect_equal(km1_g1(d, 2), c(2L, 2L, 1L, 1L, 1L))
  # The third seed is the node farthest from any single seed: node 2, 19 from
  # node 5. Node 3 is then 9 from it (nearest), node 4 is 9 from node 5.
  expect_equal(km1_g1(d, 3), c(2L, 3L, 3L, 1L, 1L))
})

test_that("the tabu search returns its best partition and never loses ground", {
  m <- as.matrix(campnet); use <- row(m) != col(m)
  cost <- function(p) sbm_hamming(m > 0, use, p, 3)
  start <- rep(1:3, length.out = 18)
  res <- tabus_g1(start, 3L, 20L, 5L, cost)
  expect_equal(res$cost, cost(res$p))
  expect_lte(res$cost, cost(start))
  expect_true(all(tabulate(res$p, 3) > 0))
})

test_that("the seed reproduces the run, and bad input is refused", {
  expect_identical(xblockoptimize(campnet, k = 3, seed = 9)$nodes,
                   xblockoptimize(campnet, k = 3, seed = 9)$nodes)
  r <- xblockoptimize(campnet, k = 2, starts = 2)
  expect_match(r$fields[["Random # seed:"]], "^[0-9]+$")
  expect_error(xblockoptimize(campnet, k = 1), "at least 2")
  expect_error(xblockoptimize(davis, k = 2), "1-mode")
})

test_that("the 1e names reach it", {
  expect_message(xBlockOptimize(campnet, k = 2, seed = 1, starts = 2), "xblockoptimize")
})

test_that("structural optimization reaches UCINET's fit", {
  # With the same seed UCINET's search is the same except where issue 35
  # changes it, so the fit is compared rather than the partition.
  skip_if_no_golden("g12_sbm_campnet", "equivalence")
  g <- golden_matrix("g12_sbm_campnet", "equivalence")[, 1]
  r <- xblockoptimize(campnet, k = 3, seed = 1)
  expect_lte(r$summary$Errors, sbm_errors(as.matrix(campnet), g))
})

test_that("regular optimization reaches UCINET's fit", {
  skip_if_no_golden("g12_rbm_campnet", "equivalence")
  g <- golden_matrix("g12_rbm_campnet", "equivalence")[, 1]
  r <- xblockoptimize(campnet, k = 2, type = "regular", seed = 1)
  expect_lte(r$summary$Errors, rbm_errors(as.matrix(campnet), g))
})

test_that("the reports print", {
  expect_snapshot(xblockoptimize(campnet, k = 3, seed = 1))
  expect_snapshot(xblockoptimize(campnet, k = 2, type = "regular", seed = 1, starts = 5))
})
