# Reciprocity, transitivity and cyclicality (chapter 10, sections 10.2.2,
# 10.2.3 and 10.2.4).
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

test_that("method chooses the printed order, not the content", {
  a <- xreciprocity(campnet, method = "dyad")
  b <- xreciprocity(campnet, method = "arc")
  expect_identical(a$summary, b$summary)
  expect_null(a$nodes)
  expect_equal(a$show_summary[1], "Dyad Reciprocity")
  expect_equal(b$show_summary[1], "Arc Reciprocity")
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

test_that("valued data are not dichotomized, and the notice explains why", {
  # The routine prints "Data are valued. Remember that xij = 3 will not match
  # xji = 2" and then compares values. Ledger entry 16. The "3 does not
  # match" half now belongs to xegoreciprocity(), whose table it concerns.
  a <- xreciprocity(baker_journals)
  expect_true(any(grepl("not been dichotomized", a$assumptions)))
})

test_that("xreciprocity refuses 2-mode data", {
  expect_error(xreciprocity(davis), "1-mode")
})

# ---- xtransitivity -----------------------------------------------------------
#
# Follows UCINET's command-line transitivity() (runtransitivity, Xdpmat.pas):
# one row per relation, the twelve triplet measures, nothing else.

test_that("the report is the command line's twelve columns", {
  s <- xtransitivity(campnet)$summary
  expect_s3_class(s, "data.frame")
  expect_equal(names(s), c("Threes", "Twos", "Transitivity", "Density",
                           "Ratio", "Transitivity Index",
                           "TP Covariance", "Transitivity Phi",
                           "Transitivity Phi Beta", "T Covariance",
                           "Transitivity Correlation", "Transitivity Beta"))
  expect_equal(rownames(s), "campnet")
  # the clustering coefficient is xclusteringcoefficient()'s now
  expect_false(any(grepl("Clustering", names(s))))
  expect_null(xtransitivity(campnet)$nodes)
})

test_that("every relation gets a row, as on the command line", {
  s <- xtransitivity(hightech)$summary
  expect_equal(rownames(s), xrelations(hightech))
  for (r in xrelations(hightech)) {
    one <- xtransitivity(as.matrix(hightech, relation = r))$summary
    expect_equal(unlist(s[r, ]), unlist(one[1, ]), tolerance = tol, info = r)
  }
})

test_that("there is no method argument any more", {
  expect_error(xtransitivity(campnet, method = "triads"), "unused argument")
})

test_that("transitivity agrees with xcohesion, which UCINET validated", {
  co <- as.matrix(xcohesion(hightech)$summary)
  s <- xtransitivity(hightech)$summary
  for (r in xrelations(hightech)) {
    expect_equal(s[r, "Transitivity"], co["Transitivity/Closure", r],
                 tolerance = tol, info = r)
    expect_equal(s[r, "Transitivity Index"], co["Transitivity Index", r],
                 tolerance = tol, info = r)
    expect_equal(s[r, "Density"], co["Density", r], tolerance = tol, info = r)
  }
})

test_that("the high-tech values are the ones chapter 10 quotes", {
  # 10.2.3: advice 0.66 against density 0.45; friendship 0.46 against 0.24;
  # reports-to has no transitivity at all.
  s <- xtransitivity(hightech)$summary
  expect_equal(round(s["Advice", "Transitivity"], 2), 0.66)
  expect_equal(round(s["Advice", "Density"], 2), 0.45)
  expect_equal(round(s["Friendship", "Transitivity"], 2), 0.46)
  expect_equal(round(s["Friendship", "Density"], 2), 0.24)
  expect_equal(s["ReportTo", "Transitivity"], 0)
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

test_that("the command line's two notes are printed", {
  out <- capture.output(print(xtransitivity(campnet)))
  expect_true(any(grepl("ratio of transitivity to density would be 1.0", out)))
  expect_true(any(grepl("Dekker, Krackhardt & Snijders 2019", out)))
})

# ---- xcyclicality ------------------------------------------------------------

test_that("the cyclicality report is UCINET's six measures", {
  s <- xcyclicality(campnet)$summary
  expect_equal(names(s), c("Threes", "Twos", "Cyclicality", "Density", "Ratio",
                           "Cyclicity Index"))
})

test_that("cyclicality counts the same two-paths as transitivity", {
  expect_equal(xcyclicality(campnet)$summary[["Twos"]],
               xtransitivity(campnet)$summary[["Twos"]][1])
})

test_that("cyclicality reports every relation, one row each", {
  # Until 19 Nov 2026 only the first relation was reported; uc_cyclicity.pas
  # loops over every matrix of the dataset.
  s <- xcyclicality(hightech)$summary
  expect_equal(rownames(s), xrelations(hightech))
  for (r in xrelations(hightech)) {
    one <- xcyclicality(as.matrix(hightech, relation = r))$summary
    expect_equal(unlist(s[r, ]), unlist(one[1, ]), tolerance = tol)
  }
  expect_equal(s[["Twos"]], xtransitivity(hightech)$summary[["Twos"]])
  expect_equal(nrow(xcyclicality(sampson)$summary), length(xrelations(sampson)))
})

test_that("cyclicality names each valued relation it dichotomizes", {
  a <- xcyclicality(sampson)$assumptions
  expect_true(all(grepl("^Relation .* dichotomized at > 0[.]$", a)))
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
               xtransitivity(campnet)$summary[["Density"]][1], tolerance = tol)
})

test_that("cyclicality refuses 2-mode data; both dichotomize valued data", {
  # xtransitivity() has a 2-mode branch since 23 Nov 2026 (xucinet#55),
  # tested in test-twomode-closure-centralization.R
  expect_error(xcyclicality(davis), "1-mode")
  expect_true(any(grepl("dichotomized", xtransitivity(baker_journals)$assumptions)))
  expect_true(any(grepl("dichotomized", xcyclicality(baker_journals)$assumptions)))
})

test_that("the reports print", {
  expect_snapshot(xreciprocity(campnet))
  expect_snapshot(xtransitivity(campnet))
  expect_snapshot(xcyclicality(campnet))
})
