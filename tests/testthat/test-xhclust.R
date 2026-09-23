# xhclust: against borgworld (the port's source) and against UCINET's Johnson's
# Hierarchical (the twin), plus the book's own worked example in section 6.4.

fx <- readRDS(test_path("fixtures", "borgworld-ch06.rds"))
tol <- 1e-12

# borgworld records one partition per merge step; we record one per distinct
# level. The partition at a level is borgworld's partition at the last merge
# step of that level, which is the step whose count of clusters equals ours.
borgworld_partition_at <- function(bw, nclusters) {
  cols <- apply(bw$partition_table, 2, function(v) length(unique(v)))
  bw$partition_table[, match(nclusters, cols)]
}

test_that("single-link clustering of cities reproduces borgworld level by level", {
  res <- xhclust(cities, type = "d", method = "single", plot = FALSE)
  bw <- fx$hclus_cities_single
  # Not borgworld's cophenetic. bcophenetic() indexes the dist object that
  # cophenetic() returns with lower.tri() of its matrix form, a 9 x 9 logical
  # applied to a length-36 vector, so it correlates the wrong cells (and NAs)
  # and reports 0.08 for cities where the correlation is 0.71. Reported to
  # borgworld; the port computes it on matching lower triangles.
  expect_equal(res$summary$Cophenetic,
               cor(as.dist(as.matrix(cities)), cophenetic(res$hclust)), tolerance = tol)
  expect_false(isTRUE(all.equal(res$summary$Cophenetic, bw$cophenetic)))
  expect_identical(rownames(res$nodes), bw$labels)
  # cities has no tied distances, so every merge step is its own level.
  expect_equal(res$summary$Levels, 8)
  for (j in seq_len(8)) {
    k <- length(unique(res$nodes[[j]]))
    expect_same_partition(res$nodes[[j]], borgworld_partition_at(bw, k), info = paste("level", j))
  }
  expect_equal(res$levels, sort(res$hclust$height), tolerance = tol)
})

test_that("Corr and Silhouette are borgworld's numbers; Modularity is UCINET's formula", {
  res <- xhclust(cities, type = "d", method = "average", plot = FALSE)
  bw <- fx$hclus_cities_average
  moca <- res$matrices[["Measures of cluster adequacy"]]
  for (j in seq_len(ncol(moca))) {
    k <- length(unique(res$nodes[[j]]))
    step <- match(k, bw$moca$n_clusters)
    expect_equal(moca["Corr", j], bw$moca$Corr[step], tolerance = tol, info = paste("Corr", j))
    expect_equal(moca["Silhouette", j], bw$moca$Silhouette[step], tolerance = tol,
                 info = paste("Silhouette", j))
  }
  # Modularity follows calcmoca() in umoca.pas, Q = sum_b (w_b/o - (k_b/o)^2),
  # which keeps i = j pairs in the null model as Newman does. borgworld's loop
  # over i < j leaves them out, so the two differ by sum(k_i^2)/o^2 and the
  # fixture is not compared; the formula is pinned by the next test.
  expect_false(isTRUE(all.equal(unname(moca["Modularity", ]), bw$moca$Modularity[-nrow(bw$moca)])))
})

test_that("modularity is Newman's Q on the similarity matrix", {
  m <- matrix(0, 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  m[1, 2] <- m[2, 3] <- m[1, 3] <- 1
  m[4, 5] <- m[5, 6] <- m[4, 6] <- 1
  m[3, 4] <- 0.5
  m <- m + t(m)
  res <- xhclust(m, type = "s", method = "average", plot = FALSE)
  two <- which(apply(res$nodes, 2, function(v) length(unique(v))) == 2)
  v <- res$nodes[[two]]
  expect_same_partition(v, rep(1:2, each = 3))
  # By hand: o = 13 (both directions), within-block sums 6 and 6, degree sums
  # 6.5 and 6.5.
  q <- 2 * (6 / 13 - (6.5 / 13)^2)
  expect_equal(res$matrices[["Measures of cluster adequacy"]]["Modularity", two], q,
               tolerance = tol)
  if (requireNamespace("igraph", quietly = TRUE)) {
    g <- igraph::graph_from_adjacency_matrix(m, mode = "undirected", weighted = TRUE)
    expect_equal(res$matrices[["Measures of cluster adequacy"]]["Modularity", two],
                 igraph::modularity(g, v, weights = igraph::E(g)$weight), tolerance = 1e-10)
  }
})

test_that("similarity input agrees with borgworld's bhiclus, which uses the same conversion", {
  m <- as.matrix(campnet); m <- (m + t(m)) / 2
  res <- xhclust(m, type = "s", method = "average", plot = FALSE)
  bw <- fx$hclus_campnet_average
  expect_equal(res$summary$Cophenetic,
               cor(as.dist(1 - m), cophenetic(res$hclust)), tolerance = tol)
  expect_true(any(grepl("converted to dissimilarities as 1 - x", res$assumptions)))
  for (j in seq_len(res$summary$Levels)) {
    k <- length(unique(res$nodes[[j]]))
    expect_same_partition(res$nodes[[j]], borgworld_partition_at(bw, k), info = paste("level", j))
  }
  # Ties collapse: campnet has 17 merge steps but fewer distinct levels.
  expect_lt(res$summary$Levels, 17)
  expect_identical(colnames(res$matrices[["Cluster sizes (proportion of items)"]]),
                   colnames(res$matrices[["Measures of cluster adequacy"]]))
})

test_that("the book's worked example: at level 808 the single-link clusters are as stated", {
  # Section 6.4: "at level 808 the clusters are (Miami), (Seattle, SF, LA),
  # (Boston, NY, DC, Chicago) and (Denver)".
  res <- xhclust(cities, type = "d", method = "single", plot = FALSE)
  j <- match(808, res$levels)
  expect_false(is.na(j))
  v <- res$nodes[[j]]
  names(v) <- rownames(res$nodes)
  expect_same_partition(v, c(BOSTON = 1, NY = 1, DC = 1, MIAMI = 2, CHICAGO = 1,
                             SEATTLE = 3, SF = 3, LA = 3, DENVER = 4))
  expect_equal(res$levels[1:3], c(206, 233, 379))
  expect_match(names(res$nodes)[1], "^1\\(8\\)206$")
})

test_that("the text cluster diagram is UCINET's, line for line", {
  res <- xhclust(cities, type = "d", method = "single", plot = FALSE)
  out <- capture.output(print(res))
  # Level labels are whole numbers here, so no decimals; the rule of dashes
  # spans the level column and every item.
  expect_true(any(out == "Level   4 6 7 8 1 2 3 5 9"))
  expect_true(any(out == "-----   - - - - - - - - -"))
  expect_true(any(out == "  206   . . . . XXX . . ."))
  expect_true(any(out == "  808   . XXXXX XXXXXXX ."))
  expect_true(any(out == " 1075   XXXXXXXXXXXXXXXXX"))
  expect_true(any(grepl("^Method: +SINGLE_LINK", out)))
  expect_true(any(grepl("^Type of Data: +Dissimilarities", out)))
})

test_that("the partition matrix is kept but not printed, as in UCINET", {
  res <- xhclust(cities, type = "d", method = "single", plot = FALSE)
  out <- capture.output(print(res))
  expect_false(any(grepl("Partition indicator matrix", out)))
  expect_true(any(grepl("Measures of cluster adequacy", out)))
  expect_equal(nrow(res$nodes), 9L)
})

test_that("levels below 1 print with four decimals, as getdd() decides", {
  m <- as.matrix(campnet); m <- (m + t(m)) / 2
  res <- xhclust(m, type = "s", plot = FALSE)
  expect_match(names(res$nodes)[1], "\\)0\\.0000$")
  expect_true(any(grepl("^0\\.0000   ", res$preamble)))
})

test_that("the printed report snapshot", {
  expect_snapshot(print(xhclust(cities, type = "d", method = "single", plot = FALSE)))
})

test_that("k fills the Cluster column without changing the rest", {
  a <- xhclust(cities, type = "d", plot = FALSE)
  b <- xhclust(cities, type = "d", k = 3, plot = FALSE)
  expect_true(all(is.na(a$nodes$Cluster)))
  keep <- setdiff(names(a$nodes), "Cluster")
  expect_identical(a$nodes[keep], b$nodes[keep])
  expect_true(is.na(a$summary[["Clusters requested"]]))
  expect_identical(b$nodes$Cluster, unname(cutree(a$hclust, k = 3)))
  expect_equal(b$summary[["Clusters requested"]], 3)
  expect_error(xhclust(cities, type = "d", k = 20, plot = FALSE), "between 1 and 9")
})

test_that("type is required, matched partially, and taught when missing", {
  expect_error(xhclust(cities, plot = FALSE), "needs to know what kind of matrix")
  expect_error(xhclust(cities, plot = FALSE), 'type = "dissimilarities"')
  expect_error(xhclust(cities, type = "x", plot = FALSE), "not recognised")
  a <- xhclust(cities, type = "dis", plot = FALSE)
  b <- xhclust(cities, type = "D", plot = FALSE)
  expect_identical(a$nodes, b$nodes)
  expect_identical(a$fields[["Type of Data:"]], "Dissimilarities")
})

test_that("input coercion: dist, data frame and asymmetric matrices", {
  d <- dist(as.matrix(cities)[, 1:3])
  res <- xhclust(d, type = "d", plot = FALSE)
  expect_identical(rownames(res$nodes), rownames(as.matrix(cities)))
  df <- as.data.frame(as.matrix(cities))
  expect_identical(xhclust(df, type = "d", plot = FALSE)$nodes, xhclust(cities, type = "d", plot = FALSE)$nodes)
  res <- xhclust(campnet, type = "s", plot = FALSE)
  expect_true(any(grepl("symmetrized by averaging", res$assumptions)))
  expect_error(xhclust(davis, type = "s", plot = FALSE), "square")
})

test_that("edge cases: missing values and a 2 x 2 matrix", {
  m <- as.matrix(cities); m[2, 5] <- m[5, 2] <- NA
  expect_error(xhclust(m, type = "d", plot = FALSE), "missing or infinite")
  m <- matrix(c(0, 3, 3, 0), 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  res <- xhclust(m, type = "d", plot = FALSE)
  expect_equal(res$summary$Levels, 1)
  expect_equal(res$levels, 3)
  expect_true(is.na(res$summary$Cophenetic))   # one pair: no variance to correlate
})

test_that("plot = TRUE draws without error on a null device and returns invisibly", {
  pdf(NULL); on.exit(dev.off())
  expect_invisible(xhclust(cities, type = "d"))
})

# ---- UCINET goldens (skip until inst/goldens/multivariate is generated) -----

golden_levels <- function(g) as.numeric(sub("^.*[)]", "", colnames(g)))

for (meth in c("single", "complete", "average")) {
  test_that(paste("levels and partitions of cities match UCINET's Johnson's,", meth, "link"), {
    nm <- paste0("g6_hc_cities_", meth)
    skip_if_no_golden(nm, "multivariate")
    gold <- golden_matrix(nm, "multivariate")
    res <- xhclust(cities, type = "d", method = meth, plot = FALSE)
    expect_equal(res$levels, golden_levels(gold), tolerance = 1e-6)
    for (j in seq_len(ncol(gold))) {
      expect_same_partition(res$nodes[[j]], unname(gold[rownames(res$nodes), j]),
                            info = paste(meth, "level", j))
    }
  })
}

test_that("the tie case: campnet levels match UCINET; merge order recorded if it differs", {
  skip_if_no_golden("g6_hc_campnet_average", "multivariate")
  gold <- golden_matrix("g6_hc_campnet_average", "multivariate")
  m <- as.matrix(campnet); m <- (m + t(m)) / 2
  res <- xhclust(m, type = "s", method = "average", plot = FALSE)
  expect_equal(res$levels, golden_levels(gold), tolerance = 1e-6)
  differing <- integer()
  for (j in seq_len(ncol(gold))) {
    if (!identical(outer(res$nodes[[j]], res$nodes[[j]], "=="),
                   outer(unname(gold[, j]), unname(gold[, j]), "=="))) differing <- c(differing, j)
  }
  # A difference here is the documented tie-breaking difference (ledger entry
  # 11). Report which levels rather than fail, but fail if the levels themselves
  # disagree, which the expect_equal above does.
  if (length(differing)) {
    message("campnet: partitions differ from UCINET at levels ", paste(differing, collapse = ", "),
            " (tie-breaking; ledger entry 11)")
  }
  succeed()
})
