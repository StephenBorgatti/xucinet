# Whole-network clustering coefficients (chapter 10, section 10.2.3).
#
# No UCINET golden yet: the menu routine is being changed in 6.850 to report
# the three definitions decided in dev/UCINET-ISSUES.md issue 41. Until then
# the checks are igraph for the underlying graph, xtransitivity() for the
# Opsahl-Panzarasa weighted value, the campnet values recorded in issue 41
# (computed independently in R on 2 October 2026), and brute-force loops that
# follow the published definitions term by term.

tol <- 1e-8

dich <- function(m) {
  a <- (m > 0) * 1
  a[is.na(a)] <- 0
  diag(a) <- 0
  a
}

# Opsahl and Panzarasa, as OpsahlPanzarosaCC enumerates them: every j -> i -> k
# with j, k, i distinct, valued by omega of the two ties, closed by j -> k.
brute_op <- function(w, omega = "am") {
  w[is.na(w) | w < 0] <- 0; diag(w) <- 0
  w <- w / max(w)
  f <- switch(omega, am = function(x, y) (x + y) / 2,
              gm = function(x, y) sqrt(x * y), min = min, max = max)
  n <- nrow(w); num <- den <- numeric(n)
  for (i in 1:n) for (j in 1:n) for (k in 1:n) {
    if (i == j || i == k || j == k) next
    if (w[j, i] > 0 && w[i, k] > 0) {
      v <- f(w[j, i], w[i, k])
      den[i] <- den[i] + v
      if (w[j, k] > 0) num[i] <- num[i] + v
    }
  }
  ok <- den > 0
  c(mean(num[ok] / den[ok]), sum(num) / sum(den))
}

# Fagiolo (2007), equation 6 written out as a triple sum rather than as the
# matrix power the function uses.
brute_fagiolo <- function(a, w = NULL) {
  x <- if (is.null(w)) a else { w[is.na(w) | w < 0] <- 0; diag(w) <- 0
                                (w / max(w))^(1 / 3) }
  n <- nrow(a); num <- den <- numeric(n)
  for (i in 1:n) {
    t <- 0
    for (j in 1:n) for (h in 1:n) {
      t <- t + (x[i, j] + x[j, i]) * (x[i, h] + x[h, i]) * (x[j, h] + x[h, j])
    }
    num[i] <- t / 2
    dtot <- sum(a[i, ]) + sum(a[, i])
    dbi <- sum(a[i, ] * a[, i])
    den[i] <- dtot * (dtot - 1) - 2 * dbi
  }
  ok <- den > 0
  c(mean(num[ok] / den[ok]), sum(num[ok]) / sum(den[ok]))
}

test_that("the report has seven columns, one row per relation", {
  res <- xclusteringcoefficient(padgett)
  s <- res$summary
  expect_s3_class(s, "data.frame")
  expect_equal(names(s), c("Overall CC", "Weighted Overall CC",
                           "Fagiolo Overall CC", "Fagiolo Weighted CC",
                           "O-P Overall CC", "O-P Weighted CC", "Density"))
  expect_equal(rownames(s), xrelations(padgett))
  # a whole-network routine: no node table (SPEC addendum, 23 Sep 2026)
  expect_null(res$nodes)
})

test_that("the underlying-graph values are igraph's", {
  for (net in list(campnet, padgett, hightech)) {
    s <- xclusteringcoefficient(net)$summary
    rels <- xrelations(net)
    for (k in seq_along(rels)) {
      a <- dich(as.matrix(net, relation = k))
      g <- igraph::graph_from_adjacency_matrix(pmax(a, t(a)), mode = "undirected")
      expect_equal(s[k, "Overall CC"], igraph::transitivity(g, "average"),
                   tolerance = tol, info = rels[k])
      expect_equal(s[k, "Weighted Overall CC"], igraph::transitivity(g, "global"),
                   tolerance = tol, info = rels[k])
    }
  }
})

test_that("campnet gives the values recorded in UCINET-ISSUES 41", {
  s <- xclusteringcoefficient(campnet)$summary
  expect_equal(round(s[["Overall CC"]], 3), 0.569)
  expect_equal(round(s[["Fagiolo Overall CC"]], 3), 0.509)
  # the CLI cc() (OpsahlPanzarosaCC) values in the issue's table
  expect_equal(round(s[["O-P Overall CC"]], 3), 0.526)
  expect_equal(round(s[["O-P Weighted CC"]], 3), 0.484)
})

test_that("the O-P weighted value is transitivity", {
  for (net in list(campnet, hightech)) {
    s <- xclusteringcoefficient(net)$summary
    t <- xtransitivity(net)$summary
    expect_equal(s[["O-P Weighted CC"]], t[["Transitivity"]], tolerance = tol)
    expect_equal(s[["Density"]], t[["Density"]], tolerance = tol)
  }
})

test_that("O-P and Fagiolo follow their definitions, binary and valued", {
  m <- as.matrix(campnet)
  s <- xclusteringcoefficient(campnet)$summary
  expect_equal(unlist(s[1, c("O-P Overall CC", "O-P Weighted CC")], use.names = FALSE),
               brute_op(dich(m)), tolerance = tol)
  expect_equal(unlist(s[1, c("Fagiolo Overall CC", "Fagiolo Weighted CC")],
                      use.names = FALSE),
               brute_fagiolo(dich(m)), tolerance = tol)

  w <- as.matrix(baker_journals)
  for (om in c("am", "gm", "min", "max")) {
    v <- xclusteringcoefficient(baker_journals, omega = om)$summary
    expect_equal(unlist(v[1, c("O-P Overall CC", "O-P Weighted CC")],
                        use.names = FALSE),
                 brute_op(w, om), tolerance = tol, info = om)
  }
  v <- xclusteringcoefficient(baker_journals)$summary
  expect_equal(unlist(v[1, c("Fagiolo Overall CC", "Fagiolo Weighted CC")],
                      use.names = FALSE),
               brute_fagiolo(dich(w), w), tolerance = tol)
})

test_that("the three definitions agree on symmetric binary data", {
  s <- xclusteringcoefficient(padgett)$summary
  expect_equal(s[["Overall CC"]], s[["Fagiolo Overall CC"]], tolerance = tol)
  expect_equal(s[["Overall CC"]], s[["O-P Overall CC"]], tolerance = tol)
  expect_equal(s[["Weighted Overall CC"]], s[["Fagiolo Weighted CC"]], tolerance = tol)
  expect_equal(s[["Weighted Overall CC"]], s[["O-P Weighted CC"]], tolerance = tol)
})

test_that("only the first pair is printed when the three agree", {
  expect_equal(xclusteringcoefficient(padgett)$show_summary,
               c("Overall CC", "Weighted Overall CC", "Density"))
  expect_length(xclusteringcoefficient(campnet)$show_summary, 7)
})

test_that("weighted chooses the treatment of tie values", {
  w <- as.matrix(baker_journals)
  off <- xclusteringcoefficient(baker_journals, weighted = FALSE)
  bin <- xclusteringcoefficient(dich(w))
  expect_equal(unname(unlist(off$summary[1, ])), unname(unlist(bin$summary[1, ])),
               tolerance = tol)
  expect_true(any(grepl("dichotomized", off$assumptions)))

  # NULL: the underlying graph is binary, the other two use the values
  def <- xclusteringcoefficient(baker_journals)$summary
  expect_equal(def[["Overall CC"]], bin$summary[["Overall CC"]], tolerance = tol)
  expect_false(isTRUE(all.equal(def[["O-P Overall CC"]],
                                bin$summary[["O-P Overall CC"]])))

  # TRUE: the underlying graph becomes the average value among the neighbors
  on <- xclusteringcoefficient(baker_journals, weighted = TRUE)$summary
  s <- pmax(w, t(w)); s[is.na(s)] <- 0; diag(s) <- 0
  vals <- vapply(seq_len(nrow(s)), function(i) {
    k <- which(s[i, ] > 0)
    if (length(k) < 2) return(NA_real_)
    sub <- s[k, k]
    mean(sub[upper.tri(sub)])
  }, numeric(1))
  expect_equal(on[["Overall CC"]], mean(vals, na.rm = TRUE), tolerance = tol)
})

test_that("bad arguments and 2-mode data are refused", {
  expect_error(xclusteringcoefficient(davis), "1-mode")
  expect_error(xclusteringcoefficient(campnet, weighted = "yes"), "weighted")
  expect_error(xclusteringcoefficient(campnet, omega = "median"))
})

test_that("a network with no node of degree two has no coefficient", {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", "b"] <- m["b", "a"] <- m["c", "d"] <- m["d", "c"] <- 1
  s <- xclusteringcoefficient(m)$summary
  expect_true(all(is.na(unlist(s[1, 1:6]))))
})

test_that("the report prints", {
  expect_snapshot(xclusteringcoefficient(campnet))
  expect_snapshot(xclusteringcoefficient(padgett))
})
