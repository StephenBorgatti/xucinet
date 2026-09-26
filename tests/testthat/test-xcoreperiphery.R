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

# ---- 2-mode (x2mcatcp.pas; Steve, 26 Sep 2026, issue #25) -----------------------

# The model's fit written out: correlation of the data with 1 in the row-core
# by column-core cells and 0 in the row-periphery by column-periphery cells.
cp2_corr <- function(a, rp, cp) {
  core <- outer(rp == 1, cp == 1, `&`); peri <- outer(rp == 2, cp == 2, `&`)
  stats::cor(c(rep(1, sum(core)), rep(0, sum(peri))), c(a[core], a[peri]))
}

test_that("2-mode: rows then columns, a class each, and cores of 3 to n - 3", {
  r <- xcoreperiphery(davis, seed = 1)
  a <- as.matrix(davis)
  expect_equal(rownames(r$nodes), c(rownames(a), colnames(a)))
  expect_equal(r$nodes$Mode, rep(c("row", "col"), c(18, 14)))
  expect_true(all(r$nodes$Class %in% 1:2))
  expect_true(r$summary[["Row core"]] >= 3 && r$summary[["Row core"]] <= 15)
  expect_true(r$summary[["Col core"]] >= 3 && r$summary[["Col core"]] <= 11)
})

test_that("2-mode: the fit is the correlation with the ideal, and no flip improves it", {
  a <- as.matrix(davis)
  r <- xcoreperiphery(davis, seed = 1)
  p <- r$nodes$Class
  rp <- p[1:18]; cp <- p[18 + 1:14]
  expect_equal(r$summary[["Categorical fit"]], cp2_corr(a, rp, cp))
  expect_lt(r$summary[["Auxiliary passes"]], 6)    # stopped because nothing moved
  for (u in seq_along(p)) {
    q <- p; q[u] <- 3L - q[u]
    qr <- q[1:18]; qc <- q[18 + 1:14]
    if (sum(qr == 1) < 3 || sum(qr == 1) > 15 || sum(qc == 1) < 3 || sum(qc == 1) > 11) next
    expect_lte(cp2_corr(a, qr, qc), r$summary[["Categorical fit"]] + 1e-12)
  }
})

test_that("2-mode: a planted core is found exactly", {
  a <- matrix(0, 10, 8, dimnames = list(paste0("r", 1:10), paste0("c", 1:8)))
  a[1:4, 1:3] <- 1          # the core block
  a[9, 2] <- 1              # a mixed-block tie, which the model ignores
  r <- xcoreperiphery(as_xucinet(a, mode = "2-mode"), seed = 2)
  # Any three or more of the four core rows fit perfectly, so the test is the
  # fit and that both cores come from the planted block.
  expect_equal(r$summary[["Categorical fit"]], 1)
  expect_true(all(which(r$nodes$Class[1:10] == 1) %in% 1:4))
  expect_true(all(which(r$nodes$Class[10 + 1:8] == 1) %in% 1:3))
})

test_that("2-mode: the density table counts every cell", {
  # UCINET's blockdensity leaves out cells whose row and column numbers are
  # equal, a 1-mode rule (UCINET issue 34, item 4).
  a <- as.matrix(davis)
  r <- xcoreperiphery(davis, seed = 1)
  p <- r$nodes$Class; rp <- p[1:18]; cp <- p[18 + 1:14]
  expect_equal(r$matrices[["Density matrix"]]["Core", "Core"], mean(a[rp == 1, cp == 1]))
  expect_equal(r$matrices[["Density matrix"]]["Periphery", "Core"], mean(a[rp == 2, cp == 1]))
})

test_that("2-mode: the seed reproduces the run; the continuous model is refused", {
  expect_identical(xcoreperiphery(davis, seed = 4)$nodes,
                   xcoreperiphery(davis, seed = 4)$nodes)
  expect_error(xcoreperiphery(davis, type = "continuous"), "only the categorical")
  small <- as_xucinet(matrix(1, 5, 7), mode = "2-mode")
  expect_error(xcoreperiphery(small), "at least six rows and six columns")
})

test_that("2-mode: the start scores 0 when the data are constant in the scored cells", {
  # UCINET scores an undefined correlation as its missing-value code, the
  # largest fitness there is (UCINET issue 34, item 5).
  a <- matrix(1, 8, 8)
  expect_equal(catcp2_fitness(a, c(rep(1, 4), rep(2, 4), rep(1, 4), rep(2, 4)), 8, 8), 0)
})

test_that("2-mode core/periphery reaches UCINET's fit", {
  # UCINET randomizes, so its partition is compared by fit, not cell by cell.
  skip_if_no_golden("g13_cp2_davis_rows", "twomode")
  skip_if_no_golden("g13_cp2_davis_cols", "twomode")
  a <- as.matrix(davis)
  ucinet <- cp2_corr(a, golden_matrix("g13_cp2_davis_rows", "twomode")[, 1],
                     golden_matrix("g13_cp2_davis_cols", "twomode")[, 1])
  expect_gte(xcoreperiphery(davis, seed = 1)$summary[["Categorical fit"]], ucinet - 1e-9)
})

test_that("the 2-mode report prints", {
  expect_snapshot(xcoreperiphery(davis, seed = 1))
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
