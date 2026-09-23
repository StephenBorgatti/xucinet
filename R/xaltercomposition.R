# Egonet alter composition, categorical and continuous.
#
# UCINET: Network | Ego Networks | Egonet Alter Composition | Categorical, the
# form uc_EgoNetComposition.pas (TEgoNetComposition.run) with the arithmetic in
# G2Tools/uegocomposition.pas (massagematrix, egonetaltercomposition) and
# G2Tools/utfrequencies5.pas (tfrequencies: addcase, maketable,
# getheterogeneity); and ... | Continuous, the form uc_EgoNetStrength.pas
# (TEgoNetStrength.run, runstats) with G1Tools/utunivariate.pas (tunivariate:
# addcase, addcasewt, calc). Repositories StephenBorgatti/ucinet at commit
# c7b4956 and StephenBorgatti/tools at commit 207958a.
#
# Dialog defaults:
#   both        Definition of Ego Network = Both incoming and outgoing ties
#               (ItemIndex 0), which massagematrix makes a max-symmetrize
#   Categorical Ignore ego's own category unchecked
#   Continuous  Valued tie data = Treat tie strengths as analytical weights
#               (ItemIndex 1); both SD filters unchecked
#
# The continuous dialog's "Filter out alters more than ... SDs above/below the
# mean" is not offered: in the source the filter never filters (UCINET issue
# 20), so there is no behaviour to reproduce.

#' Egonet alter composition
#'
#' UCINET: Network | Ego Networks | Egonet Alter Composition, both the
#' Categorical and the Continuous item, as one function. Describes the alters
#' of each ego on an attribute: for a categorical attribute, how many fall in
#' each category and how mixed they are; for a continuous one, their average,
#' spread and range.
#'
#' Whether the attribute is categorical is decided by `type`, or when that is
#' `NULL` by the attribute itself: character, factor and logical values are
#' categorical, numbers are continuous. A numeric attribute with five or fewer
#' whole-number values is probably a set of category codes (camp92's `Gender`
#' is 1 and 2), and the report says so, but it is still treated as continuous
#' unless `type = "categorical"` is given.
#'
#' **Categorical.** The first column is ego's own value. Then, for each
#' category `c` (sorted), `fc` is how many alters are in it and `pc` what
#' proportion of ego's alters that is, followed by `Heterogeneity` (Blau's
#' index, one minus the sum of squared proportions) and `IQV` (Blau divided by
#' its maximum, `1 - 1/K` for the `K` categories of the whole attribute). Tie
#' values weight the counts, as UCINET does: on valued data `fc` is the total
#' strength of ego's ties into category `c`. A table of the attribute's own
#' frequencies is printed first, as UCINET prints it.
#'
#' **Continuous.** `Avg`, `Sum`, `Min`, `Max`, `StdDev` (dividing by the
#' number of alters), `EstSD` (dividing by one less), `CV` (StdDev over Avg),
#' `Num` (the number of alters) and `WtdNum` (the sum of their tie weights).
#' With the default `weighting = "analytic"` the tie values weight the mean and
#' the standard deviations; `"multiply"` multiplies each alter's value by the
#' tie before anything else; `"none"` ignores tie values.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Egonet Alter Composition | Categorical, and ... |
#' Continuous. *Definition of Ego Network* is `direction`, *Ignore ego's own
#' category* is `ignoreown`, and the continuous dialog's *Valued tie data* is
#' `weighting`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param attribute The attribute: a vector, or the name of a column looked up
#'   first in `net`'s attribute table and then in `data`.
#' @param type `"categorical"`, `"continuous"`, or `NULL` (the default) to
#'   decide from the attribute.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param direction Who counts as an alter: `"undirected"` (the default, a tie
#'   in either direction), `"out"`, `"in"` or `"reciprocated"`.
#' @param ignoreown Categorical only: leave out alters in ego's own category?
#'   `FALSE` by default.
#' @param weighting Continuous only: `"analytic"` (the default), `"none"` or
#'   `"multiply"`.
#' @param data A data frame to look `attribute` up in.
#' @return An object of class `c("xaltercomposition", "xucinet_output")` with
#'   the measures in `$nodes`, in original node order, and, for a categorical
#'   attribute, the attribute's frequencies in `$matrices$Frequencies`.
#' @seealso [xegoaltersimilarity()] for whether alters resemble ego.
#' @examples
#' xaltercomposition(campnet, camp92_attr$Gender, type = "categorical")
#' xaltercomposition(hightech, "Age", data = hightech_attr)
#' @export
xaltercomposition <- function(net, attribute, type = NULL, relation = NULL,
                              direction = c("undirected", "out", "in",
                                            "reciprocated"),
                              ignoreown = FALSE,
                              weighting = c("analytic", "none", "multiply"),
                              data = NULL) {
  net <- xnet(net, substitute(net))
  direction <- match_direction(direction, c("undirected", "out", "in",
                                            "reciprocated"),
                               "xaltercomposition()")
  weighting <- match.arg(weighting)
  rel <- ego_relation(net, relation, "xaltercomposition()")
  m <- rel$m
  n <- nrow(m)
  att <- ego_attribute(attribute, net, data, deparse1(substitute(attribute)), n,
                       "xaltercomposition()")
  kind <- attribute_type(att$values, type, "xaltercomposition()")
  assumptions <- c(rel$note, kind$note)

  x <- ego_rows(m, direction)
  dir_label <- c(undirected = "Both incoming and outgoing ties",
                 out = "Outgoing ties only", `in` = "Incoming ties only",
                 reciprocated = "Reciprocal ties only")[[direction]]

  if (kind$type == "categorical") {
    res <- composition_categorical(x, att$values, att$name, ignoreown)
    rownames(res$nodes) <- rownames(m)
    new_xucinet_output(
      "Egonet Composition", net,
      nodes = res$nodes, assumptions = assumptions,
      fields = c("Input Attribute:" = att$name,
                 "Ego Network Type:" = dir_label),
      preamble = c("Frequencies", "",
                   format_uci_matrix(res$frequencies)),
      nodes_title = "Ego Net Composition",
      subclass = "xaltercomposition", call = match.call())
  } else {
    nodes <- composition_continuous(x, att$values, weighting)
    rownames(nodes) <- rownames(m)
    new_xucinet_output(
      "Egonet Composition: Continuous Attributes", net,
      nodes = nodes, assumptions = assumptions,
      fields = c("Input Attribute:" = att$name,
                 "Ego Network Type:" = dir_label,
                 "Weighted Ties:" = c(analytic = "Treat tie strengths as analytical weights",
                                      none = "Ignore tie strengths",
                                      multiply = "Multiply tie strength by attrrib value"
                                      )[[weighting]]),
      nodes_title = "Ego Net Composition - Continuous Attribute measures",
      subclass = "xaltercomposition", call = match.call())
  }
}

# egonetaltercomposition. `x` has ego's ties in its rows already.
composition_categorical <- function(x, values, name, ignoreown) {
  n <- nrow(x)
  cats <- category_keys(values)
  k <- length(cats$keys)
  g <- cats$codes

  # The attribute's own frequency table, over every node with a value.
  f <- tabulate(g[!is.na(g)], nbins = k)
  freqs <- cbind(Freq = f, Prop = if (sum(f) > 0) f / sum(f) else NA_real_)
  rownames(freqs) <- cats$labels

  fr <- matrix(0, n, k)
  for (i in seq_len(n)) {
    for (j in seq_len(n)) {
      w <- x[i, j]
      if (i == j || is.na(w) || w <= 0 || is.na(g[j])) next
      # `attr.equal(i, j)`: an ego with a missing value matches nobody.
      if (ignoreown && !is.na(g[i]) && g[i] == g[j]) next
      fr[i, g[j]] <- fr[i, g[j]] + w
    }
  }
  tot <- rowSums(fr)
  pr <- fr / tot
  pr[tot == 0, ] <- NA

  # getheterogeneity: missing when there is nothing to divide, IQV 0 when the
  # attribute has one category, and K is the whole attribute's category count
  # because clearfreq keeps every key.
  het <- ifelse(tot > 0, 1 - rowSums(pr^2), NA_real_)
  iqv <- if (k > 1) het / (1 - 1 / k) else ifelse(tot > 0, 0, NA_real_)

  # UCINET's attribute is a number, and so is this column: a text attribute
  # shows ego's category by its position in the sorted categories, which the
  # column headings to its right spell out.
  own <- if (is.numeric(values)) values else as.numeric(g)
  nodes <- data.frame(own, check.names = FALSE)
  names(nodes) <- name
  for (c in seq_len(k)) nodes[[paste0("f", cats$labels[c])]] <- fr[, c]
  for (c in seq_len(k)) nodes[[paste0("p", cats$labels[c])]] <- pr[, c]
  nodes$Heterogeneity <- het
  nodes$IQV <- iqv
  list(nodes = nodes, frequencies = freqs)
}

# runstats with its three weightings. Missing ties and missing attribute values
# are skipped; a tie is any positive value.
composition_continuous <- function(x, values, weighting) {
  n <- nrow(x)
  cols <- c("Avg", "Sum", "Min", "Max", "StdDev", "EstSD", "CV", "Num", "WtdNum")
  out <- matrix(NA_real_, n, length(cols), dimnames = list(NULL, cols))
  for (i in seq_len(n)) {
    js <- which(seq_len(n) != i & !is.na(x[i, ]) & x[i, ] > 0 & !is.na(values))
    v <- values[js]
    w <- x[i, js]
    if (weighting == "multiply") v <- v * w
    if (weighting != "analytic") w <- rep(1, length(v))
    out[i, ] <- weighted_univariate(v, w)
  }
  as.data.frame(out, check.names = FALSE)
}

# tunivariate after addcasewt (or addcase, which is addcasewt with weight 1):
# the weighted mean and population variance mcssq/sumwt; EstSD from
# mcssq / ((n-1) sumwt / n); Sum is the unweighted total. With no cases every
# statistic is missing except the two counts, which are 0. EstSD and a zero
# variance stay 0 rather than missing, because calc() only overwrites the
# zero that clear() left when there is something to overwrite it with.
weighted_univariate <- function(v, w) {
  k <- length(v)
  if (k == 0L) return(c(rep(NA_real_, 7), 0, 0))
  sw <- sum(w)
  mu <- sum(w * v) / sw
  mcssq <- sum(w * (v - mu)^2)
  variance <- mcssq / sw
  sd <- if (variance > 0) sqrt(variance) else 0
  estsd <- if (k > 1) sqrt(mcssq / ((k - 1) * sw / k)) else 0
  cv <- if (abs(mu) > 1e-12) sd / mu else 0
  c(mu, sum(v), min(v), max(v), sd, estsd, cv, k, sw)
}
