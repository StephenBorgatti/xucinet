# Chapter 5 transformations: xtranspose, xdichotomize, xsymmetrize,
# xnormalize, xrecode.
#
# Written against the 21 September 2026 rewrite of dev/design/
# remaining-chapters-questions.md, which reads the dialogs out of the UCINET
# source. Three layers: hand-computed cases on tiny matrices where the answer
# follows from the definition, cross-checks against another implementation
# where the definitions agree, and golden tests that skip until the UCINET
# batch in inst/goldens/transform/ has been run.

tol <- 1e-6

# A 3-node valued directed network with an asymmetric pair, a zero pair and a
# non-zero diagonal, so every branch has something to show.
toy <- function() {
  matrix(c(0, 3, 0,
           1, 0, 2,
           0, 0, 0), 3, 3, byrow = TRUE,
         dimnames = list(letters[1:3], letters[1:3]))
}

valued <- function() {
  matrix(c(0, 3, 1,
           2, 0, 0,
           5, 1, 0), 3, 3, byrow = TRUE,
         dimnames = list(letters[1:3], letters[1:3]))
}

# ---- xtranspose -------------------------------------------------------------

test_that("xtranspose swaps rows and columns and keeps the labels", {
  m <- toy()
  out <- xtranspose(m)
  expect_s3_class(out, "xucinet")
  expect_equal(as.matrix(out), t(m))
  expect_equal(rownames(as.matrix(out)), colnames(m))
})

test_that("xtranspose names the dataset the way UCINET does", {
  # TranDlg.pas: output.text := outfile(inputfn.text, '-Transp')
  expect_equal(xtranspose(campnet)$title, "campnet-Transp")
  expect_equal(attr(xtranspose(campnet), "history"), "transposed")
})

test_that("transposing twice is the identity", {
  m <- toy()
  expect_equal(as.matrix(xtranspose(xtranspose(m))), m)
})

test_that("xtranspose swaps the modes of a 2-mode network", {
  out <- xtranspose(davis)
  expect_equal(dim(as.matrix(out)), rev(dim(as.matrix(davis))))
  expect_equal(out$mode, "2-mode")
})

test_that("xtranspose transposes every relation and keeps the stack", {
  out <- xtranspose(hightech)
  expect_equal(xrelations(out), xrelations(hightech))
  expect_equal(as.matrix(out, relation = "Advice"),
               t(as.matrix(hightech, relation = "Advice")))
})

# ---- xdichotomize -----------------------------------------------------------

test_that("each of the six operators thresholds as the dialog rule says", {
  v <- valued()
  for (op in c(">", ">=", "==", "<=", "<", "!=")) {
    want <- switch(op,
                   ">"  = v >  1, ">=" = v >= 1, "==" = v == 1,
                   "<=" = v <= 1, "<"  = v <  1, "!=" = v != 1) * 1
    # diagonal = "rule" so the comparison is the only thing under test.
    got <- as.matrix(xdichotomize(v, cutoff = 1, op = op, diagonal = "rule"))
    expect_equal(as.vector(got), as.vector(want), info = op)
  }
})

test_that("the diagonal gets the else value by default", {
  # uc_Dichotomize.dfm: yDiagonals ItemIndex = 3, 'Set to "else" value'. The
  # CLI unit applies the rule instead; ledger entry 13 records the choice.
  # R follows the menu form.
  v <- valued()
  diag(v) <- 4
  expect_equal(diag(as.matrix(xdichotomize(v, cutoff = 1))), c(a = 0, b = 0, c = 0))
  # and the four other options
  expect_equal(diag(as.matrix(xdichotomize(v, cutoff = 1, diagonal = "zero"))),
               c(a = 0, b = 0, c = 0))
  expect_equal(diag(as.matrix(xdichotomize(v, cutoff = 1, diagonal = "then"))),
               c(a = 1, b = 1, c = 1))
  expect_true(all(is.na(diag(as.matrix(
    xdichotomize(v, cutoff = 1, diagonal = "missing"))))))
  expect_equal(diag(as.matrix(xdichotomize(v, cutoff = 1, diagonal = "rule"))),
               c(a = 1, b = 1, c = 1))
})

test_that("the else value is what lands off the rule, not necessarily zero", {
  v <- valued()
  out <- as.matrix(xdichotomize(v, cutoff = 1, then = 9, otherwise = -1,
                                diagonal = "rule"))
  expect_true(all(out %in% c(9, -1)))
  expect_equal(out[1, 2], 9)      # 3 > 1
  expect_equal(out[2, 3], -1)     # 0 is not
})

test_that("then and otherwise may be missing, as the dialog allows", {
  v <- valued()
  out <- as.matrix(xdichotomize(v, cutoff = 1, otherwise = NA, diagonal = "rule"))
  expect_true(is.na(out[2, 3]))
  expect_equal(out[1, 2], 1)
})

test_that("missing cells stay missing", {
  v <- valued()
  v[1, 3] <- NA
  out <- as.matrix(xdichotomize(v, cutoff = 1, diagonal = "rule"))
  expect_true(is.na(out[1, 3]))
})

test_that("xdichotomize names the dataset as setoutputfn does", {
  # <input> + _GT_ + cutoff, with dots turned into "p".
  expect_equal(xdichotomize(camp92, cutoff = 1)$title, "camp92_GT_1")
  expect_equal(xdichotomize(camp92, cutoff = 2, op = "!=")$title, "camp92_NE_2")
  expect_equal(xdichotomize(camp92, cutoff = 0.5, op = "<=")$title, "camp92_LE_0p5")
})

test_that("method = density picks the most selective cutoff that reaches it", {
  v <- valued()
  # values are 0, 1, 2, 3, 5; with op ">" the densities over all nine cells
  # are 5/9, 3/9, 2/9, 1/9, 0/9, so 0 is the largest cutoff still at 0.5.
  out <- as.matrix(xdichotomize(v, density = 0.5, diagonal = "rule"))
  expect_equal(mean(out), 5 / 9)
  expect_match(attr(xdichotomize(v, density = 0.5), "history"), "density")
})

test_that("an unreachable density is an error that says what is reachable", {
  expect_error(xdichotomize(valued(), density = 0.99), "density")
})

test_that("a density target is refused for the equality operators", {
  expect_error(xdichotomize(camp92, density = 0.3, op = "=="), "does not work")
})

test_that("method = maxcor picks the best-correlating cutoff", {
  # uc_DichotomizationApp.pas tabulates the correlation for every distinct
  # value; maxcor takes the best row. Check it really is the maximum by
  # computing the whole table here.
  m <- as.matrix(camp92)
  x <- m; diag(x) <- NA_real_
  cand <- sort(unique(as.vector(x)[!is.na(x)]))
  r <- vapply(cand, function(c0) {
    y <- (x > c0) * 1
    ok <- !is.na(x) & !is.na(y)
    a <- as.vector(x)[ok]; b <- as.vector(y)[ok]
    # A cutoff that makes the result constant has no correlation to report;
    # dich_cor() guards this the same way.
    if (stats::sd(a) == 0 || stats::sd(b) == 0) return(NA_real_)
    stats::cor(a, b)
  }, numeric(1))
  best <- cand[which.max(r)]
  expect_equal(xdichotomize(camp92, method = "maxcor")$title,
               paste0("camp92_GT_", best))
})

test_that("the maxcor history records the cutoff, density and correlation", {
  h <- attr(xdichotomize(camp92, method = "maxcor"), "history")
  expect_match(h, "maxcor")
  expect_match(h, "density")
  expect_match(h, "r ")
})

test_that("xdichotomize thresholds each relation of a stack on its own", {
  out <- xdichotomize(hightech)
  expect_equal(xrelations(out), xrelations(hightech))
  expect_true(all(as.matrix(out, relation = "Advice") %in% c(0, 1)))
})

test_that("2-mode data has no diagonal question", {
  # Non-square, so the diagonal is an ordinary cell and all 89 attendances
  # survive whatever `diagonal` says.
  expect_equal(sum(as.matrix(xdichotomize(davis))), 89)
  expect_equal(sum(as.matrix(xdichotomize(davis, diagonal = "zero"))), 89)
})

test_that("cross-check: the internal dichotomiser keeps the CLI behaviour", {
  # dichotomize_matrix() is what the analysis routines call, and it follows
  # the rule everywhere, diagonal included, as copyfromtmat does.
  m <- as.matrix(camp92)
  expect_equal(unname(dichotomize_matrix(m)), unname((m > 0) * 1), tolerance = tol)
})

# ---- xsymmetrize ------------------------------------------------------------

test_that("all sixteen methods combine the pair as Arith1 does", {
  m <- toy()                  # a = x[1,2] = 3 (upper), b = x[2,1] = 1 (lower)
  want <- c(max = 3, min = 1, mean = 2, sum = 4, difference = 2, product = 3,
            division = 3, lower = 1, upper = 3,
            gt = 1, ge = 1, eq = 0, le = 0, lt = 0, ne = 1,
            absdiffsum = 0.5)
  for (meth in names(want)) {
    expect_equal(as.matrix(xsymmetrize(m, method = meth))[1, 2],
                 want[[meth]], info = meth)
  }
})

test_that("division and absdiffsum guard their zero denominators", {
  # Arith1: division is NA when the lower cell is 0; interval is NA when the
  # pair sums to 0.
  m <- toy()                       # x[2,3] = 2, x[3,2] = 0
  expect_true(is.na(as.matrix(xsymmetrize(m, method = "division"))[2, 3]))
  expect_true(is.na(as.matrix(xsymmetrize(m, method = "absdiffsum"))[1, 3]))
})

test_that("the result is symmetric and marked undirected", {
  out <- xsymmetrize(toy())
  mm <- as.matrix(out)
  expect_equal(mm, t(mm))
  expect_false(out$directed)
})

test_that("xsymmetrize leaves the diagonal exactly as it was", {
  # symmetrize loops i = 1..nr-1, j = i+1..nc, so x[i,i] is never touched.
  m <- toy()
  diag(m) <- c(7, 8, 9)
  for (meth in c("max", "min", "mean", "sum", "product", "difference",
                 "upper", "lower", "gt", "absdiffsum")) {
    expect_equal(diag(as.matrix(xsymmetrize(m, method = meth))),
                 c(a = 7, b = 8, c = 9), info = meth)
  }
})

test_that("the missing rule is UCINET's two choices", {
  # Missing is a large sentinel there, so "choose non-missing" is min() and
  # "both missing" is max().
  m <- toy()
  m[1, 2] <- NA                    # pair is (NA, 1)
  expect_equal(as.matrix(xsymmetrize(m))[1, 2], 1)            # nonmissing
  expect_true(is.na(as.matrix(xsymmetrize(m, missing = "both"))[1, 2]))
  expect_true(is.na(as.matrix(xsymmetrize(m, missing = "both"))[2, 1]))
})

test_that("a pair missing both ways stays missing", {
  m <- toy()
  m[1, 2] <- NA; m[2, 1] <- NA
  expect_true(is.na(as.matrix(xsymmetrize(m))[1, 2]))
})

test_that("an already symmetric network is unchanged by max", {
  m <- matrix(c(0,1,1, 1,0,1, 1,1,0), 3, 3,
              dimnames = list(letters[1:3], letters[1:3]))
  expect_equal(as.matrix(xsymmetrize(m)), m)
})

test_that("xsymmetrize names the dataset for the method, as Symdlg does", {
  expect_equal(xsymmetrize(campnet)$title, "campnet-maxsym")
  expect_equal(xsymmetrize(campnet, method = "min")$title, "campnet-minsym")
  expect_equal(xsymmetrize(campnet, method = "mean")$title, "campnet-avgsym")
  expect_equal(xsymmetrize(campnet, method = "sum")$title, "campnet-sumsym")
  expect_equal(xsymmetrize(campnet, method = "difference")$title, "campnet-diffsym")
  expect_equal(xsymmetrize(campnet, method = "product")$title, "campnet-prosym")
  expect_equal(xsymmetrize(campnet, method = "division")$title, "campnet-divsym")
  expect_equal(xsymmetrize(campnet, method = "lower")$title, "campnet-lhsym")
  expect_equal(xsymmetrize(campnet, method = "upper")$title, "campnet-uhsym")
  # The comparison methods have no suffix of their own in the dialog.
  expect_equal(xsymmetrize(campnet, method = "gt")$title, "campnet-sym")
})

test_that("the history carries the six figures the log prints", {
  h <- attr(xsymmetrize(campnet), "history")
  expect_match(h, "density before")
  expect_match(h, "symmetric pairs")
  expect_match(h, "reciprocated dyads")
  expect_match(h, "density after")
  expect_match(h, "r ")
})

test_that("xsymmetrize refuses 2-mode data, as UCINET does", {
  expect_error(xsymmetrize(davis), "1-mode")
})

test_that("xsymmetrize applies to every relation and keeps the stack", {
  out <- xsymmetrize(hightech)
  expect_equal(xrelations(out), xrelations(hightech))
  a <- as.matrix(out, relation = "Advice")
  expect_equal(a, t(a))
})

test_that("cross-check: max symmetrize is the undirected graph igraph builds", {
  # as_undirected(mode = "collapse") keeps an edge when either direction has
  # one, which is the maximum rule on a binary matrix.
  skip_if_not_installed("igraph")
  m <- as.matrix(campnet)
  ours <- as.matrix(xsymmetrize(m))
  g <- igraph::graph_from_adjacency_matrix(m, mode = "directed")
  # as_undirected() since igraph 2.1.0; the old as.undirected() spelling is
  # deprecated and warns.
  theirs <- as.matrix(igraph::as_adjacency_matrix(
    igraph::as_undirected(g, mode = "collapse")))
  expect_equal(unname(ours), unname(theirs), tolerance = tol)
})

# ---- xnormalize -------------------------------------------------------------

test_that("columns are the default dimension, as the dialog has it", {
  # Normdlg: Columns, dim = 3, is the default; Marginal (sum) the criterion.
  v <- valued()
  expect_equal(unname(colSums(as.matrix(xnormalize(v)))), c(1, 1, 1))
  expect_equal(unname(rowSums(as.matrix(xnormalize(v, by = "rows")))), c(1, 1, 1))
  expect_equal(sum(as.matrix(xnormalize(v, by = "matrix"))), 1)
})

test_that("each criterion divides by the right statistic", {
  v <- valued()
  col1 <- v[, 1]
  mu <- mean(col1); sdev <- sqrt(mean((col1 - mu)^2))
  expect_equal(as.matrix(xnormalize(v, method = "max"))[, 1], col1 / max(col1))
  expect_equal(as.matrix(xnormalize(v, method = "mean"))[, 1], col1 / mu)
  expect_equal(as.matrix(xnormalize(v, method = "sd"))[, 1], col1 / sdev)
  expect_equal(as.matrix(xnormalize(v, method = "zscore"))[, 1], (col1 - mu) / sdev)
  expect_equal(as.matrix(xnormalize(v, method = "euclidean"))[, 1],
               col1 / sqrt(sum(col1^2)))
  expect_equal(as.matrix(xnormalize(v, method = "sqrtsum"))[, 1],
               col1 / sqrt(sum(col1)))
})

test_that("a zero divisor leaves the vector alone rather than making NaN", {
  z <- matrix(0, 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  expect_equal(as.matrix(xnormalize(z)), z)
})

test_that("the constant is added before normalising", {
  v <- valued()
  expect_equal(as.matrix(xnormalize(v, constant = 1))[, 1],
               (v[, 1] + 1) / sum(v[, 1] + 1))
})

test_that("diagonal = FALSE holds the diagonal out and puts it back", {
  v <- valued()
  diag(v) <- 4
  out <- as.matrix(xnormalize(v, diagonal = FALSE))
  expect_equal(diag(out), c(a = 4, b = 4, c = 4))
  # the off-diagonal cells of column 1 now sum to 1 on their own
  expect_equal(sum(out[-1, 1]), 1)
})

test_that("by = both settles when it can and warns when it cannot", {
  # A matrix with total support converges; this one does not, because cell
  # (1,2) lies on no perfect matching.
  ok <- matrix(c(1, 2, 3, 4), 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  out <- xnormalize(ok, by = "both")
  expect_equal(unname(rowSums(as.matrix(out))), c(1, 1), tolerance = 1e-3)
  expect_equal(unname(colSums(as.matrix(out))), c(1, 1), tolerance = 1e-3)
  expect_match(attr(out, "history"), "passes")
  expect_warning(xnormalize(valued(), by = "both"), "iteration limit")
})

test_that("2-mode data forces the diagonal valid", {
  expect_equal(dim(as.matrix(xnormalize(davis, diagonal = FALSE))),
               dim(as.matrix(davis)))
})

test_that("xnormalize names the dataset as the dialog does", {
  expect_equal(xnormalize(campnet)$title, "campnet-nrm")
})

# ---- xrecode ----------------------------------------------------------------

test_that("single values and ranges both recode, endpoints included", {
  v <- valued()
  expect_equal(as.vector(as.matrix(xrecode(v, from = c(3, 5), to = 9))),
               as.vector(ifelse(v %in% c(3, 5), 9, v)))
  # 1 to 3 inclusive
  got <- as.matrix(xrecode(v, from = list(c(1, 3)), to = 1))
  expect_equal(as.vector(got), as.vector(ifelse(v >= 1 & v <= 3, 1, v)))
})

test_that("a two-column matrix of ranges works too", {
  v <- valued()
  sched <- rbind(c(1, 2), c(3, 5))
  got <- as.matrix(xrecode(v, from = sched, to = c(1, 2)))
  expect_equal(got[1, 3], 1)      # 1 is in 1..2
  expect_equal(got[1, 2], 2)      # 3 is in 3..5
})

test_that("the last matching rule wins, tested on the original value", {
  # recodedsl scans every rule against m.cell, not against the running result,
  # so an overlapping schedule resolves bottom-up.
  v <- valued()
  got <- as.matrix(xrecode(v, from = list(c(1, 5), c(3, 3)), to = c(7, 8),
                           diagonal = TRUE))
  expect_equal(got[1, 2], 8)      # 3 matches both; the second rule wins
  expect_equal(got[1, 3], 7)      # 1 matches only the first
})

test_that("the diagonal is left out by default for square data", {
  # xRecodeDlg: "Include diagonal values?" defaults to No.
  v <- valued()
  diag(v) <- 4
  expect_equal(diag(as.matrix(xrecode(v, from = 4, to = 99))), c(a = 4, b = 4, c = 4))
  expect_equal(diag(as.matrix(xrecode(v, from = 4, to = 99, diagonal = TRUE))),
               c(a = 99, b = 99, c = 99))
})

test_that("non-square data forces the diagonal in", {
  m <- as.matrix(davis)
  # every attendance becomes 2; the diagonal cells are ordinary cells here
  got <- as.matrix(xrecode(davis, from = 1, to = 2))
  expect_equal(sum(got), 2 * sum(m))
})

test_that("rows and cols restrict where the schedule applies", {
  v <- valued()
  got <- as.matrix(xrecode(v, from = list(c(1, 5)), to = 7, rows = "a"))
  expect_equal(got["a", "b"], 7)
  expect_equal(got["b", "a"], 2)          # untouched
  got2 <- as.matrix(xrecode(v, from = list(c(1, 5)), to = 7, cols = "a"))
  expect_equal(got2["c", "a"], 7)
  expect_equal(got2["a", "b"], 3)         # untouched
})

test_that("relations restricts which relation is recoded", {
  out <- xrecode(hightech, from = 1, to = 5, relations = "Advice")
  expect_true(any(as.matrix(out, relation = "Advice") == 5))
  expect_equal(as.matrix(out, relation = "Friendship"),
               as.matrix(hightech, relation = "Friendship"))
  expect_error(xrecode(hightech, from = 1, to = 5, relations = "nope"),
               "no relation")
})

test_that("missing cells are never recoded", {
  v <- valued()
  v[1, 3] <- NA
  expect_true(is.na(as.matrix(xrecode(v, from = list(c(-1, 99)), to = 0))[1, 3]))
})

test_that("xrecode names the dataset as the dialog does", {
  expect_equal(xrecode(campnet, from = 1, to = 2)$title, "campnet-Rec")
})

test_that("a mismatched to is an error that counts both sides", {
  expect_error(xrecode(valued(), from = c(1, 2, 3), to = c(9, 9)), "one value")
})

# ---- goldens (skip until the sweep runs) ------------------------------------

test_that("symmetrize matches UCINET", {
  for (nm in c("g5_sym_campnet_max", "g5_sym_campnet_min", "g5_sym_campnet_avg")) {
    skip_if_no_golden(nm, "transform")
  }
  m <- as.matrix(campnet)
  expect_equal(unname(as.matrix(xsymmetrize(m, method = "max"))),
               unname(golden_matrix("g5_sym_campnet_max", "transform")), tolerance = tol)
  expect_equal(unname(as.matrix(xsymmetrize(m, method = "min"))),
               unname(golden_matrix("g5_sym_campnet_min", "transform")), tolerance = tol)
  expect_equal(unname(as.matrix(xsymmetrize(m, method = "mean"))),
               unname(golden_matrix("g5_sym_campnet_avg", "transform")), tolerance = tol)
})

test_that("dichotomize matches UCINET on valued data", {
  skip_if_no_golden("g5_dich_camp92_1", "transform")
  skip_if_no_golden("g5_dich_camp92_3", "transform")
  m <- as.matrix(camp92)
  expect_equal(unname(as.matrix(xdichotomize(m, cutoff = 1))),
               unname(golden_matrix("g5_dich_camp92_1", "transform")), tolerance = tol)
  expect_equal(unname(as.matrix(xdichotomize(m, cutoff = 3))),
               unname(golden_matrix("g5_dich_camp92_3", "transform")), tolerance = tol)
})

test_that("normalize matches UCINET", {
  skip_if_no_golden("g5_norm_campnet_rowsum", "transform")
  skip_if_no_golden("g5_norm_campnet_colmax", "transform")
  m <- as.matrix(campnet)
  expect_equal(unname(as.matrix(xnormalize(m, by = "rows", method = "sum"))),
               unname(golden_matrix("g5_norm_campnet_rowsum", "transform")),
               tolerance = tol)
  expect_equal(unname(as.matrix(xnormalize(m, by = "cols", method = "max"))),
               unname(golden_matrix("g5_norm_campnet_colmax", "transform")),
               tolerance = tol)
})

# ---- printed form -----------------------------------------------------------

test_that("a transformation prints as the network it is", {
  expect_snapshot(xsymmetrize(campnet))
})
