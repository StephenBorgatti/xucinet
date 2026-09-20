# borgworld reference sources

The chapter 6 routines (`xmds`, `xcorrespondence`, `xhclust`) are ports of
Steve's `borgworld` package (github.com/stephenborgatti/borgworld), not of the
UCINET forms. borgworld is GitHub-only and xucinet is CRAN-bound, so the code
is copied in rather than imported, and the sources it was copied from are kept
here unchanged so that "the port reproduces borgworld" stays checkable after
borgworld moves on.

Vendored from borgworld at commit `6b0f0df` (HEAD of `main`, 3 December 2025).
The last commit touching each file:

| file | commit | date | ported into |
|---|---|---|---|
| `b_classicalmds.R` | `d9ca8bc` | 14 Oct 2025 | `R/xmds.R` (`method = "classical"`) |
| `b_nonmetricmds.R` | `d95ccf2` | 8 Oct 2025 | `R/xmds.R` (`method = "nonmetric"`), `xshepard()` |
| `b_hiclus.R` | `2eb26f4` | 25 Oct 2025 | `R/xhclust.R` |
| `b_moca.R` | `ad1e0ca` | 7 Oct 2025 | `R/xhclust.R` (`moca_table()`) |
| `b_corresp.R` | `51d6dca` | 14 Oct 2025 | `R/xcorrespondence.R` |
| `b_plotcoord.R` | `2eb26f4` | 25 Oct 2025 | `R/proximity-internals.R` (`plot_coords()`) |
| `b_mds.R` | `d95ccf2` | 8 Oct 2025 | not ported: a dispatcher that `match.arg()` replaces |

Deliberate departures from these sources are listed in `dev/design/ch06-questions.md`
(Steve's answers, 18 September 2026) and, where they change numbers, in
`inst/DIFFERENCES.md`. The main ones: the similarity-to-dissimilarity conversion
uses the off-diagonal maximum in every routine (borgworld's MDS functions use
the whole-matrix maximum); correspondence analysis computes total inertia from
the full spectrum before truncating to `dim` (borgworld truncates first);
`Gamma` is not reported; the MDS and CA plots use equal axis scaling.
