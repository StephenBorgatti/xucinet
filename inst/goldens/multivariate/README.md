# Chapter 6 goldens (not yet generated)

The chapter 6 routines were written on 18 September 2026 before the UCINET batch
existed (prompt 2 of `asnr2e/docs/prompts/ch06-claude-code-prompts.md`). The tests in
`tests/testthat/test-xhclust.R`, `test-xmds.R` and `test-xcorrespondence.R` already
name the fixtures they expect, so the batch has to produce these datasets:

| fixture | routine | input | options |
|---|---|---|---|
| `g6_hc_cities_single` | `hiclus()` CLI, or menu Johnson's | `cities` | dissimilarities, single link |
| `g6_hc_cities_complete` | same | `cities` | dissimilarities, complete link |
| `g6_hc_cities_average` | same | `cities` | dissimilarities, weighted (size-weighted) average |
| `g6_hc_campnet_average` | same | `campnet` symmetrized by average | similarities, average; the tie case |
| `g6_ca_doctorates_r`, `g6_ca_doctorates_c`, `g6_ca_doctorates_e` | Correspondence Analysis (menu) | `doctorates` | Coordinates scaling; row scores, column scores, singular values |
| `g6_ca_davis_r`, `g6_ca_davis_c`, `g6_ca_davis_e` | same | `davis` | same |
| `g6_nmds_cities` | Non-metric MDS (menu) | `cities` | dissimilarities, 2 dimensions, defaults |
| `g6_nmds_cities_stress` | the stress value, if UCINET will save it; otherwise the log line | | |

The partition fixtures are read as they stand: level and cluster count come from
the column labels (`<j>(<k>)<level>` from the menu, `L(<k>)<level>` from the CLI;
the tests parse the trailing number as the level either way) and partitions are
compared as set partitions, so cluster numbering does not matter.

Record every dialog option as a comment in `make_goldens.txt`, save the log beside
it, and set `UCINET:` in `UCINET-VERSION` to the build used.
