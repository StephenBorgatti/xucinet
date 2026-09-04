# The descriptive-statistics block UCINET prints under a node-level table.
#
# Labels, order and formulas are ported from uestimator and setstatlabels in
# Tools/G1Tools/ustats.pas, not written from memory. The two that matter:
#
#   variance := mcssq / n        so Variance and Std Dev are the POPULATION
#   stddev   := sqrt(variance)   forms, dividing by n. R's var() and sd() divide
#                                by n - 1, so using them here would put every
#                                number slightly out against UCINET.
#
# A value is missing when it is at or above na = 1e37 (tsmat.isna); by the time
# data reaches R that is already NA, so NAs are what we count.

uci_stat_labels <- c("Mean", "Std Dev", "Sum", "Variance", "SSQ", "MCSSQ",
                     "Euc Norm", "Minimum", "Maximum", "N of Obs", "N Missing")

# The eleven statistics, in UCINET's order, for one numeric vector.
uci_stats <- function(x) {
  x <- as.numeric(x)
  nmiss <- sum(is.na(x))
  v <- x[!is.na(x)]
  n <- length(v)
  if (n == 0L) {
    out <- rep(NA_real_, 11)
    out[10:11] <- c(0, nmiss)
    names(out) <- uci_stat_labels
    return(out)
  }
  mean <- sum(v) / n
  ssq <- sum(v * v)
  mcssq <- sum((v - mean)^2)
  variance <- mcssq / n              # population, as UCINET does
  stats::setNames(
    c(mean, sqrt(variance), sum(v), variance, ssq, mcssq, sqrt(ssq),
      min(v), max(v), n, nmiss),
    uci_stat_labels)
}

# The block as a data frame: one row per statistic, one column per input column.
uci_stats_block <- function(df) {
  num <- vapply(df, is.numeric, logical(1))
  if (!any(num)) return(NULL)
  block <- vapply(df[num], uci_stats, numeric(11))
  out <- as.data.frame(block, stringsAsFactors = FALSE)
  names(out) <- names(df)[num]
  rownames(out) <- uci_stat_labels
  out
}

# ---- display formatting -----------------------------------------------------

# Format a numeric vector the way UCINET's log does. ucommon.pas sets
# defaultd = -3, which means up to three decimals with whole numbers shown bare,
# so 1 prints as 1 and 0.1764 as 0.176. Display only: the stored value keeps
# full precision. Everything is right-aligned to a common width so columns line
# up under their headings.
format_values <- function(x, digits = 3) {
  if (!is.numeric(x)) return(format(as.character(x)))
  out <- character(length(x))
  ok <- !is.na(x) & is.finite(x)
  # The decision is made once for the whole column, not per cell: a column
  # holding 1 and 0.5 prints 1.000 and 0.500, so the decimal points line up.
  if (all(x[ok] == round(x[ok]))) {
    out[ok] <- formatC(x[ok], format = "d")
  } else {
    out[ok] <- formatC(x[ok], format = "f", digits = digits)
  }
  out[!is.na(x) & !is.finite(x)] <- formatC(x[!is.na(x) & !is.finite(x)])
  out[is.na(x)] <- ""
  formatC(out, width = max(0L, max(nchar(out))), flag = "")
}

format_df <- function(df, digits = 3) {
  out <- df
  for (j in seq_along(df)) out[[j]] <- format_values(df[[j]], digits)
  out
}

# Format a numeric matrix, one width for the whole matrix so the grid lines up.
format_matrix <- function(m, digits = 3) {
  out <- m
  out[] <- format_values(as.vector(m), digits)
  dimnames(out) <- dimnames(m)
  out
}

format_number <- function(v, digits = 3) format_values(v, digits)

# ---- the result object ------------------------------------------------------

#' Construct a routine result
#'
#' Every analysis function returns an object of class `xucinet_output` plus a
#' routine-specific subclass. Printing reproduces the UCINET output log: title
#' line, input dataset name, assumptions block, aligned columns, and, under a
#' node-level table, UCINET's eleven descriptive statistics.
#'
#' @param routine Human-readable routine name, e.g. "DENSITY".
#' @param net The input `xucinet` object (for its title).
#' @param nodes Optional node-level data frame, in original node order.
#' @param summary Optional named list or data frame of whole-network statistics.
#' @param matrices Optional named list of matrix-valued results.
#' @param assumptions Character vector of notes such as "Data were symmetrized (max)".
#' @param subclass Character; additional S3 class to prepend.
#' @param call The call that produced the result.
#' @return An object of class `xucinet_output`.
#' @keywords internal
#' @export
new_xucinet_output <- function(routine, net, nodes = NULL, summary = NULL,
                               matrices = NULL, assumptions = character(),
                               subclass = NULL, call = sys.call(-1)) {
  structure(
    list(routine = routine, dataset = net$title, nodes = nodes, summary = summary,
         matrices = matrices, assumptions = assumptions, call = call),
    class = c(subclass, "xucinet_output")
  )
}

rule <- function() {
  cat(strrep("-", 80), "\n", sep = "")
}

#' Print a routine result in UCINET's log format
#'
#' @param x An `xucinet_output` object.
#' @param digits Decimal places for display. Stored values keep full precision.
#' @param sort Optional: name or position of a column of `$nodes` to sort the
#'   printed table by, largest first. The default, `NULL`, keeps the original
#'   node order, which is what UCINET's datasets are stored in and what makes
#'   rows line up across measures.
#' @param stats Show the descriptive-statistics block under a node table?
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.xucinet_output <- function(x, digits = 3, sort = NULL, stats = TRUE, ...) {
  # Checked before anything is printed, so a bad sort= does not leave half a
  # report on screen above the error.
  sort_col <- NULL
  if (!is.null(sort) && !is.null(x$nodes)) {
    sort_col <- if (is.character(sort)) match(sort, names(x$nodes)) else as.integer(sort)
    if (is.na(sort_col) || sort_col < 1 || sort_col > ncol(x$nodes)) {
      stop("sort must name a column of the node table.\n  Available: ",
           paste(names(x$nodes), collapse = ", "), call. = FALSE)
    }
  }
  cat(toupper(x$routine), "\n", sep = "")
  rule()
  cat("Input dataset:  ", x$dataset, "\n", sep = "")
  for (a in x$assumptions) cat("Note:           ", a, "\n", sep = "")
  cat("\n")

  if (!is.null(x$summary)) {
    s <- x$summary
    if (is.list(s) && !is.data.frame(s)) {
      nm <- format(names(s))
      # Each entry is its own quantity - a density, a count, an average - so
      # each is formatted on its own terms, then padded to a common width.
      vals <- vapply(s, function(v) format_values(as.numeric(v)[1], digits),
                     character(1))
      vals <- formatC(vals, width = max(nchar(vals)))
      for (i in seq_along(s)) cat(nm[i], "  ", vals[i], "\n", sep = "")
    } else {
      print(format_df(s, digits), right = TRUE)
    }
    cat("\n")
  }

  if (!is.null(x$nodes)) {
    nodes <- x$nodes
    if (!is.null(sort_col)) {
      nodes <- nodes[order(nodes[[sort_col]], decreasing = TRUE), , drop = FALSE]
    }
    print(format_df(nodes, digits), right = TRUE)
    cat("\n")
    if (isTRUE(stats)) {
      block <- uci_stats_block(nodes)
      if (!is.null(block)) {
        cat("DESCRIPTIVE STATISTICS\n\n")
        print(format_df(block, digits), right = TRUE)
        cat("\n")
      }
    }
  }

  for (nm in names(x$matrices)) {
    cat(nm, "\n", sep = "")
    print(format_matrix(x$matrices[[nm]], digits), quote = FALSE, right = TRUE)
    cat("\n")
  }
  invisible(x)
}

#' Summarise a routine result
#'
#' Returns the whole-network statistics as a one-row data frame, or, when the
#' routine produced a node-level table, UCINET's eleven descriptive statistics
#' for each of its columns.
#'
#' @param object An `xucinet_output` object.
#' @param ... Unused.
#' @return A data frame.
#' @export
summary.xucinet_output <- function(object, ...) {
  if (!is.null(object$nodes)) {
    block <- uci_stats_block(object$nodes)
    if (!is.null(block)) return(block)
  }
  s <- object$summary
  if (is.null(s)) return(data.frame())
  if (is.data.frame(s)) return(s)
  as.data.frame(s, stringsAsFactors = FALSE, check.names = FALSE)
}

#' @export
as.data.frame.xucinet_output <- function(x, ...) {
  if (!is.null(x$nodes)) return(x$nodes)
  if (is.data.frame(x$summary)) return(x$summary)
  as.data.frame(x$summary, stringsAsFactors = FALSE, check.names = FALSE)
}
