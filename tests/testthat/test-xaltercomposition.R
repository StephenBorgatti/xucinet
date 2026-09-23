# Egonet alter composition (chapter 8, sections 8.4.1 and 8.4.2).

tol <- 1e-8

# a at the centre of a star with b, c, d; e isolated.
star_iso <- function() {
  m <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  m["a", c("b", "c", "d")] <- 1
  m[c("b", "c", "d"), "a"] <- 1
  m
}
cats <- function() c(a = 1, b = 1, c = 1, d = 2, e = 2)
ages <- function() c(a = 50, b = 10, c = 20, d = 30, e = 40)

# ---- categorical ---------------------------------------------------------------

test_that("the columns are own value, f and p per category, Heterogeneity, IQV", {
  nd <- xaltercomposition(star_iso(), cats(), type = "categorical")$nodes
  expect_equal(names(nd), c("Attribute", "f1", "f2", "p1", "p2",
                            "Heterogeneity", "IQV"))
})

test_that("the centre's alters are two of category 1 and one of 2", {
  r <- unlist(xaltercomposition(star_iso(), cats(), type = "categorical")$nodes["a", ])
  expect_equal(r[["Attribute"]], 1)
  expect_equal(r[["f1"]], 2)
  expect_equal(r[["f2"]], 1)
  expect_equal(r[["p1"]], 2 / 3)
  het <- 1 - (4 / 9 + 1 / 9)
  expect_equal(r[["Heterogeneity"]], het)
  expect_equal(r[["IQV"]], het / (1 - 1 / 2))
})

test_that("an isolate has zero counts and missing proportions", {
  r <- unlist(xaltercomposition(star_iso(), cats(), type = "categorical")$nodes["e", ])
  expect_equal(r[["f1"]], 0)
  expect_true(all(is.na(r[c("p1", "p2", "Heterogeneity", "IQV")])))
})

test_that("ignoreown leaves out ego's own category", {
  r <- unlist(xaltercomposition(star_iso(), cats(), type = "categorical",
                                ignoreown = TRUE)$nodes["a", ])
  expect_equal(r[["f1"]], 0)
  expect_equal(r[["f2"]], 1)
  expect_equal(r[["Heterogeneity"]], 0)
})

test_that("tie values weight the counts, as UCINET's addcase(value, weight) does", {
  m <- star_iso()
  m["a", "d"] <- m["d", "a"] <- 4
  r <- unlist(xaltercomposition(m, cats(), type = "categorical")$nodes["a", ])
  expect_equal(r[["f2"]], 4)
  expect_equal(r[["p2"]], 4 / 6)
})

test_that("ties defines the alters", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- 1
  m["c", "a"] <- 1
  g <- c(a = 1, b = 1, c = 2)
  expect_equal(xaltercomposition(m, g, type = "categorical")$nodes["a", "f2"], 1)
  expect_equal(xaltercomposition(m, g, type = "categorical",
                                 ties = "out")$nodes["a", "f2"], 0)
  expect_equal(xaltercomposition(m, g, type = "categorical",
                                 ties = "in")$nodes["a", "f2"], 1)
})

test_that("a text attribute is categorical without being told", {
  g <- c(a = "x", b = "x", c = "x", d = "y", e = "y")
  nd <- xaltercomposition(star_iso(), g)$nodes
  expect_equal(names(nd)[2:3], c("fx", "fy"))
  expect_equal(nd["a", "fx"], 2)
  # ego's own value is shown by its category's position
  expect_equal(nd$Attribute, c(1, 1, 1, 2, 2))
})

test_that("the frequency table covers the whole attribute", {
  res <- xaltercomposition(star_iso(), cats(), type = "categorical")
  expect_true(any(grepl("Frequencies", res$preamble)))
})

test_that("a missing attribute value is skipped", {
  g <- cats()
  g["b"] <- NA
  expect_equal(xaltercomposition(star_iso(), g, type = "categorical")$nodes["a", "f1"], 1)
})

# ---- continuous ----------------------------------------------------------------

test_that("the columns are UCINET's nine", {
  expect_equal(names(xaltercomposition(star_iso(), ages())$nodes),
               c("Avg", "Sum", "Min", "Max", "StdDev", "EstSD", "CV", "Num", "WtdNum"))
})

test_that("the centre's alters are aged 10, 20 and 30", {
  r <- unlist(xaltercomposition(star_iso(), ages())$nodes["a", ])
  expect_equal(r[["Avg"]], 20)
  expect_equal(r[["Sum"]], 60)
  expect_equal(r[["Min"]], 10)
  expect_equal(r[["Max"]], 30)
  expect_equal(r[["StdDev"]], sqrt(200 / 3))     # dividing by n
  expect_equal(r[["EstSD"]], 10)                 # dividing by n - 1
  expect_equal(r[["CV"]], sqrt(200 / 3) / 20)
  expect_equal(r[["Num"]], 3)
  expect_equal(r[["WtdNum"]], 3)
})

test_that("tie strengths weight, multiply or are ignored", {
  m <- star_iso()
  m["a", "d"] <- m["d", "a"] <- 2
  a <- unlist(xaltercomposition(m, ages())$nodes["a", ])
  expect_equal(a[["Avg"]], (10 + 20 + 2 * 30) / 4)
  expect_equal(a[["Sum"]], 60)                   # the unweighted total
  expect_equal(a[["WtdNum"]], 4)
  x <- unlist(xaltercomposition(m, ages(), weighting = "multiply")$nodes["a", ])
  expect_equal(x[["Sum"]], 10 + 20 + 60)
  n <- unlist(xaltercomposition(m, ages(), weighting = "none")$nodes["a", ])
  expect_equal(n[["Avg"]], 20)
})

test_that("an isolate has counts of zero and nothing else", {
  r <- unlist(xaltercomposition(star_iso(), ages())$nodes["e", ])
  expect_equal(r[c("Num", "WtdNum")], c(Num = 0, WtdNum = 0))
  expect_true(all(is.na(r[1:7])))
})

test_that("a single alter has a spread of zero, not missing, as UCINET has it", {
  r <- unlist(xaltercomposition(star_iso(), ages())$nodes["b", ])
  expect_equal(r[["StdDev"]], 0)
  expect_equal(r[["EstSD"]], 0)
})

# ---- type detection (G3) ------------------------------------------------------

test_that("numeric codes are continuous, with a note", {
  res <- xaltercomposition(campnet, camp92_attr$Gender)
  expect_equal(names(res$nodes)[1], "Avg")
  expect_true(any(grepl("type = \"categorical\"", res$assumptions)))
})

test_that("an attribute can be named and looked up in data", {
  a <- xaltercomposition(hightech, "Age", data = hightech_attr)
  b <- xaltercomposition(hightech, hightech_attr$Age)
  expect_equal(a$nodes, b$nodes)
})

test_that("bad input is refused", {
  expect_error(xaltercomposition(campnet, 1:3), "18 nodes")
  expect_error(xaltercomposition(campnet, letters[1:18], type = "continuous"),
               "numeric")
  expect_error(xaltercomposition(davis, 1:18), "1-mode")
})

test_that("the 1e aliases set the type", {
  g <- camp92_attr$Gender
  expect_message(a <- xAlterCompositionCat(campnet, g), "1e name")
  expect_equal(names(a$nodes)[2:3], c("f1", "f2"))
  expect_message(b <- xAlterCompositionCon(campnet, g), "1e name")
  expect_equal(names(b$nodes)[1], "Avg")
})

test_that("the reports print", {
  expect_snapshot(xaltercomposition(campnet, camp92_attr$Gender,
                                    type = "categorical"))
  expect_snapshot(xaltercomposition(hightech, "Age", data = hightech_attr))
})

# ---- goldens --------------------------------------------------------------------

test_that("campnet by gender matches UCINET", {
  skip_if_no_golden("g8_egocomp_campnet_gender", "ego")
  g <- golden_matrix("g8_egocomp_campnet_gender", "ego")
  res <- xaltercomposition(campnet, camp92_attr$Gender, type = "categorical")
  expect_equal(unname(as.matrix(res$nodes)), unname(g), tolerance = 1e-5)
})

test_that("hightech advice by age matches UCINET", {
  skip_if_no_golden("g8_compcont_hightech_age", "ego")
  g <- golden_matrix("g8_compcont_hightech_age", "ego")
  res <- xaltercomposition(hightech, "Age", data = hightech_attr)
  expect_equal(unname(as.matrix(res$nodes)), unname(g), tolerance = 1e-5)
})
