# xucinet — status

Updated 23 Sep 2026 (Claude Code, after the Cowork session of the same day; Cowork should
correct anything here it knows better). Overwrite the first three sections each session;
append to the last two.

**Order of work changed 20 Sep 2026: code every remaining routine first, one UCINET goldens
batch at the end.** Design questions for all remaining chapters are batched in
`dev/design/remaining-chapters-questions.md`; the prompt per chapter is in
`asnr2e/docs/prompts/` (read `README.md` and `prompt-conventions.md` there first).

## Where things stand

- Version 2.0.0.9000. Phase 0 complete (class, coercers, print, IO for csv/xlsx/##h/uci/
  dl/vna, 39 datasets, 1e aliases, pkgdown site, CI on Windows and Ubuntu).
- Chapter 9 (centrality) complete: xdegree, xbetweenness, xcloseness, xeigenvector, xbeta,
  xpncentrality, xcentrality, xreach, xbetareach, xhubsauthorities, xinduced; goldens in
  `inst/goldens/centrality/`. `xeigenvector()` reports the eigenvector centralization
  since 23 Sep (no golden holds that figure yet).
- Chapter 10 (whole-network measures) complete 23 Sep, issue #13: `xcohesion`,
  `xreciprocity`, `xtransitivity`, `xcyclicality`, `xcomponents`, `xcentralization`,
  `xhomophily`, `xdensitybygroups`, beside the Phase 0 `xdensity`; plus `xmixing`
  (23 Sep, #16). `xdensitybygroups()` returns the density table only; `xmixing()` returns
  the observed table and the expected table and ratio under all three models (ledger
  26). `xcentralization()` covers degree, betweenness and eigenvector; closeness waits on
  open question 1. `xcohesion` is golden-tested against the Phase 0 fixtures; the rest
  wait on `inst/goldens/cohesion/`.
- Chapter 8 (ego networks) complete 23 Sep, issue #14: `xegonet`, `xstructuralholes`,
  `xtiecomposition`, `xvaluedtiecomposition`, `xaltercomposition`, `xegoaltersimilarity`,
  with shared internals in `R/ego-internals.R`. Goldens named in `inst/goldens/ego/`.
  Issue #15 (`steve`) holds its open items.
- Chapter 6 complete 18/20 Sep: `xmds`, `xshepard`, `xcorrespondence`, `xhclust`; goldens
  named in `inst/goldens/multivariate/`. `xhclust()` no longer prints the partition matrix.
- Chapter 5 complete 22 Sep, issue #12: seventeen transformations; goldens named in
  `inst/goldens/transform/`. `xnormalize()` was brought into line with `Xstdize.pas` on
  23 Sep (#16).
- Steve's 23 Sep answers (the former Next 0, issue #16) are all carried out except the
  closeness centralization (open question 1).
- Chapters 7, 11, 12, 13, 14 not started. `dev/COVERAGE.md` (23 Sep): 14 done, 40 coded
  with goldens pending, 31 not started, 1 dropped. Remaining coding order: 11, 12, 13, 14,
  7.
- `inst/extdata/crosswalk-routines.csv` was regenerated from the rebuilt crosswalk on
  23 Sep, but the chapter 8 rows and the `xmixing` row are kept as the package has them:
  the master `crosswalk.py` still has the pre-chapter-8 signatures (issue #15) and an
  `xmixing` signature with `model =`. Re-running `data-raw/make-crosswalk.R` before the
  master is fixed will revert them.
- Machine: R 4.6.1, Rtools45, devtools/roxygen2/testthat/rcmdcheck, Pandoc, TinyTeX (it
  needs `psnfss`, `cm-super`, `makeindex` for the PDF manual; `devtools::check()` passes
  `--no-manual`). igraph, sna, network and tidygraph installed 23 Sep, so the cross-check
  tests run locally. R is not on the Git Bash PATH: prefix
  `export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"`, and put `Rscript -e` code
  containing `|` in a file, because the shell hands it to cmd.exe. No Python.
- UCINET source for porting: `C:\Dev\ucinet\Source` and `C:\Dev\tools` (Delphi 13). The
  Dropbox copies are stale.

## Done this session (23 Sep 2026, Claude Code)

- **Chapter 8 (issue #14)**, then **Steve's 23 Sep answers (issue #16)**:
  (a) `xhclust()` keeps the partition matrix in `$nodes` without printing it (new
  `print_nodes` field of `new_xucinet_output()`); (b) `xdichotomize(elsevalue =)`;
  (c) `xnormalize()` follows `Xstdize.pas`, see Decisions; (d) eigenvector centralization
  in `xeigenvector()` and `xcentralization()`; (e) `xmixing()` new and `xdensitybygroups()`
  reduced to the density table, as revised by Steve; (f) `xhomophily(weighted = FALSE)`
  dichotomizes every measure; (g) cross-check packages installed; (h) crosswalk CSV
  regenerated (see "Where things stand"); (i) audit, open question 2; (j) this section;
  (k) T3 in `asnr2e/docs/text-changes.md` records the `xmixing()` decision.
- Ledger entries 23 (Correspondence and SQRT-Marginal under Matrix), 24 (homophily binary
  treatment), 25 (mixing tables skip missing cells), 26 (Mixing Tables split in two).
  UCINET issue 25 (Mixing Tables sums missing cells as 1e38); issue 23 extended to
  SQRT-Marginal.
- Units vendored: `Xstdize.pas`, `uc_MixingTables`, `unetmixingmodels.pas`,
  `uc_EigenvectorCentrality`.
- asnr2e: `docs/text-changes.md` committed locally (135b202), not pushed, because the
  asnr2e branch also carries two earlier unpushed commits that are not this session's.
  Cowork's later rewording of T3 is uncommitted there.

## Done earlier on 23 Sep 2026 (Cowork)

- Steve answered the twelve open questions; the answers are under "Decisions".
  Level-of-analysis rule (SPEC addendum 23 Sep). UCINET issues 21-24; ledger entry 22;
  design file corrections for 5.1(ii), 10.2, 10.5, 10.6. `crosswalk.py` updated for
  chapters 5, 6 and 10 and the xlsx rebuilt. Correspondence located in `Xstdize.pas`.

(23 Sep, Claude Code, first session: chapter 10, issue #13. 22 Sep, Claude Code: chapter 5,
issue #12.)

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

1. Claude Code runs the remaining chapter prompts in order: ch11, ch12, ch13, ch14, ch07
   (`asnr2e/docs/prompts/chNN-claude-code-prompts.md`, after `prompt-conventions.md`).
   Each is one session and ends with `dev/COVERAGE.md` regenerated. Chapter 11 needs G1
   (igraph to Imports), blank in the answers table, so as recommended.
2. Golden tests for chapters 5, 6, 8 and 10 stay skipped; the fixtures named in
   `inst/goldens/{transform,multivariate,ego,cohesion}/README.md` join the sweep.
3. Goldens sweep (`asnr2e/docs/prompts/goldens-sweep.md`) when Steve has a free hour with
   UCINET; `Config/ucinet/reference` bumps then.
4. Then the asnr2e side: generators and practices per chapter, and the ch07 merge
   completion once xplot exists.

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
- 23 Sep 2026: level-of-analysis rule (SPEC addendum 23 Sep).
- 23 Sep 2026: Steve's answers to the twelve open questions of 22-23 Sep, all carried
  out (issue #16) except the closeness half of 9: xhclust does not print the partition
  matrix; UCINET items 1 and 24 scheduled for 6.850; crosswalk chapter 5 edits done;
  `elsevalue =` accepted beside `otherwise =`; `xcombinenodes()` keeps refusing 2-mode;
  Correspondence added to `xnormalize()` (it is not SQRT-Marginal); ledger 13 stands;
  cross-check packages installed; eigenvector centralization added; `xdensitybygroups()`
  density only and `xmixing()` with all three models (Steve's revised wording of 0(e));
  10.2 corrected in the design file; homophily binary treatment is UCINET issue 21.
- 23 Sep 2026 (Claude Code, from `Xstdize.pas` rather than the task list): `xnormalize()`
  follows the menu unit throughout, not only where item 0(c) listed. `"mean"` subtracts
  the mean (its target is 0) instead of dividing by it; a row or column whose divisor is
  not positive comes back missing, as `adjust` makes it; `diagonal = FALSE` leaves the
  diagonal missing in the result; `by = "both"` starts with a column pass and stops when
  every margin is within tolerance of its target. The earlier behaviour came from citing
  `uNormalize.pas` and was not a decision.
- 23 Sep 2026 (Claude Code, chapter 8, answers G3 and 8.1-8.4 as recommended): one
  `direction` argument for the chapter; `xegonet` follows the dialog (no `include_ego`,
  no `directed`); ego routines report the first relation (ledger 21) except
  `xtiecomposition`; text attributes appear in a node table by category number; the
  continuous alter-composition SD filters are not offered, since UCINET's do nothing.

## Open questions for Steve

1. **Closeness centralization.** Steve asked for `xcloseness()` to carry the
   centralization UCINET reports. Only the menu item *Closeness (legacy)*
   (`xcloseness.pas`, "Network Centralization = ") prints one; the current Closeness
   dialog that `xcloseness()` follows (`uc_ClosenessMeasures.pas`) prints none. Carry the
   legacy figure over (with a ledger entry saying the current dialog does not print it),
   or leave closeness without one? Until then `xcentralization(measure = "closeness")`
   stops and says why.
2. **Level-of-analysis audit (item 0(i)).** Lower-level tables: `xreciprocity()` (a node
   table beside the whole-network ratios), `xhomophily()` (the group mixing matrix beside
   the whole-network measures), `xstructuralholes()` (dyadic matrices beside the node
   table; SPEC D5 lists these as part of its output, so the rule and D5 disagree here).
   Slots or columns that depend on an argument: `xstructuralholes(method)`, `xhclust(k)`
   (adds `Cluster`), `xreciprocity(method)`, `xtransitivity(method)`,
   `xegoaltersimilarity(method)` (one column per chosen measure),
   `xcentralization(measure)`. Input-driven and probably fine: `xaltercomposition` and
   `xegoaltersimilarity` by attribute type, `xtiecomposition` by relations,
   `xmds`/`xcorrespondence` by `dim`. Which should change?
3. **Chapter 8 items (issue #15):** the six chapter 8 signatures in `crosswalk.py`
   (`xegonet` has neither `directed` nor `include_ego`); whether `direction` is the right
   argument name; which of UCINET bugs 17-20 will be fixed. `crosswalk.py` also needs the
   `xmixing` signature without `model =`: `xmixing(net, attribute, relation = NULL,
   directed = TRUE, data = NULL)`.
