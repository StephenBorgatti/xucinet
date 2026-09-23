# Shared machinery for the chapter 8 ego-network routines.
#
# Every Ego Networks dialog in UCINET has its own way of saying which ties
# define ego's neighbourhood - "Which ties matter?", "Definition of Ego
# Network", "Ego network type", "How to define ego net" - with its own list of
# choices and its own default. The R functions share one argument, `ties`,
# and one vocabulary for it, and each offers the subset its dialog has:
#
#   "any"           a tie either way           (Undirected (OR); Both incoming
#                                               and outgoing; UNDIRECTED; Union)
#   "both"          in and out counted apart   (Both in and out)
#   "out"           outgoing ties only
#   "in"            incoming ties only
#   "reciprocated"  ties both ways             (Reciprocated; Reciprocal ties
#                                               only; Intersection)
#   "equal"         reciprocated with x(i,j) = x(j,i)
#
# Note that "Both incoming and outgoing ties" in the composition dialogs is a
# max-symmetrize (massagematrix, case 0), which is "any" here, whereas
# "Both in and out" in the tie-composition dialogs really does count a
# reciprocated tie twice. The same English, two different operations; the R
# vocabulary keeps them apart.

ego_ties_labels <- c(
  any = "Undirected (either direction)",
  both = "Both in and out",
  out = "Outgoing ties only",
  `in` = "Incoming ties only",
  reciprocated = "Reciprocated ties only",
  equal = "Reciprocated with equal values")

# match.arg with the choices named in the error, which match.arg's own message
# does not do helpfully when the choice vector is long.
match_ties <- function(ties, choices, fn) {
  if (length(ties) > 1L) return(choices[1L])
  d <- tolower(as.character(ties))
  hit <- pmatch(d, choices)
  if (is.na(hit)) {
    stop(fn, ": ties must be one of ",
         paste0("\"", choices, "\"", collapse = ", "), ".\n",
         "  Got \"", ties, "\".", call. = FALSE)
  }
  choices[hit]
}

# The composition and similarity dialogs rewrite the whole matrix before they
# look at any ego, so that row i holds ego i's ties to its alters
# (massagematrix in uegocomposition.pas, uc_EgoNetStrength.pas,
# uc_EgoNetHomophily.pas and uc_EgoNetHomophilyCont.pas, all the same four
# cases):
#   any           max of x(i,j) and x(j,i), both cells
#   out           unchanged
#   in            transposed
#   reciprocated  min of the two, both cells
# A missing value in either cell stays missing, as max() and min() of a value
# and bna do in the Delphi.
ego_rows <- function(m, ties) {
  switch(ties,
         any = pmax(m, t(m)),
         out = m,
         `in` = t(m),
         reciprocated = pmin(m, t(m)))
}

# The UCINET tie test shared by the two tie-composition routines:
# tsmat.istie(i, j, op, cut) after net.recode(opeq, 0, bna). Zeros are made
# missing first, so a zero is never a tie whatever the operator says, and a
# missing cell never is.
tie_op_labels <- c(`>` = "Greater than", `>=` = "Greater than or = to",
                   `==` = "Equal to", `<=` = "Less than or == to",
                   `<` = "Less than", `!=` = "Not equal to")

is_tie_matrix <- function(m, op, cutoff) {
  x <- m
  x[!is.na(x) & x == 0] <- NA
  out <- switch(op,
                `>` = x > cutoff,
                `>=` = x >= cutoff,
                `==` = abs(x - cutoff) < 1e-6,
                `<=` = x <= cutoff,
                `<` = x < cutoff,
                `!=` = abs(x - cutoff) >= 1e-6)
  out[is.na(out)] <- FALSE
  out
}

match_op <- function(op, fn) {
  choices <- names(tie_op_labels)
  if (length(op) > 1L) return("!=")
  if (!op %in% choices) {
    stop(fn, ": op must be one of ", paste0("\"", choices, "\"", collapse = ", "),
         ".", call. = FALSE)
  }
  op
}

# ---- attributes (design question G3) -----------------------------------------

# Categorical or continuous. Character, factor and logical are categorical;
# numeric is continuous unless `type = "categorical"` says otherwise. A numeric
# attribute that looks like a set of codes - whole numbers, five or fewer
# distinct values - is still treated as continuous, but with a note, because
# UCINET's attribute files store every category as a number and camp92's
# Gender (1, 2) is exactly that case.
attribute_type <- function(values, type, fn) {
  if (!is.null(type)) {
    choices <- c("categorical", "continuous")
    hit <- pmatch(tolower(type), choices)
    if (is.na(hit)) {
      stop(fn, ": type must be \"categorical\" or \"continuous\".", call. = FALSE)
    }
    type <- choices[hit]
    if (type == "continuous" && !is.numeric(values)) {
      stop(fn, ": a continuous attribute must be numeric; this one is ",
           class(values)[1], ".", call. = FALSE)
    }
    return(list(type = type, note = NULL))
  }
  if (is.character(values) || is.factor(values) || is.logical(values)) {
    return(list(type = "categorical", note = NULL))
  }
  v <- values[!is.na(values)]
  note <- NULL
  if (length(v) && all(v == round(v)) && length(unique(v)) <= 5L) {
    note <- paste0("Attribute has ", length(unique(v)), " whole-number values",
                   " and is treated as continuous; use type = \"categorical\"",
                   " if they are category codes.")
  }
  list(type = "continuous", note = note)
}

# Categorical values as a sorted set of keys. UCINET's attribute is numeric and
# its categories are sorted by value (tfrequencies.maketable(tab, skey) sorts the
# list before the columns are named); factors keep their level order and
# character vectors sort alphabetically. Labels are what UCINET's floattostr
# gives: 1 as "1", 1.5 as "1.5".
category_keys <- function(values) {
  if (is.factor(values)) {
    lev <- levels(values)
    lev <- lev[lev %in% as.character(values)]
    return(list(keys = lev, codes = match(as.character(values), lev),
                labels = lev))
  }
  keys <- sort(unique(values[!is.na(values)]))
  list(keys = keys, codes = match(values, keys), labels = as.character(keys))
}

# The attribute, resolved (G3) and checked against the network.
ego_attribute <- function(attribute, net, data, expr, n, fn) {
  res <- resolve_attribute(attribute, net, data, expr)
  if (length(res$values) != n) {
    stop(fn, ": the attribute has ", length(res$values), " values but the ",
         "network has ", n, " nodes.", call. = FALSE)
  }
  if (!nzchar(res$name)) res$name <- "Attribute"
  res
}

# One relation of the network, square, with a note when the dataset has more.
ego_relation <- function(net, relation, fn) {
  require_1mode(net, fn)
  m <- pick_relation(net, relation)
  note <- NULL
  if (xnrelations(net) > 1) {
    note <- sprintf("Relation: %s (of %d).",
                    if (is.null(relation)) xrelations(net)[1] else relation,
                    xnrelations(net))
  }
  list(m = m, note = note)
}
