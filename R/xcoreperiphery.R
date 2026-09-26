# Core/periphery.
#
# UCINET: Network | Core/Periphery | Categorical | Borgatti & Everett
# (uc_categoricalcoreperiphery.pas, TCategoricalCorePeriphery.run) and
# Network | Core/Periphery | Continuous (uc_ContinuousCoreness.pas,
# TContinuousCorenessDlg.run); repository StephenBorgatti/ucinet at commit
# c7b4956. The engines are G2Tools/utcpcat.pas (tcatcp), G2Tools/utminres.pas
# (tminres) and G2Tools/utconcentration.pas (getcorenessconcentration);
# repository StephenBorgatti/tools at commit 207958a.
#
# One function, as Steve asked (crosswalk annotation, 23 Sep 2026: "one
# function. Drop the helpers"). Both models are always fitted and always in
# the result; `type` chooses which is printed (SPEC addendum, 23 Sep 2026,
# item 5).
#
# Categorical (design answer 12.4: "copy ucinet's current code"):
#   - starting partition: column sums (indegree) for binary data, a short
#     power iteration on x + t(x) for valued data, cut where the fit is best
#     (getdegreepart / geteigenpart and getelbow);
#   - steepest-ascent hill climbing on single-node flips (hillclimb), from the
#     starting partition and then from random partitions in which each node is
#     core with probability 0.384 (getrandompart);
#   - the fit is the correlation between the data and the ideal: 1 in the
#     core block, 0 in the periphery block, and the off-diagonal blocks
#     ignored unless c2p / p2c give them a density.
#   Dialog defaults: exclude ties to self, 500 iterations, random starts 20
#   below 50 nodes, 10 below 150, 3 above (setrandomstarts), c2p = p2c = NA.
#   UCINET calls `randomize`, so its own runs are not reproducible; here the
#   random starts come from the Delphi generator under `seed`, and only the
#   fit can be compared with UCINET (ledger entry 35).
#   UCINET issue 29: with c2p or p2c set, tcatcp.evaluate drops off-diagonal
#   cells whose positions in the core and periphery lists coincide. The
#   off-diagonal blocks are counted whole here.
#
# Continuous: MINRES. The data are symmetrized by averaging, missing cells set
# to 0; the principal singular vector gives the loadings, and unless the
# diagonal is valid the diagonal is replaced by the loadings squared and the
# SVD re-run until the loadings move less than 1e-5. Coreness is the loadings
# normalized to unit length, absolute values unless negatives are allowed.
# The concentration table and the recommended core are getcorenessconcentration.
#
# 2-mode: UCINET's 2-Mode Categorical Core/Periphery (x2mcatcp.pas,
# run2modecategoricalcp, with genetic2 and greedy in G1Tools/Ugenetic.pas;
# ucinet c7b4956, tools 207958a), ported in catcp2_run() below. Steve, 26 Sep
# 2026 (issue #25): port UCINET's model only, no dual projection. Rows and
# columns are each split into core and periphery; the fit is the correlation
# between the data and an ideal with the row-core by column-core block 1 and the
# row-periphery by column-periphery block 0, the other two blocks ignored, and
# each core must have at least 3 members and leave at least 3 outside. Search:
# a start from the row and column sums (the top third of each), a genetic
# algorithm (population 250, crossover 0.6 on each mode separately, mutation
# 0.025, roulette selection), then single flips (greedy). UCINET issue 34: five
# defects in that code are not copied (see dev/UCINET-ISSUES.md; ledger 45).
# UCINET calls `randomize`; here R's generator runs under `seed`.

#' Core/periphery structure
#'
#' UCINET: Network | Core/Periphery | Categorical and Continuous. Finds the
#' core of a network, a set of nodes densely tied to each other, and the
#' periphery, loosely tied to each other.
#'
#' Both models are always fitted; `type` chooses which is printed.
#'
#' **Categorical** (Borgatti and Everett 1999): a partition into core and
#' periphery that maximizes the correlation between the data and the ideal
#' pattern, a complete core block and an empty periphery block. The
#' core-to-periphery and periphery-to-core blocks are ignored unless `c2p` and
#' `p2c` give them a density. The search is UCINET's: hill climbing from a
#' degree-based start and then from `starts - 1` random partitions. `Class` in
#' `$nodes` is 1 for the core and 2 for the periphery.
#'
#' **2-mode data** (UCINET's 2-Mode Categorical Core/Periphery): the rows and
#' the columns are each divided into core and periphery, so that the row core
#' is densely tied to the column core and the row periphery hardly tied to the
#' column periphery. The fit is the correlation between the data and that ideal,
#' the two mixed blocks ignored; each core has at least three members and
#' leaves at least three outside, so each mode needs six nodes. The search is
#' UCINET's genetic algorithm (`maxit` generations, 1000 by default for 2-mode
#' data; `popsize`, `stopafter`) followed by single-node flips (`auxit`
#' passes). Only the categorical model exists for 2-mode data. `$nodes` lists
#' the rows, then the columns, with `Class` and `Mode`.
#'
#' **Continuous**: a coreness score for every node, such that the product of
#' two nodes' scores approximates the tie between them, estimated by MINRES
#' (UCINET's algorithm). `Coreness` holds the scores, normalized to unit
#' length; `InCore` marks the core UCINET recommends, the top nodes where the
#' correlation between the scores and a 0/1 core vector is highest (the
#' *concentration*).
#'
#' @section UCINET equivalent:
#' Network | Core/Periphery | Categorical | Borgatti & Everett: *Exclude ties
#' to self* is `diagonal = FALSE`, *Number of random starts* is `starts`,
#' *Max number of iterations* is `maxit`, *Desired density for core to
#' periphery ties* is `c2p`, and *periphery to core* is `p2c`.
#' Network | Core/Periphery | Continuous: *Diagonal values valid* is
#' `diagonal`, *Prevent negative coreness* is `positive`.
#'
#' @param net A network (any accepted form), 1-mode or 2-mode.
#' @param type Which model to print: `"categorical"` (the default) or
#'   `"continuous"`.
#' @param relation Which relation of a multi-relation dataset, by name or
#'   position. Defaults to the first.
#' @param diagonal Count the diagonal (self-ties)? `FALSE` by default, as in
#'   both dialogs.
#' @param starts Number of starts for the categorical search, the first from
#'   the degree-based partition. `NULL` follows UCINET: 20 below 50 nodes, 10
#'   below 150, else 3.
#' @param maxit Maximum hill-climbing steps per start. UCINET's default is 500.
#'   For 2-mode data, the maximum number of generations; UCINET's default, 1000,
#'   is used when `maxit` is not given.
#' @param c2p,p2c Ideal density of the core-to-periphery and
#'   periphery-to-core blocks, or `NULL` (the default) to ignore them.
#' @param seed Seed for the random starts. `NULL` draws one; it is reported.
#' @param positive Continuous model: report absolute coreness, UCINET's
#'   *Prevent negative coreness* (on by default).
#' @param popsize,stopafter,auxit 2-mode data only: the genetic algorithm's
#'   population size (250), the number of generations in a row without
#'   improvement after which it stops (2), and the most passes of single-node
#'   flips afterwards (6). UCINET's defaults.
#' @return An object of class `c("xcoreperiphery", "xucinet_output")`.
#'   `$nodes`: `Coreness`, `InCore` and `Class`. `$summary`: the categorical
#'   and continuous fits, Gini coefficient, heterogeneity, recommended core
#'   size and its concentration. `$matrices`: the categorical block densities,
#'   the concentration table and the continuous model's expected values. `$fit`
#'   is the fit of the printed model.
#' @seealso [xblockmodel()], [xeigenvector()].
#' @examples
#' xcoreperiphery(campnet, seed = 1)
#' xcoreperiphery(campnet, type = "continuous")
#' xcoreperiphery(davis, seed = 1)
#' @export
xcoreperiphery <- function(net, type = c("categorical", "continuous"),
                           relation = NULL, diagonal = FALSE, starts = NULL,
                           maxit = 500, c2p = NULL, p2c = NULL, seed = NULL,
                           positive = TRUE, popsize = 250, stopafter = 2,
                           auxit = 6) {
  net <- xnet(net, substitute(net))
  if (identical(net$mode, "2-mode")) {
    if (!missing(type) && match.arg(type) == "continuous") {
      stop("xcoreperiphery(): 2-mode data have only the categorical model; ",
           "UCINET has no 2-mode continuous core/periphery.", call. = FALSE)
    }
    return(xcoreperiphery_2mode(net, relation, if (missing(maxit)) 1000L else maxit,
                                popsize, stopafter, auxit, seed, match.call()))
  }
  type <- match.arg(type)
  require_1mode(net, "xcoreperiphery()")
  m <- as.matrix(net, relation = relation)
  n <- nrow(m)
  labels <- rownames(m)
  assumptions <- character()
  if (xnrelations(net) > 1) {
    assumptions <- sprintf("Relation: %s (of %d).",
                           if (is.null(relation)) xrelations(net)[1] else relation,
                           xnrelations(net))
  }
  if (n < 3) stop("xcoreperiphery() needs at least three nodes.", call. = FALSE)
  if (is.null(starts)) starts <- if (n < 50) 20L else if (n < 150) 10L else 3L
  if (is.null(seed)) seed <- sample.int(10000, 1)

  cat_fit <- catcp_run(m, diagonal, as.integer(starts), as.integer(maxit),
                       if (is.null(c2p)) NA_real_ else c2p,
                       if (is.null(p2c)) NA_real_ else p2c, seed)
  cont <- contcp_run(m, diagonal, positive)

  core_first <- c("Core", "Periphery")
  dens <- aggregate_blocks(m, cat_fit$part, "mean", diagonal)
  dimnames(dens) <- list(core_first, core_first)

  nodes <- data.frame(Coreness = cont$coreness, InCore = cont$incore,
                      Class = cat_fit$part, row.names = labels,
                      check.names = FALSE)
  summary <- list(
    `Categorical fit` = cat_fit$fit,
    `Continuous fit` = cont$fit,
    `Gini coefficient` = cont$gini,
    `Gini-based core/peripheriness` = cont$gini * cont$fit,
    Heterogeneity = cont$hetero,
    `Core size` = cont$numcore,
    Concentration = cont$maxconc)

  if (anyNA(m)) {
    assumptions <- c(assumptions,
                     "Missing values are recoded to zero by the continuous model.")
  }
  if (!is.null(c2p) || !is.null(p2c)) {
    assumptions <- c(assumptions, paste(
      "Off-diagonal blocks are counted whole; UCINET 6.849 drops some of their",
      "cells (UCINET issue 29)."))
  }
  assumptions <- c(assumptions, sprintf("Random number seed: %d.", as.integer(seed)))

  if (type == "categorical") {
    memb <- c("Core/Periphery Class Memberships:", "",
              paste("       Core: ", paste(labels[cat_fit$part == 1], collapse = " ")),
              paste("  Periphery: ", paste(labels[cat_fit$part == 2], collapse = " ")),
              "")
    preamble <- c(sprintf("Core/Periphery fit (correlation) = %s",
                          formatC(cat_fit$fit, format = "fg", digits = 4)),
                  "", memb, format_blocked_matrix(m, cat_fit$part), "",
                  paste("Iterations:", paste(cat_fit$iterations, collapse = " ")))
    fields <- c("Exclude diagonal:" = if (diagonal) "NO" else "YES",
                "Number of random starts:" = format(starts),
                "Maximum iterations:" = format(maxit),
                "Density of core->periphery ties:" = if (is.null(c2p)) "NA" else format(c2p),
                "Density of periphery->core ties:" = if (is.null(p2c)) "NA" else format(p2c),
                "Measure of fit:" = "Correlation")
    epilogue <- NULL
  } else {
    preamble <- if (cont$converged) {
      sprintf("Minres concluded in %d iterations.", cont$iterations)
    } else {
      sprintf("Warning: minres did not converge in %d iterations.", cont$iterations)
    }
    fields <- c("Algorithm:" = "Minres (SVD)",
                "Diagonal values valid:" = if (diagonal) "YES" else "NO")
    epilogue <- sprintf("Recommended core membership: top %d nodes (concentration = %s).",
                        cont$numcore, formatC(cont$maxconc, format = "f", digits = 3))
  }

  out <- new_xucinet_output(
    if (type == "categorical") "Categorical Core/Periphery" else "Continuous Coreness Model",
    net,
    nodes = nodes, summary = summary,
    matrices = list(`Density matrix` = dens,
                    `Concentration scores for different sizes of core` = cont$conc,
                    `Expected Values` = cont$expected),
    assumptions = assumptions, fields = fields,
    preamble = preamble, epilogue = epilogue,
    print_nodes = type == "continuous",
    show_columns = "Coreness",
    stats_block = type == "continuous",
    nodes_title = "Multiplicative Coreness",
    show_summary = if (type == "categorical") "Categorical fit" else
      c("Continuous fit", "Gini coefficient", "Gini-based core/peripheriness",
        "Heterogeneity"),
    hide = if (type == "categorical") {
      c("Concentration scores for different sizes of core", "Expected Values")
    } else {
      "Density matrix"
    },
    subclass = "xcoreperiphery", call = match.call())
  out$fit <- if (type == "categorical") cat_fit$fit else cont$fit
  out$seed <- seed
  out
}

# ---- categorical: tcatcp ----------------------------------------------------------

# The fit of every partition reachable by flipping one node, all at once. With
# c the 0/1 core indicator and p = 1 - c, each block's cell count, sum and sum
# of squares is a quadratic form (c'Vc, c'Yc, ...), and flipping node v
# changes each by a rank-one update. The correlation is rebuilt from the
# blocks' totals, as tcorr would from the cells.
catcp_fits <- function(cvec, V, Y, Y2, x_cp, x_pc, flips = TRUE) {
  pvec <- 1 - cvec
  quad <- function(A, a, b) sum(a * (A %*% b))
  base <- function(A) c(cc = quad(A, cvec, cvec), pp = quad(A, pvec, pvec),
                        cp = quad(A, cvec, pvec), pc = quad(A, pvec, cvec))
  blocks <- list(n = base(V), s = base(Y), q = base(Y2))
  score <- function(nb, sb, qb) {
    xs <- c(1, 0, x_cp, x_pc)
    use <- !is.na(xs)
    xs <- xs[use]; nb <- nb[, use, drop = FALSE]
    sb <- sb[, use, drop = FALSE]; qb <- qb[, use, drop = FALSE]
    N <- rowSums(nb)
    sx <- drop(nb %*% xs); sxx <- drop(nb %*% xs^2)
    sy <- rowSums(sb); syy <- rowSums(qb)
    sxy <- drop(sb %*% xs)
    vx <- sxx - sx^2 / N; vy <- syy - sy^2 / N
    r <- (sxy - sx * sy / N) / sqrt(vx * vy)
    r[!(N > 0) | vx < 1e-7 * N | vy < 1e-7 * N] <- NA
    r
  }
  now <- score(matrix(blocks$n, 1), matrix(blocks$s, 1), matrix(blocks$q, 1))
  if (!flips) return(now)
  # delta = +1 moves v into the core, -1 out of it
  delta <- ifelse(cvec == 1, -1, 1)
  upd <- function(A) {
    rc <- drop(A %*% cvec); cc_ <- drop(crossprod(A, cvec))
    rp <- drop(A %*% pvec); cp_ <- drop(crossprod(A, pvec))
    d <- diag(A)
    b <- base(A)
    cbind(cc = b[["cc"]] + delta * (rc + cc_) + d,
          pp = b[["pp"]] - delta * (rp + cp_) + d,
          cp = b[["cp"]] + delta * (rp - cc_) - d,
          pc = b[["pc"]] + delta * (cp_ - rc) - d)
  }
  list(now = now, flips = score(upd(V), upd(Y), upd(Y2)))
}

catcp_run <- function(m, diagonal, starts, maxit, x_cp, x_pc, seed) {
  n <- nrow(m)
  V <- (!is.na(m)) * 1
  if (!diagonal) diag(V) <- 0
  Y <- m; Y[is.na(Y)] <- 0; Y <- Y * V
  Y2 <- Y^2
  evaluate <- function(cvec) catcp_fits(cvec, V, Y, Y2, x_cp, x_pc, flips = FALSE)
  neg <- -.Machine$double.xmax        # mindouble: an invalid fit never wins

  hillclimb <- function(cvec) {
    it <- 0L
    repeat {
      it <- it + 1L
      f <- catcp_fits(cvec, V, Y, Y2, x_cp, x_pc)
      cur <- if (is.na(f$now)) neg else f$now
      cand <- f$flips
      cand[is.na(cand)] <- neg
      best <- which.max(cand)
      if (cand[best] > cur) {
        cvec[best] <- 1 - cvec[best]
        cur <- cand[best]
      } else {
        break
      }
      if (it == maxit) break
    }
    list(cvec = cvec, fit = cur, it = it)
  }

  start <- catcp_start(m, V, Y, diagonal, evaluate)
  first <- hillclimb(start)
  best <- first
  its <- first$it
  rng <- delphi_rng(seed)
  # optimize: every start runs, and the loop stops only once a perfect fit has
  # been reached, so a perfect first fit still costs one random start.
  if (starts >= 2) {
    for (s in 2:starts) {
      cvec <- vapply(seq_len(n), function(i) {
        rng$state <- (delphi_mulmod(rng$state) + 1) %% 2^32
        if (rng$state / 2^32 < 0.384) 1 else 0
      }, numeric(1))
      h <- hillclimb(cvec)
      its <- c(its, h$it)
      if (h$fit > best$fit) best <- h
      if (best$fit >= 1) break
    }
  }
  list(part = ifelse(best$cvec == 1, 1L, 2L),
       fit = if (best$fit == neg) NA_real_ else best$fit, iterations = its)
}

# getdegreepart (binary data) or geteigenpart (valued), each cut by getelbow.
catcp_start <- function(m, V, Y, diagonal, evaluate) {
  n <- nrow(m)
  ok <- m[!is.na(m)]
  valued <- any(ok != 0 & ok != 1)
  if (!valued) {
    offd <- V; diag(offd) <- 0
    score <- colSums(Y * offd)                  # deg[j] += m[i, j]
  } else {
    s1 <- rep(1, n)
    A <- m; A[is.na(A)] <- 0
    W <- (A + t(A)) * ((!is.na(m)) * 1)
    if (!diagonal) diag(W) <- 0
    for (k in 1:4) {
      s2 <- drop(W %*% s1)
      tot <- sqrt(sum(s2^2))
      if (tot > 0) s1 <- s2 / tot
      if (max(abs(s1 - s2)) < 0.01) break
    }
    score <- s1
  }
  ord <- order(-score, seq_len(n))
  maxcorr <- -2
  cut <- score[ord[1]]
  for (i in seq_len(n - 1)) {
    cvec <- numeric(n); cvec[ord[seq_len(i)]] <- 1
    r <- evaluate(cvec)
    r <- if (is.na(r)) -.Machine$double.xmax else r
    if (r > maxcorr) { maxcorr <- r; cut <- score[ord[i]] }
  }
  (score >= cut) * 1
}

# ---- continuous: tminres and getcorenessconcentration -------------------------------

contcp_run <- function(m, diagonal, positive, maxit = 100L, tol = 1e-5) {
  n <- nrow(m)
  x <- m; x[is.na(x)] <- 0
  sym <- (x + t(x)) / 2
  extract <- function(w) {
    s <- svd(w, nu = 1, nv = 0)
    scale <- if (s$d[1] > 0) sqrt(s$d[1]) else 0
    l <- s$u[, 1] * scale
    if (sum(l < 0) > n %/% 2) l <- -l
    list(l = l, scale = scale)
  }
  e <- extract(sym)
  l <- e$l
  iterations <- 0L
  converged <- FALSE
  if (diagonal || e$scale == 0) {
    converged <- TRUE
  } else {
    for (it in seq_len(maxit)) {
      iterations <- it
      prev <- l
      w <- sym; diag(w) <- l^2
      l <- extract(w)$l
      if (max(abs(l - prev)) < tol) { converged <- TRUE; break }
    }
  }
  expected <- outer(l, l)
  keep <- if (diagonal) matrix(TRUE, n, n) else row(sym) != col(sym)
  fit <- suppressWarnings(stats::cor(expected[keep], sym[keep]))
  if (is.na(fit)) fit <- 0
  total <- sqrt(sum(l^2))
  cor_n <- if (total > 0) l / total else rep(0, n)
  if (positive) cor_n <- abs(cor_n)
  dimnames(expected) <- list(rownames(m), rownames(m))

  conc <- concentration_table(x, cor_n)
  corr <- conc$table[, "Corr"]
  numcore <- if (all(is.na(corr))) 1L else unname(which.max(corr))
  maxconc <- if (all(is.na(corr))) NA_real_ else unname(corr[numcore])
  incore <- integer(n); incore[conc$order[seq_len(numcore)]] <- 1L

  list(coreness = cor_n, fit = fit, iterations = iterations,
       converged = converged, expected = expected, conc = conc$table,
       gini = conc$gini, hetero = conc$hetero, numcore = numcore,
       maxconc = maxconc, incore = incore)
}

concentration_table <- function(net, cent) {
  n <- length(cent)
  gini <- NA_real_
  asc <- order(cent, seq_len(n))
  total <- sum(cent)
  if (n >= 2 && total > 0) {
    cy <- cumsum(cent[asc] / total)
    gini <- 1 - sum((c(0, cy[-n]) + cy) / n)
  }
  s <- sum(cent)
  hetero <- if (n >= 2 && s != 0) {
    hom <- sum(cent^2) / s^2
    (hom - 1 / n) / (1 - 1 / n)
  } else NA_real_

  dsl <- order(-cent, seq_len(n))
  cs <- cent[dsl]
  range <- cs[1] - cs[n]
  c01 <- if (range > 1e-6) (cs - cs[n]) / range else cs
  cols <- c("Diff", "nDiff", "Corr", "Ident", "CoreDen", "PerDen", "DenDiff")
  tab <- matrix(NA_real_, n - 1, length(cols),
                dimnames = list(as.character(seq_len(n - 1)), cols))
  offd <- row(net) != col(net)
  bcorr <- function(a, b) {
    va <- mean((a - mean(a))^2); vb <- mean((b - mean(b))^2)
    if (va < 1e-7 || vb < 1e-7) NA_real_
    else mean((a - mean(a)) * (b - mean(b))) / sqrt(va * vb)
  }
  for (k in seq_len(n - 1)) {
    ind <- c(rep(1, k), rep(0, n - k))
    part <- integer(n); part[dsl[seq_len(k)]] <- 1L
    cc <- outer(part == 1, part == 1) & offd
    pp <- outer(part == 0, part == 0) & offd
    mincore <- c01[k]; maxper <- c01[k + 1]
    diff <- (mean(c01[seq_len(k)] - maxper) + mean(mincore - c01[(k + 1):n])) / 2
    ssq <- sum(ind^2) + sum(c01^2)
    tab[k, ] <- c(diff, diff * sqrt(k), bcorr(ind, cs),
                  if (ssq < 1e-7) NA_real_ else 2 * sum(ind * c01) / ssq,
                  if (any(cc)) mean(net[cc]) else NA_real_,
                  if (any(pp)) mean(net[pp]) else NA_real_,
                  if (any(cc) && any(pp)) mean(net[cc]) - mean(net[pp]) else NA_real_)
  }
  list(table = tab, gini = gini, hetero = hetero, order = dsl)
}
# ---- 2-mode: x2mcatcp.pas ---------------------------------------------------------

xcoreperiphery_2mode <- function(net, relation, maxit, popsize, stopafter, auxit,
                                 seed, call) {
  m <- as.matrix(net, relation = relation)
  nr <- nrow(m); nc <- ncol(m)
  if (nr < 6 || nc < 6) {
    stop("xcoreperiphery(): 2-mode data need at least six rows and six columns, ",
         "since each core has at least three members and leaves three outside.",
         call. = FALSE)
  }
  if (is.null(seed)) seed <- sample.int(10000, 1)
  a <- unname(m); a[is.na(a)] <- 0       # x2mcatcp: cells >= na set to 0
  fit <- with_seed(seed, catcp2_run(a, as.integer(maxit), as.integer(popsize),
                                    as.integer(stopafter), as.integer(auxit)))
  rp <- fit$part[seq_len(nr)]; cp <- fit$part[nr + seq_len(nc)]
  rlabs <- rownames(m); if (is.null(rlabs)) rlabs <- paste0("r", seq_len(nr))
  clabs <- colnames(m); if (is.null(clabs)) clabs <- paste0("c", seq_len(nc))
  labels <- c(rlabs, clabs)
  if (anyDuplicated(labels)) labels <- make.unique(labels)
  core_first <- c("Core", "Periphery")
  dens <- matrix(NA_real_, 2, 2, dimnames = list(core_first, core_first))
  for (i in 1:2) for (j in 1:2) {
    cells <- m[rp == i, cp == j]
    if (length(cells) && any(!is.na(cells))) dens[i, j] <- mean(cells, na.rm = TRUE)
  }
  dimnames(m) <- list(rlabs, clabs)
  mm <- m; mm[is.na(mm)] <- 0
  new_xucinet_output(
    "2-Mode Categorical Core/Periphery Model", net,
    nodes = data.frame(Class = fit$part, Mode = rep(c("row", "col"), c(nr, nc)),
                       row.names = labels, check.names = FALSE),
    summary = list(`Starting fit` = fit$start, `Categorical fit` = fit$fit,
                   Generations = fit$generations, `Auxiliary passes` = fit$aux,
                   `Row core` = sum(rp == 1), `Col core` = sum(cp == 1)),
    matrices = list(`Density matrix` = dens),
    assumptions = c(if (anyNA(m)) "Missing cells treated as 0, as UCINET does.",
                    sprintf("Random number seed: %d.", as.integer(seed))),
    fields = c("Max generations:" = format(maxit), "Population size:" = format(popsize),
               "Stop after generations with no improvement:" = format(stopafter),
               "Max auxiliary iterations:" = format(auxit)),
    preamble = c(sprintf("Starting fitness: %s", formatC(fit$start, format = "f", digits = 3)),
                 sprintf("Number of generations: %d", fit$generations),
                 sprintf("Final fitness: %s", formatC(fit$fit, format = "f", digits = 3)),
                 sprintf("Number of auxiliary iterations: %d", fit$aux), "",
                 "Blocked Adjacency Matrix -- Final", "",
                 format_blocked_matrix(mm, rp, cp), ""),
    show_summary = character(0),
    print_nodes = FALSE,
    subclass = "xcoreperiphery", call = call)
}

# corrfit: the correlation between the data and the ideal over the core-core
# (1) and periphery-periphery (0) cells, rescaled to (r + 1) / 2 so the genetic
# algorithm's roulette never sees a negative fitness; 0 when a core is smaller
# than 3 or leaves fewer than 3 outside. An undefined correlation (the scored
# cells all equal) scores 0 here; UCINET's scores the missing-value code, the
# largest fitness there is (UCINET issue 34, item 5).
catcp2_fitness <- function(a, p, nr, nc) {
  rc <- p[seq_len(nr)] == 1; cc <- p[nr + seq_len(nc)] == 1
  r1 <- sum(rc); c1 <- sum(cc)
  if (r1 < 3 || r1 > nr - 3 || c1 < 3 || c1 > nc - 3) return(0)
  core <- outer(rc, cc, `&`); peri <- outer(!rc, !cc, `&`)
  y <- c(a[core], a[peri])
  if (stats::var(y) == 0) return(0)
  (stats::cor(c(rep(1, sum(core)), rep(0, sum(peri))), y) + 1) / 2
}

# x2mcatcp.pas: the starting partition, genetic2, greedy.
catcp2_run <- function(a, maxgen, popsize, stopafter, auxit, pcross = 0.6,
                       pmut = 0.025) {
  nr <- nrow(a); nc <- ncol(a); len <- nr + nc
  fitf <- function(p) catcp2_fitness(a, p, nr, nc)

  # initialpartition: the top third of the rows by row sum, and of the columns
  # by column sum, are core. Every cell counts; UCINET leaves out the cells
  # whose row and column numbers are equal, a 1-mode rule (issue 34, item 1).
  start <- rep(2L, len)
  start[order(-rowSums(a), seq_len(nr))[seq_len(nr %/% 3)]] <- 1L
  start[nr + order(-colSums(a), seq_len(nc))[seq_len(nc %/% 3)]] <- 1L
  start_fit <- fitf(start)

  # genetic2. Member 1 is the starting partition and is scored like the others
  # (UCINET never scores it, item 3); the run stops after `stopafter`
  # generations in a row without improvement (UCINET's counter never moves,
  # item 2).
  if (popsize %% 2L == 1L) popsize <- popsize + 1L
  pop <- matrix(sample.int(2L, popsize * len, replace = TRUE), popsize, len)
  pop[1, ] <- start
  fit <- apply(pop, 1, fitf)
  best <- pop[which.max(fit), ]; bestfit <- max(fit)
  mutate <- function(g) {
    hit <- stats::runif(length(g)) <= pmut
    g[hit] <- sample.int(2L, sum(hit), replace = TRUE)
    g
  }
  select <- function(cum, total) {
    j <- which(cum >= stats::runif(1) * total)[1]
    if (is.na(j)) popsize else j
  }
  gen <- 0L; unchanged <- 0L
  if (bestfit < 1) repeat {
    gen <- gen + 1L
    cum <- cumsum(fit); total <- sum(fit)
    newpop <- pop
    for (i in seq(1L, popsize, by = 2L)) {
      p1 <- pop[select(cum, total), ]; p2 <- pop[select(cum, total), ]
      c1 <- p1; c2 <- p2
      # rows, then columns, each with its own crossover point (RandomRange(a, b)
      # is a <= k < b)
      jr <- if (stats::runif(1) <= pcross) sample.int(nr - 2L, 1) else nr
      if (jr < nr) { s <- (jr + 1):nr; c1[s] <- p2[s]; c2[s] <- p1[s] }
      jc <- if (stats::runif(1) <= pcross) nr + sample.int(nc - 2L, 1) else len
      if (jc < len) { s <- (jc + 1):len; c1[s] <- p2[s]; c2[s] <- p1[s] }
      newpop[i, ] <- mutate(c1); newpop[i + 1L, ] <- mutate(c2)
    }
    pop <- newpop
    fit <- apply(pop, 1, fitf)
    if (max(fit) > bestfit) {
      bestfit <- max(fit); best <- pop[which.max(fit), ]; unchanged <- 0L
    } else {
      unchanged <- unchanged + 1L
    }
    if (gen >= maxgen || bestfit >= 1 || unchanged >= stopafter) break
  }

  # greedy: flip each node in turn, keep a flip that raises the fit.
  aux <- 0L
  repeat {
    aux <- aux + 1L
    changed <- FALSE
    for (u in seq_len(len)) {
      old <- best[u]
      best[u] <- if (old == 1L) 2L else 1L
      f <- fitf(best)
      if (f > bestfit) { bestfit <- f; changed <- TRUE } else best[u] <- old
    }
    if (aux >= auxit || bestfit >= 1 || !changed) break
  }
  list(part = as.integer(best), fit = 2 * bestfit - 1, start = 2 * start_fit - 1,
       generations = gen, aux = aux)
}

