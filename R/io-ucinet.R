# Native reader and writer for UCINET's ##h/##d datasets.
#
# Ported from the Delphi that UCINET itself uses, copied into
# inst/reference/delphi/ with a description of the layout in its README. Every
# offset below comes from tucdataset.loadhdr* (utucdataset.pas), ufile.seekrow
# (uufile.pas) and tsmat.loadmat (utsmat.pas); nothing here is inferred from
# looking at bytes.

# The datatype enum from ucommon.pas, in ordinal order, with dtsize alongside.
uci_dtnames <- c("nodt", "byte", "boolean", "shortint", "word", "smallint",
                 "longint", "single", "real48", "double", "comp", "extended",
                 "label", "set", "string", "pointer", "char", "integer",
                 "nodelist", "sparse", "int64")
uci_dtsize <- c(0, 1, 1, 1, 2, 2, 4, 4, 6, 8, 8, 10, 256, 32, 256, 4, 1, 4, 4, 8, 8)

# ucommon.pas: na = 1E37 is the missing-value threshold, bna = 1E38 the value
# written for a missing cell. tsmat.isna is `cell[i,j] >= na` on a single.
uci_na  <- 1e37
uci_bna <- 1e38

# How each datatype maps onto readBin(). Anything not listed is a type UCINET
# can name but that does not appear in any dataset we have seen; rather than
# guess at Delphi's 6-byte Real48 or 10-byte Extended we refuse them by name.
uci_readable <- list(
  byte     = list(what = "integer", size = 1, signed = FALSE),
  boolean  = list(what = "integer", size = 1, signed = FALSE),
  shortint = list(what = "integer", size = 1, signed = TRUE),
  word     = list(what = "integer", size = 2, signed = FALSE),
  smallint = list(what = "integer", size = 2, signed = TRUE),
  longint  = list(what = "integer", size = 4, signed = TRUE),
  integer  = list(what = "integer", size = 4, signed = TRUE),
  single   = list(what = "double",  size = 4, signed = TRUE),
  double   = list(what = "double",  size = 8, signed = TRUE)
)

#' Read a UCINET dataset
#'
#' Reads UCINET's native `.##h` / `.##d` pair, in pure R, for every header
#' version UCINET has written: 4010, 4020, 5000, 6000, 6404 and 6405. Labels,
#' the dataset title, multi-relation stacks, 2-mode shapes and missing values
#' all come across.
#'
#' UCINET stores a missing cell as 1e38 and treats anything at or above 1e37 as
#' missing; those become `NA`. Values are stored to the precision of the file's
#' own datatype, which for almost every UCINET dataset is a 4-byte single.
#'
#' @param file Path to the `.##h` file, the `.##d` file, or the name with no
#'   extension.
#' @param directed,mode,title Passed to [as_xucinet()]. `title` defaults to the
#'   title stored in the file, or the file name when the file has none.
#' @param ... Reserved.
#' @return An `xucinet` object; multi-relation datasets get one named matrix per
#'   relation, named from the file's matrix labels.
#' @seealso [xsaveucinet()] to write one, and [xread()] which dispatches here.
#' @examples
#' f <- system.file("goldens", "ucinet", "campnet.##h", package = "xucinet")
#' xreaducinet(f)
#' @export
xreaducinet <- function(file, directed = NULL, mode = NULL, title = NULL, ...) {
  paths <- ucinet_paths(file)
  h <- ucinet_header(paths$header)
  data <- ucinet_data(paths$data, h)
  labels <- ucinet_dimnames(h)
  mats <- lapply(seq_len(h$nm), function(k) {
    m <- data[[k]]
    dimnames(m) <- list(labels$row, labels$col)
    m
  })
  if (is.null(title)) {
    # Not file_path_sans_ext(): "##h" is not alphanumeric, so it leaves it on.
    title <- if (nzchar(h$title)) h$title else basename(paths$stem)
  }
  if (h$nm == 1L) {
    return(as_xucinet(mats[[1L]], directed = directed, mode = mode, title = title))
  }
  names(mats) <- labels$relation
  as_xucinet(mats, directed = directed, mode = mode, title = title)
}

#' Write a UCINET dataset
#'
#' Writes the `.##h` / `.##d` pair that UCINET reads. The default header version
#' is 6404, the version every dataset shipped with the book uses; 6405 adds one
#' trailing byte and is what current UCINET writes by default.
#'
#' `NA` is written as 1e38, which is the value UCINET reads back as missing.
#'
#' @param net A network (any accepted form).
#' @param file Output path, with or without the `.##h` extension.
#' @param version Header version to write: 4010, 4020, 5000, 6000, 6404 or 6405.
#' @param datatype Element type for the `.##d` file. `"single"` is what UCINET
#'   itself defaults to; `"double"` keeps full R precision but older UCINET
#'   routines may not expect it.
#' @param title Dataset title stored in the header. Defaults to the network's.
#' @param istable Value of the trailing `istable` byte, version 6405 only.
#' @return The path of the `.##h` file written, invisibly.
#' @examples
#' m <- matrix(c(0,1,1, 1,0,0, 1,0,0), 3, 3)
#' f <- file.path(tempdir(), "demo")
#' xsaveucinet(m, f)
#' xreaducinet(f)
#' @export
xsaveucinet <- function(net, file, version = 6404, datatype = "single",
                        title = NULL, istable = FALSE) {
  net <- as_xucinet(net)
  version <- as.integer(version)
  if (!version %in% c(4010L, 4020L, 5000L, 6000L, 6404L, 6405L)) {
    stop("version must be one of 4010, 4020, 5000, 6000, 6404, 6405; got ",
         version, ".", call. = FALSE)
  }
  datatype <- match.arg(tolower(datatype), names(uci_readable))
  if (is.null(title)) title <- net$title
  paths <- ucinet_paths(file, must_exist = FALSE)
  mats <- if (is.list(net$data)) net$data else list(net$data)
  proto <- mats[[1L]]
  ucinet_write_header(paths$header, version, datatype, title,
                      nr = nrow(proto), nc = ncol(proto), nm = length(mats),
                      collab = colnames(proto), rowlab = rownames(proto),
                      matlab = names(mats), istable = istable)
  ucinet_write_data(paths$data, mats, datatype)
  invisible(paths$header)
}

# ---- paths ------------------------------------------------------------------

# UCINET names a dataset by its stem; either extension, or none, may be given.
ucinet_paths <- function(file, must_exist = TRUE) {
  stem <- sub("\\.##[hHdD]$", "", file)
  header <- paste0(stem, ".##h")
  data <- paste0(stem, ".##d")
  if (must_exist) {
    # Files written on other machines may be upper case.
    if (!file.exists(header) && file.exists(paste0(stem, ".##H"))) {
      header <- paste0(stem, ".##H")
    }
    if (!file.exists(data) && file.exists(paste0(stem, ".##D"))) {
      data <- paste0(stem, ".##D")
    }
    if (!file.exists(header)) {
      stop("No UCINET header file at '", header, "'.", call. = FALSE)
    }
    if (!file.exists(data)) {
      stop("Found the header '", basename(header), "' but no matching .##d ",
           "data file beside it.\n  A UCINET dataset is always a pair.",
           call. = FALSE)
    }
  }
  list(header = header, data = data, stem = stem)
}

# ---- header -----------------------------------------------------------------

# getfileversion in utucdataset.pas: the first six bytes are a ShortString, so
# byte 1 is a length and bytes 2-6 are characters. "V6404"/"V6405" name
# themselves; "DATE:" means the version is in the date record's labtype field;
# anything else is a pre-DATE: file, which is version 4010.
ucinet_version <- function(con) {
  seek(con, 0)
  s <- readBin(con, "raw", 6)
  if (length(s) < 6) stop("Not a UCINET header: fewer than 6 bytes.", call. = FALSE)
  # Compared as raw, not via rawToChar(): a 4010 header starts straight into the
  # datatype and dimension bytes, which contain embedded nuls.
  if (s[2] %in% as.raw(c(0x56, 0x76))) {         # "V" or "v"
    v <- suppressWarnings(as.integer(rawToChar(s[3:6])))
    if (is.na(v)) {
      stop("Unrecognised UCINET header version '", rawToChar(s[2:6]), "'.\n",
           "  Was this file written by a later version of UCINET?", call. = FALSE)
    }
    return(v)
  }
  if (as.integer(s[1]) == 5L && identical(s[2:6], charToRaw("DATE:"))) {
    d <- readBin(con, "integer", 5, size = 2, signed = FALSE)
    labtype <- d[5]
    if (labtype %in% 1:3) return(c(4020L, 5000L, 6000L)[labtype])
    # labtype 0 means fixed 10-character labels, i.e. version 4010 - but a 4010
    # file has no DATE: block at all (savehdr only writes one when version >
    # 4010), so a file that has both is not something any UCINET writer
    # produces. Refusing beats silently misreading it.
    stop("This header starts with 'DATE:' but records labtype ", labtype,
         ", which no UCINET writer produces.\n",
         "  The file looks damaged; UCINET would misread it too.", call. = FALSE)
  }
  4010L
}

# The per-version differences, all of them. Everything after this is shared.
ucinet_layout <- function(version) {
  switch(as.character(version),
    "4010" = list(start =  0L, dimsize = 2L, labels = "fixed10",  istable = FALSE),
    "4020" = list(start = 16L, dimsize = 2L, labels = "fixed20",  istable = FALSE),
    "5000" = list(start = 16L, dimsize = 2L, labels = "ascii",    istable = FALSE),
    "6000" = list(start = 16L, dimsize = 2L, labels = "unicode",  istable = FALSE),
    "6404" = list(start = 16L, dimsize = 4L, labels = "unicode",  istable = FALSE),
    "6405" = list(start = 16L, dimsize = 4L, labels = "unicode",  istable = TRUE),
    stop("Unsupported UCINET header version ", version, ".", call. = FALSE))
}

ucinet_header <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con))
  version <- ucinet_version(con)
  lay <- ucinet_layout(version)
  # start = 6 magic bytes + 10 date-record bytes, or 0 for a pre-DATE: file.
  seek(con, lay$start)
  dt <- as.integer(readBin(con, "raw", 1))
  if (dt < 0 || dt >= length(uci_dtnames)) {
    stop("Header names datatype ", dt, ", which is outside the UCINET range.",
         call. = FALSE)
  }
  dtname <- uci_dtnames[dt + 1L]
  ndim <- readBin(con, "integer", 1, size = 2)
  if (is.na(ndim) || ndim < 1L || ndim > 8L) {
    stop("Header says the matrix has ", ndim, " dimensions; expected 2 or 3.",
         call. = FALSE)
  }
  dims <- readBin(con, "integer", ndim, size = lay$dimsize)
  # readdimensions(): dims[1] is columns and dims[2] rows, in that order.
  nc <- dims[1]
  nr <- if (ndim >= 2L) dims[2] else 1L
  nm <- if (ndim >= 3L) dims[3] else 1L
  if (is.na(nm) || nm < 1L) nm <- 1L
  title <- ucinet_read_title(con)
  haslab <- as.integer(readBin(con, "raw", ndim)) != 0L
  rd <- function(n) ucinet_read_labels(con, n, lay$labels)
  collab <- if (haslab[1]) rd(nc) else NULL
  rowlab <- if (ndim >= 2L && haslab[2]) rd(nr) else NULL
  matlab <- if (ndim >= 3L && haslab[3]) rd(nm) else NULL
  # Dimensions beyond the third are read past so nothing downstream misaligns.
  for (i in seq_len(max(0L, ndim - 3L)) + 3L) if (haslab[i]) rd(dims[i])
  istable <- if (lay$istable) as.integer(readBin(con, "raw", 1)) != 0L else NA
  list(version = version, dt = dt, dtname = dtname, ndim = ndim,
       nr = nr, nc = nc, nm = nm, title = title, haslab = haslab,
       collab = collab, rowlab = rowlab, matlab = matlab, istable = istable)
}

# readtitle(): one length byte, then that many characters.
ucinet_read_title <- function(con) {
  n <- as.integer(readBin(con, "raw", 1))
  if (is.na(n) || n == 0L) return("")
  ucinet_ansi(readBin(con, "raw", n))
}

ucinet_read_labels <- function(con, n, kind) {
  if (n <= 0L) return(character(0))
  switch(kind,
    fixed10 = ucinet_read_fixed(con, n, 10L),
    fixed20 = ucinet_read_fixed(con, n, 20L),
    ascii   = ucinet_read_variable(con, n, unicode = FALSE),
    unicode = ucinet_read_variable(con, n, unicode = TRUE))
}

# readfixedlabels(): reads `size` bytes per label starting at the ShortString's
# length byte, so a "10-character" label is one length byte and 9 characters.
ucinet_read_fixed <- function(con, n, size) {
  vapply(seq_len(n), function(i) {
    b <- readBin(con, "raw", size)
    len <- min(as.integer(b[1]), size - 1L)
    if (len <= 0L) "" else ucinet_ansi(b[seq_len(len) + 1L])
  }, character(1))
}

# readvariablelabels() / readunicodelabels(): a 2-byte count of BYTES, then that
# many bytes. For the unicode versions those bytes are UTF-16LE, so the label is
# half as many characters long.
ucinet_read_variable <- function(con, n, unicode) {
  vapply(seq_len(n), function(i) {
    nbytes <- readBin(con, "integer", 1, size = 2)
    if (is.na(nbytes) || nbytes <= 0L) return("")
    b <- readBin(con, "raw", nbytes)
    if (unicode) ucinet_utf16(b) else ucinet_ansi(b)
  }, character(1))
}

ucinet_ansi <- function(b) {
  b <- b[b != as.raw(0)]
  if (!length(b)) return("")
  s <- rawToChar(b)
  out <- iconv(s, "latin1", "UTF-8")
  if (is.na(out)) s else out
}

ucinet_utf16 <- function(b) {
  out <- iconv(list(b), from = "UTF-16LE", to = "UTF-8")
  if (is.na(out)) "" else out
}

# Labels the file did not carry are left NULL so that as_xucinet() supplies
# UCINET's own 1..n defaults.
ucinet_dimnames <- function(h) {
  list(row = h$rowlab, col = h$collab,
       relation = if (is.null(h$matlab)) paste0("relation", seq_len(h$nm)) else h$matlab)
}

# ---- data -------------------------------------------------------------------

# The .##d file has no header: it is nm matrices back to back, each written row
# by row. ufile.seekrow puts element (i,j) of matrix k at
# dtsize*((k-1)*nr*nc + (i-1)*nc + (j-1)), so the whole file is exactly
# nr*nc*nm*dtsize bytes, which is worth checking before trusting any of it.
ucinet_data <- function(path, h) {
  spec <- uci_readable[[h$dtname]]
  if (is.null(spec)) {
    stop("This dataset stores its values as '", h$dtname, "', which xucinet ",
         "cannot read yet.\n",
         "  Supported: ", paste(names(uci_readable), collapse = ", "), ".\n",
         "  Please send the file to the maintainers so the type can be added.",
         call. = FALSE)
  }
  n <- as.numeric(h$nr) * h$nc * h$nm
  expected <- n * spec$size
  actual <- file.info(path)$size
  if (!isTRUE(all.equal(actual, expected))) {
    stop("'", basename(path), "' is ", actual, " bytes but the header ",
         "describes ", h$nr, " x ", h$nc,
         if (h$nm > 1) paste0(" x ", h$nm) else "",
         " ", h$dtname, " values, which needs ", format(expected, scientific = FALSE),
         ".\n  The header and data file do not belong together.", call. = FALSE)
  }
  con <- file(path, "rb")
  on.exit(close(con))
  x <- readBin(con, spec$what, n = n, size = spec$size, signed = spec$signed,
               endian = "little")
  storage.mode(x) <- "double"
  # tsmat.isna: at or above 1e37 is missing. UCINET writes 1e38 for one.
  x[x >= uci_na] <- NA_real_
  lapply(seq_len(h$nm), function(k) {
    off <- (k - 1) * h$nr * h$nc
    matrix(x[off + seq_len(h$nr * h$nc)], nrow = h$nr, ncol = h$nc, byrow = TRUE)
  })
}

# ---- writing ----------------------------------------------------------------

ucinet_write_header <- function(path, version, datatype, title, nr, nc, nm,
                                collab, rowlab, matlab, istable) {
  lay <- ucinet_layout(version)
  con <- file(path, "wb")
  on.exit(close(con))
  if (version > 4010L) {
    magic <- if (version >= 6404L) paste0("V", version) else "DATE:"
    # saveopening(): a ShortString written as 6 bytes, length byte first.
    writeBin(as.raw(c(5L, utf8ToInt(magic))), con)
    # setdrec(): year, month, day, dow, labtype as five Words. The year is the
    # two-digit year, exactly as UCINET stores it.
    now <- as.POSIXlt(Sys.time())
    labtype <- switch(as.character(version),
                      "4020" = 1L, "5000" = 2L, 3L)
    writeBin(as.integer(c(now$year %% 100L, now$mon + 1L, now$mday,
                          now$wday + 1L, labtype)), con, size = 2)
  }
  writeBin(as.integer(match(datatype, uci_dtnames) - 1L), con, size = 1)
  # writesmalldimensions()/writeintegerdimensions(): always 3 dimensions here,
  # because we always have matrix labels to write.
  writeBin(3L, con, size = 2)
  writeBin(as.integer(c(nc, nr, nm)), con, size = lay$dimsize)
  ucinet_write_title(con, title)
  writeBin(as.raw(c(1L, 1L, 1L)), con)
  wr <- function(x, n) ucinet_write_labels(con, ucinet_fill_labels(x, n), lay$labels)
  wr(collab, nc)
  wr(rowlab, nr)
  wr(matlab, nm)
  if (lay$istable) writeBin(as.raw(as.integer(isTRUE(istable))), con)
  invisible(path)
}

ucinet_fill_labels <- function(x, n) {
  if (is.null(x) || !length(x)) as.character(seq_len(n)) else as.character(x)
}

ucinet_write_title <- function(con, title) {
  if (is.null(title)) title <- ""
  b <- charToRaw(enc2utf8(substr(title, 1, 255)))
  writeBin(as.raw(length(b)), con)
  if (length(b)) writeBin(b, con)
}

ucinet_write_labels <- function(con, labs, kind) {
  switch(kind,
    fixed10 = ucinet_write_fixed(con, labs, 10L),
    fixed20 = ucinet_write_fixed(con, labs, 20L),
    ascii   = ucinet_write_variable(con, labs, unicode = FALSE),
    unicode = ucinet_write_variable(con, labs, unicode = TRUE))
}

ucinet_write_fixed <- function(con, labs, size) {
  for (s in labs) {
    b <- charToRaw(substr(s, 1, size - 1L))
    out <- raw(size)
    out[1] <- as.raw(length(b))
    if (length(b)) out[seq_along(b) + 1L] <- b
    writeBin(out, con)
  }
}

ucinet_write_variable <- function(con, labs, unicode) {
  for (s in labs) {
    b <- if (unicode) ucinet_to_utf16(s) else charToRaw(s)
    writeBin(as.integer(length(b)), con, size = 2)
    if (length(b)) writeBin(b, con)
  }
}

ucinet_to_utf16 <- function(s) {
  if (!nzchar(s)) return(raw(0))
  out <- iconv(enc2utf8(s), "UTF-8", "UTF-16LE", toRaw = TRUE)[[1]]
  if (is.null(out)) charToRaw(s) else out
}

ucinet_write_data <- function(path, mats, datatype) {
  spec <- uci_readable[[datatype]]
  con <- file(path, "wb")
  on.exit(close(con))
  for (m in mats) {
    x <- as.numeric(t(m))               # t() gives UCINET's row-major order
    x[is.na(x)] <- uci_bna              # UCINET reads 1e38 back as missing
    if (spec$what == "integer") {
      writeBin(as.integer(x), con, size = spec$size, endian = "little")
    } else {
      writeBin(x, con, size = spec$size, endian = "little")
    }
  }
  invisible(path)
}
