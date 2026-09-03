m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3, dimnames = list(c("a","b","c"), c("a","b","c")))

test_that("a symmetric matrix becomes an undirected 1-mode network", {
  net <- as_xucinet(m)
  expect_s3_class(net, "xucinet")
  expect_equal(net$mode, "1-mode")
  expect_false(net$directed)
  expect_equal(dim(net), c(3, 3))
})

test_that("an asymmetric matrix is detected as directed", {
  m2 <- m; m2[2, 1] <- 0
  expect_true(as_xucinet(m2)$directed)
})

test_that("a rectangular matrix is 2-mode", {
  expect_equal(as_xucinet(matrix(1, 3, 5))$mode, "2-mode")
})

test_that("an edge list data frame is detected and built", {
  el <- data.frame(from = c("a","a","b"), to = c("b","c","a"))
  net <- as_xucinet(el)
  expect_equal(sort(rownames(as.matrix(net))), c("a","b","c"))
  expect_equal(as.matrix(net)["a","b"], 1)
  expect_equal(as.matrix(net)["c","a"], 0)
})

test_that("unlabeled matrices get labels", {
  expect_equal(rownames(as.matrix(as_xucinet(matrix(0, 2, 2)))), c("1","2"))
})
