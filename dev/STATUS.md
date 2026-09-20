# xucinet — status

Updated 18 Sep 2026 (Cowork session; Claude Code should correct anything here it knows
better). Overwrite the first three sections each session; append to the last two.

## Where things stand

- Version 2.0.0.9000. Phase 0 complete (class, coercers, print, IO for csv/xlsx/##h/uci/
  dl/vna, 39 datasets, 1e aliases, pkgdown site, CI on Windows and Ubuntu).
- Chapter 9 (centrality) complete: xdegree, xbetweenness, xcloseness, xeigenvector, xbeta,
  xpncentrality, xcentrality, xreach, xbetareach, xhubsauthorities, xinduced; goldens in
  `inst/goldens/centrality/`.
- Chapter 10: xdensity only (Phase 0 pilot). xcohesion, xcomponents, xreciprocity,
  xtransitivity, xcentralization, xdensitybygroups, xhomophily not started.
- Chapter 6: **written 18 Sep in a Cowork session, committed by Claude Code 20 Sep.**
  `xmds` (classical, nonmetric), `xshepard`, `xcorrespondence`, `xhclust` in `R/`, with
  `R/proximity-internals.R` (coercion, `type=` error, conversion, `plot_coords()`),
  `format_uci_dendrogram()` in `R/output.R`, borgworld sources vendored in
  `inst/reference/borgworld/`, borgworld fixtures in `tests/testthat/fixtures/`
  (`data-raw/make-ch06-fixtures.R`), tests in `test-xmds.R`, `test-xcorrespondence.R`,
  `test-xhclust.R`, `test-helper-ch06.R`. Steve's design answers are at the top of
  `dev/design/ch06-questions.md`; SPEC addendum 18 Sep; ledger entries 6–12; NEWS.md.
  `devtools::check()` was run in the Cowork cloud (see "Done this session") and again on
  the Windows machine 20 Sep: 0 errors, 0 warnings, 1 NOTE (CRAN incoming feasibility,
  new submission). UCINET goldens
  not generated: `inst/goldens/multivariate/` holds a README naming the fixtures the tests
  expect and an exempt `UCINET-VERSION`; the golden tests skip until prompt 2 is run.
- Chapters 5, 7, 8, 11, 12, 13, 14 routines not started. The merged book text already
  names them; the list of what the text asserts is in `asnr2e/docs/plan.md`
  ("Decoupling decision", requirements list).
- Machine: repo cloned to `C:\Dev\xucinet` on the new computer 16 Sep. R toolchain
  working 20 Sep: R 4.6.1, Rtools45 (`C:\rtools45`), devtools 2.5.2 / roxygen2 8.1.0 /
  testthat 3.3.2 / rcmdcheck 1.4.0 in `%LOCALAPPDATA%\R\win-library\4.6`, Pandoc 3.11
  for the vignettes, and TinyTeX for the PDF manual. `devtools::check()` runs normally:
  pkgbuild accepts rtools45 under R 4.6.1, although CRAN publishes no rtools46.
  Two notes for anyone setting this up again. Stock TinyTeX cannot build an R manual
  until `psnfss`, `cm-super` and `makeindex` are added with `tinytex::tlmgr_install()`;
  without them it fails on `\textfont 0 is undefined` in the DESCRIPTION URL.
  And `devtools::check()` passes `--no-manual` itself, so the PDF manual is only
  exercised by a plain `R CMD check --as-cran`.
- `gh` is not installed here, so issues cannot be listed or created from this machine
  and commits made here carry no `Refs #N`.
- UCINET source for porting: `C:\Dev\ucinet\Source` (repo StephenBorgatti/ucinet) and
  `C:\Dev\tools\G2Tools` (repo StephenBorgatti/tools), both on Delphi 13 since 14 Sep. The
  Dropbox copies are stale. See `asnr2e/docs/plan.md`, "UCINET, Tools and NetDraw repositories".

## Done this session (18 Sep 2026, Cowork)

- Steve answered the chapter 6 design questions (recorded at the top of
  `dev/design/ch06-questions.md`): off-diagonal max everywhere; CA input rules as
  recommended with full-spectrum inertia; UCINET's text dendrogram; MOCA keeps Corr,
  Modularity, Silhouette and drops Gamma; configuration plot by default with `xshepard()`.
- Ported the three routines from borgworld (commit 6b0f0df) and wrote their tests; ran
  `devtools::document()`, `devtools::test()` and `devtools::check()` in the cloud.
- Found a bug in borgworld's `bcophenetic()` (indexes a `dist` with `lower.tri()` of its
  matrix form; reports 0.08 for cities where the value is 0.71). The port computes it
  correctly; borgworld needs the fix.
- `MASS`, `graphics`, `grDevices` added to Imports (isoMDS and base plotting); `cluster` to
  Suggests (only for a cross-check test).

## Next

1. Verify the toolchain on the new machine: `devtools::check()` passes, `gh auth status`
   OK, pkgdown builds.
2. Chapter 6: Claude Code reviews the Cowork-written files, runs `devtools::check()` on
   Windows, commits (Refs the chapter 6 issue), then prompt 2 (goldens batch, fixture names
   in `inst/goldens/multivariate/README.md`); Steve runs the batch; then re-run the golden
   tests and fill ledger entry 11(b) with any tie-breaking datasets found. Prompt 3 is
   already done except for the golden comparison.
3. xplot() (SPEC D13) — needed to finish the chapter 7 text merge.
4. Chapter 10 whole-network routines (xcohesion et al.), then 8, 11, 12, 13, 14 in the
   order the book requirements list gives.

## Decisions

- 6 Sep 2026: seven chapter 9 design answers (node table columns follow UCINET headings;
  sort=NULL keeps node order; centralization in $summary; closeness default = UCINET
  dialog default; one section per relation; 2-mode normalization by opposite mode size;
  xcentrality one table with NA + note when undefined). Recorded in SPEC addendum.
- 8 Sep 2026: chapter 6 routines ported from borgworld; type= required; no metric MDS.
- 17 Sep 2026: `dev/STATUS.md` is the hand-off between Claude Code and Cowork sessions;
  issues are the task queue.
- 18 Sep 2026: chapter 6 design answers (SPEC addendum 18 Sep): `x` for proximity input;
  `type`, `dim`, `k`, `method`, `labels` in the D4 vocabulary; off-diagonal max conversion;
  UCINET's text dendrogram; MOCA = Corr, Modularity (UCINET's formula), Silhouette;
  D13 narrowed to network plots; `save=` deferred for all routines.

## Open questions for Steve

1. The printed `Partition indicator matrix` in `xhclust()` wraps its column labels
   (`1(8)206`) into one-character chunks because the values are single digits; that is
   UCINET's display rule, but UCINET itself does not print this matrix (it saves it). Keep
   printing it, or follow UCINET and leave it in `$nodes` only?
2. UCINET items found during Phase 0 (in `dev/UCINET-ISSUES.md`): 2-mode average degree
   divides by ncols; importfullmatrix pads a short file silently; headless batch driver for
   menu routines. Which of these are being fixed in UCINET, and in which version?
