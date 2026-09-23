# Centralization.
#
# Design question 10.5: this is a thin function over the centrality routines,
# which return their own centralization, "so the two cannot disagree; no
# independent computation". The SPEC addendum of 23 Sep 2026 makes that a rule:
# a function that summarizes another's output reads the summary from it.
#
# Three of the four measures have a centralization to read:
#
#   xdegree()       Centralization, or Out- and In-Centralization, a proportion
#                   (uc_DegreeCentrality.pas)
#   xbetweenness()  Network Centralization Index (%)
#   xeigenvector()  Eigenvector centralization (%), added 23 Sep 2026 from
#                   uc_EigenvectorCentrality.pas, getcentralization
#
# Closeness has none. The Closeness dialog that xcloseness() ports
# (uc_ClosenessMeasures.pas) prints no centralization; only the menu item
# Closeness (legacy), xcloseness.pas, did. Whether to carry that figure over
# is open for Steve (issue #16), so the measure stops with an explanation.

# Which routine to ask, and which of its summary fields is the centralization.
centralization_sources <- list(
  degree      = list(fn = "xdegree",
                     fields = c("Centralization", "Out-Centralization",
                                "In-Centralization")),
  betweenness = list(fn = "xbetweenness",
                     fields = "Network Centralization Index (%)"),
  eigenvector = list(fn = "xeigenvector",
                     fields = "Eigenvector centralization (%)"))

#' Centralization
#'
#' How unequally a centrality measure is spread across the network: how far it
#' is from a star, where one node has everything.
#'
#' This is deliberately not a computation. It calls the centrality routine and
#' hands back the centralization that routine reports, so that the two can
#' never disagree with each other (design question 10.5). Degree
#' centralization is a proportion; betweenness and eigenvector centralization
#' are percentages, as UCINET reports each.
#'
#' `"closeness"` is not available: the Closeness dialog that [xcloseness()]
#' follows reports no centralization. Only UCINET's legacy closeness routine
#' did.
#'
#' @param net A network (any accepted form).
#' @param measure `"degree"` (the default), `"betweenness"` or `"eigenvector"`.
#' @param ... Passed to the centrality routine, so its own options - `normalize`
#'   and the rest - still work.
#' @return An object of class `c("xcentralization", "xucinet_output")` whose
#'   `$summary` is the centralization the centrality routine reported.
#' @seealso [xdegree()], [xbetweenness()] and [xeigenvector()], which report
#'   the same figures as part of their fuller output.
#' @examples
#' xcentralization(campnet)
#' xcentralization(campnet, measure = "betweenness")
#' xcentralization(campnet, measure = "eigenvector")
#' @export
xcentralization <- function(net, measure = c("degree", "betweenness",
                                             "closeness", "eigenvector"),
                            ...) {
  net <- xnet(net, substitute(net))
  # All four are accepted so that closeness gets an explanation rather than
  # "should be one of".
  measure <- match.arg(measure)

  if (measure == "closeness") {
    stop("measure = \"closeness\" is not available.\n",
         "  UCINET's Closeness dialog, which xcloseness() follows, reports no ",
         "centralization; only its legacy closeness routine did.\n",
         "  This function deliberately computes nothing of its own (design ",
         "question 10.5).\n",
         "  Available: \"degree\", \"betweenness\", \"eigenvector\".",
         call. = FALSE)
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
    # Each routine's own title for the figure: only degree is a proportion.
    summary_title = switch(measure,
      degree = "Graph Centralization -- as proportion, not percentage",
      eigenvector = "Eigenvector centralization percentages",
      NULL))
}
