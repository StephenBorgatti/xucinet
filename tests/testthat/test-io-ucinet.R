# Fixtures in inst/goldens/ucinet are real UCINET files, one per header version,
# so each version is tested against bytes UCINET wrote rather than bytes we wrote.
# The two exceptions, 4010 and 6405, are written by us and named to say so; see
# that folder's README. inst/reference/delphi/README.md describes the layouts.
uci <- function(name) system.file("goldens", "ucinet", name, package = "xucinet")
tmpstem <- function() {
  f <- file.path(tempdir(), paste0("ucitest", sample.int(1e6, 1)))
  unlink(paste0(f, c(".##h", ".##d")))
  f
}

# ---- version detection ------------------------------------------------------

test_that("each fixture reports the header version it was written in", {
  expected <- c(campnet = 6404, davis = 6404, supremecourt = 6404,
                `hightech-v4020` = 4020, `davis-v5000` = 5000,
                `davis-byte-v5000` = 5000, `sampson-v6000` = 6000,
                `campnet-v4010-selfwritten` = 4010,
                `campnet-v6405-selfwritten` = 6405)
  for (nm in names(expected)) {
    h <- ucinet_header(uci(paste0(nm, ".##h")))
    expect_equal(h$version, expected[[nm]], info = nm)
  }
})

test_that("there is a fixture for all six header versions and each one reads", {
  fixtures <- list.files(system.file("goldens", "ucinet", package = "xucinet"),
                         pattern = "\\.##h$", full.names = TRUE)
  versions <- vapply(fixtures, function(f) ucinet_header(f)$version, numeric(1))
  expect_setequal(unique(versions), c(4010, 4020, 5000, 6000, 6404, 6405))
  for (f in fixtures) expect_s3_class(xreaducinet(f), "xucinet")
})

# ---- version 4020: fixed 20-byte labels -------------------------------------

test_that("version 4020 reads: fixed-length labels, three relations", {
  net <- xreaducinet(uci("hightech-v4020.##h"))
  expect_equal(dim(net), c(21, 21, 3))
  expect_equal(xrelations(net), c("ADVICE", "FRIENDSHIP", "REPORTS_TO"))
  # haslab is 001 here: only the matrix labels are stored, so nodes fall back
  # to UCINET's 1..n.
  expect_equal(rownames(as.matrix(net))[1:3], c("1", "2", "3"))
  expect_true(all(as.matrix(net) %in% c(0, 1)))
})

# ---- version 5000: variable-length 8-bit labels ------------------------------

test_that("version 5000 reads: variable-length labels, 2 dimensions", {
  net <- xreaducinet(uci("davis-v5000.##h"))
  h <- ucinet_header(uci("davis-v5000.##h"))
  expect_equal(h$ndim, 2)          # no level dimension at all
  expect_equal(dim(net), c(18, 14))
  expect_equal(net$mode, "2-mode")
  expect_equal(rownames(as.matrix(net))[1:3], c("EVELYN", "LAURA", "THERESA"))
  expect_equal(colnames(as.matrix(net))[1:2], c("E1", "E2"))
  # Davis's southern women make 89 event attendances between them.
  expect_equal(sum(as.matrix(net)), 89)
})

test_that("version 5000 reads a byte-valued data file", {
  h <- ucinet_header(uci("davis-byte-v5000.##h"))
  expect_equal(h$dtname, "byte")
  net <- xreaducinet(uci("davis-byte-v5000.##h"))
  expect_equal(sum(as.matrix(net)), 89)
})

# ---- version 6000: variable-length UTF-16 labels -----------------------------

test_that("version 6000 reads: unicode labels, ten relations", {
  net <- xreaducinet(uci("sampson-v6000.##h"))
  expect_equal(dim(net), c(18, 18, 10))
  expect_equal(xrelations(net),
               c("SAMPLK1", "SAMPLK2", "SAMPLK3", "SAMPDLK", "SAMPES",
                 "SAMPDES", "SAMPIN", "SAMPNIN", "SAMPPR", "SAMPNPR"))
  expect_equal(rownames(as.matrix(net))[1:2], c("ROMUALD", "BONAVENTURE"))
})

# ---- version 6404: what every dataset in the book uses -----------------------

test_that("version 6404 reads a 1-mode network", {
  net <- xreaducinet(uci("campnet.##h"))
  expect_equal(dim(net), c(18, 18))
  expect_equal(net$mode, "1-mode")
  expect_true(net$directed)
  expect_equal(rownames(as.matrix(net))[1:2], c("HOLLY", "BRAZEY"))
  expect_equal(as.matrix(net)["HOLLY", "PAM"], 1)
  expect_equal(as.matrix(net)["PAM", "HOLLY"], 0)
})

test_that("version 6404 reads a 2-mode network, rows and columns the right way round", {
  net <- xreaducinet(uci("davis.##h"))
  expect_equal(dim(net), c(18, 14))   # 18 women, 14 events - not 14 x 18
  expect_equal(net$mode, "2-mode")
  expect_equal(sum(as.matrix(net)), 89)
})

test_that("the title falls back to the file stem without the ##h", {
  expect_equal(xreaducinet(uci("campnet.##h"))$title, "campnet")
})

# ---- versions 4010 and 6405 --------------------------------------------------

# No 4010 or 6405 file exists in the book's battery, so these go through our own
# writer. That checks the layout is self-consistent, not that UCINET agrees.
test_that("version 4010 round trips (no UCINET-written specimen available)", {
  net <- xreaducinet(uci("campnet.##h"))
  f <- tmpstem()
  xsaveucinet(net, f, version = 4010)
  back <- xreaducinet(f)
  expect_equal(ucinet_header(paste0(f, ".##h"))$version, 4010)
  expect_equal(unname(as.matrix(back)), unname(as.matrix(net)))
  # 4010 labels are one length byte plus nine characters, so they truncate.
  expect_equal(rownames(as.matrix(back))[1], "HOLLY")
})

test_that("version 6405 round trips and always writes istable as 0", {
  net <- xreaducinet(uci("campnet.##h"))
  f <- tmpstem()
  xsaveucinet(net, f, version = 6405)
  h <- ucinet_header(paste0(f, ".##h"))
  expect_equal(h$version, 6405)
  expect_false(h$istable)          # 0 everywhere, per Steve 2026-09-03
  expect_identical(as.matrix(xreaducinet(f)), as.matrix(net))
  # and the byte really is the last one in the file, not padding
  size <- file.info(paste0(f, ".##h"))$size
  con <- file(paste0(f, ".##h"), "rb"); on.exit(close(con))
  seek(con, size - 1)
  expect_identical(readBin(con, "raw", 1), as.raw(0))
})

test_that("the 6405 istable byte is still read back from a file that sets it", {
  # The reader must not assume 0: UCINET can write 1, so flip the last byte of a
  # 6405 header and check it comes back.
  net <- xreaducinet(uci("campnet.##h"))
  f <- tmpstem()
  xsaveucinet(net, f, version = 6405)
  h <- paste0(f, ".##h")
  b <- readBin(h, "raw", file.info(h)$size)
  b[length(b)] <- as.raw(1)
  writeBin(b, h)
  expect_true(ucinet_header(h)$istable)
  expect_identical(as.matrix(xreaducinet(f)), as.matrix(net))
})

# ---- missing values ---------------------------------------------------------

test_that("UCINET's missing values become NA", {
  net <- xreaducinet(uci("supremecourt.##h"))
  m <- as.matrix(net)
  expect_equal(dim(net), c(376, 9))
  expect_equal(sum(is.na(m)), 9)
  expect_true(is.na(m["E057_Her96", 2]))
  expect_equal(sort(unique(m[!is.na(m)])), c(0, 0.5, 1))
})

test_that("NA is written as 1e38 and read back as NA", {
  m <- matrix(c(0, 1, NA, 1, 0, 1, NA, 1, 0), 3, 3)
  f <- tmpstem()
  xsaveucinet(m, f)
  expect_identical(unname(as.matrix(xreaducinet(f))), m)
  # the bytes really do hold 1e38, not something R invented
  con <- file(paste0(f, ".##d"), "rb"); on.exit(close(con))
  raw <- readBin(con, "double", 9, size = 4)
  expect_equal(raw[3], 1e38, tolerance = 1e-6)
})

test_that("the missing test is >= 1e37, exactly as UCINET's isna is", {
  # A single holding 1e37 is 9.99999993e36, below the threshold, so UCINET does
  # not call it missing either. Reproduce that rather than round it up.
  f <- tmpstem()
  xsaveucinet(matrix(c(1e37, 1e38, 0, 1), 2, 2), f)
  m <- as.matrix(xreaducinet(f))
  expect_false(is.na(m[1, 1]))
  expect_true(is.na(m[2, 1]))
})

# ---- round trips ------------------------------------------------------------

test_that("every fixture survives a write and re-read unchanged", {
  for (nm in c("campnet", "davis", "supremecourt", "hightech-v4020",
               "davis-v5000", "davis-byte-v5000", "sampson-v6000",
               "campnet-v4010-selfwritten", "campnet-v6405-selfwritten")) {
    net <- xreaducinet(uci(paste0(nm, ".##h")))
    f <- tmpstem()
    xsaveucinet(net, f)
    back <- xreaducinet(f)
    expect_equal(xnrelations(back), xnrelations(net), info = nm)
    expect_equal(xrelations(back), xrelations(net), info = nm)
    for (k in seq_len(xnrelations(net))) {
      expect_identical(as.matrix(back, relation = k),
                       as.matrix(net, relation = k), info = paste(nm, k))
    }
  }
})

test_that("a dataset round trips through every header version", {
  net <- xreaducinet(uci("sampson-v6000.##h"))
  for (v in c(4010, 4020, 5000, 6000, 6404, 6405)) {
    f <- tmpstem()
    xsaveucinet(net, f, version = v)
    back <- xreaducinet(f)
    expect_equal(ucinet_header(paste0(f, ".##h"))$version, v, info = v)
    expect_equal(unname(as.matrix(back)), unname(as.matrix(net)), info = v)
    expect_equal(xnrelations(back), 10, info = v)
  }
})

test_that("the double datatype keeps precision a single would lose", {
  m <- matrix(c(1/3, 2/7, 1e-9, 123456.789), 2, 2)
  f <- tmpstem()
  xsaveucinet(m, f, datatype = "double")
  expect_equal(unname(as.matrix(xreaducinet(f))), m, tolerance = 1e-15)
  xsaveucinet(m, f, datatype = "single")
  expect_false(isTRUE(all.equal(unname(as.matrix(xreaducinet(f))), m,
                                tolerance = 1e-12)))
})

# ---- cross-version agreement -------------------------------------------------

test_that("the same dataset reads identically from different header versions", {
  a <- as.matrix(xreaducinet(uci("davis-v5000.##h")))       # 5000, single
  b <- as.matrix(xreaducinet(uci("davis-byte-v5000.##h")))  # 5000, byte
  d <- as.matrix(xreaducinet(uci("davis.##h")))             # 6404, single
  expect_equal(unname(a), unname(d))
  expect_equal(unname(b), unname(d))
})

# ---- wiring into xread / xsave ----------------------------------------------

test_that("xread() and as_xucinet() dispatch to the UCINET reader", {
  expect_equal(dim(xread(uci("campnet.##h"))), c(18, 18))
  expect_equal(dim(as_xucinet(uci("campnet.##h"))), c(18, 18))
  expect_equal(dim(xread(uci("campnet.##h"), filetype = "ucinet")), c(18, 18))
})

test_that("xread() accepts the stem or the .##d half of the pair", {
  stem <- sub("\\.##h$", "", uci("campnet.##h"))
  expect_equal(dim(xreaducinet(stem)), c(18, 18))
  expect_equal(dim(xreaducinet(paste0(stem, ".##d"))), c(18, 18))
})

test_that("xsave(filetype = 'ucinet') writes a readable pair", {
  net <- xreaducinet(uci("campnet.##h"))
  f <- paste0(tmpstem(), ".##h")
  xsave(net, f, filetype = "ucinet")
  expect_true(file.exists(f))
  expect_true(file.exists(sub("\\.##h$", ".##d", f)))
  expect_identical(as.matrix(xread(f)), as.matrix(net))
})

# ---- errors that teach ------------------------------------------------------

test_that("a header with no data file beside it is refused clearly", {
  f <- tmpstem()
  file.copy(uci("campnet.##h"), paste0(f, ".##h"))
  expect_error(xreaducinet(f), "no matching .##d", fixed = TRUE)
})

test_that("a header and data file that disagree are refused", {
  net <- xreaducinet(uci("campnet.##h"))
  f <- tmpstem()
  xsaveucinet(net, f)
  # truncate the data file: the header now describes more than is there
  d <- paste0(f, ".##d")
  writeBin(readBin(d, "raw", 100), d)
  expect_error(xreaducinet(f), "do not belong together")
})

test_that("a missing file and a bad version are refused", {
  expect_error(xreaducinet(file.path(tempdir(), "nope")), "No UCINET header")
  expect_error(xsaveucinet(matrix(0, 2, 2), tmpstem(), version = 9999),
               "version must be one of")
})

test_that("an unreadable datatype names itself and asks for the file", {
  net <- xreaducinet(uci("campnet.##h"))
  f <- tmpstem()
  xsaveucinet(net, f)
  # rewrite the datatype byte as extended (ordinal 11), which we do not decode
  h <- paste0(f, ".##h")
  b <- readBin(h, "raw", file.info(h)$size)
  b[17] <- as.raw(11)             # 6 magic + 10 date record, then dt
  writeBin(b, h)
  expect_error(xreaducinet(f), "extended")
  expect_error(xreaducinet(f), "send the file")
})
