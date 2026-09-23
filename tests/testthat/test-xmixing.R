# Mixing tables (chapter 10, section 10.5).

tol <- 1e-8

# Four nodes, two groups. a -> b within group 1; a -> c and d -> a across.
four <- function() {
  m <- matrix(0, 4, 4, dimnames = list(letters[1:4], letters[1:4]))
  m["a", "b"] <- 1
  m["a", "c"] <- 1
  m["d", "a"] <- 2
  m
}
grp <- function() c(a = 1, b = 1, c = 2, d = 2)

gender <- function() camp92_attr$Gender

test_that("seven tables, the same seven every time (Steve, 23 Sep)", {
  want <- c("Observed", "Expected (density)", "Expected (configuration)",
            "Expected (fixed outdegree)", "Ratio (density)",
            "Ratio (configuration)", "Ratio (fixed outdegree)")
  expect_equal(names(xmixing(four(), grp())$matrices), want)
  expect_equal(names(xmixing(four(), grp(), directed = FALSE)$matrices), want)
})

test_that("there is no density table and no model argument (ledger 26)", {
  expect_false("Density" %in% names(xmixing(four(), grp())$matrices))
  expect_error(xmixing(four(), grp(), model = "density"), "unused argument")
})

test_that("observed sums tie values from group to group", {
  o <- xmixing(four(), grp())$matrices$Observed
  expect_equal(unname(o), matrix(c(1, 2, 1, 0), 2, 2))
})

test_that("the density model spreads the overall density over the pairs", {
  # total 4 over 12 ordered pairs; within-group blocks have 2 pairs, between 4
  e <- xmixing(four(), grp())$matrices[["Expected (density)"]]
  d <- 4 / 12
  expect_equal(unname(e), matrix(c(2 * d, 4 * d, 4 * d, 2 * d), 2, 2))
})

test_that("the configuration model keeps group out- and in-totals", {
  e <- xmixing(four(), grp())$matrices[["Expected (configuration)"]]
  # out: group 1 sends 2, group 2 sends 2; in: group 1 receives 3, group 2 1
  expect_equal(unname(e), outer(c(2, 2), c(3, 1)) / 4)
  expect_equal(unname(rowSums(e)), c(2, 2))
})

test_that("the fixed-outdegree model spreads each group's output by size", {
  e <- xmixing(four(), grp())$matrices[["Expected (fixed outdegree)"]]
  # each group sends 2, to (n_s or n_r - 1) of the other 3 nodes
  expect_equal(unname(e), matrix(c(2 / 3, 4 / 3, 4 / 3, 2 / 3), 2, 2))
})

test_that("each ratio is observed over its own expected table", {
  mx <- xmixing(campnet, gender())$matrices
  for (mod in c("density", "configuration", "fixed outdegree")) {
    expect_equal(mx[[paste0("Ratio (", mod, ")")]],
                 mx$Observed / mx[[paste0("Expected (", mod, ")")]],
                 tolerance = tol, info = mod)
  }
})

test_that("a ratio is missing where the expectation is zero", {
  z <- matrix(0, 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  expect_true(all(is.na(xmixing(z, c(a = 1, b = 2))$matrices[["Ratio (density)"]])))
})

test_that("the observed table totals the ties, for directed data", {
  expect_equal(sum(xmixing(campnet, gender())$matrices$Observed),
               sum(as.matrix(campnet)))
})

test_that("the density and configuration models preserve the total", {
  # The density model's cells sum to d * n(n-1), the number of ties; the
  # configuration model's to the grand total by construction.
  mx <- xmixing(campnet, gender())$matrices
  expect_equal(sum(mx[["Expected (density)"]]), sum(mx$Observed), tolerance = 1e-6)
  expect_equal(sum(mx[["Expected (configuration)"]]), sum(mx$Observed),
               tolerance = 1e-6)
})

test_that("homophily shows up as a within-group density ratio above one", {
  r <- xmixing(campnet, gender())$matrices[["Ratio (density)"]]
  expect_true(all(diag(r) > 1))
  expect_true(all(r[upper.tri(r)] < 1))
})

test_that("symmetric data are directed unless told otherwise", {
  s <- pmax(four(), t(four()))
  dir <- xmixing(s, grp())$matrices$Observed
  und <- xmixing(s, grp(), directed = FALSE)$matrices$Observed
  expect_equal(sum(dir), sum(s))
  expect_equal(und, t(und))
  expect_equal(und[1, 2], sum(s[1:2, 3:4]))    # each edge once
  # asymmetric data ignore directed = FALSE
  expect_equal(xmixing(four(), grp(), directed = FALSE)$matrices,
               xmixing(four(), grp())$matrices)
})

test_that("missing cells are skipped, not summed as 1e38 (UCINET issue 25)", {
  expect_differs_from_ucinet(25)
  m <- four()
  m["b", "c"] <- NA
  o <- xmixing(m, grp())$matrices$Observed
  expect_equal(unname(o), matrix(c(1, 2, 1, 0), 2, 2))
})

test_that("numeric groups are rounded, as UCINET's getattr does", {
  expect_equal(xmixing(four(), c(1.2, 0.8, 2.1, 1.9))$matrices,
               xmixing(four(), grp())$matrices, ignore_attr = TRUE)
})

test_that("2-mode data are refused", {
  expect_error(xmixing(davis, 1:18), "1-mode")
})

test_that("the report prints", {
  expect_snapshot(xmixing(campnet, camp92_attr$Gender))
})

# ---- goldens --------------------------------------------------------------------
#
# UCINET runs one model per call, so the three expected tables come from three
# runs of the dialog (inst/goldens/cohesion/make_goldens.txt).

test_that("campnet by gender matches UCINET under each model", {
  for (f in c("g10_mix_campnet_obs", "g10_mix_campnet_exp",
              "g10_mix_campnet_exp_config", "g10_mix_campnet_exp_fixedout")) {
    skip_if_no_golden(f, "cohesion")
  }
  mx <- xmixing(campnet, gender())$matrices
  expect_equal(unname(mx$Observed),
               unname(golden_matrix("g10_mix_campnet_obs", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(mx[["Expected (density)"]]),
               unname(golden_matrix("g10_mix_campnet_exp", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(mx[["Expected (configuration)"]]),
               unname(golden_matrix("g10_mix_campnet_exp_config", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(mx[["Expected (fixed outdegree)"]]),
               unname(golden_matrix("g10_mix_campnet_exp_fixedout", "cohesion")),
               tolerance = 1e-5)
})

test_that("the density table matches UCINET's, now from xdensitybygroups", {
  skip_if_no_golden("g10_mix_campnet_den", "cohesion")
  expect_equal(unname(xdensitybygroups(campnet, gender())$matrices$Density),
               unname(golden_matrix("g10_mix_campnet_den", "cohesion")),
               tolerance = 1e-5)
})
