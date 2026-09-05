# Reading delimited text and spreadsheets, and working out what shape the data
# is in without being told.
#
# The three layouts, in UCINET's vocabulary:
#
#   matrix    labels down the first column, labels across the header, numbers
#             in the body. Includes attribute tables, which are a nodes-by-
#             variables matrix and nothing more.
#   edgelist  two columns of node names, optionally a third of values, one row
#             per tie.
#   nodelist  one row per ego: ego first, then the alters it names, padded with
#             blanks because rows are of different lengths.
#
# Detection has to work on files nobody wrote for us, so it leans on structural
# facts rather than on conventions: raggedness, whether a column is numeric,
# whether identifiers repeat, and whether the body is square.

# Read a delimited file as raw text: no header assumed, nothing coerced, ragged
# rows filled. Everything downstream decides for itself what it is looking at.
read_delim_raw <- function(file, sep = ",") {
  raw <- utils::read.table(file, sep = sep, header = FALSE, colClasses = "character",
                           fill = TRUE, quote = "\"'", comment.char = "",
                           check.names = FALSE, blank.lines.skip = TRUE,
                           na.strings = character(0), stringsAsFactors = FALSE)
  as_raw_grid(raw)
}

as_raw_grid <- function(df) {
  m <- as.matrix(df)
  m[is.na(m)] <- ""
  dimnames(m) <- NULL
  # A byte order mark rides in on the first cell of a Windows-written csv and
  # would otherwise become part of the first label.
  if (length(m)) m[1, 1] <- sub("^\ufeff", "", m[1, 1])
  trimws(m)
}

is_numericish <- function(x) {
  x <- x[nzchar(x)]
  if (!length(x)) return(TRUE)
  !anyNA(suppressWarnings(as.numeric(x)))
}

# A header row is one that names columns rather than holding data. The reliable
# sign is a column whose top cell is text and whose body is numbers; failing
# that, a stub cell, which is what people put above a column of labels. Testing
# whole rows rather than columns is not enough: an attribute table with one
# categorical column has text below the header too.
header_stubs <- c("", "id", "name", "node", "nodes", "label", "labels", "x", "v1")

detect_header <- function(g) {
  if (nrow(g) < 2L || ncol(g) < 2L) return(FALSE)
  head <- g[1, ]
  body <- g[-1, , drop = FALSE]
  named_col <- vapply(seq_len(ncol(g)), function(j) {
    # An all-blank column is vacuously "numeric", so it has to be excluded or
    # any text above the padding of a node list would look like a header.
    any(nzchar(body[, j])) && !is_numericish(head[j]) && is_numericish(body[, j])
  }, logical(1))
  if (any(named_col)) return(TRUE)
  if (tolower(head[1]) %in% header_stubs) return(TRUE)
  # An all-text file has no column of numbers to give the header away, so fall
  # back on vocabulary: "actor,film" over rows of actors and films names nothing
  # that appears in the data. Only for a full rectangle: a file with blanks is a
  # node list, whose first row is data however unfamiliar its names look.
  if (!all(nzchar(g))) return(FALSE)
  cells <- head[nzchar(head)]
  length(cells) > 0L && !any(cells %in% unique(as.vector(body)))
}

# Ragged means rows stop early: a node list names as many alters as ego has and
# leaves the rest of the row blank. An empty cell with data after it is not
# raggedness, it is a missing value, and a matrix full of those is still a
# matrix - which is what a country with an unknown GNP looked like before this
# distinction was drawn.
is_ragged <- function(body) {
  if (!nrow(body) || ncol(body) < 3L) return(FALSE)
  filled <- apply(body, 1, function(r) sum(nzchar(r)))
  last <- apply(body, 1, function(r) {
    nz <- which(nzchar(r))
    if (!length(nz)) 0L else max(nz)
  })
  no_interior_gaps <- all(filled == last)
  no_interior_gaps && any(last < ncol(body)) && stats::sd(last) > 0
}

#' @rdname xread
#' @param g A character matrix of the file's cells, as read by `read_delim_raw()`.
#' @param has_header Whether the first row of `g` is a header.
#' @keywords internal
#' @noRd
detect_layout_grid <- function(g, has_header = detect_header(g)) {
  body <- if (has_header) g[-1, , drop = FALSE] else g
  nc <- ncol(g)
  if (!nrow(body)) return("matrix")

  # A node list is the only one of the three that is ragged: ego names as many
  # alters as it has, and the rest of the row is blank.
  if (is_ragged(body)) return("nodelist")

  rest <- seq_len(nc)[-1]
  first_numeric <- is_numericish(body[, 1])
  rest_numeric <- nc > 1L && is_numericish(body[, rest, drop = FALSE])
  any_rest_numeric <- nc > 1L &&
    any(vapply(rest, function(j) is_numericish(body[, j]), logical(1)))

  # An edge list names the same nodes over and over across its first two
  # columns; an attribute table never does, because its row labels are unique
  # and share no vocabulary with its variables. That is what separates
  # FROM,TO,PADGM,PADGB - an edge list carrying two relations - from a
  # nodes-by-variables table of the same shape.
  if (nc >= 2L) {
    a <- body[, 1][nzchar(body[, 1])]
    b <- body[, 2][nzchar(body[, 2])]
    looks_like_ties <- anyDuplicated(a) > 0L || length(intersect(a, b)) > 0L
    tail_ok <- nc <= 3L || is_numericish(body[, -(1:2), drop = FALSE])
    square_matrix <- rest_numeric && nrow(body) == nc - 1L
    if (looks_like_ties && tail_ok && !square_matrix) return("edgelist")
  }

  # Labels down the side and numbers in the body: a matrix, whether it is a
  # network or an attribute table. Checked before the edge-list rule so that a
  # three-column attribute table is not mistaken for one.
  if (nc > 1L && rest_numeric && !first_numeric) return("matrix")
  # An attribute table is still a matrix when one of its variables is
  # categorical, so long as the rest are numbers and it has a header naming
  # them. A node list has no such header and no numeric columns.
  if (nc > 2L && has_header && !first_numeric && any_rest_numeric) return("matrix")
  # The same shape but with numeric row labels, which only a square body can
  # tell apart from an edge list.
  if (nc > 1L && rest_numeric && nrow(body) == nc - 1L) return("matrix")
  # No label column at all.
  if (is_numericish(body) && nrow(body) == nc) return("matrix")

  # Two or three columns where the identifiers repeat: one row per tie.
  if (nc %in% 2:3) {
    repeats <- any(duplicated(body[, 1])) || (nc > 1L && any(duplicated(body[, 2])))
    if (repeats || nrow(body) > nc) return("edgelist")
  }
  # Names rather than numbers to the right of the first column: alters.
  if (nc > 1L && !rest_numeric) return("nodelist")
  "matrix"
}

# ---- turning a grid into a network ------------------------------------------

grid_to_matrix <- function(g, has_header) {
  body <- if (has_header) g[-1, , drop = FALSE] else g
  labelled <- !is_numericish(body[, 1]) ||
    (ncol(g) > 1L && nrow(body) == ncol(g) - 1L)
  if (labelled) {
    rlab <- body[, 1]
    body <- body[, -1, drop = FALSE]
    clab <- if (has_header) g[1, -1] else NULL
  } else {
    rlab <- if (has_header) NULL else NULL
    clab <- if (has_header) g[1, ] else NULL
  }
  # A categorical column in an attribute table gets coded to numbers, which is
  # how UCINET stores one: Wolfe's primates arrive with GENDER as male/female in
  # csv and as 1/2 in the ##h file. Announced rather than done quietly, as D10
  # asks of any auto-transformation.
  m <- matrix(NA_real_, nrow(body), ncol(body))
  for (j in seq_len(ncol(body))) {
    col <- body[, j]
    if (is_numericish(col)) {
      col[!nzchar(col)] <- NA
      m[, j] <- suppressWarnings(as.numeric(col))
    } else {
      lv <- sort(unique(col[nzchar(col)]))
      m[, j] <- match(col, lv)
      nm <- if (!is.null(clab) && length(clab) == ncol(body)) clab[j] else j
      message("Column ", nm, " is categorical; coded ",
              paste(sprintf("%s=%d", lv, seq_along(lv)), collapse = ", "), ".")
    }
  }
  if (!is.null(rlab) && length(rlab) == nrow(m)) rownames(m) <- rlab
  if (!is.null(clab) && length(clab) == ncol(m)) colnames(m) <- clab
  m
}

# Every column is kept as text; xfromedgelist() decides which are values and
# which are relation names, because that depends on what is in them.
grid_to_edgelist <- function(g, has_header) {
  body <- if (has_header) g[-1, , drop = FALSE] else g
  df <- data.frame(from = body[, 1], to = body[, 2], stringsAsFactors = FALSE)
  for (j in seq_len(ncol(body))[-(1:2)]) {
    nm <- if (has_header && nzchar(g[1, j])) g[1, j] else paste0("value", j - 2L)
    df[[nm]] <- body[, j]
  }
  df
}

grid_to_nodelist <- function(g, has_header) {
  body <- if (has_header) g[-1, , drop = FALSE] else g
  as.data.frame(body, stringsAsFactors = FALSE)
}
