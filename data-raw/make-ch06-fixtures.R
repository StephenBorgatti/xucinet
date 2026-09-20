# Fixtures for the chapter 6 port tests: borgworld's own results on the same
# inputs, so tests/testthat/test-xmds.R, test-xcorrespondence.R and
# test-xhclust.R can check the port against its source without borgworld
# installed. Sources the vendored copies in inst/reference/borgworld/ rather
# than the installed package, so the fixture is tied to the commit the port
# was made from. Re-run only when those vendored files are updated.
#
# Where the port deliberately departs from borgworld (see the header of each
# R/x*.R file) the fixture still records borgworld's numbers, and the test
# says which comparison is expected to differ.

pkg <- normalizePath(".")
src <- file.path(pkg, "inst", "reference", "borgworld")
env <- new.env()
for (f in c("b_classicalmds.R", "b_nonmetricmds.R", "b_hiclus.R", "b_moca.R", "b_corresp.R")) {
  sys.source(file.path(src, f), envir = env)
}
load(file.path(pkg, "data", "cities.rda"))
load(file.path(pkg, "data", "doctorates.rda"))
load(file.path(pkg, "data", "campnet.rda"))
load(file.path(pkg, "data", "davis.rda"))

cities_m <- as.matrix(cities$data)
doct_m <- as.matrix(doctorates$data)
davis_m <- as.matrix(davis$data)
camp_m <- as.matrix(campnet$data)
camp_sym <- (camp_m + t(camp_m)) / 2

fx <- list()

fx$cmds_cities <- env$bclassicalmds(cities_m, "d", dim = 2, plot = FALSE)
fx$nmds_cities <- env$bnonmetricmds(cities_m, "d", dim = 2, plot = FALSE)
# Similarity input: the port converts with the off-diagonal max, borgworld's
# MDS with the whole-matrix max, so these differ by design when the diagonal
# holds the maximum. campnet's diagonal is 0 and its max is 1, so here the two
# rules agree and the comparison is exact; the test says so.
fx$cmds_campnet <- env$bclassicalmds(camp_sym, "s", dim = 2, plot = FALSE)

pdf(NULL)
fx$hclus_cities_single <- env$bhiclus(cities_m, type = "d", method = "single",
                                      print_dendrogram = FALSE, plot_dendrogram = FALSE)
fx$hclus_cities_average <- env$bhiclus(cities_m, type = "d", method = "average",
                                       print_dendrogram = FALSE, plot_dendrogram = FALSE)
fx$hclus_campnet_average <- env$bhiclus(camp_sym, type = "s", method = "average",
                                        print_dendrogram = FALSE, plot_dendrogram = FALSE)
dev.off()
for (nm in grep("^hclus_", names(fx), value = TRUE)) {
  fx[[nm]] <- fx[[nm]][c("partition_table", "moca", "cophenetic", "labels", "type", "method")]
  fx[[nm]]$heights <- NULL
}

fx$ca_doctorates <- env$bcorresp(doct_m, graph = FALSE, verbose = FALSE)
fx$ca_davis <- env$bcorresp(davis_m, graph = FALSE, verbose = FALSE)
for (nm in c("ca_doctorates", "ca_davis")) {
  fx[[nm]] <- fx[[nm]][c("row.coords", "col.coords", "eigenvalues", "variance.explained",
                         "row.contrib", "col.contrib", "row.cos2", "col.cos2",
                         "chi2", "total.inertia", "n.dim")]
}

dir.create(file.path(pkg, "tests", "testthat", "fixtures"), showWarnings = FALSE)
saveRDS(fx, file.path(pkg, "tests", "testthat", "fixtures", "borgworld-ch06.rds"), version = 2)
cat("wrote", length(fx), "fixtures\n")
