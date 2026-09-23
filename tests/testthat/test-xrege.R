# REGE (chapter 12, sections 12.6-12.7).

tol <- 1e-10

# sStdrege written out loop for loop, to check the vectorized version against.
rege_literal <- function(mats, maxit) {
  n <- nrow(mats[[1]])
  sum_ <- matrix(0, n, n); deg <- numeric(n)
  for (x in mats) for (i in 1:n) for (j in 1:n) if (i != j) {
    sum_[i, j] <- sum_[i, j] + x[i, j]; sum_[j, i] <- sum_[j, i] + x[i, j]
    deg[i] <- deg[i] + x[i, j]; deg[j] <- deg[j] + x[i, j]
  }
  e <- matrix(1, n, n)
  for (i in 1:(n - 1)) for (j in (i + 1):n) {
    e[i, j] <- if (xor(deg[i] > 0, deg[j] > 0)) 0 else 1
    e[j, i] <- e[i, j]
  }
  xmax <- function(k, i, j) {
    best <- 0
    for (m in 1:n) if (sum_[j, m] > 0) {
      int1 <- 0
      for (x in mats) int1 <- int1 + min(x[j, m], x[i, k]) + min(x[m, j], x[k, i])
      v <- if (k > m) e[k, m] * int1 else e[m, k] * int1
      if (v > best) best <- v
    }
    best
  }
  cm <- function(ii, jj) {
    s <- 0
    for (k in 1:n) if (sum_[ii, k] > 0) s <- s + xmax(k, ii, jj)
    for (k in 1:n) if (sum_[jj, k] > 0) s <- s + xmax(k, jj, ii)
    s
  }
  for (it in seq_len(maxit)) {
    for (i in 1:(n - 1)) if (deg[i] > 0) for (j in (i + 1):n)
      if (deg[j] > 0) e[i, j] <- cm(i, j) / (deg[i] + deg[j])
    for (i in 1:(n - 1)) for (j in (i + 1):n) e[j, i] <- e[i, j]
  }
  e
}

test_that("the vectorized iteration is sStdrege, cell for cell", {
  m <- as.matrix(campnet)
  expect_equal(rege_iterate(list(m), 3), rege_literal(list(m), 3), tolerance = tol)
  s <- list(as.matrix(sampson, relation = "Esteem"),
            as.matrix(sampson, relation = "Disesteem"))
  expect_equal(rege_iterate(s, 2), rege_literal(s, 2), tolerance = tol)
})

test_that("regularly equivalent nodes score 1", {
  # Two bosses, each over their own two workers: the bosses are regularly
  # equivalent, and so are all four workers, though they share no one.
  m <- matrix(0, 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  m["a", c("c", "d")] <- 1
  m["b", c("e", "f")] <- 1
  e <- xrege(m)$matrices[[1]]
  expect_equal(e["a", "b"], 1)
  expect_equal(e["c", "f"], 1)
  expect_lt(e["a", "c"], 1)
})

test_that("isolates match each other and nobody else", {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", "b"] <- 1
  e <- xrege(m)$matrices[[1]]
  expect_equal(e["c", "d"], 1)
  expect_equal(e["a", "c"], 0)
})

test_that("the similarities are symmetric, on 0-1, with 1 on the diagonal", {
  e <- xrege(campnet)$matrices[[1]]
  expect_equal(e, t(e))
  expect_true(all(e >= 0 & e <= 1 + 1e-12))
  expect_equal(unname(diag(e)), rep(1, 18))
})

test_that("negative values are refused, missing values are 0", {
  m <- as.matrix(campnet); m[1, 2] <- -1
  expect_error(xrege(m), "negative")
  m[1, 2] <- NA
  r <- xrege(m)
  expect_true(any(grepl("Missing", r$assumptions)))
})

test_that("every relation is used unless some are named", {
  a <- xrege(sampson, relations = c("Esteem", "Disesteem"))$matrices[[1]]
  s <- list(as.matrix(sampson, relation = "Esteem"),
            as.matrix(sampson, relation = "Disesteem"))
  expect_equal(unname(a), rege_iterate(s, 3), tolerance = tol)
})

test_that("more iterations refine, and the clustering is xhclust's", {
  a <- xrege(campnet, iterations = 1)$matrices[[1]]
  b <- xrege(campnet, iterations = 3)$matrices[[1]]
  expect_false(isTRUE(all.equal(a, b)))
  r <- xrege(campnet, k = 2)
  h <- xhclust(r$matrices[[1]], type = "similarities", k = 2, plot = FALSE)
  expect_equal(r$nodes$Cluster, h$nodes$Cluster)
})

test_that("2-mode data are refused, as UCINET does", {
  expect_error(xrege(davis), "1-mode")
})

test_that("the report prints", {
  expect_snapshot(xrege(campnet))
})

test_that("campnet matches UCINET", {
  skip_if_no_golden("g12_rege_campnet", "equivalence")
  expect_equal(unname(xrege(campnet)$matrices[[1]]),
               unname(golden_matrix("g12_rege_campnet", "equivalence")),
               tolerance = 1e-4)
})

test_that("wiring matches UCINET", {
  skip_if_no_golden("g12_rege_wiring", "equivalence")
  expect_equal(unname(xrege(wiring)$matrices[[1]]),
               unname(golden_matrix("g12_rege_wiring", "equivalence")),
               tolerance = 1e-4)
})
