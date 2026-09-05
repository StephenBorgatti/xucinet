# VNA, NetDraw's format. Sections introduced by a *keyword line:
#
#   *Node data         header of ID plus attribute names, then one row per node
#   *Node properties   NetDraw's display settings: colour, shape, coordinates
#   *Tie data          header of from, to and one column per relation
#
# Fields are separated by spaces or tabs and may be quoted. The node section is
# what makes VNA worth reading: it lists every node, so isolates survive, where
# an edge list on its own would silently drop them.

# Fields are separated by spaces or tabs in most VNA files and by commas in
# others, and the choice is made per line rather than per file: at least one
# file in the wild writes a whitespace header over comma-separated rows. Quoted
# runs are removed before looking for a comma, so a label containing one does
# not fool the test.
vna_fields <- function(line) {
  bare <- gsub('"[^"]*"', "", line)
  sep <- if (grepl(",", bare)) "," else ""
  out <- tryCatch(
    if (nzchar(sep)) {
      scan(text = line, what = "", sep = sep, quiet = TRUE, quote = "\"'")
    } else {
      scan(text = line, what = "", quiet = TRUE, quote = "\"'")
    },
    error = function(e) character(0))
  trimws(out)
}

vna_sections <- function(lines) {
  starts <- grep("^\\s*\\*", lines)
  if (!length(starts)) return(list())
  names <- tolower(trimws(sub("^\\s*\\*", "", lines[starts])))
  ends <- c(starts[-1] - 1L, length(lines))
  out <- lapply(seq_along(starts), function(k) {
    body <- if (ends[k] > starts[k]) lines[(starts[k] + 1L):ends[k]] else character(0)
    body[nzchar(trimws(body))]
  })
  stats::setNames(out, names)
}

#' Read a VNA file
#'
#' Reads NetDraw's VNA format: the `*Node data` section supplies the nodes and
#' any attributes, `*Tie data` supplies the ties, and one column per relation
#' becomes one relation in the result. `*Node properties`, which holds NetDraw's
#' colours and coordinates, is read for its node names but is display
#' information and is otherwise ignored.
#'
#' Taking the nodes from `*Node data` rather than from the ties is the point of
#' the format: isolates survive, where an edge list alone would lose them.
#'
#' @param file Path to the `.vna` file.
#' @param directed,mode,title Passed to [as_xucinet()].
#' @param ... Reserved.
#' @return An `xucinet` object, with any node attributes in `$attributes`
#'   (see [xattributes()]).
#' @seealso [xsavevna()]
#' @export
xreadvna <- function(file, directed = NULL, mode = NULL, title = NULL, ...) {
  if (!file.exists(file)) stop("No VNA file at '", file, "'.", call. = FALSE)
  lines <- readLines(file, warn = FALSE)

  secs <- vna_sections(lines)
  if (!length(secs)) {
    stop("'", basename(file), "' has no *section lines, so it is not a VNA file.\n",
         "  A VNA file starts with a line such as *Node data.", call. = FALSE)
  }
  if (any(grepl("^(ego|alter) data", names(secs)))) {
    stop("'", basename(file), "' is an E-Net egocentric VNA (*ego data / ",
         "*alter data), which is a different format that xucinet does not read ",
         "yet.", call. = FALSE)
  }

  node_sec <- secs[[grep("^node data", names(secs))[1]]]
  tie_sec <- secs[[grep("^tie data", names(secs))[1]]]
  if (is.null(tie_sec)) {
    stop("'", basename(file), "' has no *Tie data section, so it holds no ",
         "network.", call. = FALSE)
  }

  nodes <- NULL
  attrs <- NULL
  if (!is.null(node_sec) && length(node_sec) > 1L) {
    head <- vna_fields(node_sec[1])
    rows <- lapply(node_sec[-1], vna_fields)
    rows <- rows[lengths(rows) > 0L]
    nodes <- vapply(rows, function(r) r[1], character(1))
    if (length(head) > 1L) {
      wide <- do.call(rbind, lapply(rows, function(r) {
        length(r) <- length(head); r
      }))
      attrs <- vna_attribute_frame(wide[, -1, drop = FALSE], head[-1], nodes)
    }
  }

  head <- vna_fields(tie_sec[1])
  rows <- lapply(tie_sec[-1], vna_fields)
  rows <- rows[lengths(rows) >= 2L]
  if (!length(rows)) stop("'", basename(file), "' has an empty *Tie data section.",
                          call. = FALSE)
  wide <- do.call(rbind, lapply(rows, function(r) { length(r) <- length(head); r }))
  from <- wide[, 1]; to <- wide[, 2]
  if (is.null(nodes)) nodes <- unique(c(from, to))
  nodes <- unique(c(nodes, setdiff(c(from, to), nodes)))

  relnames <- if (length(head) > 2L) head[-(1:2)] else
    sub("\\.vna$", "", basename(file), ignore.case = TRUE)
  build <- function(v) {
    m <- matrix(0, length(nodes), length(nodes), dimnames = list(nodes, nodes))
    m[cbind(from, to)] <- v
    m
  }
  mats <- if (length(head) > 2L) {
    stats::setNames(lapply(seq_along(relnames), function(k)
      build(suppressWarnings(as.numeric(wide[, k + 2L])))), relnames)
  } else {
    stats::setNames(list(build(1)), relnames)
  }

  # A single-relation dataset takes its title as its relation name, which is the
  # invariant every other reader keeps. NetDraw names the network in the tie
  # column heading, so that becomes the title rather than being dropped:
  # animag.vna calls its one column ANIMAG, oracle.vna calls its discuss.
  if (is.null(title)) {
    title <- if (length(mats) == 1L && length(head) > 2L) names(mats)[1] else
      sub("\\.vna$", "", basename(file), ignore.case = TRUE)
  }
  net <- as_xucinet(if (length(mats) == 1L) mats[[1L]] else mats,
                    directed = directed, mode = mode, title = title)
  net$attributes <- attrs
  net
}

vna_attribute_frame <- function(cells, names, nodes) {
  cols <- lapply(seq_along(names), function(j) {
    v <- cells[, j]
    num <- suppressWarnings(as.numeric(v))
    if (all(is.na(num) == (is.na(v) | !nzchar(v)))) num else v
  })
  df <- as.data.frame(stats::setNames(cols, names), stringsAsFactors = FALSE,
                      check.names = FALSE)
  rownames(df) <- nodes
  df
}

#' Write a VNA file
#'
#' Writes NetDraw's VNA format: a `*Node data` section listing every node, so
#' isolates survive, then a `*Tie data` section with one column per relation.
#'
#' @param net A network (any accepted form).
#' @param file Output path. `.vna` is appended if it has no extension.
#' @param attributes Optional data frame of node attributes keyed by node label.
#'   Defaults to the network's own, if it has any.
#' @return The path written, invisibly.
#' @seealso [xreadvna()]
#' @examples
#' f <- file.path(tempdir(), "demo.vna")
#' xsavevna(matrix(c(0,1,0, 0,0,1, 0,0,0), 3, 3), f)
#' xreadvna(f)
#' @export
xsavevna <- function(net, file, attributes = NULL) {
  net <- as_xucinet(net)
  if (!grepl("\\.[A-Za-z0-9]+$", file)) file <- paste0(file, ".vna")
  if (is.null(attributes)) attributes <- net$attributes
  mats <- if (is.list(net$data)) net$data else list(net$data)
  names(mats) <- xrelations(net)
  nodes <- rownames(mats[[1L]])

  q <- function(x) paste0('"', x, '"')
  out <- "*Node data"
  if (is.null(attributes)) {
    out <- c(out, "ID", q(nodes))
  } else {
    out <- c(out, paste(c("ID", names(attributes)), collapse = " "),
             vapply(seq_along(nodes), function(i) {
               paste(c(q(nodes[i]), as.character(unlist(attributes[i, ]))),
                     collapse = " ")
             }, character(1)))
  }

  out <- c(out, "*Tie data", paste(c("from", "to", names(mats)), collapse = " "))
  idx <- which(Reduce(`|`, lapply(mats, function(m) m != 0 & !is.na(m))),
               arr.ind = TRUE)
  if (nrow(idx)) {
    idx <- idx[order(idx[, 1], idx[, 2]), , drop = FALSE]
    vals <- vapply(seq_len(nrow(idx)), function(k) {
      paste(vapply(mats, function(m) format_values(m[idx[k, 1], idx[k, 2]]),
                   character(1)), collapse = " ")
    }, character(1))
    out <- c(out, paste(q(nodes[idx[, 1]]), q(nodes[idx[, 2]]), trimws(vals)))
  }
  writeLines(out, file)
  invisible(file)
}
