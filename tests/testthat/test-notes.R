# Dated notes on a dataset (SPEC D1, D6; issue #35): the xnotes() accessor, the
# object keeping them, and the .uci round trip.

m3 <- matrix(c(0, 1, 1, 1, 0, 0, 1, 0, 0), 3, 3,
             dimnames = list(c("a", "b", "c"), c("a", "b", "c")))
two <- data.frame(date = c("2026-10-01", "2026-10-02"),
                  text = c("Coded from field notes.", "Tie b-c corrected."))

test_that("a network without notes has no notes element", {
  net <- as_xucinet(m3)
  expect_null(xnotes(net))
  expect_false("notes" %in% names(net))
  expect_null(xnotes(campnet))
})

test_that("xnotes<- sets, replaces and removes them", {
  net <- as_xucinet(m3)
  xnotes(net) <- two
  expect_identical(xnotes(net), two)
  xnotes(net) <- NULL
  expect_null(xnotes(net))
  expect_false("notes" %in% names(net))
  # a character vector is dated today
  xnotes(net) <- "One note."
  expect_equal(xnotes(net)$date, format(Sys.Date()))
  expect_equal(xnotes(net)$text, "One note.")
})

test_that("bad notes are refused with a message", {
  net <- as_xucinet(m3)
  expect_error(xnotes(net) <- data.frame(when = "2026-10-02", text = "x"),
               "columns date and text")
  expect_error(xnotes(net) <- data.frame(date = "2 Oct 2026", text = "x"),
               "YYYY-MM-DD")
})

test_that("print shows how many notes there are", {
  net <- as_xucinet(m3)
  expect_false(any(grepl("^Notes:", capture.output(print(net)))))
  xnotes(net) <- two
  expect_true("Notes: 2 (see xnotes(x))" %in% capture.output(print(net)))
})

test_that("subsetting, coercion and the transformations keep the notes", {
  net <- as_xucinet(m3)
  xnotes(net) <- two
  expect_identical(xnotes(net[c("a", "b")]), two)
  expect_identical(xnotes(as_xucinet(net, title = "renamed")), two)
  expect_identical(xnotes(xtranspose(net)), two)
  expect_identical(xnotes(xdichotomize(net)), two)
  expect_identical(xnotes(xsymmetrize(net)), two)
  expect_identical(xnotes(xrecode(net, from = 1, to = 2)), two)

  stack <- as_xucinet(list(liking = m3, advice = t(m3)))
  xnotes(stack) <- two
  expect_identical(xnotes(xunpack(stack, "advice")), two)
  expect_identical(xnotes(xcombine(stack)), two)
  expect_identical(xnotes(xmultiplex(stack)), two)
})

test_that("notes round trip through .uci, in order", {
  skip_if_not_installed("jsonlite")
  net <- as_xucinet(m3)
  xnotes(net) <- two
  f <- file.path(tempdir(), "notes-roundtrip.uci"); on.exit(unlink(f))
  xsaveuci(net, f)
  doc <- jsonlite::fromJSON(f, simplifyVector = FALSE)
  expect_equal(doc$uci, "1.1")
  expect_equal(doc$notes[[1]], list(date = "2026-10-01", text = "Coded from field notes."))
  expect_identical(xnotes(xreaduci(f)), two)
  # and through xsave(), which writes .uci by default
  xsave(net, f)
  expect_identical(xnotes(xread(f)), two)
})

test_that("a file without notes, and a 1.0 file, read with none", {
  skip_if_not_installed("jsonlite")
  f <- file.path(tempdir(), "notes-none.uci"); on.exit(unlink(f))
  xsaveuci(m3, f)
  expect_false("notes" %in% names(jsonlite::fromJSON(f)))
  expect_null(xnotes(xreaduci(f)))
  writeLines(paste0('{"uci":"1.0","mode":"1-mode","nrows":1,"ncols":1,',
                    '"relations":[{"name":"r","layout":"matrix","values":[[0]]}]}'), f)
  expect_null(xnotes(xreaduci(f)))
})

test_that("the worked example carries a note", {
  skip_if_not_installed("jsonlite")
  net <- xreaduci(system.file("schema", "campnet-example.uci", package = "xucinet"))
  expect_equal(nrow(xnotes(net)), 1)
})

test_that("writing ##h drops the notes without a warning", {
  net <- as_xucinet(m3)
  xnotes(net) <- two
  f <- file.path(tempdir(), "notes-ucinet")
  on.exit(unlink(paste0(f, c(".##h", ".##d"))))
  expect_no_warning(xsaveucinet(net, f))
  back <- xreaducinet(f)
  expect_null(xnotes(back))
  expect_identical(unname(as.matrix(back)), unname(m3))
})

test_that("supremecourt carries the note on its 2026 corrections", {
  n <- xnotes(supremecourt)
  expect_equal(n$date, "2026-10-02")
  expect_match(n$text, "Lewis v. Casey")
})
