# Ego-alter similarity, categorical and continuous.
#
# UCINET: Network | Ego Networks | Ego-Alter Similarity (e.g. Homophily) |
# Categorical, the form uc_EgoNetHomophily.pas (tegonethomophily.run,
# massagematrix) with the measures in G1Tools/utindividualhomophily.pas
# (tindividualhomophily: addcase, calc, calckappa, copymeasures); and ... |
# Continuous, the form uc_EgoNetHomophilyCont.pas (tegonethomophilycont.run)
# with G2Tools/utindividualhomophilycont.pas, the Pearson correlation in
# G2Tools/utcorr.pas (tcorr.addcase, calc), the attribute normalizations in
# G2Tools/uNormalize.pas (normvec) and the similarity functions in
# G1Tools/umath.pas (fzegers, fminovermaxh, fabsdiff, fsqrdiff, fprod,
# fnegabsdiff). Repositories StephenBorgatti/ucinet at commit c7b4956 and
# StephenBorgatti/tools at commit 207958a.
#
# Dialog defaults: Definition of Ego Network = Outgoing ties only (ItemIndex 1)
# in both; the continuous form ticks only the last measure, -AbsDiff
# (FormCreate: measures.Checked[5] := true), with Attribute Normalization =
# None.

#' Ego-alter similarity
#'
#' UCINET: Network | Ego Networks | Ego-Alter Similarity, both the Categorical
#' and the Continuous item, as one function. For each ego, whether it is tied
#' to others who resemble it on an attribute: homophily at the level of the
#' individual.
#'
#' `type` decides which, as in [xaltercomposition()]: character, factor and
#' logical attributes are categorical, numbers continuous, and a numeric
#' attribute that looks like category codes is noted but still treated as
#' continuous unless `type = "categorical"`.
#'
#' **Categorical.** Every other node is either tied to ego or not, and either
#' in ego's category or not, which gives a two-by-two table per ego: `a` tied
#' and same, `b` tied and different, `c` untied and same, `d` untied and
#' different. The network is dichotomized at > 0. The columns are `H` (the
#' proportion of ego's ties that are in its own group, `a/(a+b)`), `H*` (H
#' less the proportion of all others in ego's group), `Coleman` (H* rescaled
#' by its maximum), `EI` (`(b-a)/(a+b)`), `Jaccard`, `Yules Q`, `Kappa`,
#' `Phi`, `Bona` (Bonacich's 1972 measure), `Odds_Ratio`, `Log_Odds`,
#' `fInGroup` (`a`) and `fOutGroup` (`b`), then ego's own value. An ego with no
#' ties has every measure missing.
#'
#' **Continuous.** For each ego, the correlation between its row of tie values
#' and the similarity of ego to each other node on the attribute. One column for
#' each of six measures, all always computed; `method` chooses which are
#' printed: `"negabsdiff"` (the dialog's default, minus the
#' absolute difference, so that higher is more similar), `"zegers"`
#' (`2xy/(x^2+y^2)`), `"minovermax"`, `"absdiff"`, `"sqdiff"` and `"product"`.
#' The two difference measures are reverse measures: a positive value means
#' ego is tied to people unlike itself.
#'
#' @section UCINET equivalent:
#' Network | Ego Networks | Ego-Alter Similarity | Categorical, and ... |
#' Continuous. *Definition of Ego Network* is `ties`; the continuous
#' dialog's *Measures* checklist is `method` and *Attribute Normalization* is
#' `normalize`.
#'
#' @inheritParams xaltercomposition
#' @param ties Which ties are ego's: `"out"` (the default, as in UCINET),
#'   `"any"` (a tie in either direction), `"in"` or `"reciprocated"`.
#' @param method Continuous only: which measures to print, one or more of
#'   `"negabsdiff"` (the default), `"zegers"`, `"minovermax"`, `"absdiff"`,
#'   `"sqdiff"`, `"product"`. All six are always computed.
#' @param normalize Continuous only: rescale the attribute first? `"none"` (the
#'   default), `"additive"` (subtract the mean), `"ratio"` (divide by the root
#'   of the sum of squared deviations) or `"interval"` (z-scores).
#' @return An object of class `c("xegoaltersimilarity", "xucinet_output")`
#'   with the measures in `$nodes`, in original node order.
#' @seealso [xhomophily()] for the whole-network measures, and
#'   [xaltercomposition()].
#' @examples
#' xegoaltersimilarity(campnet, camp92_attr$Gender, type = "categorical")
#' xegoaltersimilarity(hightech, "Age", data = hightech_attr)
#' @export
xegoaltersimilarity <- function(net, attribute, type = NULL, relation = NULL,
                                ties = c("out", "any", "in",
                                              "reciprocated"),
                                method = "negabsdiff",
                                normalize = c("none", "additive", "ratio",
                                              "interval"),
                                data = NULL) {
  net <- xnet(net, substitute(net))
  ties <- match_ties(ties, c("out", "any", "in",
                                            "reciprocated"),
                               "xegoaltersimilarity()")
  normalize <- match.arg(normalize)
  rel <- ego_relation(net, relation, "xegoaltersimilarity()")
  m <- rel$m
  n <- nrow(m)
  att <- ego_attribute(attribute, net, data, deparse1(substitute(attribute)), n,
                       "xegoaltersimilarity()")
  kind <- attribute_type(att$values, type, "xegoaltersimilarity()")
  assumptions <- c(rel$note, kind$note)
  x <- ego_rows(m, ties)
  dir_label <- c(any = "Both incoming and outgoing ties",
                 out = "Outgoing ties only", `in` = "Incoming ties only",
                 reciprocated = "Reciprocal ties only")[[ties]]

  if (kind$type == "categorical") {
    nodes <- similarity_categorical(x, att$values, att$name)
    rownames(nodes) <- rownames(m)
    new_xucinet_output(
      "Egonet Alter-Ego Similarity (e.g., homophily) for categorical attributes",
      net, nodes = nodes,
      assumptions = c(assumptions,
                      "This routine automatically dichotomizes the network data."),
      fields = c("Input Attribute:" = att$name, "Ego Network Type:" = dir_label),
      nodes_title = "Node-level alter-ego similarity",
      subclass = "xegoaltersimilarity", call = match.call())
  } else {
    meths <- similarity_methods()
    bad <- setdiff(method, names(meths))
    if (length(method) == 0L || length(bad)) {
      stop("xegoaltersimilarity(): method must be one or more of ",
           paste0("\"", names(meths), "\"", collapse = ", "), ".", call. = FALSE)
    }
    # The checklist's order, whatever order `method` gives them in.
    method <- names(meths)[names(meths) %in% method]
    a <- normalize_attribute_vec(as.numeric(att$values), normalize)
    # Every measure is computed; `method` chooses the columns printed (SPEC
    # addendum, 23 Sep 2026, item 5).
    nodes <- similarity_continuous(x, a, meths)
    shown <- vapply(meths[method], `[[`, character(1), "label")
    rownames(nodes) <- rownames(m)
    notes <- if (any(method %in% c("absdiff", "sqdiff"))) {
      c("The difference-based measures are reverse measures of ego-alter similarity or homophily.",
        "Positive values indicate ego-alter dissimilarity or heterophily.")
    }
    new_xucinet_output(
      "Egonet Alter-Ego Similarity (e.g., homophily)", net,
      nodes = nodes, assumptions = c(assumptions, notes),
      fields = c("Input Attribute:" = att$name, "Ego Network Type:" = dir_label,
                 "Measures:" = paste(vapply(meths[method], `[[`, character(1),
                                            "label"), collapse = ", "),
                 "Normalization:" = c(none = "None",
                                      additive = "Additive (mean-center)",
                                      ratio = "Ratio (mean ssq))",
                                      interval = "Interval (z-score)")[[normalize]]),
      nodes_title = "Node-level alter-ego similarity",
      show_columns = unname(shown),
      subclass = "xegoaltersimilarity", call = match.call())
  }
}

# tegonethomophily.run and tindividualhomophily. Every other node with a valid
# cell and a valid attribute value is a case; the tie is x > 0.
similarity_categorical <- function(x, values, name) {
  n <- nrow(x)
  cats <- category_keys(values)
  g <- cats$codes
  labs <- c("H", "H*", "Coleman", "EI", "Jaccard", "Yules Q", "Kappa", "Phi",
            "Bona", "Odds_Ratio", "Log_Odds", "fInGroup", "fOutGroup")
  out <- matrix(NA_real_, n, length(labs) + 1,
                dimnames = list(NULL, c(labs, name)))
  for (i in seq_len(n)) {
    if (is.na(g[i])) next                     # `if attr.isna(i) then continue`
    js <- which(seq_len(n) != i & !is.na(x[i, ]) & !is.na(g))
    tie <- x[i, js] > 0
    same <- g[js] == g[i]
    out[i, seq_along(labs)] <- individual_homophily(
      sum(tie & same), sum(tie & !same), sum(!tie & same), sum(!tie & !same))
    out[i, length(labs) + 1] <- if (is.numeric(values)) values[i] else g[i]
  }
  as.data.frame(out, check.names = FALSE)
}

# tindividualhomophily.calc, with calckappa. Nothing is computed unless ego
# has a tie; each measure is missing where its own denominator vanishes.
individual_homophily <- function(a, b, c, d) {
  out <- rep(NA_real_, 13)
  n <- a + b + c + d
  if (a + b == 0) return(out)
  ad <- a * d
  bc <- b * c
  h <- a / (a + b)
  hexp <- (a + c) / n
  hstar <- h - hexp
  coleman <- if (h >= hexp) hstar / (1 - hexp) else hstar / hexp
  ei <- (b - a) / (a + b)
  jac <- if (a + b + c > 0) a / (a + b + c) else NA_real_
  odds <- logodds <- NA_real_
  if (bc > 0 && ad > 0) {
    odds <- ad / bc
    logodds <- log(odds)
  }
  yules <- if (ad + bc > 0) (ad - bc) / (ad + bc) else NA_real_
  bona <- if (abs(ad - bc) > 1e-12) (ad - sqrt(a * b * c * d)) / (ad - bc)
          else NA_real_
  # calckappa
  g1 <- a + b; g2 <- c + d; f1 <- a + c; f2 <- b + d
  o <- a / n
  e <- g1 * f1 / n^2
  mx <- min(g1, f1) / n
  kappa <- if (e < 1) (o - e) / (mx - e) else NA_real_
  den <- f1 * f2 * g1 * g2
  phi <- if (den > 0) (ad - bc) / sqrt(den) else NA_real_
  out <- c(h, hstar, coleman, ei, jac, yules, kappa, phi, bona, odds, logodds,
           a, b)
  out[!is.finite(out)] <- NA_real_
  out + 0                                      # -0 prints as -0.000
}

# The six measures of the continuous dialog, in its order, with the heading
# UCINET takes from each item (the text before the colon).
similarity_methods <- function() {
  list(
    zegers = list(label = "Zegers", f = function(x, y) {
      s <- x^2 + y^2
      ifelse(abs(s) > 1e-12, 2 * x * y / s, NA_real_)
    }),
    minovermax = list(label = "MinOverMax", f = function(x, y) {
      # fminovermaxh: equal values are 1, and a zero is taken as 0.01.
      xx <- ifelse(abs(x) < 1e-12, 0.01, x)
      yy <- ifelse(abs(y) < 1e-12, 0.01, y)
      ifelse(abs(x - y) < 1e-12, 1, pmin(xx, yy) / pmax(xx, yy))
    }),
    absdiff = list(label = "Absolute difference", f = function(x, y) abs(x - y)),
    sqdiff = list(label = "Difference Squared", f = function(x, y) (x - y)^2),
    product = list(label = "Product", f = function(x, y) x * y),
    negabsdiff = list(label = "-AbsDiff", f = function(x, y) -abs(x - y)))
}

# normvec: additive subtracts the mean; ratio divides by the root of the
# mean-centred sum of squares without centring; interval gives z-scores with
# the population standard deviation, and is skipped when that is 0.
normalize_attribute_vec <- function(a, method) {
  v <- a[!is.na(a)]
  if (!length(v)) return(a)
  mu <- mean(v)
  mcssq <- sum((v - mu)^2)
  switch(method,
         none = a,
         additive = a - mu,
         ratio = if (sqrt(mcssq) > 1e-12) a / sqrt(mcssq) else a,
         interval = {
           sd <- sqrt(mcssq / length(v))
           if (sd > 1e-12) (a - mu) / sd else a
         })
}

# For each ego, Pearson's r between the tie values and the similarities over
# every other node where both are present (tcorr, population moments, missing
# when either variance is effectively zero).
similarity_continuous <- function(x, a, meths) {
  n <- nrow(x)
  out <- matrix(NA_real_, n, length(meths),
                dimnames = list(NULL, vapply(meths, `[[`, character(1), "label")))
  for (k in seq_along(meths)) {
    f <- meths[[k]]$f
    for (i in seq_len(n)) {
      js <- seq_len(n)[-i]
      sim <- f(rep(a[i], length(js)), a[js])
      tie <- x[i, js]
      ok <- !is.na(sim) & !is.na(tie)
      out[i, k] <- pearson_pop(tie[ok], sim[ok])
    }
  }
  as.data.frame(out, check.names = FALSE)
}

pearson_pop <- function(x, y) {
  k <- length(x)
  if (k == 0L) return(NA_real_)
  mx <- mean(x); my <- mean(y)
  vx <- sum((x - mx)^2) / k
  vy <- sum((y - my)^2) / k
  if (vx < 1e-15 || vy < 1e-15) return(NA_real_)
  sum((x - mx) * (y - my)) / k / sqrt(vx * vy)
}
