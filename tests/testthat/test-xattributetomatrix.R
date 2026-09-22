# Attribute to matrix (chapter 5, section 5.6).
#
# Ten methods from uattributetomatrix.pas. Each is small enough to work out by
# hand on four nodes, which is what most of these do.

tol <- 1e-6

# Two nodes share a value, so "same" and "minmax" both have a tie to find.
four <- function() c(alice = 1, bob = 2, carol = 2, dan = 5)

cell <- function(method, i = "alice", j = "bob", ...) {
  as.matrix(xattributetomatrix(four(), method = method, ...))[i, j]
}

test_that("same is 1 where the values agree", {
  m <- as.matrix(xattributetomatrix(four(), method = "same"))
  expect_equal(m["bob", "carol"], 1)
  expect_equal(m["alice", "bob"], 0)
  expect_equal(diag(m), c(alice = 1, bob = 1, carol = 1, dan = 1))
})

test_that("the arithmetic methods are their formulas", {
  expect_equal(cell("diff"), 1 - 2)
  expect_equal(cell("absdiff"), 1)
  expect_equal(cell("sqrdiff"), 1)
  expect_equal(cell("product"), 2)
  expect_equal(cell("sum"), 3)
  # identity coefficient: 2 a_i a_j / (a_i^2 + a_j^2) = 4/5
  expect_equal(cell("identity"), 0.8)
  # minmax: the smaller over the larger
  expect_equal(cell("minmax"), 1 / 2)
})

test_that("minmax is 1 wherever the two values are equal", {
  # getvalue() returns 1.0 on samevalue() before it divides, so a pair of
  # zeros comes back 1 rather than NaN.
  m <- as.matrix(xattributetomatrix(c(a = 0, b = 0, c = 3), method = "minmax"))
  expect_equal(m["a", "b"], 1)
  expect_equal(m["a", "c"], 0)
})

test_that("diff is the only asymmetric arithmetic method", {
  expect_equal(cell("diff", "alice", "bob"), -1)
  expect_equal(cell("diff", "bob", "alice"), 1)
  for (meth in c("same", "absdiff", "sqrdiff", "product", "sum", "identity",
                 "minmax")) {
    m <- as.matrix(xattributetomatrix(four(), method = meth))
    expect_equal(m, t(m), info = meth)
  }
})

test_that("receiver copies the attribute across every row", {
  # duplicatedrows: m[i,j] := a[j], so cell (i,j) holds the value of j - what
  # a QAP regression wants for a receiver effect.
  m <- as.matrix(xattributetomatrix(four(), method = "receiver"))
  for (i in rownames(m)) expect_equal(unname(m[i, ]), unname(four()), info = i)
})

test_that("sender copies the attribute down every column", {
  # duplicatedcols: m[i,j] := a[i].
  m <- as.matrix(xattributetomatrix(four(), method = "sender"))
  for (j in colnames(m)) expect_equal(unname(m[, j]), unname(four()), info = j)
})

test_that("the three asymmetric methods come back directed", {
  for (meth in c("diff", "receiver", "sender")) {
    expect_true(xattributetomatrix(four(), method = meth)$directed, info = meth)
  }
  for (meth in c("same", "absdiff", "sqrdiff", "product", "sum", "identity",
                 "minmax")) {
    expect_false(xattributetomatrix(four(), method = meth)$directed, info = meth)
  }
})

test_that("normalize is applied to the attribute before anything else", {
  a <- four()
  mu <- mean(a)
  sdev <- sqrt(mean((a - mu)^2))
  # centring shifts both values, so a difference is unchanged
  expect_equal(cell("diff", normalize = "center"), -1)
  # but a product is not
  expect_equal(cell("product", normalize = "center"),
               unname((a[["alice"]] - mu) * (a[["bob"]] - mu)))
  expect_equal(cell("product", normalize = "standardize"),
               unname(((a[["alice"]] - mu) / sdev) * ((a[["bob"]] - mu) / sdev)))
})

test_that("standardize uses the population standard deviation", {
  # tunivariate computes variance as mcssq/sumwt, dividing by n; the sample
  # form is a separate field (estsd) that normalizeattribute does not use.
  a <- four()
  mu <- mean(a)
  pop <- sqrt(mean((a - mu)^2))
  samp <- stats::sd(a)
  expect_false(isTRUE(all.equal(pop, samp)))
  expect_equal(cell("product", normalize = "standardize"),
               unname(((a[["alice"]] - mu) / pop) * ((a[["bob"]] - mu) / pop)))
})

test_that("a missing value gives a missing row and column", {
  a <- four()
  a[["bob"]] <- NA
  m <- as.matrix(xattributetomatrix(a, method = "same"))
  expect_true(all(is.na(m["bob", ])))
  expect_true(all(is.na(m[, "bob"])))
  expect_equal(m["alice", "carol"], 0)   # the rest is unaffected
})

test_that("a categorical attribute works for same and is refused elsewhere", {
  g <- c(alice = "F", bob = "M", carol = "F", dan = "M")
  m <- as.matrix(xattributetomatrix(g, method = "same"))
  expect_equal(m["alice", "carol"], 1)
  expect_equal(m["alice", "bob"], 0)
  expect_error(xattributetomatrix(g, method = "diff"), "numeric attribute")
  expect_error(xattributetomatrix(factor(g), method = "product"), "a factor")
})

test_that("an attribute can be named as a column of the network's table", {
  f <- system.file("schema", "campnet-example.uci", package = "xucinet")
  net <- xreaduci(f)
  m <- xattributetomatrix("Gender", net = net, method = "same")
  expect_equal(dim(as.matrix(m)), c(18, 18))
  expect_equal(rownames(as.matrix(m)), rownames(as.matrix(net)))
  expect_error(xattributetomatrix("Nope", net = net), "no attribute called")
})

test_that("an attribute can be named as a column of a data frame", {
  d <- data.frame(g = c(1, 2, 2), row.names = c("a", "b", "c"))
  m <- as.matrix(xattributetomatrix("g", data = d, method = "same"))
  expect_equal(rownames(m), c("a", "b", "c"))
  expect_equal(m["b", "c"], 1)
})

test_that("labels come from the vector, or from the network", {
  expect_equal(rownames(as.matrix(xattributetomatrix(four()))), names(four()))
  a <- unname(four())
  expect_equal(rownames(as.matrix(xattributetomatrix(a))),
               c("1", "2", "3", "4"))
})

test_that("a length mismatch is an error that counts both sides", {
  expect_error(xattributetomatrix(c(1, 2), net = campnet), "18 nodes")
})

test_that("xattributetomatrix names the dataset as getextension does", {
  # the method's suffix with the attribute's name glued on
  f <- system.file("schema", "campnet-example.uci", package = "xucinet")
  net <- xreaduci(f)
  expect_equal(xattributetomatrix("Gender", net = net)$title,
               "campnet-sameGender")
  expect_equal(xattributetomatrix("Gender", net = net, method = "absdiff")$title,
               "campnet-absdiffGender")
  expect_equal(xattributetomatrix("Role", net = net, method = "sender")$title,
               "campnet-senderRole")
})

test_that("the result is a 1-mode dataset", {
  m <- xattributetomatrix(four())
  expect_s3_class(m, "xucinet")
  expect_equal(m$mode, "1-mode")
})

# ---- goldens (skip until the sweep runs) ------------------------------------

test_that("attribute to matrix matches UCINET", {
  skip_if_no_golden("g5_attr_camp92_same", "transform")
  skip_if_no_golden("g5_attr_camp92_absdiff", "transform")
  g <- camp92_attr$Gender
  names(g) <- rownames(camp92_attr)
  expect_equal(unname(as.matrix(xattributetomatrix(g, method = "same"))),
               unname(golden_matrix("g5_attr_camp92_same", "transform")),
               tolerance = tol)
  expect_equal(unname(as.matrix(xattributetomatrix(g, method = "absdiff"))),
               unname(golden_matrix("g5_attr_camp92_absdiff", "transform")),
               tolerance = tol)
})
