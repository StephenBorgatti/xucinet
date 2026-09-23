# Egonet tie composition, binary and valued (chapter 8, sections 8.2 and 8.3).

tol <- 1e-8

# Two relations on three nodes. Friend: a <-> b. Advice: a -> c.
two_rel <- function() {
  f <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  f["a", "b"] <- f["b", "a"] <- 1
  adv <- f * 0
  adv["a", "c"] <- 1
  as_xucinet(list(Friend = f, Advice = adv))
}

# a -> b 3, a -> c 5, c -> a 2
valued <- function() {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- 3
  m["a", "c"] <- 5
  m["c", "a"] <- 2
  m
}

# ---- xtiecomposition: hand-computed -------------------------------------------

test_that("columns are Ties, a count and a proportion per relation, Blau, IQV", {
  expect_equal(names(xtiecomposition(two_rel())$nodes),
               c("Ties", "fFriend", "fAdvice", "pFriend", "pAdvice", "Blau", "IQV"))
})

test_that("undirected counts a tie either way once", {
  nd <- xtiecomposition(two_rel())$nodes
  expect_equal(unlist(nd["a", ]),
               c(Ties = 2, fFriend = 1, fAdvice = 1, pFriend = 0.5, pAdvice = 0.5,
                 Blau = 0.5, IQV = 1))
  expect_equal(nd["b", "Blau"], 0)
  expect_equal(nd["c", "fAdvice"], 1)            # c receives the advice tie
})

test_that("both counts a reciprocated tie twice", {
  nd <- xtiecomposition(two_rel(), direction = "both")$nodes
  expect_equal(nd["a", "fFriend"], 2)
  expect_equal(nd["a", "Ties"], 3)
})

test_that("out, in and reciprocated", {
  expect_equal(xtiecomposition(two_rel(), direction = "out")$nodes["c", "Ties"], 0)
  expect_equal(xtiecomposition(two_rel(), direction = "in")$nodes["c", "Ties"], 1)
  nd <- xtiecomposition(two_rel(), direction = "reciprocated")$nodes
  expect_equal(nd["a", "Ties"], 1)
  expect_equal(nd["a", "fAdvice"], 0)
})

test_that("an ego with no ties has missing proportions and heterogeneity", {
  nd <- xtiecomposition(two_rel(), direction = "out")$nodes
  expect_equal(nd["c", "fFriend"], 0)
  expect_true(all(is.na(unlist(nd["c", c("pFriend", "pAdvice", "Blau", "IQV")]))))
})

test_that("a zero is never a tie, whatever the test", {
  nd <- xtiecomposition(two_rel(), op = "<=", cutoff = 5)$nodes
  expect_equal(nd["a", "Ties"], 2)
})

test_that("the valid-tie test selects values", {
  m <- valued()
  expect_equal(xtiecomposition(m, direction = "out", op = ">", cutoff = 3)$nodes["a", "Ties"], 1)
  expect_equal(xtiecomposition(m, direction = "out", op = "==", cutoff = 3)$nodes["a", "Ties"], 1)
})

test_that("equal counts only reciprocated ties with the same value", {
  m <- valued()
  m["b", "a"] <- 3                               # a <-> b with 3 both ways
  nd <- xtiecomposition(m, direction = "equal")$nodes
  expect_equal(nd["a", "Ties"], 1)               # a-c is 5 and 2
})

test_that("diagonal = TRUE counts ties to self (UCINET issue 18)", {
  expect_differs_from_ucinet(18)
  m <- valued()
  m["a", "a"] <- 1
  expect_equal(xtiecomposition(m, direction = "out")$nodes["a", "Ties"], 2)
  expect_equal(xtiecomposition(m, direction = "out", diagonal = TRUE)$nodes["a", "Ties"], 3)
})

test_that("one relation reduces to degree, and says so", {
  res <- xtiecomposition(campnet, direction = "out")
  a <- (as.matrix(campnet) > 0) * 1
  diag(a) <- 0
  expect_equal(res$nodes$Ties, unname(rowSums(a)))
  expect_true(any(grepl("One relation", res$assumptions)))
  expect_true(all(is.na(res$nodes$IQV)))
})

test_that("relations picks a subset", {
  nd <- xtiecomposition(sampson, relations = c("LikeT1", "Dislike"))$nodes
  expect_equal(names(nd), c("Ties", "fLikeT1", "fDislike", "pLikeT1", "pDislike",
                            "Blau", "IQV"))
  expect_error(xtiecomposition(sampson, relations = "nope"), "Available")
})

test_that("the report prints", {
  expect_snapshot(xtiecomposition(sampson, relations = 1:4))
})

# ---- xvaluedtiecomposition: hand-computed ---------------------------------------

test_that("columns are UCINET's seven", {
  expect_equal(names(xvaluedtiecomposition(valued())$nodes),
               c("# of ties", "Sum of values", "Mean", "Std Dev", "Min", "Max",
                 "Range"))
})

test_that("out-ties by default", {
  r <- unlist(xvaluedtiecomposition(valued())$nodes["a", ])
  expect_equal(unname(r), c(2, 8, 4, 1, 3, 5, 2))   # population sd of 3 and 5
})

test_that("in-ties", {
  r <- unlist(xvaluedtiecomposition(valued(), direction = "in")$nodes["a", ])
  expect_equal(unname(r), c(1, 2, 2, 0, 2, 2, 0))
})

test_that("both takes the incoming tie's own value (UCINET issue 19)", {
  expect_differs_from_ucinet(19)
  # 3 and 5 out, 2 in from c. UCINET adds x(a,c) = 5 for the incoming tie.
  r <- unlist(xvaluedtiecomposition(valued(), direction = "both")$nodes["a", ])
  expect_equal(r[["# of ties"]], 3)
  expect_equal(r[["Sum of values"]], 10)
})

test_that("reciprocated and equal", {
  r <- unlist(xvaluedtiecomposition(valued(), direction = "reciprocated")$nodes["a", ])
  expect_equal(r[["# of ties"]], 2)              # both values of the a-c pair
  expect_equal(r[["Sum of values"]], 7)
  r2 <- unlist(xvaluedtiecomposition(valued(), direction = "equal")$nodes["a", ])
  expect_equal(r2[["# of ties"]], 0)
  expect_true(all(is.na(r2[-1])))
})

test_that("an ego with no ties has a count of 0 and nothing else", {
  r <- unlist(xvaluedtiecomposition(valued())$nodes["b", ])
  expect_equal(r[["# of ties"]], 0)
  expect_true(all(is.na(r[-1])))
})

test_that("missing cells are skipped", {
  m <- valued()
  m["a", "b"] <- NA
  expect_equal(xvaluedtiecomposition(m)$nodes["a", "# of ties"], 1)
})

test_that("the report prints", {
  expect_snapshot(xvaluedtiecomposition(camp92))
})

# ---- cross-check --------------------------------------------------------------

test_that("the count of out-ties is xdegree on the dichotomized network", {
  d <- xdegree(camp92, weighted = FALSE)$nodes$Outdeg
  expect_equal(xvaluedtiecomposition(camp92)$nodes$`# of ties`, d)
})

# ---- goldens (menu runs) ------------------------------------------------------

test_that("sampson tie composition matches UCINET", {
  skip_if_no_golden("g8_tiecomp_sampson", "ego")
  g <- golden_matrix("g8_tiecomp_sampson", "ego")
  expect_equal(unname(as.matrix(xtiecomposition(sampson)$nodes)), unname(g),
               tolerance = 1e-5)
})

test_that("camp92 valued tie composition matches UCINET", {
  skip_if_no_golden("g8_vtiecomp_camp92", "ego")
  g <- golden_matrix("g8_vtiecomp_camp92", "ego")
  expect_equal(unname(as.matrix(xvaluedtiecomposition(camp92)$nodes)), unname(g),
               tolerance = 1e-5)
})
