# Phase 0 issues — foundations

Each block below is one GitHub issue. Create them in this order (they are numbered so that
later issues can reference earlier ones). "Done when" is the acceptance test.

## 1. Repository setup and CI green on the skeleton

Install R tooling (`devtools`, `roxygen2`, `testthat`, `usethis`), run `devtools::document()`
to regenerate NAMESPACE and man/, run `devtools::check()`, fix whatever the skeleton gets
wrong, push, and confirm the R-CMD-check workflow passes on both Windows and Ubuntu.

Done when: CI badge is green; `devtools::test()` passes the skeleton's tests.

## 2. `xucinet` class: complete the coercers and exporters (SPEC D1)

`as_xucinet()` exists for matrix, data.frame, character, igraph and network. Add:
multi-relation input (3-D array, or named list of matrices → `$data` is a named list);
`as_igraph()`, `as_network()`, `as_tbl_graph()` exporters (Suggests, `requireNamespace`);
`xrelations(net)` to list relation names; `[.xucinet` for subsetting nodes by label or index
that keeps labels and metadata. Round-trip tests: matrix → xucinet → igraph → xucinet.

Done when: tests in `test-class.R` cover every input type and both directions.

## 3. Native ##h/##d reader and writer (`xreaducinet`, `xsaveucinet`)

Port from the Delphi reference, which is **`Tools\G2Tools\utucdataset.pas`** (class
`tucdataset`, about 1,400 lines), not `utucifile.pas` (that G3Tools unit is a 90-line helper
for writing unicode labels and dimensions, used only by `Uci.dpr` and `ug3matrix.pas`).
Copy `utucdataset.pas` and the units it depends on for constants and file access
(`ucommon.pas` for `na = 1E37`, `bna = 1E38`; `uufile`/`ufn` for the block reader; `utmat`,
`utstrvec` for the containers it fills) into `inst/reference/delphi/` so the port can cite
line numbers.

What the unit shows, and what the port must cover:
- Six header versions are readable: 4010 (10-char fixed ASCII labels), 4020 (20-char fixed
  ASCII labels), 5000 (variable-length ASCII labels, header starts with a date), 6000
  (variable-length Unicode labels), 6404 (starts with "V6404"; Unicode labels; integer
  dimensions) and 6405 (starts with "V6405"; final byte records `istable`). `loadhdr()`
  dispatches on the header; the reader must accept all six, since old datasets circulate.
- The writer uses 6404 when needed and 6000 otherwise (`savehdr`, around line 1097); write
  the same, so UCINET reads xucinet files without a version bump.
- The `##d` file begins with a data-type byte (`infile.dt`) that says how cells are stored;
  read it rather than assuming float.
- Missing values: cells >= 1E37 (`na`) map to `NA` on read; `NA` writes as 1E38 (`bna`).
- Labels, multi-relation stacks (`nm` matrices), 2-mode, and the DSL variants
  (`savedsl`/`savehdrdsl`) that the Data Editor uses.

Wire into `xread(filetype="ucinet")` and `xsave(filetype="ucinet")`.

Done when: every dataset in `3e/data/DataUCINET` reads without error and, written back and
re-read, is identical; at least one file written by xucinet opens in UCINET itself (manual
check, recorded in the issue); one fixture of each header version (4010 through 6405) is in
`inst/goldens/` and round-trips.

## 4. `.uci` JSON format: schema draft, reader, writer

Draft the schema (matrix payload dense or sparse edge list, labels, mode, directedness,
relation names, node attributes, schema version, provenance) as `inst/schema/uci-1.0.json`
with a worked example. Implement with `jsonlite`. `xsave()` writes `.uci` by default.

Done when: round-trip test passes for 1-mode, 2-mode and multi-relation datasets; schema
document reviewed by Steve for the UCINET side.

## 5. DL, VNA, Excel and edge-list import; DL and VNA export

`xread()` currently handles csv/xlsx. Add DL (all format families the UCINET importer handles:
fullmatrix, nodelist1/2, edgelist1/2, with and without labels, multiple matrices) and VNA.
Layout detection (`matrix` / `edgelist` / `nodelist`) must be tested on the csv files in
`3e/data/csv files`, including the Excel files with several sheets.

Done when: every file in `3e/data/csv files` and `R edition/Datasets as csv` imports with the
right layout without an explicit `layout=` argument, and the ones that cannot be detected
are listed in the issue with the reason.

## 6. Output class and UCINET-style report renderer (SPEC D5)

`new_xucinet_output()` and `print.xucinet_output()` exist as a first cut. Finish: aligned
numeric columns with 3-decimal display and full-precision storage; descriptive-statistics
block for node tables (mean, sd, sum, min, max, as UCINET prints); one titled section per
relation for multi-relation input; `summary()` and `as.data.frame()` methods; optional `sort=`
argument for display. Compare the printed `xdensity()` report side by side with UCINET's log
for the same dataset and make the format match line for line where feasible.

Done when: a snapshot test (`expect_snapshot`) of `xdensity(campnet)` output is committed and
Steve has compared it with UCINET's log.

## 7. Golden-fixture harness with `xdensity` as the pilot

Write `inst/goldens/make_goldens.txt` (UCINET CLI batch) that runs Density on campnet,
hightech (all three relations), davis (2-mode) and a valued dataset, and saves the outputs.
Write the test helper that parses a golden file's numeric block. Add `test-goldens.R` that
compares `xdensity()` results to the fixtures to 1e-6.

Done when: `xdensity` passes against all fixtures; the harness is documented in
`inst/goldens/README.md` so every later routine can reuse it in ten lines.

## 8. Ship the classic datasets

`data-raw/` scripts that build `data/*.rda` from the book's csv files: campnet, camp92,
hightech (+ attributes), davis, wiring, sampson, zachary, padgett, cities, doctorates,
kaptail, eies, knecht, pv504, pv960, polarstation, newfrat, plus the four Everett social-media
datasets. Names lowercase per the crosswalk Datasets sheet. Each dataset documented in
`R/data.R` with source citation and the book sections that use it. Filename-as-net
convenience: `xdensity("campnet")` loads the shipped dataset if no such file exists.

Done when: `data(package = "xucinet")` lists them all; each has a help page; the crosswalk
Datasets sheet is updated with the final names.

## 9. 1e alias layer

`R/aliases-1e.R`: one deprecated wrapper per ASNR 1e function name (all spellings the 1e
used — see the crosswalk README sheet), calling the 2.0 function with the right arguments
or extracting the right field, and emitting a one-line `message()` naming the new function.
Excluded from the pkgdown reference index.

Done when: every 1e name in the crosswalk's "xUCINET 0.x name" column resolves to a function;
a test loops over them and checks that each is a function that calls a 2.0 export.

## 10. pkgdown site, `xhelp()` and the vignette stubs

`_pkgdown.yml` with reference grouped by UCINET menu (Data, Transform, Network|Centrality, ...).
`xhelp("degree")`: fuzzy match over function names, UCINET menu paths and plain-English
aliases, printing the matches with their one-line descriptions. Stub vignettes: getting
started for UCINET users; UCINET menu → xucinet crosswalk; differences ledger.

Done when: pkgdown deploys from CI to GitHub Pages; `xhelp("centrality")` lists the centrality
functions.

## Exit criterion for Phase 0 (from PLAN.md)

`xdensity(xread("campnet"))` prints a report matching UCINET's, and a dataset written by
`xsave(net, "x.##h")` opens in UCINET. Then the chapter 9 pilot begins (Phase 1 centrality
routines, chapter generator script, Word edit).
