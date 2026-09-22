# Geodesic distances (chapter 5, section 5.5.7).
#
# The search itself is already covered by the chapter 9 tests, which lean on
# the same geodesics(); what is tested here is the dialog's behaviour around
# it - the transformation, the unreachable rule, the diagonal, and the
# defaults that move together.

tol <- 1e-6

# Two components of two nodes, so half the pairs are unreachable and the
# longest distance is 1.
split4 <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m[1, 2] <- m[2, 1] <- 1
  m[3, 4] <- m[4, 3] <- 1
  m
}

# A path a - b - c, so there is a distance of 2 to find.
path3 <- function() {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m[1, 2] <- m[2, 1] <- 1
  m[2, 3] <- m[3, 2] <- 1
  m
}

test_that("distances are the number of steps in the shortest path", {
  d <- as.matrix(xgeodesic(path3()))
  expect_equal(d["a", "b"], 1)
  expect_equal(d["a", "c"], 2)
  expect_equal(d["c", "a"], 2)
})

test_that("the defaults are the dialog's, and they move with the transform", {
  # TransformationOptionsClick: no transformation gives missing/0, reciprocal
  # gives zero/missing.
  plain <- as.matrix(xgeodesic(split4()))
  expect_equal(unname(diag(plain)), c(0, 0, 0, 0))
  expect_true(is.na(plain["a", "c"]))

  recip <- as.matrix(xgeodesic(split4(), reciprocal = TRUE))
  expect_true(all(is.na(diag(recip))))
  expect_equal(recip["a", "c"], 0)
})

test_that("each unreachable rule fills as cleanup0 does", {
  m <- split4()
  expect_true(is.na(as.matrix(xgeodesic(m, unreachable = "missing"))["a", "c"]))
  # N, the number of nodes
  expect_equal(as.matrix(xgeodesic(m, unreachable = "n"))["a", "c"], 4)
  # the longest distance found is 1, so max + 1 is 2
  expect_equal(as.matrix(xgeodesic(m, unreachable = "max+1"))["a", "c"], 2)
})

test_that("the reciprocal rules are the same three inverted, plus zero", {
  m <- split4()
  expect_true(is.na(as.matrix(
    xgeodesic(m, reciprocal = TRUE, unreachable = "missing"))["a", "c"]))
  expect_equal(as.matrix(
    xgeodesic(m, reciprocal = TRUE, unreachable = "n"))["a", "c"], 1 / 4)
  expect_equal(as.matrix(
    xgeodesic(m, reciprocal = TRUE, unreachable = "max+1"))["a", "c"], 1 / 2)
  expect_equal(as.matrix(
    xgeodesic(m, reciprocal = TRUE, unreachable = "zero"))["a", "c"], 0)
})

test_that("reciprocal distances are one over the distance", {
  r <- as.matrix(xgeodesic(path3(), reciprocal = TRUE))
  expect_equal(r["a", "b"], 1)
  expect_equal(r["a", "c"], 1 / 2)
})

test_that("zero is refused without the transformation", {
  # It is not one of UCINET's three, and it would read as "closest possible".
  expect_error(xgeodesic(split4(), unreachable = "zero"), "reciprocal")
})

test_that("the diagonal takes the three values the dialog offers", {
  m <- path3()
  expect_equal(unname(diag(as.matrix(xgeodesic(m, diagonal = 0)))), c(0, 0, 0))
  expect_equal(unname(diag(as.matrix(xgeodesic(m, diagonal = 1)))), c(1, 1, 1))
  expect_true(all(is.na(diag(as.matrix(xgeodesic(m, diagonal = NA))))))
  expect_error(xgeodesic(m, diagonal = 7), "0, 1 or NA")
})

test_that("valued data are dichotomized first, and the history says so", {
  # The dialog's only "type of input data" item is a non-valued adjacency
  # matrix.
  v <- path3()
  v[1, 2] <- v[2, 1] <- 5
  expect_equal(as.matrix(xgeodesic(v))["a", "b"], 1)
  expect_match(attr(xgeodesic(v), "history"), "dichotomized")
})

test_that("an undirected network is symmetrized with the maximum", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m[1, 2] <- 1                       # one direction only
  m[2, 3] <- 1
  out <- as.matrix(xgeodesic(m, directed = FALSE))
  expect_equal(out["b", "a"], 1)     # reachable both ways now
  expect_equal(out["c", "a"], 2)
  expect_match(attr(xgeodesic(m, directed = FALSE), "history"), "undirected")
})

test_that("a directed network keeps its asymmetry", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m[1, 2] <- 1
  m[2, 3] <- 1
  out <- as.matrix(xgeodesic(m, directed = TRUE))
  expect_equal(out["a", "c"], 2)
  expect_true(is.na(out["c", "a"]))
})

test_that("the history carries the figures the log prints", {
  h <- attr(xgeodesic(campnet), "history")
  expect_match(h, "average")
  expect_match(h, "sd")
  expect_match(h, "distances")
  expect_match(h, "unreachable")
})

test_that("the statistics ignore the diagonal", {
  # setdiagonalvalues writes the diagonal after the distances are counted, so
  # the zeros on it are not part of the average.
  h <- attr(xgeodesic(path3()), "history")
  # distances are 1, 1, 2 and their mirrors: mean 4/3
  expect_match(h, "average 1.3333")
})

test_that("xgeodesic names the dataset as the dialog does", {
  expect_equal(xgeodesic(campnet)$title, "campnet-geo")
})

test_that("xgeodesic refuses 2-mode data", {
  expect_error(xgeodesic(davis), "1-mode")
})

test_that("every relation of a stack gets its own distances", {
  out <- xgeodesic(hightech)
  expect_equal(xrelations(out), xrelations(hightech))
  expect_equal(unname(diag(as.matrix(out, relation = "Advice"))), rep(0, 21))
})

test_that("cross-check: the same distances igraph finds", {
  skip_if_not_installed("igraph")
  m <- as.matrix(campnet)
  g <- igraph::graph_from_adjacency_matrix((m > 0) * 1, mode = "directed")
  theirs <- igraph::distances(g, mode = "out")
  theirs[is.infinite(theirs)] <- NA
  ours <- as.matrix(xgeodesic(campnet, directed = TRUE))
  expect_equal(unname(ours), unname(theirs), tolerance = tol)
})

test_that("cross-check: reciprocal distances against sna", {
  skip_if_not_installed("sna")
  m <- as.matrix(campnet)
  theirs <- sna::geodist((m > 0) * 1, inf.replace = Inf)$gdist
  theirs[is.infinite(theirs)] <- NA
  ours <- as.matrix(xgeodesic(campnet, directed = TRUE))
  expect_equal(unname(ours), unname(theirs), tolerance = tol)
})

# ---- goldens (skip until the sweep runs) ------------------------------------

test_that("geodesic distances match UCINET", {
  skip_if_no_golden("g5_geo_campnet", "transform")
  expect_equal(unname(as.matrix(xgeodesic(campnet))),
               unname(golden_matrix("g5_geo_campnet", "transform")),
               tolerance = tol)
})

test_that("UCINET's stored value for an unreachable pair is what we default to", {
  # The one fixture whose value matters as much as its numbers: the dialog
  # lets the user store something else, and this settles which it is.
  skip_if_no_golden("g5_geo_disc", "transform")
  gold <- golden_matrix("g5_geo_disc", "transform")
  ours <- as.matrix(xgeodesic(xread("g9_disc")))
  expect_equal(unname(ours), unname(gold), tolerance = tol)
})
