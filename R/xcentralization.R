# Centralization.
#
# Design question 10.5: this is a thin function over the centrality routines,
# which return their own centralization, "so the two cannot disagree; no
# independent computation".
#
# That holds for two of the four measures. `xdegree()` reports
# Out-Centralization and In-Centralization (or Centralization when the data
# are undirected) and `xbetweenness()` reports its Network Centralization
# Index; `xcloseness()` and `xeigenvector()` report none, although UCINET does
# print one for each:
#
#   xcloseness.pas          'Network Centralization = ', netcent:0:2, '%'
#   uc_EigenvectorCentrality.pas   getcentralization(), reported as
#                           'Eigenvector centralization percentages'
#
# So those two are a gap in the chapter 9 routines rather than in this one.
# The formulas are in the Delphi, but the chapter 9 goldens do not hold either
# figure - log_menu.txt has the degree centralization and nothing else - so
# implementing them now would be arithmetic no golden could check. They wait
# for a UCINET run, and until then this function says so rather than
# computing something of its own.

# Which routine to ask, and which of its summary fields is the centralization.
centralization_sources <- list(
  degree      = list(fn = "xdegree",
                     fields = c("Centralization", "Out-Centralization",
                                "In-Centralization")),
  betweenness = list(fn = "xbetweenness",
                     fields = "Network Centralization Index (%)"))

#' Centralization
#'
#' How unequally a centrality measure is spread across the network: how far it
#' is from a star, where one node has everything.
#'
#' This is deliberately not a computation. It calls the centrality routine and
#' hands back the centralization that routine reports, so that the two can
#' never disagree with each other (design question 10.5).
#'
#' `"closeness"` and `"eigenvector"` are not available yet. UCINET reports a
#' centralization for both, but [xcloseness()] and [xeigenvector()] do not, and
#' the chapter 9 goldens hold neither figure, so there is nothing to check an
#' implementation against. Both are open on the issue list.
#'
#' @param net A network (any accepted form).
#' @param measure `"degree"` (the default) or `"betweenness"`.
#' @param ... Passed to the centrality routine, so its own options - `normalize`
#'   and the rest - still work.
#' @return An object of class `c("xcentralization", "xucinet_output")` whose
#'   `$summary` is the centralization the centrality routine reported.
#' @seealso [xdegree()] and [xbetweenness()], which report the same figures as
#'   part of their fuller output.
#' @examples
#' xcentralization(campnet)
#' xcentralization(campnet, measure = "betweenness")
#' @export
xcentralization <- function(net, measure = c("degree", "betweenness",
                                             "closeness", "eigenvector"),
                            ...) {
  net <- xnet(net, substitute(net))
  # All four are accepted so that the two that are not ready get an
  # explanation rather than "should be one of".
  measure <- match.arg(measure)

  if (measure %in% c("closeness", "eigenvector")) {
    stop("measure = \"", measure, "\" is not available yet.\n",
         "  UCINET reports a ", measure, " centralization, but x", measure,
         "() does not carry one and the chapter 9 goldens do not hold the ",
         "figure, so there is nothing to check an implementation against.\n",
         "  This function deliberately computes nothing of its own (design ",
         "question 10.5).\n",
         "  Available now: \"degree\", \"betweenness\".", call. = FALSE)
  }

  spec <- centralization_sources[[measure]]
  fn <- get(spec$fn, envir = asNamespace("xucinet"), mode = "function")
  res <- fn(net, ...)

  found <- intersect(spec$fields, names(res$summary))
  if (!length(found)) {
    stop("x", measure, "() reported no centralization for this network, so ",
         "there is none to hand back.", call. = FALSE)
  }

  new_xucinet_output(
    "Centralization", net,
    summary = res$summary[found],
    assumptions = c(res$assumptions,
                    paste0("Taken from x", measure, "(), not recomputed.")),
    subclass = "xcentralization",
    summary_title = "Graph Centralization -- as proportion, not percentage")
}
