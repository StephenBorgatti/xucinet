# The permutation engine for chapter 14.
#
# Every permutation test in the package goes through perm_test(), so the
# p-value convention is defined once. UCINET's routines each count
# differently:
#   QAP Correlation (utqapsim)        (1 + count) / (1 + nperm)
#   Node-level regression, Dekker MRQAP, LR-QAP
#                                     the observed value is one of nperm draws:
#                                     (1 + count) / nperm, from nperm - 1
#                                     permutations
#   Y-permutation MRQAP (xmrqapna)    count / (nperm - 1), permutations only
#   ANOVA density models (XCatC2)     count / nperm, permutations only
# They differ by at most 1/nperm. Here `nperm` is the number of random
# permutations, and the observed arrangement is counted with them:
#   p = (1 + #{permuted >= observed}) / (1 + nperm)
# which is QAP Correlation's rule and never gives p = 0 (ledger entry 40).
#
# The three proportions are UCINET's: "As Large" (permuted >= observed), "As
# Small" (<=) and "As Extreme" (|permuted| >= |observed|). The significance a
# routine reports is As Extreme for a two-tailed test, and for a one-tailed
# test the proportion in the direction of the observed statistic's sign, as
# UCINET's one-tailed options do.
#
# Randomness: R's generator under `seed`. UCINET draws its own, so p-values
# agree with UCINET in distribution, not digit for digit (SPEC D12).

# stat: a function of a permutation (an integer vector) returning a numeric
#   vector of statistics; stat(seq_len(n)) is the observed value.
# n: the length of the permutation (nodes, or cases).
# Returns the observed statistics, the three proportions, the significance for
# the chosen tails, and the permutation distribution (mean, sd, min, max, and
# the number of permutations that gave a value).
perm_test <- function(stat, n, nperm, seed = NULL, tails = 2, observed = NULL,
                      perms = NULL) {
  obs <- if (is.null(observed)) stat(seq_len(n)) else observed
  k <- length(obs)
  if (nperm < 1) {
    na <- rep(NA_real_, k)
    return(list(observed = obs, ge = na, le = na, ext = na, sig = na,
                mean = na, sd = na, min = na, max = na, n = rep(0L, k),
                nperm = 0L))
  }
  if (is.null(perms)) {
    perms <- with_seed(seed, lapply(seq_len(nperm), function(i) sample.int(n)))
  }
  draws <- vapply(perms, function(p) {
    v <- stat(p)
    if (length(v) != k) rep(NA_real_, k) else as.numeric(v)
  }, numeric(k))
  draws <- matrix(draws, nrow = k)
  perm_summary(obs, draws, tails)
}

# The proportions and distribution summary from a k x nperm matrix of draws
# (NA where a permutation gave no value, which is then not counted).
perm_summary <- function(obs, draws, tails = 2) {
  k <- length(obs)
  tol <- 1e-10 * pmax(1, abs(obs))       # ties within rounding count as ties
  one <- function(i) {
    d <- draws[i, ]
    d <- d[!is.na(d)]
    m <- length(d)
    o <- obs[i]
    if (is.na(o)) {
      return(c(NA, NA, NA, NA, NA, NA, NA, m))
    }
    ge <- (1 + sum(d >= o - tol[i])) / (1 + m)
    le <- (1 + sum(d <= o + tol[i])) / (1 + m)
    ext <- (1 + sum(abs(d) >= abs(o) - tol[i])) / (1 + m)
    sig <- if (tails == 2) ext else if (o < 0) le else ge
    c(ge, le, ext, sig,
      if (m) mean(d) else NA, if (m > 1) stats::sd(d) else NA,
      if (m) min(d) else NA, if (m) max(d) else NA, m)
  }
  res <- vapply(seq_len(k), one, numeric(9))
  res <- matrix(res, nrow = 9)
  list(observed = obs, ge = res[1, ], le = res[2, ], ext = res[3, ],
       sig = res[4, ], mean = res[5, ], sd = res[6, ], min = res[7, ],
       max = res[8, ], n = as.integer(res[9, ]), nperm = ncol(draws))
}

# Permute the rows and columns of a square matrix together (QAP).
qap_permute <- function(m, p) m[p, p, drop = FALSE]

# The cells of a square matrix a QAP routine uses: off the diagonal, the lower
# triangle only when `sym`.
qap_cells <- function(n, sym) {
  if (sym) which(lower.tri(matrix(0, n, n))) else which(row(diag(n)) != col(diag(n)))
}

check_tails <- function(tails) {
  if (!tails %in% c(1, 2)) {
    stop("tails must be 1 or 2.", call. = FALSE)
  }
  as.integer(tails)
}
