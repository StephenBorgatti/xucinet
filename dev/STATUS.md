# xucinet — status

Updated 27 Oct 2026 (Claude Code; Cowork should
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
  26). `xcentralization()` returns all four centralizations (degree, betweenness,
  closeness, eigenvector). `xcohesion` is golden-tested against the Phase 0 fixtures;
  the rest wait on `inst/goldens/cohesion/`.
- Chapter 8 (ego networks) complete 23 Sep, issue #14: `xegonet`, `xstructuralholes`,
  `xtiecomposition`, `xvaluedtiecomposition`, `xaltercomposition`, `xegoaltersimilarity`,
  with shared internals in `R/ego-internals.R`. Goldens named in `inst/goldens/ego/`.
  Issue #15 (`steve`) holds its open items.
- Chapter 6 complete 18/20 Sep: `xmds`, `xshepard`, `xcorrespondence`, `xhclust`; goldens
  named in `inst/goldens/multivariate/`. `xhclust()` no longer prints the partition matrix.
  Since 20 Oct (#40) it reports similarity input's levels as similarities, as UCINET does,
  and `plot()` redraws its dendrogram.
- Chapter 5 complete 22 Sep, issue #12: seventeen transformations; goldens named in
  `inst/goldens/transform/`. `xnormalize()` was brought into line with `Xstdize.pas` on
  23 Sep (#16).
- All of Steve's 23 Sep answers are carried out: issue #16, then (#20, 623240d) the
  level-of-analysis changes and closeness centralization, with `xegoreciprocity()` new.
- Chapter 11 (subgroups) complete 23 Sep, issue #17: `xcliques`, `xfactions`,
  `xgirvannewman`, `xlouvain`, `xfastgreedy`, `xlabelpropagation`, `xcommunities`, with
  shared internals in `R/community-internals.R` (UCINET's modularity, a port of Delphi's
  `Random`, the common Cluster/Modularity output). igraph is in Imports (G1). Cliques,
  factions, Girvan-Newman and Louvain are native ports; fast greedy and label propagation
  run on igraph. `xlouvain()` fixes UCINET issue 26 as Steve decided; on 2-mode data it is
  UCINET's bipartite-modularity Louvain (26 Sep, #18). Goldens named in
  `inst/goldens/subgroups/`.
- Chapter 12 (equivalence) done: `xstructuralequivalence`, `xblockmodel`, `xcoreperiphery`
  (categorical and continuous, and 2-mode categorical), `xrege` (23 Sep, #23), and
  `xblockoptimize` (26 Sep, #24; UCINET issue 35). Goldens named in
  `inst/goldens/equivalence/`.
- Chapter 13 (two-mode) done 24 Sep, issue #26: `xaffiliations`, `xbipartite`,
  `xbicliques`, and 2-mode data in `xdegree`/`xcloseness`/`xbetweenness`/`xeigenvector`
  (`mode =`); 2-mode Louvain (#18) and core/periphery (#25; UCINET issue 34) added 26 Sep.
  Goldens named in `inst/goldens/twomode/`. The 2-mode audit is a comment on issue #26.
- Chapter 14 (testing hypotheses) done 24 Sep, issues #27 and #28: `xcorrelation`,
  `xregression`, `xqap`, `xmrqap`, `xlrqap`, `xdensitybygroups(test = TRUE)` with the three
  ANOVA density models, and `xautoregression` (wrapping `sna::lnam`, Steve). One permutation
  engine for all (`R/permute-internals.R`). Goldens named in `inst/goldens/hypotheses/`.
- Chapter 7 (visualization) done 24 Sep, issue #30: `xplot` and `xlayout`, base graphics
  on igraph layouts, argument names without underscores. No goldens (NetDraw is not the
  oracle).
- **Every routine is coded.** `dev/COVERAGE.md` (26 Sep): 15 done, 69 coded with goldens
  pending, 0 not started, 4 dropped (project bundle, QuickClus, Walktrap, ERGM wrappers per
  D-9). No open questions. What is left is the goldens sweep and the asnr2e side.
- `inst/extdata/crosswalk-routines.csv` and `crosswalk.py` agree (25 Sep): every signature
  in the CSV appears verbatim in `crosswalk.py`, which now has the chapter 11 signatures,
  `elsevalue=` and the full 10.5 row; Walktrap and QuickClus are marked dropped in both.
  The xlsx was rebuilt from it on 25 Sep (asnr2e 7fcc115), so xlsx, `crosswalk.py` and the
  CSV all agree; `data-raw/make-crosswalk.R` can regenerate the CSV without reverting
  anything. Rebuild with `python build_xlsx.py` in `asnr2e/crosswalk`, then copy the xlsx
  over the one in the book's Dropbox folder (`ASN R 2e - Fall 2026/`), which is there only
  for the coauthors and was last refreshed 25 Sep.
- **Notes and .uci 1.1 (2 Oct, #35).** A dataset carries dated notes in `$notes` (data frame
  date/text, absent when none), `xnotes(x)` / `xnotes(x) <- value` (renamed 3 Oct, #36); kept by subsetting, the
  transformations, `xunpack`/`xcombine`/`xmultiplex`; printed as a count. `.uci` is schema
  1.1 (`inst/schema/uci-1.1.json`; 1.0 kept, still read), which adds `notes`. SPEC D1, D6.
- **supremecourt corrected (2 Oct, #35).** Rebuilt from the corrected 3e files (four coding
  errors, Ginsburg, Majority Size / NoTimesMajority); 34 cells of 0.5; carries a note;
  `?supremecourt` documents the cell codes. `make-datasets.R` reads the three Supreme Court
  files from `ASN3 Ucinet Files` only, because `DataUCINET.zip` (searched first) still has
  the old ones. The fixture `inst/goldens/ucinet/supremecourt.##h` keeps the old values (no
  test compares it with the dataset). SDSM backbone unchanged (10 pairs).
- **xsparsify() (3 Oct, #37).** UCINET's Local Sparsification as fixed for 6.850
  (UCINET-ISSUES 45, ucinet #44): each node keeps ceiling(d^e) ties by neighborhood overlap
  (L-Spar) or by tie value, on the symmetrized network. Agrees with the 6.850 dialog runs
  (`C:\Dev\ucinet\Planning\tests\lspar`); 24 golden tests `g5_lspar_*` skip until the sweep,
  with their three inputs (`lsp_barbell`, `lsp_valued`, `lsp_missing`) already in
  `inst/goldens/transform/`. Crosswalk row "5.5.2 (2e)"; book Section 5.5.2 checked (ch05
  `changes.txt`): nothing in it the function does not do.
- **LR-QAP by double semi-partialling (18 Oct, #38).** `xlrqap(method = c("dsp", "yperm"))`,
  default `"dsp"`, as UCINET 6.850's LR-QAP (UCINET-ISSUES 47, ucinet #45); the model's
  significance by Y permutation under both; the fit is Newton-Raphson as UCINET's. Agrees
  with `sna::netlogit(nullhyp = "qapspp")` and with the 6.850 build within Monte Carlo error.
  `xmrqap()` already defaulted to DSP; a netlm cross-check test was added. Ledger 49.
- **LR-QAP failed permuted fits as two p-values (18 Oct, #39, Steve's decision).** `Sig`
  leaves them out, `Sig.Upper` counts them as at least as extreme, in `$summary` and the
  coefficient table (always present, equal when nothing failed); a `Failed` column per term
  (not printed) and `$summary$Failed` for the model's test; the report prints `Sig.Upper` and
  a note after the table only when some fit failed. UCINET 6.850 the same (tools
  `ulrqap.pas`, `uc_lrqap.pas`, CLI `lrqap()`): 54/54 in
  `ucinet/Planning/tests/lrqap/compare_lrqap.out.txt`.
- **Reports: huge values in exponent form (18 Oct, UCINET-ISSUES 48).** `format_values()`
  prints a value of 1e10 or more as `1.631E+31`, as UCINET 6.850's `tmat.display`; whole
  numbers above 2^31 no longer print `NA`.
- **Permutation ties in UCINET (18 Oct, UCINET-ISSUES 49, Steve).** UCINET 6.850's QAP
  correlation, MR-QAP and node-level regression now count values within 1e-6 (1e-10 until
  19 Oct) of the observed statistic as ties, as xucinet does; `ucinet/Planning/tests/ties/` (20/20 against the
  exact p-values of all 720 permutations of a 6-cycle, and against xucinet). It found a bug of
  ours: `xmrqap(method = "dsp")`'s R-square test on symmetric data ran on a random subset of
  the dyads (fitted values stored in one triangle); fixed. UCINET's Y-permutation MRQAP has
  the same flaw (UCINET-ISSUES 50, ledger 41).
- Machine: R 4.6.1, Rtools45, devtools/roxygen2/testthat/rcmdcheck, Pandoc, TinyTeX (it
  needs `psnfss`, `cm-super`, `makeindex` for the PDF manual; `devtools::check()` passes
  `--no-manual`). igraph, sna, network and tidygraph installed 23 Sep, so the cross-check
  tests run locally. R is not on the Git Bash PATH: prefix
  `export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"`, and put `Rscript -e` code
  containing `|` in a file, because the shell hands it to cmd.exe. Python 3.13 (25 Sep, per user, with openpyxl and lxml):
  `$LOCALAPPDATA/Programs/Python/Python313/python.exe`, on the user PATH for new shells.
- UCINET source for porting: `C:\Dev\ucinet\Source` and `C:\Dev\tools` (Delphi 13). The
  Dropbox copies are stale.

## Findings 18 Oct 2026: permutation methods for MRQAP and LR-QAP (#38, Step 1 of asnr2e `docs/prompts/ch14-dsp-default.md`)

- **xucinet.** `xmrqap(method = c("dsp", "yperm"))`, default `"dsp"`. DSP permutes the
  residual of X_k on the other X's (OLS with intercept, over the off-diagonal cells used)
  and compares the classical t = b / SE of that term; `"yperm"` permutes Y and compares the
  coefficients. `xlrqap()` has no method argument: Y permutation only, comparing each
  coefficient's Wald z (labelled T), the model by its log-likelihood (pseudo R-square when
  cells are missing). Both: `nperm`, `seed`, `tails = 2` by default, two-tailed = as extreme
  in absolute value, p = (1 + count) / (1 + nperm) (ledger 40). `xlrqap()` keeps glm.fit's
  result even when it did not converge; only a draw with a constant Y gives no value.
- **UCINET.** MR-QAP is two menu entries, not a method control: Tools > Testing Hypotheses >
  Dyadic (QAP) > MR-QAP Linear Regression > *Double Dekker Semi-Partialling MRQAP* (first,
  Ctrl+R; `uc_QaPDekkerRegression.pas`, tools `G1Tools/umrqapdekker.pas`) and *Original (Y
  permutation) method* (`xmrqapna.pas`). Dekker tracks t (b / SE^2 on the fast path, UCINET
  issue 31), P-values 1- or 2-tailed (default 2), 2-tailed = |t| as extreme; Y-permutation
  compares coefficients. LR-QAP (`uc_lrqap.pas`, tools `G1Tools/ulrqap.pas`) is Y permutation
  only and says so in its caption and log; "Statistics to track" Betas / T-Statistics
  (default T: z = b / SE from the Newton-Raphson information matrix), P-values default
  2-tailed (|z| as extreme), the model's significance from the log-likelihood (pseudo
  R-square with missing data). A permutation whose Newton-Raphson does not converge in 20
  iterations is dropped silently. No method setting is stored anywhere (dialogs keep only
  the session's values, no ini key); neither routine has a CLI command; both are reachable
  from the headless dialog driver (UCINET-ISSUES 24). So the linear case needs no change in
  either program; only LR-QAP does.
- **sna 2.8**, `netlm()` and `netlogit()` (same structure): `"qap"` and `"qapspp"` run the
  *same* branch, so the 3e-errors review is right that the default is semi-partialling. For
  each term i (the intercept included, so its p-value is meaningless) it regresses X_i on
  all other columns (OLS, `qr.resid`, intercept column among them), permutes the residual
  matrix (`rmperm`, rows and columns together), refits the full model with the permuted
  residual in place of X_i, and records t (netlm) or z = b / SE (netlogit; `test.statistic
  = "beta"` gives b). That is DSP as Dekker et al. describe it. `"qapy"` permutes Y against
  the fixed X's; `"qapx"` permutes each X_i alone (cumulatively, without resetting between
  draws); `"qapallx"` permutes every X at once. p-values are proportions of the draws only
  (no +1), `pgreqabs` = |draw| >= |observed|. With one predictor besides the intercept,
  `"qap"`/`"qapspp"` silently becomes `"qapy"`. netlogit keeps glm.fit's result whatever
  its convergence (separated draws count, at the iteration limit).
- **Dekker, Krackhardt and Snijders (2007), 3.2.2**, against the prompt's summary: the same
  procedure (regress X on Z by OLS, permute the residuals, regress Y on the permuted
  residuals and Z, use a pivotal statistic, t). Differences: the paper defines DSP for the
  linear model only; the logistic version (OLS residualizing, logistic refit, z) is an
  extension, justified because replacing X_k by X_k - Z gamma is a reparameterization of the
  logistic model, so the observed b_k, SE_k and z_k are unchanged. The paper's p-value is
  the one-sided proportion "larger than or equal to the observed value"; two-tailed with
  absolute values is our (and UCINET's) convention.

## Done this session (27 Oct 2026, Claude Code, #42, for asnr2e #11)

- Dataset `friendship_abc` (relations NetworkA, NetworkB, NetworkC; nodes a01-a14,
  undirected) and `friendship_abc_attr` (Gender, 1 = male): the Figure 15.1 networks,
  built by `data-raw/make-friendship-abc.R` (not from a UCINET file; the matrices come
  from the 2022 1e practice) and checked against the chapter's counts; `test-data.R`
  tests them. Named in the house style (`<dataset>_attr`). 717a6be.
- `knecht` and `knecht_attr` help pages now say what the codes mean: 9 = missing answer and
  10 = pupil has left (structural zero) in the friendship relations; 0 = missing in
  Ethnicity, Religion and the delinquency scores. Table 15.9 reproduces the 3e table only
  with delinquency 0 set to NA.
- #43 (open): `xplot()` trims edges at the wrong radius with `nodesize` > 1 or under
  `par(mfrow)`; asnr2e's ch15 generator works around it with `par(cex = 1)`.
- Installed xucinet reinstalled from source at 717a6be (has `xleiden()` and the new
  dataset). ergm 4.12.0 and RSiena 1.6.6 installed from CRAN (they were missing).

## Done 23 Oct 2026 (Claude Code, #41)

- `xleiden()` (R/xleiden.R): Leiden community detection (Traag, Waltman & van Eck 2019),
  modularity with `resolution`, seeded with Delphi's Random. Spec shared with UCINET,
  step for step: `dev/design/leiden.md`. UCINET's port (ucinet #46, branch `leiden` in
  ucinet and tools) gives the same partition for every seed tried: 115 of 115 checks in
  `ucinet/Planning/tests/leiden/`. Tests: `test-xleiden.R` (Zachary's optimum 0.4198 for
  every seed, connected communities, no improving single move, igraph's Leiden in
  distribution, snapshot).
- `xcommunities()` has a Leiden column after Louvain (snapshot `subgroups` updated).
- Crosswalk row added (asnr2e #10); `inst/extdata/crosswalk-routines.csv` and
  `dev/COVERAGE.md` regenerated (they also pick up crosswalk edits since 25 Sep: 7.6
  `xplot`, the 10.5 wording, "dropped"). `_pkgdown.yml` lists `xleiden` and
  `plot.xhclust` (missed on 20 Oct). `check()` 0/0/0.
- The installed xucinet is still 3f39661 (no `xleiden()`); the UCINET comparison loads
  the source with `load_all()`.

## Done 20 Oct 2026 (Claude Code, #40)

- `xhclust()` with `type = "similarities"` reports every level as a similarity (Johnson2 with
  `sim = true`, Uclus.pas): the text diagram, the `$nodes` column names, `$levels` and the
  plot axis. Clustering still runs on `max - x`; `$hclust` keeps those heights, and the new
  `$max_similarity` (missing for dissimilarities) converts between them. The "Similarities
  converted to dissimilarities" note is gone from `xhclust()` (still printed by `xmds()`).
  `to_dissimilarity()` returns `mx` and takes `note =`.
- New S3 method `plot.xhclust()` (main, ylab, labels, `...` to `plot.hclust`); `xhclust(plot =
  TRUE)` calls it. For similarities the axis is relabelled `Similarity`, running down from
  the largest value.
- `xrege()` and `xstructuralequivalence()` carry `$max_similarity` beside `$hclust`. The
  diagrams printed by `xrege()`, `xcliques()` and `xbicliques()` now show REGE
  coefficients and co-membership counts (snapshots `xrege`, `subgroups`, `twomode`
  updated).
- Test: single-link levels of the sampson REGE matrix start 0.88377, 0.85295, 0.85003,
  0.80413, and the nine-cluster partition is the one in book 12.7. `check()` 0/0/0.
- Spec split: package part `dev/design/xhclust-similarity-levels.md`; book part
  asnr2e#9 (Figures 12.8 and 13.4 now use `plot()`).

## Done 19 Oct 2026 (Claude Code, Steve's "yes" to the 18 Oct UCINET questions)

- Tie tolerance widened from 1e-10 to 1e-6 (relative) in `perm_summary` and the matching
  test in `test-hypotheses.R` (Steve, 19 Oct); UCINET's `permtol` the same. `check()` 0/0/0;
  `ucinet/Planning/tests/ties` 29/29 and `ties2` 26/26, Moran on the decimal-tie data now
  0.203 against the exact 0.2.

- UCINET side only; no change to `R/`. Ledger: 32, 50, 51 fixed in 6.850; new 52 (UCINET
  MR-QAP Y-permutation expected values and mediation count; fixed), 53 (how UCINET's
  permutation tests count the observed arrangement, and other counting defects; partly fixed,
  questions in `ucinet/STATUS.md`), 54 (UCINET Moran/Geary NaN; fixed); 49 extended to every
  remaining UCINET permutation test, with its limit (ties that exist only in decimal
  arithmetic, in single-precision data). DIFFERENCES 41: 32 and 50 fixed for 6.850.
- xucinet reinstalled in the main R library (Steve: "yes"), at 5a94ab3's code.
- Later: Steve chose xucinet's convention for every UCINET permutation test (UCINET-ISSUES
  53, now fixed in 6.850): nperm permutations, p = (1 + count) / (1 + nperm), summaries of
  the permuted values only. xucinet already does this, so nothing changes here; UCINET 6.850's
  permutation p-values and summaries move toward ours. New entry 55 (UCINET only, open).

## Done 18 Oct 2026 (Claude Code, Steve's answers on the tie rule and LR-QAP's output)

- UCINET-ISSUES 48 (report layout, from Steve's LR-QAP log): `format_values()` exponent form
  from 1e10, and its `formatC(format = "d")` overflow above 2^31 fixed (it printed `NA`; `-0`
  still prints `0`). Test in `test-output.R`. NEWS.
- UCINET-ISSUES 49 (the tie rule, done on the UCINET side), 50 (UCINET Y-permutation MRQAP,
  symmetric data, open) and 51 (two reproducibility bugs in UCINET, open); more evidence on 31.
- `xmrqap(method = "dsp")` R-square test on symmetric data: the fitted matrix is mirrored
  before permuting (it ran on a random subset of the dyads; 6-cycle p 0.045 -> about 1/60).
  Test "symmetric data: the DSP R-square test permutes the whole fitted matrix". Table 14.3
  (hightech, asymmetric) is unaffected. Ledger 41 gains issue 50. NEWS.
  `devtools::check()`: 0 errors, 0 warnings, 0 notes.

## Done earlier on 18 Oct 2026 (Claude Code, #39)

- From asnr2e `docs/prompts/lrqap-failures.md` (Steve's decision on #39). `xlrqap()`:
  `Sig.Upper` beside `Sig` in `$summary` and the coefficient table, `Failed` column per term
  (DSP: its own permutations; yperm: the shared ones), `$summary$Failed` now the model test's
  count (it was the total over every test under DSP); `show_summary`/`show_matrix_columns`
  hide `Sig.Upper` when nothing failed and always hide `Failed`; the note is the report's
  epilogue (helpers `lr_upper()`, `lr_fail_note()`), replacing the "left out" assumption
  line. Tests: both bounds hand-checked on the 5-node case by refitting every draw with
  `lr_fit()` (DSP and yperm, the model's test too), Table 14.4 under both methods with no
  failures (one p column, columns equal, no note), a snapshot of the failure report; the
  hightech snapshot and the pre-#38 Y-permutation p-values are unchanged. Roxygen, NEWS,
  ledger 49 (retitled), UCINET-ISSUES 47 rule 4, goldens README (column layout).
  `devtools::check()`: 0 errors, 0 warnings, 0 notes. COVERAGE not affected (no status change).
- Table 14.4, 5000 permutations by DSP, seeds 1-4: no coefficient test ever failed; the
  model's Y-permutation test failed once in 5000 for seed 2. (UCINET's seed-1 run had one too
  until its Y-permutations were made reproducible later the same day; now it has none.)
- UCINET side and the asnr2e practice prompt in the same session (ucinet STATUS; asnr2e
  `docs/prompts/ch14-table143-practice143.md` 14.3.3).

## Done earlier on 18 Oct 2026 (Claude Code, #38)

- #38, from asnr2e `docs/prompts/ch14-dsp-default.md`: Step 1 findings above ("Findings 18 Oct
  2026"); `xlrqap()` gains `method`, default `"dsp"`, `$summary$Failed`, the `Method:` field;
  helpers `lr_fit()` (Newton-Raphson, UCINET's convergence rule) and `lr_dsp_one()`. Tests:
  glm() at full convergence, DSP default vs `"yperm"` (same slots and observed values),
  `"yperm"` reproduces the pre-#38 p-values exactly (82c9ed3), the reparameterization identity,
  separation counted (5-node case) and a separated observed model an error, missing cells and
  diagonal, and the sna cross-checks (netlogit on Table 14.4's model and a collinear example;
  netlm on Table 14.3's model and a collinear example). Snapshot updated. NEWS, ledger 49,
  UCINET-ISSUES 47, crosswalk row (both copies; xlsx rebuilt in asnr2e, Dropbox copy not
  refreshed), goldens README and batch (`g14_lrqap_hightech` now DSP, `_yperm` added, driver
  lines), COVERAGE regenerated. `devtools::check()`: 0 errors, 0 warnings, 0 notes.
- UCINET side in the same session: tools `G1Tools/ulrqap.pas`, ucinet `uc_lrqap.pas`/`.dfm`,
  CLI `lrqap()`, help, `Planning/6.850-changes.md` (ucinet #45).
- Table 14.3/14.4 by both methods: asnr2e text-changes T34-T37.

## Done 3 Oct 2026 (Claude Code)

- #37 `xsparsify()` (R/xsparsify.R, tests/testthat/test-xsparsify.R), from asnr2e
  `docs/prompts/sparsify.md` block B after block A in ucinet/tools. Help with the SIGMOD 2011
  citation, NEWS, pkgdown Transform group, crosswalk row (both copies; xhelp finds it by
  "sparsify", "sparsification", "lspar"), goldens README and batch. `dev/make-coverage.R`
  now counts only `g*` fixtures, so input datasets in a goldens folder do not mark the family
  generated; COVERAGE regenerated (15 done, 70 coded). UCINET-ISSUES 45 committed and marked
  fixed in 6.850 (0d5b42f).

- #36: `notes()` / `notes<-` renamed `xnotes()` / `xnotes<-` (Steve), no alias; the `$notes`
  element and the `.uci` key keep their name.

## Done 2 Oct 2026 (Claude Code)

- #35 (notes field; Supreme Court corrections), from
  `asnr2e/docs/prompts/supremecourt-corrections.md`: see "Where things stand". Tests in
  `tests/testthat/test-notes.R` and `test-data.R`. Package reinstalled.
- UCINET-ISSUES 37-43 committed (79ace5c), as the ucinet STATUS asked; entry 44 added
  (Datafiles corrected, Datafiles.zip stale, .uci notes; ucinet #43).
- ucinet 779992a: the corrected Datafiles copies committed (Refs ucinet #43).
- Earlier today: #34 (Valente-Foreman); asnr2e #3 (book Tables 9.1-9.5).

## Done 27 Sep 2026 (Claude Code)


- **#32 (55567b1):** `xsimilarities(mode = "matrices")` is `mode = "relations"` (asnr2e T4).
- **#33 (d803db5):** the ANOVA density models and `test = TRUE` moved from
  `xdensitybygroups()` to `xmixing()` (asnr2e T3). `xmixing()` now returns ten tables, the
  last three the models' coefficients, fitted always and printed with `test = TRUE`; a model
  whose dummies are collinear is NA with a note instead of an error. `xdensitybygroups()` is
  the density table only. The shared printer no longer prints the title of a suppressed
  summary block. Crosswalk rows (both copies) and ledger 42 follow.
- **xplot labels (f059ae4):** the plot widens on the right for node labels, which were
  clipped at the edge (found drawing book Figure 13.5).
- Package reinstalled from source, so the asnr2e generators (Figures 7.25-7.26, Matrix 12.3,
  Figures 13.5-13.6, Table 14.4; asnr2e 2d81e23) run on the current code.
- **xplot for print (5ff2129):** `palette = "grey"`, `labelpos = "auto"` (labels placed where
  they collide least) with the window fitted to nodes and labels, a single number for
  `nodesize`/`labelsize` as a multiple of the default, category shapes circle, square,
  triangle, diamond, down-triangle. For the greyscale book figures (Steve, 27 Sep).
- **Relation names ignore case (issue #31; 6966112; asnr2e T23, T24).** `match_relation()`
  in `R/class-xucinet.R`: an exact match first, then case-insensitive; two relations
  differing only in case make such a name an error listing both. Used by
  `pick_relation()` (so every `relation =` and `as.matrix(net, relation =)`), `xunpack()`,
  `xcombine()`, `xrecode()`, `xblockmodel()`, `xrege()`, `xstructuralequivalence()`,
  `xtiecomposition()`, `xplot()`/`xlayout()` and the QAP formulas. Reports print the
  stored name through `relation_label()` (a position used to print as a number). Docs of
  every relation argument and of `xrelations()`; NEWS. T23 and T24 done: the book text
  stands.

## Done earlier on 26 Sep 2026 (Claude Code)


- **Steve's answers on T5, T11, T12, T19** (asnr2e `docs/text-changes.md`), carried out:
  DL nodelists read `alter:value` and `alter:.` (T5; UCINET issue 36 asks UCINET's
  importer for the same; ledger 47); `xlouvain(order = "random", seed = )` (T11; ledger
  48); T12 is a text edit only; Table 14.4 regenerated with `xlrqap()`, 5000
  permutations, seed 1 (T19: p 0.017 and 0.100 where the text has 0.012 and 0.064).

- **Steve's decisions on open questions 4, 6, 7, 8**, recorded in both STATUS files; T9,
  T13, T14 turned into plain text edits. Then:
- **2-mode Louvain (#18, closed).** `xlouvain()` on 2-mode data ports
  `u2modelouvain.pas`: Barber's Q_b, one level of local moving in an order shuffled by
  Delphi's `Random` under `seed`, the blocked matrix (`format_blocked_matrix()` now takes a
  column partition). Tests: Q_b written out, local optimality, two bicliques.
- **2-mode core/periphery (#25, closed).** `xcoreperiphery()` on 2-mode data ports
  `x2mcatcp.pas` and `Ugenetic.pas` (`genetic2`, `greedy`), R's generator under `seed`.
  UCINET issue 34: five defects (a 1-mode diagonal rule in the start and the density
  table, the stopping counter that never moves, the start never scored, an undefined
  correlation scored as the best). Ledger 45. New arguments `popsize`, `stopafter`, `auxit`.
- **`xblockoptimize` (#24, closed).** Structural (binary, valued) and regular optimization,
  ported from `xsbmb.pas`, `xsbmv.pas`, `xrbm.pas` with the G1 `tabus` and `km1`, Delphi's
  generator. UCINET issue 35: five defects (the start's distance, the valued routine never
  using its random starts, the regular moves never reaching the last block, the diagonal
  option not reaching the costs, missing cells read as values). Ledger 46. The regular
  cost is matrix products: lazega at k = 3 takes 13 s.
- Crosswalk signatures for all three in both copies; xlsx rebuilt and the Dropbox copy
  refreshed (asnr2e 19f3d66). COVERAGE: 0 not started.
- **Table 14.4 (#29, closed; 830fa83).** Steve found the model in the 1e practice:
  week 1 top three on week 0's top three, its transpose, and the 2-path count, fitted with
  `sna::netlogit` (semi-partialling). `xlrqap()` reproduces the coefficients (-2.642,
  2.258, 0.829, 0.510) and log likelihood (-100.08); test added. The text says the 2-path
  matrix is 0/1 and the test Y permutation; both are asnr2e T19, open: decision.
- **`xplot(op =)` (17741ab).** The cutoff takes a rule, so Figure 7.18's top three is
  `cutoff = 4, op = "<"`; a zero is never a tie.
- **COVERAGE (d967244).** Dropped rows are matched by topic, so QuickClus and Walktrap no
  longer show a function `drop()`, and the ERGM row is dropped per D-9 instead of a
  not-started `statnet()`.
- asnr2e `STATUS.md` brought up to date (7447008).

## Done 25 Sep 2026 (Claude Code)

- Housekeeping Steve asked for: issue #15 closed (answered 23 Sep); T8 in
  `asnr2e/docs/text-changes.md` turned from `open: decision` into a plain text edit (no
  WPGMA; UCINET's weighted average is `xhclust(method = "average")`); open question 5
  done: the chapter 11 signatures copied into `crosswalk.py`, and the other rows where the
  two copies differed (5.5.1, 8.2, 8.4, 8.5, 8.6.1, 10.5) brought into line with the
  functions' actual arguments.
- asnr2e 174a3bf, at Steve's request: the crosswalk xlsx rebuild through chapter 14 that
  had been sitting uncommitted, and `build_xlsx.py`, which now carries Steve's answers to
  D-1 to D-10 (a new column on the Decisions sheet) so that rebuilds keep them.
- Python 3.13 installed (with openpyxl, lxml), and the xlsx rebuilt from the current
  `crosswalk.py` (asnr2e 7fcc115): chapter 7 rows and the 25 Sep signature sync now in it.

## Done on 24 Sep 2026 (Claude Code)

- **`xautoregression` (issue #28, fb9a231).** Steve chose to wrap `sna::lnam`: lag and
  error models, W row-normalized by default, net first as everywhere. `numDeriv` joins
  Suggests (lnam needs it). Checked against an independent concentrated-likelihood fit.
  Ledger 43; T17 done (the text already says what the package does).
- **Newcomb data (#29).** Steve assigned it to Cowork, but the data already ship as
  `newfrat` (17 nodes, PreferenceT00-T15, week 9 missing). Commented on #29 and corrected
  T16: what is left is naming `newfrat` in the text and the Table 14.4 specification.
- **Chapter 7 (issue #30, ea68649).** `xlayout()`: spring (Fruchterman-Reingold), kk,
  mds and nmds of geodesics (unreachable max + 1), circle, random, groups (by attribute,
  Figure 7.6), bipartite; seeded by default so a call always gives the same picture.
  `xplot()`: attributes by name, vector or node-level result to colour (categories get a
  palette and legend, numbers grey shades), size, shape and label size; valued ties to
  width and darkness; several relations by colour and style with multiplex ties thicker
  (Figure 7.20); `cutoff`, `keep`, `ego`, `isolates = FALSE` (keeps coordinates);
  coordinates matched by label, so a layout serves subsets and later networks; attribute
  columns as a layout draw axes (Figure 7.5); `file =` writes png/jpg/tiff/pdf/svg.
  Tests on coordinates, filtering, mapping and files; every drawing run on a null device.
  Ledger 44. pkgdown group Visualize. Book (asnr2e 3af07b0): crosswalk rows; T18 lists
  what the ch07 merge needs (7.2.3, 7.4.2, 7.5.1, 7.7, and Figure 7.27 is
  `xcorrespondence()`).
- **Chapter 14 (issue #27; 4500f3c).** Node level: `xcorrelation()` and `xregression()`
  (Tools | Testing Hypotheses | Node-level | Regression), permuting y, classical and
  permutation p-values side by side. Dyadic: `xqap()` reports all seven utqapsim measures,
  each with its own test (the book's Padgett numbers, Table 14.2, reproduced); `xmrqap()`
  by Double Dekker semi-partialling (default) or Y permutation, with the robust SE UCINET
  prints (hightech, Table 14.3, reproduced); `xlrqap()`. Mixed: `xdensitybygroups()`
  always fits UCINET's three ANOVA density models (XCatC2.pas); `test = TRUE` adds their
  p-values. UCINET issues 31-33; ledger 40-42. Book (asnr2e 7e83cd3): crosswalk rows,
  T15 (`xqap` has no measure option), T16, T17.
- UCINET-SIDE.md: Cowork's edit of 24 Sep committed (94c4b42).

## Done earlier on 24 Sep 2026 (Claude Code)

- **Chapter 13 (issue #26; 319e535).** `xaffiliations()` (Data | Affiliations, twelve of
  its thirteen methods; UCINET issue 30, covariance not divided by n, ledger 38);
  `xbipartite()` (Transform | Bipartite, `$attributes$mode`); `xbicliques()` (the CLI
  `biclique()`, which is 2-cliques of the bipartite graph through the same Bron-Kerbosch
  as `xcliques`, so UCINET's order; brute-force checked; the book's Figure 13.4
  clustering added, ledger 37). The audit found that the chapter 9 centrality routines
  refused 2-mode data although 13.4 says they take it; they now report 2-Mode
  Centrality's scores with `mode = "both"/"rows"/"cols"`. `ximpute()` refuses 2-mode data,
  as UCINET's imputation does (the prompt expected otherwise). Book: T14 (2-mode
  core/periphery), crosswalk rows for chapter 13 (asnr2e 198d443).
- **SDSM backbone in `xaffiliations()`** (Steve, 24 Sep): `method = "sdsm"`,
  `nullmodel = "logistic"` (UCINET's default) or `"bicm"`, `alpha = 0.05`, ported from
  `usdsm.pas` with its exact Poisson-binomial tail. Checked against `glm()`, the
  `backbone` package's BiCM (to 1e-9) and brute-force enumeration; backbone 3.x itself
  keeps fewer edges because it approximates the tail (ledger 39).

## Done on 23 Sep 2026 (Claude Code)

- **Chapter 12 (issue #23; 144c4fe, 6a77f25).** `xstructuralequivalence()` (Xse.pas,
  ug2sim `sesim2`): every relation stacked, five diagonal treatments, seven measures,
  dialog defaults (Euclidean, Reciprocal1, transpose). The prompt asked to add WPGMA to
  `xhclust()`; UCINET's "weighted average" is size-weighted, i.e. UPGMA, already
  `"average"`, so nothing was added. The book's Sampson numbers (Matrix 12.3) come from
  Reciprocal2, not the default: T13. `xblockmodel()`: the report of Block - Aggregate by
  Partitions (blocked matrix ported from `blockdisplay`, autocorrelation) plus an image
  matrix (ledger 34). `xcoreperiphery()`: categorical (`utcpcat`) and continuous (MINRES,
  concentration) in one function, both always fitted; Baker's journals reproduce Figure
  12.10 and Table 12.2 exactly; UCINET issue 29 (off-diagonal blocks lose cells when a
  density is set), ledger 35. `xrege()` (`sStdrege`), checked against a literal
  translation; UCINET's REGE is 1-mode only and refuses to run in 64-bit builds; ledger 36.
  Units vendored; golden batch `inst/goldens/equivalence/`.
- **Issues #21, #22 (400c341, aa72176).** `xcommunities(net, ...)` as a node-by-method
  membership table; the negative-tie aliases; `xinverseweighteddegree()` (UCINET issue 28,
  ledger 33); `direction` renamed `ties` in the ego routines. The alias generator
  (`data-raw/make-aliases.R`) now supports hand-written wrappers
  (`R/aliases-1e-special.R`).
- asnr2e: everything committed and pushed (crosswalk, prompts, STATUS, plan, CLAUDE.md,
  T12, T13, the chapter 12 and `xcommunities` signatures).
- **Next 0, Steve's later 23 Sep answers (issue #20, 623240d).** Level of analysis:
  `xreciprocity()` whole-network only, its node table the new `xegoreciprocity()` (Steve:
  "add only the Symmetric column" to `xegonet()`, which now has seventeen columns);
  `xhomophily()` without the mixing matrix; `xtransitivity()` both versions (the triad
  ratio renamed `Triad Transitivity`); `xegoaltersimilarity()` every measure;
  `xcentralization()` all four; `xhclust()` always `Cluster`; `xstructuralholes()` eleven
  columns under both models, the whole model printing UCINET's five; `xgirvannewman()`
  every partition, printing up to the first with at least `k` clusters, which is exactly
  what UCINET prints (the snapshot did not change). Report objects gain `show_summary`,
  `show_columns`, `show_matrix_columns`. Closeness centralization ported from
  `xcloseness.pas` into `xcloseness()$summary`. Ledger 31 (closeness centralization), 32
  (level of analysis), 16 updated. Golden batch `inst/goldens/centrality/make_goldens_3.txt`
  (CLI `centralization()`, since the legacy routine has no menu item any more). Book:
  T12 in `asnr2e/docs/text-changes.md` (4dd73fe, local); chapters 6 and 8-11 checked for
  descriptions of the old output and found none.
- **Chapter 8 (issue #14)**, then **Steve's 23 Sep answers (issue #16)**:
  (a) `xhclust()` keeps the partition matrix in `$nodes` without printing it (new
  `print_nodes` field of `new_xucinet_output()`); (b) `xdichotomize(elsevalue =)`;
  (c) `xnormalize()` follows `Xstdize.pas`, see Decisions; (d) eigenvector centralization
  in `xeigenvector()` and `xcentralization()`; (e) `xmixing()` new and `xdensitybygroups()`
  reduced to the density table, as revised by Steve; (f) `xhomophily(weighted = FALSE)`
  dichotomizes every measure; (g) cross-check packages installed; (h) crosswalk CSV
  regenerated (see "Where things stand"); (i) the level-of-analysis audit, since
  answered (Decisions); (j) this section; (k) T3 in `asnr2e/docs/text-changes.md`
  records the `xmixing()` decision.
- **Speed-ups (issue #19, d7f1668):** Girvan-Newman on igraph's edge betweenness,
  incremental scoring in Louvain and factions, factions' starting distances from igraph.
  Same partitions as before (tests keep the old versions as references); on a 200-node
  network 5.4 s, 4.8 s and 11 s became 0.2, 0.06 and 0.4.
- Ledger entries 23 (Correspondence and SQRT-Marginal under Matrix), 24 (homophily binary
  treatment), 25 (mixing tables skip missing cells), 26 (Mixing Tables split in two).
  UCINET issue 25 (Mixing Tables sums missing cells as 1e38); issue 23 extended to
  SQRT-Marginal.
- Units vendored: `Xstdize.pas`, `uc_MixingTables`, `unetmixingmodels.pas`,
  `uc_EigenvectorCentrality`.
- **Chapter 11 (issue #17).** igraph to Imports (a214749, its own commit), then the seven
  routines (067c056). Read from the source: Cliques' default Type is Weak, which is the
  maximum-symmetrize of answer 11.1; the clique order is Bron-Kerbosch version 2's,
  ported step for step; Factions' measures are Hamming, Phi, Modularity and Entailment
  (not the correlation the prompt named) and its randomness is Delphi's LCG, now
  reproducible from the seed; Girvan-Newman removes all tied top edges at once, so it is
  native rather than igraph; UCINET's Louvain is deterministic, and its 2-mode version
  is Barber's bipartite modularity, not dual projection (issue #18); UCINET's FastGreedy
  starts from cliques by default. Ledger entries 27-30; UCINET issue 27 (missing cells
  in factions and Louvain). Report objects gain `hide =` and `epilogue =`.
- asnr2e: `docs/text-changes.md` is committed locally (135b202, then a9f1d25 with T10 and
  T11 for chapter 11 and Cowork's T3/T9 edits), not pushed, because the asnr2e branch
  also carries two earlier unpushed commits that are not this session's.

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

0. #38 and #39 done; their book side is asnr2e T34-T37, the practice prompt
   `docs/prompts/ch14-table143-practice143.md` and `asnr2e/STATUS.md`.
   UCINET side of the Supreme Court corrections: rebuild both `Datafiles.zip` in the ucinet
   repo (ucinet #43).
1. Golden tests for chapters 5, 6, 8, 10, 11, 12, 13 and 14 stay skipped (chapter 7 has none); the fixtures named in
   `inst/goldens/{transform,multivariate,ego,cohesion,subgroups,equivalence,twomode,hypotheses}/README.md` join the
   sweep. The Louvain golden is expected to differ until UCINET issue 26 is fixed.
2. Goldens sweep (`asnr2e/docs/prompts/goldens-sweep.md`) when Steve has a free hour with
   UCINET; `Config/ucinet/reference` bumps then.
3. Then the asnr2e side: generators and practices per chapter, and the ch07 merge
   completion (`tools/merge-edits/edits07.py`, a separate asnr2e prompt; T18 has the facts),
   now that xplot exists.

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
- 23 Sep 2026 (Steve, via Cowork): Louvain is a native port of UCINET's, without its
  move-test and reported-Q bugs (UCINET-ISSUES 26).
- 23 Sep 2026 (Claude Code, chapter 8, answers G3 and 8.1-8.4 as recommended): one
  `direction` argument for the chapter; `xegonet` follows the dialog (no `include_ego`,
  no `directed`); ego routines report the first relation (ledger 21) except
  `xtiecomposition`; text attributes appear in a node table by category number; the
  continuous alter-composition SD filters are not offered, since UCINET's do nothing.
- 23 Sep 2026 (Claude Code, chapter 11, G1 and 11.2-11.5 as recommended, 11.1 as
  answered): igraph in Imports. Where UCINET's routine is deterministic and cheap to port
  (Girvan-Newman, Louvain) it is ported rather than run on igraph, since igraph's
  versions are different algorithms (one-edge-at-a-time removal; randomized order); fast
  greedy and label propagation stay on igraph as the prompt says. `xfactions(method =)`
  offers UCINET's four measures. Every partition routine reports `Modularity` on the same
  matrix (max-symmetrized, diagonal ignored, values kept), so methods compare directly.
  Girvan-Newman's `Cluster` is its partition with the highest modularity. Walktrap and
  QuickClus are dropped.
- 23 Sep 2026 (Steve, via Cowork; former open question 2): the level-of-analysis audit.
  SPEC addendum 23 Sep, items 5 and 6 and "Applications": an argument changes values or
  what is printed, never which slots or columns exist; where it chooses among outputs,
  all are computed and it chooses what is printed. `xhomophily()` drops its mixing
  matrix (it is `xmixing()`'s); `xreciprocity()` drops its node table (node-level
  reciprocity becomes an `xegonet()` column) and always has both ratios;
  `xtransitivity` both versions; `xegoaltersimilarity` every measure; `xcentralization`
  all four in one row; `xhclust` always has `Cluster`; `xstructuralholes` fixed columns
  and a named exception for its dyadic matrices. Input-driven differences stand.
- 23 Sep 2026 (Steve; former open question 6, Cowork's recommendation accepted):
  `xgirvannewman()` returns a partition column for every component count it reaches, and
  `k` sets only what is printed; `xcliques()`'s co-membership matrix is a second named
  exception (SPEC item 6), since the text and the crosswalk use it and UCINET computes,
  saves and clusters it.
- 23 Sep 2026 (Steve; former open question 1): `xcloseness()` carries the closeness
  centralization from UCINET's legacy Closeness routine, checked against
  `runcentralization` in `Xdpmat.pas`, with a ledger entry, since the current Closeness
  dialog prints none.
- 23 Sep 2026 (Steve, issue #19): Girvan-Newman takes edge betweenness from igraph inside
  UCINET's removal loop; Louvain and factions stay native and score moves incrementally.
  All three give the partitions of the straightforward versions, which the tests keep as
  references.
- 23 Sep 2026 (Steve, issue #20): `xegonet()` gains only the Symmetric column of UCINET's
  node-level reciprocity; the full six-column table is a new function,
  `xegoreciprocity()`.
- 23 Sep 2026 (Claude Code, issue #20): the legacy Closeness routine is not reachable from
  any menu in the current source (`Freeman1Click` is not wired in `ucinet.dfm`), so the
  closeness centralization golden comes from the CLI `centralization()`, which divides the
  same sum by a star's; the test suite checks that identity on our side. `xgirvannewman()`
  prints up to and including the first partition with at least `k` clusters, because that
  is where UCINET's loop stops.
- 23 Sep 2026 (Claude Code, issue #23): UCINET's "weighted average" linkage is
  size-weighted (`wtdavgcomp`, UPGMA), so the profile and REGE clusterings use
  `xhclust(method = "average")` and no WPGMA method was added, contrary to the prompt.
- 23 Sep 2026 (Claude Code, issue #23): `xstructuralequivalence()` defaults to UCINET's
  current dialog (Euclidean, Reciprocal1, transpose), design answer 12.1 included; the
  book's Matrix 12.3 is Reciprocal2 (open question 8). The ug2sim measures are ported
  rather than taken from `xsimilarities()`, because the two units differ at the edges.
- 23 Sep 2026 (Claude Code, issue #23): `xblockmodel()` reports the current Block -
  Aggregate by Partitions routine, not the legacy Block, with an added image matrix.
  `xcoreperiphery()` always fits both models (level-of-analysis rule); its random starts
  use the Delphi generator under `seed`, though UCINET itself calls `randomize`.
- 23 Sep 2026 (Claude Code, issue #21): `xcommunities()` has no `method` argument: it
  always runs all five, as Steve's note describes a node-by-method matrix.

- 24 Sep 2026 (Claude Code, issue #26): the single-measure centrality routines take 2-mode
  data by returning UCINET's 2-Mode Centrality scores (`mode` default `"both"`, SPEC D4);
  `xcentrality()` keeps its `"rows"` default, one margin as UCINET's dialog.
  `xbipartite()` is titled `<input>-bi` rather than UCINET's fixed `bi`.

- 24 Sep 2026 (Steve): `xaffiliations()` includes the SDSM backbone, as a 1-mode
  projection like the other methods.

- 24 Sep 2026 (Claude Code, issue #27): every permutation routine uses one convention:
  p = (1 + count)/(1 + nperm), the observed value counted, R's generator under `seed`,
  `tails = 2` testing As Extreme and `tails = 1` the direction of the observed sign;
  UCINET's routines differ among themselves (ledger 40). `xqap()` has no measure argument,
  since UCINET computes and prints all seven. `xdensitybygroups()` always fits the three
  ANOVA density models (level-of-analysis rule); `test` only adds the p-values. The book
  has no t-test or ANOVA example, so there is no `xttest` / `xanova`.


- 24 Sep 2026 (Steve, issue #28): `xautoregression()` wraps `sna::lnam`, since UCINET has no
  routine; ledger 43.

- 24 Sep 2026 (Steve, design 7.2): no underscores in argument names, so `nodecolor`,
  `nodesize`, `nodeshape`, `edgewidth`, `edgecolor` and so on.

- 24 Sep 2026 (Claude Code, issue #30): `xplot()` draws the first relation by default, and
  several with `relation = c(...)`; the layout of a named method is computed on what is
  shown after `cutoff`, `keep` and `ego` but before isolates are dropped, so
  `isolates = FALSE` keeps the others' coordinates (7.5.1). 2-mode data are drawn with the
  spring layout by default rather than the bipartite one the prompt proposed, since two
  lines of nodes hide the structure the chapters discuss; `layout = "bipartite"` is there.
  Numbers with at most six distinct whole values count as categories for colour and shape.

- 26 Sep 2026 (Steve; former open questions 4, 6, 7, 8):
  (4) `xlouvain()` on 2-mode data maximizes bipartite modularity as UCINET's 2-mode Louvain
  does; no dual projection in the package (T9 is a text edit; issue #18).
  (6) `xblockoptimize` is a native port of UCINET's optimization routines, structural and
  regular equivalence (issue #24).
  (7) 2-mode core/periphery ports UCINET's `x2mcatcp.pas` only, no dual projection (T14 is
  a text edit; issue #25).
  (8) Profile similarity keeps the Reciprocal1 default; the text says Matrix 12.3 was
  computed with Reciprocal2 and the practice passes `diagonal = "reciprocal2"` (T13).

- 26 Sep 2026 (Steve; asnr2e T5, T11, T12, T19): valued nodelists are a DL format that
  xucinet reads (and UCINET is to read, issue 36); `xlouvain()` keeps the fixed order and
  offers `order = "random"`; the closeness-centralization exercise leaves Pucci out;
  Table 14.4 keeps the 2-path count and is regenerated with `xlrqap()`.

- 27 Sep 2026 (Steve; asnr2e T23, T24): relation names are matched case-insensitively,
  after an exact match, so the book's `relation = "games"` stands.

- 27 Sep 2026 (Steve; asnr2e T3, T4): the ANOVA density test belongs to `xmixing()`;
  `mode = "matrices"` is accepted beside `"relations"`.

- 2 Oct 2026 (Steve, #35): datasets carry dated notes, in the object and in `.uci`; the
  Supreme Court data are corrected everywhere.
- 2 Oct 2026 (Claude Code, #35): the notes field makes `.uci` schema 1.1, not an amendment
  of 1.0, by the schema's own rule (a minor version adds optional keys; readers refuse only
  an unknown major version). Notes are kept by every transformation built on
  `map_relations()`, including those that change the nodes (projections, `xcombinenodes`,
  `xmatch`), since the notes describe the data they derive from; routines that build a new
  object (`xsimilarities()`, `xattributetomatrix()`, `xbipartite()`) start without them. The accessor is
  `notes()` without the x prefix, as Steve named it.
- 3 Oct 2026 (Steve, #36): the notes accessor follows the x prefix: `xnotes()`, `xnotes<-`;
  no deprecated `notes()`, since nothing has been released.
- 3 Oct 2026 (Steve): the Dropbox datasets (`3e/data/DataUCINET.zip`) are not updated;
  `make-datasets.R` keeps reading the Supreme Court files from `ASN3 Ucinet Files`. Former
  open question 9.
- 3 Oct 2026 (Steve; UCINET-ISSUES 45): `xsparsify()` does exactly what UCINET's fixed Local
  Sparsification does. Implementation details shared with ulspar.pas (Claude Code): neighborhoods
  of the symmetrized network without the diagonal; ceiling(d^e) with a 1e-9 tolerance; ties counted
  as symmetrized pairs; the title is `<name>-lspar`, as UCINET names the output.
- 18 Oct 2026 (Steve's prompt `asnr2e/docs/prompts/ch14-dsp-default.md`; #38; UCINET-ISSUES 47):
  LR-QAP defaults to double semi-partialling in both programs, Y permutation on request; the
  argument and values are `xmrqap()`'s (`method = c("dsp", "yperm")`, not the prompt's `"y"`,
  since the prompt says to match xmrqap). Claude Code's details: the model's significance stays
  a Y-permutation test (its null is that no predictor matters, under which Y is exchangeable);
  the logistic fit is Newton-Raphson from zero, 20 iterations, steps <= 1e-4, with pivoted
  elimination rather than UCINET's SVD pseudo-inverse, which let separated fits pass as
  converged; SE at the final coefficients; failed fits left out and counted (pending #39).
- 18 Oct 2026 (Steve, #39; former open question 1; asnr2e `docs/prompts/lrqap-failures.md`):
  LR-QAP permutations whose fit fails are reported as two bounds in both programs, lower
  p = (1 + count) / (1 + converged), upper p = (1 + count + failed) / (1 + nperm); one p-value
  printed when nothing failed, both and a note when something did. Claude Code's details: the
  per-term counts are a `Failed` column of the coefficient table rather than a vector in
  `$summary` (SPEC level-of-analysis rule 4/5: `$summary$Failed` keeps one shape whatever
  `method`); one display rule for both tables (any failure in any test shows `Sig.Upper` in
  both); UCINET's saved datasets always carry `Sig.Upper` and `Failed`, since a saved
  dataset's columns follow the dialog's options (Betas / T-statistics), not the run's outcome.
- 18 Oct 2026 (Steve, former open question 1): UCINET's QAP correlation, MR-QAP and
  node-level regression count values within 1e-10 * max(1, |obs|) of the observed statistic
  as ties, xucinet's rule (UCINET-ISSUES 49).
- 19 Oct 2026 (Steve, former open question 1): the tie tolerance is 1e-6 * max(1, |obs|), not
  1e-10, in `perm_summary` and in UCINET (tools `utunivariate.permtol`) together, so that ties
  holding only in decimal arithmetic in single-precision data count too (UCINET-ISSUES 49).
- 19 Oct 2026 (Steve; #40): `xhclust()` reports similarity input's levels as similarities, as
  UCINET does; `$hclust` stays on the dissimilarities `max - x` so `cutree()` works.
- 23 Oct 2026 (Steve; #41): Leiden in xucinet and UCINET: modularity with a resolution
  parameter (no CPM); seeded with Delphi's Random so one seed gives one partition in both;
  `xcommunities()` gets a Leiden column; UCINET's goes in after 6.850, on branch `leiden`.

## Open questions for Steve

(Former questions 1, the tie rule in UCINET, answered 18 Oct, and the decimal-tie tolerance,
answered 19 Oct: see Decisions.)


