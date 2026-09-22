# Filling in missing ties (chapter 5, section 5.5.5).
#
# Nine methods from timputation in uimputemissing.pas, plus Replace Missing
# Values as its own routine.

tol <- 1e-6

# Four nodes with one missing cell in each of three rows, each of which has an
# observed reciprocal, so reconstruction has something to work with.
holes <- function() {
  matrix(c( 0,  1,  1,  0,
           NA,  0,  1,  1,
            0, NA,  0,  1,
            1,  1, NA,  0), 4, 4, byrow = TRUE,
         dimnames = list(letters[1:4], letters[1:4]))
}

test_that("the diagonal is set missing first and never imputed", {
  # Every loop in timputation is `if i <> j`.
  for (meth in c("remo", "re", "mo", "mean", "tm", "knn", "nti", "copy")) {
    out <- as.matrix(ximpute(holes(), method = meth, seed = 1))
    expect_true(all(is.na(diag(out))), info = meth)
  }
})

test_that("re takes the reciprocal cell", {
  out <- as.matrix(ximpute(holes(), method = "re"))
  expect_equal(out["b", "a"], 1)     # from [a,b]
  expect_equal(out["c", "b"], 1)     # from [b,c]
  expect_equal(out["d", "c"], 1)     # from [c,d]
})

test_that("observed cells are never touched", {
  m <- holes()
  for (meth in c("remo", "re", "mo", "mean", "tm", "knn", "nti", "copy",
                 "random")) {
    out <- as.matrix(ximpute(m, method = meth, seed = 1))
    seen <- !is.na(m) & row(m) != col(m)
    expect_equal(out[seen], m[seen], info = meth)
  }
})

test_that("the ties rule decides pairs that are missing both ways", {
  # reoptions.ItemIndex = 0, so zero is the dialog's default.
  p <- matrix(c(0, NA, NA, 0), 2, 2, dimnames = list(c("a","b"), c("a","b")))
  expect_equal(as.matrix(ximpute(p, method = "re"))["a", "b"], 0)
  expect_equal(as.matrix(ximpute(p, method = "re", ties = "zero"))["a", "b"], 0)
  expect_true(is.na(as.matrix(
    ximpute(p, method = "re", ties = "missing"))["a", "b"]))
})

test_that("ties = density compares the density with the cutoff", {
  # A dense network fills with 1, a sparse one with 0.
  dense <- matrix(1, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  dense[1, 2] <- NA; dense[2, 1] <- NA
  expect_equal(as.matrix(
    ximpute(dense, method = "re", ties = "density"))["a", "b"], 1)
  sparse <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  sparse[1, 2] <- NA; sparse[2, 1] <- NA
  expect_equal(as.matrix(
    ximpute(sparse, method = "re", ties = "density"))["a", "b"], 0)
})

test_that("mo and mean use the column, because the column is what others said", {
  m <- holes()
  # column a has 0 (from c) and 1 (from d) observed
  expect_equal(as.matrix(ximpute(m, method = "mean", round = FALSE))["b", "a"],
               mean(c(0, 1)))
  expect_true(as.matrix(ximpute(m, method = "mo"))["b", "a"] %in% c(0, 1))
})

test_that("rounding is half-up, not to even", {
  # runroundup: `if samevalue(means - t, 0.5) then t + 1`.
  expect_equal(round_half_up(c(0.5, 1.5, 2.5)), c(1, 2, 3))
  expect_false(isTRUE(all.equal(round_half_up(0.5), round(0.5))))
  m <- holes()
  expect_equal(as.matrix(ximpute(m, method = "mean", round = TRUE))["b", "a"], 1)
})

test_that("tm fills every hole with the global mean", {
  m <- holes()
  out <- as.matrix(ximpute(m, method = "tm", round = FALSE))
  off <- row(m) != col(m)
  avg <- mean(m[off & !is.na(m)])
  expect_equal(out["b", "a"], avg)
  expect_equal(out["c", "b"], avg)
})

test_that("nti fills with the value it is given", {
  expect_equal(as.matrix(ximpute(holes(), method = "nti"))["b", "a"], 0)
  expect_equal(as.matrix(ximpute(holes(), method = "nti", value = 7))["b", "a"], 7)
})

test_that("remo is re and then mo", {
  # Anything reconstruction can reach is the same as re; what it cannot is
  # filled from the column mode rather than by the ties rule.
  m <- holes()
  expect_equal(as.matrix(ximpute(m, method = "remo"))["b", "a"],
               as.matrix(ximpute(m, method = "re"))["b", "a"])
})

test_that("knn imputes from the nearest columns", {
  out <- as.matrix(ximpute(holes(), method = "knn", k = 3))
  expect_false(is.na(out["b", "a"]))
})

test_that("copy uses what the node's own contacts said", {
  # a's out-ties are b and c; both were asked about d.
  m <- matrix(c(0, 1, 1, NA,
                0, 0, 0,  1,
                0, 0, 0,  1,
                0, 0, 0,  0), 4, 4, byrow = TRUE,
              dimnames = list(letters[1:4], letters[1:4]))
  expect_equal(as.matrix(ximpute(m, method = "copy", seed = 1))["a", "d"], 1)
})

test_that("a node with no contacts to copy from gets zero", {
  # `if num = 0 then exit(0)`.
  m <- matrix(c(0, 0, NA,
                0, 0, 1,
                0, 1, 0), 3, 3, byrow = TRUE,
              dimnames = list(letters[1:3], letters[1:3]))
  expect_equal(as.matrix(ximpute(m, method = "copy", seed = 1))["a", "c"], 0)
})

test_that("random fills only the missing cells, unlike UCINET", {
  # dev/UCINET-ISSUES.md issue 15: runrandom's binary branch has no isna test
  # and overwrites the whole matrix, and its valued branch draws from a pool
  # that includes the missing cells. Ledger entry 15.
  expect_differs_from_ucinet(15)
  m <- holes()
  out <- as.matrix(ximpute(m, method = "random", seed = 3))
  seen <- !is.na(m) & row(m) != col(m)
  expect_equal(out[seen], m[seen])
  expect_false(any(is.na(out[row(m) != col(m)])))
})

test_that("random on valued data draws from the observed ties", {
  expect_differs_from_ucinet(15)
  m <- matrix(c(0, 5, 7, NA,
                5, 0, 7,  5,
                7, 7, 0,  7,
                5, 5, 7,  0), 4, 4, byrow = TRUE,
              dimnames = list(letters[1:4], letters[1:4]))
  out <- as.matrix(ximpute(m, method = "random", seed = 4))
  expect_true(out["a", "d"] %in% c(5, 7))
})

test_that("seed makes the random methods reproducible", {
  a <- as.matrix(ximpute(holes(), method = "random", seed = 11))
  b <- as.matrix(ximpute(holes(), method = "random", seed = 11))
  expect_equal(a, b)
})

test_that("ximpute names the dataset and counts what it filled", {
  out <- ximpute(holes())
  expect_equal(out$title, "holes()-imp")
  expect_match(attr(out, "history"), "3 cells filled")
})

test_that("ximpute refuses 2-mode data", {
  expect_error(ximpute(davis), "1-mode")
})

test_that("every relation of a stack is imputed", {
  s <- as_xucinet(list(one = holes(), two = holes()))
  out <- ximpute(s)
  expect_equal(xrelations(out), c("one", "two"))
  expect_match(attr(out, "history"), "6 cells")
})

# ---- xreplacemissing --------------------------------------------------------

test_that("xreplacemissing takes the transpose by default", {
  # The dialog's "needs to be transposed" box is checked, and the source may
  # be the input itself, which is reconstruction.
  out <- as.matrix(xreplacemissing(holes()))
  expect_equal(out["b", "a"], 1)
  # Off the diagonal it is the same thing as reconstruction. On the diagonal
  # it is not: ximpute blanks it first, as its dialog does, and this routine
  # has no such rule, so the original self-ties survive.
  same <- as.matrix(ximpute(holes(), method = "re", ties = "missing"))
  off <- row(out) != col(out)
  expect_equal(out[off], same[off])
  expect_equal(unname(diag(out)), rep(0, 4))
  expect_true(all(is.na(diag(same))))
})

test_that("a separate source can be used, transposed or not", {
  m <- holes()
  src <- matrix(9, 4, 4, dimnames = dimnames(m))
  expect_equal(as.matrix(xreplacemissing(m, src, transpose = FALSE))["b", "a"], 9)
})

test_that("a source of the wrong shape is an error that points at xmatch", {
  src <- matrix(1, 2, 2, dimnames = list(c("a","b"), c("a","b")))
  expect_error(xreplacemissing(holes(), src), "xmatch")
})

test_that("xreplacemissing names the dataset and counts what it filled", {
  out <- xreplacemissing(holes())
  expect_equal(out$title, "holes()-rna")
  expect_match(attr(out, "history"), "3 missing cells")
})
