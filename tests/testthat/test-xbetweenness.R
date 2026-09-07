# xbetweenness against UCINET 6.849.
#
# The fixtures are the CLI betw(), which returns the same Betweenness column the
# Freeman Betweenness menu routine does: runbetweenness2 passes issymmetric to
# getbetweenness, XFreeBet passes false and halves afterwards, and the two agree.
# Fixtures are stored as singles, hence 1e-5 rather than 1e-6 here.

tol <- 1e-5

disc <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_disc"))
iso  <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))

test_that("betweenness matches UCINET on directed, symmetric and valued data", {
  cases <- list(list("G9_BET_CAMPNET", campnet),
                list("G9_BET_DISC",    disc()),
                list("G9_BET_ISO",     iso()),
                list("G9_BET_BAKER",   baker_journals))
  for (case in cases) {
    skip_if_no_golden(case[[1]], "centrality")
    gold <- as.vector(golden_matrix(case[[1]], "centrality"))
    expect_equal(xbetweenness(case[[2]])$nodes$Betweenness, gold,
                 tolerance = tol, info = case[[1]])
  }
})

test_that("every relation of a multi-relation dataset matches", {
  skip_if_no_golden("G9_BET_SAMPSON", "centrality")
  gold <- golden_matrix("G9_BET_SAMPSON", "centrality")
  expect_equal(ncol(gold), 10)
  for (k in seq_len(ncol(gold))) {
    expect_equal(xbetweenness(sampson, relation = k)$nodes$Betweenness,
                 unname(gold[, k]), tolerance = tol,
                 info = colnames(gold)[k])
  }
})

test_that("the normalized column is a percentage of the un-halved count", {
  # The trap: UCINET halves the directed count for symmetric data but
  # normalizes the un-halved one, so nBetweenness is 200*Betweenness/(n-1)(n-2)
  # for a symmetric graph and 100*Betweenness/(n-1)(n-2) for a directed one.
  res <- xbetweenness(campnet)                       # directed
  n <- nrow(res$nodes)
  expect_equal(res$nodes$nBetweenness,
               100 * res$nodes$Betweenness / ((n - 1) * (n - 2)), tolerance = tol)

  sym <- xbetweenness(disc())                        # symmetric
  n <- nrow(sym$nodes)
  expect_equal(sym$nodes$nBetweenness,
               200 * sym$nodes$Betweenness / ((n - 1) * (n - 2)), tolerance = tol)
  # and it is a percentage, so it can exceed 1
  expect_true(max(res$nodes$nBetweenness) > 1)
})

test_that("isolates and unreachable pairs give zero, not missing", {
  res <- xbetweenness(iso())
  expect_false(anyNA(res$nodes$Betweenness))
  # Six zeros: the three isolates, the two ends of the core path, and n3, which
  # the chord n2-n4 routes around so that it lies on no shortest path at all.
  expect_equal(sum(res$nodes$Betweenness == 0), 6)
  expect_equal(res$nodes$Betweenness[c(1, 3, 7, 8, 9, 10)], rep(0, 6))
})

test_that("centralization follows XFreeBet's two-step formula", {
  res <- xbetweenness(campnet)
  b <- res$nodes$Betweenness
  n <- length(b)
  expect_equal(res$summary$`Un-normalized centralization`,
               sum(max(b) - b), tolerance = tol)
  # 200 * raw / ((n-1)^2 (n-2)), halved again because campnet is directed
  expect_equal(res$summary$`Network Centralization Index (%)`,
               (200 * sum(max(b) - b) / ((n - 1)^2 * (n - 2))) / 2,
               tolerance = tol)
})

test_that("the report prints the statistics block, unlike degree", {
  # XFreeBet.pas prints DESCRIPTIVE STATISTICS FOR EACH MEASURE;
  # uc_DegreeCentrality.pas does not. The routine decides, not the printer.
  out <- capture.output(print(xbetweenness(campnet)))
  expect_true(any(grepl("DESCRIPTIVE STATISTICS FOR EACH MEASURE", out)))
  expect_false(any(grepl("DESCRIPTIVE STATISTICS",
                         capture.output(print(xdegree(campnet))))))
})

test_that("a valued matrix is treated as the graph underneath it", {
  # copyfromtmat dichotomises at > 0, so betweenness never sees the values.
  expect_equal(xbetweenness(baker_journals)$nodes$Betweenness,
               xbetweenness(dichotomize(as.matrix(baker_journals)))$nodes$Betweenness,
               tolerance = tol)
  expect_true(any(grepl("dichotomized", xbetweenness(baker_journals)$assumptions)))
})

test_that("brandes agrees with a definition-based count on a small graph", {
  # A five-node path: 1-2-3-4-5. Node 3 lies on 1-4, 1-5, 2-4, 2-5, 1-3? no -
  # betweenness counts pairs strictly either side, so 3 is on {1,2} x {4,5} = 4
  # unordered pairs, node 2 on {1} x {3,4,5} = 3, node 4 the same by symmetry.
  a <- matrix(0, 5, 5)
  for (i in 1:4) { a[i, i + 1] <- 1; a[i + 1, i] <- 1 }
  dimnames(a) <- list(letters[1:5], letters[1:5])
  expect_equal(xbetweenness(a)$nodes$Betweenness, c(0, 3, 4, 3, 0))
})
