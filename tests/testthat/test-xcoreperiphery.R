# Core/periphery (chapter 12, section 12.8; chapter 10.4).

tol <- 1e-8

# An ideal core/periphery network: a clique of four, each tied to all six
# peripheral nodes, which are not tied to each other (Figure 12.9).
ideal <- function() {
  m <- matrix(0, 10, 10, dimnames = list(paste0("a", 1:10), paste0("a", 1:10)))
  m[1:4, ] <- 1; m[, 1:4] <- 1
  diag(m) <- 0
  m
}

baker <- function() xdichotomize(baker_journals)

# ---- layer (a): hand-computed ------------------------------------------------

test_that("an ideal structure is found exactly, with a perfect fit", {
  r <- xcoreperiphery(ideal(), seed = 1)
  expect_equal(r$nodes$Class, c(rep(1L, 4), rep(2L, 6)))
  expect_equal(r$summary[["Categorical fit"]], 1)
})

test_that("the fit is the correlation over the core and periphery blocks", {
  m <- as.matrix(campnet)
  r <- xcoreperiphery(campnet, seed = 1)
  cv <- r$nodes$Class == 1
  x <- y <- numeric(0)
  for (i in 1:18) for (j in 1:18) if (i != j && cv[i] == cv[j]) {
    x <- c(x, cv[i] * 1); y <- c(y, m[i, j])
  }
  expect_equal(r$summary[["Categorical fit"]], cor(x, y), tolerance = tol)
})

test_that("the flip scores are exact, not approximations", {
  m <- as.matrix(campnet); V <- 1 * !is.na(m); diag(V) <- 0; Y <- m * V
  cv <- rep(c(1, 0), 9)
  f <- catcp_fits(cv, V, Y, Y^2, 0.5, NA)
  direct <- vapply(1:18, function(v) {
    cc <- cv; cc[v] <- 1 - cc[v]
    catcp_fits(cc, V, Y, Y^2, 0.5, NA, flips = FALSE)
  }, numeric(1))
  expect_equal(unname(f$flips), direct, tolerance = 1e-10)
})

test_that("off-diagonal densities enter the fit when given", {
  expect_differs_from_ucinet(29)
  a <- xcoreperiphery(campnet, seed = 1)
  b <- xcoreperiphery(campnet, seed = 1, c2p = 1, p2c = 1)
  expect_false(isTRUE(all.equal(a$summary[["Categorical fit"]],
                                b$summary[["Categorical fit"]])))
  expect_true(any(grepl("UCINET issue 29", b$assumptions)))
})

test_that("the seed makes the search reproducible", {
  a <- xcoreperiphery(zachary, seed = 7)
  b <- xcoreperiphery(zachary, seed = 7)
  expect_identical(a$nodes, b$nodes)
  expect_equal(a$seed, 7)
})

test_that("the continuous model's expected values are products of loadings", {
  r <- xcoreperiphery(campnet)
  e <- r$matrices[["Expected Values"]]
  expect_equal(e, t(e))
  l <- sqrt(diag(e))
  expect_equal(unname(r$nodes$Coreness), unname(l / sqrt(sum(l^2))), tolerance = 1e-6)
  expect_equal(sum(r$nodes$Coreness^2), 1)
})

test_that("with the diagonal valid, coreness is the principal eigenvector", {
  # tminres runs a single SVD then; on a symmetric binary network that is the
  # eigenvector of the largest eigenvalue, which xeigenvector reports too.
  u <- xsymmetrize(campnet)
  r <- xcoreperiphery(u, diagonal = TRUE)
  ev <- eigen(as.matrix(u), symmetric = TRUE)$vectors[, 1]
  expect_equal(unname(r$nodes$Coreness), abs(ev), tolerance = 1e-8)
  expect_equal(cor(r$nodes$Coreness, xeigenvector(u)$nodes[[1]]), 1,
               tolerance = 1e-8)
})

test_that("without it, MINRES and the eigenvector differ", {
  # The communality iteration replaces the diagonal, so the scores move away
  # from the eigenvector (ledger entry 35).
  u <- xsymmetrize(campnet)
  a <- xcoreperiphery(u)$nodes$Coreness
  b <- xcoreperiphery(u, diagonal = TRUE)$nodes$Coreness
  expect_gt(max(abs(a - b)), 1e-4)
})

test_that("the concentration picks the core size with the highest correlation", {
  r <- xcoreperiphery(baker(), type = "continuous")
  conc <- r$matrices[["Concentration scores for different sizes of core"]]
  expect_equal(r$summary[["Core size"]], unname(which.max(conc[, "Corr"])))
  expect_equal(sum(r$nodes$InCore), r$summary[["Core size"]])
})

test_that("the gini and heterogeneity are utconcentration's", {
  x <- c(0.1, 0.2, 0.7)
  cc <- concentration_table(matrix(0, 3, 3), x)
  expect_equal(cc$hetero, (sum(x^2) / sum(x)^2 - 1 / 3) / (1 - 1 / 3))
  cy <- cumsum(sort(x) / sum(x))
  expect_equal(cc$gini, 1 - sum((c(0, cy[-3]) + cy) / 3))
})

test_that("Baker's journals reproduce the book's Figure 12.10 and Table 12.2", {
  # 12.8: core density 0.93, periphery 0.04, core to periphery 0.21, periphery
  # to core 0.39; the continuous model recommends the same six journals.
  r <- xcoreperiphery(baker(), seed = 1)
  d <- r$matrices[["Density matrix"]]
  expect_equal(round(d, 2), matrix(c(0.93, 0.39, 0.21, 0.04), 2,
                                   dimnames = dimnames(d)))
  expect_equal(r$nodes$InCore, 2L - r$nodes$Class)
  core <- rownames(r$nodes)[r$nodes$Class == 1]
  expect_setequal(core, c("CW", "JSWE", "SCW", "SSR", "SW", "SWRA"))
})

test_that("type chooses what is printed, not what is returned", {
  a <- xcoreperiphery(campnet, seed = 1)
  b <- xcoreperiphery(campnet, type = "continuous", seed = 1)
  expect_identical(a$nodes, b$nodes)
  expect_identical(a$summary, b$summary)
  expect_equal(a$fit, a$summary[["Categorical fit"]])
  expect_equal(b$fit, b$summary[["Continuous fit"]])
})

test_that("missing cells are left out of the categorical fit", {
  m <- ideal(); m[1, 5] <- NA
  expect_equal(xcoreperiphery(m, seed = 1)$summary[["Categorical fit"]], 1)
})

test_that("2-mode data are refused for now", {
  expect_error(xcoreperiphery(davis), "1-mode")
})

test_that("a 200-node network runs in reasonable time", {
  skip_on_cran()
  set.seed(3)
  m <- matrix(rbinom(200^2, 1, 0.05), 200)
  m[1:20, 1:20] <- 1; diag(m) <- 0
  t0 <- proc.time()[["elapsed"]]
  xcoreperiphery(m, seed = 1)
  expect_lt(proc.time()[["elapsed"]] - t0, 30)
})

test_that("the reports print", {
  expect_snapshot(xcoreperiphery(campnet, seed = 1))
  expect_snapshot(xcoreperiphery(campnet, type = "continuous"))
})

# ---- layer (c): goldens ---------------------------------------------------------

test_that("continuous coreness matches UCINET", {
  skip_if_no_golden("g12_contcp_campnet", "equivalence")
  skip_if_no_golden("g12_contcp_zachary", "equivalence")
  expect_equal(xcoreperiphery(campnet)$nodes$Coreness,
               golden_matrix("g12_contcp_campnet", "equivalence")[, 1],
               tolerance = 1e-4)
  expect_equal(xcoreperiphery(zachary)$nodes$Coreness,
               golden_matrix("g12_contcp_zachary", "equivalence")[, 1],
               tolerance = 1e-4)
})

test_that("categorical core/periphery reaches UCINET's fit", {
  # UCINET randomizes its starts, so the partition may differ where fits tie;
  # the fit it reports is compared from its log (README).
  skip_if_no_golden("g12_catcp_campnet", "equivalence")
  skip_if_no_golden("g12_catcp_zachary", "equivalence")
  g <- golden_matrix("g12_catcp_campnet", "equivalence")[, 1]
  r <- xcoreperiphery(campnet, seed = 1)
  expect_same_partition(r$nodes$Class, g)
})
