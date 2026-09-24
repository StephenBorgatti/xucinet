# Affiliations: 2-mode to 1-mode.
#
# UCINET: Data | Affiliations (2-mode to 1-mode) (uc_AffiliationsDlg.pas,
# TAffiliationsDlg.run; repository StephenBorgatti/ucinet at commit c7b4956),
# with the measures in G2Tools/ug2simdis.pas (repository StephenBorgatti/tools
# at commit 207958a). Transform | Legacy routines | Affiliations runs the older
# TwoMode2OneMode and is not followed.
#
# Dialog defaults: Mode Rows, Method "Sums of cross-products (overlaps)",
# opposite-mode normalization None, recode missing values to zeros checked.
# Every relation of the dataset is projected. The result is saved as the input
# name followed by the mode, with no separator (outfile(inputfn, 'Rows')), so
# davis gives davisRows.
#
# The measures, per pair of rows (or columns), x and y, over the cells where
# both are present:
#   crossproduct   sum x*y                        (SSCP; the diagonal is the
#                                                  row's sum of squares)
#   min            sum min(x, y)                  (sumcrossmin)
#   covariance     sum (x - mean x)(y - mean y) / n    UCINET issue 30: the
#                  unit returns the sum without dividing by n
#   correlation    Pearson; 0 when one vector is constant, 1 when both are
#   matches        proportion of equal cells
#   jaccard        a / (a + b + c) on presence
#   identity       2 sum xy / (sum x^2 + sum y^2)
#   bonacich       Bonacich (1972): (n11 n22 - sqrt(n11 n22 n12 n21)) /
#                  (n11 n22 - n12 n21), 0.5 when the two products are equal
#   maxmin         the largest min(x, y)
#   crossproductmin  sum x*y / min(sum x, sum y)
#   ssd            sum of squared differences
#   cosine         sum xy / sqrt(sum x^2 sum y^2); 0 / 1 as correlation
# The dialog's thirteenth method, the SDSM backbone, is a statistical model
# rather than a similarity and is not ported.
#
# Opposite-mode normalization (tsmat.normcols / normrows): each column (for
# rows) is divided by its sum before the projection; a column summing to zero
# becomes missing.

affiliation_methods <- c(
  crossproduct = "Sums of cross-products (overlaps)",
  min = "Sums of cross-minimums",
  covariance = "Covariance",
  correlation = "Correlation",
  matches = "Matches (counts of same values)",
  jaccard = "Jaccard (positive matches)",
  identity = "Identity coefficient",
  bonacich = "Bonacich '72",
  maxmin = "Max of cross-minimums",
  crossproductmin = "Sum(xi*yi)/Min(x+,y+)",
  ssd = "Sum of squared differences",
  cosine = "Cosine similarity (congruence)")

#' Affiliations: from 2-mode to 1-mode
#'
#' UCINET: Data | Affiliations (2-mode to 1-mode). Turns a 2-mode network,
#' such as women by the events they attended, into a 1-mode network of the
#' rows (women by women) or of the columns (events by events). With the
#' default, the value for a pair of women is the number of events both
#' attended, and a woman's diagonal cell is the number she attended.
#'
#' @section UCINET equivalent:
#' Data | Affiliations (2-mode to 1-mode). *Mode* is `mode`, *Method* is
#' `method`, *Opposite mode normalization* is `normalize`, *Recode missing
#' values to zeros* is `recode`. The Backbone (SDSM) method is not offered.
#'
#' @param net A 2-mode network (any accepted form); a 1-mode network is
#'   projected the same way, row by row.
#' @param mode `"rows"` (the default) or `"cols"`.
#' @param method How a pair is compared: `"crossproduct"` (the default, the
#'   number of shared ties for binary data), `"min"`, `"covariance"`,
#'   `"correlation"`, `"matches"`, `"jaccard"`, `"identity"`, `"bonacich"`,
#'   `"maxmin"`, `"crossproductmin"`, `"ssd"` or `"cosine"`.
#' @param normalize Weight the opposite mode inversely by its totals first?
#'   `FALSE` by default.
#' @param recode Recode missing values to 0 first? `TRUE` by default, as in
#'   the dialog.
#' @return An `xucinet` object: a 1-mode, undirected, valued network, titled
#'   as UCINET names it (`davisRows`), with a `history` attribute.
#' @seealso [xbipartite()], [xsimilarities()].
#' @examples
#' xaffiliations(davis)
#' xaffiliations(davis, mode = "cols")
#' @export
xaffiliations <- function(net, mode = c("rows", "cols"),
                          method = c("crossproduct", "min", "covariance",
                                     "correlation", "matches", "jaccard",
                                     "identity", "bonacich", "maxmin",
                                     "crossproductmin", "ssd", "cosine"),
                          normalize = FALSE, recode = TRUE) {
  net <- xnet(net, substitute(net))
  mode <- match.arg(mode)
  method <- match.arg(method)
  notes <- character()

  project <- function(m) {
    if (mode == "cols") m <- t(m)
    if (isTRUE(recode) && anyNA(m)) {
      notes <<- c(notes, sprintf("%d missing values recoded to zeros.", sum(is.na(m))))
      m[is.na(m)] <- 0
    }
    if (isTRUE(normalize)) {
      # normcols on the rows' matrix: the opposite mode is the columns here.
      tot <- colSums(m, na.rm = TRUE)
      m <- sweep(m, 2, tot, "/")
      m[, abs(tot) < 1e-7] <- NA
    }
    k <- nrow(m)
    r <- matrix(NA_real_, k, k, dimnames = list(rownames(m), rownames(m)))
    for (i in seq_len(k)) {
      for (j in seq_len(i)) {
        r[i, j] <- r[j, i] <- affiliation_pair(m[i, ], m[j, ], method)
      }
    }
    r
  }

  out <- map_relations(net, project)
  out$mode <- "1-mode"
  out$directed <- FALSE
  out <- transformed(out, if (mode == "rows") "Rows" else "Columns",
                     paste0("affiliations of the ", mode, " (",
                            affiliation_methods[[method]],
                            if (isTRUE(normalize)) ", opposite mode normalized" else "",
                            ")"))
  if (length(notes)) {
    attr(out, "history") <- c(attr(out, "history"), unique(notes))
  }
  out
}

# One pair, as the ug2simdis procedure of the same name computes it.
affiliation_pair <- function(x, y, method) {
  n <- length(x)
  ok <- !is.na(x) & !is.na(y)
  num <- sum(ok)
  if (num == 0 && method != "ssd" && method != "bonacich") return(NA_real_)
  xo <- x[ok]; yo <- y[ok]
  tiny <- 1e-7
  switch(method,
    crossproduct = sum(xo * yo),
    min = sum(pmin(xo, yo)),
    covariance = sum((xo - mean(xo)) * (yo - mean(yo))) / num,
    correlation = {
      sx <- sum((xo - mean(xo))^2); sy <- sum((yo - mean(yo))^2)
      if (xor(sx < tiny, sy < tiny)) 0 else if (sx < tiny) 1 else
        sum((xo - mean(xo)) * (yo - mean(yo))) / sqrt(sx * sy)
    },
    matches = sum(xo == yo) / num,
    jaccard = {
      either <- xo > 0 | yo > 0
      if (any(either)) sum(xo > 0 & yo > 0) / sum(either) else NA_real_
    },
    identity = {
      s <- sum(xo^2) + sum(yo^2)
      if (s > 0) 2 * sum(xo * yo) / s else NA_real_
    },
    bonacich = {
      # sscp over the cells present; n is the full length, as in the unit
      n11 <- sum(xo * yo); xx <- sum(x[!is.na(x)]^2); yy <- sum(y[!is.na(y)]^2)
      n12 <- xx - n11; n21 <- yy - n11; n22 <- n - (n11 + n12 + n21)
      a <- n11 * n22; b <- n12 * n21
      if (a < 0 || b < 0) NA_real_
      else if (isTRUE(all.equal(a, b))) 0.5
      else (a - sqrt(a * b)) / (a - b)
    },
    maxmin = max(pmin(xo, yo)),
    crossproductmin = {
      mn <- min(sum(xo), sum(yo))
      if (abs(mn) < tiny) NA_real_ else sum(xo * yo) / mn
    },
    ssd = sum((xo - yo)^2),
    cosine = {
      sx <- sum(xo^2); sy <- sum(yo^2)
      if (xor(sx < tiny, sy < tiny)) 0 else if (sx < tiny) 1 else
        sum(xo * yo) / sqrt(sx * sy)
    })
}
