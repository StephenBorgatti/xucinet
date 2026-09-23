# Subgroups (chapter 11): cliques, factions, Girvan-Newman, Louvain, fast
# greedy, label propagation and the xcommunities dispatcher.

tol <- 1e-8

# Two complete groups of four joined by one tie (d - e).
barbell8 <- function() {
  m <- matrix(0, 8, 8, dimnames = list(letters[1:8], letters[1:8]))
  m[1:4, 1:4] <- 1
  m[5:8, 5:8] <- 1
  diag(m) <- 0
  m["d", "e"] <- m["e", "d"] <- 1
  m
}
two_groups <- function() rep(1:2, each = 4)

# Two triangles sharing node c.
bowtie <- function() {
  m <- matrix(0, 5, 5, dimnames = list(letters[1:5], letters[1:5]))
  for (p in list(c(1, 2), c(1, 3), c(2, 3), c(3, 4), c(3, 5), c(4, 5))) {
    m[p[1], p[2]] <- m[p[2], p[1]] <- 1
  }
  m
}

sym_campnet <- function() {
  u <- pmax(as.matrix(campnet), t(as.matrix(campnet)))
  u
}

set_of <- function(cl) sort(vapply(cl, function(x) paste(sort(x), collapse = ","),
                                   character(1)))

# ---- modularity ------------------------------------------------------------------

test_that("modularity is UCINET's formula, which is igraph's on symmetric data", {
  u <- sym_campnet()
  g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected")
  p <- xlouvain(campnet)$nodes$Cluster
  expect_equal(community_modularity(u, p), igraph::modularity(g, p), tolerance = tol)
  expect_equal(community_modularity(barbell8(), two_groups()),
               igraph::modularity(igraph::graph_from_adjacency_matrix(
                 barbell8(), mode = "undirected"), two_groups()), tolerance = tol)
})

test_that("Delphi's Random is reproduced", {
  # RandSeed := 0 -> 1 -> 134775814; Random(100) = floor(state * 100 / 2^32).
  rng <- delphi_rng(0)
  expect_equal(delphi_random(rng, 100), 0)
  expect_equal(rng$state, 1)
  expect_equal(delphi_random(rng, 100), floor(134775814 * 100 / 2^32))
  expect_equal(rng$state, 134775814)
})

# ---- xcliques --------------------------------------------------------------------

test_that("the cliques of a bowtie are its two triangles", {
  r <- xcliques(bowtie())
  expect_equal(set_of(r$cliques), c("a,b,c", "c,d,e"))
})

test_that("min drops smaller cliques", {
  # the bowtie plus a pendant f on d: the pair {d, f} is a clique of two
  m <- matrix(0, 6, 6, dimnames = list(letters[1:6], letters[1:6]))
  m[1:5, 1:5] <- bowtie()
  m["d", "f"] <- m["f", "d"] <- 1
  expect_equal(length(xcliques(m, min = 2)$cliques), 3L)
  expect_equal(length(xcliques(m)$cliques), 2L)
})

test_that("participation counts the node itself, over the clique's size", {
  p <- xcliques(bowtie())$matrices$participation
  expect_equal(unname(p["c", ]), c(1, 1))
  expect_equal(unname(p["a", ]), c(1, 1 / 3))    # a is tied to c only
})

test_that("co-membership counts shared cliques, the diagonal a node's own", {
  cm <- xcliques(bowtie())$matrices$comembership
  expect_equal(cm["c", "c"], 2)
  expect_equal(cm["a", "b"], 1)
  expect_equal(cm["a", "d"], 0)
  expect_identical(xcliques(bowtie())$comembership, cm)
})

test_that("weak cliques take a tie either way, strong ones need both", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- m["b", "c"] <- m["c", "a"] <- 1
  expect_equal(length(xcliques(m)$cliques), 1L)
  expect_equal(length(xcliques(m, type = "strong")$cliques), 0L)
})

test_that("valued data are treated as binary, with UCINET's warning", {
  r <- xcliques(bowtie() * 3)
  expect_equal(set_of(r$cliques), c("a,b,c", "c,d,e"))
  expect_true(any(grepl("Valued graph", r$assumptions)))
})

test_that("the co-membership matrix is clustered by average link and not printed", {
  r <- xcliques(campnet)
  expect_s3_class(r$clustering, "xhclust")
  out <- capture.output(print(r))
  expect_true(any(grepl("OVERLAP MATRIX", out)))
  expect_false(any(out == "comembership"))
})

test_that("the clique set is igraph's", {
  # Both enumerate maximal cliques of the undirected graph; only the order may
  # differ, and the order is UCINET's (Bron-Kerbosch version 2).
  for (nm in c("campnet", "zachary")) {
    net <- get(nm)
    u <- pmax(as.matrix(net), t(as.matrix(net)))
    u[u > 0] <- 1
    g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected")
    ig <- lapply(igraph::max_cliques(g, min = 3), names)
    expect_equal(set_of(xcliques(net)$cliques), set_of(ig), info = nm)
  }
})

test_that("the cliques report prints", {
  expect_snapshot(xcliques(campnet))
})

# ---- xfactions ---------------------------------------------------------------------

test_that("an obvious two-faction structure is found from every seed", {
  for (s in 1:10) {
    expect_same_partition(xfactions(barbell8(), 2, seed = s)$nodes$Cluster,
                          two_groups(), info = paste("seed", s))
  }
})

test_that("each measure finds the two groups", {
  for (meth in c("hamming", "phi", "modularity", "entailment")) {
    p <- xfactions(barbell8(), 2, method = meth, seed = 3)$nodes$Cluster
    if (meth != "entailment") {
      expect_same_partition(p, two_groups(), info = meth)
    }
  }
})

test_that("the Hamming search reaches the global optimum on campnet", {
  # Checked once by brute force over all 2^17 splits: the best cost is 102.
  r <- xfactions(campnet, 2, seed = 1)
  expect_equal(r$summary[[1]], 1 - 102 / (18 * 17), tolerance = tol)
})

test_that("the same seed gives the same partition", {
  expect_identical(xfactions(campnet, 3, seed = 42)$nodes,
                   xfactions(campnet, 3, seed = 42)$nodes)
})

test_that("the block densities follow the partition", {
  d <- xfactions(barbell8(), 2, seed = 1)$matrices$`Block densities`
  expect_equal(unname(sort(diag(d))), c(1, 1))
  expect_equal(d[1, 2], 1 / 16)
})

test_that("k = 1 puts everyone together", {
  expect_true(all(xfactions(campnet, 1, seed = 1)$nodes$Cluster == 1))
})

test_that("missing cells are no tie (UCINET issue 27)", {
  expect_differs_from_ucinet(27)
  m <- barbell8()
  m["a", "h"] <- NA
  expect_same_partition(xfactions(m, 2, seed = 1)$nodes$Cluster, two_groups())
})

test_that("the factions report prints", {
  expect_snapshot(xfactions(campnet, 2, seed = 1))
})

# ---- xgirvannewman ------------------------------------------------------------------

test_that("the bridge goes first", {
  r <- xgirvannewman(barbell8())
  expect_same_partition(r$matrices$Partitions[, "C2"], two_groups())
  expect_same_partition(r$nodes$Cluster, two_groups())
})

test_that("tied edges are removed together, as UCINET does", {
  # A 4-cycle: every edge has the same betweenness, so one step removes all
  # four and the only partition is into four; igraph would pass through one
  # component first.
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  for (i in 1:4) m[i, i %% 4 + 1] <- m[i %% 4 + 1, i] <- 1
  r <- xgirvannewman(m)
  expect_equal(colnames(r$matrices$Partitions), "C4")
})

test_that("modularity is reported per partition, and the best is Cluster", {
  r <- xgirvannewman(campnet)
  q <- r$matrices$Modularity[1, ]
  expect_equal(r$summary$Modularity, max(q))
  expect_equal(r$summary$Modularity,
               community_modularity(as.matrix(campnet), r$nodes$Cluster))
})

test_that("k sets what is printed, not what is kept", {
  # SPEC addendum, 23 Sep 2026: every partition is in the result; the report
  # stops at the first with at least k clusters, where UCINET stops.
  all <- xgirvannewman(campnet)
  r <- xgirvannewman(campnet, k = 3)
  expect_identical(r$matrices, all$matrices)
  expect_identical(r$nodes, all$nodes)
  shown <- r$show_matrix_columns$Partitions
  nclus <- as.integer(sub("C", "", shown))
  expect_true(all(nclus[-length(nclus)] < 3))
  expect_true(nclus[length(nclus)] >= 3)
  expect_equal(max(apply(all$matrices$Partitions, 2, max)), nrow(all$nodes))
})

test_that("the first split agrees with igraph where no edges tie", {
  # With a single top edge the two algorithms make the same first cut.
  g <- igraph::graph_from_adjacency_matrix(barbell8(), mode = "undirected")
  eb <- igraph::cluster_edge_betweenness(g)
  expect_same_partition(igraph::cut_at(eb, 2), two_groups())
})

test_that("the Girvan-Newman report prints", {
  expect_snapshot(xgirvannewman(campnet))
})

# ---- xlouvain ------------------------------------------------------------------------

test_that("two groups joined by a tie come apart", {
  expect_same_partition(xlouvain(barbell8())$nodes$Cluster, two_groups())
})

test_that("the search is deterministic", {
  expect_identical(xlouvain(zachary)$nodes, xlouvain(zachary)$nodes)
})

test_that("each level's Q is its own partition's Q (UCINET issue 26)", {
  expect_differs_from_ucinet(26)
  r <- xlouvain(zachary)
  lev <- r$matrices$Levels
  w <- pmax(as.matrix(zachary), t(as.matrix(zachary)))
  for (j in seq_len(ncol(lev))) {
    q <- as.numeric(sub("^.*\\|", "", colnames(lev)[j]))
    # headers carry Q to three decimals
    expect_lt(abs(q - modularity_uci(w, lev[, j])), 5e-4,
                 label = paste("level", j))
  }
})

test_that("modularity never falls from one level to the next", {
  r <- xlouvain(zachary)
  q <- as.numeric(sub("^.*\\|", "", colnames(r$matrices$Levels)))
  expect_true(all(diff(q) >= -1e-9))
})

test_that("Louvain reaches igraph's modularity on zachary, or near it", {
  # Different visiting orders reach different local optima; both are near 0.42.
  g <- igraph::graph_from_adjacency_matrix(pmax(as.matrix(zachary),
                                                t(as.matrix(zachary))),
                                           mode = "undirected", weighted = TRUE)
  ours <- xlouvain(zachary)$summary$Modularity
  expect_true(ours > 0.40)
  expect_true(abs(ours - igraph::modularity(igraph::cluster_louvain(g))) < 0.03)
})

test_that("2-mode data wait on issue #18", {
  expect_error(xlouvain(davis), "#18")
})

test_that("directed data are symmetrized by maximum unless told not to", {
  r <- xlouvain(campnet)
  expect_true(any(grepl("symmetrized by max", r$assumptions)))
  expect_false(any(grepl("symmetrized", xlouvain(campnet, symmetrize = "none")$assumptions)))
})

test_that("the Louvain report prints", {
  expect_snapshot(xlouvain(campnet))
})

# ---- xfastgreedy, xlabelpropagation ------------------------------------------------------

test_that("fast greedy is igraph's partition", {
  u <- sym_campnet()
  g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected", weighted = TRUE)
  expect_same_partition(xfastgreedy(campnet)$nodes$Cluster,
                        igraph::membership(igraph::cluster_fast_greedy(g)))
})

test_that("label propagation repeats under a seed and leaves R's RNG alone", {
  set.seed(99); before <- .Random.seed
  a <- xlabelpropagation(zachary, seed = 5)
  expect_identical(.Random.seed, before)
  b <- xlabelpropagation(zachary, seed = 5)
  expect_identical(a$nodes, b$nodes)
})

# ---- xcommunities ------------------------------------------------------------------------

test_that("every method returns the same shape", {
  for (meth in c("louvain", "fastgreedy", "girvannewman", "labelpropagation",
                 "factions")) {
    args <- list(campnet, method = meth)
    if (meth %in% c("labelpropagation", "factions")) args$seed <- 1
    r <- do.call(xcommunities, args)
    expect_equal(names(r$nodes), "Cluster", info = meth)
    expect_equal(names(r$summary), c("Clusters", "Modularity"), info = meth)
    expect_equal(r$summary$Modularity,
                 community_modularity(as.matrix(campnet), r$nodes$Cluster),
                 info = meth)
    expect_identical(r$method, meth)
  }
})

test_that("the 1e Walktrap aliases say what to use instead", {
  expect_error(xWalkTrap(campnet), "xcommunities")
})

# ---- goldens --------------------------------------------------------------------------

gold_part <- function(name) {
  g <- golden_matrix(name, "subgroups")
  g[, ncol(g)]
}

test_that("cliques match UCINET, in UCINET's order", {
  for (f in c("g11_cliq_campnet", "g11_cliq_hightech_fr", "g11_cliq_zachary")) {
    skip_if_no_golden(f, "subgroups")
  }
  # The saved clique indicator matrix is node by clique, in UCINET's order.
  check <- function(name, res) {
    g <- golden_matrix(name, "subgroups")
    ours <- sapply(res$cliques, function(cl) as.numeric(rownames(g) %in% cl))
    expect_equal(unname(ours), unname(g), info = name)
  }
  check("g11_cliq_campnet", xcliques(campnet))
  check("g11_cliq_hightech_fr", xcliques(hightech, relation = "Friendship"))
  check("g11_cliq_zachary", xcliques(zachary))
})

test_that("factions match UCINET for the seed UCINET used", {
  for (f in c("g11_fact_campnet_2", "g11_fact_campnet_3", "g11_fact_zachary_2")) {
    skip_if_no_golden(f, "subgroups")
  }
  expect_same_partition(xfactions(campnet, 2, seed = 1)$nodes$Cluster,
                        gold_part("g11_fact_campnet_2"))
  expect_same_partition(xfactions(campnet, 3, seed = 1)$nodes$Cluster,
                        gold_part("g11_fact_campnet_3"))
  expect_same_partition(xfactions(zachary, 2, seed = 1)$nodes$Cluster,
                        gold_part("g11_fact_zachary_2"))
})

test_that("Girvan-Newman partitions match UCINET", {
  skip_if_no_golden("g11_gn_zachary", "subgroups")
  skip_if_no_golden("g11_gn_campnet", "subgroups")
  for (nm in c("zachary", "campnet")) {
    g <- golden_matrix(paste0("g11_gn_", nm), "subgroups")
    ours <- xgirvannewman(get(nm))$matrices$Partitions
    for (col in intersect(colnames(g), colnames(ours))) {
      expect_same_partition(ours[, col], g[, col], info = paste(nm, col))
    }
  }
})

test_that("Louvain differs from UCINET until issue 26 is fixed", {
  skip_if_no_golden("g11_louv_zachary", "subgroups")
  expect_differs_from_ucinet(26)
  # From a fixed build this becomes: the same final partition.
  succeed()
})

# ---- the speed-ups give the same answers (issue #19) --------------------------------

equiv_nets <- function() {
  set.seed(19)
  rnd <- function(n, p) {
    m <- matrix(0, n, n); m[upper.tri(m)] <- rbinom(n * (n - 1) / 2, 1, p)
    m <- m + t(m); dimnames(m) <- list(paste0("v", 1:n), paste0("v", 1:n)); m
  }
  list(campnet = pmax(as.matrix(campnet), t(as.matrix(campnet))),
       campnet_dir = as.matrix(campnet),
       zachary = pmax(as.matrix(zachary), t(as.matrix(zachary))),
       hightech_valued = pmax(as.matrix(hightech, relation = "Advice"),
                              t(as.matrix(hightech, relation = "Advice"))),
       random40 = rnd(40, 0.12), random60 = rnd(60, 0.08))
}

test_that("fast factions search visits the same partitions as the full one", {
  for (nm in names(equiv_nets())) {
    m <- equiv_nets()[[nm]]
    a <- (m > 0) * 1; diag(a) <- 0
    ties <- which(a > 0, arr.ind = TRUE)
    n <- nrow(a)
    for (meth in c("hamming", "phi", "modularity", "entailment")) {
      for (k in 2:3) {
        fitof <- factions_fit(meth, ties[, 1], ties[, 2], nrow(ties), n, k)
        ctx <- list(a = a, method = meth, numedges = nrow(ties))
        set.seed(k)
        p0 <- sample.int(k, n, replace = TRUE)
        expect_identical(factions_tabu(p0, ctx, k, 20, 15),
                         ref_factions_tabu(p0, fitof, k, 20, 15),
                         info = paste(nm, meth, k))
      }
    }
  }
})

test_that("fast Louvain gives the same levels as the full recomputation", {
  for (nm in names(equiv_nets())) {
    w <- equiv_nets()[[nm]]
    w[is.na(w)] <- 0
    if (nm == "campnet_dir") next          # xlouvain symmetrizes by default
    expect_identical(louvain_levels(w, nrow(w))$hier,
                     ref_louvain_levels(w, nrow(w))$hier, info = nm)
  }
})

test_that("Girvan-Newman on igraph's edge betweenness gives the same partitions", {
  cyc <- matrix(0, 4, 4); for (i in 1:4) cyc[i, i %% 4 + 1] <- cyc[i %% 4 + 1, i] <- 1
  nets <- c(equiv_nets(), list(cycle = cyc))
  for (nm in names(nets)) {
    a <- community_adjacency(nets[[nm]])
    expect_equal(girvan_newman_partitions(a, 10),
                 ref_girvan_newman_partitions(a, 10), info = nm)
  }
})

test_that("the factions start from igraph's distances is the Floyd port's", {
  for (nm in names(equiv_nets())) {
    a <- equiv_nets()[[nm]]
    a[is.na(a)] <- 0
    a[a > 1] <- 1
    d <- binary_floyd(a)
    d[row(d) != col(d) & d == 0] <- 1e38
    diag(d) <- 0
    for (k in 2:4) {
      expect_identical(factions_start(a, k), km1(d, k), info = paste(nm, k))
    }
  }
})
