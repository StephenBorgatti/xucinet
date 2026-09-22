# Similarities and distances between the rows, the columns, or the relations
# of a dataset.
#
# Ported from the UCINET Delphi: the dialog is uc_SimDis.pas / .dfm
# (repository StephenBorgatti/ucinet at commit c7b4956) and the measures are
# G2Tools/utsimilarity.pas (the tsimilarity class family) with Tucker,
# YulesQ, CohenKappa and SumSqrDiff from G2Tools/ug2sim2.pas (repository
# StephenBorgatti/tools at commit 207958a).
#
# Dialog defaults, read from the .dfm: pMode.ItemIndex = 1, so Columns;
# SimMeasure.ItemIndex = 0, so Pearson correlation; the "Diagonal values are
# valid" checkbox is unchecked, and applies to square matrices only.
#
# Every measure deletes pairwise: tsimilarity.valid() counts a cell only when
# both profiles have it, which is what `if (x < na) and (y < na)` means once
# missing values are real NAs rather than a large sentinel.
#
# Design question G2 rule (a) makes this a dataset rather than a report. The
# log's Cronbach's alpha is dropped (question 5.9(a)): it is a by-product of
# the correlation case and says nothing about the other eighteen.

# The dialog's own label for each measure, and whether it is a similarity or a
# distance. UCINET names the saved dataset with the first three letters of the
# label, so the labels are part of the interface, not decoration.
sim_measures <- list(
  correlation      = list(label = "Pearson correlation",        kind = "similarity"),
  covariance       = list(label = "Covariance",                 kind = "similarity"),
  crossproducts    = list(label = "Cross-Products",             kind = "similarity"),
  avgcrossproducts = list(label = "Avg Cross-Products",         kind = "similarity"),
  matches          = list(label = "Matches",                    kind = "similarity"),
  jaccard          = list(label = "Jaccard",                    kind = "similarity"),
  valuedjaccard    = list(label = "Valued Jaccard",             kind = "similarity"),
  identity         = list(label = "Identity Coefficient",       kind = "similarity"),
  cosine           = list(label = "Cosine / Tucker's",          kind = "similarity"),
  kappa            = list(label = "Cohen's Kappa",              kind = "similarity"),
  yulesq           = list(label = "Yule's Q",                   kind = "similarity"),
  euclidean        = list(label = "Euclidean distance",         kind = "distance"),
  manhattan        = list(label = "Manhattan distance",         kind = "distance"),
  avgabsdiff       = list(label = "Avg absolute difference",    kind = "distance"),
  nssd             = list(label = "Normed SSD",                 kind = "distance"),
  nonmatches       = list(label = "Proportion of non-matches",  kind = "distance"),
  jaccarddistance  = list(label = "Jaccard distance",           kind = "distance"),
  hamming          = list(label = "Hamming distance",           kind = "distance"),
  ssd              = list(label = "Sum of squared differences", kind = "distance")
)

#' Similarities and distances between rows, columns or relations
#'
#' UCINET: Tools | Similarities & Distances. Compares every pair of rows,
#' every pair of columns, or every pair of relations, and returns the square
#' matrix of the chosen measure.
#'
#' Nineteen measures, the eleven similarities and eight distances the dialog
#' offers, ported cell for cell from `utsimilarity.pas` so the numbers match.
#' All of them delete pairwise: a cell counts only where both profiles have a
#' value.
#'
#' @param net A network (any accepted form).
#' @param method One of `"correlation"` (the dialog's default), `"covariance"`,
#'   `"crossproducts"`, `"avgcrossproducts"`, `"matches"`, `"jaccard"`,
#'   `"valuedjaccard"`, `"identity"`, `"cosine"`, `"kappa"`, `"yulesq"`,
#'   `"euclidean"`, `"manhattan"`, `"avgabsdiff"`, `"nssd"`, `"nonmatches"`,
#'   `"jaccarddistance"`, `"hamming"` or `"ssd"`.
#' @param mode `"cols"` (the dialog's default), `"rows"`, or `"relations"` to
#'   compare the relations of a multi-relation dataset with each other.
#' @param diagonal Are the diagonal values valid? `FALSE` by default, as the
#'   dialog has it: the diagonal is set missing before the profiles are
#'   compared, so cells `(i,i)` and `(j,j)` drop out of every pair. Square
#'   1-mode data only; forced `TRUE` otherwise.
#' @return An `xucinet` object: a square, symmetric, undirected dataset
#'   labelled by whatever was compared, titled the way UCINET names it
#'   (`campnet-Pea-C`). The `history` attribute says which measure was used
#'   and whether it is a similarity or a distance, which is what
#'   [xmds()] and [xhclust()] will want to know.
#' @seealso [xmds()] and [xhclust()], which take a proximity matrix;
#'   [xgeodesic()] for distances through the network rather than between
#'   profiles.
#' @examples
#' s <- xsimilarities(campnet)
#' round(as.matrix(s)[1:4, 1:4], 3)
#' attr(s, "history")
#'
#' # Jaccard on the columns of a 2-mode dataset
#' round(as.matrix(xsimilarities(davis, method = "jaccard"))[1:4, 1:4], 3)
#' @export
xsimilarities <- function(net, method = "correlation",
                          mode = c("cols", "rows", "relations"),
                          diagonal = FALSE) {
  net <- xnet(net, substitute(net))
  mode <- match.arg(mode)
  method <- match.arg(method, names(sim_measures))
  spec <- sim_measures[[method]]

  mats <- relation_matrices(net)
  square <- nrow(mats[[1]]) == ncol(mats[[1]])
  # "For square matrices only": anything else has no diagonal to discount.
  if (!square || !identical(net$mode, "1-mode")) diagonal <- TRUE

  profiles <- sim_profiles(net, mats, mode, diagonal)
  out <- sim_matrix(profiles, method)

  res <- new_xucinet(out, mode = "1-mode", directed = FALSE, title = net$title)
  transformed(res, sim_suffix(spec$label, mode),
              paste0(spec$label, " between ", mode, " (", spec$kind, ")"))
}

# campnet-Pea-C: the first three letters of the dialog's label, then R, C or M.
sim_suffix <- function(label, mode) {
  paste0("-", substr(label, 1, 3), "-",
         switch(mode, rows = "R", cols = "C", relations = "M"))
}

# The vectors that get compared. setdiagonal(bna) makes the whole diagonal
# missing first, so for a pair of columns i and j exactly cells (i,i) and
# (j,j) fall out; the other diagonal cells belong to other columns.
sim_profiles <- function(net, mats, mode, diagonal) {
  if (identical(mode, "relations")) {
    if (length(mats) < 2) {
      stop("mode = \"relations\" compares the relations of a stack with each ",
           "other, and this dataset has ", length(mats), ".\n",
           "  Use mode = \"rows\" or \"cols\", or join several networks with ",
           "xjoin() first.", call. = FALSE)
    }
    vecs <- lapply(mats, function(m) {
      if (!diagonal && nrow(m) == ncol(m)) m[row(m) == col(m)] <- NA_real_
      as.vector(m)
    })
    names(vecs) <- xrelations(net)
    return(vecs)
  }

  m <- mats[[1]]
  if (!diagonal && nrow(m) == ncol(m)) diag(m) <- NA_real_
  if (identical(mode, "rows")) {
    vecs <- lapply(seq_len(nrow(m)), function(i) m[i, ])
    names(vecs) <- rownames(m)
  } else {
    vecs <- lapply(seq_len(ncol(m)), function(j) m[, j])
    names(vecs) <- colnames(m)
  }
  vecs
}

sim_matrix <- function(profiles, method) {
  n <- length(profiles)
  out <- matrix(NA_real_, n, n,
                dimnames = list(names(profiles), names(profiles)))
  for (i in seq_len(n)) {
    for (j in i:n) {
      v <- sim_pair(profiles[[i]], profiles[[j]], method)
      out[i, j] <- v
      out[j, i] <- v
    }
  }
  out
}

# One measure on one pair of profiles, pairwise complete. Each branch is the
# Delphi class of the same name; see the file header for where each lives.
sim_pair <- function(x, y, method) {
  ok <- !is.na(x) & !is.na(y)
  n <- sum(ok)
  x <- x[ok]; y <- y[ok]
  # tmanhattan.getresult is the one with no n > 0 guard: it returns the sum
  # it has, which is zero when there is nothing to add.
  if (n == 0 && !identical(method, "manhattan")) return(NA_real_)

  switch(
    method,

    # --- similarities ---
    correlation = {
      sx <- sum((x - mean(x))^2); sy <- sum((y - mean(y))^2)
      if (sx > 0 && sy > 0) sum((x - mean(x)) * (y - mean(y))) / sqrt(sx * sy)
      else NA_real_
    },
    # tcovariance divides the same cross-product sum by n, not by n - 1.
    covariance       = sum((x - mean(x)) * (y - mean(y))) / n,
    crossproducts    = sum(x * y),
    avgcrossproducts = sum(x * y) / n,
    matches          = sum(x == y) / n,
    jaccard = {
      either <- x > 0 | y > 0
      if (any(either)) sum(x > 0 & y > 0) / sum(either) else NA_real_
    },
    valuedjaccard = {
      either <- x > 0 | y > 0
      den <- sum(pmax(x[either], y[either]))
      if (den > 0) sum(pmin(x[either], y[either])) / den else NA_real_
    },
    identity = {
      den <- sum(x^2) + sum(y^2)
      if (den != 0) 2 * sum(x * y) / den else NA_real_
    },
    cosine = {
      sx <- sum(x^2); sy <- sum(y^2)
      if (sx > 0 && sy > 0) sum(x * y) / (sqrt(sx) * sqrt(sy)) else NA_real_
    },
    kappa  = sim_kappa(x, y, n),
    yulesq = {
      t2 <- sim_table(x, y)
      den <- t2[["a"]] * t2[["d"]] + t2[["b"]] * t2[["c"]]
      if (den != 0) (t2[["a"]] * t2[["d"]] - t2[["b"]] * t2[["c"]]) / den
      else NA_real_
    },

    # --- distances ---
    euclidean  = sqrt(sum((x - y)^2)),
    manhattan  = sum(abs(x - y)),
    avgabsdiff = sum(abs(x - y)) / n,
    nssd = {
      xsq <- sum(x^2); ysq <- sum(y^2)
      if (xsq > 0 && ysq > 0) sum((x - y)^2) / (xsq * ysq) else NA_real_
    },
    nonmatches = 1 - sum(x == y) / n,
    jaccarddistance = {
      either <- x > 0 | y > 0
      if (any(either)) 1 - sum(x > 0 & y > 0) / sum(either) else NA_real_
    },
    hamming = sum(x != y),
    ssd     = sum((x - y)^2))
}

# The 2 x 2 table both kappa and Yule's Q are built on: presence is > 0.
sim_table <- function(x, y) {
  xp <- x > 0; yp <- y > 0
  c(a = sum(xp & yp), b = sum(xp & !yp), c = sum(!xp & yp), d = sum(!xp & !yp))
}

sim_kappa <- function(x, y, n) {
  t2 <- sim_table(x, y)
  a <- t2[["a"]]; b <- t2[["b"]]; c <- t2[["c"]]; d <- t2[["d"]]
  r1 <- a + b; r2 <- c + d; c1 <- a + c; c2 <- b + d
  expagree <- (r1 * c1 / n) + (r2 * c2 / n)
  if (n > expagree) (a + d - expagree) / (n - expagree) else NA_real_
}
