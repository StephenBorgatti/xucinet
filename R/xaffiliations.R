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
#   sdsm           Neal's stochastic degree sequence model backbone: 1 where the
#                  pair co-occurs significantly more than chance (see below)
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
  cosine = "Cosine similarity (congruence)",
  sdsm = "Backbone (SDSM)")

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
#' values to zeros* is `recode`, *SDSM null model* is `nullmodel`, *Alpha* is
#' `alpha`.
#'
#' `method = "sdsm"` extracts the backbone of the projection by Neal's (2014)
#' stochastic degree sequence model: two rows are tied (1) when they share more
#' columns than a null model that keeps the degrees would produce, at
#' significance `alpha` (one-tailed, exact Poisson-binomial test). The null
#' model is a logistic regression on the row and column degrees (the default,
#' as in the R package backbone) or the bipartite configuration model. The data
#' are read as binary, and `normalize` does not apply. The fit is recorded in the
#' result's `history`.
#'
#' @param net A 2-mode network (any accepted form); a 1-mode network is
#'   projected the same way, row by row.
#' @param mode `"rows"` (the default) or `"cols"`.
#' @param method How a pair is compared: `"crossproduct"` (the default, the
#'   number of shared ties for binary data), `"min"`, `"covariance"`,
#'   `"correlation"`, `"matches"`, `"jaccard"`, `"identity"`, `"bonacich"`,
#'   `"maxmin"`, `"crossproductmin"`, `"ssd"`, `"cosine"` or `"sdsm"` (the
#'   backbone; see Details).
#' @param normalize Weight the opposite mode inversely by its totals first?
#'   `FALSE` by default.
#' @param recode Recode missing values to 0 first? `TRUE` by default, as in
#'   the dialog.
#' @param nullmodel For `method = "sdsm"`: `"logistic"` (the default) or
#'   `"bicm"`.
#' @param alpha For `method = "sdsm"`: the one-tailed significance level, 0.05
#'   by default.
#' @return An `xucinet` object: a 1-mode, undirected, valued network, titled
#'   as UCINET names it (`davisRows`), with a `history` attribute. The SDSM
#'   backbone is binary.
#' @seealso [xbipartite()], [xsimilarities()].
#' @examples
#' xaffiliations(davis)
#' xaffiliations(davis, mode = "cols")
#' xaffiliations(davis, method = "sdsm")
#' @export
xaffiliations <- function(net, mode = c("rows", "cols"),
                          method = c("crossproduct", "min", "covariance",
                                     "correlation", "matches", "jaccard",
                                     "identity", "bonacich", "maxmin",
                                     "crossproductmin", "ssd", "cosine", "sdsm"),
                          normalize = FALSE, recode = TRUE,
                          nullmodel = c("logistic", "bicm"), alpha = 0.05) {
  net <- xnet(net, substitute(net))
  mode <- match.arg(mode)
  method <- match.arg(method)
  nullmodel <- match.arg(nullmodel)
  notes <- character()

  project <- function(m) {
    if (mode == "cols") m <- t(m)
    if (method == "sdsm") {
      # runbackbonesdsm: missing cells count as 0 inside the unit, and the
      # opposite-mode normalization does not apply.
      res <- sdsm_backbone(m, nullmodel, alpha)
      notes <<- c(notes, res$stats)
      return(res$backbone)
    }
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
                            if (isTRUE(normalize) && method != "sdsm") ", opposite mode normalized" else "",
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

# ---- SDSM backbone: G2Tools/usdsm.pas ------------------------------------------
#
# Neal's (2014) stochastic degree sequence model. The 2-mode matrix is read as
# binary (a missing cell or a zero is 0; the unit ignores recode and the
# opposite-mode normalization). Each cell gets a probability under a null model
# that keeps the degrees in expectation:
#   logistic  logit p[i,k] = b0 + b1 R[i] + b2 C[k], fitted over all cells by
#             Newton-Raphson from zero, the linear predictor clamped at +-30,
#             stopping when no coefficient moves by 1e-8 (SolveLogitSDSM; what
#             backbone::sdsm() fits by default)
#   bicm      the bipartite configuration model, p = x y / (1 + x y), by
#             SolveBiCM's fixed point (tolerance 1e-8, 2000 iterations), rows
#             and columns of degree 0 or full pinned at p = 0 or 1
# A pair's co-occurrences are then a sum of Bernoulli(p[i,k] p[j,k]) over the
# other mode; the exact Poisson-binomial upper tail P(S >= observed) is the
# p-value, and the pair is tied (1) when it is below alpha. The diagonal is 0.

sdsm_backbone <- function(m, nullmodel, alpha) {
  if (!(alpha > 0 && alpha < 1)) {
    stop("xaffiliations(): alpha must be between 0 and 1.", call. = FALSE)
  }
  b <- (!is.na(m) & m != 0) * 1
  nr <- nrow(b); nc <- ncol(b)
  R <- rowSums(b); C <- colSums(b)
  info <- list(iterations = 0L, converged = TRUE, b = c(0, 0, 0))
  P <- matrix(0, nr, nc)
  if (any(b > 0)) {
    if (nullmodel == "logistic") {
      fit <- sdsm_logit(b, R, C)
      eta <- pmin(pmax(fit$b[1] + outer(fit$b[2] * R, fit$b[3] * C, "+"), -30), 30)
      P <- 1 / (1 + exp(-eta))
    } else {
      fit <- sdsm_bicm(R, C)
      xy <- outer(fit$x, fit$y)
      P <- ifelse(outer(fit$x <= 0, fit$y <= 0, "|"), 0,
                  ifelse(outer(fit$x >= 1e12, fit$y >= 1e12, "|"), 1,
                         xy / (1 + xy)))
    }
    info <- fit[c("iterations", "converged", "b")]
  }

  out <- matrix(0, nr, nr, dimnames = list(rownames(m), rownames(m)))
  if (nr >= 2 && any(b > 0)) {
    pairs <- which(upper.tri(out), arr.ind = TRUE)
    obs <- rowSums(b[pairs[, 1], , drop = FALSE] * b[pairs[, 2], , drop = FALSE])
    q <- P[pairs[, 1], , drop = FALSE] * P[pairs[, 2], , drop = FALSE]
    pval <- poisson_binomial_upper(obs, q)
    keep <- pairs[pval < alpha, , drop = FALSE]
    out[keep] <- 1
    out[keep[, 2:1, drop = FALSE]] <- 1
  }
  npairs <- nr * (nr - 1) / 2
  signif <- sum(out[upper.tri(out)])
  stats <- c(
    sprintf("SDSM null model: %s", if (nullmodel == "logistic")
      "Logistic SDSM (logit p = b0 + b1*R + b2*C)" else "BiCM (bipartite configuration model)"),
    sprintf("Alpha (one-tailed): %s", format(alpha)),
    sprintf("Pairs tested: %d; significant edges retained: %d (%.2f%%)",
            as.integer(npairs), as.integer(signif),
            if (npairs > 0) 100 * signif / npairs else 0),
    if (nullmodel == "logistic") sprintf(
      "Logit b0 = %.4f, b1 (row degree) = %.4f, b2 (column degree) = %.4f",
      info$b[1], info$b[2], info$b[3]),
    sprintf("%s iterations: %d; converged: %s",
            if (nullmodel == "logistic") "IRLS" else "BiCM",
            as.integer(info$iterations), if (info$converged) "yes" else "NO"))
  list(backbone = out, stats = stats)
}

# SolveLogitSDSM: Newton-Raphson on the three coefficients.
sdsm_logit <- function(b, R, C, maxit = 100L, tol = 1e-8) {
  y <- as.vector(b)
  X <- cbind(1, rep(R, times = ncol(b)), rep(C, each = nrow(b)))
  beta <- c(0, 0, 0)
  converged <- FALSE
  iterations <- 0L
  for (it in seq_len(maxit)) {
    eta <- pmin(pmax(drop(X %*% beta), -30), 30)
    p <- 1 / (1 + exp(-eta))
    w <- p * (1 - p)
    g <- drop(crossprod(X, y - p))
    H <- crossprod(X, X * w)
    delta <- tryCatch(solve(H, g), error = function(e) NULL)
    if (is.null(delta)) break                 # singular: keep the current betas
    beta <- beta + delta
    iterations <- it
    if (max(abs(delta)) < tol) { converged <- TRUE; break }
  }
  list(b = beta, iterations = iterations, converged = converged)
}

# SolveBiCM: the fixed point for the row and column fitnesses.
sdsm_bicm <- function(R, C, maxit = 2000L, tol = 1e-8) {
  nr <- length(R); nc <- length(C)
  big <- 1e12
  M <- sum(R)
  x <- ifelse(R <= 0, 0, ifelse(R >= nc, big, if (M > 0) R / sqrt(M) else 1))
  y <- ifelse(C <= 0, 0, ifelse(C >= nr, big, if (M > 0) C / sqrt(M) else 1))
  px <- R <= 0 | R >= nc
  py <- C <= 0 | C >= nr
  term <- function(a, other) {
    # sum over the other side of other / (1 + a * other), with the pinned ends
    vapply(a, function(ai) {
      live <- other > 0 & other < big
      s <- sum(other[live] / (1 + ai * other[live]))
      if (ai > 0) s <- s + sum(other >= big) / ai
      s
    }, numeric(1))
  }
  converged <- FALSE
  iterations <- 0L
  for (it in seq_len(maxit)) {
    dx <- term(x, y)
    nx <- ifelse(px, x, ifelse(dx > 0, R / dx, x))
    dy <- term(y, nx)
    ny <- ifelse(py, y, ifelse(dy > 0, C / dy, y))
    change <- max(c(abs(nx - x)[!px], abs(ny - y)[!py], 0))
    x <- nx; y <- ny
    iterations <- it
    if (change < tol) { converged <- TRUE; break }
  }
  list(x = x, y = y, iterations = iterations, converged = converged,
       b = c(NA_real_, NA_real_, NA_real_))
}

# PoissonBinomialUpperTailP for many pairs at once: row p of q holds the
# Bernoulli probabilities for pair p, obs[p] the observed count.
poisson_binomial_upper <- function(obs, q, chunk = 20000L) {
  np <- nrow(q); nq <- ncol(q)
  out <- numeric(np)
  for (start in seq(1L, np, by = chunk)) {
    idx <- start:min(np, start + chunk - 1L)
    qq <- pmin(pmax(q[idx, , drop = FALSE], 0), 1)
    prob <- matrix(0, length(idx), nq + 1L)
    prob[, 1] <- 1
    for (k in seq_len(nq)) {
      qk <- qq[, k]
      s <- seq_len(k + 1L)
      shifted <- cbind(0, prob[, s[-length(s)], drop = FALSE])
      prob[, s] <- shifted * qk + prob[, s, drop = FALSE] * (1 - qk)
    }
    o <- obs[idx]
    tail <- vapply(seq_along(idx), function(r) {
      if (o[r] <= 0) return(1)
      if (o[r] > nq) return(0)
      sum(prob[r, (o[r] + 1L):(nq + 1L)])
    }, numeric(1))
    out[idx] <- pmin(pmax(tail, 0), 1)
  }
  out
}
