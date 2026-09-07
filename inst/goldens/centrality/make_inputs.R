# Inputs for the chapter 9 centrality goldens.
#
# Run from the package root:  Rscript inst/goldens/centrality/make_inputs.R
#
# Writes every input make_goldens.txt needs into this folder as a ##h/##d pair,
# so UCINET can be pointed at one directory and nothing outside it is touched.
# Four come straight from the shipped datasets; two are built here because the
# package ships no disconnected network and none with isolates, and those are
# exactly the cases that tell closeness conventions apart.
#
# Our own writer produces these, which is safe: UCINET read every file it wrote
# in issue #3, and reading them back here checks the round trip again.

devtools::load_all(".", quiet = TRUE)
here <- "inst/goldens/centrality"

# --- the shipped four --------------------------------------------------------
# campnet         binary, directed, 18 nodes      the everyday case, and the
#                                                 directed one
# sampson         10 relations, 18 nodes          the multi-relation case
# davis           2-mode, 18 women by 14 events   the 2-mode case
# baker_journals  valued, directed, 20 nodes      the valued case
# newguinea       Alliance + Opposition, 16       the negative-tie case, for
#                                                 xdegree(net, relation = ...)
for (d in c("campnet", "sampson", "davis", "baker_journals", "newguinea")) {
  xsaveucinet(get(d), file.path(here, d), title = d)
}

# --- disconnected, no isolates -----------------------------------------------
# Three components of different size AND shape, so the four Freeman options for
# undefined distances (N, max+1, ignore, within-component) all give different
# numbers rather than coinciding by luck.
#   star     n1 hub, spokes n2-n5   within-component diameter 2
#   path     n6-n7-n8-n9            within-component diameter 3
#   triangle n10-n11-n12            within-component diameter 1
disc <- matrix(0, 12, 12, dimnames = list(paste0("n", 1:12), paste0("n", 1:12)))
edges <- rbind(c(1,2), c(1,3), c(1,4), c(1,5),
               c(6,7), c(7,8), c(8,9),
               c(10,11), c(11,12), c(10,12))
disc[edges] <- 1
disc[edges[, 2:1]] <- 1
xsaveucinet(disc, file.path(here, "g9_disc"), title = "g9_disc")

# --- isolates ----------------------------------------------------------------
# A connected core of seven plus three isolates. The chord makes betweenness
# vary across the core instead of being a flat path, and the isolates give
# degree 0, undefined closeness and eigenvector 0 in the same dataset.
iso <- matrix(0, 10, 10, dimnames = list(paste0("n", 1:10), paste0("n", 1:10)))
edges <- rbind(c(1,2), c(2,3), c(3,4), c(4,5), c(5,6), c(6,7), c(2,4))
iso[edges] <- 1
iso[edges[, 2:1]] <- 1
xsaveucinet(iso, file.path(here, "g9_iso"), title = "g9_iso")

# --- a small 2-mode network --------------------------------------------------
# davis is 18 x 14, too big to work a normalization denominator out of by
# inspection. This is 5 rows by 3 columns, deliberately uneven so that row and
# column margins, path lengths and degrees are all different and no two
# candidate denominators can coincide by luck.
small2 <- matrix(c(1, 1, 0,
                   1, 0, 0,
                   0, 1, 1,
                   0, 0, 1,
                   1, 1, 1), nrow = 5, byrow = TRUE,
                 dimnames = list(paste0("r", 1:5), paste0("c", 1:3)))
xsaveucinet(small2, file.path(here, "g9_small2"), title = "g9_small2")

# --- check the round trip ----------------------------------------------------
stopifnot(identical(unname(as.matrix(xreaducinet(file.path(here, "g9_disc")))),
                    unname(disc)),
          identical(unname(as.matrix(xreaducinet(file.path(here, "g9_iso")))),
                    unname(iso)),
          all(as.matrix(xreaducinet(file.path(here, "davis"))) ==
              as.matrix(davis)))

cat("wrote", length(dir(here, pattern = "[.]##h$")), "inputs to", here, "\n")
