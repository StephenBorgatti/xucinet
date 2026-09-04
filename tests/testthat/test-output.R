# The report renderer (SPEC D5). The descriptive-statistics block is ported from
# uestimator / setstatlabels in Tools/G1Tools/ustats.pas, so these tests check
# against those formulas rather than against R's defaults.

test_that("the eleven statistics are UCINET's, in UCINET's order", {
  expect_equal(names(uci_stats(1:4)),
               c("Mean", "Std Dev", "Sum", "Variance", "SSQ", "MCSSQ",
                 "Euc Norm", "Minimum", "Maximum", "N of Obs", "N Missing"))
})

test_that("Variance and Std Dev are the population forms, not R's", {
  x <- c(1, 2, 3, 4, 5)
  s <- uci_stats(x)
  n <- length(x); mcssq <- sum((x - mean(x))^2)
  expect_equal(unname(s[["Variance"]]), mcssq / n)      # UCINET: mcssq/n
  expect_equal(unname(s[["Std Dev"]]), sqrt(mcssq / n))
  # and they are genuinely different from what R would give
  expect_false(isTRUE(all.equal(unname(s[["Variance"]]), stats::var(x))))
  expect_false(isTRUE(all.equal(unname(s[["Std Dev"]]), stats::sd(x))))
})

test_that("the other nine statistics are what they say", {
  x <- c(2, 4, 4, 6)
  s <- uci_stats(x)
  expect_equal(unname(s[["Mean"]]), 4)
  expect_equal(unname(s[["Sum"]]), 16)
  expect_equal(unname(s[["SSQ"]]), sum(x^2))
  expect_equal(unname(s[["MCSSQ"]]), sum((x - 4)^2))
  expect_equal(unname(s[["Euc Norm"]]), sqrt(sum(x^2)))
  expect_equal(unname(s[["Minimum"]]), 2)
  expect_equal(unname(s[["Maximum"]]), 6)
  expect_equal(unname(s[["N of Obs"]]), 4)
  expect_equal(unname(s[["N Missing"]]), 0)
})

test_that("missing values are counted, not propagated", {
  s <- uci_stats(c(1, 2, NA, 4))
  expect_equal(unname(s[["N of Obs"]]), 3)
  expect_equal(unname(s[["N Missing"]]), 1)
  expect_equal(unname(s[["Mean"]]), 7 / 3)
  expect_false(is.na(s[["Std Dev"]]))
})

test_that("an all-missing column reports zero observations rather than failing", {
  s <- uci_stats(c(NA_real_, NA_real_))
  expect_equal(unname(s[["N of Obs"]]), 0)
  expect_equal(unname(s[["N Missing"]]), 2)
  expect_true(is.na(s[["Mean"]]))
})

# ---- display ----------------------------------------------------------------

test_that("whole numbers print bare and fractions to three places", {
  # ucommon.pas sets defaultd = -3: up to three decimals, whole numbers plain.
  expect_equal(trimws(format_values(c(1, 0))), c("1", "0"))
  expect_equal(trimws(format_values(0.1764706)), "0.176")
  expect_equal(trimws(format_values(c(1, 0.5))), c("1.000", "0.500"))
})

test_that("columns are right-aligned to a common width", {
  out <- format_values(c(1, 10, 100))
  expect_true(all(nchar(out) == 3))
  expect_equal(out, c("  1", " 10", "100"))
})

test_that("display rounds but storage does not", {
  res <- xdensity(campnet)
  expect_output(print(res), "0.176")
  expect_equal(res$summary$Density, 3 / 17, tolerance = 1e-12)
})

test_that("missing cells print as blanks", {
  expect_equal(format_values(c(1, NA)), c("1", " "))
})

# ---- the report -------------------------------------------------------------

fake_output <- function() {
  net <- as_xucinet(campnet)
  nodes <- data.frame(Degree = c(3, 1, 4, 2), nDegree = c(0.5, 0.25, 1, 0.5),
                      row.names = c("a", "b", "c", "d"))
  new_xucinet_output("Degree", net, nodes = nodes,
                     matrices = list(Distances = matrix(c(0, 1, 1, 0), 2, 2)),
                     assumptions = "Data treated as directed.")
}

test_that("the report carries title, dataset, assumptions and a stats block", {
  out <- capture.output(print(fake_output()))
  expect_true(any(grepl("^DEGREE$", out)))
  expect_true(any(grepl("Input dataset:  campnet", out)))
  expect_true(any(grepl("Note:           Data treated as directed", out)))
  expect_true(any(grepl("DESCRIPTIVE STATISTICS", out)))
  expect_true(any(grepl("Euc Norm", out)))
  expect_true(any(grepl("N Missing", out)))
})

test_that("the stats block can be turned off", {
  out <- capture.output(print(fake_output(), stats = FALSE))
  expect_false(any(grepl("DESCRIPTIVE STATISTICS", out)))
})

test_that("matrix results print as their own titled sections", {
  out <- capture.output(print(fake_output()))
  expect_true(any(grepl("^Distances$", out)))
})

test_that("node tables keep original order unless sort is asked for", {
  out <- capture.output(print(fake_output()))
  rows <- grep("^[abcd] ", out, value = TRUE)
  expect_equal(substr(rows, 1, 1), c("a", "b", "c", "d"))

  sorted <- capture.output(print(fake_output(), sort = "Degree"))
  rows <- grep("^[abcd] ", sorted, value = TRUE)
  expect_equal(substr(rows, 1, 1), c("c", "a", "d", "b"))
})

test_that("sort accepts a position and refuses an unknown column", {
  bypos <- capture.output(print(fake_output(), sort = 1))
  byname <- capture.output(print(fake_output(), sort = "Degree"))
  expect_identical(bypos, byname)
  expect_error(print(fake_output(), sort = "nope"), "must name a column")
  expect_error(print(fake_output(), sort = "nope"), "Degree, nDegree")
})

# ---- summary() and as.data.frame() ------------------------------------------

test_that("summary() of a node-level result is the statistics block", {
  s <- summary(fake_output())
  expect_s3_class(s, "data.frame")
  expect_equal(rownames(s), uci_stat_labels)
  expect_equal(names(s), c("Degree", "nDegree"))
  expect_equal(s["Sum", "Degree"], 10)
})

test_that("summary() of a whole-network result is its statistics", {
  s <- summary(xdensity(campnet))
  expect_s3_class(s, "data.frame")
  expect_equal(s$Density, 3 / 17, tolerance = 1e-12)
})

test_that("as.data.frame() returns the node table when there is one", {
  expect_equal(nrow(as.data.frame(fake_output())), 4)
  expect_equal(names(as.data.frame(xdensity(campnet)))[1], "Density")
})

# ---- xdensity fidelity ------------------------------------------------------

test_that("xdensity reports UCINET's population standard deviation", {
  res <- xdensity(campnet)
  m <- as.matrix(campnet)
  cells <- m[row(m) != col(m)]
  expect_equal(res$summary$`Std Dev`, sqrt(sum((cells - mean(cells))^2) / length(cells)))
  expect_false(isTRUE(all.equal(res$summary$`Std Dev`, stats::sd(cells))))
})

test_that("relation= picks a relation and says so in the report", {
  out <- capture.output(print(xdensity(hightech, relation = "Friendship")))
  expect_true(any(grepl("Relation: Friendship \\(of 3\\)", out)))
  expect_equal(xdensity(hightech, relation = 2)$summary$Density,
               xdensity(hightech, relation = "Friendship")$summary$Density)
})

# ---- the snapshot issue #6 asks for -----------------------------------------

test_that("the campnet density report is stable", {
  expect_snapshot(xdensity(campnet))
})
