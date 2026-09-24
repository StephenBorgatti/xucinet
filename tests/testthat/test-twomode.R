# Two-mode routines of chapter 13: xaffiliations, xbipartite, xbicliques.

tol <- 1e-10

small <- function() {
  m <- matrix(c(1, 1, 0, 1,
                1, 1, 1, 0,
                0, 1, 1, 1,
                1, 1, 1, 1,
                0, 0, 1, 1), 5, 4, byrow = TRUE,
              dimnames = list(paste0("r", 1:5), paste0("c", 1:4)))
  m
}

# ---- xaffiliations ------------------------------------------------------------

test_that("davis women by women are the well-known overlap counts", {
  a <- as.matrix(xaffiliations(davis))
  d <- as.matrix(davis)
  expect_equal(a, d %*% t(d), ignore_attr = TRUE)
  expect_equal(a["EVELYN", "LAURA"], 6)
  expect_equal(a["EVELYN", "THERESA"], 7)
  expect_equal(a["EVELYN", "EVELYN"], 8)           # events attended
})

test_that("the result is a 1-mode undirected network titled as UCINET names it", {
  a <- xaffiliations(davis)
  expect_equal(a$mode, "1-mode")
  expect_false(a$directed)
  expect_equal(a$title, "davisRows")
  expect_equal(xaffiliations(davis, mode = "cols")$title, "davisColumns")
  expect_true(any(grepl("affiliations of the rows", attr(a, "history"))))
})

test_that("events by events project the columns", {
  e <- as.matrix(xaffiliations(davis, mode = "cols"))
  d <- as.matrix(davis)
  expect_equal(e, t(d) %*% d, ignore_attr = TRUE)
})

test_that("the other measures are what they say, by hand", {
  m <- small()
  mn <- as.matrix(xaffiliations(m, method = "min"))
  expect_equal(mn["r1", "r2"], sum(pmin(m[1, ], m[2, ])))
  j <- as.matrix(xaffiliations(m, method = "jaccard"))
  expect_equal(j["r1", "r2"], 2 / 4)
  cv <- as.matrix(xaffiliations(m, method = "covariance"))
  expect_equal(cv["r1", "r3"], mean((m[1, ] - mean(m[1, ])) * (m[3, ] - mean(m[3, ]))))
  co <- as.matrix(xaffiliations(m, method = "correlation"))
  expect_equal(co["r1", "r3"], cor(m[1, ], m[3, ]), tolerance = tol)
  expect_equal(co["r4", "r1"], 0)                  # r4 is constant
  cs <- as.matrix(xaffiliations(m, method = "cosine"))
  expect_equal(cs["r1", "r2"], 2 / sqrt(3 * 3))
  mx <- as.matrix(xaffiliations(m, method = "maxmin"))
  expect_equal(mx["r1", "r5"], 1)
  cm <- as.matrix(xaffiliations(m, method = "crossproductmin"))
  expect_equal(cm["r4", "r5"], 2 / 2)
  expect_equal(as.matrix(xaffiliations(m, method = "ssd"))["r1", "r5"], 3)
  expect_equal(as.matrix(xaffiliations(m, method = "matches"))["r1", "r2"], 2 / 4)
  expect_equal(as.matrix(xaffiliations(m, method = "identity"))["r1", "r2"],
               2 * 2 / (3 + 3))
})

test_that("Bonacich's measure follows the 1972 formula", {
  m <- small()
  b <- as.matrix(xaffiliations(m, method = "bonacich"))
  x <- m[1, ]; y <- m[3, ]
  n11 <- sum(x * y); n12 <- sum(x) - n11; n21 <- sum(y) - n11; n22 <- 4 - n11 - n12 - n21
  expect_equal(b["r1", "r3"],
               (n11 * n22 - sqrt(n11 * n22 * n12 * n21)) / (n11 * n22 - n12 * n21))
})

test_that("covariance divides by n, not as UCINET does (issue 30)", {
  expect_differs_from_ucinet(30)
  m <- small()
  cv <- as.matrix(xaffiliations(m, method = "covariance"))
  expect_equal(cv["r2", "r2"], mean((m[2, ] - mean(m[2, ]))^2))
})

test_that("opposite-mode normalization divides by the column totals", {
  m <- small()
  a <- as.matrix(xaffiliations(m, normalize = TRUE))
  w <- sweep(m, 2, colSums(m), "/")
  expect_equal(a, w %*% t(w), ignore_attr = TRUE)
})

test_that("missing cells are recoded to zero unless asked not to", {
  m <- small(); m[1, 2] <- NA
  a <- xaffiliations(m)
  expect_equal(as.matrix(a)["r1", "r2"], 1)
  expect_true(any(grepl("missing values recoded", attr(a, "history"))))
  b <- as.matrix(xaffiliations(m, recode = FALSE))
  expect_equal(b["r1", "r2"], 1)
})

test_that("every relation is projected", {
  two <- list(a = small(), b = 1 - small())
  p <- xaffiliations(two)
  expect_equal(xnrelations(p), 2)
})

# ---- xbipartite ---------------------------------------------------------------

test_that("the bipartite matrix has the data off the diagonal blocks", {
  b <- xbipartite(davis)
  y <- as.matrix(b)
  d <- as.matrix(davis)
  expect_equal(dim(y), c(32L, 32L))
  expect_equal(y[1:18, 19:32], d, ignore_attr = TRUE)
  expect_equal(y[19:32, 1:18], t(d), ignore_attr = TRUE)
  expect_true(all(y[1:18, 1:18] == 0))
  expect_true(all(y[19:32, 19:32] == 0))
  expect_equal(rownames(y), c(rownames(d), colnames(d)))
})

test_that("it is a 1-mode undirected network with each node's mode", {
  b <- xbipartite(davis)
  expect_equal(b$mode, "1-mode")
  expect_false(b$directed)
  expect_equal(xattributes(b)$mode, rep(c("row", "col"), c(18, 14)))
  # coercing it again does not make it 2-mode
  expect_equal(as_xucinet(b)$mode, "1-mode")
  expect_equal(xdegree(b)$nodes[["Degree"]][1:18], rowSums(as.matrix(davis)),
               ignore_attr = TRUE)
})

test_that("the options are UCINET's", {
  b <- as.matrix(xbipartite(small(), symmetric = FALSE, fill = NA))
  expect_true(all(is.na(b[1:5, 1:5])))
  expect_true(all(is.na(b[6:9, 1:5])))
  p <- xbipartite(small(), rowprefix = "R_", colprefix = "C_")
  expect_equal(rownames(as.matrix(p))[c(1, 6)], c("R_r1", "C_c1"))
})

test_that("a label shared by a row and a column is refused", {
  m <- small(); colnames(m)[1] <- "r1"
  expect_error(xbipartite(m), "colprefix")
})

# ---- xbicliques ---------------------------------------------------------------

# Every maximal biclique of m with at least a rows and b columns, by brute
# force over the subsets of columns.
brute_bicliques <- function(m, a, b) {
  nc <- ncol(m)
  out <- list()
  for (s in 1:(2^nc - 1)) {
    cols <- which(bitwAnd(s, 2^(0:(nc - 1))) > 0)
    rows <- unname(which(rowSums(m[, cols, drop = FALSE] > 0) == length(cols)))
    if (!length(rows)) next
    # closed: the columns are exactly those every row in `rows` shares
    closure <- unname(which(colSums(m[rows, , drop = FALSE] > 0) == length(rows)))
    if (!identical(closure, cols)) next
    if (length(rows) >= a && length(cols) >= b) {
      out[[length(out) + 1]] <- paste(paste(rows, collapse = ","), "|",
                                      paste(cols, collapse = ","))
    }
  }
  sort(unlist(out))
}

test_that("the bicliques are exactly the maximal complete bipartite sets", {
  set.seed(4)
  for (trial in 1:5) {
    m <- matrix(rbinom(7 * 6, 1, 0.55), 7, 6,
                dimnames = list(paste0("r", 1:7), paste0("c", 1:6)))
    got <- xbicliques(m, 2, 2)$bicliques
    got <- sort(vapply(got, function(b) paste(
      paste(match(b$rows, rownames(m)), collapse = ","), "|",
      paste(match(b$cols, colnames(m)), collapse = ",")), character(1)))
    expect_equal(got, brute_bicliques(m, 2, 2), info = paste("trial", trial))
  }
})

test_that("davis has 22 bicliques of at least 3 by 3, each complete", {
  r <- xbicliques(davis)
  expect_length(r$bicliques, 22)
  d <- as.matrix(davis)
  for (b in r$bicliques) expect_true(all(d[b$rows, b$cols] == 1))
})

test_that("the minimum sizes filter the bicliques", {
  a <- xbicliques(davis, 2, 2)$bicliques
  b <- xbicliques(davis, 4, 4)$bicliques
  expect_gt(length(a), 22)
  expect_true(all(vapply(b, function(x) length(x$rows) >= 4 && length(x$cols) >= 4,
                         logical(1))))
})

test_that("participation and co-membership are per mode", {
  r <- xbicliques(davis)
  rp <- r$matrices[["Row participation"]]
  expect_equal(dim(rp), c(18L, 22L))
  expect_equal(rp["THERESA", 1], 1)
  rc <- r$matrices[["Row co-membership"]]
  expect_equal(unname(diag(rc)),
               unname(rowSums(r$matrices[["Row participation"]] == 1 &
                              vapply(r$bicliques, function(b) rownames(rp) %in% b$rows,
                                     logical(18)))))
  expect_equal(dim(r$matrices[["Column co-membership"]]), c(14L, 14L))
})

test_that("valued data are dichotomized with a note", {
  r <- xbicliques(small() * 2, 2, 2)
  expect_true(any(grepl("Valued", r$assumptions)))
})

test_that("the reports print", {
  expect_snapshot(xbicliques(davis))
})

# ---- goldens --------------------------------------------------------------------

test_that("davis affiliations match UCINET", {
  skip_if_no_golden("g13_affil_davis_rows", "twomode")
  skip_if_no_golden("g13_affil_davis_rowsmin", "twomode")
  skip_if_no_golden("g13_affil_davis_cols", "twomode")
  expect_equal(unname(as.matrix(xaffiliations(davis))),
               unname(golden_matrix("g13_affil_davis_rows", "twomode")))
  expect_equal(unname(as.matrix(xaffiliations(davis, method = "min"))),
               unname(golden_matrix("g13_affil_davis_rowsmin", "twomode")))
  expect_equal(unname(as.matrix(xaffiliations(davis, mode = "cols"))),
               unname(golden_matrix("g13_affil_davis_cols", "twomode")))
})

test_that("davis bipartite matches UCINET", {
  skip_if_no_golden("g13_bipartite_davis", "twomode")
  expect_equal(unname(as.matrix(xbipartite(davis))),
               unname(golden_matrix("g13_bipartite_davis", "twomode")))
})

test_that("davis bicliques match UCINET, in UCINET's order", {
  skip_if_no_golden("g13_biclique_davis", "twomode")
  g <- golden_matrix("g13_biclique_davis", "twomode")   # nodes by bicliques
  r <- xbicliques(davis)
  ours <- rbind(r$matrices[["Row participation"]] == 1,
                r$matrices[["Column participation"]] == 1) * 1
  expect_equal(unname(ours), unname(g))
})

# ---- 2-mode centrality through the chapter 9 routines --------------------------

test_that("the centrality routines give 2-Mode Centrality's scores on 2-mode data", {
  rows <- xcentrality(davis)$nodes
  cols <- xcentrality(davis, mode = "cols")$nodes
  d <- xdegree(davis, mode = "rows")$nodes
  expect_equal(d$nDegree, rows$Degree)
  expect_equal(d$Degree, unname(rowSums(as.matrix(davis))))
  expect_equal(xcloseness(davis, mode = "cols")$nodes$Closeness, cols$Closeness)
  expect_equal(xbetweenness(davis, mode = "rows")$nodes$nBetweenness, rows$Betweenness)
  expect_equal(xeigenvector(davis, mode = "cols")$nodes$Eigenvector, cols$Eigenvector)
})

test_that("Ruth's normalized degree is 4/14, as section 13.4 says", {
  d <- xdegree(davis)$nodes
  expect_equal(d["RUTH", "nDegree"], 4 / 14)
})

test_that("mode both stacks the rows and the columns with a Mode column", {
  d <- xdegree(davis)$nodes
  expect_equal(nrow(d), 32)
  expect_equal(d$Mode, rep(c("row", "col"), c(18, 14)))
  expect_equal(rownames(d), c(rownames(as.matrix(davis)), colnames(as.matrix(davis))))
})

test_that("a square matrix declared 2-mode is treated as 2-mode", {
  m <- small()[1:4, ]
  net <- as_xucinet(m, mode = "2-mode")
  expect_true(identical(xdegree(net)$nodes$Mode[1], "row"))
  u <- m; dimnames(u) <- list(letters[1:4], letters[1:4])
  expect_false("Mode" %in% names(xdegree(u)$nodes))   # same labels: 1-mode
})

test_that("the biclique co-membership of both modes is clustered", {
  r <- xbicliques(davis)
  co <- r$matrices[["Co-membership"]]
  expect_equal(dim(co), c(32L, 32L))
  expect_equal(co[1:18, 1:18], r$matrices[["Row co-membership"]], ignore_attr = TRUE)
  expect_s3_class(r$clustering, "xhclust")
})

# ---- SDSM backbone ----------------------------------------------------------------

blocks <- function() {
  set.seed(11)
  nr <- 60; nc <- 40
  g <- rep(1:3, length.out = nr); h <- rep(1:3, length.out = nc)
  p <- outer(g, h, function(a, b) ifelse(a == b, 0.45, 0.08)) *
    outer(runif(nr, .5, 1.5), runif(nc, .5, 1.5))
  matrix(rbinom(nr * nc, 1, pmin(p, 1)), nr, nc,
         dimnames = list(paste0("r", 1:nr), paste0("c", 1:nc)))
}

test_that("the backbone is binary, symmetric, with an empty diagonal", {
  b <- as.matrix(xaffiliations(blocks(), method = "sdsm"))
  expect_true(all(b %in% c(0, 1)))
  expect_true(isSymmetric(unname(b)))
  expect_true(all(diag(b) == 0))
  expect_gt(sum(b), 0)
  h <- attr(xaffiliations(blocks(), method = "sdsm"), "history")
  expect_true(any(grepl("significant edges retained", h)))
})

test_that("the logistic null model is the glm fit of ties on the degrees", {
  m <- blocks()
  R <- rowSums(m); C <- colSums(m)
  fit <- sdsm_logit(m, R, C)
  df <- data.frame(y = as.vector(m), r = rep(R, times = ncol(m)),
                   c = rep(C, each = nrow(m)))
  g <- stats::glm(y ~ r + c, family = stats::binomial, data = df)
  expect_equal(unname(fit$b), unname(stats::coef(g)), tolerance = 1e-6)
  expect_true(fit$converged)
})

test_that("the BiCM probabilities reproduce the degrees in expectation", {
  m <- blocks()
  f <- sdsm_bicm(rowSums(m), colSums(m))
  P <- outer(f$x, f$y); P <- P / (1 + P)
  expect_equal(rowSums(P), rowSums(m), ignore_attr = TRUE, tolerance = 1e-6)
  expect_equal(colSums(P), colSums(m), ignore_attr = TRUE, tolerance = 1e-6)
})

test_that("the BiCM probabilities are backbone's", {
  skip_if_not_installed("backbone")
  m <- blocks()
  f <- sdsm_bicm(rowSums(m), colSums(m))
  P <- outer(f$x, f$y); P <- P / (1 + P)
  theirs <- get("bicm", asNamespace("backbone"))(m)
  expect_equal(P, theirs, ignore_attr = TRUE, tolerance = 1e-7)
})

test_that("the tail probability is exact Poisson-binomial", {
  # enumerate all 2^6 outcomes
  q <- c(0.1, 0.5, 0.3, 0.8, 0.05, 0.6)
  out <- as.matrix(expand.grid(rep(list(0:1), 6)))
  pr <- apply(out, 1, function(o) prod(ifelse(o == 1, q, 1 - q)))
  s <- rowSums(out)
  for (k in 0:7) {
    expect_equal(poisson_binomial_upper(k, matrix(q, 1)),
                 if (k <= 0) 1 else sum(pr[s >= k]), tolerance = 1e-12,
                 info = paste("k =", k))
  }
})

test_that("rows and columns are both projected", {
  m <- blocks()
  a <- as.matrix(xaffiliations(m, method = "sdsm", mode = "cols"))
  expect_equal(dim(a), c(40L, 40L))
  expect_equal(xaffiliations(m, method = "sdsm", mode = "cols")$title, "mColumns")
})

test_that("alpha must lie between 0 and 1", {
  expect_error(xaffiliations(davis, method = "sdsm", alpha = 1.5), "alpha")
})

test_that("missing cells are read as 0, as UCINET's unit does", {
  m <- blocks(); m[1, 1] <- NA
  n <- blocks(); n[1, 1] <- 0
  expect_equal(as.matrix(xaffiliations(m, method = "sdsm")),
               as.matrix(xaffiliations(n, method = "sdsm")))
})

test_that("davis SDSM backbones match UCINET", {
  skip_if_no_golden("g13_sdsm_davis_cols", "twomode")
  skip_if_no_golden("g13_sdsm_davis_rows_bicm", "twomode")
  expect_equal(unname(as.matrix(xaffiliations(davis, method = "sdsm", mode = "cols"))),
               unname(golden_matrix("g13_sdsm_davis_cols", "twomode")))
  expect_equal(unname(as.matrix(xaffiliations(davis, method = "sdsm", nullmodel = "bicm"))),
               unname(golden_matrix("g13_sdsm_davis_rows_bicm", "twomode")))
})
