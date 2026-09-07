# The ASNR 1e alias layer (issue #9). The list comes from the crosswalk in the
# book repo via data-raw/make-aliases.R, so these tests walk the whole table
# rather than a sample: an alias that stopped resolving would be a book example
# that stopped running.

test_that("every 1e name in the table resolves to an exported function", {
  map <- xucinet_1e_names()
  expect_gt(length(map), 100)
  for (old in names(map)) {
    expect_true(exists(old, envir = asNamespace("xucinet"), mode = "function"),
                info = old)
    expect_true(old %in% getNamespaceExports("xucinet"), info = old)
  }
})

test_that("each wrapper points at the 2.0 name the table says", {
  # Read it out of the function body rather than trusting the table twice over.
  map <- xucinet_1e_names()
  for (old in names(map)) {
    body_txt <- paste(deparse(body(get(old, envir = asNamespace("xucinet")))),
                      collapse = " ")
    expect_true(grepl(paste0('"', map[[old]], '"'), body_txt, fixed = TRUE),
                info = old)
    expect_true(grepl("alias_1e", body_txt, fixed = TRUE), info = old)
  }
})

test_that("a wrapper whose target exists calls it and names the replacement", {
  # xDensity -> xdensity, which is written.
  expect_message(xDensity(campnet), "xucinet 2.0 calls it xdensity")
  expect_equal(suppressMessages(xDensity(campnet))$summary$Density,
               xdensity(campnet)$summary$Density)
})

test_that("a wrapper whose target is unwritten says so, and says which", {
  # xBetweennessCentrality -> xbetweenness, still to come. xDegreeCentrality
  # used to be the example here and is not any more, which is the point: the
  # message turns into a working call the day the routine lands, with no change
  # to the alias layer.
  expect_error(xBetweennessCentrality(campnet), "xbetweenness\\(\\) is not written yet")
  expect_error(xBetweennessCentrality(campnet), "ASNR 1e name")
  # the message names the routine to wait for, not just "not implemented"
  expect_error(xBetweennessCentrality(campnet), "the day xbetweenness\\(\\) lands")
})

test_that("xDegreeCentrality now forwards, because xdegree has landed", {
  expect_message(xDegreeCentrality(campnet), "xucinet 2.0 calls it xdegree")
  expect_equal(suppressMessages(xDegreeCentrality(campnet))$nodes,
               xdegree(campnet)$nodes)
})

test_that("the spellings the 1e was inconsistent about all resolve, together", {
  # The crosswalk README lists these as names the 1e used two ways. Both
  # spellings have to work, and both have to land on the same 2.0 routine.
  pairs <- list(c("xTieDichotomize", "xDichotomize"),
                c("xWalkTrap", "xWalktrap"),
                c("xLabelProp", "xLabelPropagation"),
                c("xBlockOptimize", "xBlockOptimization"),
                c("xTwoModeToOneMode", "xTwomodeToOnemode"),
                c("xAutoRegression", "xAutoregression"),
                c("xHierarchicalClustering", "xHierarchicalCluster"))
  map <- xucinet_1e_names()
  for (p in pairs) {
    expect_true(all(p %in% names(map)), info = paste(p, collapse = " / "))
    expect_equal(map[[p[1]]], map[[p[2]]], info = paste(p, collapse = " / "))
  }
})

test_that("the names the 0.x package exported are all covered", {
  # The crosswalk is built from the manuscript, which does not mention every
  # function the released package exported. Both sets are in the table.
  from_0x <- c("xAddAttributesToProject", "xAttributeToNetwork", "xBlockmodel",
               "xBlockmodelOptimizing", "xCombineTies", "xCorePeriphery",
               "xDualStructuralEquivalence", "xMultipleTieComposition",
               "xNegativeDegreeCentrality", "xNegativeWeightedCentrality",
               "xPermuteQAP", "xRemoveFromProject")
  expect_true(all(from_0x %in% names(xucinet_1e_names())))
})

test_that("the aliases share one help page, marked internal", {
  # \keyword{internal} keeps them out of the pkgdown reference index, so they do
  # not crowd out the 2.0 interface (issue #9, and #10 when the site is built).
  rd <- testthat::test_path("..", "..", "man", "xucinet-1e.Rd")
  skip_if_not(file.exists(rd), "man/ not present in this check layout")
  txt <- readLines(rd, warn = FALSE)
  expect_true(any(grepl("\\keyword{internal}", txt, fixed = TRUE)))
  # every alias is an \alias{} on that one page rather than a page of its own
  aliased <- sub(".*\\\\alias\\{(.*)\\}.*", "\\1", grep("\\\\alias\\{", txt, value = TRUE))
  expect_true(all(names(xucinet_1e_names()) %in% aliased))
})

test_that("no alias collides with a 2.0 export", {
  # 1e names are xCamelCase and 2.0 names are lowercase, so a collision would
  # mean one of the two conventions had slipped.
  exports <- getNamespaceExports("xucinet")
  twopoint0 <- setdiff(exports, c(names(xucinet_1e_names()), "xucinet_1e_names"))
  expect_length(intersect(names(xucinet_1e_names()), twopoint0), 0)
  expect_true(all(grepl("^x[A-Z]", names(xucinet_1e_names()))))
})

test_that("xEigenvector is not an alias", {
  # It appears in the 1e's core-periphery text as the name of a method option,
  # not a function. As an alias it would mislead: anyone typing it wants
  # eigenvector centrality (Steve, 6 Sep 2026).
  expect_false("xEigenvector" %in% names(xucinet_1e_names()))
  expect_false(exists("xEigenvector", envir = asNamespace("xucinet")))
  # the real centrality alias is still there and points where it should
  expect_equal(xucinet_1e_names()[["xEigenvectorCentrality"]], "xeigenvector")
})

test_that("xRegression goes to the regression routine", {
  expect_equal(xucinet_1e_names()[["xRegression"]], "xregression")
  expect_equal(xucinet_1e_names()[["xPermuteRegression"]], "xregression")
})

test_that("the negative-tie aliases explain what to do instead", {
  # Both are degree on a negative-tie matrix rather than routines of their own.
  # The note used to arrive inside the not-written-yet error; now that xdegree
  # exists the call succeeds and the note arrives as the message beside it, so
  # the explanation survives the target landing rather than disappearing with it.
  for (nm in c("xNegativeDegreeCentrality", "xNegativeWeightedCentrality")) {
    expect_equal(xucinet_1e_names()[[nm]], "xdegree")
    f <- get(nm, envir = asNamespace("xucinet"))
    expect_message(f(campnet), "negative-tie matrix")
    expect_message(f(campnet), "xpncentrality")
  }
})
