# Filling in missing ties.
#
# Two UCINET routines, both from repository StephenBorgatti/ucinet at commit
# c7b4956:
#
#   ximpute          Transform | Znidarsic et al Imputation of Ties
#                    (uc_ImputeMissing.pas), algorithms in
#                    G2Tools/uimputemissing.pas, class timputation
#                    (repository StephenBorgatti/tools at commit 207958a)
#   xreplacemissing  Transform | Replace Missing Values (uc_replacena.pas)
#
# Dialog defaults, read from uc_ImputeMissing.dfm: method.ItemIndex = 3, so
# REMO; reoptions.ItemIndex = 0, so ties among missing respondents are zeroed;
# tmhowtoround.ItemIndex = 0, so rounding is half-up rather than to even.
#
# Every loop in timputation is `if i <> j`, and the diagonal is set missing
# before imputation, so a self-tie is never filled in.

#' Fill in missing ties
#'
#' UCINET: Transform | Znidarsic et al Imputation of Ties. Replaces missing
#' cells using the rest of the network.
#'
#' The diagonal is set missing first and is never imputed, as in UCINET.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param method How to impute. `"remo"` (the dialog's default) reconstructs
#'   from the transpose and then fills what is left with the modal incoming
#'   tie; `"re"` reconstructs only; `"mo"` uses the modal incoming tie, for
#'   binary data; `"mean"` the mean incoming tie, for valued data; `"tm"` the
#'   global mean; `"knn"` the median among the *k* nodes whose columns are
#'   most like the missing node's; `"nti"` puts `value` everywhere;
#'   `"random"` draws from the observed ties; `"copy"` uses what the node's
#'   own contacts said.
#' @param ties For `"re"` and `"remo"`, what to do with a pair that is missing
#'   both ways and so cannot be reconstructed: `"zero"` (the dialog's
#'   default), `"density"` (1 everywhere if the density reaches `cutoff`, 0
#'   otherwise), `"random"` (1 with probability equal to the density) or
#'   `"missing"` to leave it.
#' @param cutoff The density threshold for `ties = "density"`.
#' @param round Round the imputed value to a whole number, for `"mean"` and
#'   `"tm"`? Rounding is half-up, as the dialog's default is; UCINET's
#'   banker's-rounding option is not offered.
#' @param k Neighbours for `"knn"`.
#' @param value The value `"nti"` fills with.
#' @param seed Seed for the methods that draw at random.
#' @return An `xucinet` object titled `<name>-imp`, with a `history` attribute
#'   recording the method and how many cells were filled. The diagonal comes
#'   back missing.
#' @seealso [xreplacemissing()] to fill from another dataset instead.
#' @examples
#' m <- matrix(c(0,1,1, NA,0,1, 0,NA,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' as.matrix(ximpute(m))
#' as.matrix(ximpute(m, method = "re"))
#' @export
ximpute <- function(net,
                    method = c("remo", "re", "mo", "mean", "tm", "knn",
                               "nti", "random", "copy"),
                    ties = c("zero", "density", "random", "missing"),
                    cutoff = 0.5, round = TRUE, k = 3, value = 0,
                    seed = NULL) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  ties <- match.arg(ties)
  require_1mode(net, "ximpute()")
  if (!is.null(seed)) set.seed(seed)

  filled <- 0L
  out <- map_relations(net, function(m) {
    # "The diagonal is set to missing before imputation."
    diag(m) <- NA_real_
    y <- impute_matrix(m, method, ties, cutoff, round, k, value)
    off <- row(m) != col(m)
    filled <<- filled + sum(off & is.na(m) & !is.na(y))
    y
  })
  transformed(out, "-imp",
              paste0("imputed (", method, ", ", filled, " cell",
                     if (filled == 1) "" else "s", " filled)"))
}

impute_matrix <- function(m, method, ties, cutoff, round, k, value) {
  y <- m
  off <- row(m) != col(m)
  seen <- m[off & !is.na(m)]
  binary <- all(seen %in% c(0, 1))
  # A network with nothing observed off the diagonal has no density to work
  # from; treat it as zero rather than let NaN reach the comparisons.
  avg <- if (length(seen)) mean(seen) else 0

  y <- switch(
    method,
    re     = impute_re(m, ties, cutoff, avg),
    mo     = impute_column(m, "mode"),
    mean   = impute_column(m, "mean", round),
    remo   = impute_column(impute_re(m, ties, cutoff, avg), "mode"),
    tm     = impute_fill(m, if (round) round_half_up(avg) else avg),
    knn    = impute_knn(m, k),
    nti    = impute_fill(m, value),
    random = impute_random(m, binary, avg),
    copy   = impute_copy(m, binary))
  diag(y) <- NA_real_
  dimnames(y) <- dimnames(m)
  y
}

# UCINET rounds .5 away from zero; R's round() goes to even.
round_half_up <- function(x) {
  ifelse(is.na(x), x, floor(x + 0.5))
}

impute_fill <- function(m, v) {
  y <- m
  off <- row(m) != col(m)
  y[off & is.na(m)] <- v
  y
}

# reconstruction: take x[j,i] for a missing x[i,j], then deal with the pairs
# that are missing both ways.
impute_re <- function(m, ties, cutoff, avg) {
  y <- m
  off <- row(m) != col(m)
  from <- t(m)
  take <- off & is.na(m) & !is.na(from)
  y[take] <- from[take]

  left <- off & is.na(y)
  if (any(left)) {
    y[left] <- switch(ties,
                      zero    = 0,
                      density = if (avg >= cutoff) 1 else 0,
                      random  = stats::rbinom(sum(left), 1, min(max(avg, 0), 1)),
                      missing = NA_real_)
    if (identical(ties, "random") && isTRUE(isSymmetric(unname(m)))) {
      # `if sym then y.mirror(i,j)`: a symmetric network stays symmetric.
      y[lower.tri(y)] <- t(y)[lower.tri(y)]
    }
  }
  y
}

# meanincoming / modalincoming: the statistic of column j fills the missing
# cells of column j, because column j is what everyone said about j.
impute_column <- function(m, stat, round = FALSE) {
  y <- m
  off <- row(m) != col(m)
  stats_j <- vapply(seq_len(ncol(m)), function(j) {
    v <- m[, j][off[, j] & !is.na(m[, j])]
    if (!length(v)) return(NA_real_)
    if (identical(stat, "mean")) mean(v) else modal_value(v)
  }, numeric(1))
  if (identical(stat, "mean") && round) stats_j <- round_half_up(stats_j)
  for (j in seq_len(ncol(m))) {
    gap <- off[, j] & is.na(m[, j])
    y[gap, j] <- stats_j[j]
  }
  y
}

modal_value <- function(v) {
  tab <- table(v)
  as.numeric(names(tab)[which.max(tab)])
}

# knnmedian: order the other columns by squared distance from this node's
# column, then take the median of the first k valid values they offer.
impute_knn <- function(m, k) {
  y <- m
  n <- nrow(m)
  off <- row(m) != col(m)
  for (i in seq_len(n)) {
    gaps <- which(off[i, ] & is.na(m[i, ]))
    if (!length(gaps)) next
    others <- setdiff(seq_len(n), i)
    d <- vapply(others, function(j) column_distance(m, i, j), numeric(1))
    order_j <- others[order(d)]
    for (j in gaps) {
      pool <- order_j[order_j != j]
      vals <- m[pool, j]
      vals <- vals[!is.na(vals)]
      if (!length(vals)) next
      y[i, j] <- stats::median(utils::head(vals, k))
    }
  }
  y
}

# getdistance: squared differences over the rows where both columns are
# observed, skipping the two nodes' own rows.
column_distance <- function(m, c1, c2) {
  rows <- setdiff(seq_len(nrow(m)), c(c1, c2))
  a <- m[rows, c1]; b <- m[rows, c2]
  ok <- !is.na(a) & !is.na(b)
  if (!any(ok)) return(Inf)
  sum((a[ok] - b[ok])^2)
}

# copyfriend: what i's own out-ties say about j.
impute_copy <- function(m, binary) {
  y <- m
  off <- row(m) != col(m)
  for (i in seq_len(nrow(m))) {
    friends <- which(!is.na(m[i, ]) & m[i, ] > 0)
    friends <- setdiff(friends, i)
    for (j in which(off[i, ] & is.na(m[i, ]))) {
      vals <- m[friends, j]
      vals <- vals[!is.na(vals)]
      # `if num = 0 then exit(0)`.
      avg <- if (length(vals)) mean(vals) else 0
      y[i, j] <- if (binary) stats::rbinom(1, 1, min(max(avg, 0), 1)) else avg
    }
  }
  y
}

# runrandom, with two UCINET defects corrected: see dev/UCINET-ISSUES.md
# issue 15. Its binary branch rewrites every off-diagonal cell rather than
# only the missing ones, and its valued branch draws from a pool that
# includes the missing cells, so a missing value can be "imputed" as missing.
# Here only the missing cells are touched, and the pool is the observed ties.
impute_random <- function(m, binary, avg) {
  y <- m
  off <- row(m) != col(m)
  gap <- off & is.na(m)
  if (!any(gap)) return(y)
  if (binary) {
    y[gap] <- stats::rbinom(sum(gap), 1, min(max(avg, 0), 1))
  } else {
    pool <- m[off & !is.na(m)]
    if (!length(pool)) return(y)
    y[gap] <- sample(pool, sum(gap), replace = TRUE)
  }
  y
}

#' Fill missing ties from another dataset
#'
#' UCINET: Transform | Replace Missing Values. Takes the values for the
#' missing cells from a second dataset of the same shape.
#'
#' The dialog's "Matrix containing replacement values needs to be transposed"
#' box is checked by default, and the source may be the input itself - which
#' is reconstruction from the transpose, the same thing
#' `ximpute(method = "re")` does.
#'
#' @param net A network (any accepted form).
#' @param source Where the replacements come from. The network itself by
#'   default.
#' @param transpose Transpose the source first? `TRUE`, as the dialog has it.
#' @return An `xucinet` object titled `<name>-rna`, with a `history` attribute
#'   recording how many cells were filled.
#' @seealso [ximpute()].
#' @examples
#' m <- matrix(c(0,1,1, NA,0,1, 0,NA,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' as.matrix(xreplacemissing(m))
#' @export
xreplacemissing <- function(net, source = net, transpose = TRUE) {
  net <- xnet(net, substitute(net))
  src <- as.matrix(as_xucinet(source))
  if (transpose) src <- t(src)

  filled <- 0L
  out <- map_relations(net, function(m) {
    if (!identical(dim(m), dim(src))) {
      stop("the replacement dataset is ", nrow(src), " by ", ncol(src),
           " and the network is ", nrow(m), " by ", ncol(m), ".\n",
           "  They have to be the same shape; line them up with xmatch().",
           call. = FALSE)
    }
    take <- is.na(m) & !is.na(src)
    filled <<- filled + sum(take)
    m[take] <- src[take]
    m
  })
  transformed(out, "-rna",
              paste0("replaced ", filled, " missing cell",
                     if (filled == 1) "" else "s",
                     if (transpose) " from the transpose" else " from a source"))
}
