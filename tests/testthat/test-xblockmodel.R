# Blockmodel of a given partition (chapter 12, section 12.4).

tol <- 1e-8
gender <- function() camp92_attr$Gender

test_that("block densities are the means of the blocks, by hand", {
  m <- as.matrix(campnet)
  g <- gender()
  res <- xblockmodel(campnet, g)
  agg <- res$matrices[["Aggregated matrix"]]
  for (a in 1:2) for (b in 1:2) {
    cells <- m[g == a, g == b, drop = FALSE]
    if (a == b) cells <- cells[row(cells) != col(cells)]
    expect_equal(agg[a, b], mean(cells), tolerance = tol, info = paste(a, b))
  }
})

test_that("the image marks blocks at or above the density", {
  res <- xblockmodel(campnet, gender())
  d <- sum(as.matrix(campnet)) / (18 * 17)
  expect_equal(res$summary$Cutoff, d)
  expect_equal(unname(res$matrices$Image), unname((res$matrices[[1]] >= d) * 1))
  high <- xblockmodel(campnet, gender(), cutoff = 0.3)$matrices$Image
  expect_equal(unname(high), matrix(c(1, 0, 0, 0), 2))
})

test_that("the autocorrelation correlates each cell with its block value", {
  m <- as.matrix(campnet)
  g <- gender()
  res <- xblockmodel(campnet, g)
  agg <- res$matrices[[1]]
  off <- row(m) != col(m)
  expect_equal(res$summary$Autocorrelation,
               cor(agg[cbind(g[row(m)], g[col(m)])][off], m[off]),
               tolerance = tol)
})

test_that("a result with a Cluster column can be the partition", {
  se <- xstructuralequivalence(campnet, k = 3)
  a <- xblockmodel(campnet, se)
  b <- xblockmodel(campnet, se$nodes$Cluster)
  expect_equal(a$matrices, b$matrices)
  expect_error(xblockmodel(campnet, xstructuralequivalence(campnet)), "Cluster")
})

test_that("the method changes the summary, the diagonal is optional", {
  m <- matrix(c(2, 1, 0,
                3, 5, 0,
                0, 4, 1), 3, 3, byrow = TRUE,
              dimnames = list(letters[1:3], letters[1:3]))
  g <- c(1, 1, 2)
  expect_equal(xblockmodel(m, g, method = "sum")$matrices[[1]][1, 1], 4)
  expect_equal(xblockmodel(m, g, method = "sum", diagonal = TRUE)$matrices[[1]][1, 1], 11)
  expect_equal(xblockmodel(m, g, method = "count")$matrices[[1]][2, 1], 1)
  expect_equal(xblockmodel(m, g, method = "maximum")$matrices[[1]][1, 1], 3)
  # a one-node block has no off-diagonal cells
  expect_true(is.na(xblockmodel(m, g)$matrices[[1]][2, 2]))
})

test_that("every relation is blocked", {
  res <- xblockmodel(sampson, rep(1:2, 9), relations = c("Esteem", "Disesteem"))
  expect_true(all(c("Aggregated matrix (Esteem)", "Image (Disesteem)") %in%
                    names(res$matrices)))
  expect_true("Autocorrelation (Disesteem)" %in% names(res$summary))
})

test_that("a partition of the wrong length is refused", {
  expect_error(xblockmodel(campnet, 1:3), "3 values")
})

test_that("the blocked matrix puts each group together", {
  lines <- format_blocked_matrix(as.matrix(campnet), gender())
  rows <- grep("\\|", lines, value = TRUE)
  expect_length(rows, 18)
  # the first rows are the women, the rule sits between the groups
  expect_match(rows[1], "HOLLY")
  expect_true(any(grepl("^ +-+$", lines)))
})

test_that("the report prints", {
  expect_snapshot(xblockmodel(campnet, camp92_attr$Gender))
})

test_that("campnet by gender matches UCINET", {
  skip_if_no_golden("g12_block_campnet", "equivalence")
  g <- golden_matrix("g12_block_campnet", "equivalence")
  expect_equal(unname(xblockmodel(campnet, gender())$matrices[[1]]), unname(g),
               tolerance = 1e-4)
})
