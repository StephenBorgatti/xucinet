# xdegree against UCINET 6.849.
#
# Two fixtures, from the two surfaces, because they do not report the same
# thing (UCINET issue 4). g9m_deg_campnet is the Degree menu routine, which is
# what our $nodes reproduces; G9_DEG_CAMPNET is the CLI degree() function, whose
# extra symmetrized column is a useful independent check on our row sums.

tol <- 1e-6

test_that("the node table matches the Degree menu routine", {
  skip_if_no_golden("g9m_deg_campnet", "centrality")
  gold <- golden_matrix("g9m_deg_campnet", "centrality")
  res <- xdegree(campnet)

  expect_identical(colnames(gold), c("Outdeg", "Indeg", "nOutdeg", "nIndeg"))
  expect_identical(names(res$nodes), colnames(gold))
  expect_identical(rownames(res$nodes), rownames(gold))
  for (col in colnames(gold)) {
    expect_equal(res$nodes[[col]], unname(gold[, col]), tolerance = tol)
  }
})

test_that("graph centralization matches, as a proportion not a percentage", {
  skip_if_no_golden("campnet-degcz", "centrality")
  gold <- golden_matrix("campnet-degcz", "centrality")
  res <- xdegree(campnet)

  expect_equal(res$summary$`Out-Centralization`,
               unname(gold[1, "Out-Centralization"]), tolerance = tol)
  expect_equal(res$summary$`In-Centralization`,
               unname(gold[1, "In-Centralization"]), tolerance = tol)
  # campnet is fixed-choice - everyone names three - so out-centralization is
  # exactly zero, and in-centralization is (18*5 - 54) / (18-1)^2.
  expect_equal(res$summary$`Out-Centralization`, 0)
  expect_equal(res$summary$`In-Centralization`, 36 / 289, tolerance = tol)
})

test_that("the CLI degree() agrees where the two surfaces overlap", {
  skip_if_no_golden("G9_DEG_CAMPNET", "centrality")
  gold <- golden_matrix("G9_DEG_CAMPNET", "centrality")
  res <- xdegree(campnet)

  expect_equal(res$nodes$Outdeg, unname(gold[, "Outdegree"]), tolerance = tol)
  expect_equal(res$nodes$Indeg,  unname(gold[, "Indegree"]),  tolerance = tol)
  # The CLI's extra "Degree" column is the symmetrized degree, which is what we
  # return when directed = FALSE.
  sym <- xdegree(campnet, directed = FALSE)
  expect_equal(sym$nodes$Degree, unname(gold[, "Degree"]), tolerance = tol)
})

test_that("normalization divides by maxval * (n - 1)", {
  skip_if_no_golden("G9_DEGN_CAMPNET", "centrality")
  gold <- golden_matrix("G9_DEGN_CAMPNET", "centrality")
  res <- xdegree(campnet)

  expect_equal(res$nodes$nOutdeg, unname(gold[, "Outdegree"]), tolerance = tol)
  expect_equal(res$nodes$nIndeg,  unname(gold[, "Indegree"]),  tolerance = tol)
  expect_equal(res$nodes$nOutdeg, res$nodes$Outdeg / 17, tolerance = tol)
})

test_that("valued data sums values, and normalizes by the largest of them", {
  skip_if_no_golden("G9_DEG_BAKER", "centrality")
  gold <- golden_matrix("G9_DEG_BAKER", "centrality")
  res <- xdegree(baker_journals)
  m <- as.matrix(baker_journals)
  diag(m) <- 0

  expect_equal(res$nodes$Outdeg, unname(gold[, "Outdegree"]), tolerance = tol)
  expect_equal(res$nodes$Outdeg, unname(rowSums(m)), tolerance = tol)
  # Weighted normalization is UCINET's default, so the denominator carries the
  # largest cell value; on binary data it collapses to n - 1.
  expect_equal(res$nodes$nOutdeg,
               res$nodes$Outdeg / (max(as.matrix(baker_journals)) * 19),
               tolerance = tol)
})

test_that("weighted = FALSE dichotomizes first", {
  res <- xdegree(baker_journals, weighted = FALSE)
  m <- dichotomize(as.matrix(baker_journals))
  diag(m) <- 0
  expect_equal(res$nodes$Outdeg, unname(rowSums(m)), tolerance = tol)
  expect_equal(res$nodes$nOutdeg, res$nodes$Outdeg / 19, tolerance = tol)
  expect_true(any(grepl("dichotomized", res$assumptions)))
})

test_that("symmetric data gives two columns and one centralization", {
  skip_if_no_golden("G9_DEG_DISC", "centrality")
  res <- xdegree(xreaducinet(file.path(goldens_dir("centrality"), "g9_disc")))
  expect_identical(names(res$nodes), c("Degree", "nDegree"))
  expect_identical(names(res$summary), "Centralization")
  # Freeman's denominator for a symmetric graph is (n-1)(n-2), not (n-1)^2.
  d <- res$nodes$Degree
  n <- length(d)
  expect_equal(res$summary$Centralization,
               (n * max(d) - sum(d)) / ((n - 1) * (n - 2)), tolerance = tol)
})

test_that("isolates come back as zeros rather than as missing", {
  skip_if_no_golden("G9_DEG_ISO", "centrality")
  gold <- golden_matrix("G9_DEG_ISO", "centrality")
  res <- xdegree(xreaducinet(file.path(goldens_dir("centrality"), "g9_iso")))
  expect_equal(res$nodes$Degree, unname(gold[, 1]), tolerance = tol)
  expect_equal(sum(res$nodes$Degree == 0), 3)
  expect_false(anyNA(res$nodes$Degree))
})

test_that("the printed table reproduces UCINET's layout", {
  # Landmarks rather than bytes, and against the CLI log rather than
  # log_menu.txt, because that file is a paste: its Degree block sits one
  # character left of what UCINET wrote, so a byte comparison would be a
  # comparison against a typo. UCINET's own log echoes commands as well as
  # output, so the paste was never needed; when those four menu runs are
  # repeated and the real log saved, this test should become a byte-for-byte
  # comparison of the whole block, which is the stronger check.
  skip_if_no_golden("g9m_deg_campnet", "centrality")
  out <- capture.output(print(xdegree(campnet)))

  expect_true(any(out == "Degree Measures"))
  expect_true(any(out == "Graph Centralization -- as proportion, not percentage"))
  # Three decimals everywhere, including the integer columns, because a node
  # table is not stored as a table: see format_uci_matrix().
  expect_match(out[grep("HOLLY", out)], "3[.]000")
  # No descriptive-statistics block: uc_DegreeCentrality.pas prints none.
  expect_false(any(grepl("DESCRIPTIVE STATISTICS", out)))
})

test_that("sort is a printing choice and does not move the statistics", {
  res <- xdegree(campnet)
  plain  <- capture.output(print(res))
  sorted <- capture.output(print(res, sort = "Indeg"))

  expect_false(identical(plain, sorted))
  expect_identical(rownames(res$nodes)[1], "HOLLY")     # object unchanged
  expect_equal(grep("BILL", sorted)[1] > grep("PAM", sorted)[1], TRUE)
  expect_error(print(res, sort = "nosuchcolumn"), "must name a column")
})

test_that("a rectangular matrix is refused, and says what to use instead", {
  expect_error(xdegree(davis), "square")
})
