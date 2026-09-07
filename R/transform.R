# Transformations. Phase 1 exports these as xdichotomize(), xsymmetrize() and
# the rest; for now only the dichotomiser exists, because xdensity(weighted =
# FALSE) needs it and it has to agree with UCINET cell for cell.

# Dichotomise at > 0, the way UCINET's dichot() does.
#
# UCINET's dichot() used to zero the diagonal, and through Phase 0 we matched
# that for 1-mode data while arguing it was wrong for 2-mode, where cell (i, i)
# is row-node i tied to column-node i and dropping it deletes real ties.
#
# UCINET 6.849 no longer zeroes it. Regenerating the density goldens changed
# g_baker_bin: the twenty diagonal cells that used to come back 0 now come back
# 1, because baker_journals counts a journal's citations to itself. So the
# special case goes away and dichotomising is a threshold and nothing else.
# The `twomode` argument is kept because callers pass it and the distinction may
# return; it no longer changes the result. Ledger entry 1.
dichotomize <- function(m, twomode = FALSE) {
  out <- (m > 0) * 1
  dim(out) <- dim(m)
  dimnames(out) <- dimnames(m)
  out
}
