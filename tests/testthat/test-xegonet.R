# Egonet basic measures (chapter 8, section 8.6.2).

tol <- 1e-8

# A star: a at the centre, b, c and d on the points.
star <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", c("b", "c", "d")] <- 1
  m[c("b", "c", "d"), "a"] <- 1
  m
}

# The star with an isolate e.
star_iso <- function() {
  m <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  m[1:4, 1:4] <- star()
  m
}

triangle <- function() {
  m <- matrix(1, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  diag(m) <- 0
  m
}

# a -> b -> c
path3 <- function() {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["b", "c"] <- 1
  m
}

row_of <- function(res, node) unlist(res$nodes[node, ])

# ---- layer (a): hand-computed ------------------------------------------------

test_that("the columns are UCINET's sixteen, in its order, then Symmetric", {
  expect_equal(names(xegonet(star())$nodes),
               c("Size", "Ties", "Pairs", "Density", "AvgRecipDist", "Diameter",
                 "nWeakComp", "CompRatio", "2StepReach", "2StepPct",
                 "ReachEffic", "Broker", "nBroker", "nClosed", "EgoBetween",
                 "nEgoBetween", "Symmetric"))
})

test_that("the centre of a star is a pure broker", {
  r <- row_of(xegonet(star()), "a")
  expect_equal(r[["Size"]], 3)
  expect_equal(r[["Ties"]], 0)
  expect_equal(r[["Pairs"]], 6)
  expect_equal(r[["Density"]], 0)
  expect_equal(r[["AvgRecipDist"]], 0)
  expect_true(is.na(r[["Diameter"]]))           # the alters cannot reach each other
  expect_equal(r[["nWeakComp"]], 3)
  expect_equal(r[["CompRatio"]], 100)           # (3 - 1) / (3 - 1), as a percentage
  expect_equal(r[["2StepReach"]], 3)
  expect_equal(r[["2StepPct"]], 100)
  expect_true(is.na(r[["ReachEffic"]]))         # the alters have no other ties
  expect_equal(r[["Broker"]], 3)
  expect_equal(r[["nBroker"]], 1)
  expect_equal(r[["nClosed"]], 0)
  # Three pairs of points, every one through the centre; halved because the
  # ego network is symmetric, and normalized by (4-1)(4-2) on the unhalved 6.
  expect_equal(r[["EgoBetween"]], 3)
  expect_equal(r[["nEgoBetween"]], 100)
})

test_that("a point of the star reaches the others in two steps", {
  r <- row_of(xegonet(star()), "b")
  expect_equal(r[["Size"]], 1)
  expect_equal(r[["Pairs"]], 0)
  expect_true(is.na(r[["Density"]]))
  expect_equal(r[["2StepReach"]], 3)            # a, and through a, c and d
  expect_equal(r[["ReachEffic"]], 100)          # 3 / (1 + a's two other ties)
  expect_true(is.na(r[["nBroker"]]))
  expect_true(is.na(r[["nEgoBetween"]]))        # (2-1)(2-2) = 0
})

test_that("a complete triangle has no brokerage and density 100", {
  r <- row_of(xegonet(triangle()), "a")
  expect_equal(r[["Density"]], 100)
  expect_equal(r[["Broker"]], 0)
  expect_equal(r[["EgoBetween"]], 0)
  expect_equal(r[["AvgRecipDist"]], 1)
  expect_equal(r[["Diameter"]], 1)
  expect_equal(r[["nWeakComp"]], 1)
  expect_equal(r[["CompRatio"]], 0)
  # nClosed is UCINET's tie count, twice the one closed triad.
  expect_equal(r[["nClosed"]], 2)
})

test_that("an isolate gets missing ratios, not UCINET's zeros (issue 17)", {
  expect_differs_from_ucinet(17)
  r <- row_of(xegonet(star_iso()), "e")
  expect_equal(r[["Size"]], 0)
  expect_equal(r[["Broker"]], 0)
  expect_true(all(is.na(r[c("Density", "AvgRecipDist", "Diameter", "CompRatio",
                            "ReachEffic", "nBroker", "nEgoBetween")])))
  # and the others' 2StepPct now divides by 4
  expect_equal(row_of(xegonet(star_iso()), "a")[["2StepPct"]], 75)
})

test_that("direction picks the neighbourhood", {
  p <- path3()
  expect_equal(xegonet(p, direction = "out")$nodes["b", "Size"], 1)
  expect_equal(xegonet(p, direction = "in")$nodes["b", "Size"], 1)
  r <- row_of(xegonet(p), "b")
  expect_equal(r[["Size"]], 2)
  # a -> b -> c: one ordered pair through b, not halved because the ego network
  # is not symmetric, over (3-1)(3-2).
  expect_equal(r[["EgoBetween"]], 1)
  expect_equal(r[["nEgoBetween"]], 50)
  expect_equal(xegonet(p, direction = "out")$nodes["c", "Size"], 0)
})

test_that("valued data are dichotomized with UCINET's notice", {
  m <- star() * 3
  res <- xegonet(m)
  expect_equal(res$nodes, xegonet(star())$nodes)
  expect_true(any(grepl("dichotomized", res$assumptions)))
})

test_that("missing cells are no tie", {
  m <- triangle()
  m["a", "b"] <- NA
  expect_equal(xegonet(m)$nodes["c", "Ties"], 1)
})

test_that("a multi-relation dataset uses the first relation and says so", {
  res <- xegonet(hightech)
  expect_true(any(grepl("Relation: Advice", res$assumptions)))
  expect_equal(res$nodes, xegonet(hightech, relation = "Advice")$nodes)
})

test_that("2-mode data are refused", {
  expect_error(xegonet(davis), "1-mode")
})

test_that("the report prints", {
  expect_snapshot(xegonet(campnet))
})

# ---- layer (b): cross-check ---------------------------------------------------

test_that("Size is degree in the chosen direction", {
  # Size counts neighbours, which is what xdegree counts on binary data.
  a <- (as.matrix(campnet) > 0) * 1
  diag(a) <- 0
  expect_equal(xegonet(campnet, direction = "out")$nodes$Size,
               unname(rowSums(a)))
  expect_equal(xegonet(campnet, direction = "in")$nodes$Size,
               unname(colSums(a)))
})

test_that("ego betweenness agrees with igraph on the ego network", {
  skip_if_not_installed("igraph")
  # Both count shortest paths through ego among its alters; on an undirected
  # ego network igraph's betweenness is UCINET's halved sum.
  u <- pmax(as.matrix(campnet), t(as.matrix(campnet)))
  res <- xegonet(u)
  g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected")
  for (v in seq_len(nrow(u))) {
    eg <- igraph::make_ego_graph(g, order = 1, nodes = v)[[1]]
    ego_id <- which(igraph::V(eg)$name == rownames(u)[v])
    expect_equal(res$nodes$EgoBetween[v],
                 unname(igraph::betweenness(eg)[ego_id]), tolerance = tol)
  }
})

# ---- layer (c): goldens ---------------------------------------------------------

golden_cols <- function(name, res) {
  g <- golden_matrix(name, "ego")
  # UCINET's sixteen columns; Symmetric, the seventeenth, is xegoreciprocity's
  # and is checked against it.
  ours <- as.matrix(res$nodes[setdiff(names(res$nodes), "Symmetric")])
  expect_equal(unname(ours), unname(g[, seq_len(ncol(ours))]), tolerance = 1e-5)
}

test_that("campnet matches UCINET, undirected", {
  skip_if_no_golden("g8_egonet_campnet", "ego")
  golden_cols("g8_egonet_campnet", xegonet(campnet))
})

test_that("campnet matches UCINET, out- and in-neighbourhoods", {
  skip_if_no_golden("g8_egonet_campnet_out", "ego")
  skip_if_no_golden("g8_egonet_campnet_in", "ego")
  golden_cols("g8_egonet_campnet_out", xegonet(campnet, direction = "out"))
  golden_cols("g8_egonet_campnet_in", xegonet(campnet, direction = "in"))
})

test_that("g9_iso matches UCINET apart from the isolate (issue 17)", {
  skip_if_no_golden("g8_egonet_iso", "ego")
  expect_differs_from_ucinet(17)
  iso <- xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))
  res <- xegonet(iso)
  g <- golden_matrix("g8_egonet_iso", "ego")
  keep <- res$nodes$Size > 1
  expect_equal(unname(as.matrix(res$nodes[keep, ])), unname(g[keep, ]),
               tolerance = 1e-5)
})
