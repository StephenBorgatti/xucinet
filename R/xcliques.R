# Cliques.
#
# UCINET: Network | Subgroups | Cliques. The procedure cliques in Xclique.pas
# (with its dialog CliqDlg), the enumeration BronKerbosch in
# G1Tools/uclique.pas (ExtendVersion2; saveclique and constructoverlapmatrix
# in the same unit), and clusteroverlaps in Xclqtool.pas, which runs
# average-link hierarchical clustering on the co-membership matrix. Repositories
# StephenBorgatti/ucinet at commit c7b4956 and StephenBorgatti/tools at commit
# 207958a.
#
# Dialog defaults: minimum size 3; Type = Weak (a tie in either direction,
# which is the maximum-symmetrize of design answer 11.1; Strong needs both);
# "Analyze pattern of overlaps" on. Valued data: "WARNING: Valued graph. All
# values > 0 treated as 1".
#
# The enumeration is Bron and Kerbosch's version 2 (CACM Algorithm 457), ported
# step for step, because the order in which it finds the cliques is the order
# UCINET numbers and prints them. igraph::max_cliques finds the same set in
# another order.
#
# Left out: UCINET also clusters the clique-by-clique overlap matrix. The
# chapter uses the actor-by-actor clustering only.

#' Cliques
#'
#' UCINET: Network | Subgroups | Cliques. Every maximal complete subgraph of at
#' least `min` nodes, how much each node takes part in each, and a clustering
#' of the nodes by how many cliques they share.
#'
#' A clique is a set of nodes all tied to one another that no other node could
#' join. Directed data are made undirected first: a tie in either direction
#' counts (UCINET's *Weak* cliques, the default), or with `type = "strong"`
#' only ties that go both ways. Valued data are treated as binary.
#'
#' The report lists the cliques in the order UCINET finds and numbers them,
#' then the participation scores (for each node and clique, the proportion of
#' the clique's members the node is tied to, counting itself), then the
#' hierarchical clustering of the co-membership matrix, which counts for each
#' pair of nodes the cliques they are both in. That matrix is kept in the object
#' but not printed, as in UCINET.
#'
#' @section UCINET equivalent:
#' Network | Subgroups | Cliques. *Minimum size* is `min`; *Type* is `type`.
#'
#' @param net A network (any accepted form). 1-mode.
#' @param min The smallest clique to report. UCINET's default is 3.
#' @param type `"weak"` (the default: a tie in either direction) or
#'   `"strong"` (ties both ways).
#' @param relation Which relation of a multi-relation dataset, by name (in any case) or
#'   position. Defaults to the first.
#' @return An object of class `c("xcliques", "xucinet_output")` with
#'   `$cliques`, a list of label vectors in UCINET's order;
#'   `$matrices$participation` (node by clique) and `$matrices$comembership`
#'   (node by node); and `$clustering`, the [xhclust()] result on the
#'   co-membership matrix. `$comembership` is the same matrix, for
#'   `xhclust(xcliques(net)$comembership, type = "similarities")`.
#' @seealso [xfactions()] and [xcommunities()] for partitions rather than
#'   overlapping groups; [xhclust()].
#' @examples
#' xcliques(campnet)
#' @export
xcliques <- function(net, min = 3, type = c("weak", "strong"), relation = NULL) {
  net <- xnet(net, substitute(net))
  type <- match.arg(type)
  rel <- ego_relation(net, relation, "xcliques()")
  m <- rel$m
  n <- nrow(m)
  labels <- rownames(m)
  if (!is.numeric(min) || length(min) != 1 || min < 1) {
    stop("xcliques(): min must be a whole number of at least 1.", call. = FALSE)
  }

  assumptions <- rel$note
  vals <- m[!is.na(m) & row(m) != col(m)]
  if (any(vals != 0 & vals != 1)) {
    assumptions <- c(assumptions, "Valued graph. All values > 0 treated as 1.")
  }
  tie <- !is.na(m) & m > 0
  adj <- if (type == "weak") tie | t(tie) else tie & t(tie)
  diag(adj) <- FALSE

  cliques <- bron_kerbosch_v2(adj, min)
  k <- length(cliques)
  clique_labels <- lapply(cliques, function(ix) labels[sort(ix)])

  # Participation: `d.cell[i][i] := 1`, then ties from i to the members over
  # the clique's size.
  adj_self <- adj
  diag(adj_self) <- TRUE
  part <- matrix(0, n, k, dimnames = list(labels, as.character(seq_len(k))))
  for (j in seq_len(k)) {
    ix <- cliques[[j]]
    part[, j] <- rowSums(adj_self[, ix, drop = FALSE]) / length(ix)
  }

  # constructoverlapmatrix: pairs of nodes, number of cliques they share; the
  # diagonal is the number of cliques each node is in.
  # Added clique by clique rather than as member %*% t(member), which on 4275
  # nodes and 1244 cliques took 12 s (#45).
  comemb <- matrix(0, n, n)
  for (ix in cliques) comemb[ix, ix] <- comemb[ix, ix] + 1
  dimnames(comemb) <- list(labels, labels)

  clustering <- NULL
  epilogue <- NULL
  if (k > 0 && n > 2) {
    clustering <- xhclust(comemb, type = "similarities", method = "average",
                          plot = FALSE)
    # runcluster is called with the title 'Hierarchical Clustering of Overlap
    # Matrix', which takes the place of the diagram's usual heading.
    epilogue <- clustering$preamble
    epilogue[1] <- toupper("Hierarchical Clustering of Overlap Matrix")
  }

  preamble <- c(paste0(k, " cliques found."), "",
                vapply(seq_len(k), function(j) {
                  paste0(formatC(j, width = 4), ":  ",
                         paste(clique_labels[[j]], collapse = " "))
                }, character(1)))

  out <- new_xucinet_output(
    "Cliques", net,
    matrices = list(participation = part, comembership = comemb),
    assumptions = assumptions,
    fields = c("Minimum Set Size:" = format(min),
               "Type:" = if (type == "weak") "Weak" else "Strong"),
    preamble = preamble,
    hide = "comembership",
    epilogue = epilogue,
    subclass = "xcliques", call = match.call())
  out$cliques <- clique_labels
  out$comembership <- comemb
  out$clustering <- clustering
  out
}

# BronKerbosch / ExtendVersion2 in uclique.pas. `adj` is logical, symmetric,
# with a FALSE diagonal; a pair is "connected" when it is a tie or the same
# node (the Delphi zeroes the diagonal of a distance matrix and tests
# `<= maxd`). Returns the cliques as index vectors, in the order the algorithm
# saves them. The Delphi's scalar loops (counting non-neighbours, filtering
# the new `not` and candidate sets) are done as vector operations; the choice
# of fixed point and the order of the backtrack are unchanged, so the cliques
# come out in the same order (#45: Terro, 4275 nodes, from 11 s to well under
# a second).
bron_kerbosch_v2 <- function(adj, minsize) {
  n <- nrow(adj)
  conn <- adj
  diag(conn) <- TRUE
  found <- list()
  compsub <- integer(0)

  extend <- function(old, ne, ce) {
    cand <- if (ne < ce) old[(ne + 1L):ce] else integer(0)
    # Fixed point: the first of old[1..ce] with the fewest non-neighbours among
    # the candidates. The Delphi's early exit (icount >= minnod) only skips
    # points that cannot win, so counting in full picks the same point.
    nonadj <- !conn[old[seq_len(ce)], cand, drop = FALSE]
    counts <- rowSums(nonadj)
    i <- which.min(counts)
    minnod <- counts[[i]]
    fixp <- old[i]
    if (i <= ne) {
      # A point of `not`: start from its last non-neighbour among the candidates
      # (`pos` in the Delphi). With minnod = 0 the loop below does not run.
      s <- if (minnod > 0) ne + max(which(nonadj[i, ])) else 0L
      nod <- 0L
    } else {
      s <- i
      nod <- 1L
    }
    # Backtrack cycle.
    k <- minnod + nod
    while (k >= 1) {
      p <- old[s]; old[s] <- old[ne + 1L]
      sel <- p; old[ne + 1L] <- p
      knot <- if (ne > 0) old[seq_len(ne)] else integer(0)
      knot <- knot[conn[sel, knot]]
      kcand <- if (ne + 2L <= ce) old[(ne + 2L):ce] else integer(0)
      kcand <- kcand[conn[sel, kcand]]
      knew <- c(knot, kcand)
      newne <- length(knot)
      newce <- length(knew)
      compsub <<- c(compsub, sel)
      if (newce == 0) {
        if (length(compsub) >= minsize) found[[length(found) + 1L]] <<- compsub
      } else if (newne < newce) {
        extend(knew, newne, newce)
      }
      compsub <<- compsub[-length(compsub)]
      ne <- ne + 1L
      if (k > 1) {
        # Select a candidate disconnected from the fixed point.
        s <- ne + which(!conn[fixp, old[(ne + 1L):ce]])[1L]
      }
      k <- k - 1L
    }
    invisible(NULL)
  }

  if (n > 0) extend(seq_len(n), 0L, n)
  found
}
