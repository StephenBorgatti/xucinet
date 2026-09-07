# Golden fixtures

UCINET's own output, kept so the test suite can prove xucinet returns the same
numbers. Three families live here.

| folder | what it holds |
|---|---|
| `ucinet/` | `##h`/`##d` files in every header version, for the format reader (issue #3). Inputs, not results. |
| `density/` | the Density goldens (issue #7): the four input datasets, the UCINET batch that measures them, and the results it writes. |
| `centrality/` | the chapter 9 goldens: seven input datasets, `make_inputs.R` that writes them, the batch that measures them, and the 42 fixtures plus two logs it produced on 7 September 2026. |

## Regenerating

Each family has a `make_goldens.txt`, a UCINET CLI script. From UCINET's command
line box:

```
->cd <package>\inst\goldens\density
->run make_goldens.txt
```

Commit whatever it writes. Also save the output log next to it as
`make_goldens.log`: the saved datasets carry the numbers, but only the log shows
the printed format, which is what the report renderer is matched against.

Regenerate whenever UCINET changes, and note the build that produced them.

## Why results are datasets, not scraped text

Each measure is assigned to a dataset, so UCINET writes a `##h`/`##d` pair:

```
g_campnet_den = density(campnet)
```

`xreaducinet()` then reads it exactly. Scraping the log would mean parsing text
and rounding everything to the three decimals UCINET displays, which is far
short of the 1e-6 the tests compare at. `parse_golden_log()` is still available
in `tests/testthat/helper-goldens.R` for the log, and for any routine whose CLI
form will not hand back a dataset.

## Adding a routine

Roughly ten lines. Say the routine is `xdegree`:

1. Make `inst/goldens/degree/`, and copy in the input `##h`/`##d` datasets it
   should be measured on.
2. Write `make_goldens.txt` there, assigning each result to a dataset whose name
   starts `g_`:
   ```
   dec 8
   g_campnet_deg = degree(campnet)
   dsp g_campnet_deg
   ```
3. In `tests/testthat/test-goldens.R`:
   ```r
   test_that("degree of campnet matches UCINET", {
     skip_if_no_golden("g_campnet_deg", "degree")
     expect_equal(xdegree(campnet)$nodes$Degree,
                  as.vector(golden_matrix("g_campnet_deg", "degree")),
                  tolerance = 1e-6)
   })
   ```
4. Run the batch in UCINET, commit the `g_*` files.

`skip_if_no_golden()` means step 3 can be committed before step 4 happens: the
test skips until the fixture exists, so CI stays green in between and turns into
a real comparison the moment the files land.

## Status

`density/` was run in UCINET on 4 September 2026. All nine fixtures were
produced, no line failed, and `tests/testthat/test-goldens.R` compares against
them for real.

## What the run established

`density()` returns two columns, **Density** and **AvgDeg**, one row per matrix
in the stack, row-labelled by relation. `cohesion()` returns 33 whole-network
measures as rows, one column per relation. Neither reports a standard deviation,
so the `Std Dev` in our own report has no golden behind it yet.

It also caught two real bugs in `xdensity()`, both in the 2-mode case, which is
exactly what davis was in the battery for:

- We were excluding a pseudo-diagonal from an 18 x 14 matrix, where cell (i, i)
  is woman i at event i and means nothing. Density came out 0.324 against
  UCINET's 0.353.
- Average degree divides by the number of **columns**. Only 2-mode data tells
  the denominators apart: UCINET reports 89/14 for davis, not 89/18.

Average degree has since been settled the other way: we report both margins for
2-mode data, `Avg Degree (rows)` and `Avg Degree (cols)`, so UCINET's 89/14 is
still there but no longer stands alone (Steve, 6 September 2026; ledger entry 2).

It also settled how dichotomising treats the diagonal. UCINET's `dichot()`
zeroes it; we now do the same for 1-mode data, so `g_baker_bin` reproduces cell
for cell. We do **not** zero it for 2-mode data, where cell (i, i) is row-node i
tied to column-node i and dropping it would delete real ties: 12 of davis's 89
attendances. Both halves are pinned by tests, and the reasoning is in
`inst/DIFFERENCES.md`, which is also where average degree on 2-mode data is
logged.

## The menu routine's report

`density/density_menu_log.txt` is UCINET's output from **Network | Whole
Networks | Density | Density Overall** on campnet, 5 September 2026, UCINET
6.847. It is a different surface from `log_make_goldens.txt`, which is the CLI
session: the CLI's `density()` is a function whose result `dsp` prints as a bare
matrix, while the menu routine prints the titled report our `print()` method
imitates.

`test-goldens.R` compares our printed report against it line for line. Two lines
have no counterpart on our side and are dropped before comparing: UCINET appends
the path of the file it read, and names an output dataset because it was asked
to save one. Our assumptions block is an xucinet addition (SPEC D4/D5) and is
dropped too. Everything else, all fifteen lines, matches exactly.

That log is also what confirmed the standard deviation. UCINET prints 0.381 for
campnet, which is the population form; `stats::sd()` gives 0.382.

## `centrality/`

The chapter 9 battery, run in UCINET 6.849 on 6-7 September 2026. Seven inputs:
campnet (directed), davis (2-mode), sampson (ten relations), baker_journals
(valued), newguinea (Alliance and Opposition, for the negative-tie case), and
two networks built by `make_inputs.R` because the package ships nothing like
them - `g9_disc`, three components of different size and shape, and `g9_iso`, a
seven-node core plus three isolates. Those two are the cases that tell closeness
conventions apart, which is why they were built rather than borrowed.

`make_goldens.txt` there is for **numbers, not layout**, and that division is
worth understanding before adding any chapter 9 routine.

The printed layout is derived from the Delphi instead. Everything a centrality
routine prints comes from two shared places: the `tlogfile` header helpers,
where `putstr` right-pads each label to the single constant `pwidth`, and
`tmat.display` in `utmat.pas`, which is the algorithm `cat_uci_matrix()` in
`R/output.R` reproduces — a six-wide row-index field, `binbywidth` chopping
over-wide column labels into value-width chunks, `pad` (= `lpad`, so the chunks
are right-aligned), per-column widths, then the dashed rule. Those units are
vendored in `inst/reference/delphi/`.

The reason is that a log is one path through a routine that branches. Degree
alone branches on six dialog controls, and reading the source rather than a
sample immediately corrected three things: the headings are `Degree` / `Outdeg`
/ `Indeg` with an `n` prefix for the normalized pass, not `NrmDegree`, and there
is no `Share` column; graph centralization is a second titled matrix at four
decimals, a proportion and not a percentage; and both the raw and the normalized
columns are optional, so a four-column table is the default tick state rather
than a fixed shape. That last one is ledger entry 5.

PART B is therefore four menu runs, not a checklist. One of them, Degree on
campnet, exists purely to confirm that the source tree matches the installed
binary; the other three are the dialog-only measurements we need numbers for
now. Only six of the thirteen routines exist as command-language functions —
closeness, reach, beta reach, hubs and authorities, induced, 2-mode centrality
and reach betweenness have no keyword in `Xdpfunc.pas` and their run procedures
take no parser argument — so the rest of the dialog-only numbers will be
collected when their routines are written.

### What the centrality run established

**The source is the binary.** PART B run 1 reproduced the layout predicted from
`uc_DegreeCentrality.pas` exactly: the title, all nine header lines, the
`Degree Measures` table headed `Outdeg` / `Indeg` / `nOutdeg` / `nIndeg`, and
the `Graph Centralization -- as proportion, not percentage` matrix at four
decimals. So the remaining chapter 9 routines can be written from the Delphi,
and UCINET is needed only for numbers.

**Closeness is settled.** The dialog prints the options it used, so nothing had
to be inferred. All three measures — Freeman, Valente-Forman, reciprocal —
reproduce from the geodesics in `G9_GEO_DISC` under the printed defaults. The
formulas and headings are in the chapter 9 addendum of `dev/SPEC.md`.

**`mcent()` exists in 6.849**, with `undef:n|max1|zero|avg`, and the four
`G9_MC_DISC_*` fixtures are the raw distance sums under each convention. That
is an independent check on closeness that does not go through the dialog.

**Two UCINET behaviours changed under us**, both caught by regenerating the
density goldens on the same day: `dichot()` no longer zeroes the diagonal, and
2-mode average degree is now ties over the nodes of both modes. Ledger entries 1
and 2. Anything measured against an older UCINET needs re-checking.

Four smaller things went into `dev/UCINET-ISSUES.md` rather than being copied:
negative eigenvector values from 2-Mode Centrality, `eigenvec()` ignoring its
assigned output name for asymmetric input, the CLI and menu disagreeing about
what `degree` returns, and centralization not being computed when raw totals are
unticked.
