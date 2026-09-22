# Lining datasets up on one node set (chapter 5, section 5.4.4).
#
# One function for UCINET's two match routines, since R dispatches on class.

# Overlapping but not identical node sets: a has x y z, b has y z w.
netA <- function() matrix(1, 3, 3, dimnames = list(c("x","y","z"), c("x","y","z")))
netB <- function() matrix(2, 3, 3, dimnames = list(c("y","z","w"), c("y","z","w")))
attrD <- function() data.frame(g = c(10, 20, 30), row.names = c("y", "z", "w"))

test_that("nodes = first keeps the first dataset's node set and order", {
  m <- suppressMessages(xmatch(netA(), netB()))
  expect_equal(rownames(as.matrix(m[[1]])), c("x", "y", "z"))
  expect_equal(rownames(as.matrix(m[[2]])), c("x", "y", "z"))
})

test_that("nodes = last, intersection and union pick the other three sets", {
  expect_equal(rownames(as.matrix(
    suppressMessages(xmatch(netA(), netB(), nodes = "last"))[[1]])),
    c("y", "z", "w"))
  expect_equal(rownames(as.matrix(
    suppressMessages(xmatch(netA(), netB(), nodes = "intersection"))[[1]])),
    c("y", "z"))
  # union is ordered by first appearance
  expect_equal(rownames(as.matrix(
    suppressMessages(xmatch(netA(), netB(), nodes = "union"))[[1]])),
    c("x", "y", "z", "w"))
})

test_that("a node the network did not have is filled with zero", {
  # tmat.allocsize calls allocate(..., zfill = true), which zerofills. That
  # is what UCINET's match routines leave in the absent cells.
  m <- suppressMessages(xmatch(netA(), netB(), nodes = "union"))
  out <- as.matrix(m[[1]])
  expect_equal(unname(out["w", ]), c(0, 0, 0, 0))
  expect_equal(unname(out[, "w"]), c(0, 0, 0, 0))
  expect_equal(out["x", "y"], 1)            # what was there is untouched
})

test_that("fill = NA gives Time Stack's behaviour instead", {
  m <- suppressMessages(xmatch(netA(), netB(), nodes = "union", fill = NA))
  expect_true(all(is.na(as.matrix(m[[1]])["w", ])))
})

test_that("an absent attribute row is NA, not the fill", {
  # An unobserved tie is reasonably zero; an unobserved attribute is not.
  m <- suppressMessages(xmatch(netA(), attrD(), nodes = "union"))
  expect_true(is.na(m[[2]]["x", "g"]))
  expect_equal(m[[2]]["y", "g"], 10)
})

test_that("sort reorders the node set", {
  u <- function(s) rownames(as.matrix(
    suppressMessages(xmatch(netA(), netB(), nodes = "union", sort = s))[[1]]))
  expect_equal(u("first"), c("x", "y", "z", "w"))
  expect_equal(u("alphabetical"), c("w", "x", "y", "z"))
})

test_that("numerical sort orders numeric labels as numbers", {
  a <- matrix(1, 3, 3, dimnames = list(c("10","9","2"), c("10","9","2")))
  b <- matrix(1, 1, 1, dimnames = list("1", "1"))
  got <- rownames(as.matrix(suppressMessages(
    xmatch(a, b, nodes = "union", sort = "numerical"))[[1]]))
  expect_equal(got, c("1", "2", "9", "10"))
})

test_that("labels are matched exactly, including case", {
  a <- matrix(1, 2, 2, dimnames = list(c("Bob","Ann"), c("Bob","Ann")))
  b <- matrix(1, 2, 2, dimnames = list(c("bob","ann"), c("bob","ann")))
  expect_error(suppressMessages(xmatch(a, b, nodes = "intersection")),
               "no nodes are left")
})

test_that("a data frame can be matched on a column instead of its rownames", {
  d <- data.frame(id = c("y", "z"), g = c(1, 2))
  m <- suppressMessages(xmatch(netA(), d, by = "id", nodes = "intersection"))
  expect_equal(rownames(m[[2]]), c("y", "z"))
  expect_error(suppressMessages(xmatch(netA(), d, by = "nope")), "no column")
})

test_that("the result is named from the arguments, or from the titles", {
  m <- suppressMessages(xmatch(early = netA(), late = netB()))
  expect_equal(names(m), c("early", "late"))
  m2 <- suppressMessages(xmatch(campnet, netB(), nodes = "first"))
  expect_equal(names(m2)[1], "campnet")
})

test_that("a message says what was dropped and added, per dataset", {
  expect_message(xmatch(netA(), netB(), nodes = "union"), "1 added")
  expect_message(xmatch(netA(), netB(), nodes = "intersection"), "dropped")
})

test_that("networks keep their class, mode and relation stack", {
  m <- suppressMessages(xmatch(hightech, netB(), nodes = "first"))
  expect_s3_class(m[[1]], "xucinet")
  expect_equal(xrelations(m[[1]]), xrelations(hightech))
  expect_equal(m[[1]]$mode, "1-mode")
})

test_that("data frames stay data frames", {
  m <- suppressMessages(xmatch(netA(), attrD()))
  expect_s3_class(m[[2]], "data.frame")
})

test_that("attach returns the network carrying the attributes", {
  n <- suppressMessages(xmatch(netA(), attrD(), attach = TRUE))
  expect_s3_class(n, "xucinet")
  expect_equal(rownames(xattributes(n)), c("x", "y", "z"))
  expect_equal(xattributes(n)["y", "g"], 10)
})

test_that("attach needs exactly one network and one table", {
  expect_error(suppressMessages(xmatch(netA(), netB(), attach = TRUE)),
               "one network and one attribute table")
})

test_that("more than two datasets line up at once", {
  # The three-time-point case question 5.8 was revised for.
  # b is in all three; each wave also has someone the others lack.
  t1 <- matrix(1, 2, 2, dimnames = list(c("a","b"), c("a","b")))
  t2 <- matrix(1, 2, 2, dimnames = list(c("b","c"), c("b","c")))
  t3 <- matrix(1, 2, 2, dimnames = list(c("b","d"), c("b","d")))
  m <- suppressMessages(xmatch(t1, t2, t3, nodes = "union"))
  expect_length(m, 3)
  for (x in m) expect_equal(rownames(as.matrix(x)), c("a", "b", "c", "d"))
  keepers <- suppressMessages(xmatch(t1, t2, t3, nodes = "intersection"))
  expect_length(keepers, 3)
  expect_equal(rownames(as.matrix(keepers[[1]])), "b")
})

test_that("an intersection that is empty is an error, not an empty dataset", {
  # Three waves with no one in all of them.
  t1 <- matrix(1, 2, 2, dimnames = list(c("a","b"), c("a","b")))
  t2 <- matrix(1, 2, 2, dimnames = list(c("b","c"), c("b","c")))
  t3 <- matrix(1, 2, 2, dimnames = list(c("c","d"), c("c","d")))
  expect_error(suppressMessages(xmatch(t1, t2, t3, nodes = "intersection")),
               "no nodes are left")
})

test_that("one dataset is not a match", {
  expect_error(xmatch(netA()), "two or more")
})
