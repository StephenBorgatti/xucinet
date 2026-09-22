# Turn a node attribute into a matrix.
#
# Ported from uc_AttributeToMatrix.pas (repository StephenBorgatti/ucinet at
# commit c7b4956) with the formulas in G2Tools/uattributetomatrix.pas,
# procedure convertattributetomatrix and the ten it dispatches to (repository
# StephenBorgatti/tools at commit 207958a).
#
# The dialog normalises the attribute first (normalizeattribute): none,
# centre, or standardise. Its standard deviation is tunivariate.stddev, which
# is `sqrt(mcssq/sumwt)` - the population form. The sample form is a separate
# field, estsd, and is not what this uses.
#
# The saved dataset is named by getextension: the method's suffix with the
# attribute's name glued on, so Gender under Exact Matches comes back as
# <input>-sameGender.

# Method -> suffix, and whether the result is asymmetric. difference is
# a_i - a_j; duplicatedrows and duplicatedcols copy the vector across rows or
# down columns, so none of the three is symmetric.
atm_methods <- list(
  same     = list(suffix = "-same",     directed = FALSE),
  diff     = list(suffix = "-diff",     directed = TRUE),
  absdiff  = list(suffix = "-absdiff",  directed = FALSE),
  sqrdiff  = list(suffix = "-sqrdiff",  directed = FALSE),
  product  = list(suffix = "-prod",     directed = FALSE),
  sum      = list(suffix = "-sum",      directed = FALSE),
  identity = list(suffix = "-ident",    directed = FALSE),
  receiver = list(suffix = "-receiver", directed = TRUE),
  sender   = list(suffix = "-sender",   directed = TRUE),
  minmax   = list(suffix = "-minmax",   directed = FALSE)
)

#' Turn a node attribute into a matrix
#'
#' UCINET: Data | Attribute to matrix. Builds a node-by-node matrix out of a
#' single attribute, so that homophily, sender and receiver effects can be
#' tested with the same machinery as any other network.
#'
#' `"receiver"` and `"sender"` are the two that answer "does the value of the
#' node being chosen, or of the node doing the choosing, predict the tie?":
#' `"receiver"` copies the attribute across every row, so cell `(i,j)` holds
#' the value of *j*, and `"sender"` copies it down every column, so cell
#' `(i,j)` holds the value of *i*. Both are what a QAP regression wants as a
#' predictor.
#'
#' A missing attribute value gives a missing row and column.
#'
#' @param attribute The attribute: a vector (named, or matched to `net`'s
#'   nodes in order), or the name of a column, which is looked up first in
#'   `net`'s attribute table and then in `data`.
#' @param method One of `"same"` (the dialog's default: 1 where two nodes have
#'   the same value, 0 where they do not), `"diff"` (`a[i] - a[j]`),
#'   `"absdiff"`, `"sqrdiff"`, `"product"`, `"sum"`, `"identity"` (the identity
#'   coefficient, `2 a[i] a[j] / (a[i]^2 + a[j]^2)`), `"receiver"`, `"sender"`,
#'   or `"minmax"` (the smaller over the larger, and 1 where they are equal).
#' @param normalize Applied to the attribute before anything else: `"none"`
#'   (the default), `"center"` (subtract the mean) or `"standardize"`
#'   (subtract the mean and divide by the population standard deviation).
#' @param net A network to take node labels from, and to look `attribute` up
#'   in when it is a column name.
#' @param data A data frame to look `attribute` up in when it is a column name
#'   and `net` does not carry it.
#' @return A 1-mode `xucinet` object, `directed = TRUE` for the three
#'   asymmetric methods and `FALSE` otherwise, titled the way UCINET names it
#'   (`camp92-sameGender`).
#' @seealso [xcombinenodes()] to aggregate a network by an attribute instead.
#' @examples
#' gender <- camp92_attr$Gender
#' names(gender) <- rownames(camp92_attr)
#' as.matrix(xattributetomatrix(gender, method = "same"))[1:4, 1:4]
#'
#' # a sender effect: every column is the attribute
#' as.matrix(xattributetomatrix(gender, method = "sender"))[1:4, 1:4]
#' @export
xattributetomatrix <- function(attribute,
                               method = c("same", "diff", "absdiff", "sqrdiff",
                                          "product", "sum", "identity",
                                          "receiver", "sender", "minmax"),
                               normalize = c("none", "center", "standardize"),
                               net = NULL, data = NULL) {
  method <- match.arg(method)
  normalize <- match.arg(normalize)
  spec <- atm_methods[[method]]

  expr <- deparse1(substitute(attribute))
  res <- resolve_attribute(attribute, net, data, expr)
  a <- res$values
  labels <- res$labels

  categorical <- is.character(a) || is.factor(a)
  if (categorical && !identical(method, "same")) {
    stop("method = \"", method, "\" needs a numeric attribute; ",
         if (nzchar(res$name)) res$name else expr,
         " is ", if (is.factor(a)) "a factor" else "text", ".\n",
         "  Only method = \"same\" is meaningful for a categorical ",
         "attribute.", call. = FALSE)
  }
  if (!categorical) {
    a <- as.numeric(a)
    a <- normalize_attribute(a, normalize)
  }

  out <- attribute_matrix(a, method, labels)
  net_out <- new_xucinet(out, mode = "1-mode", directed = spec$directed,
                         title = res$title)
  transformed(net_out, paste0(spec$suffix, res$name),
              paste0(method, " matrix from ", res$name,
                     if (!identical(normalize, "none"))
                       paste0(" (", normalize, "d first)") else ""))
}

# normalizeattribute: 1 centres, 2 standardises by the population sd.
normalize_attribute <- function(a, normalize) {
  if (identical(normalize, "none")) return(a)
  obs <- a[!is.na(a)]
  if (!length(obs)) return(a)
  mu <- mean(obs)
  if (identical(normalize, "center")) return(a - mu)
  sdev <- sqrt(mean((obs - mu)^2))
  if (sdev > 0) (a - mu) / sdev else a
}

# G3: an attribute may be a vector, or the name of a column looked up first in
# the network's own table and then in `data`.
resolve_attribute <- function(attribute, net, data, expr) {
  name <- ""
  # The network's own table first, then `data`; neither is looked at unless
  # the attribute arrived as a name.
  from_net <- if (is.null(net)) NULL else xattributes(net)
  if (is.character(attribute) && length(attribute) == 1 &&
      !(is.null(from_net) && is.null(data))) {
    name <- attribute
    tbl <- if (!is.null(from_net)) from_net else data
    if (is.null(tbl) || !name %in% names(tbl)) {
      stop("no attribute called \"", name, "\".\n",
           "  Available: ", paste(names(tbl), collapse = ", "), call. = FALSE)
    }
    values <- tbl[[name]]
    labels <- rownames(tbl)
  } else {
    values <- attribute
    labels <- names(attribute)
    # `camp92_attr$Gender` names the variable as clearly as a string would.
    name <- if (grepl("\\$", expr)) sub("^.*\\$", "", expr) else ""
  }

  if (is.null(labels)) {
    labels <- if (!is.null(net)) rownames(as.matrix(net))
              else as.character(seq_along(values))
  }
  if (length(labels) != length(values)) {
    stop("the attribute has ", length(values), " values but there are ",
         length(labels), " nodes to label them with.", call. = FALSE)
  }
  title <- if (!is.null(net)) as_xucinet(net)$title else expr
  list(values = values, labels = labels, name = name, title = title)
}

attribute_matrix <- function(a, method, labels) {
  n <- length(a)
  gap <- is.na(a)
  out <- switch(
    method,
    same     = outer(a, a, function(x, y) as.numeric(x == y)),
    diff     = outer(a, a, "-"),
    absdiff  = abs(outer(a, a, "-")),
    sqrdiff  = outer(a, a, "-")^2,
    product  = outer(a, a, "*"),
    sum      = outer(a, a, "+"),
    identity = {
      num <- 2 * outer(a, a, "*")
      den <- outer(a^2, a^2, "+")
      ifelse(den != 0, num / den, NA_real_)
    },
    # duplicatedrows: m[i,j] := a[j], so every row is the attribute.
    receiver = matrix(rep(a, each = n), n, n),
    # duplicatedcols: m[i,j] := a[i], so every column is.
    sender   = matrix(rep(a, times = n), n, n),
    minmax   = {
      lo <- pmin(outer(a, a, function(x, y) x), outer(a, a, function(x, y) y))
      hi <- pmax(outer(a, a, function(x, y) x), outer(a, a, function(x, y) y))
      # getvalue returns 1 when the two are equal, which covers hi == 0 too.
      ifelse(outer(a, a, "==") , 1, lo / hi)
    })

  storage.mode(out) <- "double"
  # Every procedure skips a missing attribute value, leaving the cell as the
  # matrix was allocated: missing.
  if (any(gap)) { out[gap, ] <- NA_real_; out[, gap] <- NA_real_ }
  dimnames(out) <- list(labels, labels)
  out
}
