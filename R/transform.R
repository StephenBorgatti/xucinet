# Transformations. Phase 1 exports these as xdichotomize(), xsymmetrize() and
# the rest; for now only the dichotomiser exists, because xdensity(weighted =
# FALSE) needs it and it has to agree with UCINET cell for cell.

# Dichotomise at > 0, the way UCINET's dichot() does.
#
# UCINET zeroes the diagonal as part of dichotomising. Comparing our result with
# g_baker_bin, which UCINET wrote from `dichot(baker_journals GT 0)`, the only
# cells that differed were the twenty on the diagonal: UCINET 0, ours 1, because
# baker_journals counts a journal's citations to itself.
#
# We follow that for 1-mode data only. A 2-mode matrix has no diagonal - cell
# (i, i) is row-node i tied to column-node i, two unrelated things - so zeroing
# it would silently delete real ties. Steve's call, 5 Sep 2026; recorded in
# inst/DIFFERENCES.md.
dichotomize <- function(m, twomode = FALSE) {
  out <- (m > 0) * 1
  dim(out) <- dim(m)
  dimnames(out) <- dimnames(m)
  if (!twomode && nrow(out) == ncol(out)) diag(out) <- 0
  out
}
