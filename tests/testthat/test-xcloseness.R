# xcloseness against UCINET 6.849's Closeness menu routine.
#
# This is the routine SPEC D7 named first among the danger zones, so the tests
# check the conventions as well as the numbers: which measure, which
# substitution for unreachable pairs, which denominator.

tol <- 1e-5

disc <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_disc"))

test_that("all three measures match on a disconnected graph", {
  skip_if_no_golden("g9_clo_disc", "centrality")
  gold <- golden_matrix("g9_clo_disc", "centrality")
  res <- xcloseness(disc())

  expect_identical(colnames(gold), c("FreeClo", "ValClo", "RecipClo"))
  expect_identical(names(res$nodes), colnames(gold))
  for (cn in colnames(gold)) {
    expect_equal(res$nodes[[cn]], unname(gold[, cn]), tolerance = tol, info = cn)
  }
})

test_that("directed data gives six columns, with UCINET's own naming", {
  skip_if_no_golden("g9m_clo_campnet", "centrality")
  gold <- golden_matrix("g9m_clo_campnet", "centrality")
  res <- xcloseness(campnet)

  # Not parallel: the Freeman pair are OutClose/InClose, not OutFreeClo.
  expect_identical(colnames(gold),
                   c("OutClose", "InClose", "OutValClo", "InValClo",
                     "OutRecipClo", "InRecipClo"))
  expect_identical(names(res$nodes), colnames(gold))
  for (cn in colnames(gold)) {
    expect_equal(res$nodes[[cn]], unname(gold[, cn]), tolerance = tol, info = cn)
  }
})

test_that("Freeman substitutes max observed distance plus one by default", {
  # g9_disc has three components and a maximum observed distance of 3, so an
  # unreachable pair counts 4. n1 has four neighbours at distance 1 and seven
  # unreachable: 4 + 7*4 = 32, and 11/32 = 0.34375.
  res <- xcloseness(disc())
  expect_equal(res$nodes$FreeClo[1], 11 / 32, tolerance = tol)
  expect_true(any(grepl("Max observed distance plus 1", res$assumptions)))
})

test_that("the other three substitutions are UCINET's, and differ", {
  skip_if_no_golden("G9_MC_DISC_N", "centrality")
  d <- disc()
  n <- 12
  # mcent's closeness columns are the raw distance SUMS under each convention,
  # so the sum recovered from our Freeman score has to reproduce them.
  for (v in c("n", "max1", "zero")) {
    gold <- as.vector(golden_matrix(paste0("G9_MC_DISC_", toupper(v)),
                                    "centrality"))
    got <- (n - 1) / xcloseness(d, undefined = v)$nodes$FreeClo
    expect_equal(got, gold, tolerance = 1e-4, info = v)
  }
  # and they really are four different answers, which is why g9_disc has
  # components of different size and shape
  vals <- vapply(c("max1", "n", "zero", "avg"),
                 function(u) xcloseness(d, undefined = u)$nodes$FreeClo[1],
                 numeric(1))
  expect_equal(length(unique(round(vals, 6))), 4L)
})

test_that("Valente-Forman is reverse distance over the diameter", {
  res <- xcloseness(disc())
  # n1: four neighbours at distance 1, reverse distance 3+1-1 = 3 each, zero for
  # the seven unreachable; (12/11)/3 = 0.36364.
  expect_equal(res$nodes$ValClo[1], (12 / 11) / 3, tolerance = tol)
})

test_that("reciprocal distance averages 1/d over n - 1", {
  res <- xcloseness(disc())
  expect_equal(res$nodes$RecipClo[1], 4 / 11, tolerance = tol)
  # n6 sits on the four-path: 1/1 + 1/2 + 1/3 over 11
  expect_equal(res$nodes$RecipClo[6], (1 + 1/2 + 1/3) / 11, tolerance = tol)
})

test_that("the options used are recorded, as UCINET records them", {
  res <- xcloseness(campnet)
  expect_true(any(grepl("\\(Freeman\\) Output options", res$assumptions)))
  expect_true(any(grepl("\\(Valente-Forman\\)", res$assumptions)))
  expect_true(any(grepl("\\(Reciprocal\\)", res$assumptions)))
  # No statistics block: uc_ClosenessMeasures.pas prints none.
  expect_false(any(grepl("DESCRIPTIVE STATISTICS",
                         capture.output(print(res)))))
})

test_that("a node that reaches nobody scores zero rather than erroring", {
  iso <- xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))
  res <- xcloseness(iso)
  expect_false(anyNA(res$nodes$RecipClo))
  expect_equal(res$nodes$RecipClo[8:10], c(0, 0, 0))
})
