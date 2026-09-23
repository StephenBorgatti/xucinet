# xucinet — status

Updated 23 Sep 2026 (Claude Code session, then Cowork; Cowork should correct anything here it knows
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
- Chapter 10 (whole-network measures) **complete 23 Sep, issue #13**: `xcohesion`,
  `xreciprocity`, `xtransitivity`, `xcyclicality`, `xcomponents`, `xcentralization`,
  `xhomophily`, `xdensitybygroups`, beside the Phase 0 `xdensity`. `xkeyplayer` is
  dropped (question 10.6) and its crosswalk row removed. **`xcohesion` is
  golden-tested already**: the Density form and Network | Whole-Network Measures both
  call `ucohesion.getcohesion`, so the Phase 0 fixtures `G_CAMPNET_COH`,
  `G_BAKER_COH` and `G_HIGHTECH_COH` cover all 33 measures on all five columns, to
  1.8e-07. The rest wait on `inst/goldens/cohesion/`.
  Two routines are deliberately partial, both for want of a UCINET run:
  `xcentralization` covers degree and betweenness only, and
  `xdensitybygroups(model=)` offers the Density model only. See "Open questions".
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
- Chapters 7, 8, 11, 12, 13, 14 routines not started. About 37 exported functions
  remain against the crosswalk (see `dev/COVERAGE.md`, regenerated 23 Sep: 14 done,
  33 coded with goldens pending, 37 not started, 1 dropped). The merged book text already
  names them; the list of what the text asserts is in `asnr2e/docs/plan.md` ("Decoupling
  decision", requirements list). Remaining coding order: 8, 11, 12, 13, 14, 7.
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

## Done this session (23 Sep 2026, Cowork, after the Claude Code session)

- Steve answered the twelve open questions below; the answers are carried into the files
  listed here. Code changes are listed under "Next" for Claude Code, since this session could
  not run `devtools::check()`.
- **Level-of-analysis rule** (Steve, 23 Sep): SPEC addendum 23 Sep 2026; pointer in
  `dev/CLAUDE.md`. A function is named and placed by the level of its main result; it may
  include short higher-level summaries of that result (centralization, distance
  distribution); it never includes a lower-level table; its slot structure never depends on
  arguments.
- `dev/UCINET-ISSUES.md`: issue 1 scheduled for 6.850; new issues 21 (homophily "Treat data
  as"), 22 (Mixing Tables `getattr`, row dimension), 23 (Normalize, Correspondence under
  Matrix does nothing), 24 (headless batch driver, scheduled for 6.850).
- `inst/DIFFERENCES.md`: entry 1 notes 6.850; new entry 22 (no node-level clustering
  coefficient).
- `dev/design/remaining-chapters-questions.md`: 5.1(ii) reference to "entry 1" explained;
  10.2 corrected from the source; 10.5 updated.
- `asnr2e/crosswalk/crosswalk.py`: the six chapter 5 signatures, `xnormalize` gains
  `"correspondence"`, `xtransitivity` signature and decision, `xcentralization` decision,
  `xkeyplayer` row removed, `xmixing` row added. `ASNR2e_routine_crosswalk_v1.xlsx` rebuilt
  with `build_xlsx.py` (it had not been rebuilt since the 8 Sep chapter 6 edits; the rebuild
  changes nothing else). `data-raw/make-crosswalk.R` now reads it from `C:/Dev/asnr2e`.
- Question 6 answered from the source: Correspondence is method 8 in `Xstdize.pas` (the unit
  the Normalize menu runs), not in `uNormalize.pas`. It is x(i,j)/sqrt(R_i*C_j) with R and C
  the row and column totals of the input, which is `handlemarginals` in `Xcorresp.pas` with
  `keepfirst` (the grand total cancels). Not the same as SQRT-Marginal, so it is to be added.
  Reading the same unit showed two faults in `xnormalize()`; see "Next", item 0(c).

## Done earlier on 23 Sep 2026 (Claude Code)

- **Chapter 10 complete (issue #13).** `xcohesion`, `xreciprocity`, `xtransitivity`,
  `xcyclicality`, `xcomponents`, `xcentralization`, `xhomophily`, `xdensitybygroups`.
  `xcohesion` is golden-tested already against the Phase 0 density fixtures, all 33
  measures on all five columns; the rest await `inst/goldens/cohesion/`.
- Read out of the source rather than assumed: `Components` in the cohesion block is
  Tarjan, so strong; `Connectedness` is pair reachability and unrelated to it; the
  K-core index and `Deg Centralization` are computed after symmetrizing (`//must be
  last`) and so ignore `directed`; and their denominator is (n-1)(n-2) where the other
  two centralizations use (n-1)^2.
- Ledger entry 16 (reciprocity and valued data); `dev/UCINET-ISSUES.md` issue 16 (the
  node-level clustering coefficient, per question 10.2).
- `xkeyplayer` dropped and its crosswalk row removed (question 10.6).

(22 Sep 2026, Claude Code:)

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

0. **Claude Code, before the next chapter: carry out Steve's 23 Sep answers.** Run
   `devtools::check()` after these, as usual.
   (a) `xhclust()`: stop printing the Partition indicator matrix; keep it in the object
       (question 1). Update the snapshot.
   (b) `xdichotomize()`: accept `elsevalue =` as a synonym for `otherwise =`; stop if both
       are given (question 4).
   (c) `xnormalize()` (question 6; `Xstdize.pas`, `runrowcols` and `runnormalize`):
       - add `method = "correspondence"`: x(i,j)/sqrt(R_i*C_j), R and C the row and column
         totals over valid cells (diagonal included only if `diagonal = TRUE`), computed once
         from the input; cells whose R_i or C_j is not positive are left alone; same result
         for every `by`. UCINET returns the input unchanged under Dimension = Matrix
         (UCINET-ISSUES 23): ledger entry, "UCINET fix pending".
       - `constant` **replaces** cells with |x| below single precision; it does not add to
         every cell. The dialog label is "Constant to replace zeros with".
       - `by = "both"` with `method = "sum"`: the column target is nr/nc, not 1
         (`ct.cell[i]:= dm*m.nr/m.nc` when `dim = 4`), which is what lets 2-mode data
         converge. Check the other methods' targets against `runrowcols` at the same time.
       - the unit comment at the top of the xnormalize block names `uNormalize.pas`; the
         menu routine is `Xstdize.pas`.
   (d) `xcloseness()` and `xeigenvector()` gain the centralization UCINET reports
       (`xcloseness.pas`, "Network Centralization = "; `uc_EigenvectorCentrality.pas`,
       `getcentralization`, as percentages), and `xcentralization()` covers all four
       measures (question 9). Goldens join the sweep.
   (e) `xmixing()`, new (question 10): UCINET's Network | Mixing Tables
       (`uc_MixingTables.pas`, engine `unetmixingmodels`). Observed, expected, density and
       observed/expected matrices, one set per relation; expected-value model Density
       (default), Configuration, Fixed outdegree; "For undirected networks, treat ties as"
       Directed (default) or the alternative in the .dfm. Ratio missing where expected is 0.
       A group-level routine under the 23 Sep rule. `xdensitybygroups()` is left as it is.
       The fixtures `g10_mix_campnet_exp_config` and `g10_mix_campnet_exp_fixedout` already
       in `inst/goldens/cohesion/make_goldens.txt` cover it; add the density model.
   (f) `xhomophily(weighted = FALSE)`: dichotomize before every measure, not only the mixing
       matrix (question 12, UCINET-ISSUES 21); ledger entry "UCINET fix pending"; the test
       is marked as expected to differ from UCINET.
   (g) Install `igraph`, `sna`, `network` and `tidygraph` on the Windows machine
       (question 8) and run the cross-check tests locally.
   (h) Rerun `data-raw/make-crosswalk.R` to regenerate `inst/extdata/crosswalk-routines.csv`
       from the rebuilt crosswalk; add a signature note for `elsevalue`.
   (i) Audit the exports against the 23 Sep level-of-analysis rule and list any function
       that returns a lower-level table or whose slots depend on arguments.
   (j) "Where things stand" says chapter 8 is not started, but ledger entries 17-21 and
       UCINET-ISSUES 17-20 record chapter 8 routines (issue #14). Bring the section and
       `dev/COVERAGE.md` up to date.
   (k) Book text: `xsimilarities(by =)` is now `mode =` (question 3).
1. Claude Code runs the remaining chapter prompts in order: ch08, ch11, ch12,
   ch13, ch14, ch07 (`asnr2e/docs/prompts/chNN-claude-code-prompts.md`, after
   `prompt-conventions.md`). Each is one session; each ends with `dev/COVERAGE.md`
   regenerated. Chapters 5 (#12) and 10 (#13) are done.
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

- 23 Sep 2026: level-of-analysis rule (SPEC addendum 23 Sep). Answers to the twelve
  questions below, carried into Next 0.

## Open questions for Steve
Steve's answers prefixed with ***

1. The printed `Partition indicator matrix` in `xhclust()` wraps its column labels
   (`1(8)206`) into one-character chunks because the values are single digits; that is
   UCINET's display rule, but UCINET itself does not print this matrix (it saves it). Keep
   printing it, or follow UCINET and leave it in `$nodes` only?
*** follow ucinet and don't print
   → Next 0(a).
2. UCINET items found during Phase 0 (in `dev/UCINET-ISSUES.md`): 2-mode average degree
   divides by ncols; importfullmatrix pads a short file silently; headless batch driver for
   menu routines. Which of these are being fixed in UCINET, and in which version?
*** all to be fixed in 6.850
   → Issue 1 marked scheduled for 6.850; the batch driver added as issue 24. The 2-mode
   average degree was already fixed in 6.849 (UCINET-ISSUES, "Fixed since this list started").
3. **`asnr2e/crosswalk/crosswalk.py` needs six signature edits** (chapter 5, 22 Sep).
   `xdichotomize` gains `then`/`otherwise`/`diagonal` and its `method` values are
   cutoff/density/maxcor; `xsymmetrize` goes from six methods to sixteen plus `missing`;
   `xnormalize` defaults to columns and gains `constant`/`diagonal`/`tolerance`/`maxit`;
   `xgeodesic` replaces `unreachable=NA` with `reciprocal`/`unreachable`/`diagonal`;
   `xrecode` gains `diagonal`/`rows`/`cols`/`relations`; and **`xsimilarities` renames
   `by=` to `mode=`** and goes from four measures to nineteen. The last one touches the
   book text. The package's copy in `inst/extdata/` is already updated.
*** ok
   → Done in `asnr2e/crosswalk/crosswalk.py` 23 Sep (Cowork); xlsx rebuilt. Book text: Next 0(k).
4. **`else` cannot be an R argument name**, so UCINET's "else value" in
   `xdichotomize()` is `otherwise =`. Happy with that, or would `elsevalue =` read
   better to a UCINET user?
*** can we accept both? if not, go with otherwise
   → Both can be accepted: Next 0(b).
5. **`xcombinenodes()` refuses 2-mode data.** UCINET's Block dialog takes a separate
   partition for rows and columns; question 5.6 gives one `attribute` argument, so rather
   than invent a second the function stops and says why. Is 2-mode aggregation wanted?
*** no
   → No change; the refusal stays.
6. **Question 5.3's "full criterion list" for `xnormalize`.** Seven of the dialog's eight
   are implemented; SQRT-Marginal is there as `"sqrtsum"`, but **Correspondence** is not,
   because its formula is not in `uNormalize.pas` and guessing it would be guessing
   numbers. Where does it live, or should it be dropped?
*** i think correspondence may be the same as sqrt-marginal. check the code in ucinet/source/xcorresp.pas, particularly the routine called handlemarginals. if the same as sqrt-marginal then drop correspondence option. If not, add the method in handlemarginals
   → Not the same (see "Done this session"). Next 0(c).
7. **The design file asks for ledger entry 1 to be corrected** (5.1(ii)). It cannot be:
   entry 1 is the truncated DL file, and the entry describing the dichotomize diagonal was
   retired when UCINET 6.849 stopped zeroing it, as the lifecycle in `dev/CLAUDE.md`
   requires. Entry **13** is written in its place.
*** need to give me more context
   → Explained to Steve 23 Sep (Cowork): the design file's "entry 1" was the dichotomize-
   diagonal entry removed when 6.849 fixed it; entry 13 is correct. Design file annotated.
8. **`igraph`, `sna`, `network` and `tidygraph` are not installed on the Windows
   machine**, so the cross-check layer the conventions require skips locally (8 tests).
   They are written and run on CI. Worth installing here?
*** please install
   → Next 0(g). (Cowork has no shell on the machine.)
9. **`xcentralization()` covers degree and betweenness only.** UCINET reports a
   closeness centralization (`xcloseness.pas`, "Network Centralization = ") and an
   eigenvector one (`uc_EigenvectorCentrality.pas`, `getcentralization`), but
   `xcloseness()` and `xeigenvector()` carry neither, and `log_menu.txt` captured the
   degree figure only. Question 10.5 says this function must not compute anything of
   its own, so the two wait on a UCINET run that records them. That is a chapter 9
   gap rather than a chapter 10 one.
** xcentralization should cover closeness and betweenness as well
   → Steve confirmed 23 Sep: closeness and eigenvector. Next 0(d).
10. **`xdensitybygroups(model=)` offers the Density model only.** UCINET's Mixing
   Tables has three - Density (its default), Configuration, Fixed outdegree. The
   other two are refused rather than guessed; `inst/goldens/cohesion/make_goldens.txt`
   asks for `g10_mix_campnet_exp_config` and `g10_mix_campnet_exp_fixedout`, which
   would let them be written.
*** leave xdensitybygroups alone. Add xmixing to imitate ucinet's mixing tables routine
   → Next 0(e); crosswalk row added.
11. **Question 10.2 described an argument the dialog does not have.** It proposed
   `xtransitivity(type = c("adjacency","weak","strong"))`; Transform | Transitivity
   actually offers Triads / Triplets (Triplets the default) plus a separate
   Adjacency / Strengths / Costs group for the data. The function follows the dialog:
   `method = c("triplets","triads")`. Worth correcting in the design file, which was
   written from memory for chapter 10 - sections 5.1 to 5.7 were rewritten from the
   source on 21 Sep but chapter 10 was not.
*** ok, will correct it
   → Corrected in the design file 23 Sep (Cowork).
12. **`xhomophily(weighted=)` affects only the mixing matrix.** `calcwhomophily`
   takes the raw cell value for the internal and external totals whatever the
   "Treat data as" radio says, and branches on it only when filling `mrs`. So `H`,
   `h-star`, `Corr`, `Yules Q` and `E-I Index` are identical either way. That is
   reproduced, and documented, but it looks like an oversight in UCINET rather than
   a design: the dialog reads as though it should affect everything. Worth a view on
   whether it belongs on the bug list.
*** add to ucinet bug list
   → UCINET-ISSUES 21; xucinet to implement the correct behaviour, Next 0(f).
