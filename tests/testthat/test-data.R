# The shipped datasets are built from the UCINET ##h files by
# data-raw/make-datasets.R. These tests check the build came out right, since a
# silent transposition or a lost label would poison every book example.

networks <- c("baker_journals", "bkham", "camp92", "campnet", "pv504", "pv960",
              "burkhardt", "davis", "eies", "doctorates", "wiring", "cities",
              "polarstation", "kaptail", "knecht", "hightech", "mainas_terro",
              "newfrat", "padgett", "pane_training", "sampson", "trade_pre29",
              "papuan_village", "wolfe_primates", "zachary",
              "lazega", "newguinea", "supremecourt")
attributes <- c("camp92_attr", "pv504_attr", "eies_attr", "knecht_attr",
                "hightech_attr", "padgett_attr", "wolfe_primates_attr",
                "zachary_attr", "lazega_attr",
                "supremecourt_cases_attr", "supremecourt_judges_attr")

get_data <- function(name) {
  env <- new.env(parent = emptyenv())
  utils::data(list = name, package = "xucinet", envir = env)
  get(name, envir = env, inherits = FALSE)
}

test_that("every dataset in the manifest is shipped and listed", {
  shipped <- utils::data(package = "xucinet")$results[, "Item"]
  expect_setequal(shipped, c(networks, attributes))
})

test_that("every network is an xucinet object with labels on both margins", {
  for (nm in networks) {
    net <- get_data(nm)
    expect_s3_class(net, "xucinet")
    m <- as.matrix(net)
    expect_false(is.null(rownames(m)), info = nm)
    expect_false(is.null(colnames(m)), info = nm)
    expect_true(all(nzchar(rownames(m))), info = nm)
    expect_equal(net$title, nm, info = nm)
  }
})

test_that("every attribute table is a data frame keyed by node label", {
  for (nm in attributes) {
    df <- get_data(nm)
    expect_s3_class(df, "data.frame")
    expect_false(is.null(rownames(df)), info = nm)
    expect_true(all(vapply(df, is.numeric, logical(1))), info = nm)
  }
})

test_that("attribute tables line up with their network, node for node", {
  pairs <- list(c("camp92", "camp92_attr"), c("pv504", "pv504_attr"),
                c("eies", "eies_attr"), c("knecht", "knecht_attr"),
                c("hightech", "hightech_attr"), c("padgett", "padgett_attr"),
                c("wolfe_primates", "wolfe_primates_attr"),
                c("zachary", "zachary_attr"), c("lazega", "lazega_attr"))
  for (p in pairs) {
    net <- get_data(p[1]); df <- get_data(p[2])
    expect_identical(rownames(as.matrix(net)), rownames(df), info = p[1])
  }
})

test_that("campnet borrows camp92's attribute table", {
  # There is no campnet_attr: same 18 people, so camp92_attr keys both.
  expect_identical(rownames(as.matrix(get_data("campnet"))),
                   rownames(get_data("camp92_attr")))
  expect_false("campnet_attr" %in% utils::data(package = "xucinet")$results[, "Item"])
})

test_that("supremecourt has one attribute table per mode", {
  m <- as.matrix(get_data("supremecourt"))
  expect_identical(rownames(m), rownames(get_data("supremecourt_cases_attr")))
  expect_identical(colnames(m), rownames(get_data("supremecourt_judges_attr")))
})

# ---- shapes and labels that a transposition would break ---------------------

test_that("2-mode datasets keep rows and columns the right way round", {
  davis <- get_data("davis")
  expect_equal(dim(davis), c(18, 14))          # 18 women, 14 events
  expect_equal(davis$mode, "2-mode")
  expect_equal(rownames(as.matrix(davis))[1], "EVELYN")
  expect_equal(colnames(as.matrix(davis))[1], "E1")
  expect_equal(sum(as.matrix(davis)), 89)      # the published attendance total

  doc <- get_data("doctorates")
  expect_equal(dim(doc), c(12, 8))             # 12 fields by 8 years
  expect_equal(rownames(as.matrix(doc))[1], "Engineering")
  expect_equal(colnames(as.matrix(doc))[1], "1960")
})

test_that("multi-relation datasets keep their relation names", {
  expect_equal(xrelations(get_data("hightech")),
               c("Advice", "Friendship", "ReportTo"))
  expect_equal(xrelations(get_data("padgett")), c("Marriage", "Business"))
  expect_equal(xrelations(get_data("zachary")), c("Connection", "Strength"))
  expect_equal(xnrelations(get_data("sampson")), 10)
  expect_equal(xnrelations(get_data("newfrat")), 15)   # week 9 is missing
  expect_equal(xnrelations(get_data("wiring")), 6)
})

test_that("node labels are the ones UCINET uses", {
  expect_equal(rownames(as.matrix(get_data("campnet")))[1:2], c("HOLLY", "BRAZEY"))
  expect_equal(rownames(as.matrix(get_data("padgett")))[1], "ACCIAIUOLI")
  expect_equal(rownames(as.matrix(get_data("sampson")))[1], "ROMUALD")
  expect_equal(rownames(as.matrix(get_data("cities")))[1], "BOSTON")
  expect_equal(rownames(as.matrix(get_data("trade_pre29")))[1:2], c("UK", "US"))
})

test_that("directedness matches what the data actually are", {
  expect_true(get_data("campnet")$directed)
  expect_false(get_data("padgett")$directed)   # marriage and business symmetric
  expect_false(get_data("cities")$directed)    # a distance matrix
  expect_true(is.na(get_data("davis")$directed))  # 2-mode
})

test_that("the big ones are the size they should be", {
  expect_equal(dim(get_data("pv960")), c(960, 960))
  expect_equal(dim(get_data("pv504")), c(504, 504))
  expect_equal(dim(get_data("mainas_terro")), c(4275, 4275))
})

# ---- filename-as-net convenience --------------------------------------------

test_that("a dataset name works anywhere a network is expected", {
  expect_equal(dim(as_xucinet("campnet")), c(18, 18))
  expect_equal(as_xucinet("campnet")$title, "campnet")
  expect_identical(as.matrix(as_xucinet("campnet")),
                   as.matrix(get_data("campnet")))
  expect_equal(xdensity("campnet")$summary$Density,
               xdensity(get_data("campnet"))$summary$Density)
})

test_that("the report names the dataset, not the expression", {
  expect_output(print(xdensity("campnet")), "campnet")
})

test_that("a real file beats a dataset of the same name", {
  d <- file.path(tempdir(), paste0("shadow", sample.int(1e6, 1)))
  dir.create(d)
  on.exit(unlink(d, recursive = TRUE), add = TRUE)
  old <- setwd(d); on.exit(setwd(old), add = TRUE)
  # a 3x3 file called campnet, which must win over the 18x18 dataset
  xsaveucinet(matrix(0, 3, 3), "campnet")
  expect_equal(dim(as_xucinet("campnet")), c(3, 3))
})

test_that("an unknown name still gives the file-type error, not a data error", {
  expect_error(as_xucinet("no_such_dataset_anywhere"), "Cannot detect the file type")
})

test_that("a path is never mistaken for a dataset name", {
  expect_error(xread("some/dir/campnet"), "Cannot detect the file type")
})

test_that("the three newly named datasets carry their structure", {
  laz <- get_data("lazega")
  expect_equal(dim(laz), c(71, 71, 3))
  expect_equal(xrelations(laz), c("Advice", "Coworking", "Friendship"))

  ng <- get_data("newguinea")
  expect_equal(dim(ng), c(16, 16, 2))
  expect_equal(xrelations(ng), c("Alliance", "Opposition"))
  expect_false(ng$directed)
  expect_equal(rownames(as.matrix(ng))[1], "GAVEV")

  sc <- get_data("supremecourt")
  expect_equal(dim(sc), c(376, 9))       # cases by judges, not the reverse
  expect_equal(sc$mode, "2-mode")
  expect_equal(colnames(as.matrix(sc))[1], "Rehnquist")
  expect_equal(sum(is.na(as.matrix(sc))), 9)
})
