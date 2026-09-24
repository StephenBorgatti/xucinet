# QAP correlation.
#
# UCINET: Tools | Testing Hypotheses | Dyadic (QAP) | QAP Correlation
# (uc_qapcorrdlg.pas, Tqapcorrdlg.run; repository StephenBorgatti/ucinet at
# commit c7b4956), with G1Tools/utqapsim.pas (tqapsim.runpermutations and
# getmeasures) and G1Tools/utsim.pas (tsim; repository StephenBorgatti/tools
# at commit 207958a).
#
# Dialog defaults: 5000 permutations, 2-tailed, analysis type "Fast" (Pearson
# only, no missing values). The "Detailed" type computes all seven of tsim's
# measures with missing cells deleted pairwise; xqap() always does that, and
# its Pearson is the Fast one's whenever there is nothing missing (design
# answer 14.3). Only the lower triangle is used when both matrices are
# symmetric; the diagonal never. Distances (Euclidean, Hamming) are tested in
# the lower tail, as the unit does; the rest by `tails`.
#
# tsim.calc: correlation with population moments, NA when a variance is zero;
# Goodman-Kruskal gamma (a d - b c)/(a d + b c) on presence (0 when the
# denominator is 0); Jaccard a/(a+b+c) (0 when empty); match proportion;
# Hamming proportion; Euclidean sqrt(sum sq diff) (0 when 0); Hubert's gamma
# the sum of cross-products.

qap_measure_names <- c("Pearson Correlation", "Euclidean Distance",
                       "Hamming Distance", "Match Coef", "Jaccard Coef",
                       "Goodman-Kruskal Gamma", "Hubert Gamma")

#' QAP correlation
#'
#' UCINET: Tools | Testing Hypotheses | Dyadic (QAP) | QAP Correlation. How
#' strongly two networks on the same nodes go together, cell by cell, with a
#' p-value from the quadratic assignment procedure: the rows and columns of
#' one network are permuted together, many times, and the observed association
#' is compared with the permuted ones. Permuting whole nodes keeps each
#' network's structure intact, which is why QAP, unlike a test on the
#' vectorized cells, is valid for network data (book, 14.5.1).
#'
#' Seven measures are reported, as UCINET's detailed analysis does: Pearson
#' correlation, Euclidean and Hamming distance, the match and Jaccard
#' coefficients, Goodman-Kruskal gamma and Hubert's gamma. The diagonal is
#' left out, only one triangle is used when both networks are symmetric, and a
#' cell missing in either network is dropped.
#'
#' @section UCINET equivalent:
#' Tools | Testing Hypotheses | Dyadic (QAP) | QAP Correlation, *Type of
#' analysis* Detailed. *Number of permutations* is `nperm`, *Tails* is
#' `tails`.
#'
#' @param net1,net2 Two networks (any accepted form) on the same nodes, in the
#'   same order.
#' @param nperm Number of random permutations. UCINET's default is 5000.
#' @param seed Random seed.
#' @param tails 2 (the default) or 1.
#' @return An object of class `c("xqap", "xucinet_output")` whose `$matrices`
#'   holds the QAP results: for each measure the observed value, its
#'   significance, the mean, standard deviation, minimum and maximum over the
#'   permutations, the three proportions and the number of cells.
#' @seealso [xmrqap()], [xcorrelation()].
#' @examples
#' xqap(as.matrix(padgett, relation = 1), as.matrix(padgett, relation = 2),
#'      nperm = 1000, seed = 1)
#' @export
xqap <- function(net1, net2, nperm = 5000, seed = NULL, tails = 2) {
  tails <- check_tails(tails)
  n1 <- xnet(net1, substitute(net1)); n2 <- xnet(net2, substitute(net2))
  a <- as.matrix(n1); b <- as.matrix(n2)
  if (nrow(a) != ncol(a) || nrow(b) != ncol(b)) {
    stop("xqap(): the QAP technique needs square matrices.", call. = FALSE)
  }
  if (!identical(dim(a), dim(b))) {
    stop("xqap(): the two networks are not the same size.", call. = FALSE)
  }
  n <- nrow(a)
  sym <- isSymmetric(unname(a)) && isSymmetric(unname(b))
  cells <- qap_cells(n, sym)
  av <- a[cells]
  stat <- function(p) qap_measures(av, b[p, p][cells])

  res <- perm_test(stat, n, nperm, seed, tails)
  # Distances are tested in the lower tail whatever the tails setting.
  res$sig[2:3] <- res$le[2:3]
  nobs <- sum(!is.na(av) & !is.na(b[cells]))

  tab <- cbind(`Obs Value` = res$observed, Significance = res$sig,
               Average = res$mean, `Std Dev` = res$sd, Minimum = res$min,
               Maximum = res$max, `Prop >= Obs` = res$ge,
               `Prop <= Obs` = res$le, `N Obs` = nobs,
               `Prop |perm|>=|obs|` = res$ext)
  rownames(tab) <- qap_measure_names
  title <- sprintf("QAP results for %s * %s (%d permutations, %d-tailed)",
                   n1$title, n2$title, as.integer(nperm), tails)

  new_xucinet_output(
    "QAP Correlation", n1,
    matrices = stats::setNames(list(tab), title),
    summary = list(`Pearson Correlation` = res$observed[1],
                   Significance = res$sig[1], `N Obs` = nobs),
    show_summary = character(0),
    assumptions = c(
      if (sym) "Both matrices symmetric: the lower triangle is used.",
      if (nobs < length(cells)) sprintf("%d cells missing in either matrix, dropped.",
                                        length(cells) - nobs)),
    fields = c("Data Matrices:" = paste(n1$title, n2$title, sep = ", "),
               "# of Permutations:" = format(nperm),
               "Random seed:" = if (is.null(seed)) "(R session)" else format(seed),
               "Tails:" = if (tails == 2) "2-tailed (|perm| >= |obs|)"
                          else "1-tailed"),
    subclass = "xqap", call = match.call())
}

# tsim.addcase / calc on the cells present in both vectors.
qap_measures <- function(x, y) {
  ok <- !is.na(x) & !is.na(y)
  x <- x[ok]; y <- y[ok]
  n <- length(x)
  if (n < 1) return(rep(NA_real_, 7))
  vx <- mean((x - mean(x))^2); vy <- mean((y - mean(y))^2)
  r <- if (vx < 1e-7 || vy < 1e-7) NA_real_ else
    mean((x - mean(x)) * (y - mean(y))) / sqrt(vx * vy)
  px <- abs(x) > 1e-12; py <- abs(y) > 1e-12
  a <- sum(px & py); b <- sum(px & !py); c <- sum(!px & py); d <- sum(!px & !py)
  gk <- if (a * d + b * c > 0) (a * d - b * c) / (a * d + b * c) else 0
  jac <- if (a + b + c > 0) a / (a + b + c) else 0
  euc <- sqrt(sum((x - y)^2))
  c(r, euc, sum(x != y) / n, sum(x == y) / n, jac, gk, sum(x * y))
}
