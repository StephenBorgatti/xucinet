# Ego-alter similarity (chapter 8, sections 8.5.1 and 8.5.2).

tol <- 1e-8

# Ego a is tied to b (same group) and c (different); not to d (same) or e, f
# (different). So a = 1, b = 1, c = 1, d = 2.
six <- function() {
  m <- matrix(0, 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  m["a", c("b", "c")] <- 1
  m
}
groups <- function() c(a = 1, b = 1, c = 2, d = 1, e = 2, f = 2)

# ---- categorical ---------------------------------------------------------------

test_that("the columns are UCINET's thirteen and ego's value", {
  nd <- xegoaltersimilarity(six(), groups(), type = "categorical")$nodes
  expect_equal(names(nd), c("H", "H*", "Coleman", "EI", "Jaccard", "Yules Q",
                            "Kappa", "Phi", "Bona", "Odds_Ratio", "Log_Odds",
                            "fInGroup", "fOutGroup", "Attribute"))
})

test_that("the two-by-two gives every measure", {
  r <- unlist(xegoaltersimilarity(six(), groups(), type = "categorical")$nodes["a", ])
  expect_equal(r[["H"]], 1 / 2)
  expect_equal(r[["H*"]], 1 / 2 - 2 / 5)         # a + c over n = 5
  expect_equal(r[["Coleman"]], 0.1 / 0.6)
  expect_equal(r[["EI"]], 0)
  expect_equal(r[["Jaccard"]], 1 / 3)
  expect_equal(r[["Yules Q"]], 1 / 3)            # ad = 2, bc = 1
  expect_equal(r[["Kappa"]], (0.2 - 0.16) / (0.4 - 0.16))
  expect_equal(r[["Phi"]], 1 / sqrt(36))
  expect_equal(r[["Bona"]], 2 - sqrt(2))
  expect_equal(r[["Odds_Ratio"]], 2)
  expect_equal(r[["Log_Odds"]], log(2))
  expect_equal(r[["fInGroup"]], 1)
  expect_equal(r[["fOutGroup"]], 1)
  expect_equal(r[["Attribute"]], 1)
})

test_that("an ego with no ties has every measure missing", {
  r <- unlist(xegoaltersimilarity(six(), groups(), type = "categorical")$nodes["b", ])
  expect_true(all(is.na(r[1:13])))
  expect_equal(r[["Attribute"]], 1)
})

test_that("out-ties by default; direction changes the rows", {
  expect_true(is.na(xegoaltersimilarity(six(), groups(),
                                        type = "categorical")$nodes["b", "H"]))
  expect_equal(xegoaltersimilarity(six(), groups(), type = "categorical",
                                   direction = "in")$nodes["b", "H"], 1)
})

test_that("valued data are dichotomized", {
  m <- six() * 5
  expect_equal(xegoaltersimilarity(m, groups(), type = "categorical")$nodes,
               xegoaltersimilarity(six(), groups(), type = "categorical")$nodes)
})

test_that("an ego with a missing value is skipped", {
  g <- groups()
  g["a"] <- NA
  expect_true(is.na(xegoaltersimilarity(six(), g, type = "categorical")$nodes["a", "H"]))
})

test_that("EI and H agree with xhomophily's definitions node by node", {
  # xhomophily's E-I index over a single ego's row is (b - a)/(a + b), the same
  # quantity.
  nd <- xegoaltersimilarity(campnet, camp92_attr$Gender, type = "categorical")$nodes
  expect_equal(nd$EI, (nd$fOutGroup - nd$fInGroup) / (nd$fOutGroup + nd$fInGroup))
  expect_equal(nd$H, nd$fInGroup / (nd$fInGroup + nd$fOutGroup))
})

test_that("the report prints", {
  expect_snapshot(xegoaltersimilarity(campnet, camp92_attr$Gender,
                                      type = "categorical"))
})

# ---- continuous ----------------------------------------------------------------

vals <- function() c(a = 1, b = 2, c = 4, d = 7, e = 11, f = 16)

test_that("-AbsDiff is the default and is Pearson's r of ties on similarity", {
  res <- xegoaltersimilarity(six(), vals())
  expect_equal(names(res$nodes), "-AbsDiff")
  tie <- c(1, 1, 0, 0, 0)
  sim <- -abs(1 - c(2, 4, 7, 11, 16))
  expect_equal(res$nodes["a", 1], stats::cor(tie, sim), tolerance = tol)
})

test_that("several measures come back in the dialog's order", {
  nd <- xegoaltersimilarity(six(), vals(),
                            method = c("negabsdiff", "zegers", "absdiff"))$nodes
  expect_equal(names(nd), c("Zegers", "Absolute difference", "-AbsDiff"))
  expect_equal(nd$`Absolute difference`, -nd$`-AbsDiff`)
})

test_that("an ego with no ties has no correlation", {
  expect_true(is.na(xegoaltersimilarity(six(), vals())$nodes["b", 1]))
})

test_that("normalization moves the attribute, not the difference measures", {
  a <- xegoaltersimilarity(six(), vals())$nodes
  b <- xegoaltersimilarity(six(), vals(), normalize = "additive")$nodes
  z <- xegoaltersimilarity(six(), vals(), normalize = "interval")$nodes
  expect_equal(a, b)
  expect_equal(a, z)
  pz <- xegoaltersimilarity(six(), vals(), method = "product",
                            normalize = "additive")$nodes
  pa <- xegoaltersimilarity(six(), vals(), method = "product")$nodes
  expect_false(isTRUE(all.equal(pz, pa)))
})

test_that("minovermax takes a zero as 0.01 and equal values as 1", {
  f <- similarity_methods()$minovermax$f
  expect_equal(f(0, 2), 0.01 / 2)
  expect_equal(f(3, 3), 1)
  expect_equal(f(4, 2), 0.5)
})

test_that("bad methods are refused", {
  expect_error(xegoaltersimilarity(six(), vals(), method = "cosine"), "method")
})

test_that("the 1e aliases set the type", {
  g <- camp92_attr$Gender
  expect_message(a <- xEgoAlterSimilarityCat(campnet, g), "1e name")
  expect_equal(names(a$nodes)[1], "H")
  expect_message(b <- xEgoAlterSimilarityCon(campnet, g), "1e name")
  expect_equal(names(b$nodes), "-AbsDiff")
})

test_that("the report prints", {
  expect_snapshot(xegoaltersimilarity(hightech, "Age", data = hightech_attr))
})

# ---- goldens --------------------------------------------------------------------

test_that("campnet by gender matches UCINET's categohom", {
  skip_if_no_golden("g8_egohom_campnet_gender", "ego")
  g <- golden_matrix("g8_egohom_campnet_gender", "ego")
  res <- xegoaltersimilarity(campnet, camp92_attr$Gender, type = "categorical")
  expect_equal(unname(as.matrix(res$nodes)), unname(g), tolerance = 1e-5)
})

test_that("hightech advice by age matches UCINET", {
  skip_if_no_golden("g8_egohomcont_hightech_age", "ego")
  g <- golden_matrix("g8_egohomcont_hightech_age", "ego")
  res <- xegoaltersimilarity(hightech, "Age", data = hightech_attr,
                             method = c("zegers", "minovermax", "absdiff",
                                        "sqdiff", "product", "negabsdiff"))
  expect_equal(unname(as.matrix(res$nodes)), unname(g), tolerance = 1e-5)
})
