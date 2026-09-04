#' @export
print.xucinet <- function(x, ...) {
  m <- as.matrix(x)
  k <- xnrelations(x)
  cat(x$title, "\n", sep = "")
  cat(nrow(m), "rows,", ncol(m), "columns,", k,
      if (k == 1) "relation;" else "relations;",
      x$mode, ";",
      if (isTRUE(x$directed)) "directed" else if (isFALSE(x$directed)) "undirected" else "directedness not determined",
      "\n")
  if (k > 1) cat("Relations:", paste(xrelations(x), collapse = ", "), "\n")
  if (nrow(m) > 30 || ncol(m) > 30) {
    cat("(matrix larger than 30 x 30 not shown; use as.matrix() or xdisplay())\n")
    return(invisible(x))
  }
  # One titled block per relation, as UCINET's display does for a stack.
  for (r in seq_len(k)) {
    if (k > 1) cat("\n", xrelations(x)[r], "\n", sep = "")
    print(format_matrix(as.matrix(x, relation = r)), quote = FALSE, right = TRUE)
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

# The xucinet_output result class, its print/summary/as.data.frame methods and
# the shared number formatting all live in R/output.R.
