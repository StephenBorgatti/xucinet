# Bipartite: 2-mode to a square 1-mode matrix.
#
# UCINET: Transform | Graph Theoretic | Bipartite (Xbipart.pas, bipartite;
# repository StephenBorgatti/ucinet at commit c7b4956). The (nr + nc) square
# matrix: rows first, then columns; the row-by-row and column-by-column blocks
# filled with the fill value (0 by default); the original matrix top right
# and, with "Symmetric" Yes (the default), its transpose bottom left. Labels
# are the row labels then the column labels, each with an optional prefix.
# Only the first relation is converted, as UCINET's d.loaddat is called once.
#
# UCINET saves the result under the dialog's fixed default name "bi"; the
# title here is the input's with "-bi" added, so it still says what it came
# from. The design answer 13.2 adds a `mode` column to $attributes, so later
# routines can tell the two node sets apart.

#' Bipartite representation of a 2-mode network
#'
#' UCINET: Transform | Graph Theoretic | Bipartite. Turns a 2-mode network of
#' `nr` rows by `nc` columns into a 1-mode network of `nr + nc` nodes, the
#' rows followed by the columns, in which a row node is tied to the column
#' nodes it had a tie with. Rows are never tied to rows, nor columns to
#' columns.
#'
#' `$attributes` has a `mode` column, `"row"` or `"col"`, so a plot or a
#' later routine can tell the two kinds of node apart.
#'
#' @section UCINET equivalent:
#' Transform | Graph Theoretic | Bipartite. *Value to fill blocks* is `fill`,
#' *Symmetric* is `symmetric`, the label prefixes are `rowprefix` and
#' `colprefix`.
#'
#' @param net A 2-mode network (any accepted form).
#' @param relation Which relation, by name or position. Defaults to the first,
#'   the only one UCINET converts.
#' @param fill The value of the row-by-row and column-by-column blocks. 0 by
#'   default; `NA` for missing.
#' @param symmetric Put the transpose in the bottom-left block, making the
#'   result undirected? `TRUE` by default.
#' @param rowprefix,colprefix Text put in front of the row and column labels.
#' @return An `xucinet` object: 1-mode, `nr + nc` nodes, undirected when
#'   `symmetric`, with `$attributes$mode`.
#' @seealso [xaffiliations()], [xbicliques()].
#' @examples
#' b <- xbipartite(davis)
#' xattributes(b)
#' @export
xbipartite <- function(net, relation = NULL, fill = 0, symmetric = TRUE,
                       rowprefix = "", colprefix = "") {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  nr <- nrow(m); nc <- ncol(m)
  n <- nr + nc
  rl <- rownames(m); if (is.null(rl)) rl <- as.character(seq_len(nr))
  cl <- colnames(m); if (is.null(cl)) cl <- as.character(seq_len(nc))
  labels <- c(paste0(rowprefix, rl), paste0(colprefix, cl))
  if (anyDuplicated(labels)) {
    stop("xbipartite(): a row and a column share the label '",
         labels[anyDuplicated(labels)], "'.\n",
         "  Give one mode a prefix, e.g. colprefix = \"e_\".", call. = FALSE)
  }

  y <- matrix(fill, n, n, dimnames = list(labels, labels))
  y[seq_len(nr), nr + seq_len(nc)] <- m
  y[nr + seq_len(nc), seq_len(nr)] <- if (isTRUE(symmetric)) t(m) else fill

  out <- as_xucinet(y, directed = !isTRUE(symmetric), mode = "1-mode",
                    title = paste0(net$title, "-bi"))
  out$attributes <- data.frame(mode = rep(c("row", "col"), c(nr, nc)),
                               row.names = labels, stringsAsFactors = FALSE)
  attr(out, "history") <- c(attr(net, "history"), sprintf(
    "bipartite: %d rows and %d columns as %d nodes", nr, nc, n))
  out
}
