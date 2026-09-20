# The chapter 6 comparison helpers on synthetic data, so a failing routine test
# is a failing routine and not a failing helper.

test_that("a rotated, reflected, translated and scaled copy is Procrustes-equal", {
  set.seed(1)
  a <- matrix(rnorm(40), 20, 2)
  th <- 0.7
  rot <- matrix(c(cos(th), sin(th), -sin(th), cos(th)), 2, 2)
  b <- 3 * (a %*% rot) %*% diag(c(1, -1)) + matrix(c(5, -2), 20, 2, byrow = TRUE)
  expect_lt(procrustes_rss(a, b), 1e-12)
  expect_procrustes_equal(a, b, tolerance = 1e-10)
  # A different configuration is not.
  expect_gt(procrustes_rss(a, matrix(rnorm(40), 20, 2)), 0.05)
})

test_that("a column-sign-flipped score matrix compares equal, a shuffled one does not", {
  set.seed(2)
  a <- matrix(rnorm(30), 10, 3)
  b <- a %*% diag(c(1, -1, 1))
  expect_equal_up_to_sign(a, b)
  expect_failure(expect_equal_up_to_sign(a, a[sample(10), ]))
})

test_that("partitions compare as set partitions", {
  expect_same_partition(c(1, 1, 2, 2, 3), c(3, 3, 1, 1, 2))
  expect_failure(expect_same_partition(c(1, 1, 2, 2, 3), c(1, 2, 2, 2, 3)))
})
