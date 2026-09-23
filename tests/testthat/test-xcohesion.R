# Whole-network measures (chapter 10, section 10.3.2).
#
# Unusually for a routine written in this phase, the goldens already exist:
# the Phase 0 density run saved UCINET's cohesion block for three datasets, so
# these tests run rather than skip and the routine is checked against UCINET
# from the day it lands.
#
# The comparison tolerance is looser than the usual 1e-6 because UCINET stores
# these as singles: the largest disagreement across all five golden columns is
# about 2e-7, which is float32 rounding and not arithmetic.

tol <- 1e-5

# A four-node directed network small enough to do by hand: a <-> b, a -> c,
# c <-> d. Two strong components, one unreciprocated arc, one unreachable
# direction.
hand4 <- function() {
  matrix(c(0, 1, 1, 0,
           1, 0, 0, 0,
           0, 0, 0, 1,
           0, 0, 1, 0), 4, 4, byrow = TRUE,
         dimnames = list(letters[1:4], letters[1:4]))
}

val <- function(m, name) as.matrix(xcohesion(m)$summary)[name, 1]

# ---- the block itself -------------------------------------------------------

test_that("the block is UCINET's 33 measures in UCINET's order", {
  s <- xcohesion(campnet)$summary
  expect_equal(nrow(s), 33)
  expect_equal(rownames(s)[1:3], c("# of nodes", "# of ties", "Avg Degree"))
  expect_equal(rownames(s)[33], "Reciprocity Index")
  # the four the chapter 10 text names
  expect_true(all(c("Connectedness", "Fragmentation", "Compactness", "Breadth")
                  %in% rownames(s)))
})

test_that("there is one column per relation, named as UCINET names it", {
  # d.cdvn: the dataset name for a single relation, the relation names for a
  # stack.
  expect_equal(colnames(xcohesion(campnet)$summary), "campnet")
  expect_equal(colnames(xcohesion(hightech)$summary), xrelations(hightech))
})

# ---- hand-computed -----------------------------------------------------------

test_that("the counting measures are what they say", {
  m <- hand4()
  expect_equal(val(m, "# of nodes"), 4)
  expect_equal(val(m, "# of ties"), 5)          # arcs, not dyads
  expect_equal(val(m, "Avg Degree"), 5 / 4)
  expect_equal(val(m, "Density"), (5 / 4) / 3)
})

test_that("Components counts strongly connected components", {
  # tnodelist.getcomponents is Tarjan's. {a,b} and {c,d} are each strongly
  # connected; a -> c is one-way, so they do not merge.
  m <- hand4()
  expect_equal(val(m, "Components"), 2)
  expect_equal(val(m, "Largest Component"), 2)
  expect_equal(val(m, "Component Ratio"), (2 - 1) / (4 - 1))
})

test_that("Connectedness is reachability, not components", {
  # 8 of the 12 ordered pairs can reach each other: c and d cannot get back to
  # a or b.
  m <- hand4()
  expect_equal(val(m, "Connectedness"), 8 / 12)
  expect_equal(val(m, "Fragmentation"), 1 - 8 / 12)
})

test_that("the distance measures use the reachable pairs only", {
  m <- hand4()
  # distances: a-b 1, a-c 1, a-d 2, b-a 1, b-c 2, b-d 3, c-d 1, d-c 1
  expect_equal(val(m, "Wiener Index"), 12)
  expect_equal(val(m, "Avg Distance"), 12 / 8)
  expect_equal(val(m, "Diameter"), 3)
  # s.sum - s.n
  expect_equal(val(m, "Dependency Sum"), 12 - 8)
  expect_equal(val(m, "Prop within 3"), 8 / 12)
})

test_that("Compactness averages the reciprocal distances over every pair", {
  # sr takes 0 for an unreachable pair, so the denominator is n(n-1) and not
  # the number of reachable pairs.
  m <- hand4()
  recip <- sum(1 / c(1, 1, 2, 1, 2, 3, 1, 1))
  expect_equal(val(m, "Compactness"), recip / 12)
  expect_equal(val(m, "Breadth"), 1 - recip / 12)
})

test_that("the dyad census is a proportion of the unordered pairs", {
  # (a,b) mutual, (c,d) mutual, (a,c) asymmetric, the other three null.
  m <- hand4()
  expect_equal(val(m, "Mutuals"), 2 / 6)
  expect_equal(val(m, "Asymmetrics"), 1 / 6)
  expect_equal(val(m, "Nulls"), 3 / 6)
})

test_that("the two reciprocity ratios are arcs and dyads", {
  # 4 of the 5 arcs are reciprocated; 2 of the 3 non-null dyads are mutual.
  m <- hand4()
  expect_equal(val(m, "Arc Reciprocity"), 4 / 5)
  expect_equal(val(m, "Dyad Reciprocity"), 4 / (4 + 2 * 1))
})

test_that("the two degree centralizations use different denominators", {
  # getdirdegcentralization divides by (n-1)^2; getoutdegcentralization, which
  # supplies Deg Centralization on the symmetrized graph, divides by
  # (n-1)(n-2).
  m <- hand4()
  expect_equal(val(m, "Out-Centralization"), (2 * 4 - 5) / (4 - 1)^2)
  expect_equal(val(m, "In-Centralization"), (2 * 4 - 5) / (4 - 1)^2)
  u <- pmax(m, t(m))
  expect_equal(val(m, "Deg Centralization"),
               (max(rowSums(u)) * 4 - sum(u)) / (4^2 - 3 * 4 + 2))
})

test_that("transitivity is closed two-paths, and the index adjusts for density", {
  m <- hand4()
  # the two-paths are a->c->d and b->a->c; neither is closed
  expect_equal(val(m, "Transitivity/Closure"), 0)
  d <- (5 / 4) / 3
  expect_equal(val(m, "Transitivity Index"), (0 - d) / (1 - d))
})

test_that("Small Worldness is withheld unless the network is strongly connected", {
  expect_true(is.na(val(hand4(), "Small Worldness")))
  # a mutual triangle is strongly connected, so it gets a value
  tri <- matrix(1, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  diag(tri) <- 0
  expect_false(is.na(val(tri, "Small Worldness")))
})

test_that("the K-core index is taken on the underlying graph", {
  # `//must be last` in getcohesion: the network is symmetrized first, so
  # direction cannot change this one.
  expect_equal(val(hand4(), "K-core index"),
               val(pmax(hand4(), t(hand4())), "K-core index"))
})

test_that("a degree correlation with no variance to work with is missing", {
  # campnet's outdegree is 3 for everyone, so the absolute differences are all
  # zero and there is nothing to correlate. UCINET reports missing too.
  expect_true(is.na(as.matrix(xcohesion(campnet)$summary)["Outdeg Corr", 1]))
})

# ---- behaviour ---------------------------------------------------------------

test_that("valued data are dichotomized, and the assumption says so", {
  expect_true(any(grepl("dichotomized", xcohesion(baker_journals)$assumptions)))
})

test_that("self-ties are removed", {
  m <- hand4()
  diag(m) <- 1
  expect_equal(val(m, "# of ties"), 5)
  expect_true(any(grepl("Self-ties removed", xcohesion(m)$assumptions)))
})

test_that("directed = FALSE ignores the direction of ties", {
  a <- xcohesion(campnet)$summary
  b <- xcohesion(campnet, directed = FALSE)$summary
  expect_false(isTRUE(all.equal(a[["campnet"]], b[["campnet"]])))
  # once undirected, every arc is reciprocated
  expect_equal(as.matrix(b)["Arc Reciprocity", 1], 1)
  expect_true(any(grepl("Direction of ties ignored",
                        xcohesion(campnet, directed = FALSE)$assumptions)))
})

test_that("a disconnected network is flagged", {
  expect_true(any(grepl("disconnected", xcohesion(campnet)$assumptions)))
})

test_that("xcohesion refuses 2-mode data and one-node networks", {
  expect_error(xcohesion(davis), "1-mode")
  one <- matrix(0, 1, 1, dimnames = list("a", "a"))
  expect_error(xcohesion(one), "more than one node")
})

test_that("the report prints", {
  expect_snapshot(xcohesion(campnet))
})

# ---- goldens: these run, they do not skip -----------------------------------

test_that("every measure matches UCINET on campnet", {
  skip_if_no_golden("G_CAMPNET_COH", "density")
  gold <- golden_matrix("G_CAMPNET_COH", "density")
  ours <- xcohesion(campnet)$summary
  ours <- as.matrix(ours[match(rownames(gold), rownames(ours)), , drop = FALSE])
  expect_equal(unname(ours), unname(gold), tolerance = tol)
})

test_that("every measure matches UCINET on valued data", {
  skip_if_no_golden("G_BAKER_COH", "density")
  gold <- golden_matrix("G_BAKER_COH", "density")
  ours <- xcohesion(baker_journals)$summary
  ours <- as.matrix(ours[match(rownames(gold), rownames(ours)), , drop = FALSE])
  expect_equal(unname(ours), unname(gold), tolerance = tol)
})

test_that("every measure matches UCINET on all three relations at once", {
  skip_if_no_golden("G_HIGHTECH_COH", "density")
  gold <- golden_matrix("G_HIGHTECH_COH", "density")
  ours <- xcohesion(hightech)$summary
  ours <- as.matrix(ours[match(rownames(gold), rownames(ours)), , drop = FALSE])
  expect_equal(dim(ours), c(33L, 3L))
  expect_equal(unname(ours), unname(gold), tolerance = tol)
})

test_that("the measure names are UCINET's own, read back from the golden", {
  skip_if_no_golden("G_CAMPNET_COH", "density")
  gold <- golden_matrix("G_CAMPNET_COH", "density")
  expect_equal(rownames(xcohesion(campnet)$summary), rownames(gold))
})
