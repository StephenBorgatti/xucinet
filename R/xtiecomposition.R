# Egonet tie composition, binary and valued.
#
# UCINET: Network | Ego Networks | Egonet Tie Composition, the form
# uc_egonettiecomposition.pas (TEgonetTieComposition.run), with the counting in
# G2Tools/utegotiecomp2.pas (tegotiecomp.addmat and calc); and Network | Ego
# Networks | Egonet Valued Tie Composition, the form
# uc_egonetvaluedtiecomposition.pas (TValuedTieComposition.run, analyzer), with
# the statistics in G1Tools/utunivariate.pas (tunivariate.addcase and calc).
# Repositories StephenBorgatti/ucinet at commit c7b4956 and
# StephenBorgatti/tools at commit 207958a.
#
# Dialog defaults:
#   Tie Composition         Which ties matter? = Undirected (OR)   (ItemIndex 1)
#   Valued Tie Composition  Which ties matter? = Outgoing only     (ItemIndex 1)
#   both                    Valid ties = Not equal to 0 (ItemIndex 5, value 0);
#                           Include ties to self unchecked
#
# Two departures, both UCINET bugs (dev/UCINET-ISSUES.md):
#   18  Tie Composition never passes the Include-ties-to-self checkbox to
#       addmat, so the diagonal is always left out. `diagonal = TRUE` works here.
#   19  Valued Tie Composition, "Both in and out", adds x(i,m) for an incoming
#       tie where it means x(m,i). Here the incoming tie's own value is used.

#' Egonet tie composition
#'
#' UCINET: Network | Ego Networks | Egonet Tie Composition. For a network with
#' several relations - Sampson's liking, esteem and their negatives, say - how
#' each ego's ties are spread across them: the count on each relation, the
#' proportions, and how heterogeneous the mix is.
#'
#' For each ego the columns are `Ties` (the total over every relation), then a
#' count `f<relation>` and a proportion `p<relation>` for each relation, then
#' `Blau`, one minus the sum of squared proportions, and `IQV`, Blau divided
#' by its maximum `1 - 1/R` for `R` relations. An ego with no ties has missing
#' proportions and heterogeneity.
#'
#' On a single relation the count is just degree - out-degree, in-degree or
#' their union according to `direction` - and the proportions are trivially 1,
#' which the report notes.
#'
#' A tie is any cell passing the test `op`/`cutoff` (by default, any value other
#' than 0). A zero is never a tie, whatever the test, because UCINET recodes
#' zeros to missing before testing.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Egonet Tie Composition. *Which ties matter?* is
#' `direction`; the valid-ties operator and value are `op` and `cutoff`;
#' *Include ties to self* is `diagonal`.
#'
#' @param net A network (any accepted form), usually with several relations.
#' @param relations Which relations to use, by name or position. `NULL`, the
#'   default, uses them all, as UCINET does.
#' @param direction Which of ego's ties count: `"undirected"` (the default, a
#'   tie in either direction counted once), `"both"` (in and out counted
#'   separately, so a reciprocated tie counts twice), `"out"`, `"in"`,
#'   `"reciprocated"`, or `"equal"` (reciprocated with the same value both ways).
#' @param op,cutoff What counts as a tie: the value compared with `cutoff` by
#'   `op`, one of `"!="` (the default), `">"`, `">="`, `"=="`, `"<="`, `"<"`.
#' @param diagonal Count ties to self? `FALSE` by default.
#' @return An object of class `c("xtiecomposition", "xucinet_output")` with the
#'   measures in `$nodes`, in original node order.
#' @seealso [xvaluedtiecomposition()] for the values of the ties rather than
#'   their count.
#' @examples
#' xtiecomposition(sampson)
#' @export
xtiecomposition <- function(net, relations = NULL,
                            direction = c("undirected", "both", "out", "in",
                                          "reciprocated", "equal"),
                            op = c("!=", ">", ">=", "==", "<=", "<"),
                            cutoff = 0, diagonal = FALSE) {
  net <- xnet(net, substitute(net))
  require_1mode(net, "xtiecomposition()")
  direction <- match_direction(direction, c("undirected", "both", "out", "in",
                                            "reciprocated", "equal"),
                               "xtiecomposition()")
  op <- match_op(op, "xtiecomposition()")

  mats <- relation_list(net)
  if (!is.null(relations)) {
    idx <- if (is.character(relations)) match(relations, names(mats)) else
      as.integer(relations)
    if (anyNA(idx) || any(idx < 1 | idx > length(mats))) {
      stop("xtiecomposition(): relations must name relations of the dataset.\n",
           "  Available: ", paste(names(mats), collapse = ", "), call. = FALSE)
    }
    mats <- mats[idx]
  }
  nm <- length(mats)
  n <- nrow(mats[[1]])

  freq <- vapply(mats, function(m) {
    tie <- is_tie_matrix(m, op, cutoff)
    ego_tie_counts(m, tie, direction, diagonal)
  }, numeric(n))
  dim(freq) <- c(n, nm)

  tot <- rowSums(freq)
  prop <- freq / tot
  prop[tot == 0, ] <- NA
  blau <- 1 - rowSums(prop^2)
  iqv <- if (nm > 1) blau / (1 - 1 / nm) else rep(NA_real_, n)

  rel_names <- names(mats)
  nodes <- data.frame(Ties = tot, check.names = FALSE)
  for (j in seq_len(nm)) nodes[[paste0("f", rel_names[j])]] <- freq[, j]
  for (j in seq_len(nm)) nodes[[paste0("p", rel_names[j])]] <- prop[, j]
  nodes$Blau <- blau
  nodes$IQV <- iqv
  rownames(nodes) <- rownames(mats[[1]])

  assumptions <- if (nm == 1) {
    "One relation: Ties is degree, every proportion is 1 and Blau is 0."
  } else character(0)

  new_xucinet_output(
    "Node-level Tie Composition Measures", net,
    nodes = nodes, assumptions = assumptions,
    fields = c("Which ties to count?" = ego_direction_labels[[direction]],
               "Valid ties operator:" = tie_op_labels[[op]],
               "Valid ties value:" = format(cutoff)),
    nodes_title = "Node-level tie composition measures",
    subclass = "xtiecomposition", call = match.call())
}

#' Egonet valued tie composition
#'
#' UCINET: Network | Ego Networks | Egonet Valued Tie Composition. For each
#' ego, the values of its ties: how many there are, their sum, mean, standard
#' deviation, minimum, maximum and range.
#'
#' The standard deviation divides by the number of ties, not one less, as all
#' UCINET's descriptive statistics do. An ego with no ties has a count of 0 and
#' everything else missing.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Egonet Valued Tie Composition. *Which ties matter?*
#' is `direction`; the valid-ties operator and value are `op` and `cutoff`;
#' *Include ties to self* is `diagonal`.
#'
#' @inheritParams xtiecomposition
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param direction Which of ego's ties count: `"out"` (the default), `"in"`,
#'   `"both"` (out and in, a reciprocated pair contributing both values),
#'   `"reciprocated"` (both values of each reciprocated pair) or `"equal"`
#'   (reciprocated with the same value both ways).
#' @return An object of class `c("xvaluedtiecomposition", "xucinet_output")`
#'   with the seven statistics in `$nodes`, in original node order.
#' @seealso [xtiecomposition()].
#' @examples
#' xvaluedtiecomposition(camp92)
#' xvaluedtiecomposition(camp92, direction = "in")
#' @export
xvaluedtiecomposition <- function(net, relation = NULL,
                                  direction = c("out", "in", "both",
                                                "reciprocated", "equal"),
                                  op = c("!=", ">", ">=", "==", "<=", "<"),
                                  cutoff = 0, diagonal = FALSE) {
  net <- xnet(net, substitute(net))
  direction <- match_direction(direction, c("out", "in", "both", "reciprocated",
                                            "equal"), "xvaluedtiecomposition()")
  op <- match_op(op, "xvaluedtiecomposition()")
  rel <- ego_relation(net, relation, "xvaluedtiecomposition()")
  m <- rel$m
  n <- nrow(m)
  tie <- is_tie_matrix(m, op, cutoff)

  cols <- c("# of ties", "Sum of values", "Mean", "Std Dev", "Min", "Max",
            "Range")
  out <- matrix(NA_real_, n, length(cols),
                dimnames = list(rownames(m), cols))
  for (i in seq_len(n)) {
    others <- if (diagonal) seq_len(n) else seq_len(n)[-i]
    v <- ego_tie_values(m, tie, i, others, direction)
    out[i, ] <- univariate(v)
  }

  new_xucinet_output(
    "Egonet Valued Tie Composition Measures", net,
    nodes = as.data.frame(out, check.names = FALSE),
    assumptions = c(rel$note,
                    "The program assumes all non-zero values are ties."),
    fields = c("Which ties define egonet?" = ego_direction_labels[[direction]],
               "Valid ties operator:" = tie_op_labels[[op]],
               "Valid ties value:" = format(cutoff),
               "Include ties to self?" = if (diagonal) "YES" else "NO"),
    subclass = "xvaluedtiecomposition", call = match.call())
}

# Every relation of the dataset as a named list of matrices.
relation_list <- function(net) {
  d <- net$data
  if (is.list(d)) return(d)
  stats::setNames(list(d), net$title)
}

# addmat, for one relation: a count per ego.
ego_tie_counts <- function(m, tie, direction, diagonal) {
  n <- nrow(m)
  keep <- if (diagonal) matrix(TRUE, n, n) else row(tie) != col(tie)
  tt <- t(tie)
  same <- abs(m - t(m)) < 1e-6
  same[is.na(same)] <- FALSE
  x <- switch(direction,
              both = tie + tt,
              undirected = tie | tt,
              out = tie,
              `in` = tt,
              reciprocated = tie & tt,
              equal = tie & tt & same)
  rowSums(x * keep)
}

# analyzer, for one ego: the values that go into its statistics.
ego_tie_values <- function(m, tie, i, others, direction) {
  out_ok <- tie[i, others]
  in_ok <- tie[others, i]
  xo <- m[i, others]
  xi <- m[others, i]
  switch(direction,
         out = xo[out_ok],
         `in` = xi[in_ok],
         both = c(xo[out_ok], xi[in_ok]),
         reciprocated = as.vector(rbind(xo, xi)[, out_ok & in_ok]),
         equal = {
           ok <- out_ok & in_ok & abs(xo - xi) < 1e-6
           as.vector(rbind(xo, xi)[, ok])
         })
}

# tunivariate.calc: n, sum, mean, population sd, min, max, range. Empty gives a
# count of 0 and missing for the rest.
univariate <- function(v) {
  v <- v[!is.na(v)]
  k <- length(v)
  if (k == 0L) return(c(0, rep(NA_real_, 6)))
  mu <- mean(v)
  c(k, sum(v), mu, sqrt(sum((v - mu)^2) / k), min(v), max(v), max(v) - min(v))
}
