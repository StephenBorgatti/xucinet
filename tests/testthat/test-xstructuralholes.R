# Structural holes (chapter 8, section 8.6.1).

tol <- 1e-8

star <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", c("b", "c", "d")] <- 1
  m[c("b", "c", "d"), "a"] <- 1
  m
}

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

# ---- layer (a): hand-computed ------------------------------------------------

test_that("the columns are UCINET's, for each model", {
  expect_equal(names(xstructuralholes(star())$nodes),
               c("Degree", "EffSize", "Efficiency", "Constraint", "Hierarchy",
                 "EgoBet", "Ln(Constraint)", "Indirects", "Density", "AvgDeg",
                 "Open Pairs"))
  expect_equal(names(xstructuralholes(star(), method = "whole")$nodes),
               c("EffSize", "Efficiency", "Constraint", "Hierarchy", "Indirects"))
  expect_equal(names(xstructuralholes(star())$matrices),
               c("Dyadic Redundancy", "Dyadic Constraint"))
})

test_that("the centre of a star has no redundancy and constraint 1/3", {
  # Each point takes a third of the centre's time; the points share nobody but
  # the centre, so p(a,q) m(j,q) is zero for every q other than a itself.
  r <- xstructuralholes(star())$nodes["a", ]
  expect_equal(r$Degree, 3)
  expect_equal(r$EffSize, 3)
  expect_equal(r$Efficiency, 1)
  expect_equal(r$Constraint, 3 * (1 / 3)^2)
  expect_equal(r$Hierarchy, 0, tolerance = tol)  # spread evenly
  expect_equal(r[["Ln(Constraint)"]], log(1 / 3))
  expect_equal(r$Indirects, 0)
  expect_equal(r$Density, 0)
  expect_equal(r$AvgDeg, 0)
  expect_equal(r[["Open Pairs"]], 6)             # ordered pairs of alters
  expect_equal(r$EgoBet, 6)                      # ordered pairs, not halved
})

test_that("a point of the star is a pendant, and gets the dialog's values", {
  r <- xstructuralholes(star())$nodes["b", ]
  expect_equal(r$Degree, 1)
  expect_equal(r$EffSize, 1)
  expect_true(is.na(r$Constraint))
  expect_equal(r$Hierarchy, 1)
  r2 <- xstructuralholes(star(), pendant = c(0.5, 1))$nodes["b", ]
  expect_equal(r2$EffSize, 0.5)
  expect_equal(r2$Constraint, 1)
})

test_that("an isolate gets the isolate values", {
  r <- xstructuralholes(star_iso())$nodes["e", ]
  expect_equal(r$Degree, 0)
  expect_equal(r$EffSize, 0)
  expect_true(is.na(r$Constraint))
  expect_true(is.na(r$Efficiency))
  expect_equal(xstructuralholes(star_iso(), isolate = c(0, 0))$nodes["e", "Constraint"], 0)
})

test_that("a triangle: each alter is half redundant", {
  # p(a,b) = p(a,c) = 1/2; m(b,c) = 1; pm(b) = p(a,c) m(b,c) = 1/2.
  res <- xstructuralholes(triangle())
  r <- res$nodes["a", ]
  expect_equal(r$EffSize, 1)
  expect_equal(r$Efficiency, 0.5)
  # dyadic constraint (1/2 + 1/2 * 1/2)^2 = 0.5625, twice
  expect_equal(r$Constraint, 2 * 0.5625)
  expect_equal(res$matrices$`Dyadic Constraint`["a", "b"], 0.5625)
  expect_equal(res$matrices$`Dyadic Redundancy`["a", "b"], 0.5)
  expect_equal(r$Hierarchy, 0, tolerance = tol)
  expect_equal(r$Indirects, 0.5)
})

test_that("the whole-network model agrees with the ego model on a star", {
  # Nobody in a star has a tie outside the centre's ego network.
  e <- xstructuralholes(star())$nodes
  w <- xstructuralholes(star(), method = "whole")$nodes
  expect_equal(w["a", "Constraint"], e["a", "Constraint"])
  expect_equal(w["a", "EffSize"], e["a", "EffSize"])
  # the whole model has no pendant rule: a point is fully constrained by a
  expect_equal(w["b", "Constraint"], 1)
  expect_equal(w["b", "Hierarchy"], 1)
})

test_that("the two models differ once alters have ties outside the ego network", {
  e <- xstructuralholes(campnet)$nodes$Constraint
  w <- xstructuralholes(campnet, method = "whole")$nodes$Constraint
  expect_false(isTRUE(all.equal(e, w)))
})

test_that("tie values are used, and summed across the diagonal ala Burt", {
  m <- star()
  m["a", "b"] <- 3                               # a -> b is strong, b -> a is 1
  r <- xstructuralholes(m)$nodes["a", ]
  # z(a,b) + z(b,a) = 4 against 2 and 2: p = 1/2, 1/4, 1/4
  expect_equal(r$Constraint, (1 / 2)^2 + 2 * (1 / 4)^2)
  r2 <- xstructuralholes(m, symmetrize = FALSE)$nodes["a", ]
  # out-ties only: 3, 1, 1 out of 5
  expect_equal(r2$Constraint, (3 / 5)^2 + 2 * (1 / 5)^2)
})

test_that("direction defines the ego network", {
  m <- matrix(0, 3, 3, dimnames = list(letters[1:3], letters[1:3]))
  m["a", "b"] <- 1
  m["c", "a"] <- 1
  expect_equal(xstructuralholes(m)$nodes["a", "Degree"], 2)
  expect_equal(xstructuralholes(m, direction = "out")$nodes["a", "Degree"], 1)
  expect_equal(xstructuralholes(m, direction = "reciprocated")$nodes["a", "Degree"], 0)
})

test_that("the diagonal is ignored unless it is valid", {
  m <- triangle()
  diag(m) <- 5
  expect_equal(xstructuralholes(m)$nodes, xstructuralholes(triangle())$nodes)
})

test_that("bad isolate or pendant values are refused", {
  expect_error(xstructuralholes(star(), isolate = 0), "pair")
})

test_that("2-mode data are refused", {
  expect_error(xstructuralholes(davis), "1-mode")
})

test_that("the report prints", {
  expect_snapshot(xstructuralholes(campnet))
})

# ---- layer (b): cross-check against igraph -----------------------------------

test_that("the whole-network model is igraph's constraint on symmetric data", {
  skip_if_not_installed("igraph")
  # On an undirected binary graph both compute Burt's p(i,j) = a(i,j)/deg(i)
  # over the whole network and sum (p(i,j) + sum_q p(i,q) p(q,j))^2 over i's
  # neighbours, so they must agree. Ledger entry 17.
  u <- pmax(as.matrix(campnet), t(as.matrix(campnet)))
  g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected")
  expect_equal(xstructuralholes(u, method = "whole")$nodes$Constraint,
               unname(igraph::constraint(g)), tolerance = tol)
})

test_that("the default ego-network model is NOT igraph's constraint", {
  skip_if_not_installed("igraph")
  # The ego-network model takes p(q,j) inside ego's network only, so an alter
  # with ties outside it weighs less. If this ever starts passing as equal,
  # one of the two definitions has moved. Ledger entry 17.
  u <- pmax(as.matrix(campnet), t(as.matrix(campnet)))
  g <- igraph::graph_from_adjacency_matrix(u, mode = "undirected")
  expect_false(isTRUE(all.equal(xstructuralholes(u)$nodes$Constraint,
                                unname(igraph::constraint(g)))))
})

# ---- layer (c): goldens -------------------------------------------------------
#
# holes() is the command-line form of the ego-network model. It writes
# fourteen columns: the eleven here plus Term1-Term3 of Burt's decomposition,
# which the dialog does not print.

holes_golden <- function(name, res) {
  g <- golden_matrix(name, "ego")
  expect_equal(unname(as.matrix(res$nodes)), unname(g[, 1:11]), tolerance = 1e-5)
}

test_that("campnet matches UCINET", {
  skip_if_no_golden("g8_holes_campnet", "ego")
  holes_golden("g8_holes_campnet", xstructuralholes(campnet))
})

test_that("hightech advice, valued, matches UCINET", {
  skip_if_no_golden("g8_holes_hightech", "ego")
  holes_golden("g8_holes_hightech", xstructuralholes(hightech))
})

test_that("sampson's first relation, ranked choices, matches UCINET", {
  skip_if_no_golden("g8_holes_sampson", "ego")
  holes_golden("g8_holes_sampson", xstructuralholes(sampson))
})

test_that("g9_iso and g9_disc match UCINET", {
  skip_if_no_golden("g8_holes_iso", "ego")
  skip_if_no_golden("g8_holes_disc", "ego")
  iso <- xreaducinet(file.path(goldens_dir("centrality"), "g9_iso"))
  disc <- xreaducinet(file.path(goldens_dir("centrality"), "g9_disc"))
  holes_golden("g8_holes_iso", xstructuralholes(iso))
  holes_golden("g8_holes_disc", xstructuralholes(disc))
})

test_that("the dyadic matrices match UCINET's menu run", {
  skip_if_no_golden("g8_holes_campnet_dr", "ego")
  skip_if_no_golden("g8_holes_campnet_dc", "ego")
  res <- xstructuralholes(campnet)
  expect_equal(unname(res$matrices$`Dyadic Redundancy`),
               unname(golden_matrix("g8_holes_campnet_dr", "ego")), tolerance = 1e-5)
  expect_equal(unname(res$matrices$`Dyadic Constraint`),
               unname(golden_matrix("g8_holes_campnet_dc", "ego")), tolerance = 1e-5)
})
