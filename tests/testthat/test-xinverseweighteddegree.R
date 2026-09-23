# Inverse-weighted degree (Network | Centrality | Inverse-Weighted Degree;
# chapter 9, not in the book text). UCINET issue 28, ledger entry 33.

test_that("the scores are what they say, by hand", {
  # a -> b, a -> c, b -> c: indegrees b 1, c 2; outdegrees a 2, b 1.
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["a", "c"] <- m["b", "c"] <- 1
  nd <- xinverseweighteddegree(m)$nodes
  expect_equal(names(nd), c("OutIWD", "InIWD", "nOutIWD", "nInIWD"))
  expect_equal(nd$OutIWD, c(1 / 1 + 1 / 2, 1 / 2, 0))
  expect_equal(nd$InIWD, c(0, 1 / 2, 1 / 2 + 1))
  expect_equal(nd$nOutIWD, nd$OutIWD / 2)
})

test_that("in-IWD is the column sums of the row-stochastic matrix", {
  m <- as.matrix(campnet)
  diag(m) <- 0
  expect_equal(xinverseweighteddegree(campnet)$nodes$InIWD,
               unname(colSums(m / rowSums(m))))
})

test_that("symmetric data give one measure", {
  r <- xinverseweighteddegree(xsymmetrize(campnet))
  expect_equal(names(r$nodes), c("IWD", "nIWD"))
})

test_that("normalize chooses what is printed first, not what is returned", {
  a <- xinverseweighteddegree(campnet)
  b <- xinverseweighteddegree(campnet, normalize = FALSE)
  expect_identical(a$nodes, b$nodes)
  expect_equal(a$show_columns[1], "nOutIWD")
  expect_equal(b$show_columns[1], "OutIWD")
})

test_that("the diagonal is excluded and valued data are not scaled", {
  # UCINET issue 28: an unset diagonal flag and a maxval factor.
  m <- matrix(c(5, 2, 0,
                0, 5, 4,
                4, 0, 5), 3, 3, byrow = TRUE,
              dimnames = list(letters[1:3], letters[1:3]))
  nd <- xinverseweighteddegree(m)$nodes
  m0 <- m; diag(m0) <- 0
  expect_equal(nd$OutIWD, unname(rowSums(sweep(m0, 2, colSums(m0), "/"))))
  expect_equal(nd$nOutIWD, nd$OutIWD / 2)
})

test_that("the totals belong to the relation analysed", {
  # UCINET issue 28(2): totals carried from earlier relations.
  second <- xinverseweighteddegree(newguinea, relation = 2)$nodes
  alone <- xinverseweighteddegree(as.matrix(newguinea, relation = 2))$nodes
  expect_equal(second, alone)
})

test_that("campnet matches UCINET, which is right on binary data", {
  skip_if_no_golden("g9_iwd_campnet", "centrality")
  g <- golden_matrix("g9_iwd_campnet", "centrality")
  ours <- xinverseweighteddegree(campnet)$nodes
  expect_equal(unname(as.matrix(ours[c("nOutIWD", "nInIWD")])), unname(g),
               tolerance = 1e-4)
})

test_that("the report prints", {
  expect_snapshot(xinverseweighteddegree(campnet))
})
