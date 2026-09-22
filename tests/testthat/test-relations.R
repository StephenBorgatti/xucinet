# Building, splitting and collapsing multi-relation datasets
# (chapter 5, sections 5.4.6 and 5.9).

tol <- 1e-6

wide <- function() matrix(1, 3, 2, dimnames = list(c("x","y","z"), c("p","q")))
narrow <- function() matrix(2, 3, 1, dimnames = list(c("x","y","z"), "r"))

# Three relations on three nodes, with a different pattern in each.
stack3 <- function() {
  n <- c("a", "b", "c")
  as_xucinet(list(
    one   = matrix(c(0,1,0, 0,0,0, 0,0,0), 3, 3, byrow = TRUE, dimnames = list(n, n)),
    two   = matrix(c(0,1,1, 0,0,0, 0,0,0), 3, 3, byrow = TRUE, dimnames = list(n, n)),
    three = matrix(c(0,0,1, 0,0,0, 0,0,0), 3, 3, byrow = TRUE, dimnames = list(n, n))
  ))
}

# ---- xjoin ------------------------------------------------------------------

test_that("col is the default and appends columns", {
  out <- as.matrix(xjoin(wide(), narrow()))
  expect_equal(dim(out), c(3, 3))
  expect_equal(colnames(out), c("p", "q", "r"))
  expect_equal(unname(out[, "r"]), c(2, 2, 2))
})

test_that("row appends rows", {
  top <- matrix(1, 2, 2, dimnames = list(c("x","y"), c("p","q")))
  bot <- matrix(3, 1, 2, dimnames = list("z", c("p","q")))
  out <- as.matrix(xjoin(top, bot, mode = "row"))
  expect_equal(dim(out), c(3, 2))
  expect_equal(unname(out["z", ]), c(3, 3))
})

test_that("mat stacks the datasets as relations", {
  j <- xjoin(advice = campnet, friends = campnet, mode = "mat")
  expect_equal(xrelations(j), c("advice", "friends"))
  expect_equal(xnrelations(j), 2L)
  expect_equal(as.matrix(j, relation = "advice"), as.matrix(campnet))
})

test_that("relation names come from the arguments, the titles, or names", {
  expect_equal(xrelations(xjoin(campnet, campnet, mode = "mat")),
               c("campnet", "campnet.1"))
  expect_equal(xrelations(xjoin(campnet, campnet, mode = "mat",
                                names = c("t1", "t2"))),
               c("t1", "t2"))
})

test_that("the title records what went in", {
  expect_equal(xjoin(wide(), narrow())$title, "wide()+narrow()")
  expect_equal(xjoin(early = campnet, late = campnet, mode = "mat")$title,
               "early+late")
})

test_that("mismatched shapes are an error that points at xmatch", {
  small <- matrix(1, 2, 2, dimnames = list(c("x","y"), c("x","y")))
  expect_error(xjoin(campnet, small, mode = "mat"), "xmatch")
  expect_error(xjoin(wide(), small, mode = "col"), "xmatch")
})

test_that("mismatched labels are an error even when the shape fits", {
  a <- matrix(1, 2, 2, dimnames = list(c("x","y"), c("x","y")))
  b <- matrix(1, 2, 2, dimnames = list(c("p","q"), c("p","q")))
  expect_error(xjoin(a, b, mode = "mat"), "same node labels")
})

test_that("a list of datasets works as well as several arguments", {
  j <- xjoin(list(one = campnet, two = campnet), mode = "mat")
  expect_equal(xrelations(j), c("one", "two"))
})

test_that("one dataset is not a join", {
  expect_error(xjoin(campnet), "two or more")
})

# ---- xunpack ----------------------------------------------------------------

test_that("xunpack returns one dataset per relation, named and titled", {
  parts <- xunpack(hightech)
  expect_equal(names(parts), xrelations(hightech))
  expect_equal(parts[["Advice"]]$title, "Advice")
  expect_equal(as.matrix(parts[["Advice"]]),
               as.matrix(hightech, relation = "Advice"))
  expect_equal(xnrelations(parts[["Advice"]]), 1L)
})

test_that("a single relation can be asked for by name or position", {
  expect_equal(as.matrix(xunpack(hightech, "Advice")),
               as.matrix(xunpack(hightech, 1)))
  expect_error(xunpack(hightech, "nope"), "no relation")
})

test_that("prefix titles the unpacked datasets", {
  expect_equal(xunpack(hightech, "Advice", prefix = "ht-")$title, "ht-Advice")
})

test_that("join and unpack are inverses", {
  back <- xjoin(xunpack(hightech), mode = "mat")
  expect_equal(xrelations(back), xrelations(hightech))
  expect_equal(as.matrix(back, relation = "Advice"),
               as.matrix(hightech, relation = "Advice"))
})

# ---- xcombine ---------------------------------------------------------------

test_that("each statistic collapses the relations cellwise", {
  s <- stack3()
  # cell (a,b) is 1, 1, 0 across the three relations
  expect_equal(as.matrix(xcombine(s, method = "sum"))["a", "b"], 2)
  expect_equal(as.matrix(xcombine(s, method = "mean"))["a", "b"], 2 / 3)
  expect_equal(as.matrix(xcombine(s, method = "min"))["a", "b"], 0)
  expect_equal(as.matrix(xcombine(s, method = "max"))["a", "b"], 1)
  expect_equal(as.matrix(xcombine(s, method = "product"))["a", "b"], 0)
  v <- c(1, 1, 0)
  expect_equal(as.matrix(xcombine(s, method = "sd"))["a", "b"],
               sqrt(mean((v - mean(v))^2)))
})

test_that("sum is the default", {
  expect_equal(as.matrix(xcombine(stack3())),
               as.matrix(xcombine(stack3(), method = "sum")))
})

test_that("the diagonal comes back missing unless it is asked for", {
  out <- as.matrix(xcombine(stack3()))
  expect_true(all(is.na(diag(out))))
  expect_equal(unname(diag(as.matrix(xcombine(stack3(), diagonal = TRUE)))),
               c(0, 0, 0))
})

test_that("relations picks which ones are used", {
  s <- stack3()
  out <- as.matrix(xcombine(s, relations = c("one", "two"), method = "sum"))
  expect_equal(out["a", "c"], 1)       # only relation two has it
  expect_error(xcombine(s, relations = "nope"), "no relation")
})

test_that("missing cells take no part", {
  s <- stack3()
  s$data$one["a", "b"] <- NA
  expect_equal(as.matrix(xcombine(s, method = "sum"))["a", "b"], 1)
})

test_that("a list of separate networks is joined first", {
  out <- xcombine(list(one = campnet, two = campnet))
  expect_equal(dim(as.matrix(out)), c(18, 18))
})

test_that("one relation is not a combination", {
  expect_error(xcombine(campnet), "two or more relations")
})

test_that("xcombine names the dataset and lists what it used", {
  expect_equal(xcombine(hightech)$title, "hightech-agg")
  expect_match(attr(xcombine(hightech), "history"), "3 relations")
})

# ---- xmultiplex -------------------------------------------------------------

test_that("relation k contributes 2^(k-1)", {
  s <- stack3()
  out <- as.matrix(xmultiplex(s))
  # (a,b) is in relations one and two: 1 + 2 = 3
  expect_equal(out["a", "b"], 3)
  # (a,c) is in two and three: 2 + 4 = 6
  expect_equal(out["a", "c"], 6)
  # (b,a) is in none
  expect_equal(out["b", "a"], 0)
})

test_that("only positive, present cells count", {
  s <- stack3()
  s$data$one["a", "b"] <- NA
  # relation one no longer contributes its 1
  expect_equal(as.matrix(xmultiplex(s))["a", "b"], 2)
})

test_that("the legend names the relations behind every code that occurs", {
  h <- attr(xmultiplex(stack3()), "history")
  expect_match(h[1], "multiplex codes")
  expect_true(any(grepl("3 = one \\+ two", h)))
  expect_true(any(grepl("6 = two \\+ three", h)))
  expect_true(any(grepl("0 = none", h)))
})

test_that("xmultiplex names the dataset", {
  expect_equal(xmultiplex(hightech)$title, "hightech-mpx")
})

test_that("one relation is not a multiplex", {
  expect_error(xmultiplex(campnet), "several relations")
})

# ---- xread / xfromedgelist duplicates (5.10) --------------------------------

test_that("duplicated pairs are summed by default", {
  # The ch05 text says duplicates are summed; the reader used to keep the last.
  el <- data.frame(from = c("a","b","a"), to = c("b","c","b"), w = c(1, 2, 5))
  m <- as.matrix(suppressMessages(xfromedgelist(el, weight = 3)))
  expect_equal(m["a", "b"], 6)
  expect_equal(m["b", "c"], 2)
})

test_that("last keeps the last value and error refuses", {
  el <- data.frame(from = c("a","b","a"), to = c("b","c","b"), w = c(1, 2, 5))
  m <- as.matrix(suppressMessages(
    xfromedgelist(el, weight = 3, duplicates = "last")))
  expect_equal(m["a", "b"], 5)
  expect_error(xfromedgelist(el, weight = 3, duplicates = "error"),
               "listed more than once")
})

test_that("an unweighted pair listed twice counts twice", {
  el <- data.frame(from = c("a","a"), to = c("b","b"))
  expect_equal(as.matrix(suppressMessages(xfromedgelist(el)))["a", "b"], 2)
})

test_that("the count is reported and recorded", {
  el <- data.frame(from = c("a","b","a"), to = c("b","c","b"), w = c(1, 2, 5))
  expect_message(xfromedgelist(el, weight = 3), "1 duplicated pair summed")
  expect_match(attr(suppressMessages(xfromedgelist(el, weight = 3)), "history"),
               "1 duplicated pair summed")
})

test_that("a clean edge list says nothing", {
  el <- data.frame(from = c("a","b"), to = c("b","c"), w = c(1, 2))
  expect_silent(xfromedgelist(el, weight = 3))
  expect_null(attr(xfromedgelist(el, weight = 3), "history"))
})

test_that("xread passes duplicates through", {
  tmp <- file.path(tempdir(), "xucinet-dup.csv")
  writeLines(c("from,to,w", "a,b,1", "b,c,2", "a,b,5"), tmp)
  on.exit(unlink(tmp))
  expect_equal(as.matrix(suppressMessages(xread(tmp)))["a", "b"], 6)
  expect_equal(as.matrix(suppressMessages(
    xread(tmp, duplicates = "last")))["a", "b"], 5)
})
