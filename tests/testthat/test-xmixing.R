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

test_that("four tables in UCINET's order", {
  expect_equal(names(xmixing(four(), grp())$matrices),
               c("Observed", "Expected", "Density", "Ratio"))
})

test_that("observed sums tie values from group to group", {
  o <- xmixing(four(), grp())$matrices$Observed
  expect_equal(unname(o), matrix(c(1, 2, 1, 0), 2, 2))
})

test_that("the density model spreads the overall density over the pairs", {
  # total 4 over 12 ordered pairs; within-group blocks have 2 pairs, between 4
  e <- xmixing(four(), grp())$matrices$Expected
  d <- 4 / 12
  expect_equal(unname(e), matrix(c(2 * d, 4 * d, 4 * d, 2 * d), 2, 2))
})

test_that("the configuration model keeps group out- and in-totals", {
  e <- xmixing(four(), grp(), model = "configuration")$matrices$Expected
  # out: group 1 sends 2, group 2 sends 2; in: group 1 receives 3, group 2 1
  expect_equal(unname(e), outer(c(2, 2), c(3, 1)) / 4)
  expect_equal(unname(rowSums(e)), c(2, 2))
})

test_that("the fixed-outdegree model spreads each group's output by size", {
  e <- xmixing(four(), grp(), model = "fixedout")$matrices$Expected
  # each group sends 2, to (n_s or n_r - 1) of the other 3 nodes
  expect_equal(unname(e), matrix(c(2 / 3, 4 / 3, 4 / 3, 2 / 3), 2, 2))
})

test_that("ratio is observed over expected, missing where expected is zero", {
  res <- xmixing(four(), grp())$matrices
  expect_equal(res$Ratio, res$Observed / res$Expected)
  z <- matrix(0, 2, 2, dimnames = list(c("a", "b"), c("a", "b")))
  expect_true(all(is.na(xmixing(z, c(a = 1, b = 2))$matrices$Ratio)))
})

test_that("density is xcombinenodes' block mean", {
  expect_equal(unname(xmixing(campnet, camp92_attr$Gender)$matrices$Density),
               unname(as.matrix(xcombinenodes(campnet, camp92_attr$Gender))),
               tolerance = tol)
})

test_that("the density model agrees with xdensitybygroups", {
  a <- xmixing(campnet, camp92_attr$Gender)$matrices
  b <- xdensitybygroups(campnet, camp92_attr$Gender)$matrices
  expect_equal(a$Expected, b$Expected)
  expect_equal(a$Observed, b$Observed)
})

test_that("symmetric data are directed unless told otherwise", {
  s <- pmax(four(), t(four()))
  dir <- xmixing(s, grp())$matrices$Observed
  und <- xmixing(s, grp(), directed = FALSE)$matrices$Observed
  expect_equal(sum(dir), sum(s))
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

test_that("campnet by gender matches UCINET under each model", {
  for (f in c("g10_mix_campnet_obs", "g10_mix_campnet_exp",
              "g10_mix_campnet_exp_config", "g10_mix_campnet_exp_fixedout")) {
    skip_if_no_golden(f, "cohesion")
  }
  g <- camp92_attr$Gender
  expect_equal(unname(xmixing(campnet, g)$matrices$Observed),
               unname(golden_matrix("g10_mix_campnet_obs", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(xmixing(campnet, g)$matrices$Expected),
               unname(golden_matrix("g10_mix_campnet_exp", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(xmixing(campnet, g, model = "configuration")$matrices$Expected),
               unname(golden_matrix("g10_mix_campnet_exp_config", "cohesion")),
               tolerance = 1e-5)
  expect_equal(unname(xmixing(campnet, g, model = "fixedout")$matrices$Expected),
               unname(golden_matrix("g10_mix_campnet_exp_fixedout", "cohesion")),
               tolerance = 1e-5)
})
