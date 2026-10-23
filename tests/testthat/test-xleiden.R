# xleiden: dev/design/leiden.md. Until UCINET's Leiden (ucinet #46) produces
# goldens, the tests check what the algorithm guarantees (connected
# communities, no single move that raises the quality), the known optimum for
# Zachary's karate club, agreement with igraph's Leiden in distribution, and
# the report.

leiden_w <- function(net) community_matrix(as.matrix(pick_relation(xnet(net), NULL)))

# Every community induces a connected subgraph (breadth-first search).
communities_connected <- function(w, p) {
  all(vapply(unique(p), function(c) {
    i <- which(p == c)
    seen <- i[1]; frontier <- i[1]
    while (length(frontier)) {
      nxt <- setdiff(i[colSums(w[frontier, i, drop = FALSE] > 0) > 0], seen)
      seen <- c(seen, nxt); frontier <- nxt
    }
    length(seen) == length(i)
  }, logical(1)))
}

# The largest gain in Q_gamma from moving one node to another community
# (existing or empty).
best_single_move <- function(w, p, gamma) {
  q0 <- leiden_quality(w, p, gamma)
  best <- -Inf
  for (v in seq_along(p)) {
    for (c in c(unique(p), max(p) + 1L)) {
      if (c == p[v]) next
      p2 <- p; p2[v] <- c
      best <- max(best, leiden_quality(w, p2, gamma) - q0)
    }
  }
  best
}

test_that("Zachary's karate club: the optimum, Q = 0.4198, for every seed", {
  for (s in 1:5) {
    r <- xleiden(zachary, seed = s)
    expect_equal(r$summary$Modularity, 0.4197896, tolerance = 1e-6, info = s)
    expect_equal(r$summary$Clusters, 4L)
    expect_equal(r$summary$Quality, r$summary$Modularity, tolerance = 1e-12)
  }
})

test_that("communities are connected and no single move raises the quality", {
  for (nm in c("zachary", "campnet", "padgett")) {
    w <- leiden_w(get(nm))
    for (g in c(0.5, 1, 1.5)) for (s in 1:3) {
      p <- xleiden(get(nm), resolution = g, seed = s)$nodes$Cluster
      expect_true(communities_connected(w, p), info = paste(nm, g, s))
      expect_lte(best_single_move(w, p, g), 1e-10)
    }
  }
})

test_that("the same seed gives the same partition; a NULL seed is reported", {
  a <- xleiden(padgett, seed = 7)
  b <- xleiden(padgett, seed = 7)
  expect_identical(a$nodes, b$nodes)
  expect_identical(a$fields[["Random number seed:"]], "7")
  r <- xleiden(padgett)
  s <- as.numeric(r$fields[["Random number seed:"]])
  expect_true(s >= 1 && s <= 1000)
  expect_identical(xleiden(padgett, seed = s)$nodes, r$nodes)
})

test_that("a higher resolution gives more communities", {
  k <- vapply(c(0.25, 1, 4), function(g) xleiden(campnet, resolution = g, seed = 1)$summary$Clusters,
              integer(1))
  expect_true(all(diff(k) > 0))
})

test_that("modularity agrees with igraph's Leiden over seeds", {
  skip_if_not_installed("igraph")
  w <- leiden_w(padgett)
  g <- igraph::graph_from_adjacency_matrix(w, mode = "undirected", weighted = TRUE)
  ours <- vapply(1:20, function(s) xleiden(padgett, seed = s)$summary$Modularity, numeric(1))
  theirs <- vapply(1:20, function(s) {
    set.seed(s)
    igraph::modularity(g, igraph::membership(igraph::cluster_leiden(
      g, objective_function = "modularity", n_iterations = -1)))
  }, numeric(1))
  expect_equal(max(ours), max(theirs), tolerance = 1e-6)
  expect_lt(abs(mean(ours) - mean(theirs)), 0.005)
})

test_that("Delphi's Random: the real draw is the state after the step over 2^32", {
  rng <- delphi_rng(1)
  expect_equal(delphi_random_real(rng), 134775814 / 2^32)
  rng <- delphi_rng(1); r1 <- delphi_random(rng, 1000)
  rng <- delphi_rng(1); expect_equal(floor(delphi_random_real(rng) * 1000), r1)
})

test_that("input handling: symmetrizing, negatives, empty networks, errors", {
  m <- matrix(0, 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  m[1, 2] <- m[2, 3] <- m[3, 1] <- m[4, 5] <- m[5, 6] <- m[6, 4] <- 1
  m[3, 4] <- -1
  r <- xleiden(m, seed = 1)
  expect_true("Negative values removed." %in% r$assumptions)
  expect_true("Data symmetrized by max." %in% r$assumptions)
  expect_identical(r$nodes$Cluster, c(1L, 1L, 1L, 2L, 2L, 2L))
  expect_identical(xleiden(matrix(0, 3, 3), seed = 1)$nodes$Cluster, 1:3)
  expect_error(xleiden(davis, seed = 1), "1-mode")
  expect_error(xleiden(zachary, resolution = 0), "positive")
  expect_error(xleiden(zachary, seed = 1.5), "whole number")
})

test_that("the Leiden report prints", {
  expect_snapshot(xleiden(campnet, seed = 1))
})
