test_that("density of a small undirected graph matches UCINET", {
  m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
  res <- xdensity(m)
  expect_s3_class(res, "xdensity")
  expect_equal(res$summary$Density, 4/6)
  expect_equal(res$summary[["No. of Ties"]], 4)
  expect_output(print(res), "DENSITY")
})

test_that("weighted = FALSE dichotomizes valued data", {
  m <- matrix(c(0,3,0, 2,0,0, 0,0,0), 3, 3)
  expect_equal(xdensity(m, weighted = FALSE)$summary$Density, 2/6)
  expect_equal(xdensity(m)$summary$Density, 5/6)
})
