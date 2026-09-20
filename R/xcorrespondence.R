# Ported from borgworld::bcorresp() (R/b_corresp.R, commit 51d6dca, 14 October
# 2025), computational block only; the ggplot2 plotting path is not taken
# (SPEC D9) and the base-graphics map is drawn by plot_coords(). The report
# follows UCINET's Xcorresp.pas (ucinet repository, 18 September 2026): Row
# Scores and Column Scores as consecutive sections, principal coordinates on
# both margins, which is what UCINET's default `Coordinates` scaling gives.
# The vendored borgworld source is in inst/reference/borgworld/.
#
# Departures from borgworld, decided by Steve on 18 September 2026
# (dev/design/ch06-questions.md, question 11):
#   - total inertia, percentages and chi-square come from the FULL spectrum;
#     bcorresp truncates the eigenvalues to ncp first, so with dim = 2 its
#     percentages always sum to 100 and its chi-square is wrong;
#   - NA cells are replaced by the overall mean, as UCINET does, not by 0;
#   - all-zero rows and columns are dropped and named in the report.

#' Correspondence analysis
#'
#' UCINET: Tools | Scaling/Decomposition | Correspondence Analysis. Row and
#' column scores from the singular value decomposition of the standardized
#' residuals of a non-negative table, so that rows with similar profiles are
#' placed near each other, columns likewise, and rows near the columns in
#' which they are relatively strong. Book section 6.3.
#'
#' The scores are principal coordinates for both rows and columns (the
#' symmetric map), which is what UCINET's default scaling produces. Axes are
#' determined only up to sign, and UCINET, borgworld and xucinet fix the sign
#' differently, so a map that looks mirror-imaged against UCINET's is the same
#' map; see the differences vignette.
#'
#' UCINET's singular-values table reports each singular value as a share of
#' their sum. The table here reports the principal inertias (squared singular
#' values) and their share of the total inertia, which is what "variance
#' explained" means in correspondence analysis elsewhere; both columns are
#' printed so the relationship is visible.
#'
#' @param x A non-negative table: a matrix, data frame, `xucinet` object
#'   (1-mode or 2-mode) or file name. Need not be square, and may have more
#'   columns than rows.
#' @param dim Number of dimensions of scores to keep. At most
#'   `min(nrow, ncol) - 1`.
#' @param plot Draw the joint map of the first two dimensions with base
#'   graphics. Rows and columns are drawn as two groups.
#' @return An `xucinet_output` of subclass `xcorrespondence`. `$nodes` holds
#'   the row scores (`Dim1 ... Dimk`, original row order); `$matrices` holds
#'   `Column Scores`, `Singular Values` (singular value, inertia, percent and
#'   cumulative percent of total inertia, one row per non-trivial dimension of
#'   the full solution), `Row Contributions` and `Column Contributions`
#'   (percent of each dimension's inertia). `$summary` holds the total
#'   inertia, chi-square, degrees of freedom and p-value. `$cos2` holds the
#'   row and column quality-of-representation matrices, which are not printed.
#' @references Greenacre, M. J. (1984). *Theory and Applications of
#'   Correspondence Analysis*. Academic Press.
#' @seealso [xmds()], [xhclust()]
#' @examples
#' xcorrespondence(doctorates, plot = FALSE)
#' @export
xcorrespondence <- function(x, dim = 2, plot = TRUE) {
  px <- xprox(x, substitute(x), "xcorrespondence()", square = FALSE)
  m <- px$m
  assumptions <- px$assumptions
  if (any(m < 0, na.rm = TRUE)) {
    stop("xcorrespondence() needs a non-negative table (counts or frequencies); ",
         "this one has ", sum(m < 0, na.rm = TRUE), " negative cells.", call. = FALSE)
  }
  if (anyNA(m)) {
    fill <- mean(m, na.rm = TRUE)
    assumptions <- c(assumptions, sprintf(
      "%d missing cells replaced by the overall mean (%s), as UCINET does.",
      sum(is.na(m)), format_number(fill)))
    m[is.na(m)] <- fill
  }
  zr <- which(rowSums(m) == 0); zc <- which(colSums(m) == 0)
  if (length(zr)) {
    assumptions <- c(assumptions, paste0("All-zero rows dropped: ",
                                         paste(rownames(m)[zr], collapse = ", "), "."))
    m <- m[-zr, , drop = FALSE]
  }
  if (length(zc)) {
    assumptions <- c(assumptions, paste0("All-zero columns dropped: ",
                                         paste(colnames(m)[zc], collapse = ", "), "."))
    m <- m[, -zc, drop = FALSE]
  }
  nr <- nrow(m); nc <- ncol(m)
  rank <- min(nr, nc) - 1L
  if (rank < 1L) {
    stop("xcorrespondence() needs at least two rows and two columns after ",
         "dropping empty ones; this table is ", nr, " x ", nc, ".", call. = FALSE)
  }
  dim <- as.integer(dim)
  if (is.na(dim) || dim < 1L) stop("dim must be at least 1.", call. = FALSE)
  if (dim > rank) {
    assumptions <- c(assumptions, sprintf(
      "dim reduced from %d to %d, the rank of a %d x %d table.", dim, rank, nr, nc))
    dim <- rank
  }

  # ---- the decomposition (bcorresp, steps 1-9) ----------------------------
  N <- sum(m)
  P <- m / N
  r <- rowSums(P); cmass <- colSums(P)
  E <- outer(r, cmass)
  S <- diag(1 / sqrt(r), nr) %*% (P - E) %*% diag(1 / sqrt(cmass), nc)
  sv <- svd(S)
  d_all <- sv$d[seq_len(rank)]           # the trivial (zero) dimension excluded
  inertia_all <- d_all^2
  total_inertia <- sum(inertia_all)
  pct <- 100 * inertia_all / total_inertia
  cum <- cumsum(pct)

  keep <- seq_len(dim)
  rowsc <- diag(1 / sqrt(r), nr) %*% sv$u[, keep, drop = FALSE] %*% diag(d_all[keep], dim)
  colsc <- diag(1 / sqrt(cmass), nc) %*% sv$v[, keep, drop = FALSE] %*% diag(d_all[keep], dim)
  dn <- paste0("Dim", keep)
  dimnames(rowsc) <- list(rownames(m), dn)
  dimnames(colsc) <- list(colnames(m), dn)

  row_contrib <- 100 * (r * rowsc^2) %*% diag(1 / inertia_all[keep], dim)
  col_contrib <- 100 * (cmass * colsc^2) %*% diag(1 / inertia_all[keep], dim)
  dimnames(row_contrib) <- dimnames(rowsc)
  dimnames(col_contrib) <- dimnames(colsc)

  row_profiles <- sweep(P, 1, r, "/")
  row_dist2 <- rowSums(sweep((row_profiles - matrix(cmass, nr, nc, byrow = TRUE))^2, 2, cmass, "/"))
  col_profiles <- sweep(t(P), 1, cmass, "/")
  col_dist2 <- rowSums(sweep((col_profiles - matrix(r, nc, nr, byrow = TRUE))^2, 2, r, "/"))
  row_cos2 <- rowsc^2 / row_dist2; row_cos2[is.nan(row_cos2)] <- 0
  col_cos2 <- colsc^2 / col_dist2; col_cos2[is.nan(col_cos2)] <- 0

  chi2 <- N * total_inertia
  df <- (nr - 1) * (nc - 1)
  pval <- stats::pchisq(chi2, df, lower.tail = FALSE)

  singular <- cbind("Singular value" = d_all, "Inertia" = inertia_all,
                    "Percent" = pct, "Cumulative" = cum)
  rownames(singular) <- as.character(seq_len(rank))

  if (isTRUE(plot) && dim >= 2L) {
    coords <- rbind(rowsc[, 1:2, drop = FALSE], colsc[, 1:2, drop = FALSE])
    plot_coords(coords,
                labels = c(rownames(m), colnames(m)),
                groups = rep(c("Rows", "Columns"), c(nr, nc)),
                main = "Correspondence analysis",
                xlab = sprintf("Dimension 1 (%.1f%%)", pct[1]),
                ylab = sprintf("Dimension 2 (%.1f%%)", pct[2]))
  } else if (isTRUE(plot)) {
    message("xcorrespondence(): nothing to plot with dim = 1; use dim = 2 for a map.")
  }

  out <- new_xucinet_output(
    "Correspondence analysis", px$net,
    nodes = as.data.frame(rowsc, check.names = FALSE),
    summary = list("Total inertia" = total_inertia, "Chi-square" = chi2,
                   "df" = df, "p-value" = pval),
    matrices = list("Column Scores" = colsc,
                    "Singular Values" = singular,
                    "Row Contributions" = row_contrib,
                    "Column Contributions" = col_contrib),
    assumptions = assumptions,
    fields = c("Method:" = "Principal Coordinates"),
    nodes_title = "Row Scores",
    stats_block = FALSE,
    subclass = "xcorrespondence", call = match.call())
  out$cos2 <- list(rows = row_cos2, columns = col_cos2)
  out$masses <- list(rows = r, columns = cmass)
  out$inertias <- list(rows = r * row_dist2, columns = cmass * col_dist2)
  if (isTRUE(plot)) invisible(out) else out
}
