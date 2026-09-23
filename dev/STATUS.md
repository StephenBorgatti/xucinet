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
  26). `xcentralization()` covers degree, betweenness and eigenvector; closeness is Next
  0(b). `xcohesion` is golden-tested against the Phase 0 fixtures; the rest
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
- Steve's first 23 Sep answers (issue #16) are all carried out; his later ones (closeness
  centralization, the level-of-analysis changes) are Next 0.
- Chapter 11 (subgroups) complete 23 Sep, issue #17: `xcliques`, `xfactions`,
  `xgirvannewman`, `xlouvain`, `xfastgreedy`, `xlabelpropagation`, `xcommunities`, with
  shared internals in `R/community-internals.R` (UCINET's modularity, a port of Delphi's
  `Random`, the common Cluster/Modularity output). igraph is in Imports (G1). Cliques,
  factions, Girvan-Newman and Louvain are native ports; fast greedy and label propagation
  run on igraph. `xlouvain()` fixes UCINET issue 26 as Steve decided, and refuses 2-mode
  input until open question 4 (issue #18). Goldens named in `inst/goldens/subgroups/`.
- Chapters 7, 12, 13, 14 not started. `dev/COVERAGE.md` (23 Sep): 14 done, 48 coded with
  goldens pending, 21 not started, 3 dropped (Walktrap and QuickClus now counted as
  dropped). Remaining coding order: 12, 13, 14, 7.
- `inst/extdata/crosswalk-routines.csv` was regenerated from the rebuilt crosswalk on
  23 Sep; its chapter 8 and chapter 11 rows are edited by hand to the signatures the
  package has, because the master `crosswalk.py` does not have them yet (issue #15 for
  chapter 8; chapter 11 is open question 5). Re-running `data-raw/make-crosswalk.R` before
  the master is updated will revert them.
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

0. **Before chapter 12, Claude Code applies Steve's 23 Sep answers:**
   (a) **Level of analysis** (SPEC addendum 23 Sep, items 5 and 6 and "Applications") to
   the functions listed there: `xhomophily`, `xreciprocity`, `xegonet` (new reciprocity
   column), `xtransitivity`, `xegoaltersimilarity`, `xcentralization`, `xhclust`,
   `xstructuralholes`, `xgirvannewman` (a partition column for every component count
   reached; `k` sets only what is printed) and `xcliques` (unchanged: its co-membership
   matrix is now a named exception). Snapshot updates, 1e alias checks, and
   `text-changes.md` entries wherever a chapter describes the old output (check 8.6.2 and
   10.2.2 for reciprocity, 10.5 for the homophily report). The `xegonet()` reciprocity
   column follows UCINET's node-level reciprocity if one exists in the Reciprocity
   routine or the ego-network units; if the definition has to be chosen, stop and ask.
   (b) **Closeness centralization:** port the figure from the legacy Closeness routine
   (`xcloseness.pas`, "Network Centralization = ") into `xcloseness()$summary`, check it
   against `runcentralization` in `Xdpmat.pas`, add a ledger entry saying UCINET's
   current Closeness dialog does not print it, and let `xcentralization(measure =
   "closeness")` return it. Its golden joins the sweep.

1. Claude Code runs the remaining chapter prompts in order: ch12, ch13, ch14, ch07
   (`asnr2e/docs/prompts/chNN-claude-code-prompts.md`, after `prompt-conventions.md`).
   Each is one session and ends with `dev/COVERAGE.md` regenerated. Chapter 12 has
   answers 12.1-12.4 in the table, two of them questions back to Claude Code (12.2, 12.3).
   **2-mode Louvain:** still waits for open question 4 (issue #18) before the 2-mode
   branch of `xlouvain()` is written; it may land with chapter 13.
2. Golden tests for chapters 5, 6, 8, 10 and 11 stay skipped; the fixtures named in
   `inst/goldens/{transform,multivariate,ego,cohesion,subgroups}/README.md` join the
   sweep. The Louvain golden is expected to differ until UCINET issue 26 is fixed.
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

## Open questions for Steve

(Questions 1, 2 and 6 were answered on 23 Sep and are under "Decisions"; the remaining
ones keep their numbers because other notes refer to them.)

3. **Chapter 8 items (issue #15):** the six chapter 8 signatures in `crosswalk.py`
   (`xegonet` has neither `directed` nor `include_ego`); whether `direction` is the right
   argument name; which of UCINET bugs 17-20 will be fixed. (The `xmixing` signature
   without `model =` has been in `crosswalk.py` and the xlsx since the Cowork commit of
   23 Sep; only the chapter 8 rows remain.)
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
