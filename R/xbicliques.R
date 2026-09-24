# Bicliques.
#
# UCINET has no menu item for bicliques; the command language's biclique()
# does it (Xdpmat.pas, runbiclique; repository StephenBorgatti/ucinet at
# commit c7b4956): make the bipartite graph (makebipartite), find its
# 2-cliques of at least min rows + min columns nodes (getncliques in
# G2Tools/ug2clique.pas: the within-distance-2 graph, then BronKerbosch in
# G2Tools/ubronkb.pas; tools commit 207958a), and drop those with fewer than
# the minimum rows or columns. Defaults 3 and 3.
#
# In a bipartite graph a row and a column are at odd distance, so a 2-clique
# that contains a row and a column has every row tied to every column, and
# its rows (and columns) are within two steps through them: the 2-cliques with
# both kinds of node are exactly the maximal complete bipartite subgraphs.
# ubronkb's BronKerbosch is the same Algorithm 457 as uclique's, which
# xcliques() ports step for step, so the port is reused and the bicliques come
# in UCINET's order.

#' Bicliques
#'
#' A biclique of a 2-mode network is a set of rows and a set of columns in
#' which every row is tied to every column, and to which no row or column can
#' be added: the 2-mode counterpart of a clique. In the Davis data, a set of
#' women who all attended the same set of events.
#'
#' UCINET finds them with the command-language function `biclique()`; there is
#' no menu item. The result is shaped like [xcliques()]': the bicliques in the
#' order UCINET finds them, a participation matrix for each mode, and the
#' co-membership of each mode.
#'
#' @section UCINET equivalent:
#' The command `bc = biclique(davis 3 3)`.
#'
#' @param net A 2-mode network (any accepted form). Values above 0 are ties.
#' @param min_rows,min_cols The fewest rows and columns a biclique may have.
#'   UCINET's defaults are 3 and 3.
#' @param relation Which relation, by name or position. Defaults to the first.
#' @return An object of class `c("xbicliques", "xucinet_output")`.
#'   `$bicliques` lists each biclique's `rows` and `cols`. `$matrices` holds,
#'   for each mode, the participation matrix (the share of the biclique's
#'   other-mode members each node is tied to, 1 for members) and the
#'   co-membership matrix (the number of bicliques two nodes share; the
#'   diagonal is the number each is in), and the co-membership of all the
#'   nodes together, which is clustered by average link (the book's Figure
#'   13.4); `$clustering` holds that clustering.
#' @seealso [xcliques()], [xbipartite()].
#' @examples
#' xbicliques(davis)
#' @export
xbicliques <- function(net, min_rows = 3, min_cols = 3, relation = NULL) {
  net <- xnet(net, substitute(net))
  m <- as.matrix(net, relation = relation)
  nr <- nrow(m); nc <- ncol(m)
  rl <- rownames(m); if (is.null(rl)) rl <- as.character(seq_len(nr))
  cl <- colnames(m); if (is.null(cl)) cl <- as.character(seq_len(nc))
  assumptions <- character()
  vals <- m[!is.na(m)]
  if (any(vals != 0 & vals != 1)) {
    assumptions <- "Valued data. All values > 0 treated as 1."
  }
  tie <- !is.na(m) & m > 0

  # makebipartite, then getwithindist(d, 2)
  n <- nr + nc
  a <- matrix(FALSE, n, n)
  a[seq_len(nr), nr + seq_len(nc)] <- tie
  a[nr + seq_len(nc), seq_len(nr)] <- t(tie)
  two <- (a | (a %*% a) > 0)
  diag(two) <- FALSE

  found <- bron_kerbosch_v2(two, min_rows + min_cols)
  keep <- vapply(found, function(ix) {
    sum(ix <= nr) >= min_rows && sum(ix > nr) >= min_cols
  }, logical(1))
  found <- found[keep]
  k <- length(found)
  bicl <- lapply(found, function(ix) {
    ix <- sort(ix)
    list(rows = rl[ix[ix <= nr]], cols = cl[ix[ix > nr] - nr])
  })

  ids <- as.character(seq_len(k))
  rmem <- matrix(0, nr, k, dimnames = list(rl, ids))
  cmem <- matrix(0, nc, k, dimnames = list(cl, ids))
  rpart <- rmem; cpart <- cmem
  for (j in seq_len(k)) {
    r <- match(bicl[[j]]$rows, rl); cc <- match(bicl[[j]]$cols, cl)
    rmem[r, j] <- 1; cmem[cc, j] <- 1
    rpart[, j] <- rowSums(tie[, cc, drop = FALSE]) / length(cc)
    cpart[, j] <- colSums(tie[r, , drop = FALSE]) / length(r)
  }
  rco <- rmem %*% t(rmem); cco <- cmem %*% t(cmem)

  # The book's Figure 13.4: the co-membership of all the nodes, rows and
  # columns together, clustered by average link as xcliques() clusters its
  # co-membership. UCINET's biclique() saves the bicliques only; this is an
  # addition (ledger entry 37).
  allmem <- rbind(rmem, cmem)
  aco <- allmem %*% t(allmem)
  clustering <- NULL
  epilogue <- NULL
  if (k > 0 && n > 2) {
    clustering <- xhclust(aco, type = "similarities", method = "average",
                          plot = FALSE)
    epilogue <- clustering$preamble
    epilogue[1] <- toupper("Hierarchical Clustering of Biclique Co-membership")
  }

  preamble <- c(paste0(k, " bicliques found."), "",
                vapply(seq_len(k), function(j) {
                  paste0(formatC(j, width = 4), ":  ",
                         paste(bicl[[j]]$rows, collapse = " "), "  |  ",
                         paste(bicl[[j]]$cols, collapse = " "))
                }, character(1)))

  out <- new_xucinet_output(
    "Bicliques", net,
    matrices = list(`Row participation` = rpart,
                    `Column participation` = cpart,
                    `Row co-membership` = rco,
                    `Column co-membership` = cco, `Co-membership` = aco),
    assumptions = assumptions,
    fields = c("Minimum rows:" = format(min_rows),
               "Minimum columns:" = format(min_cols)),
    preamble = preamble,
    hide = c("Row co-membership", "Column co-membership", "Co-membership"),
    epilogue = epilogue,
    subclass = "xbicliques", call = match.call())
  out$bicliques <- bicl
  out$clustering <- clustering
  out
}
