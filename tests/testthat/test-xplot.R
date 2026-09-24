# xplot and xlayout (issue #30). No goldens: NetDraw is not the oracle. The
# tests cover what is not a picture - coordinates, which nodes and ties are
# drawn, how attributes are mapped, files written - and every drawing runs on
# a null device so check exercises the drawing code.

draw <- function(...) {
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off())
  xplot(...)
}

test_that("xlayout returns one labelled row per node", {
  for (m in c("spring", "kk", "mds", "nmds", "circle", "random")) {
    xy <- xlayout(campnet, m)
    expect_equal(dim(xy), c(18L, 2L), info = m)
    expect_equal(rownames(xy), rownames(as.matrix(campnet)), info = m)
    expect_true(all(is.finite(xy)), info = m)
    expect_equal(attr(xy, "xlayout"), m)
  }
})

test_that("the same call gives the same picture; seed = NULL need not", {
  expect_equal(xlayout(campnet), xlayout(campnet))
  expect_false(isTRUE(all.equal(xlayout(campnet, seed = 1), xlayout(campnet, seed = 2))))
})

test_that("the layout leaves the caller's random stream alone", {
  set.seed(42); a <- stats::runif(1)
  set.seed(42); xlayout(campnet); b <- stats::runif(1)
  expect_equal(a, b)
})

test_that("mds copes with an isolate: unreachable pairs are max + 1", {
  xy <- xlayout(padgett, "mds", relation = "Marriage")
  expect_true(all(is.finite(xy)))
  # PUCCI, the isolate, is the node farthest from the centre.
  ctr <- colMeans(xy)
  far <- rownames(xy)[which.max(rowSums(sweep(xy, 2, ctr)^2))]
  expect_equal(far, "PUCCI")
})

test_that("groups puts each category together", {
  dept <- hightech_attr$Department
  xy <- xlayout(hightech, "groups", attribute = dept)
  d <- as.matrix(stats::dist(xy))
  same <- outer(dept, dept, "==")
  off <- row(d) != col(d)
  expect_lt(max(d[same & off]), min(d[!same]))
  expect_error(xlayout(hightech, "groups"), "attribute")
})

test_that("an attribute can be named, and looked up in data", {
  a <- xlayout(hightech, "groups", attribute = "Department", data = hightech_attr)
  b <- xlayout(hightech, "groups", attribute = hightech_attr$Department)
  expect_equal(a, b)
})

test_that("bipartite lays the two modes out in two lines", {
  xy <- xlayout(davis, "bipartite")
  expect_equal(nrow(xy), 18L + 14L)
  expect_equal(unname(xy[1:18, 2]), rep(1, 18))
  expect_equal(unname(xy[19:32, 2]), rep(0, 14))
  expect_error(xlayout(campnet, "bipartite"), "2-mode")
})

test_that("xplot returns the coordinates it drew, reusable as a layout", {
  xy <- draw(campnet)
  expect_equal(unname(xy), unname(xlayout(campnet, relation = 1)),
               ignore_attr = TRUE)
  again <- draw(campnet, layout = xy)
  expect_equal(unname(again), unname(xy), ignore_attr = TRUE)
})

test_that("a layout is matched by label, so a subset keeps its places", {
  xy <- xlayout(campnet)
  keep <- c("PAM", "HOLLY", "BILL")
  sub <- draw(campnet, layout = xy, keep = keep)
  expect_equal(rownames(sub), rownames(xy)[rownames(xy) %in% keep])
  expect_equal(unname(sub[, 1]), unname(xy[rownames(sub), 1]))
  expect_error(draw(campnet, layout = xy[1:5, ]), "no coordinates for 13 nodes")
})

test_that("isolates = FALSE keeps the others where they were and says how many", {
  s <- as.matrix(xunpack(zachary, relation = "Strength"))
  diag(s) <- 0
  expected <- sum(rowSums(s > 3) + colSums(s > 3) == 0)
  xy <- draw(zachary, relation = "Strength")
  expect_message(
    kept <- draw(zachary, relation = "Strength", layout = xy, cutoff = 3,
                 isolates = FALSE),
    paste(expected, "isolates not drawn"))
  expect_equal(nrow(kept), 34L - expected)
  expect_equal(unname(kept), unname(xy[rownames(kept), ]), ignore_attr = TRUE)
})

test_that("ego draws the node and everyone tied to it in either direction", {
  m <- as.matrix(campnet)
  alters <- rownames(m)[m["HOLLY", ] != 0 | m[, "HOLLY"] != 0]
  xy <- draw(campnet, ego = "HOLLY")
  expect_setequal(rownames(xy), c("HOLLY", alters))
  expect_error(draw(campnet, ego = "NOBODY"), "no node called")
})

test_that("node attributes come from names, data, vectors or results", {
  labs <- rownames(as.matrix(campnet))
  deg <- xdegree(campnet)
  v <- node_values(deg, as_xucinet(campnet), NULL, labs, "", "nodesize")
  expect_equal(unname(v), deg$nodes[[1]])
  lev <- node_values("Level", as_xucinet(hightech), hightech_attr,
                     rownames(as.matrix(hightech)), "", "nodecolor")
  expect_equal(unname(lev), hightech_attr$Level)
  # Named values are put back in node order, whatever order they came in.
  shuffled <- stats::setNames(seq_along(labs), labs)[rev(seq_along(labs))]
  expect_equal(unname(node_values(shuffled, NULL, NULL, labs, "", "x")),
               seq_along(labs))
  expect_error(node_values(1:3, NULL, NULL, labs, "", "nodesize"),
               "3 values but there are 18 nodes")
})

test_that("categories and sizes follow the documented rules", {
  expect_true(is_categorical(c("a", "b")))
  expect_true(is_categorical(c(1, 2, 3, 1)))
  expect_false(is_categorical(c(1.5, 2, 3)))
  expect_false(is_categorical(1:10))
  expect_equal(rescale(c(0, 5, 10), 1, 3), c(1, 2, 3))
  expect_equal(rescale(c(4, 4), 1, 3), c(2, 2))
})

test_that("every argument draws without error", {
  expect_silent(draw(hightech, relation = "Friendship", nodesize = "Tenure",
                     nodecolor = "Level", nodeshape = "Level", data = hightech_attr,
                     main = "friendship"))
  expect_silent(draw(padgett, relation = c("Marriage", "Business"),
                     edgecolor = c("darkgreen", "blue", "black"),
                     edgestyle = c("solid", "dashed")))
  expect_silent(draw(padgett, relation = "Marriage", labelsize = "Wealth",
                     nodesize = "NoPriors", data = padgett_attr, nodecolor = "white",
                     nodeshape = "square"))
  expect_silent(draw(newfrat, relation = 1, cutoff = NULL, arrowsize = TRUE,
                     label = FALSE))
  expect_silent(draw(davis))
  expect_silent(draw(wolfe_primates, relation = "JointPresence", cutoff = 5,
                     layout = wolfe_primates_attr[, c("Age", "Rank")]))
  expect_silent(draw(campnet, nodecolor = xbetweenness(campnet), arrows = FALSE,
                     edgewidth = 2, legend = FALSE))
})

test_that("file = writes the file and draws nothing on screen", {
  dir <- tempfile("xplot")
  dir.create(dir)
  on.exit(unlink(dir, recursive = TRUE))
  for (ext in c("png", "pdf", "svg", "jpg")) {
    f <- file.path(dir, paste0("net.", ext))
    xy <- xplot(campnet, file = f, width = 3, height = 3, dpi = 72)
    expect_true(file.exists(f), info = ext)
    expect_gt(file.size(f), 0)
    expect_equal(nrow(xy), 18L)
  }
  sig <- readBin(file.path(dir, "net.png"), "raw", 4)
  expect_equal(sig, as.raw(c(0x89, 0x50, 0x4e, 0x47)))
  expect_error(xplot(campnet, file = file.path(dir, "net.bmp")), "must end in")
})

test_that("relations are named or numbered, and wrong names teach", {
  expect_error(draw(padgett, relation = "Friendship"), "Available: Marriage, Business")
  a <- draw(padgett, relation = 2)
  b <- draw(padgett, relation = "Business")
  expect_equal(a, b)
})

test_that("xhelp finds the drawing functions by the words people use", {
  for (w in c("plot", "draw", "netdraw", "layout")) {
    r <- suppressMessages(utils::capture.output(res <- xhelp(w)))
    expect_true("xplot" %in% res$name_2, info = w)
  }
})
