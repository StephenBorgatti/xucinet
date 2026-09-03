#' @export
print.xucinet <- function(x, ...) {
  m <- as.matrix(x)
  cat(x$title, "\n", sep = "")
  cat(nrow(m), "rows,", ncol(m), "columns,", xnrelations(x),
      if (xnrelations(x) == 1) "relation;" else "relations;",
      x$mode, ";",
      if (isTRUE(x$directed)) "directed" else if (isFALSE(x$directed)) "undirected" else "directedness not determined",
      "\n")
  if (nrow(m) <= 30 && ncol(m) <= 30) {
    print(format_matrix(m), quote = FALSE, right = TRUE)
  } else {
    cat("(matrix larger than 30 x 30 not shown; use as.matrix() or xdisplay())\n")
  }
  invisible(x)
}

#' Display a dataset in UCINET's Data|Display style
#'
#' @param net A network (any accepted form).
#' @param relation Which relation to show for a multi-relation dataset.
#' @return The network, invisibly.
#' @export
xdisplay <- function(net, relation = NULL) {
  net <- as_xucinet(net)
  m <- as.matrix(net, relation = relation)
  cat(net$title, "\n\n", sep = "")
  print(format_matrix(m), quote = FALSE, right = TRUE)
  invisible(net)
}

# Format a numeric matrix the way UCINET's log does: integers as integers,
# non-integers to 3 decimals, missing as blank.
format_matrix <- function(m, digits = 3) {
  out <- m
  is_int <- all(m == round(m), na.rm = TRUE)
  out[] <- if (is_int) formatC(m, format = "d") else formatC(m, format = "f", digits = digits)
  out[is.na(m)] <- ""
  out
}

# ---- xucinet_output: the shared result class (SPEC D5) ----------------------

#' Construct a routine result
#'
#' Every analysis function returns an object of class `xucinet_output` plus a
#' routine-specific subclass. Printing reproduces the UCINET output log:
#' title line, input dataset name, assumptions block, aligned columns.
#'
#' @param routine Human-readable routine name, e.g. "DENSITY".
#' @param net The input `xucinet` object (for its title).
#' @param nodes Optional node-level data frame, in original node order.
#' @param summary Optional named list or data frame of whole-network statistics.
#' @param matrices Optional named list of matrix-valued results.
#' @param assumptions Character vector of notes such as "Data were symmetrized (max)".
#' @param subclass Character; additional S3 class to prepend.
#' @param call The call that produced the result.
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

#' @export
print.xucinet_output <- function(x, digits = 3, ...) {
  cat(toupper(x$routine), "\n", sep = "")
  cat("--------------------------------------------------------------------------------\n")
  cat("Input dataset:  ", x$dataset, "\n", sep = "")
  for (a in x$assumptions) cat("Note:           ", a, "\n", sep = "")
  cat("\n")
  if (!is.null(x$summary)) {
    s <- x$summary
    if (is.list(s) && !is.data.frame(s)) {
      nm <- format(names(s))
      for (i in seq_along(s)) cat(nm[i], "  ", format_number(s[[i]], digits), "\n", sep = "")
    } else print(s, digits = digits)
    cat("\n")
  }
  if (!is.null(x$nodes)) {
    print(format_df(x$nodes, digits), row.names = TRUE, right = TRUE)
    cat("\n")
  }
  for (nm in names(x$matrices)) {
    cat(nm, "\n", sep = "")
    print(format_matrix(x$matrices[[nm]], digits), quote = FALSE, right = TRUE)
    cat("\n")
  }
  invisible(x)
}

format_number <- function(v, digits = 3) {
  if (is.numeric(v) && all(v == round(v), na.rm = TRUE)) formatC(v, format = "d")
  else if (is.numeric(v)) formatC(v, format = "f", digits = digits)
  else as.character(v)
}

format_df <- function(df, digits = 3) {
  out <- df
  for (j in seq_along(df)) if (is.numeric(df[[j]])) out[[j]] <- format_number(df[[j]], digits)
  out
}

#' @export
as.data.frame.xucinet_output <- function(x, ...) {
  if (!is.null(x$nodes)) return(x$nodes)
  if (is.data.frame(x$summary)) return(x$summary)
  as.data.frame(x$summary, ...)
}
