m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3, dimnames = list(c("a","b","c"), c("a","b","c")))
d <- matrix(c(0,1,1, 0,0,0, 1,0,0), 3, 3, dimnames = list(c("a","b","c"), c("a","b","c")))
v <- matrix(c(0,3,2, 3,0,0, 2,0,0), 3, 3, dimnames = list(c("a","b","c"), c("a","b","c")))
bi <- matrix(c(1,0, 1,1, 0,1), 2, 3, dimnames = list(c("w1","w2"), c("e1","e2","e3")))

# ---- input: matrices --------------------------------------------------------

test_that("a symmetric matrix becomes an undirected 1-mode network", {
  net <- as_xucinet(m)
  expect_s3_class(net, "xucinet")
  expect_equal(net$mode, "1-mode")
  expect_false(net$directed)
  expect_equal(dim(net), c(3, 3))
})

test_that("an asymmetric matrix is detected as directed", {
  m2 <- m; m2[2, 1] <- 0
  expect_true(as_xucinet(m2)$directed)
})

test_that("a rectangular matrix is 2-mode with undetermined directedness", {
  net <- as_xucinet(matrix(1, 3, 5))
  expect_equal(net$mode, "2-mode")
  expect_true(is.na(net$directed))
})

test_that("unlabeled matrices get labels", {
  expect_equal(rownames(as.matrix(as_xucinet(matrix(0, 2, 2)))), c("1","2"))
})

test_that("integer and logical matrices are stored as doubles", {
  mi <- matrix(0L, 2, 2)
  expect_type(as.matrix(as_xucinet(mi)), "double")
  expect_type(as.matrix(as_xucinet(matrix(FALSE, 2, 2))), "double")
})

test_that("a character matrix is refused with advice about labels", {
  ch <- matrix(c("a","b","c","d"), 2, 2)
  expect_error(as_xucinet(ch), "must hold numbers")
  expect_error(as_xucinet(ch), "xread")
})

test_that("directed, mode and title arguments override detection", {
  net <- as_xucinet(m, directed = TRUE, mode = "2-mode", title = "mine")
  expect_true(net$directed)
  expect_equal(net$mode, "2-mode")
  expect_equal(net$title, "mine")
})

test_that("mode matching is forgiving and case-insensitive", {
  expect_equal(as_xucinet(m, mode = "1")$mode, "1-mode")
  expect_equal(as_xucinet(m, mode = "TwoMode")$mode, "2-mode")
  expect_error(as_xucinet(m, mode = "banana"), "1-mode")
})

# ---- input: data frames -----------------------------------------------------

test_that("an edge list data frame is detected and built", {
  el <- data.frame(from = c("a","a","b"), to = c("b","c","a"))
  net <- as_xucinet(el)
  expect_equal(sort(rownames(as.matrix(net))), c("a","b","c"))
  expect_equal(as.matrix(net)["a","b"], 1)
  expect_equal(as.matrix(net)["c","a"], 0)
})

test_that("an adjacency data frame is read as a matrix", {
  df <- as.data.frame(m)
  net <- as_xucinet(df)
  expect_equal(net$mode, "1-mode")
  expect_equal(unname(as.matrix(net)), unname(m))
})

# ---- input: multi-relation --------------------------------------------------

test_that("a named list of matrices becomes a multi-relation dataset", {
  net <- as_xucinet(list(liking = m, advice = d))
  expect_true(is.list(net$data))
  expect_equal(xrelations(net), c("liking", "advice"))
  expect_equal(xnrelations(net), 2L)
  expect_equal(as.matrix(net, relation = "advice"), d)
  expect_equal(dim(net), c(3, 3, 2))
})

test_that("an unnamed list gets generated lowercase relation names", {
  expect_equal(xrelations(as_xucinet(list(m, d))), c("relation1", "relation2"))
})

test_that("a 3-D array becomes a multi-relation dataset, third dimension is the relation", {
  a <- array(0, c(3, 3, 2), dimnames = list(rownames(m), colnames(m), c("liking","advice")))
  a[, , 1] <- m; a[, , 2] <- d
  net <- as_xucinet(a)
  expect_equal(xrelations(net), c("liking", "advice"))
  expect_equal(as.matrix(net, relation = "liking"), m)
  expect_equal(as.matrix(net, relation = 2), d)
})

test_that("an unnamed 3-D array still labels its nodes and relations", {
  net <- as_xucinet(array(0, c(2, 2, 2)))
  expect_equal(xrelations(net), c("relation1", "relation2"))
  expect_equal(rownames(as.matrix(net)), c("1","2"))
})

test_that("a 4-D array is refused", {
  expect_error(as_xucinet(array(0, c(2,2,2,2))), "3")
})

test_that("relations may be given as xucinet objects", {
  net <- as_xucinet(list(liking = as_xucinet(m), advice = as_xucinet(d)))
  expect_equal(as.matrix(net, relation = "advice"), d)
})

test_that("a stack is directed if any relation is asymmetric", {
  expect_false(as_xucinet(list(a = m, b = m))$directed)
  expect_true(as_xucinet(list(a = m, b = d))$directed)
})

test_that("mismatched relations are refused with a reason", {
  expect_error(as_xucinet(list(m, matrix(0, 2, 2))), "same dimensions")
  other <- m; dimnames(other) <- list(c("x","y","z"), c("x","y","z"))
  expect_error(as_xucinet(list(m, other)), "different row labels")
  expect_error(as_xucinet(list()), "at least one matrix")
  expect_error(as_xucinet(list(m, "nope")), "must be a matrix")
})

test_that("relation names must be unique", {
  expect_error(as_xucinet(list(a = m, a = d)), "unique")
})

# ---- input: passthrough, files, unsupported ---------------------------------

test_that("as_xucinet on an xucinet is idempotent and can retitle", {
  net <- as_xucinet(m, title = "one")
  expect_identical(as_xucinet(net), net)
  expect_equal(as_xucinet(net, title = "two")$title, "two")
})

test_that("a file name is read from disk", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(m, f)
  net <- as_xucinet(f)
  expect_s3_class(net, "xucinet")
  expect_equal(unname(as.matrix(net)), unname(m))
})

test_that("an unsupported object is refused with a list of what is accepted", {
  expect_error(as_xucinet(sum), "Don't know how to")
  expect_error(as_xucinet(sum), "edge list")
})

# ---- input: other packages --------------------------------------------------

test_that("igraph objects are converted, keeping direction, values and labels", {
  skip_if_not_installed("igraph")
  expect_equal(as.matrix(as_xucinet(as_igraph(d))), d)
  expect_true(as_xucinet(as_igraph(d))$directed)
  expect_false(as_xucinet(as_igraph(m))$directed)
  expect_equal(as.matrix(as_xucinet(as_igraph(v))), v)
})

test_that("a bipartite igraph is recognised as 2-mode", {
  skip_if_not_installed("igraph")
  net <- as_xucinet(as_igraph(bi))
  expect_equal(net$mode, "2-mode")
  expect_equal(as.matrix(net), bi)
})

test_that("network objects are converted", {
  skip_if_not_installed("network")
  expect_equal(as.matrix(as_xucinet(as_network(d))), d)
  expect_true(as_xucinet(as_network(d))$directed)
  expect_equal(as.matrix(as_xucinet(as_network(v))), v)
  expect_equal(as_xucinet(as_network(bi))$mode, "2-mode")
})

test_that("tbl_graph objects are converted", {
  skip_if_not_installed("tidygraph")
  net <- as_xucinet(as_tbl_graph(m))
  expect_s3_class(net, "xucinet")
  expect_equal(as.matrix(net), m)
})

# ---- output: exporters ------------------------------------------------------

test_that("matrix -> xucinet -> igraph -> xucinet round trips exactly", {
  skip_if_not_installed("igraph")
  for (x in list(m, d, v, bi)) {
    expect_identical(as.matrix(as_xucinet(as_igraph(as_xucinet(x)))), x)
  }
})

test_that("matrix -> xucinet -> network -> xucinet round trips exactly", {
  skip_if_not_installed("network")
  for (x in list(m, d, v, bi)) {
    expect_equal(as.matrix(as_xucinet(as_network(as_xucinet(x)))), x)
  }
})

test_that("matrix -> xucinet -> tbl_graph -> xucinet round trips exactly", {
  skip_if_not_installed("tidygraph")
  for (x in list(m, d, v)) {
    expect_identical(as.matrix(as_xucinet(as_tbl_graph(as_xucinet(x)))), x)
  }
})

test_that("exporters pick the requested relation", {
  skip_if_not_installed("igraph")
  net <- as_xucinet(list(liking = m, advice = d))
  expect_equal(as.matrix(as_xucinet(as_igraph(net, relation = "advice"))), d)
  expect_equal(as.matrix(as_xucinet(as_igraph(net))), m)
})

test_that("exporting a network with missing ties is refused with advice", {
  skip_if_not_installed("igraph")
  na <- m; na[1, 2] <- NA
  expect_error(as_igraph(na), "missing tie")
  expect_error(as_igraph(na), "is.na")
})

test_that("the ecosystem's own generics understand an xucinet object", {
  skip_if_not_installed("igraph")
  skip_if_not_installed("network")
  skip_if_not_installed("tidygraph")
  net <- as_xucinet(m)
  expect_s3_class(igraph::as.igraph(net), "igraph")
  expect_s3_class(network::as.network(net), "network")
  expect_s3_class(tidygraph::as_tbl_graph(net), "tbl_graph")
})

# ---- relations --------------------------------------------------------------

test_that("a single-relation dataset reports its title as the relation name", {
  net <- as_xucinet(m, title = "campnet")
  expect_equal(xrelations(net), "campnet")
  expect_equal(xnrelations(net), 1L)
})

test_that("length(xrelations()) is always xnrelations()", {
  for (net in list(as_xucinet(m), as_xucinet(list(a = m, b = d)))) {
    expect_equal(length(xrelations(net)), xnrelations(net))
  }
})

test_that("an unknown relation is refused with the list of real ones", {
  net <- as_xucinet(list(liking = m, advice = d))
  expect_error(as.matrix(net, relation = "hostility"), "liking, advice")
  expect_error(as.matrix(net, relation = 5), "out of range")
  expect_error(as.matrix(as_xucinet(m, title = "one"), relation = "nope"),
               "one relation")
})

test_that("a single-relation dataset still accepts relation = 1 or its title", {
  net <- as_xucinet(m, title = "campnet")
  expect_equal(as.matrix(net, relation = 1), m)
  expect_equal(as.matrix(net, relation = "campnet"), m)
})

# ---- subsetting -------------------------------------------------------------

test_that("subsetting by label keeps the same nodes on both margins", {
  net <- as_xucinet(m)[c("a", "b")]
  expect_s3_class(net, "xucinet")
  expect_equal(dim(net), c(2, 2))
  expect_equal(rownames(as.matrix(net)), c("a", "b"))
  expect_equal(colnames(as.matrix(net)), c("a", "b"))
})

test_that("subsetting keeps mode, directedness and title", {
  net <- as_xucinet(d, title = "keepme")[1:2]
  expect_equal(net$mode, "1-mode")
  expect_true(net$directed)
  expect_equal(net$title, "keepme")
  expect_false(as_xucinet(m)[1:2]$directed)
})

test_that("positions, negative positions and logicals all work", {
  net <- as_xucinet(m)
  expect_equal(rownames(as.matrix(net[2:3])), c("b", "c"))
  expect_equal(rownames(as.matrix(net[-1])), c("b", "c"))
  expect_equal(rownames(as.matrix(net[c(FALSE, TRUE, TRUE)])), c("b", "c"))
})

test_that("row and column selections can differ", {
  net <- as_xucinet(m)[1:2, 3]
  expect_equal(dim(net), c(2, 1))
  expect_equal(net$mode, "2-mode")
})

test_that("2-mode data subsets rows and columns independently", {
  net <- as_xucinet(bi)
  expect_equal(dim(net["w1"]), c(1, 3))
  expect_equal(dim(net["w1", c("e1", "e2")]), c(1, 2))
  expect_equal(net["w1"]$mode, "2-mode")
})

test_that("subsetting a stack subsets every relation", {
  net <- as_xucinet(list(liking = m, advice = d))[c("a", "b")]
  expect_equal(xrelations(net), c("liking", "advice"))
  expect_equal(dim(net), c(2, 2, 2))
  expect_equal(as.matrix(net, relation = "advice"), d[1:2, 1:2])
})

test_that("drop = TRUE gives back the plain matrix", {
  expect_true(is.matrix(as_xucinet(m)[1:2, drop = TRUE]))
  dropped <- as_xucinet(list(liking = m, advice = d))[1:2, drop = TRUE]
  expect_type(dropped, "list")
  expect_equal(names(dropped), c("liking", "advice"))
})

test_that("bad subscripts are refused with a reason", {
  net <- as_xucinet(m)
  expect_error(net["zz"], "unknown row label")
  expect_error(net["zz"], "Available: a, b, c")
  expect_error(net[1:9], "out of bounds")
  expect_error(net[c(TRUE, FALSE)], "one entry per row")
  expect_error(net[c(-1, 2)], "cannot mix")
})

# ---- printing ---------------------------------------------------------------

test_that("printing reports shape and lists relations", {
  expect_output(print(as_xucinet(m)), "3 rows, 3 columns, 1 relation")
  expect_output(print(as_xucinet(m)), "undirected")
  out <- capture.output(print(as_xucinet(list(liking = m, advice = d))))
  expect_true(any(grepl("Relations: liking, advice", out)))
  expect_true(any(grepl("^liking$", out)))
})
