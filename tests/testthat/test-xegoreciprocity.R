# Node-level reciprocity (chapter 8; Network | Ego Networks | Egonet
# Reciprocity). The table used to be part of xreciprocity(); it moved here on
# 23 Sep 2026 (SPEC addendum, level of analysis).

# a <-> b, a -> c, c <-> d: one mutual pair either side of one lone arc.
hand4 <- function() {
  matrix(c(0, 1, 1, 0,
           1, 0, 0, 0,
           0, 0, 0, 1,
           0, 0, 1, 0), 4, 4, byrow = TRUE,
         dimnames = list(letters[1:4], letters[1:4]))
}

test_that("the node table is UCINET's six proportions in its order", {
  n <- xegoreciprocity(campnet)$nodes
  expect_equal(names(n), c("Symmetric", "Non-Symmetric", "Out/NonSym",
                           "In/NonSym", "Sym/Out", "Sym/In"))
  expect_equal(rownames(n), rownames(as.matrix(campnet)))
  # Symmetric and Non-Symmetric partition the contacts
  ok <- !is.na(n$Symmetric)
  expect_equal(n$Symmetric[ok] + n$`Non-Symmetric`[ok], rep(1, sum(ok)))
})

test_that("node-level reciprocity is what it says, by hand", {
  n <- xegoreciprocity(hand4())$nodes
  # a has contacts b (mutual) and c (one-way out): half symmetric
  expect_equal(n["a", "Symmetric"], 0.5)
  expect_equal(n["a", "Out/NonSym"], 1)   # the lone asymmetry is outgoing
  expect_equal(n["a", "In/NonSym"], 0)
  # b has only a, and it is mutual
  expect_equal(n["b", "Symmetric"], 1)
})

test_that("node-level symmetry is value equality, not just presence", {
  # A pair of unequal positive values is a tie both ways but not symmetric,
  # while the whole-network arc ratio counts it as reciprocated, because that
  # report tests presence. Ledger entry 16.
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- 3; m["b", "a"] <- 2
  res <- xegoreciprocity(m)
  expect_equal(res$nodes["a", "Symmetric"], 0)
  expect_true(any(grepl("3 does not match", res$assumptions)))
  expect_equal(xreciprocity(m)$summary[["Arc Reciprocity"]], 1)
})

test_that("xegonet's Symmetric column is the same figure", {
  expect_equal(xegonet(campnet)$nodes$Symmetric,
               xegoreciprocity(campnet)$nodes$Symmetric)
})

test_that("xegoreciprocity refuses 2-mode data", {
  expect_error(xegoreciprocity(davis))
})

test_that("the report prints", {
  expect_snapshot(xegoreciprocity(campnet))
})
