# DL, UCINET's text format. A parameter block, optional label blocks, then the
# data:
#
#   DL N=5, FORMAT=FULLMATRIX
#   LABELS:
#   a,b,c,d,e
#   DATA:
#   0 1 0 0 0
#   ...
#
# The keyword vocabulary, including which abbreviations are accepted, is taken
# from the dlkey table in Tools/G1Tools/udlreader.pas rather than from memory:
# UCINET matches on a prefix, so NR, NROW and NI all mean the same thing, as do
# NL, NM, NMAT, NREL and NRESP.

dl_keys <- list(
  nr     = c("nr", "nrow", "ni"),
  nc     = c("nc", "ncol"),
  nm     = c("nl", "nm", "nmat", "nrel", "nresp"),
  n      = "n",
  format = "format",
  diag   = "diagonal",
  labels = "labels"
)

# Formats we read. UCINET names more, but these are the ones that appear in
# files; anything else is refused by name rather than guessed at.
dl_formats <- c("fullmatrix", "edgelist1", "edgelist2", "nodelist1", "nodelist2",
                "lowerhalf", "upperhalf")

dl_split <- function(x) {
  out <- trimws(unlist(strsplit(x, "[,[:space:]]+")))
  out[nzchar(out)]
}

# The value of KEY=VALUE anywhere in the parameter block, matched by prefix as
# UCINET does.
dl_param <- function(txt, aliases) {
  for (a in aliases) {
    m <- regmatches(txt, regexpr(paste0("\\b", a, "\\s*=\\s*[^,[:space:]]+"), txt,
                                 ignore.case = TRUE))
    if (length(m) && nzchar(m[1])) return(trimws(sub("^[^=]*=\\s*", "", m[1])))
  }
  NA_character_
}

#' Read a DL file
#'
#' Reads UCINET's DL text format. The formats understood are `fullmatrix`,
#' `edgelist1`, `edgelist2`, `nodelist1`, `nodelist2`, `lowerhalf` and
#' `upperhalf`, with `n`/`nr`/`nc` for shape, `nm` (also `nl`, `nmat`, `nrel`,
#' `nresp`) for a stack of matrices, `diagonal absent`, and `labels`,
#' `row labels`, `column labels` and `matrix labels` blocks. Keywords are
#' matched on a prefix and are not case sensitive, as UCINET matches them.
#'
#' @param file Path to the `.dl` file.
#' @param directed,mode,title Passed to [as_xucinet()].
#' @param ... Reserved.
#' @return An `xucinet` object.
#' @seealso [xsavedl()]
#' @examples
#' f <- file.path(tempdir(), "demo.dl")
#' xsavedl(matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3), f)
#' xreaddl(f)
#' @export
xreaddl <- function(file, directed = NULL, mode = NULL, title = NULL, ...) {
  if (!file.exists(file)) stop("No DL file at '", file, "'.", call. = FALSE)
  lines <- readLines(file, warn = FALSE)
  lines <- lines[nzchar(trimws(lines))]
  if (!length(lines) || !grepl("^\\s*dl\\b", lines[1], ignore.case = TRUE)) {
    stop("'", basename(file), "' does not start with DL, so it is not a DL file.",
         call. = FALSE)
  }

  # Where each block begins. Everything before the first one is parameters.
  marks <- list(
    data = grep("^\\s*(data|begin|start)\\s*:", lines, ignore.case = TRUE),
    rowlab = grep("^\\s*row\\s+lab", lines, ignore.case = TRUE),
    collab = grep("^\\s*col(umn)?\\s+lab", lines, ignore.case = TRUE),
    matlab = grep("^\\s*(matrix|level|mat|lev)\\s+lab", lines, ignore.case = TRUE),
    lab = grep("^\\s*lab(els)?\\s*:", lines, ignore.case = TRUE)
  )
  if (!length(marks$data)) {
    stop("'", basename(file), "' has no DATA: line, so there is nothing to read.",
         call. = FALSE)
  }
  first_block <- min(unlist(marks))
  params <- paste(lines[seq_len(first_block - 1L)], collapse = " ")

  fmt <- dl_param(params, dl_keys$format)
  fmt <- if (is.na(fmt)) "fullmatrix" else tolower(fmt)
  hit <- dl_formats[startsWith(dl_formats, fmt)]
  if (!length(hit)) {
    stop("'", basename(file), "' asks for FORMAT=", fmt, ", which xucinet does ",
         "not read.\n  Understood: ", paste(dl_formats, collapse = ", "), ".",
         call. = FALSE)
  }
  fmt <- hit[1]

  num <- function(k) {
    v <- suppressWarnings(as.integer(dl_param(params, dl_keys[[k]])))
    if (length(v) && !is.na(v)) v else NA_integer_
  }
  n <- num("n"); nr <- num("nr"); nc <- num("nc"); nm <- num("nm")
  if (is.na(nr)) nr <- n
  if (is.na(nc)) nc <- n
  if (is.na(nm) || nm < 1L) nm <- 1L
  diag_absent <- grepl("diag\\w*\\s*[:=]?\\s*absent", params, ignore.case = TRUE)

  block <- function(where, upto) {
    if (!length(where)) return(character(0))
    start <- where[1] + 1L
    ends <- unlist(marks); ends <- ends[ends > where[1]]
    stop_at <- if (length(ends)) min(ends) - 1L else length(lines)
    if (start > stop_at) character(0) else dl_split(lines[start:stop_at])
  }
  rowlab <- block(marks$rowlab)
  collab <- block(marks$collab)
  matlab <- block(marks$matlab)
  both <- block(marks$lab)
  if (length(both) && !length(rowlab)) rowlab <- both
  if (length(both) && !length(collab)) collab <- both

  data_tokens <- dl_split(lines[(marks$data[1] + 1L):length(lines)])
  if (is.na(nr) && length(rowlab)) nr <- length(rowlab)
  if (is.na(nc) && length(collab)) nc <- length(collab)

  mats <- switch(fmt,
    fullmatrix = dl_fullmatrix(data_tokens, nr, nc, nm, diag_absent, file),
    lowerhalf  = dl_halfmatrix(data_tokens, nr, nm, diag_absent, "lower", file),
    upperhalf  = dl_halfmatrix(data_tokens, nr, nm, diag_absent, "upper", file),
    edgelist1  = dl_edgelist(lines, marks$data[1], nr, nc, nm, rowlab, collab, FALSE),
    edgelist2  = dl_edgelist(lines, marks$data[1], nr, nc, nm, rowlab, collab, TRUE),
    nodelist1  = dl_nodelist(lines, marks$data[1], nr, nc, rowlab, collab, FALSE),
    nodelist2  = dl_nodelist(lines, marks$data[1], nr, nc, rowlab, collab, TRUE)
  )

  mats <- lapply(mats, function(m) {
    if (length(rowlab) == nrow(m)) rownames(m) <- rowlab
    if (length(collab) == ncol(m)) colnames(m) <- collab
    m
  })
  names(mats) <- if (length(matlab) == length(mats)) matlab else
    if (length(mats) == 1L) NULL else paste0("relation", seq_along(mats))

  if (is.null(title)) title <- sub("\\.dl$", "", basename(file), ignore.case = TRUE)
  if (is.null(mode) && fmt %in% c("edgelist2", "nodelist2")) mode <- "2-mode"
  as_xucinet(if (length(mats) == 1L) mats[[1L]] else mats,
             directed = directed, mode = mode, title = title)
}

dl_numbers <- function(tokens, file) {
  v <- suppressWarnings(as.numeric(tokens))
  if (anyNA(v)) {
    bad <- utils::head(unique(tokens[is.na(v)]), 3)
    stop("'", basename(file), "' has non-numeric values in its DATA block: ",
         paste(bad, collapse = ", "),
         ".\n  If the labels are embedded, say LABELS EMBEDDED in the header.",
         call. = FALSE)
  }
  v
}

dl_fullmatrix <- function(tokens, nr, nc, nm, diag_absent, file) {
  v <- dl_numbers(tokens, file)
  if (is.na(nr)) stop("'", basename(file), "' gives no N or NR, so the shape of ",
                      "the matrix is unknown.", call. = FALSE)
  if (is.na(nc)) nc <- nr
  per <- if (diag_absent) nr * (nc - 1L) else nr * nc
  if (length(v) < per * nm) {
    stop("'", basename(file), "' declares ", nr, " x ", nc,
         if (nm > 1) paste0(" x ", nm) else "", " but its DATA block holds ",
         length(v), " values, not ", per * nm, ".", call. = FALSE)
  }
  lapply(seq_len(nm), function(k) {
    chunk <- v[((k - 1L) * per + 1L):(k * per)]
    if (!diag_absent) return(matrix(chunk, nr, nc, byrow = TRUE))
    # DIAGONAL ABSENT: each row omits its own cell, which is read back as zero.
    m <- matrix(0, nr, nc)
    pos <- 1L
    for (i in seq_len(nr)) {
      js <- setdiff(seq_len(nc), i)
      m[i, js] <- chunk[pos:(pos + length(js) - 1L)]
      pos <- pos + length(js)
    }
    m
  })
}

dl_halfmatrix <- function(tokens, n, nm, diag_absent, half, file) {
  v <- dl_numbers(tokens, file)
  if (is.na(n)) stop("'", basename(file), "' gives no N, so the shape is unknown.",
                     call. = FALSE)
  per <- if (diag_absent) n * (n - 1L) / 2L else n * (n + 1L) / 2L
  lapply(seq_len(nm), function(k) {
    chunk <- v[((k - 1L) * per + 1L):(k * per)]
    m <- matrix(0, n, n)
    pos <- 1L
    for (i in seq_len(n)) {
      js <- if (half == "lower") seq_len(i) else i:n
      if (diag_absent) js <- setdiff(js, i)
      if (length(js)) {
        m[i, js] <- chunk[pos:(pos + length(js) - 1L)]
        pos <- pos + length(js)
      }
    }
    m + t(m) * (row(m) != col(m))
  })
}

# Rows of "i j value", by number or by label. edgelist2 means the two columns
# index different node sets, which is what makes the result 2-mode.
dl_edgelist <- function(lines, data_at, nr, nc, nm, rowlab, collab, twomode) {
  rows <- lapply(lines[(data_at + 1L):length(lines)], dl_split)
  rows <- rows[lengths(rows) >= 2L]
  from <- vapply(rows, `[`, character(1), 1)
  to <- vapply(rows, `[`, character(1), 2)
  val <- vapply(rows, function(r) if (length(r) >= 3L) r[3] else "1", character(1))
  rn <- dl_axis(from, rowlab, nr)
  cn <- dl_axis(to, if (twomode) collab else rowlab, if (twomode) nc else nr)
  m <- matrix(0, length(rn$labels), length(cn$labels),
              dimnames = list(rn$labels, cn$labels))
  m[cbind(rn$idx, cn$idx)] <- suppressWarnings(as.numeric(val))
  list(m)
}

# Rows of "ego alter alter ...".
dl_nodelist <- function(lines, data_at, nr, nc, rowlab, collab, twomode) {
  rows <- lapply(lines[(data_at + 1L):length(lines)], dl_split)
  rows <- rows[lengths(rows) >= 1L]
  egos <- vapply(rows, `[`, character(1), 1)
  alters <- unlist(lapply(rows, function(r) r[-1]))
  reps <- vapply(rows, function(r) length(r) - 1L, integer(1))
  rn <- dl_axis(egos, rowlab, nr)
  cn <- dl_axis(alters, if (twomode) collab else rowlab, if (twomode) nc else nr)
  m <- matrix(0, length(rn$labels), length(cn$labels),
              dimnames = list(rn$labels, cn$labels))
  if (length(alters)) m[cbind(rep(rn$idx, reps), cn$idx)] <- 1
  list(m)
}

# Turn the identifiers in a data block into positions, whether they are numbers
# into a declared node set or labels in their own right.
dl_axis <- function(x, labels, n) {
  numeric_ids <- !anyNA(suppressWarnings(as.numeric(x)))
  if (numeric_ids) {
    idx <- as.integer(as.numeric(x))
    size <- if (!is.na(n)) n else max(idx)
    lab <- if (length(labels) == size) labels else as.character(seq_len(size))
    return(list(idx = idx, labels = lab))
  }
  lab <- if (length(labels)) labels else unique(x)
  list(idx = match(x, lab), labels = lab)
}

#' Write a DL file
#'
#' Writes UCINET's DL text format, as `fullmatrix` with a labels block, or as
#' `edgelist1` when asked. A stack of relations is written as consecutive
#' matrices with a matrix labels block.
#'
#' @param net A network (any accepted form).
#' @param file Output path. `.dl` is appended if it has no extension.
#' @param format `"fullmatrix"` (default) or `"edgelist1"`.
#' @return The path written, invisibly.
#' @seealso [xreaddl()]
#' @export
xsavedl <- function(net, file, format = c("fullmatrix", "edgelist1")) {
  net <- as_xucinet(net)
  format <- match.arg(format)
  if (!grepl("\\.[A-Za-z0-9]+$", file)) file <- paste0(file, ".dl")
  mats <- if (is.list(net$data)) net$data else list(net$data)
  names(mats) <- xrelations(net)
  m1 <- mats[[1L]]
  nr <- nrow(m1); nc <- ncol(m1)

  hdr <- if (nr == nc) paste0("DL N=", nr) else paste0("DL NR=", nr, ", NC=", nc)
  if (length(mats) > 1L) hdr <- paste0(hdr, ", NM=", length(mats))
  out <- c(hdr, paste0("FORMAT = ", toupper(format)))

  if (nr == nc && identical(rownames(m1), colnames(m1))) {
    out <- c(out, "LABELS:", paste(rownames(m1), collapse = ","))
  } else {
    out <- c(out, "ROW LABELS:", paste(rownames(m1), collapse = ","),
             "COLUMN LABELS:", paste(colnames(m1), collapse = ","))
  }
  if (length(mats) > 1L) {
    out <- c(out, "MATRIX LABELS:", paste(names(mats), collapse = ","))
  }
  out <- c(out, "DATA:")

  for (m in mats) {
    if (format == "fullmatrix") {
      out <- c(out, apply(m, 1, function(r) paste(format_values(r), collapse = " ")))
    } else {
      idx <- which(m != 0 & !is.na(m), arr.ind = TRUE)
      if (nrow(idx)) {
        idx <- idx[order(idx[, 1], idx[, 2]), , drop = FALSE]
        out <- c(out, paste(idx[, 1], idx[, 2], format_values(m[idx])))
      }
    }
  }
  writeLines(out, file)
  invisible(file)
}
