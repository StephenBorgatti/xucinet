# The .uci single-file JSON format (SPEC D6). Schema in inst/schema/uci-1.0.json.
#
# The format is meant to be written by xucinet and read by UCINET, so the tests
# lean on exactness: a value that survives a round trip here has to survive it
# bit for bit, not to three decimals.

skip_if_no_jsonlite <- function() skip_if_not_installed("jsonlite")

tmpuci <- function() file.path(tempdir(), paste0("t", sample.int(1e6, 1), ".uci"))

roundtrip <- function(net, ...) {
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(net, f, ...)
  xreaduci(f)
}

# ---- the schema and its worked example --------------------------------------

test_that("the schema ships and is valid JSON", {
  skip_if_no_jsonlite()
  p <- system.file("schema", "uci-1.0.json", package = "xucinet")
  expect_true(nzchar(p))
  s <- jsonlite::fromJSON(p, simplifyVector = FALSE)
  expect_equal(s[["$schema"]], "http://json-schema.org/draft-07/schema#")
  expect_setequal(unlist(s$required), c("uci", "mode", "nrows", "ncols", "relations"))
  # every key the writer emits is described, or the schema would reject our own
  # output for having additionalProperties
  expect_true(all(c("uci", "title", "mode", "directed", "nrows", "ncols",
                    "rowlabels", "collabels", "datatype", "relations",
                    "attributes", "provenance") %in% names(s$properties)))
})

test_that("the worked example reads back as campnet", {
  skip_if_no_jsonlite()
  p <- system.file("schema", "campnet-example.uci", package = "xucinet")
  expect_true(nzchar(p))
  net <- xreaduci(p)
  expect_identical(as.matrix(net), as.matrix(campnet))
  expect_equal(net$title, "campnet")
  expect_true(net$directed)
  # and it demonstrates the attribute block, which campnet itself has no room for
  expect_s3_class(net$attributes, "data.frame")
  expect_equal(names(net$attributes), c("Gender", "Role", "Betweenness"))
  expect_identical(rownames(net$attributes), rownames(as.matrix(campnet)))
})

test_that("every key the writer emits is allowed by the schema", {
  skip_if_no_jsonlite()
  s <- jsonlite::fromJSON(system.file("schema", "uci-1.0.json", package = "xucinet"),
                          simplifyVector = FALSE)
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(campnet, f, attributes = camp92_attr)
  doc <- jsonlite::fromJSON(f, simplifyVector = FALSE)
  expect_true(all(names(doc) %in% names(s$properties)))
  rel <- doc$relations[[1]]
  expect_true(all(names(rel) %in% names(s$properties$relations$items$properties)))
})

# ---- the round trips issue #4 asks for --------------------------------------

test_that("a 1-mode dataset round trips", {
  skip_if_no_jsonlite()
  back <- roundtrip(campnet)
  expect_identical(as.matrix(back), as.matrix(campnet))
  expect_equal(back$mode, "1-mode")
  expect_true(back$directed)
  expect_equal(back$title, "campnet")
})

test_that("a 2-mode dataset round trips, rows and columns the right way round", {
  skip_if_no_jsonlite()
  back <- roundtrip(davis)
  expect_identical(as.matrix(back), as.matrix(davis))
  expect_equal(dim(back), c(18, 14))
  expect_equal(back$mode, "2-mode")
  expect_equal(rownames(as.matrix(back))[1], "EVELYN")
  expect_equal(colnames(as.matrix(back))[1], "E1")
})

test_that("a multi-relation dataset round trips, names and order intact", {
  skip_if_no_jsonlite()
  back <- roundtrip(sampson)
  expect_equal(xnrelations(back), 10)
  expect_equal(xrelations(back), xrelations(sampson))
  for (k in seq_len(10)) {
    expect_identical(as.matrix(back, relation = k), as.matrix(sampson, relation = k),
                     info = xrelations(sampson)[k])
  }
})

test_that("2-mode directedness comes back as NA, not FALSE", {
  skip_if_no_jsonlite()
  # The writer omits the key rather than inventing a value, and the reader has
  # to leave it undetermined rather than let as_xucinet() guess from symmetry.
  expect_true(is.na(roundtrip(davis)$directed))
})

# ---- exactness --------------------------------------------------------------

test_that("missing values survive as missing", {
  skip_if_no_jsonlite()
  back <- roundtrip(supremecourt)
  expect_equal(sum(is.na(as.matrix(back))), 9)
  expect_identical(as.matrix(back), as.matrix(supremecourt))
})

test_that("doubles survive to the last bit", {
  skip_if_no_jsonlite()
  # 17 significant digits. jsonlite's default of 4 decimals would make this fail
  # on the first value, and digits = NA still loses the last two bits.
  m <- matrix(c(1/3, pi, .Machine$double.eps, 1e-300), 2, 2)
  back <- as.matrix(roundtrip(as_xucinet(m)))
  expect_identical(unname(back), m)
})

test_that("valued data keeps its values", {
  skip_if_no_jsonlite()
  expect_identical(as.matrix(roundtrip(baker_journals)), as.matrix(baker_journals))
})

test_that("whole numbers come back as doubles, not integers", {
  skip_if_no_jsonlite()
  # JSON has one number type; without forcing this, a binary matrix reads back
  # as integer storage and identical() against any other network fails.
  expect_type(as.matrix(roundtrip(campnet)), "double")
})

# ---- dense and sparse payloads ----------------------------------------------

test_that("both layouts give the same matrix back", {
  skip_if_no_jsonlite()
  dense <- roundtrip(campnet, layout = "matrix")
  sparse <- roundtrip(campnet, layout = "edgelist")
  expect_identical(as.matrix(dense), as.matrix(campnet))
  expect_identical(as.matrix(sparse), as.matrix(campnet))
})

test_that("a sparse payload records missing cells rather than dropping them", {
  skip_if_no_jsonlite()
  m <- matrix(0, 4, 4); m[1, 2] <- 1; m[3, 4] <- NA
  back <- as.matrix(roundtrip(as_xucinet(m), layout = "edgelist"))
  expect_equal(back[1, 2], 1)
  expect_true(is.na(back[3, 4]))
  expect_equal(sum(back == 0, na.rm = TRUE), 14)
})

test_that("the layout is chosen by size, not by density alone", {
  skip_if_no_jsonlite()
  # SPEC D6: sparse is for large networks. campnet is sparse enough that an
  # edge list would be smaller, but at 324 cells the saving is not worth the
  # loss of readability.
  layout_of <- function(net) {
    f <- tmpuci(); on.exit(unlink(f), add = TRUE)
    xsaveuci(net, f)
    jsonlite::fromJSON(f, simplifyVector = FALSE)$relations[[1]]$layout
  }
  expect_equal(layout_of(campnet), "matrix")
  expect_equal(layout_of(mainas_terro), "edgelist")
})

test_that("sparse is dramatically smaller for a big sparse network", {
  skip_if_no_jsonlite()
  # A synthetic 300 x 300 rather than mainas_terro: the point is the ratio, and
  # writing 4275 x 4275 densely costs 53 MB and most of the suite's runtime.
  m <- matrix(0, 300, 300)
  m[cbind(1:300, c(2:300, 1))] <- 1
  f1 <- tmpuci(); f2 <- tmpuci(); on.exit(unlink(c(f1, f2)), add = TRUE)
  xsaveuci(as_xucinet(m), f1, layout = "edgelist")
  xsaveuci(as_xucinet(m), f2, layout = "matrix")
  expect_lt(file.info(f1)$size * 20, file.info(f2)$size)
  # and both still give the same matrix back
  expect_identical(as.matrix(xreaduci(f1)), as.matrix(xreaduci(f2)))
})

# ---- attributes -------------------------------------------------------------

test_that("node attributes round trip, keyed by label", {
  skip_if_no_jsonlite()
  back <- roundtrip(campnet, attributes = camp92_attr)
  expect_s3_class(back$attributes, "data.frame")
  expect_equal(names(back$attributes), names(camp92_attr))
  expect_identical(rownames(back$attributes), rownames(camp92_attr))
  expect_equal(back$attributes$Gender, camp92_attr$Gender)
})

test_that("a network without attributes reads back with none", {
  skip_if_no_jsonlite()
  expect_null(roundtrip(campnet)$attributes)
})

# ---- wiring into xread and xsave --------------------------------------------

test_that("xsave() writes .uci when nothing else is asked for", {
  skip_if_no_jsonlite()
  stem <- file.path(tempdir(), paste0("d", sample.int(1e6, 1)))
  on.exit(unlink(paste0(stem, ".uci")), add = TRUE)
  out <- xsave(campnet, stem)
  expect_true(file.exists(paste0(stem, ".uci")))
  expect_identical(as.matrix(xread(paste0(stem, ".uci"))), as.matrix(campnet))
})

test_that("xread() and as_xucinet() dispatch on the .uci extension", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(davis, f)
  expect_equal(dim(xread(f)), c(18, 14))
  expect_equal(dim(as_xucinet(f)), c(18, 14))
  expect_equal(dim(xread(f, filetype = "uci")), c(18, 14))
})

test_that("xsave(filetype = 'uci') passes its layout through", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsave(campnet, f, filetype = "uci", layout = "edgelist")
  expect_equal(jsonlite::fromJSON(f, simplifyVector = FALSE)$relations[[1]]$layout,
               "edgelist")
})

# ---- errors that teach ------------------------------------------------------

test_that("a missing file is refused clearly", {
  skip_if_no_jsonlite()
  expect_error(xreaduci(file.path(tempdir(), "nope.uci")), "No .uci file")
})

test_that("a file with no uci key is refused as not being one", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  writeLines('{"nrows": 2, "ncols": 2}', f)
  expect_error(xreaduci(f), "not a .uci dataset", fixed = FALSE)
})

test_that("a schema version from the future is refused, not guessed at", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(campnet, f)
  txt <- sub('"uci": "1.0"', '"uci": "9.0"', readLines(f), fixed = TRUE)
  writeLines(txt, f)
  expect_error(xreaduci(f), "schema version 9.0")
  expect_error(xreaduci(f), "Upgrade xucinet")
})

test_that("an inconsistent file is refused with the numbers that disagree", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(campnet, f)
  txt <- sub('"nrows": 18', '"nrows": 17', readLines(f), fixed = TRUE)
  writeLines(txt, f)
  expect_error(xreaduci(f), "18 row labels but declares 17")
})

test_that("an unknown layout is refused by name", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  xsaveuci(campnet, f)
  txt <- sub('"layout": "matrix"', '"layout": "triangle"', readLines(f), fixed = TRUE)
  writeLines(txt, f)
  expect_error(xreaduci(f), "triangle")
  expect_error(xreaduci(f), "matrix")
})

test_that("a sparse payload with ragged arrays is refused", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  writeLines(paste0('{"uci":"1.0","mode":"1-mode","nrows":2,"ncols":2,',
                    '"relations":[{"name":"r","layout":"edgelist",',
                    '"i":[1,2],"j":[1],"values":[1,1]}]}'), f)
  expect_error(xreaduci(f), "the three must match")
})

test_that("a sparse payload indexing outside the matrix is refused", {
  skip_if_no_jsonlite()
  f <- tmpuci(); on.exit(unlink(f), add = TRUE)
  writeLines(paste0('{"uci":"1.0","mode":"1-mode","nrows":2,"ncols":2,',
                    '"relations":[{"name":"r","layout":"edgelist",',
                    '"i":[9],"j":[1],"values":[1]}]}'), f)
  expect_error(xreaduci(f), "outside the declared")
})
