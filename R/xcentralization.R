# Centralization.
#
# Design question 10.5: this is a thin function over the centrality routines,
# which return their own centralization, "so the two cannot disagree; no
# independent computation". The SPEC addendum of 23 Sep 2026 makes that a rule:
# a function that summarizes another's output reads the summary from it.
#
# All four measures have a centralization to read:
#
#   xdegree()       Centralization, or Out- and In-Centralization, a proportion
#                   (uc_DegreeCentrality.pas)
#   xbetweenness()  Network Centralization Index (%)
#   xcloseness()    Network Centralization (%), or in- and out-, from UCINET's
#                   legacy Closeness routine (xcloseness.pas), since the current
#                   dialog prints none (Steve, 23 Sep 2026; ledger entry 31)
#   xeigenvector()  Eigenvector centralization (%), from
#                   uc_EigenvectorCentrality.pas, getcentralization
#
# Since 23 Sep 2026 (SPEC addendum, item 5) the result always holds all four,
# in one row, missing where a routine reports none for the network; `measure`
# chooses which is printed.
#
# 2-mode data (xucinet#56, 23 Nov 2026): each routine reports a centralization
# for the rows and one for the columns (twomode_centralization() in
# R/xcentrality.R), so the result holds two figures per measure. UCINET has no
# 2-mode centralization (DIFFERENCES 52).

# Which routine to ask, and which of its summary fields are the centralization.
centralization_sources <- list(
  degree      = list(fn = "xdegree",
                     fields = c("Centralization", "Out-Centralization",
                                "In-Centralization", "Row Centralization",
                                "Column Centralization")),
  betweenness = list(fn = "xbetweenness",
                     fields = c("Network Centralization Index (%)",
                                "Row Centralization Index (%)",
                                "Column Centralization Index (%)")),
  closeness   = list(fn = "xcloseness",
                     fields = c("Network Centralization (%)",
                                "Network in-Centralization (%)",
                                "Network out-Centralization (%)",
                                "Row Centralization (%)",
                                "Column Centralization (%)")),
  eigenvector = list(fn = "xeigenvector",
                     fields = c("Eigenvector centralization (%)",
                                "Row eigenvector centralization (%)",
                                "Column eigenvector centralization (%)")))

#' Centralization
#'
#' How unequally a centrality measure is spread across the network: how far it
#' is from a star, where one node has everything.
#'
#' This is deliberately not a computation. It calls the four centrality
#' routines and hands back the centralization each reports, so that the two can
#' never disagree (design question 10.5). All four are always in the result;
#' `measure` chooses which is printed. Degree centralization is a proportion;
#' betweenness, closeness and eigenvector centralization are percentages, as
#' UCINET reports each. Closeness centralization is the figure UCINET's legacy
#' Closeness routine printed, since its current Closeness dialog prints none,
#' and it is missing for a network that is not connected.
#'
#' @param net A network (any accepted form).
#' @param measure Which centralization to print: `"degree"` (the default),
#'   `"betweenness"`, `"closeness"` or `"eigenvector"`.
#' @param ... Passed to the centrality routines that take them, so `directed`,
#'   `normalize` and the rest still work.
#' @return An object of class `c("xcentralization", "xucinet_output")` whose
#'   `$summary` holds every centralization the four routines report: degree
#'   (one figure, or out- and in- for directed data), betweenness, closeness
#'   (one, or in- and out-) and eigenvector. For 2-mode data each measure has
#'   a row and a column figure, computed for each mode separately; see
#'   [xdegree()]. UCINET reports no 2-mode centralization.
#' @seealso [xdegree()], [xbetweenness()], [xcloseness()] and [xeigenvector()],
#'   which report the same figures as part of their fuller output.
#' @examples
#' xcentralization(campnet)
#' xcentralization(campnet, measure = "betweenness")
#' xcentralization(campnet, measure = "eigenvector")
#' @export
xcentralization <- function(net, measure = c("degree", "betweenness",
                                             "closeness", "eigenvector"),
                            ...) {
  net <- xnet(net, substitute(net))
  measure <- match.arg(measure)
  dots <- list(...)

  summary <- list()
  shown <- character(0)
  assumptions <- character(0)
  for (ms in names(centralization_sources)) {
    spec <- centralization_sources[[ms]]
    fn <- get(spec$fn, envir = asNamespace("xucinet"), mode = "function")
    args <- dots[names(dots) %in% names(formals(fn))]
    res <- tryCatch(do.call(fn, c(list(net), args)), error = function(e) NULL)
    got <- if (is.null(res)) list() else res$summary[intersect(spec$fields,
                                                              names(res$summary))]
    if (!length(got)) {
      got <- stats::setNames(list(NA_real_), spec$fields[1])
    }
    summary <- c(summary, got)
    if (ms == measure) {
      shown <- names(got)
      if (!is.null(res)) assumptions <- res$assumptions
    }
  }

  new_xucinet_output(
    "Centralization", net,
    summary = summary, show_summary = shown,
    assumptions = c(assumptions, sprintf("Taken from %s(), not recomputed.",
                                         centralization_sources[[measure]]$fn)),
    subclass = "xcentralization", call = match.call(),
    # Each routine's own title for the figure: only degree is a proportion.
    summary_title = switch(measure,
      degree = "Graph Centralization -- as proportion, not percentage",
      eigenvector = "Eigenvector centralization percentages",
      NULL))
}
