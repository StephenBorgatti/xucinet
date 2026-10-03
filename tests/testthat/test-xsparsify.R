# xsparsify(): Local Sparsification as UCINET 6.850's fixed routine
# (UCINET-ISSUES 45; issue #37). Three layers: the hand-worked example, the
# rules one at a time, and UCINET's own results. Until the goldens sweep, the
# UCINET results are the dropped pairs and counts from the 6.850 development
# build's dialog runs of 3 Oct 2026 (C:/Dev/ucinet/Planning/tests/lspar,
# compare_lspar.out.txt: 37 checks against the same rules); the golden tests
# below skip until g5_lspar_* exist.

# The three test inputs are shipped beside the transform goldens (made by
# C:/Dev/ucinet/Planning/tests/lspar/make_inputs.R).
lsp_input <- function(name) golden_matrix(name, "transform")
dropped <- function(input, output) {
  a <- input != 0 | t(input) != 0; a[is.na(a)] <- FALSE
  k <- output != 0 | t(output) != 0; k[is.na(k)] <- FALSE
  d <- which(upper.tri(a) & a & !k, arr.ind = TRUE)
  sort(paste(rownames(input)[d[, 1]], colnames(input)[d[, 2]], sep = "-"))
}
history_counts <- function(s) {
  h <- attr(s, "history")
  as.integer(regmatches(h, regexec("([0-9]+) of ([0-9]+) ties kept", h))[[1]][2:3])
}

# Two 4-cliques {N1..N4} and {N5..N8} joined by the bridge N4-N5.
barbell <- function() {
  lab <- paste0("N", 1:8)
  m <- matrix(0, 8, 8, dimnames = list(lab, lab))
  m[1:4, 1:4] <- 1; m[5:8, 5:8] <- 1; diag(m) <- 0
  m[4, 5] <- m[5, 4] <- 1
  m
}

test_that("the hand-worked barbell: the bridge goes", {
  m <- barbell()
  # Every node keeps ceiling(d^0.5) = 2 ties. Jaccard is 0.5 inside a clique,
  # 0.4 to the bridge node, 0 for the bridge; N4 keeps N1, N2 by node order,
  # N5 keeps N6, N7.
  s <- xsparsify(m)
  expect_equal(dropped(m, as.matrix(s)), c("N3-N4", "N4-N5", "N5-N8"))
  expect_equal(history_counts(s), c(10L, 13L))
  # by value, binary data: node order alone, with a warning
  expect_warning(v <- xsparsify(m, method = "value"), "same value")
  expect_equal(dropped(m, as.matrix(v)), c("N3-N4", "N7-N8"))
})

test_that("the keep count is ceiling(d^e), at least 1, at most d", {
  expect_equal(xucinet:::sparsify_keep(c(1, 2, 4, 9, 100), 0.5), c(1, 2, 2, 3, 10))
  expect_equal(xucinet:::sparsify_keep(c(3, 4), 0.3), c(2, 2))
  expect_equal(xucinet:::sparsify_keep(c(1, 5, 17), 1), c(1, 5, 17))
})

test_that("e = 1 returns the input, missing cells included", {
  m <- lsp_input("lsp_missing")
  expect_identical(as.matrix(xsparsify(m, e = 1)), m)
  expect_identical(as.matrix(xsparsify(campnet, e = 1)), as.matrix(campnet))
})

test_that("directed data: ranked on the symmetrized network, both cells kept", {
  m <- as.matrix(campnet)
  s <- as.matrix(xsparsify(campnet))
  a <- (m != 0 | t(m) != 0) & upper.tri(m)
  kept <- (s != 0 | t(s) != 0)[a]
  expect_equal(s[a][kept], m[a][kept])
  expect_equal(t(s)[a][kept], t(m)[a][kept])
  expect_true(all(s[a][!kept] == 0 & t(s)[a][!kept] == 0))
  expect_match(attr(xsparsify(campnet), "history"), "symmetrized network")
})

test_that("missing cells are no tie and stay missing", {
  m <- lsp_input("lsp_missing")
  s <- as.matrix(xsparsify(m))
  expect_true(is.na(s["N1", "N2"]) && is.na(s["N3", "N4"]))
  # N1-N2 is still a tie (the other cell is 1); N3-N4 is not
  expect_equal(history_counts(xsparsify(m)), c(10L, 12L))
})

test_that("equal Jaccard scores are decided by tie value, then node order", {
  v <- lsp_input("lsp_valued")
  # complete graph: every pair has Jaccard 0.6, so the values decide; A-E
  # ranks as 8, the larger of its two cells
  expect_equal(dropped(v, as.matrix(xsparsify(v))), c("A-D", "B-C", "C-E", "D-E"))
  expect_equal(dropped(v, as.matrix(xsparsify(v, method = "value"))),
               c("A-D", "B-C", "C-E", "D-E"))
  expect_no_warning(xsparsify(v, method = "value"))
})

test_that("campnet agrees with UCINET 6.850 (dialog runs of 3 Oct 2026)", {
  m <- as.matrix(campnet)
  expect_equal(dropped(m, as.matrix(xsparsify(campnet))),
               sort(c("HOLLY-PAM", "HOLLY-PAT", "PAT-JENNIE", "PAULINE-JOHN",
                      "MICHAEL-GERY", "GERY-STEVE", "BERT-RUSS")))
  expect_equal(dropped(m, as.matrix(suppressWarnings(xsparsify(campnet, method = "value")))),
               sort(c("PAULINE-ANN", "BILL-HARRY", "DON-HARRY", "STEVE-BERT",
                      "STEVE-RUSS", "BERT-RUSS")))
  expect_equal(dropped(m, as.matrix(xsparsify(campnet, e = 0.3))),
               sort(c("HOLLY-PAM", "CAROL-PAM", "HOLLY-PAT", "PAT-JENNIE", "PAULINE-ANN",
                      "HOLLY-MICHAEL", "MICHAEL-BILL", "PAULINE-JOHN", "MICHAEL-GERY",
                      "LEE-STEVE", "GERY-STEVE", "BERT-RUSS")))
  expect_equal(dropped(m, as.matrix(suppressWarnings(xsparsify(campnet, e = 0.3, method = "value")))),
               sort(c("PAT-PAULINE", "PAULINE-ANN", "BILL-HARRY", "DON-HARRY",
                      "GERY-STEVE", "STEVE-BERT", "STEVE-RUSS", "BERT-RUSS")))
  expect_equal(history_counts(xsparsify(campnet)), c(28L, 35L))
})

test_that("the result is a transform: titled, a history, stacks kept", {
  s <- xsparsify(campnet)
  expect_s3_class(s, "xucinet")
  expect_equal(s$title, "campnet-lspar")
  expect_match(attr(s, "history"), "L-Spar, neighborhood overlap, e = 0.5\\): 28 of 35 ties kept \\(80.0%\\)")
  h <- xsparsify(hightech)
  expect_equal(xrelations(h), xrelations(hightech))
  expect_identical(as.matrix(h, relation = 2),
                   as.matrix(xsparsify(as.matrix(hightech, relation = 2))))
})

test_that("bad input is refused with a message", {
  expect_error(xsparsify(davis), "1-mode.*\\n.*sdsm")
  expect_error(xsparsify(campnet, e = 0), "greater than 0")
  expect_error(xsparsify(campnet, e = 1.5), "at most 1")
  expect_error(xsparsify(campnet, method = "jaccard"), "should be one of")
})

# ---- goldens (UCINET 6.850 final build; the goldens sweep) ------------------

test_that("xsparsify matches UCINET's Local Sparsification", {
  inputs <- list(barbell = lsp_input("lsp_barbell"), campnet = as.matrix(campnet),
                 valued = lsp_input("lsp_valued"), missing = lsp_input("lsp_missing"))
  for (net in names(inputs)) for (e in c(0.3, 0.5, 1)) for (k in 0:1) {
    nm <- sprintf("g5_lspar_%s_e%s_m%d", net, sub(".", "", format(e), fixed = TRUE), k)
    skip_if_no_golden(nm, "transform")
    got <- suppressWarnings(xsparsify(inputs[[net]], e = e, method = c("lspar", "value")[k + 1]))
    expect_equal(unname(as.matrix(got)), unname(golden_matrix(nm, "transform")), info = nm)
  }
})
