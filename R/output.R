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

# UCINET's matrix layout, ported from its own logs (inst/goldens/density/
# "density log.txt" and log_make_goldens.txt):
#
#                    1     2     3     4
#                Densi No. o Std D Avg D
#                   ty f Tie    ev egree
#                          s
#                ----- ----- ----- -----
#      1 campnet 0.176    54 0.381     3
#
# The rules, read off those logs:
#   - the column width comes from the VALUES, never from the labels;
#   - a label too wide for it wraps into as many chunks as it needs, each right
#     aligned, stacked downwards from the first header line;
#   - the stub is a 6-wide row number, a space, the row labels right aligned to
#     their widest, and a space;
#   - every column is its value right aligned in the width, then one space.
format_uci_matrix <- function(m, digits = 3, footer = TRUE, by_column = TRUE) {
  m <- as.matrix(m)
  nr <- nrow(m); nc <- ncol(m)
  if (nr == 0L || nc == 0L) return("(empty matrix)")
  # Decimals: `if istable then getwdbycol else getwd` in tmat.display. Either
  # way the test is "is it integer valued", and the answer decides between 0
  # decimals and defaultd = -3, which means three, always shown. What changes is
  # the scope of the question.
  #
  #   by_column = TRUE  (istable): asked per column. UCINET's Density report
  #     prints 89 bare next to 0.353, because Ties is an integer column.
  #   by_column = FALSE (not istable): asked once for the whole matrix. UCINET's
  #     Degree Measures table prints 3.000 and 4.000 next to 0.176, because one
  #     non-integer anywhere puts every column on three decimals.
  #
  # Both are pinned by goldens: density/density_menu_log.txt for the first,
  # centrality/log_menu.txt for the second.
  vals <- if (by_column) {
    vapply(seq_len(nc), function(j) format_values(m[, j], digits), character(nr))
  } else {
    matrix(format_values(as.vector(m), digits), nr, nc)
  }
  dim(vals) <- c(nr, nc)
  w <- max(nchar(vals), nchar(as.character(nc)))
  vals[] <- formatC(vals, width = w)
  rlab <- rownames(m); if (is.null(rlab)) rlab <- as.character(seq_len(nr))
  clab <- colnames(m); if (is.null(clab)) clab <- as.character(seq_len(nc))
  idxw <- max(6L, nchar(as.character(nr)))
  stub <- strrep(" ", idxw + 1L + max(nchar(rlab)) + 1L)
  band <- function(cells) paste0(paste0(formatC(cells, width = w), " ", collapse = ""))

  lines <- paste0(stub, band(as.character(seq_len(nc))))
  # Labels wrap into w-character chunks, top aligned, blank where they run out.
  chunks <- lapply(clab, function(s) {
    if (!nzchar(s)) return("")
    vapply(seq_len(ceiling(nchar(s) / w)),
           function(i) substr(s, (i - 1L) * w + 1L, i * w), character(1))
  })
  for (li in seq_len(max(1L, max(lengths(chunks))))) {
    lines <- c(lines, paste0(stub, band(vapply(chunks, function(ch)
      if (li <= length(ch)) ch[li] else "", character(1)))))
  }
  lines <- c(lines, paste0(stub, band(rep(strrep("-", w), nc))))
  for (i in seq_len(nr)) {
    lines <- c(lines, paste0(formatC(as.character(i), width = idxw), " ",
                             formatC(rlab[i], width = max(nchar(rlab))), " ",
                             band(vals[i, ])))
  }
  if (footer) {
    lines <- c(lines, "",
               sprintf("%d rows, %d columns, 1 levels.", nr, nc))
  }
  lines
}

cat_uci_matrix <- function(m, digits = 3, footer = TRUE, by_column = TRUE) {
  cat(format_uci_matrix(m, digits, footer, by_column), sep = "\n")
  invisible(NULL)
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
#' @param nodes_title Title UCINET prints above the node table, e.g.
#'   `"Degree Measures"`. `NULL` prints the table with no title.
#' @param summary_title Title UCINET prints above the whole-network block when it
#'   renders it as a titled matrix rather than as bare label/value lines.
#' @param stats_block Does UCINET print its descriptive-statistics block for this
#'   routine? It is not universal: `XFreeBet.pas` and `xcentrality.pas` print
#'   `DESCRIPTIVE STATISTICS FOR EACH MEASURE`, `uc_DegreeCentrality.pas` and
#'   `uc_ClosenessMeasures.pas` print nothing of the kind. So the routine
#'   decides, rather than the printer assuming.
#' @param fields Optional named character vector of header lines UCINET prints
#'   with `log.putstr()` before the dataset name, such as `c("Method:" =
#'   "AVERAGE", "Type of Data:" = "Dissimilarities")`. Printed label-padded in
#'   the same way as `Input dataset:`.
#' @param preamble Optional character vector of preformatted lines printed after
#'   the header block and before any table, for output that is not a matrix,
#'   such as the text cluster diagram of Johnson's clustering.
#' @param print_nodes Print the node table? `TRUE` by default. `FALSE` keeps it
#'   in the object without printing it, for a routine whose UCINET log does not
#'   show a table it saves, such as the partition matrix of Johnson's
#'   clustering.
#' @param hide Names of `matrices` kept in the object but not printed, for a
#'   matrix UCINET saves without showing it in the log (the clique
#'   co-membership matrix).
#' @param epilogue Optional preformatted lines printed after every table, for
#'   output UCINET places last, such as the clustering diagram that ends the
#'   Cliques report.
#' @param show_summary,show_columns Which entries of `$summary`, and which
#'   columns of `$nodes`, the report prints, in the order given. `NULL`, the
#'   default, prints them all. This is how an argument chooses what is printed
#'   without changing what the object holds (SPEC addendum, 23 September 2026,
#'   item 5).
#' @param show_matrix_columns A named list: for each matrix named, which of its
#'   columns the report prints. Matrices not named print whole. Girvan-Newman
#'   uses it to print only the partitions UCINET would reach with `k`.
#' @return An object of class `xucinet_output`.
#' @keywords internal
#' @export
new_xucinet_output <- function(routine, net, nodes = NULL, summary = NULL,
                               matrices = NULL, assumptions = character(),
                               subclass = NULL, call = sys.call(-1),
                               nodes_title = NULL, summary_title = NULL,
                               stats_block = FALSE, fields = NULL,
                               preamble = NULL, print_nodes = TRUE,
                               hide = character(), epilogue = NULL,
                               show_summary = NULL, show_columns = NULL,
                               show_matrix_columns = NULL) {
  structure(
    list(routine = routine, dataset = net$title, nodes = nodes, summary = summary,
         matrices = matrices, assumptions = assumptions, call = call,
         nodes_title = nodes_title, summary_title = summary_title,
         stats_block = stats_block, fields = fields, preamble = preamble,
         print_nodes = print_nodes, hide = hide, epilogue = epilogue,
         show_summary = show_summary, show_columns = show_columns,
         show_matrix_columns = show_matrix_columns),
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
#' @param stats Show the descriptive-statistics block under a node table? The
#'   default, `NULL`, follows UCINET: the block appears for the routines that
#'   print one and not for the routines that do not.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
print.xucinet_output <- function(x, digits = 3, sort = NULL, stats = NULL, ...) {
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
  if (is.null(stats)) stats <- isTRUE(x$stats_block)

  cat(toupper(x$routine), "\n", sep = "")
  rule()
  cat("\n")
  # UCINET pads its header labels to column 40 before the value.
  field <- function(label, value) cat(formatC(label, width = -40), value, "\n", sep = "")
  # Routine-specific header lines come first, as UCINET's log.putstr() calls
  # precede log.dataset() (XCluster.pas prints Method: and Type of Data: before
  # the dataset name).
  for (nm in names(x$fields)) field(nm, x$fields[[nm]])
  field("Input dataset:", x$dataset)
  for (a in x$assumptions) field("Note:", a)
  cat("\n\n\n")
  if (length(x$preamble)) {
    cat(x$preamble, sep = "\n")
    cat("\n")
  }

  # UCINET prints the whole-network block BEFORE a node table only when there is
  # no node table - density is its own report. Where a routine has both, as
  # every centrality routine does, the node table comes first and the graph-level
  # figure follows it. Ordering here rather than in each routine keeps the
  # routines free of display logic.
  summary_block <- function() {
    if (is.null(x$summary)) return(invisible(NULL))
    if (!is.null(x$summary_title)) cat(x$summary_title, "\n\n", sep = "")
    s <- x$summary
    if (!is.null(x$show_summary)) {
      s <- if (is.data.frame(s)) s[, x$show_summary, drop = FALSE] else s[x$show_summary]
    }
    if (is.list(s) && !is.data.frame(s)) {
      m <- matrix(vapply(s, function(v) as.numeric(v)[1], numeric(1)), nrow = 1,
                  dimnames = list(x$dataset, names(s)))
      cat_uci_matrix(m, digits)
    } else {
      cat_uci_matrix(as.matrix(s), digits)
    }
    cat("\n")
  }

  # A node table the routine keeps but UCINET does not print behaves, for
  # printing, as if there were none.
  show_nodes <- !is.null(x$nodes) && !isFALSE(x$print_nodes)

  if (!show_nodes) summary_block()

  if (show_nodes) {
    nodes <- x$nodes
    if (!is.null(x$show_columns)) nodes <- nodes[, x$show_columns, drop = FALSE]
    # The statistics describe the measure, not the view of it, so they are taken
    # from the full table before any sorting or subsetting (SPEC ch 9 decision 2).
    block <- if (isTRUE(stats)) uci_stats_block(nodes) else NULL
    if (!is.null(sort_col)) {
      nodes <- nodes[order(x$nodes[[sort_col]], decreasing = TRUE), , drop = FALSE]
    }
    if (!is.null(x$nodes_title)) cat(x$nodes_title, "\n\n", sep = "")
    # A node table is saved as a plain dataset rather than a table, so decimals
    # are decided across the whole matrix: see format_uci_matrix().
    cat_uci_matrix(as.matrix(nodes), digits, by_column = FALSE)
    cat("\n")
    if (!is.null(block)) {
      cat("DESCRIPTIVE STATISTICS FOR EACH MEASURE\n\n")
      cat_uci_matrix(as.matrix(block), digits, footer = FALSE, by_column = FALSE)
      cat("\n")
    }
    summary_block()
  }

  for (nm in names(x$matrices)) {
    if (nm %in% x$hide) next
    mat <- x$matrices[[nm]]
    keep <- x$show_matrix_columns[[nm]]
    if (!is.null(keep)) mat <- mat[, keep, drop = FALSE]
    cat(nm, "\n\n", sep = "")
    cat_uci_matrix(mat, digits)
    cat("\n")
  }
  if (length(x$epilogue)) {
    cat(x$epilogue, sep = "\n")
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

# ---- the text cluster diagram -----------------------------------------------
#
# UCINET's Johnson's Hierarchical Clustering report draws its cluster diagram
# with Text_Dendrogram in Tools/G1Tools/Udendro.pas (GetBestPerm for the item
# order, dendroguts for the rows), called from XCluster.pas with flip = false,
# label "Level" and character "X". This reproduces it line for line:
#
#   HIERARCHICAL CLUSTERING
#
#              M       C
#              i S     h
#              a e   B i
#              m a D o c
#              i t C s a
#              . . . . .
#   Level      3 8 2 1 4
#   -----      - - - - -
#     206      . . . XXX .
#     ...
#
# `part` is the item-by-level partition matrix (integer cluster ids), `levels`
# the level labels already formatted to UCINET's decimals (see hclust_decimals),
# `ids` the pre-renumbering cluster ids GetBestPerm sorts on (in UCINET these
# are Johnson2's own, which are the largest original index in each cluster),
# and `labels` the item labels.

# GetBestPerm: a shell sort of the items on their cluster ids, coarsest level
# first (branchesup = TRUE), ties broken by the next finer level. Ported as a
# comparison plus order() rather than as the shell sort, which gives the same
# permutation because the comparison is a total order on distinct rows and
# GetBestPerm's swap-on-strict-less keeps original order among equal rows, as
# a stable sort does.
uci_dendrogram_order <- function(ids) {
  keys <- lapply(rev(seq_len(ncol(ids))), function(k) ids[, k])
  do.call(order, c(keys, list(seq_len(nrow(ids)))))
}

format_uci_dendrogram <- function(part, levels, ids, labels,
                                  title = "HIERARCHICAL CLUSTERING",
                                  lab = "Level", ch = "X") {
  n <- nrow(part); npart <- ncol(part)
  bp <- uci_dendrogram_order(ids)
  # clen(): labels are cut to 11 characters in the diagram, whatever the
  # dataset holds.
  cl <- pmin(nchar(labels), 11L)
  rw <- max(nchar(lab), max(nchar(levels)))
  lines <- character()
  if (nzchar(title)) lines <- c(lines, toupper(title), "")
  stub <- strrep(" ", rw + 2L)
  # Labels written downwards, bottom-aligned, each character right-aligned in
  # a two-character column.
  maxclen <- max(cl[bp])
  for (k in seq(maxclen, 1L)) {
    cells <- vapply(bp, function(j) {
      if (cl[j] >= k) {
        s <- substr(labels[j], 1L, cl[j])
        formatC(substr(s, cl[j] - k + 1L, cl[j] - k + 1L), width = 2L)
      } else "  "
    }, character(1))
    lines <- c(lines, paste0(stub, paste(cells, collapse = "")))
  }
  lines <- c(lines, "")
  # The item numbers, one digit per row, units row carrying the level label.
  num <- formatC(bp, width = 4L)
  digit_row <- function(pos, prefix = "") {
    paste0(formatC(prefix, width = rw), "  ",
           paste(formatC(substr(num, pos, pos), width = 2L), collapse = ""))
  }
  if (n > 999) lines <- c(lines, digit_row(1L))
  if (n > 99)  lines <- c(lines, digit_row(2L))
  if (n > 9)   lines <- c(lines, digit_row(3L))
  lines <- c(lines, digit_row(4L, lab))
  lines <- c(lines, paste0(strrep("-", rw), "  ", paste(rep(" -", n), collapse = "")))
  # dendroguts, rows in level order (flip = false).
  for (it in seq_len(npart)) {
    cc <- rep(" ", n); ss <- rep(" ", n)
    lastp <- 0L; cc[n] <- "."
    for (j in seq_len(n)) {
      p <- part[bp[j], it]
      if (identical(p, lastp)) {
        cc[j] <- ch
        if (j > 1L) { ss[j - 1L] <- ch; cc[j - 1L] <- ch }
      } else {
        cc[j] <- "."
        ss[j] <- " "
      }
      lastp <- p
    }
    body <- paste0(paste0(cc[-n], ss[-n], collapse = ""), cc[n])
    lines <- c(lines, paste0(formatC(levels[it], width = rw), "   ", body))
  }
  lines
}

cat_uci_dendrogram <- function(...) {
  cat(format_uci_dendrogram(...), sep = "\n")
  invisible(NULL)
}
