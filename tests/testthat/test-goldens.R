# xdensity against UCINET's own numbers, at 1e-6.
#
# The fixtures come from inst/goldens/density/make_goldens.txt, run in UCINET.
# Until that has been run every test here skips, so the harness can be committed
# ahead of the fixtures without turning CI red. Once the g_* datasets are in the
# folder these start comparing for real; nothing needs changing to switch them
# on. See inst/goldens/README.md for how to add a routine in about ten lines.

tol <- 1e-6

test_that("the harness knows where the goldens live", {
  expect_true(nzchar(goldens_dir("density")))
  expect_true(file.exists(file.path(goldens_dir("density"), "make_goldens.txt")))
  # the four inputs the batch runs on ship with the package
  for (f in c("campnet", "hightech", "davis", "baker_journals")) {
    expect_true(file.exists(file.path(goldens_dir("density"), paste0(f, ".##h"))),
                info = f)
  }
})

test_that("parse_golden_log picks numbers out of a UCINET log block", {
  f <- tempfile(); on.exit(unlink(f))
  writeLines(c("DENSITY", "", "Density          0.17647059",
               "Avg Degree       3.00000000", "No. of Ties     54",
               "some prose that is not a measure"), f)
  got <- parse_golden_log(f)
  expect_equal(unname(got[["Density"]]), 0.17647059)
  expect_equal(unname(got[["Avg Degree"]]), 3)
  expect_equal(unname(got[["No. of Ties"]]), 54)
  expect_false("some prose that is not a measure" %in% names(got))
})

# ---- campnet: binary, directed ----------------------------------------------

test_that("density of campnet matches UCINET", {
  skip_if_no_golden("g_campnet_den")
  expect_equal(xdensity(campnet)$summary$Density,
               golden_value("g_campnet_den", "Density"), tolerance = tol)
})

test_that("the whole-network block for campnet matches UCINET", {
  skip_if_no_golden("g_campnet_coh")
  res <- xdensity(campnet)
  expect_equal(res$summary$Density,
               golden_value("g_campnet_coh", "Density"), tolerance = tol)
  expect_equal(res$summary$`Avg Degree`,
               golden_value("g_campnet_coh", "Avg Degree"), tolerance = tol)
  expect_equal(res$summary$`No. of Ties`,
               golden_value("g_campnet_coh", "# of ties"), tolerance = tol)
})

# ---- hightech: three relations ----------------------------------------------

test_that("density of each hightech relation matches UCINET", {
  skip_if_no_golden("g_hightech_den")
  gold <- golden_matrix("g_hightech_den")
  # one value per matrix in the stack, in stack order
  vals <- as.vector(gold)
  expect_length(vals, xnrelations(hightech))
  for (k in seq_len(xnrelations(hightech))) {
    expect_equal(xdensity(hightech, relation = k)$summary$Density, vals[k],
                 tolerance = tol, info = xrelations(hightech)[k])
  }
})

# ---- davis: 2-mode ----------------------------------------------------------

test_that("density of a 2-mode network matches UCINET", {
  skip_if_no_golden("g_davis_den")
  expect_equal(xdensity(davis)$summary$Density,
               golden_value("g_davis_den", "Density"), tolerance = tol)
})

# ---- baker_journals: valued -------------------------------------------------

test_that("density of valued data matches UCINET", {
  # For valued data density is the mean cell value, not a proportion, so this
  # is the case that catches a wrong denominator.
  skip_if_no_golden("g_baker_den")
  expect_equal(xdensity(baker_journals)$summary$Density,
               golden_value("g_baker_den", "Density"), tolerance = tol)
})

test_that("dichotomising valued data matches UCINET's own dichotomisation", {
  skip_if_no_golden("g_baker_bin_den")
  expect_equal(xdensity(baker_journals, weighted = FALSE)$summary$Density,
               golden_value("g_baker_bin_den", "Density"), tolerance = tol)
})

test_that("we dichotomise the same cells UCINET does", {
  skip_if_no_golden("g_baker_bin")
  ours <- (as.matrix(baker_journals) > 0) * 1
  expect_equal(unname(ours), unname(golden_matrix("g_baker_bin")), tolerance = tol)
})

# ---- printed report ---------------------------------------------------------

test_that("our report agrees with UCINET's log where the two overlap", {
  log <- file.path(goldens_dir("density"), "make_goldens.log")
  skip_if_not(file.exists(log), "make_goldens.log not captured yet")
  gold <- parse_golden_log(log)
  skip_if(!("Density" %in% names(gold)), "no Density line in the log")
  expect_equal(xdensity(campnet)$summary$Density,
               unname(gold[["Density"]][1]), tolerance = 1e-5)
})
