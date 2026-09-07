# The package tracks one UCINET build. These tests are what makes that true
# rather than aspirational: a fixture family that drifts off the declared
# reference fails here, by name, instead of failing later as a wrong number
# with no explanation.

test_that("every golden family records the build that produced it", {
  families <- basename(list.dirs(system.file("goldens", package = "xucinet"),
                                 recursive = FALSE))
  skip_if(length(families) == 0, "package not installed with goldens")

  for (f in families) {
    manifest <- file.path(system.file("goldens", f, package = "xucinet"),
                          "UCINET-VERSION")
    expect_true(file.exists(manifest),
                info = paste0("inst/goldens/", f, " has no UCINET-VERSION file"))
    d <- read.dcf(manifest)
    expect_true("UCINET" %in% colnames(d),
                info = paste0(f, "/UCINET-VERSION has no UCINET: field"))
  }
})

test_that("every golden family is at the declared reference build", {
  want <- reference_ucinet_version()
  expect_false(is.na(want))
  expect_match(want, "^[0-9]+\\.[0-9]+$")

  families <- basename(list.dirs(system.file("goldens", package = "xucinet"),
                                 recursive = FALSE))
  skip_if(length(families) == 0, "package not installed with goldens")

  for (f in families) {
    got <- golden_ucinet_version(f)
    if (is.na(got)) next                      # exempt: see ucinet/UCINET-VERSION
    expect_identical(got, want,
                     info = paste0("inst/goldens/", f, " is at UCINET ", got,
                                   ", reference is ", want,
                                   " - regenerate it or correct DESCRIPTION"))
  }
})

test_that("the reference build check actually fires", {
  # Cheap, but it is the guard the whole convention rests on, and a check that
  # silently never runs is worse than no check.
  expect_error(check_golden_version("density", want = "0.0"),
               "produced by UCINET 6[.]849 but DESCRIPTION declares 0[.]0")
  # and an exempt folder stays quiet whatever it is compared against
  expect_silent(check_golden_version("ucinet", want = "0.0"))
})
