# xreach, xbetareach and xhubsauthorities against UCINET 6.849.

tol <- 1e-5

disc <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_disc"))

test_that("reach proportions match UCINET", {
  skip_if_no_golden("g9m_reach_disc", "centrality")
  gold <- golden_matrix("g9m_reach_disc", "centrality")
  res <- xreach(disc())
  prop <- res$matrices[[1]]

  expect_equal(dim(prop), dim(gold))
  expect_equal(unname(prop), unname(gold), tolerance = tol)
  # On a disconnected graph a row plateaus at its own component's size: n1 is in
  # the five-node star, so it reaches 4 of the other 11 and stops.
  expect_equal(unname(prop[1, ]), rep(4 / 11, 11), tolerance = tol)
})

test_that("the reach summary measures match", {
  skip_if_no_golden("g9m_reach_disc_summary", "centrality")
  gold <- golden_matrix("g9m_reach_disc_summary", "centrality")
  res <- xreach(disc())$nodes

  expect_identical(names(res), c("dwr", "ard"))
  expect_equal(res$dwr, unname(gold[, "dwr"]), tolerance = tol)
  expect_equal(res$ard, unname(gold[, "ard"]), tolerance = tol)
  # ard is dwr averaged over the n - 1 others, and dwr is the sum of reciprocal
  # distances, so ard is the same figure xcloseness calls RecipClo.
  expect_equal(res$ard, res$dwr / 11, tolerance = tol)
  expect_equal(res$ard, xcloseness(disc())$nodes$RecipClo, tolerance = tol)
})

test_that("beta reach matches UCINET at its default beta", {
  skip_if_no_golden("g9m_breach_disc", "centrality")
  gold <- as.vector(golden_matrix("g9m_breach_disc", "centrality"))
  res <- xbetareach(disc())

  expect_equal(res$summary$Beta, 0.8)
  expect_equal(res$nodes[[1]], gold, tolerance = tol)
})

test_that("beta reach collapses to its two end cases", {
  d <- disc()
  n <- nrow(as.matrix(d))
  # beta = 1: every reachable node counts fully, so it is the proportion
  # reachable, which is the last column of the reach table.
  expect_equal(xbetareach(d, beta = 1)$nodes[[1]],
               unname(xreach(d)$matrices[[1]][, n - 1]), tolerance = tol)
  # beta = 0: only distance 1 counts, so it is degree over n - 1.
  expect_equal(xbetareach(d, beta = 0)$nodes[[1]],
               xdegree(d)$nodes$Degree / (n - 1), tolerance = tol)
})

test_that("hubs and authorities match, up to the sign UCINET gets wrong", {
  for (case in list(list("g9m_hubs_campnet", campnet),
                    list("g9m_hubs_baker",   baker_journals))) {
    skip_if_no_golden(case[[1]], "centrality")
    gold <- golden_matrix(case[[1]], "centrality")
    res <- xhubsauthorities(case[[2]])$nodes
    expect_identical(names(res), c("Hub", "Authority"))
    expect_equal(res$Hub, abs(unname(gold[, "Hub"])), tolerance = tol,
                 info = case[[1]])
    expect_equal(res$Authority, abs(unname(gold[, "Authority"])),
                 tolerance = tol, info = case[[1]])
  }
})

test_that("we report hub and authority scores positive", {
  expect_differs_from_ucinet(issue = 2)
  gold <- golden_matrix("g9m_hubs_campnet", "centrality")
  res <- xhubsauthorities(campnet)$nodes
  expect_true(all(res$Hub >= 0))
  expect_true(all(gold[, "Hub"] <= 0))            # UCINET's are negative
  expect_true(any(grepl("reported positive", xhubsauthorities(campnet)$assumptions)))
})

test_that("both columns are unit length", {
  res <- xhubsauthorities(campnet)$nodes
  expect_equal(sum(res$Hub^2), 1, tolerance = tol)
  expect_equal(sum(res$Authority^2), 1, tolerance = tol)
})

test_that("on symmetric data hubs and authorities coincide", {
  res <- xhubsauthorities(disc())
  expect_equal(res$nodes$Hub, res$nodes$Authority, tolerance = tol)
  expect_true(any(grepl("symmetric", res$assumptions)))
})
