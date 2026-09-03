#' Density and average degree
#'
#' UCINET: Network | Whole Networks | Density | Density Overall. Phase 0 pilot
#' routine: the first function golden-tested against UCINET output, and the
#' template every later routine follows.
#'
#' @param net A network (any accepted form).
#' @param directed `NULL` (detect), `TRUE` or `FALSE`. Detection is reported as
#'   an assumption in the printed output.
#' @param weighted `NULL` (use values if the matrix is valued), `TRUE` or
#'   `FALSE` (dichotomize at > 0 first).
#' @param diagonal Logical; include the diagonal? UCINET's default is `FALSE`.
#' @return An object of class `c("xdensity", "xucinet_output")` with `$summary`
#'   holding density, average degree, standard deviation of ties, and number
#'   of ties; one section per relation for multi-relation data.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
#' xdensity(m)
#' @export
xdensity <- function(net, directed = NULL, weighted = NULL, diagonal = FALSE) {
  net <- xnet(net, substitute(net), directed = directed)
  m <- as.matrix(net)
  assumptions <- character()
  if (is.null(directed)) {
    assumptions <- c(assumptions, sprintf("Data treated as %s (detected from symmetry).",
                                          if (isTRUE(net$directed)) "directed" else "undirected"))
  }
  valued <- any(m != 0 & m != 1, na.rm = TRUE)
  if (isFALSE(weighted) && valued) {
    m <- (m > 0) * 1
    assumptions <- c(assumptions, "Data dichotomized at > 0.")
  }
  if (!diagonal) diag(m) <- NA
  n <- nrow(m)
  cells <- if (diagonal) m else m[row(m) != col(m)]
  cells <- cells[!is.na(cells)]
  density <- mean(cells)
  ties <- sum(cells != 0)
  avg_degree <- sum(m, na.rm = TRUE) / n
  summary <- list("Density" = density,
                  "Avg Degree" = avg_degree,
                  "Std Dev" = stats::sd(cells),
                  "No. of Ties" = ties)
  new_xucinet_output("Density", net, summary = summary, assumptions = assumptions,
                     subclass = "xdensity", call = match.call())
}
