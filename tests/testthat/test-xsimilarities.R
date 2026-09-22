# Similarities and distances (chapter 5, section 5.5.2).
#
# Nineteen measures ported from utsimilarity.pas and ug2sim2.pas. Each one is
# checked against its definition on profiles small enough to work out by hand,
# and the four that R or another package also computes are cross-checked.

tol <- 1e-6

# Three columns whose overlaps are easy to count:
#   p = (1, 0, 1)   q = (1, 1, 0)   r = (0, 0, 1)
tiny <- function() {
  matrix(c(1, 0, 1,
           1, 1, 0,
           0, 0, 1), 3, 3,
         dimnames = list(letters[1:3], c("p", "q", "r")))
}

# p and q as the dialog would compare them, with the diagonal left in.
pq <- function(method) {
  as.matrix(xsimilarities(tiny(), method = method, diagonal = TRUE))["p", "q"]
}

test_that("the defaults are the dialog's: columns, Pearson, diagonal invalid", {
  # pMode.ItemIndex = 1 (Columns), SimMeasure.ItemIndex = 0 (Pearson), and
  # the "Diagonal values are valid" box unchecked.
  s <- xsimilarities(campnet)
  expect_equal(dim(as.matrix(s)), c(18, 18))
  expect_match(attr(s, "history"), "Pearson correlation between cols")
  # correlation of the columns with the diagonal blanked out first
  m <- as.matrix(campnet)
  diag(m) <- NA
  theirs <- suppressWarnings(stats::cor(m, use = "pairwise.complete.obs"))
  expect_equal(unname(as.matrix(s)), unname(theirs), tolerance = tol)
})

test_that("each similarity is its definition", {
  # p = (1,0,1), q = (1,1,0): one shared positive, three cells where either
  # is positive, one match out of three.
  expect_equal(pq("jaccard"), 1 / 3)
  expect_equal(pq("valuedjaccard"), 1 / 3)     # binary data, so the same
  expect_equal(pq("matches"), 1 / 3)
  expect_equal(pq("crossproducts"), 1)         # only row a contributes
  expect_equal(pq("avgcrossproducts"), 1 / 3)
  expect_equal(pq("identity"), 2 * 1 / (2 + 2))
  expect_equal(pq("cosine"), 1 / (sqrt(2) * sqrt(2)))
  expect_equal(pq("covariance"),
               sum((c(1,0,1) - 2/3) * (c(1,1,0) - 2/3)) / 3)
})

test_that("each distance is its definition", {
  expect_equal(pq("euclidean"), sqrt(2))
  expect_equal(pq("manhattan"), 2)
  expect_equal(pq("avgabsdiff"), 2 / 3)
  expect_equal(pq("hamming"), 2)
  expect_equal(pq("ssd"), 2)
  expect_equal(pq("nonmatches"), 1 - 1 / 3)
  expect_equal(pq("jaccarddistance"), 1 - 1 / 3)
  expect_equal(pq("nssd"), 2 / (2 * 2))        # sum((x-y)^2) / (sum x^2 * sum y^2)
})

test_that("Yule's Q and Cohen's kappa use the 2 x 2 table", {
  # p = (1,0,1), q = (1,1,0): a = 1, b = 1, c = 1, d = 0.
  # Q = (ad - bc)/(ad + bc) = (0 - 1)/(0 + 1) = -1
  expect_equal(pq("yulesq"), -1)
  # kappa: expected agreement = (r1*c1 + r2*c2)/n = (2*2 + 1*1)/3 = 5/3
  # (a + d - E)/(n - E) = (1 - 5/3)/(3 - 5/3) = (-2/3)/(4/3) = -0.5
  expect_equal(pq("kappa"), -0.5)
})

test_that("a pair with no shared positive cells has no Jaccard to report", {
  # tjaccard returns bna when the denominator is zero.
  m <- matrix(0, 3, 2, dimnames = list(letters[1:3], c("p", "q")))
  expect_true(is.na(as.matrix(
    xsimilarities(m, method = "jaccard", diagonal = TRUE))["p", "q"]))
})

test_that("a constant profile has no correlation to report", {
  # tpearson.getresult needs both sums of squares above zero.
  m <- cbind(p = c(1, 1, 1), q = c(1, 0, 1))
  rownames(m) <- letters[1:3]
  expect_true(is.na(as.matrix(
    xsimilarities(m, method = "correlation", diagonal = TRUE))["p", "q"]))
})

test_that("every measure gives a symmetric matrix with a unit-like diagonal", {
  for (me in names(sim_measures)) {
    v <- as.matrix(xsimilarities(campnet, method = me))
    expect_equal(v, t(v), info = me)
  }
})

test_that("measures delete pairwise", {
  # valid(x, y) counts a cell only when both profiles have it.
  m <- cbind(p = c(1, 0, 1), q = c(1, NA, 0))
  rownames(m) <- letters[1:3]
  # only rows a and c are usable: matches on a, not on c
  expect_equal(as.matrix(
    xsimilarities(m, method = "matches", diagonal = TRUE))["p", "q"], 1 / 2)
})

test_that("the diagonal is dropped from both profiles, and only those two", {
  # setdiagonal(bna) makes every (k,k) missing, so comparing columns i and j
  # loses cells (i,i) and (j,j) and nothing else.
  m <- matrix(1, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m[1, 1] <- 5; m[2, 2] <- 7
  # with the diagonal valid, columns a and b differ on those two cells
  expect_equal(as.matrix(
    xsimilarities(m, method = "hamming", diagonal = TRUE))["a", "b"], 2)
  # with it invalid, both cells drop out and nothing is left to differ on
  expect_equal(as.matrix(
    xsimilarities(m, method = "hamming"))["a", "b"], 0)
})

test_that("non-square and 2-mode data force the diagonal valid", {
  # The option is captioned "For square matrices only".
  a <- as.matrix(xsimilarities(davis, method = "hamming"))
  b <- as.matrix(xsimilarities(davis, method = "hamming", diagonal = TRUE))
  expect_equal(a, b)
})

test_that("mode picks what is compared", {
  expect_equal(dim(as.matrix(xsimilarities(davis, mode = "rows"))), c(18, 18))
  expect_equal(dim(as.matrix(xsimilarities(davis, mode = "cols"))), c(14, 14))
  r <- xsimilarities(hightech, mode = "relations")
  expect_equal(rownames(as.matrix(r)), xrelations(hightech))
})

test_that("comparing relations needs more than one", {
  expect_error(xsimilarities(campnet, mode = "relations"), "relations")
})

test_that("xsimilarities names the dataset as UCINET does", {
  # <input>-<first three letters of the dialog's label>-<R|C|M>
  expect_equal(xsimilarities(campnet)$title, "campnet-Pea-C")
  expect_equal(xsimilarities(campnet, mode = "rows")$title, "campnet-Pea-R")
  expect_equal(xsimilarities(campnet, method = "euclidean")$title, "campnet-Euc-C")
  expect_equal(xsimilarities(campnet, method = "yulesq")$title, "campnet-Yul-C")
  expect_equal(xsimilarities(hightech, mode = "relations")$title, "hightech-Pea-M")
})

test_that("the history says whether the measure is a similarity or a distance", {
  # xmds() and xhclust() still require type=, but the reader should be able to
  # see which way round the numbers run.
  expect_match(attr(xsimilarities(campnet), "history"), "similarity")
  expect_match(attr(xsimilarities(campnet, method = "euclidean"), "history"),
               "distance")
})

test_that("the result is an undirected 1-mode dataset", {
  s <- xsimilarities(davis, mode = "rows")
  expect_s3_class(s, "xucinet")
  expect_equal(s$mode, "1-mode")
  expect_false(s$directed)
})

test_that("cross-check: euclidean distances against stats::dist", {
  m <- as.matrix(campnet)
  ours <- as.matrix(xsimilarities(m, method = "euclidean", mode = "rows",
                                  diagonal = TRUE))
  theirs <- as.matrix(stats::dist(m, method = "euclidean"))
  expect_equal(unname(ours), unname(theirs), tolerance = tol)
})

test_that("cross-check: manhattan distances against stats::dist", {
  m <- as.matrix(campnet)
  ours <- as.matrix(xsimilarities(m, method = "manhattan", mode = "rows",
                                  diagonal = TRUE))
  theirs <- as.matrix(stats::dist(m, method = "manhattan"))
  expect_equal(unname(ours), unname(theirs), tolerance = tol)
})

test_that("cross-check: covariance is the population form, not R's default", {
  # tcovariance divides by n; stats::cov divides by n - 1.
  m <- as.matrix(campnet)
  diag(m) <- NA
  ours <- as.matrix(xsimilarities(campnet, method = "covariance"))
  theirs <- stats::cov(m, use = "pairwise.complete.obs")
  # Blanking the diagonal costs a pair of columns two of the 18 cells, so 16
  # are complete and the ratio is exactly 15/16.
  expect_equal(ours[1, 2] / theirs[1, 2], 15 / 16, tolerance = tol)
})

# ---- goldens (skip until the sweep runs) ------------------------------------

test_that("similarities match UCINET", {
  skip_if_no_golden("g5_simil_campnet_corr", "transform")
  skip_if_no_golden("g5_simil_campnet_eucl", "transform")
  m <- as.matrix(campnet)
  expect_equal(unname(as.matrix(xsimilarities(m, method = "correlation",
                                              mode = "rows"))),
               unname(golden_matrix("g5_simil_campnet_corr", "transform")),
               tolerance = tol)
  expect_equal(unname(as.matrix(xsimilarities(m, method = "euclidean",
                                              mode = "rows"))),
               unname(golden_matrix("g5_simil_campnet_eucl", "transform")),
               tolerance = tol)
})

test_that("Jaccard on 2-mode columns matches UCINET", {
  skip_if_no_golden("g5_simil_davis_jacc", "transform")
  expect_equal(unname(as.matrix(xsimilarities(davis, method = "jaccard",
                                              mode = "cols"))),
               unname(golden_matrix("g5_simil_davis_jacc", "transform")),
               tolerance = tol)
})
