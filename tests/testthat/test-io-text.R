# DL and VNA, and the layout detection that lets csv and xlsx files be read
# without being told what shape they are in (issue #5).

dlfile <- function(...) {
  p <- tempfile(fileext = ".dl")
  writeLines(c(...), p)
  p
}
full3 <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)

# ---- DL: the format families ------------------------------------------------

test_that("DL fullmatrix reads, with and without labels", {
  p <- dlfile("DL N=3", "FORMAT = FULLMATRIX", "LABELS:", "a,b,c",
              "DATA:", "0 1 1", "1 0 0", "1 0 0")
  net <- xreaddl(p)
  expect_equal(unname(as.matrix(net)), full3)
  expect_equal(rownames(as.matrix(net)), c("a", "b", "c"))
  # no LABELS block: UCINET's 1..n
  bare <- xreaddl(dlfile("DL N=3", "DATA:", "0 1 1", "1 0 0", "1 0 0"))
  expect_equal(unname(as.matrix(bare)), full3)
  expect_equal(rownames(as.matrix(bare)), c("1", "2", "3"))
})

test_that("DL keywords are matched by prefix and ignore case", {
  # udlreader.pas matches on a prefix, so NROW, NI and NR are the same key, as
  # are NL, NM, NMAT, NREL and NRESP.
  a <- xreaddl(dlfile("dl nrow=3, ncol=3", "format = fullmatrix",
                      "data:", "0 1 1", "1 0 0", "1 0 0"))
  expect_equal(unname(as.matrix(a)), full3)
  b <- xreaddl(dlfile("DL N=3, NREL=2", "DATA:", "0 1 1", "1 0 0", "1 0 0",
                      "0 0 1", "0 0 0", "1 0 0"))
  expect_equal(xnrelations(b), 2)
})

test_that("DL rectangular data is 2-mode", {
  net <- xreaddl(dlfile("DL NR=2, NC=3", "FORMAT=FULLMATRIX", "DATA:", "1 0 1", "0 1 0"))
  expect_equal(dim(net), c(2, 3))
  expect_equal(net$mode, "2-mode")
})

test_that("DL NM stacks matrices and names them", {
  net <- xreaddl(dlfile("DL N=3, NM=2", "FORMAT=FULLMATRIX", "MATRIX LABELS:",
                        "one,two", "DATA:", "0 1 1", "1 0 0", "1 0 0",
                        "0 0 1", "0 0 0", "1 0 0"))
  expect_equal(xnrelations(net), 2)
  expect_equal(xrelations(net), c("one", "two"))
  expect_equal(unname(as.matrix(net, relation = "one")), full3)
})

test_that("DIAGONAL ABSENT leaves the diagonal out of the data", {
  net <- xreaddl(dlfile("DL N=3", "FORMAT=FULLMATRIX", "DIAGONAL ABSENT",
                        "DATA:", "1 1", "1 0", "1 0"))
  expect_equal(unname(as.matrix(net)), full3)
})

test_that("DL edgelist1 reads by number and by label", {
  bynum <- xreaddl(dlfile("DL N=3", "FORMAT=EDGELIST1", "DATA:",
                          "1 2 1", "1 3 1", "2 1 1", "3 1 1"))
  expect_equal(unname(as.matrix(bynum)), full3)
  bylab <- xreaddl(dlfile("DL N=3", "FORMAT=EDGELIST1", "LABELS:", "a,b,c",
                          "DATA:", "a b 1", "a c 1", "b a 1", "c a 1"))
  expect_equal(unname(as.matrix(bylab)), full3)
  expect_equal(rownames(as.matrix(bylab)), c("a", "b", "c"))
})

test_that("DL nodelist1 reads ego then alters", {
  net <- xreaddl(dlfile("DL N=3", "FORMAT=NODELIST1", "LABELS:", "a,b,c",
                        "DATA:", "a b c", "b a", "c a"))
  expect_equal(unname(as.matrix(net)), full3)
})

test_that("the 2-mode variants index two different node sets", {
  el <- xreaddl(dlfile("DL NR=2, NC=3", "FORMAT=EDGELIST2", "ROW LABELS:", "r1,r2",
                       "COLUMN LABELS:", "c1,c2,c3", "DATA:", "1 1 1", "2 3 1"))
  expect_equal(dim(el), c(2, 3))
  expect_equal(el$mode, "2-mode")
  expect_equal(as.matrix(el)["r1", "c1"], 1)
  nl <- xreaddl(dlfile("DL NR=2, NC=3", "FORMAT=NODELIST2", "ROW LABELS:", "r1,r2",
                       "COLUMN LABELS:", "c1,c2,c3", "DATA:", "r1 c1 c2", "r2 c3"))
  expect_equal(dim(nl), c(2, 3))
  expect_equal(sum(as.matrix(nl)), 3)
})

test_that("DL half matrices are mirrored into a full one", {
  sym <- matrix(c(0,1,1, 1,0,1, 1,1,0), 3, 3)
  lower <- xreaddl(dlfile("DL N=3", "FORMAT=LOWERHALF", "DIAGONAL ABSENT",
                          "DATA:", "1", "1 1"))
  expect_equal(unname(as.matrix(lower)), sym)
})

# ---- DL: round trips and errors ---------------------------------------------

test_that("DL round trips 1-mode, 2-mode and a stack", {
  for (nm in c("campnet", "davis", "hightech")) {
    net <- get(nm)
    p <- tempfile(fileext = ".dl"); on.exit(unlink(p), add = TRUE)
    xsavedl(net, p)
    back <- xreaddl(p)
    expect_equal(unname(as.matrix(back)), unname(as.matrix(net)), info = nm)
    expect_equal(xnrelations(back), xnrelations(net), info = nm)
  }
})

test_that("DL can be written as an edge list and read back", {
  p <- tempfile(fileext = ".dl"); on.exit(unlink(p), add = TRUE)
  xsavedl(campnet, p, format = "edgelist1")
  expect_true(any(grepl("EDGELIST1", readLines(p))))
  expect_equal(unname(as.matrix(xreaddl(p))), unname(as.matrix(campnet)))
})

test_that("bad DL files are refused with the reason", {
  expect_error(xreaddl(dlfile("hello", "world")), "does not start with DL")
  expect_error(xreaddl(dlfile("DL N=3", "FORMAT=TRIANGLE", "DATA:", "0")),
               "does not read")
  expect_error(xreaddl(dlfile("DL N=3", "DATA:", "0 1")), "not 9")
  expect_error(xreaddl(dlfile("DL N=3", "LABELS:", "a,b,c")), "no DATA")
})

# ---- VNA --------------------------------------------------------------------

vnafile <- function(...) {
  p <- tempfile(fileext = ".vna")
  writeLines(c(...), p)
  p
}

test_that("VNA reads nodes, ties and attributes", {
  p <- vnafile('*Node data', 'ID gender', '"a" 1', '"b" 2', '"c" 1',
               '*Tie data', 'from to strength', '"a" "b" 2', '"b" "c" 3')
  net <- xreadvna(p)
  expect_equal(dim(net), c(3, 3))
  expect_equal(as.matrix(net)["a", "b"], 2)
  expect_equal(xrelations(net), "strength")
  expect_equal(xattributes(net)$gender, c(1, 2, 1))
  expect_identical(rownames(xattributes(net)), c("a", "b", "c"))
})

test_that("VNA keeps isolates, which an edge list would lose", {
  p <- vnafile('*Node data', 'ID', '"a"', '"b"', '"c"', '"d"',
               '*Tie data', 'from to v', '"a" "b" 1')
  net <- xreadvna(p)
  expect_equal(dim(net), c(4, 4))
  expect_equal(rownames(as.matrix(net)), c("a", "b", "c", "d"))
})

test_that("VNA carries one relation per tie column", {
  p <- vnafile('*Node data', 'ID', '"a"', '"b"',
               '*Tie data', 'from to advice friendship', '"a" "b" 1 5')
  net <- xreadvna(p)
  expect_equal(xrelations(net), c("advice", "friendship"))
  expect_equal(as.matrix(net, relation = "friendship")["a", "b"], 5)
})

test_that("VNA separators are decided per line, not per file", {
  # A file in the wild writes a whitespace header over comma-separated rows.
  p <- vnafile('*Node data', '"ID", "grp"', '"a","1"', '"b","2"',
               '*Tie data', 'FROM TO w', '"a","b",7')
  net <- xreadvna(p)
  expect_equal(as.matrix(net)["a", "b"], 7)
  expect_equal(names(xattributes(net)), "grp")
})

test_that("VNA round trips a stack and its isolates", {
  p <- tempfile(fileext = ".vna"); on.exit(unlink(p), add = TRUE)
  xsavevna(hightech, p)
  back <- xreadvna(p)
  expect_equal(xrelations(back), xrelations(hightech))
  expect_equal(unname(as.matrix(back, relation = "Advice")),
               unname(as.matrix(hightech, relation = "Advice")))
})

test_that("an E-Net egocentric VNA is refused by name, not misread", {
  p <- vnafile("*ego data", "ID", "1", "*alter data", "ID", "2")
  expect_error(xreadvna(p), "E-Net")
})

# ---- layout detection -------------------------------------------------------

csvfile <- function(...) {
  p <- tempfile(fileext = ".csv")
  writeLines(c(...), p)
  p
}

test_that("a labelled matrix is detected", {
  p <- csvfile("ID,a,b,c", "a,0,1,1", "b,1,0,0", "c,1,0,0")
  expect_equal(detect_layout_grid(read_delim_raw(p)), "matrix")
  expect_equal(unname(as.matrix(xread(p))), full3)
})

test_that("an empty first header cell still means a header", {
  p <- csvfile('"","a","b"', '"a",0,1', '"b",1,0')
  expect_true(detect_header(read_delim_raw(p)))
  expect_equal(dim(xread(p)), c(2, 2))
})

test_that("an edge list with a header is detected", {
  p <- csvfile("from,to,discuss", "1,2,1", "1,3,1", "2,3,1")
  expect_equal(detect_layout_grid(read_delim_raw(p)), "edgelist")
  expect_equal(dim(xread(p)), c(3, 3))
})

test_that("a headerless ragged node list is detected", {
  p <- csvfile("10,171,229,,", "100,211,24,302,50", "109,129,,,")
  g <- read_delim_raw(p)
  expect_false(detect_header(g))
  expect_equal(detect_layout_grid(g), "nodelist")
})

test_that("an attribute table is a matrix, not an edge list", {
  # Three columns of numbers under unique row labels: the shape of an edge list
  # but none of its repetition.
  p <- csvfile("ID,Gender,Role,Betweenness", "HOLLY,1,1,78.3", "BRAZEY,1,1,0",
               "CAROL,2,1,4.5")
  expect_equal(detect_layout_grid(read_delim_raw(p)), "matrix")
})

test_that("a missing value does not make a matrix look ragged", {
  # An empty cell with data after it is a missing value; only trailing blanks
  # mean a node list. This cost the country-attribute files their layout.
  p <- csvfile("ID,a,b,c", "x,1,,3", "y,4,5,6")
  g <- read_delim_raw(p)
  expect_false(is_ragged(g[-1, , drop = FALSE]))
  expect_equal(detect_layout_grid(g), "matrix")
  expect_true(is.na(as.matrix(xread(p))["x", "b"]))
})

test_that("a categorical attribute column is coded, and says so", {
  p <- csvfile("ID,GENDER,AGE", "A01,male,15", "A02,female,10")
  expect_equal(detect_layout_grid(read_delim_raw(p)), "matrix")
  expect_message(xread(p), "categorical")
  m <- suppressMessages(as.matrix(xread(p)))
  expect_equal(unname(m[, 1]), c(2, 1))   # female=1, male=2, sorted
})

test_that("an edge list carrying two relations gives two relations", {
  p <- csvfile("FROM,TO,PADGM,PADGB", "a,b,1,0", "a,c,1,1", "b,c,0,1")
  expect_equal(detect_layout_grid(read_delim_raw(p)), "edgelist")
  net <- xread(p)
  expect_equal(xrelations(net), c("PADGM", "PADGB"))
  expect_equal(as.matrix(net, relation = "PADGB")["a", "c"], 1)
})

test_that("an edge list whose third column names the relation splits on it", {
  # from, to, relation-name. Coercing that column to numbers would make every
  # cell NA.
  p <- csvfile("a,b,PADGM", "a,c,PADGM", "b,c,PADGB")
  net <- xread(p)
  expect_equal(xrelations(net), c("PADGM", "PADGB"))
  expect_equal(as.matrix(net, relation = "PADGM")["a", "b"], 1)
  expect_equal(as.matrix(net, relation = "PADGB")["b", "c"], 1)
})

test_that("a byte order mark does not become part of the first label", {
  p <- tempfile(fileext = ".csv")
  writeLines(c("﻿ID,a,b", "a,0,1", "b,1,0"), p, useBytes = TRUE)
  expect_equal(rownames(as.matrix(xread(p)))[1], "a")
})

test_that("layout= overrides detection", {
  p <- csvfile("ID,a,b,c", "a,0,1,1", "b,1,0,0", "c,1,0,0")
  expect_equal(dim(xread(p, layout = "matrix")), c(3, 3))
})
