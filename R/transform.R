# Chapter 5 transformations: the routines that produce a dataset rather than a
# report (design question G2, rule a).
#
# Ported from the UCINET Delphi. Repositories StephenBorgatti/ucinet at commit
# c7b4956 (the form units: dialog options, defaults and output dataset names)
# and StephenBorgatti/tools at commit 207958a (the algorithms):
#
#   transpose    TranDlg.pas (dialog, output name '-Transp')
#                G2Tools/uTranspose.pas, procedure runrcl
#   dichotomize  uc_Dichotomize.pas / .dfm (dialog, output name '<in>_GT_0')
#                CLI form: G2Tools/udichotomize.pas, dichotomizematrix
#   symmetrize   xsymmetrize.pas and Symdlg.pas (dialogs), usym.pas,
#                procedure symmetrize and function Arith1
#   normalize    Xstdize.pas, dialog Normdlg.pas / .dfm,
#                G2Tools/uNormalize.pas (rowstoch and the normvec family)
#   recode       Xrecode.pas / xRecodeDlg.pas, procedure recodedsl
#
# Each returns a `xucinet` object, silently, titled the way UCINET names the
# dataset it saves, with a `history` attribute recording the operation and any
# statistics the UCINET log prints.

# ---- shared machinery -------------------------------------------------------

# Apply f to every relation and keep the shape of the stack: $data is a bare
# matrix for a single-relation dataset and a named list for a multi-relation
# one, and a transformation must not quietly change which.
map_relations <- function(net, f) {
  if (is.list(net$data)) net$data <- lapply(net$data, f) else net$data <- f(net$data)
  net
}

# Every matrix of a dataset, as a list, whatever the stack shape.
relation_matrices <- function(net) {
  if (is.list(net$data)) net$data else list(net$data)
}

# Retitle the way UCINET names the dataset it saves, and record the operation.
transformed <- function(net, suffix, entry) {
  net$title <- paste0(net$title, suffix)
  attr(net, "history") <- c(attr(net, "history"), entry)
  net
}

# usym.symmetrize logs "Matrix must be square to symmetrize." and stops.
require_1mode <- function(net, what) {
  if (identical(net$mode, "2-mode")) {
    stop(what, " needs a 1-mode network; this dataset is 2-mode (",
         nrow(as.matrix(net)), " rows by ", ncol(as.matrix(net)), " columns).\n",
         "  UCINET refuses it too: the matrix has to be square.\n",
         "  For a 2-mode dataset, project it to one mode first.", call. = FALSE)
  }
  invisible(NULL)
}

#' Transpose a network
#'
#' UCINET: Transform | Transpose. Rows become columns and columns become rows.
#' For a directed 1-mode network this reverses every tie, turning "i chooses j"
#' into "i is chosen by j"; for a 2-mode network it swaps the two node sets.
#'
#' @param net A network (any accepted form).
#' @return An `xucinet` object, titled as UCINET names it (`campnet-Transp`),
#'   with a `history` attribute. Multi-relation input is transposed relation by
#'   relation and stays a stack.
#' @seealso [xsymmetrize()] to fold the two directions together instead.
#' @examples
#' m <- matrix(c(0,1,1, 0,0,1, 0,0,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' xtranspose(m)
#'
#' # 2-mode: the modes swap over
#' dim(davis)
#' dim(xtranspose(davis))
#' @export
xtranspose <- function(net) {
  net <- xnet(net, substitute(net))
  out <- map_relations(net, t)
  transformed(out, "-Transp", "transposed")
}

# ---- xdichotomize -----------------------------------------------------------
#
# uc_Dichotomize.pas: "if x(i,j) op value then y(i,j) = then-value else
# else-value". Six operators, a then-value and an else-value either of which
# may be missing, and five ways to treat the diagonal of the output.
#
# The menu form and the older CLI disagree about the diagonal, which is what
# question 5.1(ii) asked to be checked:
#
#   CLI   G2Tools/udichotomize.pas has five operators (no NE), a hard-wired
#         1/0 result, and one boolean `diagok` - apply the rule to the
#         diagonal or leave it alone - forced on for a non-square matrix.
#   menu  uc_Dichotomize.pas has six operators, configurable then/else values,
#         and yDiagonals with ItemIndex = 3, so the DEFAULT is "Set to 'else'
#         value" and following the rule is one of five choices.
#
# R follows the menu form, so `diagonal = "else"` is the default here. The
# CLI-made Phase 0 goldens show the rule applied instead; ledger entry 13
# records the choice. (The older entry that described the diagonal was retired
# when UCINET 6.849 stopped zeroing it, which is why nothing numbered 1 covers
# this any more.)
# The internal `dichotomize_matrix()` keeps the CLI behaviour, because that is
# what `copyfromtmat` gives the analysis routines that call it.

# Operator -> the name UCINET builds the output dataset from (setoutputfn).
dich_op_tag <- c(">" = "_GT_", ">=" = "_GE_", "==" = "_EQ_",
                 "<=" = "_LE_", "<" = "_LT_", "!=" = "_NE_")

#' Dichotomize a valued network
#'
#' UCINET: Transform | Dichotomize. Applies the rule "if `x[i,j]` *op* cutoff
#' then `then` else `otherwise`" to every cell.
#'
#' The cutoff can be given three ways, chosen by `method`: as a value, as a
#' target density, or by maximising the correlation between the dichotomized
#' matrix and the original. The last is what UCINET's Transform | Dichotomize
#' Interactive does one row at a time - it tabulates every distinct value with
#' its correlation, number of ones and density, and the user picks a row - so
#' `method = "maxcor"` picks the best row automatically. Neither the density
#' target nor `maxcor` is a batch routine in UCINET; see the differences
#' ledger.
#'
#' @param net A network (any accepted form).
#' @param cutoff The value to compare against. Used when `method = "cutoff"`,
#'   which is the default.
#' @param op One of `">"` (UCINET's default), `">="`, `"=="`, `"<="`, `"<"` or
#'   `"!="`.
#' @param then Value written where the rule holds. `1` by default; `NA` is
#'   allowed, as in the dialog.
#' @param otherwise Value written where it does not. `0` by default; `NA` is
#'   allowed. UCINET calls this the "else" value, which cannot be an argument
#'   name in R because `else` is reserved.
#' @param elsevalue The same as `otherwise`, under a name closer to the
#'   dialog's. Give one or the other, not both.
#' @param density Target density, used when `method = "density"`. The cutoff
#'   chosen is the most selective one, among the values present, whose density
#'   is still at least this.
#' @param method `"cutoff"` (default), `"density"` or `"maxcor"`.
#' @param diagonal What to write on the diagonal of a square result:
#'   `"else"` (the dialog's default), `"zero"`, `"missing"`, `"then"`, or
#'   `"rule"` to dichotomize it like any other cell. Ignored for 2-mode data,
#'   where the diagonal is an ordinary cell.
#' @return An `xucinet` object titled as UCINET names it (`camp92_GT_1`; a dot
#'   in the cutoff becomes `p`), with a `history` attribute giving the cutoff
#'   used and, for `"density"` and `"maxcor"`, the density and correlation it
#'   achieved.
#' @seealso [xsymmetrize()], [xrecode()], [xdensity()].
#' @examples
#' m <- matrix(c(0,3,1, 2,0,0, 5,1,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' as.matrix(xdichotomize(m, cutoff = 1))
#' as.matrix(xdichotomize(m, cutoff = 1, op = "<="))
#'
#' # the cutoff that best reproduces the valued matrix
#' d <- xdichotomize(m, method = "maxcor")
#' attr(d, "history")
#' @export
xdichotomize <- function(net, cutoff = 0,
                         op = c(">", ">=", "==", "<=", "<", "!="),
                         then = 1, otherwise = 0, density = NULL,
                         method = c("cutoff", "density", "maxcor"),
                         diagonal = c("else", "zero", "missing", "then", "rule"),
                         elsevalue = NULL) {
  net <- xnet(net, substitute(net))
  # Two names for the dialog's "else value" (Steve, 23 Sep 2026).
  if (!is.null(elsevalue)) {
    if (!missing(otherwise)) {
      stop("give otherwise = or elsevalue =, not both; they are the same ",
           "argument.", call. = FALSE)
    }
    otherwise <- elsevalue
  }
  op <- match.arg(op)
  diagonal <- match.arg(diagonal)
  # Giving density = is enough to mean it, without naming the method too.
  if (missing(method) && !is.null(density)) method <- "density"
  method <- match.arg(method)

  if (method == "density") {
    if (is.null(density)) {
      stop("method = \"density\" needs density = a number between 0 and 1.",
           call. = FALSE)
    }
    if (op %in% c("==", "!=")) {
      stop("a density target does not work with op = \"", op, "\".\n",
           "  Density rises and falls with the cutoff for an equality test, ",
           "so there is no single cutoff to solve for.\n",
           "  Use method = \"cutoff\" instead.", call. = FALSE)
    }
    if (!is.numeric(density) || length(density) != 1 || is.na(density) ||
        density < 0 || density > 1) {
      stop("density must be one number between 0 and 1.", call. = FALSE)
    }
  }

  notes <- character(0)
  cuts <- numeric(0)
  out <- map_relations(net, function(m) {
    cut <- switch(method,
                  cutoff  = cutoff,
                  density = density_cutoff(m, op, density),
                  maxcor  = maxcor_cutoff(m, op, diagonal))
    cuts <<- c(cuts, cut)
    y <- dichotomize_matrix(m, cut, op, then, otherwise)
    y <- dich_diagonal(y, then, otherwise, diagonal)
    notes <<- c(notes, dich_note(m, y, cut, op, method))
    y
  })
  # UCINET names the output for one cutoff; with a stack the first one names
  # the dataset.
  transformed(out, dich_suffix(cuts[1], op), paste(notes, collapse = "; "))
}

# The title UCINET would give the saved dataset: setoutputfn glues the operator
# tag to the cutoff with dots turned into "p".
dich_suffix <- function(cutoff, op) {
  paste0(dich_op_tag[[op]], gsub(".", "p", format(cutoff), fixed = TRUE))
}

# What the log prints: the cutoff, and for the two searching methods the
# density and correlation it settled on.
dich_note <- function(m, y, cut, op, method) {
  note <- paste0("dichotomized ", op, " ", format(cut))
  if (method %in% c("density", "maxcor")) {
    note <- paste0(note, " (", method, ": density ",
                   format(round(mean(y, na.rm = TRUE), 4)),
                   ", r ", format(round(dich_cor(m, y), 4)), ")")
  }
  note
}

# The cell rule. Missing cells stay missing: the Delphi compares only where
# `m.cell[i,j] < na`.
dichotomize_matrix <- function(m, cutoff = 0, op = ">", then = 1, otherwise = 0) {
  hit <- switch(op,
                ">"  = m >  cutoff,
                ">=" = m >= cutoff,
                "==" = m == cutoff,
                "<=" = m <= cutoff,
                "<"  = m <  cutoff,
                "!=" = m != cutoff)
  out <- ifelse(hit, then, otherwise)
  out[is.na(m)] <- NA_real_
  dim(out) <- dim(m)
  dimnames(out) <- dimnames(m)
  storage.mode(out) <- "double"
  out
}

# yDiagonals, ItemIndex = 3 by default. A non-square matrix has no diagonal to
# speak of, so the option does not apply.
dich_diagonal <- function(y, then, otherwise, diagonal) {
  if (nrow(y) != ncol(y) || diagonal == "rule") return(y)
  diag(y) <- switch(diagonal,
                    zero    = 0,
                    missing = NA_real_,
                    then    = then,
                    "else"  = otherwise)
  y
}

# Pearson correlation between the dichotomized matrix and the original, over
# the cells both have.
dich_cor <- function(m, y) {
  ok <- !is.na(m) & !is.na(y)
  if (sum(ok) < 2) return(NA_real_)
  a <- as.vector(m)[ok]; b <- as.vector(y)[ok]
  if (stats::sd(a) == 0 || stats::sd(b) == 0) return(NA_real_)
  stats::cor(a, b)
}

# The most selective cutoff that still leaves the density at or above the
# target. Selectivity rises with the cutoff for the "greater" operators and
# falls for the "less" ones, so the two are searched from opposite ends.
density_cutoff <- function(m, op, target) {
  candidates <- sort(unique(as.vector(m)[!is.na(m)]))
  reached <- vapply(candidates,
                    function(cut) mean(dichotomize_matrix(m, cut, op), na.rm = TRUE),
                    numeric(1))
  ok <- which(reached >= target)
  if (!length(ok)) {
    stop("no cutoff in this matrix reaches a density of ", target, ".\n",
         "  The highest available with op = \"", op, "\" is ",
         format(max(reached)), ".", call. = FALSE)
  }
  if (op %in% c("<", "<=")) candidates[min(ok)] else candidates[max(ok)]
}

# uc_DichotomizationApp.pas tabulates every distinct value of X against the
# correlation between the dichotomized matrix and X; this takes the best row.
# The diagonal is excluded from the comparison unless it is being dichotomized
# by the rule, which is the dialog's "diagonal is valid" case.
maxcor_cutoff <- function(m, op, diagonal) {
  x <- m
  if (nrow(m) == ncol(m) && !identical(diagonal, "rule")) diag(x) <- NA_real_
  candidates <- sort(unique(as.vector(x)[!is.na(x)]))
  if (!length(candidates)) {
    stop("method = \"maxcor\" needs at least one observed value to try.",
         call. = FALSE)
  }
  r <- vapply(candidates,
              function(cut) dich_cor(x, dichotomize_matrix(x, cut, op)),
              numeric(1))
  if (all(is.na(r))) {
    stop("method = \"maxcor\" found no cutoff that gives a usable ",
         "correlation.\n  Every candidate made the result constant; give ",
         "cutoff = instead.", call. = FALSE)
  }
  candidates[which.max(r)]
}

# ---- xsymmetrize ------------------------------------------------------------
#
# usym.pas, procedure symmetrize and function Arith1. Sixteen methods, in the
# dialog's order; `a` is the upper cell x[i,j] (i < j) and `b` the lower cell
# x[j,i]. A pair with a missing cell never reaches Arith1 - symmetrize tests
# `(a < na) and (b < na)` first - so the missing rule is applied on its own.

#' Symmetrize a directed network
#'
#' UCINET: Transform | Symmetrize. Replaces each pair of cells `x[i,j]` and
#' `x[j,i]` with a single value computed from both, so the result is
#' undirected.
#'
#' The diagonal is left exactly as it was: UCINET's loop runs over the strict
#' upper triangle (`for i := 1 to nr-1, for j := i+1 to nc`), so `x[i,i]`
#' never enters the calculation and never changes.
#'
#' @param net A network (any accepted form). 1-mode only.
#' @param method One of the sixteen the dialog offers, in its order. The
#'   arithmetic ones: `"max"` (the default, UCINET's Maximum), `"min"`,
#'   `"mean"`, `"sum"`, `"difference"` (the *absolute* difference, as in
#'   `Arith1`), `"product"`, `"division"` (upper divided by lower; a zero
#'   lower cell gives `NA`), `"lower"` (keep the lower half), `"upper"` (keep
#'   the upper half) and `"absdiffsum"` (`abs(a-b)/(a+b)`, `NA` when both are
#'   zero). The comparisons, which give 1 or 0: `"gt"`, `"ge"`, `"eq"`,
#'   `"le"`, `"lt"` and `"ne"`, each reading "upper *op* lower".
#' @param missing `"nonmissing"` (the dialog's default) takes the observed
#'   value when only one cell of the pair is missing; `"both"` makes the pair
#'   missing whenever either cell is. UCINET stores missing as a large
#'   sentinel and applies `min()` or `max()` to the raw cells, which is what
#'   these two amount to.
#' @return An `xucinet` object with `directed = FALSE`, titled the way UCINET
#'   names it for the method chosen (`campnet-maxsym`, `campnet-avgsym`, ...).
#'   The `history` attribute carries the six figures UCINET's log prints: the
#'   density before, the number and percentage of symmetric pairs, the number
#'   and percentage of reciprocated dyads, the density after, and the
#'   correlation with the input.
#' @seealso [xtranspose()], [xdichotomize()].
#' @examples
#' m <- matrix(c(0,3,0, 1,0,2, 0,0,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' as.matrix(xsymmetrize(m))                  # max
#' as.matrix(xsymmetrize(m, method = "min"))
#' as.matrix(xsymmetrize(m, method = "difference"))
#' attr(xsymmetrize(campnet), "history")
#' @export
xsymmetrize <- function(net,
                        method = c("max", "min", "mean", "sum", "difference",
                                   "product", "division", "lower", "upper",
                                   "gt", "ge", "eq", "le", "lt", "ne",
                                   "absdiffsum"),
                        missing = c("nonmissing", "both")) {
  net <- xnet(net, substitute(net))
  method <- match.arg(method)
  missing <- match.arg(missing)
  require_1mode(net, "xsymmetrize()")

  notes <- character(0)
  out <- map_relations(net, function(m) {
    y <- symmetrize_matrix(m, method, missing)
    notes <<- c(notes, symmetrize_note(m, y))
    y
  })
  out$directed <- FALSE
  transformed(out, symmetrize_suffix(method),
              paste0("symmetrized (", method, "); ", paste(notes, collapse = "; ")))
}

# Symdlg.pas, function getext: the saved dataset is named for the method. The
# dialog has no distinct suffix for the comparison methods, which fall through
# to its `else` branch.
symmetrize_suffix <- function(method) {
  switch(method,
         max        = "-maxsym",
         min        = "-minsym",
         mean       = "-avgsym",
         sum        = "-sumsym",
         difference = "-diffsym",
         product    = "-prosym",
         division   = "-divsym",
         lower      = "-lhsym",
         upper      = "-uhsym",
         "-sym")
}

symmetrize_matrix <- function(m, method, missing) {
  up <- upper.tri(m)
  a <- m[up]                 # x[i,j], i < j
  b <- t(m)[up]              # x[j,i]
  gap <- is.na(a) | is.na(b)

  combined <- switch(
    method,
    max        = pmax(a, b),
    min        = pmin(a, b),
    mean       = (a + b) / 2,
    sum        = a + b,
    difference = abs(a - b),
    product    = a * b,
    # Arith1: `if feq(b,0.0) then na else a/b`.
    division   = ifelse(b == 0, NA_real_, a / b),
    lower      = b,
    upper      = a,
    gt         = as.numeric(a >  b),
    ge         = as.numeric(a >= b),
    eq         = as.numeric(a == b),
    le         = as.numeric(a <= b),
    lt         = as.numeric(a <  b),
    ne         = as.numeric(a != b),
    # Arith1's `interval`: abs(a-b)/(a+b), missing when the sum is zero.
    absdiffsum = ifelse(a + b == 0, NA_real_, abs(a - b) / (a + b)))

  if (any(gap)) {
    combined[gap] <- if (identical(missing, "nonmissing")) {
      # min() over cells where missing is a large sentinel: the observed value
      # wins, and a pair missing both ways stays missing.
      pmin(a[gap], b[gap], na.rm = TRUE)
    } else {
      NA_real_
    }
  }

  out <- m
  out[up] <- combined
  out <- t(out)
  out[up] <- combined
  out <- t(out)
  diag(out) <- diag(m)
  dimnames(out) <- dimnames(m)
  out
}

# The six figures the Symmetrize log prints.
symmetrize_note <- function(m, y) {
  up <- upper.tri(m)
  a <- m[up]; b <- t(m)[up]
  both <- !is.na(a) & !is.na(b)
  numsym <- sum(a[both] == b[both])
  pctsym <- if (any(both)) numsym / sum(both) else NA_real_
  any_tie <- both & (a > 0 | b > 0)
  numpos <- sum(both & a > 0 & b > 0)
  pctpos <- if (any(any_tie)) numpos / sum(any_tie) else NA_real_
  paste0("density before ", format(round(mean(m, na.rm = TRUE), 4)),
         ", symmetric pairs ", numsym, " (", format(round(100 * pctsym, 2)), "%)",
         ", reciprocated dyads ", numpos, " (", format(round(100 * pctpos, 2)), "%)",
         ", density after ", format(round(mean(y, na.rm = TRUE), 4)),
         ", r ", format(round(dich_cor(m, y), 4)))
}

# ---- xnormalize -------------------------------------------------------------
#
# Xstdize.pas (runnormalize, runrowcols with rcalc/ccalc/adjust, runmatrix),
# with the dialog Normdlg.pas/.dfm; repository StephenBorgatti/ucinet at commit
# c7b4956. Not G2Tools/uNormalize.pas, which an earlier version of this comment
# named: that unit serves other routines, and its conventions differ.
#
# What the menu routine does, read from the source:
#   - Dimension Matrix, Rows, Columns or Both; Columns is the default.
#   - Criteria, each as "rescale so the statistic reaches its target":
#       Marginal       sum -> 1          Euclidean  norm -> 1
#       Mean           mean -> 0         Maximum    max -> 1
#                      (x - mean: a shift, not a division)
#       Std-Dev        sd -> 1           SQRT-Marginal  x / sqrt(sum)
#       Z-Score        mean -> 0 and sd -> 1
#       Correspondence x / sqrt(R_i * C_j), R and C the row and column totals
#   - A row or column whose divisor is not positive gets missing cells
#     (`if a.cell[k] > 0 then ... else x := bna`); the Matrix dimension
#     tests `<> 0` for the sum and the maximum and `> 0` for the rest.
#   - "Diagonal valid? No" sets the diagonal missing first, and it stays
#     missing in the output. Forced to Yes for non-square data.
#   - The constant *replaces* cells whose absolute value is below single
#     precision ("Constant to replace zeros with"), before anything else.
#   - Both: one column pass, then alternately test the rows (stop if every row
#     statistic is within the tolerance of its target), adjust the rows, test
#     the columns, adjust the columns; at most maxit rounds. For Marginal the
#     column target is nr/nc rather than 1, which is what lets a non-square
#     matrix have both margins met.
#
# Two places where UCINET's Matrix dimension skips a criterion - Correspondence
# (UCINET issue 23) and SQRT-Marginal, which runmatrix has no branch for either
# - xucinet does the arithmetic instead of returning the input unchanged. For
# Correspondence the result is the same for every `by`, as runrowcols makes it.

#' Normalize a network's rows, columns or cells
#'
#' UCINET: Transform | Normalize. Rescales the matrix so that every row, every
#' column, or the matrix as a whole meets a chosen criterion.
#'
#' `by = "both"` alternates row and column passes until every row and every
#' column is within `tolerance` of its target or `maxit` rounds have been made,
#' and warns if it stops at the limit. Alternating passes only have a fixed
#' point when every non-zero cell lies on some perfect matching of rows to
#' columns; when they do not, the iteration drifts rather than settling. For
#' `method = "sum"` on non-square data the column target is `nrow/ncol` rather
#' than 1, since both margins cannot otherwise sum to the same total.
#'
#' A row (or column, or matrix) whose divisor is not positive comes back
#' missing, as in UCINET: its cells have no defined normalized value.
#'
#' @param net A network (any accepted form).
#' @param by `"cols"` (UCINET's default), `"rows"`, `"matrix"` or `"both"`.
#' @param method The criterion: `"sum"` (the default, UCINET's Marginal:
#'   divide by the total), `"mean"` (subtract the mean), `"sd"` (divide by the
#'   standard deviation), `"zscore"` (subtract the mean, then divide by the
#'   standard deviation), `"euclidean"` (divide by the root of the sum of
#'   squares), `"max"`, `"sqrtsum"` (UCINET's SQRT-Marginal: divide by the
#'   square root of the total), or `"correspondence"` (divide each cell by the
#'   square root of its row total times its column total, the same whatever
#'   `by` says). Standard deviations are the population form, as UCINET's
#'   estimator reports them.
#' @param constant Replaces every zero cell before normalising, as the dialog's
#'   "Constant to replace zeros with" does. `0`, the default, changes nothing.
#' @param diagonal Include the diagonal? Yes by default, as in the dialog. When
#'   `FALSE` the diagonal is set missing, as UCINET does, and stays missing in
#'   the result. Forced on for 2-mode data.
#' @param tolerance,maxit Convergence controls for `by = "both"`; UCINET's
#'   defaults are 0.001 and 100.
#' @return An `xucinet` object titled `<name>-nrm`, with a `history` attribute;
#'   for `by = "both"` it records how many rounds it took.
#' @seealso [xdichotomize()], [xsymmetrize()].
#' @examples
#' m <- matrix(c(0,3,1, 2,0,0, 5,1,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' round(as.matrix(xnormalize(m)), 3)                    # columns sum to 1
#' round(as.matrix(xnormalize(m, by = "rows")), 3)
#' @export
xnormalize <- function(net, by = c("cols", "rows", "matrix", "both"),
                       method = c("sum", "mean", "sd", "zscore",
                                  "euclidean", "max", "sqrtsum",
                                  "correspondence"),
                       constant = 0, diagonal = TRUE,
                       tolerance = 0.001, maxit = 100) {
  net <- xnet(net, substitute(net))
  by <- match.arg(by)
  method <- match.arg(method)

  passes <- integer(0)
  out <- map_relations(net, function(m) {
    # `if m.nr <> m.nc then diagok := true`
    diag_ok <- diagonal || nrow(m) != ncol(m)
    if (!diag_ok) diag(m) <- NA_real_
    if (constant != 0) {
      near0 <- !is.na(m) & abs(m) < 1e-7
      m[near0] <- constant
    }
    res <- normalize_matrix(m, by, method, diag_ok, tolerance, maxit)
    passes <<- c(passes, res$passes)
    res$m
  })
  entry <- paste0("normalized (", by, ", ", method, ")")
  if (identical(by, "both") && method != "correspondence") {
    entry <- paste0(entry, ", ", paste(passes, collapse = ", "), " passes")
  }
  transformed(out, "-nrm", entry)
}

# rcalc/ccalc: the statistic of one row or column, over its valid cells, as
# tunivariate reports it (population sd; nrm is the root of the sum of
# squares). Missing when the vector has no valid cells.
normalize_stat <- function(v, method) {
  obs <- v[!is.na(v)]
  if (!length(obs)) return(c(NA_real_, NA_real_))
  mu <- mean(obs)
  sdev <- sqrt(mean((obs - mu)^2))
  switch(method,
         sum = , correspondence = c(sum(obs), NA),
         mean = c(mu, NA),
         sd = c(sdev, NA),
         zscore = c(mu, sdev),
         euclidean = c(sqrt(sum(obs^2)), NA),
         max = c(max(obs), NA),
         sqrtsum = c(sqrt(sum(obs)), NA))
}

# adjust: move one vector's statistic to its target. Missing cells stay
# missing; a divisor that is not positive makes the vector missing.
normalize_adjust <- function(v, method, target) {
  a <- normalize_stat(v, method)
  ok <- !is.na(v)
  if (method == "mean") {
    v[ok] <- v[ok] + target - a[1]
  } else if (method == "zscore") {
    v[ok] <- if (!is.na(a[2]) && a[2] > 0) (v[ok] - a[1]) / a[2] else NA_real_
  } else {
    v[ok] <- if (!is.na(a[1]) && a[1] > 0) v[ok] * target / a[1] else NA_real_
  }
  v
}

normalize_matrix <- function(m, by, method, diag_ok, tolerance, maxit) {
  nr <- nrow(m); nc <- ncol(m)
  # Cells the routine may touch: everything, or everything off the diagonal.
  # With the diagonal excluded it is already missing, so this only matters to
  # keep the statistic's denominators right.
  passes <- NA_integer_

  if (method == "correspondence") {
    rt <- apply(m, 1, function(v) sum(v, na.rm = TRUE))
    ct <- apply(m, 2, function(v) sum(v, na.rm = TRUE))
    for (i in which(rt > 0)) for (j in which(ct > 0)) {
      m[i, j] <- m[i, j] / sqrt(rt[i] * ct[j])
    }
    return(list(m = m, passes = passes))
  }

  row_target <- if (method == "mean" || method == "zscore") 0 else 1
  col_target <- if (method == "sum" && by == "both") nr / nc else row_target

  adjust_rows <- function(x) {
    for (i in seq_len(nr)) x[i, ] <- normalize_adjust(x[i, ], method, row_target)
    x
  }
  adjust_cols <- function(x) {
    for (j in seq_len(nc)) x[, j] <- normalize_adjust(x[, j], method, col_target)
    x
  }
  # rowsok / colsok: every statistic within the tolerance of its target. For
  # the z-score both the mean (target 0) and the sd (target 1) are tested.
  within <- function(x, margin, target) {
    stats <- apply(x, margin, normalize_stat, method = method)
    want <- if (method == "zscore") c(0, 1) else c(target, NA)
    d1 <- abs(stats[1, ] - want[1])
    d2 <- if (method == "zscore") abs(stats[2, ] - want[2]) else 0
    all(c(d1, d2)[!is.na(c(d1, d2))] <= tolerance)
  }

  out <- switch(
    by,
    rows = adjust_rows(m),
    cols = adjust_cols(m),
    matrix = {
      x <- m
      ok <- !is.na(x)
      obs <- x[ok]
      if (length(obs)) {
        mu <- mean(obs)
        sdev <- sqrt(mean((obs - mu)^2))
        tot <- sum(obs)
        # runmatrix: the sum and the maximum test `<> 0`, the others `> 0`.
        x[ok] <- switch(method,
          sum = if (tot != 0) obs / tot else NA_real_,
          mean = obs - mu,
          sd = if (sdev > 0) obs / sdev else NA_real_,
          zscore = if (sdev > 0) (obs - mu) / sdev else NA_real_,
          euclidean = if (sqrt(sum(obs^2)) > 0) obs / sqrt(sum(obs^2)) else NA_real_,
          max = if (max(obs) != 0) obs / max(obs) else NA_real_,
          sqrtsum = if (tot > 0) obs / sqrt(tot) else NA_real_)
      }
      x
    },
    both = {
      x <- adjust_cols(m)
      settled <- FALSE
      passes <- 0L
      for (it in seq_len(maxit)) {
        passes <- it
        if (within(x, 1, row_target)) { settled <- TRUE; break }
        x <- adjust_rows(x)
        if (within(x, 2, col_target)) { settled <- TRUE; break }
        x <- adjust_cols(x)
      }
      if (!settled) {
        warning("xnormalize(by = \"both\") stopped at the iteration limit (",
                maxit, ") with a margin still more than tolerance = ",
                format(tolerance), " away from its target.\n",
                "  Rows and columns cannot both be normalized for this ",
                "matrix, or not to this tolerance.\n",
                "  Raise maxit =, loosen tolerance =, or normalize one ",
                "dimension only.", call. = FALSE)
      }
      x
    })
  dimnames(out) <- dimnames(m)
  list(m = out, passes = passes)
}

# ---- xrecode ----------------------------------------------------------------
#
# Xrecode.pas, procedure recodedsl, and xRecodeDlg.pas. The schedule is a
# table of (low, high, new value) rows. Every rule is tested against the
# ORIGINAL cell value and the last rule that matches wins, so an overlapping
# schedule resolves bottom-up rather than stopping at the first hit. Both ends
# of a range are inclusive. "Include diagonal values?" defaults to No for
# square data and is forced to Yes otherwise. Output name '-Rec'.

#' Recode the values in a network
#'
#' UCINET: Transform | Recode. Replaces cell values according to a schedule of
#' inclusive ranges.
#'
#' Every rule is tested against the cell's *original* value and the last
#' matching rule wins, which is how `recodedsl` resolves an overlapping
#' schedule. A cell matched by no rule keeps the value it had, and missing
#' cells are never recoded.
#'
#' @param net A network (any accepted form).
#' @param from Values to replace: a numeric vector of single values, a
#'   two-column matrix of `low, high` ranges, or a list mixing single values
#'   and `c(low, high)` pairs.
#' @param to The replacement for each rule; either one value for all of them
#'   or one per rule.
#' @param diagonal Recode the diagonal too? `FALSE` by default for square
#'   data, as in the dialog, and forced on for a non-square matrix.
#' @param rows,cols Restrict the recoding to these rows or columns, by label
#'   or index. `NULL` (the default) means all of them, UCINET's ALL.
#' @param relations Restrict it to these relations of a stack, by name or
#'   position. `NULL` means all.
#' @return An `xucinet` object titled `<name>-Rec`, with a `history` attribute.
#' @seealso [xdichotomize()] for the binary case.
#' @examples
#' m <- matrix(c(0,3,1, 2,0,0, 5,1,0), 3, 3, byrow = TRUE,
#'             dimnames = list(letters[1:3], letters[1:3]))
#' as.matrix(xrecode(m, from = c(3, 5), to = 9))
#' # a range: anything from 1 to 3 becomes 1
#' as.matrix(xrecode(m, from = list(c(1, 3)), to = 1))
#' @export
xrecode <- function(net, from, to, diagonal = FALSE,
                    rows = NULL, cols = NULL, relations = NULL) {
  net <- xnet(net, substitute(net))
  sched <- recode_schedule(from, to)
  wanted <- recode_relations(net, relations)
  k <- 0L
  out <- map_relations(net, function(m) {
    k <<- k + 1L
    if (!(k %in% wanted)) return(m)
    recode_matrix(m, sched, diagonal, rows, cols)
  })
  transformed(out, "-Rec",
              paste0("recoded (", nrow(sched), " rule",
                     if (nrow(sched) == 1) "" else "s", ")"))
}

# Which relations to touch, as positions.
recode_relations <- function(net, relations) {
  n <- xnrelations(net)
  if (is.null(relations)) return(seq_len(n))
  if (is.character(relations)) {
    hit <- match(relations, xrelations(net))
    if (anyNA(hit)) {
      stop("no relation called \"", relations[is.na(hit)][1], "\".\n",
           "  Available: ", paste(xrelations(net), collapse = ", "),
           call. = FALSE)
    }
    return(hit)
  }
  as.integer(relations)
}

# Normalise from/to into UCINET's three-column schedule.
recode_schedule <- function(from, to) {
  if (is.matrix(from)) {
    if (ncol(from) != 2) {
      stop("a matrix `from` must have two columns, low and high.", call. = FALSE)
    }
    from <- lapply(seq_len(nrow(from)), function(i) from[i, ])
  }
  if (!is.list(from)) from <- as.list(from)
  if (!length(from)) stop("from must name at least one value or range.", call. = FALSE)
  if (length(to) == 1) to <- rep(to, length(from))
  if (length(to) != length(from)) {
    stop("to must have one value for every rule in from, or exactly one ",
         "value for all of them.\n  from has ", length(from),
         " rule", if (length(from) == 1) "" else "s",
         ", to has ", length(to), ".", call. = FALSE)
  }
  rows <- lapply(seq_along(from), function(i) {
    v <- from[[i]]
    if (!is.numeric(v) || !length(v) %in% c(1, 2) || anyNA(v)) {
      stop("each rule in from must be one number or a c(low, high) pair; ",
           "rule ", i, " is neither.", call. = FALSE)
    }
    if (length(v) == 1) v <- c(v, v)
    c(low = min(v), high = max(v), new = to[[i]])
  })
  do.call(rbind, rows)
}

recode_matrix <- function(m, sched, diagonal, rows, cols) {
  if (nrow(m) != ncol(m)) diagonal <- TRUE
  where <- matrix(TRUE, nrow(m), ncol(m))
  if (!is.null(rows)) {
    where[] <- FALSE
    where[resolve_index(rows, rownames(m), "row"), ] <- TRUE
  }
  if (!is.null(cols)) {
    keep <- matrix(FALSE, nrow(m), ncol(m))
    keep[, resolve_index(cols, colnames(m), "column")] <- TRUE
    where <- where & keep
  }
  if (!diagonal) where[row(m) == col(m)] <- FALSE

  out <- m
  for (k in seq_len(nrow(sched))) {
    # Tested against m, the original, never against out.
    hit <- where & !is.na(m) & m >= sched[k, "low"] & m <= sched[k, "high"]
    out[hit] <- sched[k, "new"]
  }
  dimnames(out) <- dimnames(m)
  out
}
