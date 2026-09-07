# xbeta, xpncentrality and xcentrality against UCINET 6.849.

tol <- 1e-5

iso  <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))

# ---- beta centrality --------------------------------------------------------

test_that("beta centrality matches UCINET at an explicit beta", {
  skip_if_no_golden("G9_BETA_CAMPNET", "centrality")
  gold <- as.vector(golden_matrix("G9_BETA_CAMPNET", "centrality"))
  expect_equal(xbeta(campnet, beta = 0.1)$nodes[[1]], gold, tolerance = tol)

  skip_if_no_golden("G9_BETA_ISO", "centrality")
  gold <- as.vector(golden_matrix("G9_BETA_ISO", "centrality"))
  expect_equal(xbeta(iso(), beta = 0.1)$nodes[[1]], gold, tolerance = tol)
})

test_that("the column is named for the beta, as UCINET names it", {
  expect_identical(names(xbeta(campnet, beta = 0.1)$nodes), "B0.10000")
})

test_that("in centrality is the default, and transposes first", {
  # UCINET says "In beta centrality selected. Comparable to indegree."
  res <- xbeta(campnet, beta = 0.1)
  expect_true(any(grepl("In beta centrality", res$assumptions)))
  expect_equal(res$nodes[[1]],
               xbeta(t(as.matrix(campnet)), beta = 0.1,
                     direction = "out")$nodes[[1]], tolerance = tol)
})

test_that("normalization puts the sum of squares at n", {
  v <- xbeta(campnet, beta = 0.1)$nodes[[1]]
  expect_equal(sum(v^2), nrow(as.matrix(campnet)), tolerance = tol)
  raw <- xbeta(campnet, beta = 0.1, normalize = FALSE)$nodes[[1]]
  expect_false(isTRUE(all.equal(sum(raw^2), 18)))
  expect_equal(stats::cor(v, raw), 1, tolerance = tol)
})

test_that("the automatic beta is 0.999 over the largest eigenvalue", {
  # Both confirmed against UCINET's own mcent log, which prints the beta it
  # chose: 0.333 for campnet, whose principal eigenvalue is 3, and
  # 0.426390438228062 for g9_iso, whose principal eigenvalue is 2.34292322433943.
  expect_equal(xbeta(campnet)$summary$Beta, 0.999 / 3, tolerance = tol)
  expect_equal(xbeta(iso())$summary$Beta, 0.4263904, tolerance = 1e-6)
})

# ---- PN centrality ----------------------------------------------------------

test_that("PN centrality matches UCINET", {
  cases <- list(list("G9_PN_CAMPNET",   campnet),
                list("G9_PN_ISO",       iso()),
                list("G9_PN_NEWGUINEA", newguinea))
  for (case in cases) {
    skip_if_no_golden(case[[1]], "centrality")
    gold <- as.vector(golden_matrix(case[[1]], "centrality"))
    expect_equal(xpncentrality(case[[2]])$nodes$PN, gold,
                 tolerance = tol, info = case[[1]])
  }
})

test_that("PN's two constants are UCINET's and are reported", {
  res <- xpncentrality(campnet)
  n <- nrow(as.matrix(campnet))
  expect_equal(res$summary$Beta, -1 / (2 * (n - 1)))
  expect_equal(res$summary$`Negative weight`, 2)
})

test_that("negative ties are doubled before the inverse", {
  # A signed matrix and the same matrix with its negatives already doubled must
  # not give the same answer, or the weight is not being applied.
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m[1, 2] <- m[2, 1] <- 1
  m[3, 4] <- m[4, 3] <- -1
  doubled <- m; doubled[doubled < 0] <- doubled[doubled < 0] * 2
  expect_false(isTRUE(all.equal(xpncentrality(m)$nodes$PN,
                                xpncentrality(doubled)$nodes$PN)))
})

test_that("an all-positive matrix computes but says the measure is off-label", {
  res <- xpncentrality(campnet)
  expect_true(any(grepl("No negative ties", res$assumptions)))
  expect_false(anyNA(res$nodes$PN))
})

# ---- the suite --------------------------------------------------------------

test_that("the suite's columns are UCINET's, in UCINET's order", {
  skip_if_no_golden("G9_MC_ISO", "centrality")
  gold <- golden_matrix("G9_MC_ISO", "centrality")
  expect_identical(names(xcentrality(iso())$nodes), colnames(gold))
})

test_that("the columns that are written match mcent", {
  skip_if_no_golden("G9_MC_ISO", "centrality")
  gold <- golden_matrix("G9_MC_ISO", "centrality")
  ours <- xcentrality(iso())$nodes
  for (cn in c("Degree", "Eigenvector", "Betweenness")) {
    expect_equal(ours[[cn]], unname(gold[, cn]), tolerance = tol, info = cn)
  }
})

test_that("Closeness is closeness, not mcent's farness", {
  # Ledger entry 5. mcent labels the column Closeness and fills it with total
  # distance, which runs the other way; we put xcloseness()'s score there so the
  # suite cannot contradict the routine.
  skip_if_no_golden("G9_MC_ISO", "centrality")
  expect_differs_from_ucinet(issue = 11)
  gold <- golden_matrix("G9_MC_ISO", "centrality")
  ours <- xcentrality(iso())$nodes

  expect_equal(ours$Closeness, xcloseness(iso())$nodes$FreeClo, tolerance = tol)
  expect_false(isTRUE(all.equal(ours$Closeness, unname(gold[, "Closeness"]))))
  # and mcent's column really is the raw distance total with unreachable = n
  m <- as.matrix(iso()); n <- nrow(m)
  d <- geodesics(adjacency(m)); d[is.na(d)] <- n
  expect_equal(unname(gold[, "Closeness"]), unname(rowSums(d)), tolerance = 1e-4)
})

test_that("unwritten measures are NA columns that say what is missing", {
  res <- xcentrality(iso())
  for (cn in c("TwoLocal", "ARD", "TwoStepBet", "2StepReach", "kCoreness",
               "Frag", "DwFrag")) {
    expect_true(all(is.na(res$nodes[[cn]])), info = cn)
  }
  expect_true(any(grepl("Not written yet", res$assumptions)))
  expect_true(any(grepl("k-coreness", res$assumptions)))
})

test_that("directed data gives the paired columns and no eigenvector", {
  res <- xcentrality(campnet)
  expect_true(all(c("OutDegree", "InDegree", "OutCloseness", "InCloseness")
                  %in% names(res$nodes)))
  expect_false("Eigenvector" %in% names(res$nodes))
  expect_equal(res$nodes$OutDegree, xdegree(campnet)$nodes$Outdeg)
})
