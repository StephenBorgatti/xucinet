# Components and centralization (chapter 10, sections 10.3.1 and 10.4).

tol <- 1e-8

# Two pairs and an isolate: three weak components of sizes 2, 2, 1.
split5 <- function() {
  m <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  m["a", "b"] <- m["b", "a"] <- 1
  m["c", "d"] <- m["d", "c"] <- 1
  m
}

# One weak component, two strong ones: a <-> b, b -> c, c -> b is absent.
oneway3 <- function() {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["b", "a"] <- 1
  m["b", "c"] <- 1
  m
}

# ---- xcomponents -------------------------------------------------------------

test_that("weak is the default, as the dialog has it", {
  # Method.ItemIndex = 0 is Weak Components.
  expect_equal(xcomponents(oneway3())$summary$Components,
               xcomponents(oneway3(), type = "weak")$summary$Components)
})

test_that("weak and strong differ where direction matters", {
  expect_equal(xcomponents(oneway3(), type = "weak")$summary$Components, 1)
  # c cannot get back to a or b
  expect_equal(xcomponents(oneway3(), type = "strong")$summary$Components, 2)
})

test_that("isolates are components of size one", {
  out <- xcomponents(split5())
  expect_equal(out$summary$Components, 3)
  expect_equal(sort(as.vector(out$matrices$Sizes)), c(1, 2, 2))
})

test_that("the node table keeps the original order", {
  out <- xcomponents(split5())
  expect_equal(out$nodes$Node, letters[1:5])
  expect_equal(out$nodes$Component[1], out$nodes$Component[2])
  expect_false(out$nodes$Component[1] == out$nodes$Component[3])
})

test_that("the strong count agrees with xcohesion, which UCINET validated", {
  expect_equal(xcomponents(campnet, type = "strong")$summary$Components,
               as.matrix(xcohesion(campnet)$summary)["Components", 1])
})

test_that("normalized heterogeneity is the fragmentation of the network", {
  # UCINET's own closing note. iqv works out to (n^2 - sum s_k^2)/(n(n-1)),
  # which is the proportion of ordered pairs in different components.
  out <- xcomponents(split5())
  n <- 5
  sizes <- c(2, 2, 1)
  expect_equal(out$summary[["Normalized heterogeneity"]],
               (n^2 - sum(sizes^2)) / (n * (n - 1)), tolerance = tol)
  # and against the cohesion block on an undirected network
  co <- as.matrix(xcohesion(split5(), directed = FALSE)$summary)
  expect_equal(out$summary[["Normalized heterogeneity"]],
               co["Fragmentation", 1], tolerance = 1e-6)
})

test_that("the heterogeneity figures are getheterogeneity's", {
  out <- xcomponents(split5())
  p <- c(2, 2, 1) / 5
  expect_equal(out$summary[["Heterogeneity"]], 1 - sum(p^2), tolerance = tol)
  expect_equal(out$summary[["Entropy"]], -sum(p * log(p)), tolerance = tol)
  # ncat is the node count, so the ceiling is one component per node
  expect_equal(out$summary[["Normalized entropy"]],
               -sum(p * log(p)) / log(5), tolerance = tol)
  expect_equal(out$summary[["Component ratio"]], (3 - 1) / (5 - 1))
})

test_that("a single component has no heterogeneity", {
  m <- matrix(1, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  diag(m) <- 0
  out <- xcomponents(m)
  expect_equal(out$summary$Components, 1)
  expect_equal(out$summary[["Normalized heterogeneity"]], 0)
})

test_that("min drops the small components and renumbers the rest", {
  out <- xcomponents(split5(), min = 2)
  expect_equal(out$summary$Components, 2)
  expect_true(is.na(out$nodes$Component[out$nodes$Node == "e"]))
  expect_equal(sort(unique(out$nodes$Component[!is.na(out$nodes$Component)])),
               c(1, 2))
  expect_true(any(grepl("below min", xcomponents(split5(), min = 2)$assumptions)))
})

test_that("sortby orders the size table", {
  out <- xcomponents(split5(), sortby = "size")
  expect_equal(as.vector(out$matrices$Sizes), c(2, 2, 1))
  byid <- xcomponents(split5(), sortby = "id")
  expect_equal(rownames(byid$matrices$Sizes), c("1", "2", "3"))
})

test_that("2-mode data is treated as the bipartite graph", {
  out <- xcomponents(davis)
  expect_equal(nrow(out$nodes), 18 + 14)
  expect_true(any(grepl("bipartite", out$assumptions)))
})

test_that("valued data are dichotomized", {
  expect_true(any(grepl("dichotomized", xcomponents(baker_journals)$assumptions)))
})

test_that("the report prints", {
  expect_snapshot(xcomponents(campnet))
})

# ---- xcentralization ---------------------------------------------------------

test_that("centralization is taken from the centrality routine, not recomputed", {
  # Design question 10.5: the two must not be able to disagree.
  got <- xcentralization(campnet)$summary
  from <- xdegree(campnet)$summary
  expect_equal(got[["Out-Centralization"]], from[["Out-Centralization"]])
  expect_equal(got[["In-Centralization"]], from[["In-Centralization"]])
})

test_that("betweenness centralization comes from xbetweenness", {
  key <- "Network Centralization Index (%)"
  expect_equal(xcentralization(campnet, measure = "betweenness")$summary[[key]],
               xbetweenness(campnet)$summary[[key]])
})

test_that("the result holds all four measures whichever is printed", {
  # SPEC addendum, 23 Sep 2026, item 5: `measure` chooses what is printed.
  s <- xcentralization(campnet, directed = FALSE)$summary
  expect_equal(names(s), c("Centralization", "Network Centralization Index (%)",
                           "Network Centralization (%)",
                           "Eigenvector centralization (%)"))
  expect_equal(s[["Centralization"]],
               xdegree(campnet, directed = FALSE)$summary[["Centralization"]])
  expect_identical(xcentralization(campnet, directed = FALSE,
                                   measure = "eigenvector")$summary, s)
  expect_equal(xcentralization(campnet, measure = "closeness")$show_summary,
               c("Network in-Centralization (%)", "Network out-Centralization (%)"))
})

test_that("degree centralization agrees with the cohesion block", {
  # Both are (n*max - sum)/(n-1)^2, and the block was checked against UCINET.
  co <- as.matrix(xcohesion(campnet)$summary)
  s <- xcentralization(campnet)$summary
  expect_equal(s[["In-Centralization"]], co["In-Centralization", 1],
               tolerance = 1e-6)
  expect_equal(s[["Out-Centralization"]], co["Out-Centralization", 1],
               tolerance = 1e-6)
})

test_that("closeness centralization comes from xcloseness", {
  key <- "Network Centralization (%)"
  expect_equal(
    xcentralization(campnet, directed = FALSE, measure = "closeness")$summary[[key]],
    xcloseness(campnet, directed = FALSE)$summary[[key]])
})

test_that("closeness centralization is the legacy routine's figure", {
  # xcloseness.pas: (2n - 3) * sum(max c - c) / (n^2 - 3n + 2), c in percent.
  # A star scores 100 and a complete graph 0.
  star <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  star[1, -1] <- star[-1, 1] <- 1
  key <- "Network Centralization (%)"
  expect_equal(xcloseness(star)$summary[[key]], 100)
  full <- matrix(1, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  diag(full) <- 0
  expect_equal(xcloseness(full)$summary[[key]], 0)
  # runcentralization (Xdpmat.pas) divides the sum of differences by the
  # star's, which is the same figure as a proportion.
  cl <- xcloseness(campnet, directed = FALSE)$nodes$FreeClo
  starc <- xcloseness(matrix(c(0, rep(1, 17), rep(c(1, rep(0, 17)), 17)), 18, 18,
                             dimnames = list(1:18, 1:18)))$nodes$FreeClo
  expect_equal(xcloseness(campnet, directed = FALSE)$summary[[key]],
               100 * sum(max(cl) - cl) / sum(max(starc) - starc))
})

test_that("closeness centralization is missing for an unconnected network", {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m[1, 2] <- m[2, 1] <- m[3, 4] <- m[4, 3] <- 1
  res <- xcloseness(m)
  expect_true(is.na(res$summary[["Network Centralization (%)"]]))
  expect_true(any(grepl("not computed for unconnected", res$assumptions)))
})

test_that("eigenvector centralization comes from xeigenvector", {
  expect_equal(
    xcentralization(campnet, measure = "eigenvector")$summary[["Eigenvector centralization (%)"]],
    xeigenvector(campnet)$summary[["Eigenvector centralization (%)"]])
})

test_that("eigenvector centralization is 100 for a star and 0 for a ring", {
  # getcentralization's denominator is the star's total, so a star scores 100
  # and a vertex-transitive graph, where every score is equal, scores 0.
  star <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  star[1, -1] <- star[-1, 1] <- 1
  expect_equal(xeigenvector(star)$summary[["Eigenvector centralization (%)"]], 100)
  ring <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  for (i in 1:5) ring[i, i %% 5 + 1] <- ring[i %% 5 + 1, i] <- 1
  expect_equal(xeigenvector(ring)$summary[["Eigenvector centralization (%)"]], 0,
               tolerance = 1e-8)
})

test_that("arguments reach the centrality routine", {
  expect_silent(xcentralization(campnet, measure = "degree", directed = TRUE))
})

test_that("the assumption records where the figure came from", {
  expect_true(any(grepl("Taken from xdegree", xcentralization(campnet)$assumptions)))
})
