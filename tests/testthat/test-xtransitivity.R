# Reciprocity, transitivity and cyclicality (chapter 10, sections 10.2.2 and
# 10.2.3).
#
# The strongest check available before the goldens are generated is internal
# agreement: xcohesion's block was validated against real UCINET output, and
# three of its 33 measures are what these routines report, so they have to
# match it to the digit.

tol <- 1e-8

# a <-> b, a -> c, c <-> d: one mutual pair either side of one lone arc.
hand4 <- function() {
  matrix(c(0, 1, 1, 0,
           1, 0, 0, 0,
           0, 0, 0, 1,
           0, 0, 1, 0), 4, 4, byrow = TRUE,
         dimnames = list(letters[1:4], letters[1:4]))
}

nm3 <- list(letters[1:3], letters[1:3])
blank3 <- function() matrix(0, 3, 3, dimnames = nm3)

# ---- xreciprocity ------------------------------------------------------------

test_that("both ratios are always reported, whichever is asked for", {
  for (meth in c("dyad", "arc", "hybrid")) {
    s <- xreciprocity(campnet, method = meth)$summary
    expect_true(all(c("Dyad Reciprocity", "Arc Reciprocity") %in% names(s)),
                info = meth)
  }
})

test_that("method chooses the order, not the content", {
  a <- xreciprocity(campnet, method = "dyad")$summary
  b <- xreciprocity(campnet, method = "arc")$summary
  expect_equal(names(a)[1], "Dyad Reciprocity")
  expect_equal(names(b)[1], "Arc Reciprocity")
  expect_equal(a[["Dyad Reciprocity"]], b[["Dyad Reciprocity"]])
})

test_that("hybrid is the dyad ratio at the whole-network level", {
  # UCINET's log: "in the hybrid method, the overall and node-level
  # reciprocity values are the same as in the dyad-based model".
  expect_equal(xreciprocity(campnet, method = "hybrid")$summary[["Dyad Reciprocity"]],
               xreciprocity(campnet, method = "dyad")$summary[["Dyad Reciprocity"]])
})

test_that("the ratios are what they say, by hand", {
  # 5 arcs, 4 reciprocated; 3 non-null dyads, 2 mutual.
  s <- xreciprocity(hand4())$summary
  expect_equal(s[["Arc Reciprocity"]], 4 / 5)
  expect_equal(s[["Dyad Reciprocity"]], 4 / (4 + 2 * 1))
})

test_that("the ratios agree with xcohesion's, which UCINET validated", {
  co <- as.matrix(xcohesion(campnet)$summary)
  s <- xreciprocity(campnet)$summary
  expect_equal(s[["Dyad Reciprocity"]], co["Dyad Reciprocity", 1], tolerance = tol)
  expect_equal(s[["Arc Reciprocity"]], co["Arc Reciprocity", 1], tolerance = tol)
})

test_that("the node table is UCINET's six proportions in its order", {
  n <- xreciprocity(campnet)$nodes
  expect_equal(names(n), c("Node", "Symmetric", "Non-Symmetric", "Out/NonSym",
                           "In/NonSym", "Sym/Out", "Sym/In"))
  expect_equal(nrow(n), 18)
  # Symmetric and Non-Symmetric partition the contacts
  ok <- !is.na(n$Symmetric)
  expect_equal(n$Symmetric[ok] + n$`Non-Symmetric`[ok], rep(1, sum(ok)))
})

test_that("node-level reciprocity is what it says, by hand", {
  n <- xreciprocity(hand4())$nodes
  # a has contacts b (mutual) and c (one-way out): half symmetric
  expect_equal(n$Symmetric[n$Node == "a"], 0.5)
  expect_equal(n$`Out/NonSym`[n$Node == "a"], 1)   # the lone asymmetry is outgoing
  expect_equal(n$`In/NonSym`[n$Node == "a"], 0)
  # b has only a, and it is mutual
  expect_equal(n$Symmetric[n$Node == "b"], 1)
})

test_that("valued data are not dichotomized, and the notice explains why", {
  # The routine prints "Data are valued. Remember that xij = 3 will not match
  # xji = 2" and then compares values. Ledger entry 16.
  a <- xreciprocity(baker_journals)
  expect_true(any(grepl("not been dichotomized", a$assumptions)))
  expect_true(any(grepl("3 does not match", a$assumptions)))
})

test_that("node-level symmetry is value equality, not just presence", {
  # A pair of unequal positive values is a tie both ways but not symmetric.
  m <- blank3()
  m["a", "b"] <- 3; m["b", "a"] <- 2
  n <- xreciprocity(m)$nodes
  expect_equal(n$Symmetric[n$Node == "a"], 0)
  # while the whole-network arc ratio counts it as reciprocated, because that
  # half of the report tests presence
  expect_equal(xreciprocity(m)$summary[["Arc Reciprocity"]], 1)
})

test_that("xreciprocity refuses 2-mode data", {
  expect_error(xreciprocity(davis), "1-mode")
})

# ---- xtransitivity, triplets -------------------------------------------------

test_that("the triplet report is UCINET's twelve measures plus clustering", {
  s <- xtransitivity(campnet)$summary
  expect_equal(names(s)[1:6], c("Threes", "Twos", "Transitivity", "Density",
                                "Ratio", "Transitivity Index"))
  expect_equal(names(s)[7:12], c("TP Covariance", "Transitivity Phi",
                                 "Transitivity Phi Beta", "T Covariance",
                                 "Transitivity Correlation", "Transitivity Beta"))
  # question 10.2 folds this one in
  expect_true("Clustering Coefficient" %in% names(s))
})

test_that("transitivity agrees with xcohesion, which UCINET validated", {
  co <- as.matrix(xcohesion(campnet)$summary)
  s <- xtransitivity(campnet)$summary
  expect_equal(s[["Transitivity"]], co["Transitivity/Closure", 1], tolerance = tol)
  expect_equal(s[["Transitivity Index"]], co["Transitivity Index", 1], tolerance = tol)
  expect_equal(s[["Density"]], co["Density", 1], tolerance = tol)
})

test_that("the counts are two-paths and the transitive ones among them", {
  # hand4: the two-paths are a->c->d and b->a->c, neither closed.
  s <- xtransitivity(hand4())$summary
  expect_equal(s[["Twos"]], 2)
  expect_equal(s[["Threes"]], 0)
  expect_equal(s[["Transitivity"]], 0)
})

test_that("a transitive triple is entirely transitive", {
  m <- blank3()
  m["a", "b"] <- 1; m["a", "c"] <- 1; m["b", "c"] <- 1
  s <- xtransitivity(m)$summary
  expect_equal(s[["Twos"]], 1)         # a -> b -> c
  expect_equal(s[["Threes"]], 1)       # closed by a -> c
  expect_equal(s[["Transitivity"]], 1)
})

test_that("the centred measures follow FinalizeTransitivity", {
  # Recomputed here from the four sufficient counts, the way the Delphi does.
  m <- as.matrix(campnet)
  a <- (m > 0) * 1; diag(a) <- 0
  n <- nrow(a)
  s2 <- a %*% a; diag(s2) <- 0
  off <- row(a) != col(a)
  twos <- sum(s2[off]); threes <- sum(s2[off] * (a[off] > 0))
  ties <- sum(a)
  n2 <- n * (n - 1); n3 <- n2 * (n - 2)
  d <- ties / n2
  got <- xtransitivity(campnet)$summary
  expect_equal(got[["TP Covariance"]], (threes - d * twos) / n3, tolerance = tol)
  expect_equal(got[["T Covariance"]], (threes - d * twos) / n2, tolerance = tol)
  # the dyadic covariance is (n-2) times the triadic one
  expect_equal(got[["T Covariance"]], (n - 2) * got[["TP Covariance"]],
               tolerance = 1e-6)
})

# ---- xtransitivity, triads ---------------------------------------------------

test_that("the triad report is UCINET's three counts", {
  s <- xtransitivity(campnet, method = "triads")$summary
  expect_equal(names(s)[1:3], c("Trans", "Trans+InTrans", "Transitivity"))
  expect_equal(s[["Transitivity"]], s[["Trans"]] / s[["Trans+InTrans"]])
})

test_that("the census covers every triple exactly once", {
  for (net in list(campnet, hightech, hand4())) {
    cen <- xucinet:::triad_census(xucinet:::binary_offdiag(as.matrix(net)))
    n <- nrow(as.matrix(net))
    expect_equal(sum(cen), choose(n, 3))
  }
})

test_that("every one of the sixteen types is recognised", {
  # One hand-built example of each, which is the only way to be sure the
  # D/U/C splits are the right way round.
  z <- blank3()
  cases <- list(
    "003" = z,
    "012" = local({ m <- z; m["a","b"] <- 1; m }),
    "102" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m }),
    "021D" = local({ m <- z; m["a","b"] <- m["a","c"] <- 1; m }),
    "021U" = local({ m <- z; m["b","a"] <- m["c","a"] <- 1; m }),
    "021C" = local({ m <- z; m["a","b"] <- m["b","c"] <- 1; m }),
    "111D" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m["c","a"] <- 1; m }),
    "111U" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m["a","c"] <- 1; m }),
    "030T" = local({ m <- z; m["a","b"] <- m["a","c"] <- m["b","c"] <- 1; m }),
    "030C" = local({ m <- z; m["a","b"] <- m["b","c"] <- m["c","a"] <- 1; m }),
    "201" = local({ m <- z; m["a","b"] <- m["b","a"] <- m["a","c"] <- m["c","a"] <- 1; m }),
    "120D" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m["c","a"] <- m["c","b"] <- 1; m }),
    "120U" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m["a","c"] <- m["b","c"] <- 1; m }),
    "120C" = local({ m <- z; m["a","b"] <- m["b","a"] <- 1; m["c","a"] <- m["b","c"] <- 1; m }),
    "210" = local({ m <- z; m["a","b"] <- m["b","a"] <- m["a","c"] <- m["c","a"] <- 1
                    m["b","c"] <- 1; m }),
    "300" = local({ m <- matrix(1, 3, 3, dimnames = nm3); diag(m) <- 0; m }))
  for (want in names(cases)) {
    cen <- stats::setNames(
      xucinet:::triad_census(xucinet:::binary_offdiag(cases[[want]])),
      xucinet:::triad_names)
    expect_equal(names(cen)[cen == 1], want, info = want)
  }
})

test_that("the transitive and intransitive sets are UCINET's", {
  # t = 030T, 120D, 120U, 300; it = 021C, 111D, 111U, 030C, 201, 120C, 210.
  tri <- blank3()
  tri["a", "b"] <- tri["a", "c"] <- tri["b", "c"] <- 1     # 030T
  s <- xtransitivity(tri, method = "triads")$summary
  expect_equal(s[["Trans"]], 1)
  expect_equal(s[["Trans+InTrans"]], 1)

  cyc <- blank3()
  cyc["a", "b"] <- cyc["b", "c"] <- cyc["c", "a"] <- 1     # 030C
  s2 <- xtransitivity(cyc, method = "triads")$summary
  expect_equal(s2[["Trans"]], 0)
  expect_equal(s2[["Trans+InTrans"]], 1)
  expect_equal(s2[["Transitivity"]], 0)
})

test_that("a vacuous triple counts in neither", {
  # 003 and 012 are neither transitive nor intransitive.
  s <- xtransitivity(blank3(), method = "triads")$summary
  expect_equal(s[["Trans+InTrans"]], 0)
  expect_true(is.na(s[["Transitivity"]]))
})

# ---- xcyclicality ------------------------------------------------------------

test_that("the cyclicality report is UCINET's six measures", {
  s <- xcyclicality(campnet)$summary
  expect_equal(names(s), c("Threes", "Twos", "Cyclicality", "Density", "Ratio",
                           "Cyclicity Index"))
})

test_that("cyclicality counts the same two-paths as transitivity", {
  expect_equal(xcyclicality(campnet)$summary[["Twos"]],
               xtransitivity(campnet)$summary[["Twos"]])
})

test_that("a three-cycle is wholly cyclic and not at all transitive", {
  m <- blank3()
  m["a", "b"] <- m["b", "c"] <- m["c", "a"] <- 1
  expect_equal(xcyclicality(m)$summary[["Cyclicality"]], 1)
  expect_equal(xtransitivity(m)$summary[["Transitivity"]], 0)
})

test_that("a transitive triple is not at all cyclic", {
  m <- blank3()
  m["a", "b"] <- m["a", "c"] <- m["b", "c"] <- 1
  expect_equal(xcyclicality(m)$summary[["Cyclicality"]], 0)
})

test_that("the density matches the other routines", {
  expect_equal(xcyclicality(campnet)$summary[["Density"]],
               xtransitivity(campnet)$summary[["Density"]], tolerance = tol)
})

test_that("both refuse 2-mode data and dichotomize valued data", {
  expect_error(xtransitivity(davis), "1-mode")
  expect_error(xcyclicality(davis), "1-mode")
  expect_true(any(grepl("dichotomized", xtransitivity(baker_journals)$assumptions)))
  expect_true(any(grepl("dichotomized", xcyclicality(baker_journals)$assumptions)))
})

test_that("the reports print", {
  expect_snapshot(xreciprocity(campnet))
  expect_snapshot(xtransitivity(campnet))
  expect_snapshot(xcyclicality(campnet))
})
