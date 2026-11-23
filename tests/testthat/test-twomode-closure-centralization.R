# 2-mode transitivity (xucinet#55) and 2-mode centralization (xucinet#56).
# UCINET has neither (DIFFERENCES 52 and 53), so the checks are against hand
# counts, brute force and the extremal graphs, not against goldens.

test_that("2-mode transitivity is Robins-Alexander closure on davis", {
  s <- xtransitivity(davis)$summary
  expect_equal(names(s), c("4-Cycles", "3-Paths", "Transitivity", "Density",
                           "Ratio", "Transitivity Index"))
  expect_equal(s[["4-Cycles"]], 341)
  expect_equal(s[["3-Paths"]], 2916)
  expect_equal(s$Transitivity, 4 * 341 / 2916)
  expect_equal(s$Density, 89 / (18 * 14))
})

test_that("2-mode transitivity agrees with brute-force enumeration", {
  set.seed(3)
  x <- matrix(rbinom(6 * 5, 1, 0.5), 6, 5,
              dimnames = list(paste0("r", 1:6), paste0("c", 1:5)))
  paths <- 0; closed <- 0
  for (i in 1:6) for (v in which(x[i, ] == 1)) {
    for (j in setdiff(which(x[, v] == 1), i)) for (w in setdiff(which(x[j, ] == 1), v)) {
      paths <- paths + 1
      if (x[i, w] == 1) closed <- closed + 1
    }
  }
  s <- xtransitivity(as_xucinet(x))$summary
  expect_equal(s[["3-Paths"]], paths)
  expect_equal(4 * s[["4-Cycles"]], closed)
  # the same paths and cycles seen from the other mode
  expect_equal(xtransitivity(as_xucinet(t(x)))$summary, s, ignore_attr = TRUE)
})

test_that("2-mode transitivity dichotomizes valued data and says so", {
  x <- as.matrix(davis) * 3
  r <- xtransitivity(as_xucinet(x))
  expect_equal(r$summary$Transitivity, xtransitivity(davis)$summary$Transitivity)
  expect_true(any(grepl("dichotomized", r$assumptions)))
})

test_that("1-mode transitivity is unchanged", {
  s <- xtransitivity(campnet)$summary
  expect_equal(s$Threes, 60)
  expect_equal(s$Twos, 124)
})

test_that("2-mode degree centralization by hand on davis", {
  s <- xdegree(davis)$summary
  # rows: (18 x 8 - 89) / 14 / 17; columns: max degree 14 of 18
  expect_equal(s[["Row Centralization"]], (18 * 8 - 89) / 14 / 17)
  expect_equal(s[["Column Centralization"]], (14 * 14 - 89) / 18 / 13)
})

test_that("the bipartite star is fully centralized in its own mode", {
  st <- xucinet:::bipartite_star(6, 4)
  dimnames(st) <- list(paste0("r", 1:6), paste0("c", 1:4))
  net <- as_xucinet(st)
  expect_equal(xbetweenness(net)$summary[["Row Centralization Index (%)"]], 100)
  expect_equal(xcloseness(net)$summary[["Row Centralization (%)"]], 100)
})

test_that("degree and eigenvector reach 1 with one node tied to everything", {
  x <- matrix(0, 4, 3, dimnames = list(paste0("r", 1:4), paste0("c", 1:3)))
  x[1, ] <- 1
  net <- as_xucinet(x)
  expect_equal(xdegree(net)$summary[["Row Centralization"]], 1)
  expect_equal(xeigenvector(net)$summary[["Row eigenvector centralization (%)"]], 100)
  # disconnected: closeness centralization is missing, as in 1-mode
  expect_true(is.na(xcloseness(net)$summary[["Row Centralization (%)"]]))
})

test_that("no bipartite graph up to 3 x 3 exceeds the denominators", {
  ts <- xucinet:::twomode_scores
  for (k in 0:(2^9 - 1)) {
    m <- matrix(as.integer(intToBits(k))[1:9], 3, 3)
    for (meas in c("Degree", "Betweenness", "Closeness", "Eigenvector")) {
      cz <- suppressWarnings(xucinet:::twomode_centralization(m, meas))
      expect_true(all(is.na(cz) | cz <= 1 + 1e-9))
    }
  }
})

test_that("xcentralization reads the 2-mode figures", {
  s <- xcentralization(davis)$summary
  expect_length(s, 8)
  expect_false(anyNA(unlist(s)))
  expect_equal(s[["Row Centralization"]], xdegree(davis)$summary[["Row Centralization"]])
  # summary does not depend on `mode`
  expect_equal(xdegree(davis, mode = "rows")$summary, xdegree(davis)$summary)
})
