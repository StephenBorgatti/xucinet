# xucinet — status

Updated 22 Sep 2026 (Claude Code session; Cowork should correct anything here it knows
better). Overwrite the first three sections each session; append to the last two.

**Order of work changed 20 Sep 2026: code every remaining routine first, one UCINET goldens
batch at the end.** Design questions for all remaining chapters are batched in
`dev/design/remaining-chapters-questions.md`; the prompt per chapter is in
`asnr2e/docs/prompts/` (read `README.md` and `prompt-conventions.md` there first).

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
- Chapter 5 (data management and transformations) **complete 22 Sep, issue #12**:
  `xtranspose`, `xdichotomize`, `xsymmetrize`, `xnormalize`, `xrecode`, `xgeodesic`,
  `xsimilarities`, `xattributetomatrix`, `xcombinenodes`, `xmatch`, `xjoin`, `xunpack`,
  `xcombine`, `xmultiplex`, `ximpute`, `xreplacemissing`, plus `duplicates =` on
  `xread()`. Projects are dropped (question 5.11); the four 1e project aliases stop with
  an explanation rather than the generic "not written yet". Goldens not generated:
  `inst/goldens/transform/` names the eighteen fixtures the tests expect and carries the
  batch; the golden tests skip until the sweep.
- Chapters 7, 8, 10, 11, 12, 13, 14 routines not started. About 40 exported functions
  remain against the crosswalk (see `dev/COVERAGE.md`, regenerated 22 Sep: 13 done,
  27 coded with goldens pending, 45 not started, 1 dropped). The merged book text already
  names them; the list of what the text asserts is in `asnr2e/docs/plan.md` ("Decoupling
  decision", requirements list). Remaining coding order: 10, 8, 11, 12, 13, 14, 7.
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
- UCINET source for porting: `C:\Dev\ucinet\Source` (repo StephenBorgatti/ucinet) and
  `C:\Dev\tools\G2Tools` (repo StephenBorgatti/tools), both on Delphi 13 since 14 Sep. The
  Dropbox copies are stale. See `asnr2e/docs/plan.md`, "UCINET, Tools and NetDraw repositories".

## Done this session (22 Sep 2026, Claude Code)

- **Chapter 5 complete (issue #12).** Seventeen exports: `xtranspose`, `xdichotomize`,
  `xsymmetrize`, `xnormalize`, `xrecode`, `xgeodesic`, `xsimilarities`,
  `xattributetomatrix`, `xcombinenodes`, `xmatch`, `xjoin`, `xunpack`, `xcombine`,
  `xmultiplex`, `ximpute`, `xreplacemissing`, plus the `duplicates =` option on
  `xread()`/`xfromedgelist()`. All written against the 21 Sep rewrite of the design
  questions, which reads the dialogs out of `C:\Dev\ucinet\Source`; the first draft had
  several defaults wrong and three routines were rebuilt after it landed.
- Two tasks the design file assigned here, both answered from the source. (5.1(ii)) The
  CLI unit and the menu form disagree about the dichotomize diagonal: `udichotomize.pas`
  has five operators and one `diagok` boolean, `uc_Dichotomize.pas` has six operators,
  then/else values and a five-way choice defaulting to the else value. R follows the menu
  form. (5.8) What UCINET fills absent cells with under union is **zero**:
  `tmat.allocsize` is `allocate(..., zfill = true)` and `allocate` calls `zerofill`.
- Ledger entries 13 (dichotomize diagonal), 14 (density and maxcor are not UCINET batch
  routines), 15 (random imputation). `dev/UCINET-ISSUES.md` gains issue 15.
- `dev/COVERAGE.md` and its generator `dev/make-coverage.R`. 86 crosswalk rows: 13 done,
  27 coded with goldens pending, 45 not started, 1 dropped.
- Six signatures updated in `inst/extdata/crosswalk-routines.csv`; the master
  `asnr2e/crosswalk/crosswalk.py` needs the same edits. See "Open questions".

Earlier sessions, kept because they are what this one was built on:

(18 Sep, Cowork: chapter 6 routines ported from borgworld and tested; `bcophenetic()` bug
found in borgworld, still to be fixed there; MASS, graphics, grDevices to Imports.)

(20 Sep, Cowork:)

- Decided to code all remaining routines before generating any more goldens (coauthors
  need to see the package near complete; goldens are Steve's alone and can wait).
- Wrote `dev/design/remaining-chapters-questions.md`: 44 design questions with
  recommendations for chapters 5, 10, 8, 11, 12, 13, 14, 7 plus three cross-cutting ones
  (igraph to Imports; transformations return `xucinet`; attribute lookup and type rule).
  Steve answers the table at the top once.
- Wrote the Claude Code prompts in `asnr2e/docs/prompts/`: `README.md`,
  `prompt-conventions.md` (standing rules: three test layers, golden tests written now with
  `skip_if_no_golden()`, batch lines appended per chapter, `dev/COVERAGE.md` regenerated
  per chapter as the page for coauthors), one file per chapter, `goldens-sweep.md` (the
  single batch at the end, two prompts).

## Next

1. Claude Code runs the remaining chapter prompts in order: ch10, ch08, ch11, ch12,
   ch13, ch14, ch07 (`asnr2e/docs/prompts/chNN-claude-code-prompts.md`, after
   `prompt-conventions.md`). Each is one session; each ends with `dev/COVERAGE.md`
   regenerated. Chapter 5 is done (issue #12).
2. Chapter 6 and chapter 5 golden tests stay skipped; the fixtures named in
   `inst/goldens/multivariate/README.md` and `inst/goldens/transform/README.md` join
   the sweep.
3. Goldens sweep (`asnr2e/docs/prompts/goldens-sweep.md`, prompts A and B) when Steve has
   a free hour with UCINET; `Config/ucinet/reference` bumps then.
4. Then the asnr2e side: generators and practices per chapter (ch09 first, then 6, 5, 10,
   …), and the ch07 merge completion once xplot exists.

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
- 20 Sep 2026: code first, goldens last. All remaining routines are coded chapter by
  chapter (5, 10, 8, 11, 12, 13, 14, 7) with hand-computed, cross-check and skipping
  golden tests; one UCINET batch at the end turns the golden tests on. Design questions
  batched into one document. `dev/COVERAGE.md` (crosswalk row → status) is regenerated
  each chapter as the progress page for coauthors.

## Open questions for Steve

1. The printed `Partition indicator matrix` in `xhclust()` wraps its column labels
   (`1(8)206`) into one-character chunks because the values are single digits; that is
   UCINET's display rule, but UCINET itself does not print this matrix (it saves it). Keep
   printing it, or follow UCINET and leave it in `$nodes` only?
2. UCINET items found during Phase 0 (in `dev/UCINET-ISSUES.md`): 2-mode average degree
   divides by ncols; importfullmatrix pads a short file silently; headless batch driver for
   menu routines. Which of these are being fixed in UCINET, and in which version?
3. **`asnr2e/crosswalk/crosswalk.py` needs six signature edits** (chapter 5, 22 Sep).
   `xdichotomize` gains `then`/`otherwise`/`diagonal` and its `method` values are
   cutoff/density/maxcor; `xsymmetrize` goes from six methods to sixteen plus `missing`;
   `xnormalize` defaults to columns and gains `constant`/`diagonal`/`tolerance`/`maxit`;
   `xgeodesic` replaces `unreachable=NA` with `reciprocal`/`unreachable`/`diagonal`;
   `xrecode` gains `diagonal`/`rows`/`cols`/`relations`; and **`xsimilarities` renames
   `by=` to `mode=`** and goes from four measures to nineteen. The last one touches the
   book text. The package's copy in `inst/extdata/` is already updated.
4. **`else` cannot be an R argument name**, so UCINET's "else value" in
   `xdichotomize()` is `otherwise =`. Happy with that, or would `elsevalue =` read
   better to a UCINET user?
5. **`xcombinenodes()` refuses 2-mode data.** UCINET's Block dialog takes a separate
   partition for rows and columns; question 5.6 gives one `attribute` argument, so rather
   than invent a second the function stops and says why. Is 2-mode aggregation wanted?
6. **Question 5.3's "full criterion list" for `xnormalize`.** Seven of the dialog's eight
   are implemented; SQRT-Marginal is there as `"sqrtsum"`, but **Correspondence** is not,
   because its formula is not in `uNormalize.pas` and guessing it would be guessing
   numbers. Where does it live, or should it be dropped?
7. **The design file asks for ledger entry 1 to be corrected** (5.1(ii)). It cannot be:
   entry 1 is the truncated DL file, and the entry describing the dichotomize diagonal was
   retired when UCINET 6.849 stopped zeroing it, as the lifecycle in `dev/CLAUDE.md`
   requires. Entry **13** is written in its place.
8. **`igraph`, `sna`, `network` and `tidygraph` are not installed on the Windows
   machine**, so the cross-check layer the conventions require skips locally (8 tests).
   They are written and run on CI. Worth installing here?
