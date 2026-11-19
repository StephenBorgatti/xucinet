# Multirelational datasets in the whole-network and group routines (xucinet
# #53, 19 Nov 2026). Each used to read only the first relation, silently.
# xhomophily() now reports every relation, one row each, as UCINET's routine
# does; xreciprocity(), xcomponents() and xdensitybygroups() take `relation`
# and name the relation used (differences ledger, entry 51).

tol <- 1e-10
dept <- function() hightech_attr$Department

test_that("xhomophily() reports every relation, one row each", {
  s <- xhomophily(hightech, dept())$summary
  expect_s3_class(s, "data.frame")
  expect_equal(rownames(s), xrelations(hightech))
  expect_equal(names(s), c("H", "h-star", "Corr", "Modul Q", "Assort",
                           "Yules Q", "E-I Index"))
  for (r in xrelations(hightech)) {
    one <- xhomophily(as.matrix(hightech, relation = r), dept())$summary
    expect_equal(unlist(s[r, ]), unlist(one[1, ]), tolerance = tol)
  }
  # the book's Table 10.6 (generators/ch10.R in asnr2e)
  expect_equal(round(s[["E-I Index"]], 3), c(0.516, 0.255, -0.600))
  expect_equal(round(s[["Yules Q"]], 3), c(0.096, 0.471, 0.886))
})

test_that("xhomophily() with one relation is a one-row table", {
  s <- xhomophily(campnet, camp92_attr$Gender)$summary
  expect_equal(nrow(s), 1L)
  expect_equal(s[["H"]], unlist(s[1, ])[["H"]])
})

test_that("xreciprocity() reads the relation asked for and says which", {
  for (r in xrelations(hightech)) {
    got <- xreciprocity(hightech, relation = r)
    one <- xreciprocity(as.matrix(hightech, relation = r))
    expect_equal(got$summary, one$summary, tolerance = tol)
    expect_true(sprintf("Relation: %s (of 3).", r) %in% got$assumptions)
  }
  expect_true("Relation: Advice (of 3)." %in% xreciprocity(hightech)$assumptions)
  expect_false(any(grepl("^Relation:", xreciprocity(campnet)$assumptions)))
  expect_error(xreciprocity(hightech, relation = "Nope"), "not a relation")
})

test_that("xcomponents() reads the relation asked for and says which", {
  for (r in xrelations(hightech)) {
    got <- xcomponents(hightech, relation = r)
    one <- xcomponents(as.matrix(hightech, relation = r))
    expect_equal(got$nodes$Component, one$nodes$Component)
    expect_equal(got$summary, one$summary, tolerance = tol)
    expect_true(sprintf("Relation: %s (of 3).", r) %in% got$assumptions)
  }
  # ReportTo is a tree with the CEO at the root: one weak component; the
  # strong components are the 21 single nodes.
  expect_equal(xcomponents(hightech, relation = "ReportTo")$summary$Components, 1)
  expect_equal(xcomponents(hightech, relation = "ReportTo",
                           type = "strong")$summary$Components, 21)
})

test_that("xdensitybygroups() reads the relation asked for and says which", {
  for (r in xrelations(hightech)) {
    got <- xdensitybygroups(hightech, dept(), relation = r)
    one <- xdensitybygroups(as.matrix(hightech, relation = r), dept())
    expect_equal(got$matrices$Density, one$matrices$Density, tolerance = tol)
    expect_true(sprintf("Relation: %s (of 3).", r) %in% got$assumptions)
  }
  expect_true("Relation: Advice (of 3)." %in%
                xdensitybygroups(hightech, dept())$assumptions)
})
