# Homophily and mixing by groups (chapter 10, section 10.5).

tol <- 1e-8

# Two groups of two, tied only within: perfect homophily.
homo4 <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", "b"] <- m["b", "a"] <- 1
  m["c", "d"] <- m["d", "c"] <- 1
  m
}

# The same four nodes tied only across: perfect heterophily.
hetero4 <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", "c"] <- m["c", "a"] <- 1
  m["b", "d"] <- m["d", "b"] <- 1
  m
}

pair <- function() c(a = 1, b = 1, c = 2, d = 2)

gender <- function() {
  g <- camp92_attr$Gender
  names(g) <- rownames(camp92_attr)
  g
}

# ---- xhomophily --------------------------------------------------------------

test_that("the report is UCINET's seven measures in its order", {
  s <- xhomophily(campnet, gender())$summary
  expect_equal(names(s), c("H", "h-star", "Corr", "Modul Q", "Assort",
                           "Yules Q", "E-I Index"))
})

test_that("H and the E-I index are opposite ends of the same ratio", {
  s <- xhomophily(homo4(), pair())$summary
  expect_equal(s[["H"]], 1)
  expect_equal(s[["E-I Index"]], -1)

  s2 <- xhomophily(hetero4(), pair())$summary
  expect_equal(s2[["H"]], 0)
  expect_equal(s2[["E-I Index"]], 1)
})

test_that("h-star takes the group sizes off H", {
  # Without the diagonal the chance share is sum n_k(n_k - 1) / N(N - 1).
  s <- xhomophily(homo4(), pair())$summary
  expected <- (2 * 1 + 2 * 1) / (4 * 3)
  expect_equal(s[["h-star"]], 1 - expected)
})

test_that("assortativity and modularity see the structure", {
  s <- xhomophily(homo4(), pair())$summary
  expect_equal(s[["Assort"]], 1)
  expect_true(s[["Modul Q"]] > 0)
  # a network tied only across groups has negative assortativity
  expect_true(xhomophily(hetero4(), pair())$summary[["Assort"]] < 0)
})

test_that("Yule's Q is the two-by-two of tie against sameness", {
  # Perfect homophily: every tie is within, every non-tie across or within.
  s <- xhomophily(homo4(), pair())$summary
  expect_equal(s[["Yules Q"]], 1)
  expect_equal(xhomophily(hetero4(), pair())$summary[["Yules Q"]], -1)
})

test_that("weighted changes only the mixing matrix, as calcwhomophily does", {
  # `wt := net.cell[i,j]` is unconditional for the internal and external
  # totals; treatvalued branches only when filling mrs.
  a <- xhomophily(camp92, gender(), weighted = TRUE)
  b <- xhomophily(camp92, gender(), weighted = FALSE)
  for (k in c("H", "h-star", "Corr", "Yules Q", "E-I Index")) {
    expect_equal(a$summary[[k]], b$summary[[k]], info = k)
  }
  # but the mixing matrix, and so assortativity, do change
  expect_false(isTRUE(all.equal(a$matrices$Mixing, b$matrices$Mixing)))
})

test_that("the mixing matrix totals the ties", {
  mx <- xhomophily(campnet, gender())$matrices$Mixing
  expect_equal(sum(mx), sum(as.matrix(campnet)))
  expect_equal(dim(mx), c(2L, 2L))
})

test_that("direction can be ignored", {
  a <- xhomophily(campnet, gender())
  b <- xhomophily(campnet, gender(), directed = FALSE)
  expect_false(isTRUE(all.equal(a$summary[["H"]], b$summary[["H"]])))
  expect_true(any(grepl("Direction of ties ignored", b$assumptions)))
})

test_that("a partition of the wrong length is an error", {
  expect_error(xhomophily(campnet, c(1, 2)), "18 nodes")
})

test_that("xhomophily refuses 2-mode data", {
  expect_error(xhomophily(davis, rep(1, 18)), "1-mode")
})

test_that("the report prints", {
  expect_snapshot(xhomophily(campnet, gender()))
})

# ---- xdensitybygroups --------------------------------------------------------

test_that("four tables come back", {
  d <- xdensitybygroups(campnet, gender())
  expect_equal(names(d$matrices), c("Density", "Observed", "Expected", "Ratio"))
})

test_that("the density table is the one xcombinenodes gives", {
  # getdensitymatrix is aggbygroups with its default mean, which is the same
  # call xcombinenodes makes.
  expect_equal(unname(xdensitybygroups(campnet, gender())$matrices$Density),
               unname(as.matrix(xcombinenodes(campnet, gender()))),
               tolerance = tol)
})

test_that("the observed table totals the ties, for directed data", {
  obs <- xdensitybygroups(campnet, gender())$matrices$Observed
  expect_equal(sum(obs), sum(as.matrix(campnet)))
})

test_that("the density model preserves the total, for directed data", {
  # E[r,s] sums to d * n(n-1), which is the number of ties.
  d <- xdensitybygroups(campnet, gender())
  expect_equal(sum(d$matrices$Expected), sum(d$matrices$Observed),
               tolerance = 1e-6)
})

test_that("the ratio is observed over expected", {
  d <- xdensitybygroups(campnet, gender())
  expect_equal(d$matrices$Ratio, d$matrices$Observed / d$matrices$Expected,
               tolerance = tol)
})

test_that("homophily shows up as a within-group ratio above one", {
  d <- xdensitybygroups(campnet, gender())
  expect_true(all(diag(d$matrices$Ratio) > 1))
  expect_true(all(d$matrices$Ratio[upper.tri(d$matrices$Ratio)] < 1))
})

test_that("undirected counts each edge once and mirrors the blocks", {
  d <- xdensitybygroups(campnet, gender(), directed = FALSE)
  obs <- d$matrices$Observed
  expect_equal(obs, t(obs))
  m <- pmax(as.matrix(campnet), t(as.matrix(campnet)))
  # the within-group blocks hold the within-group edges
  expect_equal(sum(diag(obs)), sum(m[upper.tri(m)] *
    outer(gender(), gender(), "==")[upper.tri(m)]))
  expect_true(any(grepl("Symmetrized", d$assumptions)))
})

test_that("test = TRUE says where the permutation engine is", {
  expect_error(xdensitybygroups(campnet, gender(), test = TRUE), "chapter 14")
})

test_that("the two unported expected models say so", {
  for (mod in c("configuration", "fixedout")) {
    expect_error(xdensitybygroups(campnet, gender(), model = mod),
                 "not ported yet", info = mod)
  }
})

test_that("an attribute can be named as a column", {
  f <- system.file("schema", "campnet-example.uci", package = "xucinet")
  net <- xreaduci(f)
  expect_equal(dim(xdensitybygroups(net, "Gender")$matrices$Density), c(2L, 2L))
  expect_equal(dim(xhomophily(net, "Gender")$matrices$Mixing), c(2L, 2L))
})

test_that("xdensitybygroups refuses 2-mode data", {
  expect_error(xdensitybygroups(davis, rep(1, 18)), "1-mode")
})
