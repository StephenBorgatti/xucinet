# xucinet — status

Updated 24 Sep 2026 (Claude Code, chapter 13; Cowork should
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
  run on igraph. `xlouvain()` fixes UCINET issue 26 as Steve decided, and refuses 2-mode
  input until open question 4 (issue #18). Goldens named in `inst/goldens/subgroups/`.
- Chapter 12 (equivalence) mostly done 23 Sep, issue #23: `xstructuralequivalence`,
  `xblockmodel`, `xcoreperiphery` (categorical and continuous), `xrege`. Waiting on Steve:
  `xblockoptimize` (issue #24, open question 6), 2-mode core/periphery (issue #25, open
  question 7), the profile-similarity diagonal default (open question 8, T13). Goldens
  named in `inst/goldens/equivalence/`.
- Chapter 13 (two-mode) done 24 Sep, issue #26: `xaffiliations`, `xbipartite`,
  `xbicliques`, and 2-mode data in `xdegree`/`xcloseness`/`xbetweenness`/`xeigenvector`
  (`mode =`). 2-mode Louvain and core/periphery still wait on open questions 4 and 7.
  Goldens named in `inst/goldens/twomode/`. The 2-mode audit is a comment on issue #26.
- Chapters 7 and 14 not started. `dev/COVERAGE.md` (24 Sep): 15 done, 58 coded with
  goldens pending, 12 not started, 3 dropped. Remaining coding order: 14, 7.
- `inst/extdata/crosswalk-routines.csv` was regenerated from the rebuilt crosswalk on
  23 Sep; its chapter 8, 11, 12 and 13 rows are edited by hand to the package's
  signatures. `crosswalk.py` has the chapter 8, 12 and 13 signatures too but still the
  old chapter 11 ones (open question 5), so re-running `data-raw/make-crosswalk.R` now
  would revert rows.
- Machine: R 4.6.1, Rtools45, devtools/roxygen2/testthat/rcmdcheck, Pandoc, TinyTeX (it
  needs `psnfss`, `cm-super`, `makeindex` for the PDF manual; `devtools::check()` passes
  `--no-manual`). igraph, sna, network and tidygraph installed 23 Sep, so the cross-check
  tests run locally. R is not on the Git Bash PATH: prefix
  `export PATH="/c/Program Files/R/R-4.6.1/bin:$PATH"`, and put `Rscript -e` code
  containing `|` in a file, because the shell hands it to cmd.exe. No Python.
- UCINET source for porting: `C:\Dev\ucinet\Source` and `C:\Dev\tools` (Delphi 13). The
  Dropbox copies are stale.

## Done this session (24 Sep 2026, Claude Code)

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

0. **Cowork:** rebuild the crosswalk xlsx (`build_xlsx.py`) and commit it (an uncommitted
   rebuild was sitting in asnr2e on 24 Sep): `crosswalk.py` has new
   signatures for `xcommunities` and the chapter 12 and 13 routines.
1. **Chapter 12 leftovers, once Steve answers:** `xblockoptimize` (open question 6,
   issue #24), 2-mode core/periphery (open question 7, issue #25), the profile-similarity
   diagonal default (open question 8, T13).
2. Claude Code runs the remaining chapter prompts in order: ch14, ch07
   (`asnr2e/docs/prompts/chNN-claude-code-prompts.md`, after `prompt-conventions.md`).
   Each is one session and ends with `dev/COVERAGE.md` regenerated. **2-mode:** Louvain
   (open question 4, #18) and core/periphery (open question 7, #25) both wait for Steve;
   each is a small follow-up once decided (T9, T14).
3. Golden tests for chapters 5, 6, 8, 10, 11, 12 and 13 stay skipped; the fixtures named in
   `inst/goldens/{transform,multivariate,ego,cohesion,subgroups,equivalence,twomode}/README.md` join the
   sweep. The Louvain golden is expected to differ until UCINET issue 26 is fixed.
4. Goldens sweep (`asnr2e/docs/prompts/goldens-sweep.md`) when Steve has a free hour with
   UCINET; `Config/ucinet/reference` bumps then.
5. Then the asnr2e side: generators and practices per chapter, and the ch07 merge
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


## Open questions for Steve

(Questions 1, 2 and 6 were answered on 23 Sep and are under "Decisions"; the remaining
ones keep their numbers because other notes refer to them.)

3. **Chapter 8 items (issue #15):** the six chapter 8 signatures in `crosswalk.py`
   (`xegonet` has neither `directed` nor `include_ego`); whether `direction` is the right
   argument name; which of UCINET bugs 17-20 will be fixed. (The `xmixing` signature
   without `model =` has been in `crosswalk.py` and the xlsx since the Cowork commit of
   23 Sep; only the chapter 8 rows remain.)
   → Partly answered 23 Sep (Steve, via Cowork). The argument is renamed `ties`, with
   `"undirected"` becoming `"any"` (Next 2; SPEC addendum). The chapter 8 rows of
   `crosswalk.py` now carry the package's signatures with `ties`. Still open: whether
   UCINET issues 17-20 go on the 6.850 list.
   → Answered 23 Sep (Steve): yes, all four are scheduled for 6.850 (UCINET-ISSUES 17-20
   updated). Question 3 is closed.
4. **2-mode Louvain (design question 11.4).** UCINET's 2-mode Louvain
   (`uc_2modelouvain.pas`, engine `G2Tools/u2modelouvain.pas`) maximizes Barber's
   bipartite modularity Q_b: one level of local moving, no aggregation, nodes visited in
   a random order under a seed, communities spanning both modes. The book (13.5.1,
   Figure 13.5, Practice 13.x) describes and uses dual projection instead (Everett and
   Borgatti 2013: Louvain on each projection, then combine). Options: (a) `xlouvain()` on
   2-mode data does bipartite modularity as UCINET does, and 13.5.1 is rewritten;
   (b) it does dual projection, as the text says, with a ledger entry; (c) both, chosen by
   an argument (the slot structure is the same either way). Recorded as
   `asnr2e/docs/text-changes.md` T9.
5. **Chapter 11 signatures for `crosswalk.py`** (issue #17). The package's copy has
   them; the master needs them: `xcliques(net, min = 3, type = c("weak","strong"),
   relation = NULL)`, `xfactions(net, k = 2, method = c("hamming","phi","modularity",
   "entailment"), restarts = 3, maxit = 20, penalty = 15, seed = NULL, relation = NULL)`,
   `xgirvannewman(net, k = 10, relation = NULL)`, `xlouvain(net, symmetrize =
   c("max","min","average","sum","none"), maxlevels = NULL, relation = NULL)` (no
   `resolution`: UCINET's Louvain has none), `xfastgreedy(net, relation = NULL)`,
   `xlabelpropagation(net, seed = NULL, relation = NULL)`; and the Walktrap row marked
   dropped. Book text: T10 (factions measures) and T11 (Louvain is deterministic) in
   `asnr2e/docs/text-changes.md`.
6. **`xblockoptimize` (design 12.3, issue #24).** Steve asked whether it differs from
   `xblockmodel` (yes: it searches for the partition, `xblockmodel` summarizes a given
   one), how to implement it, and whether a package exists. Options: (a) a native port of
   UCINET's optimization routine, as factions was (factions' tabu search runs a 200-node
   network in 0.4 s in R); (b) the CRAN package blockmodeling, fast, but with criterion
   functions that are not UCINET's. Recommendation (a).
7. **2-mode core/periphery (design 12.4, 13.6; issue #25).** UCINET's 2-mode routine
   (`x2mcatcp.pas`) is a genetic algorithm on the row-by-column correlation, not the dual
   projection the design note and 13.6 describe. Options: port UCINET's, do dual
   projection, or both. Same shape as open question 4.
8. **Profile similarity's diagonal default (design 12.1; T13).** UCINET's dialog and the
   answer to 12.1 give Reciprocal1; the book's Matrix 12.3 and its prose are Reciprocal2.
   Keep Reciprocal1 and change the text, or default to Reciprocal2 against the dialog?
