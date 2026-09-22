# Aggregate a network by a partition (chapter 5, section 5.5.8).
#
# Four nodes in two groups, with self-ties set to 9 so that the diagonal rule
# is visible in every statistic.

tol <- 1e-6

blocks4 <- function() {
  m <- matrix(c(0, 1, 1, 0,
                1, 0, 0, 1,
                1, 0, 0, 1,
                0, 1, 1, 0), 4, 4, byrow = TRUE,
              dimnames = list(letters[1:4], letters[1:4]))
  diag(m) <- 9
  m
}

two <- function() c(a = 1, b = 1, c = 2, d = 2)

agg <- function(method, ...) {
  as.matrix(xcombinenodes(blocks4(), two(), method = method, ...))
}

test_that("each statistic summarises the cells of its block", {
  # Block (1,1) off the diagonal is just (a,b) = 1 and (b,a) = 1.
  # Block (1,2) is (a,c) = 1, (a,d) = 0, (b,c) = 0, (b,d) = 1.
  expect_equal(agg("mean")["1", "1"], 1)
  expect_equal(agg("mean")["1", "2"], 0.5)
  expect_equal(agg("sum")["1", "2"], 2)
  expect_equal(agg("count")["1", "2"], 2)
  expect_equal(agg("max")["1", "2"], 1)
  expect_equal(agg("min")["1", "2"], 0)
  expect_equal(agg("sd")["1", "2"], 0.5)
})

test_that("mean is the default, and is what UCINET calls the density", {
  expect_equal(agg("mean"), as.matrix(xcombinenodes(blocks4(), two())))
})

test_that("sd is the population form", {
  # tunivariate computes variance as mcssq/sumwt.
  cells <- c(1, 0, 0, 1)
  expect_equal(agg("sd")["1", "2"], sqrt(mean((cells - mean(cells))^2)))
})

test_that("self-ties are left out by default and pulled in by diagonal", {
  # The test in aggbygroups is `(i <> j) or diagok`, so it is the matrix
  # diagonal that goes, not the block diagonal.
  expect_equal(agg("max")["1", "1"], 1)
  expect_equal(agg("max", diagonal = TRUE)["1", "1"], 9)
  # the off-diagonal block is unaffected either way
  expect_equal(agg("max")["1", "2"], agg("max", diagonal = TRUE)["1", "2"])
})

test_that("within-group cells other than self-ties survive", {
  # Block (1,1) keeps (a,b) and (b,a); only (a,a) and (b,b) go.
  expect_equal(agg("count")["1", "1"], 2)
})

test_that("a group pair with nothing usable comes back missing", {
  g <- two()
  g[["d"]] <- NA                 # group 2 is now just c, whose only cell is a self-tie
  out <- as.matrix(xcombinenodes(blocks4(), g, method = "count"))
  expect_true(is.na(out["2", "2"]))
  expect_equal(out["1", "2"], 1)
})

test_that("missing cells take no part in the summary", {
  m <- blocks4()
  m["a", "c"] <- NA
  out <- as.matrix(xcombinenodes(m, two(), method = "count"))
  expect_equal(out["1", "2"], 1)    # only (b,d) is left above zero
})

test_that("groups are labelled by the attribute's values", {
  g <- c(a = "men", b = "men", c = "women", d = "women")
  out <- as.matrix(xcombinenodes(blocks4(), g))
  expect_equal(rownames(out), c("men", "women"))
  expect_equal(colnames(out), c("men", "women"))
})

test_that("the result is one row and column per group", {
  gender <- camp92_attr$Gender
  names(gender) <- rownames(camp92_attr)
  out <- xcombinenodes(campnet, gender)
  expect_equal(dim(as.matrix(out)), c(2, 2))
  expect_s3_class(out, "xucinet")
})

test_that("an attribute can be named as a column", {
  f <- system.file("schema", "campnet-example.uci", package = "xucinet")
  net <- xreaduci(f)
  out <- xcombinenodes(net, "Gender")
  expect_equal(dim(as.matrix(out)), c(2, 2))
})

test_that("a partition of the wrong length is an error that counts both", {
  expect_error(xcombinenodes(blocks4(), c(1, 2)), "4 nodes")
})

test_that("every relation of a stack is aggregated", {
  g <- rep(c(1, 2), length.out = 21)
  names(g) <- rownames(as.matrix(hightech))
  out <- xcombinenodes(hightech, g)
  expect_equal(xrelations(out), xrelations(hightech))
  expect_equal(dim(as.matrix(out, relation = "Advice")), c(2, 2))
})

test_that("xcombinenodes names the dataset as the dialog does", {
  expect_equal(xcombinenodes(campnet, rep(1, 18))$title, "campnet-blk")
})

test_that("the history says what it aggregated by", {
  gender <- camp92_attr$Gender
  names(gender) <- rownames(camp92_attr)
  expect_match(attr(xcombinenodes(campnet, gender), "history"), "2 groups")
})

test_that("2-mode data is refused, since it needs two partitions", {
  expect_error(xcombinenodes(davis, rep(1, 18)), "2-mode")
})

# ---- goldens (skip until the sweep runs) ------------------------------------

test_that("collapsing by an attribute matches UCINET", {
  skip_if_no_golden("g5_coll_campnet_sum", "transform")
  skip_if_no_golden("g5_coll_campnet_den", "transform")
  gender <- camp92_attr$Gender
  names(gender) <- rownames(camp92_attr)
  expect_equal(unname(as.matrix(xcombinenodes(campnet, gender, method = "sum"))),
               unname(golden_matrix("g5_coll_campnet_sum", "transform")),
               tolerance = tol)
  # UCINET's "density" is the mean of the cells.
  expect_equal(unname(as.matrix(xcombinenodes(campnet, gender, method = "mean"))),
               unname(golden_matrix("g5_coll_campnet_den", "transform")),
               tolerance = tol)
})
