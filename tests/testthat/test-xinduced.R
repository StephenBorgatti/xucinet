# xinduced against UCINET 6.849.
#
# Nine whole-network statistics, each differenced. The conventions matter more
# than the arithmetic here: two plausible readings of "remove the node" both
# give wrong answers, so the tests pin the reading as well as the numbers.

tol <- 1e-3          # the fixture is single precision and the sums are large

iso <- function() xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))

test_that("all nine measures match UCINET on campnet", {
  skip_if_no_golden("g9m_induced_campnet", "centrality")
  gold <- golden_matrix("g9m_induced_campnet", "centrality")
  res <- xinduced(campnet)$nodes

  expect_identical(names(res), colnames(gold))
  for (cn in colnames(gold)) {
    expect_equal(res[[cn]], unname(gold[, cn]), tolerance = tol, info = cn)
  }
})

test_that("all nine match on a graph with isolates", {
  skip_if_no_golden("g9m_induced_iso", "centrality")
  gold <- golden_matrix("g9m_induced_iso", "centrality")
  res <- xinduced(iso())$nodes
  for (cn in colnames(gold)) {
    expect_equal(res[[cn]], unname(gold[, cn]), tolerance = tol, info = cn)
  }
})

test_that("an isolate contributes nothing except through the distance count", {
  # g9_iso's last three nodes are isolates. Stripping a node that has no ties
  # changes no structural measure, so those rows are zero - except for the two
  # distance sums, which move because an isolate's own pairs are dropped from
  # the sum when it is ignored.
  res <- xinduced(iso())$nodes
  for (cn in c("W'in3", "SumOverlap", "Transtriples", "SumBetweenness",
               "SumEdgeBetween", "Fragmentation")) {
    expect_equal(res[[cn]][8:10], c(0, 0, 0), info = cn)
  }
  expect_true(all(res$SumDist[8:10] < 0))
})

test_that("SumDist and Fragmentation run the other way round", {
  # For those two an increase is the damage, so UCINET reports X(G-k) - X(G).
  # HOLLY is the clearest case in campnet: stripping her raises both.
  res <- xinduced(campnet)$nodes
  expect_true(res$SumDist[1] > 0)
  expect_true(res$Fragmentation[1] > 0)
  expect_true(any(grepl("in reverse", xinduced(campnet)$assumptions)))
})

test_that("the k cutoff names its own column", {
  expect_identical(names(xinduced(campnet, k = 2)$nodes)[1], "W'in2")
  expect_identical(names(xinduced(campnet)$nodes)[1], "W'in3")
  # a wider cutoff cannot catch fewer pairs
  expect_true(all(xinduced(campnet, k = 4)$nodes[[1]] >=
                    xinduced(campnet, k = 2)$nodes[[1]] - tol))
})

test_that("edge betweenness agrees with node betweenness on a path", {
  # On a path every shortest path uses whole edges, so the two totals are
  # related in a way that is easy to check by hand: a 4-path has node
  # betweenness 0,2,2,0 and edge betweenness 3,4,3 each way.
  a <- matrix(0, 4, 4)
  for (i in 1:3) { a[i, i + 1] <- 1; a[i + 1, i] <- 1 }
  b <- brandes_edges(a)
  expect_equal(b$node, c(0, 4, 4, 0))          # directed count, unhalved
  expect_equal(sum(b$edge), 20)
  expect_equal(b$edge[1, 2], 3)
})
