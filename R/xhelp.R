# xhelp(): find the routine you want without knowing what we called it.
#
# A UCINET user knows the menu path, a first-edition reader knows the 1e name,
# and everyone else knows roughly what the thing is called in English. All three
# should get you there, so the search runs over the shipped crosswalk table -
# menu path, topic, 1e name, 2.0 name - rather than over function names alone.
#
# Whether a routine exists yet is worked out at call time, never stored: most of
# them are still to be written, and a status frozen into the table would start
# lying the day the first one landed.

xhelp_table <- function() {
  if (!is.null(the$crosswalk)) return(the$crosswalk)
  p <- system.file("extdata", "crosswalk-routines.csv", package = "xucinet")
  if (!nzchar(p)) return(NULL)
  tbl <- utils::read.csv(p, stringsAsFactors = FALSE, colClasses = "character")
  tbl$exists <- vapply(tbl$name_2, function(f) {
    f <- sub("[(].*$", "", trimws(sub(",.*$", "", f)))
    grepl("^[a-z_]", f) && exists(f, envir = asNamespace("xucinet"), mode = "function")
  }, logical(1))
  the$crosswalk <- tbl
  tbl
}

the <- new.env(parent = emptyenv())
the$crosswalk <- NULL

#' Find a routine by name, menu path or plain English
#'
#' Searches every way you might know a routine by: the xucinet name, the UCINET
#' menu path it corresponds to, the name the first edition used, and the plain
#' English description. `xhelp("degree")`, `xhelp("Network|Centrality")` and
#' `xhelp("xDegreeCentrality")` all find the same thing.
#'
#' Matching is case-insensitive, matches anywhere in the text, and falls back to
#' approximate matching when nothing matches exactly, so a near miss or a typo
#' still finds the routine.
#'
#' Routines still to be written are listed too, marked `planned`. That is
#' deliberate: knowing a routine is coming and what it will be called is more
#' use than an empty result, and the whole of Phases 1 to 5 is still ahead.
#'
#' @param topic What to look for. Omit to list everything.
#' @param max Most results to print.
#' @return A data frame of matches, invisibly.
#' @examples
#' xhelp("centrality")
#' xhelp("Network|Cohesion")
#' @export
xhelp <- function(topic = NULL, max = 25) {
  tbl <- xhelp_table()
  if (is.null(tbl)) {
    stop("The crosswalk table is missing from the installed package.", call. = FALSE)
  }
  hits <- if (is.null(topic) || !nzchar(topic)) tbl else xhelp_search(tbl, topic)

  if (!nrow(hits)) {
    cat("Nothing matches \"", topic, "\".\n", sep = "")
    cat("Try a menu path (\"Network|Cohesion\"), a measure (\"betweenness\"),\n")
    cat("or a first-edition name (\"xDegreeCentrality\"). xhelp() lists everything.\n")
    return(invisible(hits))
  }

  shown <- utils::head(hits, max)
  name_w <- max(nchar(shown$name_2), 8L)
  for (i in seq_len(nrow(shown))) {
    r <- shown[i, ]
    cat(formatC(r$name_2, width = -name_w), "  ",
        if (r$exists) "          " else "(planned) ",
        r$topic, "\n", sep = "")
    if (nzchar(r$menu)) {
      cat(strrep(" ", name_w + 12), "UCINET: ", r$menu, "\n", sep = "")
    }
  }
  if (nrow(hits) > max) {
    cat("... and ", nrow(hits) - max, " more; raise max= to see them.\n", sep = "")
  }
  invisible(hits)
}

# Exact-ish first: anything containing the term, anywhere. Only if that finds
# nothing does approximate matching run, so a real match is never buried under
# fuzzy ones.
xhelp_search <- function(tbl, topic) {
  # Everything is lowercased and matched literally rather than with
  # ignore.case = TRUE, which grepl() silently drops when fixed = TRUE. Literal
  # matching is what "Network|Cohesion" needs: as a regex the bar would be an
  # alternation and would match nearly every row.
  q <- tolower(topic)
  name <- tolower(paste(tbl$name_2, tbl$name_1e))
  rest <- tolower(paste(tbl$topic, tbl$menu, tbl$section))
  fields <- paste(name, rest)

  in_name <- grepl(q, name, fixed = TRUE)
  in_rest <- grepl(q, rest, fixed = TRUE)
  if (any(in_name | in_rest)) {
    hits <- tbl[in_name | in_rest, , drop = FALSE]
    # A hit on the name is what the reader most likely meant; a hit on the
    # description is a suggestion.
    return(hits[order(!in_name[in_name | in_rest]), , drop = FALSE])
  }

  words <- strsplit(q, "[^a-z0-9]+")[[1]]
  words <- words[nzchar(words)]
  if (length(words)) {
    hit <- Reduce(`&`, lapply(words, function(w) grepl(w, fields, fixed = TRUE)))
    if (any(hit)) return(tbl[hit, , drop = FALSE])
  }
  tbl[agrepl(q, fields, ignore.case = TRUE, max.distance = 0.2), , drop = FALSE]
}
