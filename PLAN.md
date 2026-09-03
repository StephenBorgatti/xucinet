# xUcinet 2.0 — Implementation Plan

*Draft 2026-07-27. Companion to SPEC.md. Phases are sequential but each ships something usable;
routine lists map to UCINET menus so coverage is auditable against the real menu tree.*

## Tooling & repo layout

- `usethis` scaffold, `roxygen2` docs, `testthat` (edition 3), `pkgdown` site, GitHub Actions
  (R CMD check matrix + pkgdown deploy), `air`/styler for formatting.
- Repo layout:
  ```
  R/                  one file per routine family (centrality.R, cliques.R, qap.R, io-ucinet.R, ...)
  R/class-xucinet.R   core class + coercers
  R/output.R          xucinet_output class, print/summary/as.data.frame machinery
  data/               shipped datasets (.rda)
  inst/goldens/       UCINET-generated fixtures + the CLI script that makes them
  tests/testthat/
  vignettes/          getting-started, ucinet-crosswalk, differences-ledger
  ```
- Golden-fixture generator: a UCINET CLI batch script kept in `inst/goldens/make_goldens.txt`,
  run on the Windows side whenever UCINET changes; outputs checked into the repo.

## Phase 0 — Foundations (everything else depends on this)

1. Repo + CI + pkgdown skeleton; decide D8 (naming/compat) first since it fixes the package name.
2. **##h/##d binary read/write**, ported exactly from the Delphi reference (`utucifile.pas` /
   G3Tools). Includes labels, multi-relation stacks, 2-mode, missing-value mapping (≥1e37 → NA,
   NA → 1e38). Round-trip tests: UCINET-written file → R → written back → re-read by UCINET.
3. **`.uci` JSON schema draft** (joint UCINET/xUcinet format) + R reader/writer (jsonlite;
   sparse edge-list payload for large networks). `.uci` is xUcinet's default save format.
4. DL / VNA / Excel / edge-list import; DL + VNA export.
5. `xucinet` class, coercers to/from matrix, igraph, network, tbl_graph; auto-detection of
   directedness/2-mode; `xucinet_project` (thin).
6. `xucinet_output` class with print/summary/as.data.frame; the UCINET-style report renderer
   (aligned columns, headers, assumptions block) — built once, used by every routine.
7. Golden-test harness wired end to end with one pilot routine (Density) proving
   value-identity and print-similarity. Parallel UCINET-side track: the `ucinetcl` console
   build (see SPEC §5) so fixture generation is scriptable rather than manual.
8. Ship the classic datasets.

**Exit criterion:** `xdensity(xreaducinet("campnet"))` prints a report matching UCINET's, and a
dataset written by `xsaveucinet()` opens cleanly in UCINET.

## Phase 1 — The everyday 80%

Transformations (needed by everything downstream):
dichotomize, symmetrize, transpose, recode/reverse, normalize, subgraph/extract, remove
isolates, combine/stack relations, permute/sort by vector, attribute↔network (xattributetonetwork
etc.), geodesic distances, reachability.

Whole-network descriptives: density, average degree, reciprocity (both defs), transitivity/
clustering coefficient (network + ego-level, matching the recent UCINET split), components
(weak/strong), connectedness/fragmentation, compactness/breadth, centralization.

Centrality suite: degree (in/out), closeness (UCINET's disconnected-graph options), betweenness,
eigenvector, Bonacich beta, 2-step reach/ARD, hubs & authorities, PageRank-as-UCINET-does-it,
2-mode centrality; the multi-measure convenience (equivalent of the Multiple Centrality suite,
one call → aligned node×measure table).

**Exit criterion:** every routine golden-tested; book chapters on centrality/cohesion run
end-to-end with the new package.

## Phase 2 — Subgroups & communities

Cliques (+ overlap/co-membership analysis), n-cliques, n-clans, k-plexes, k-cores, factions,
Girvan-Newman, Louvain (incl. 2-mode Louvain), Newman modularity reporting, core-periphery
(categorical + continuous), bridging/brokerage measures (VF 2010 + EV 2016, matching the recent
UCINET additions).

## Phase 3 — Equivalence, roles & blockmodels

Structural-equivalence profiles (Euclidean/correlation), CONCOR, Johnson hierarchical
clustering, optimization blockmodeling (tabu), density/image tables with the blocked-matrix
display, REGE/regular equivalence (port after the UCINET Xrege engine work settles).

## Phase 4 — Testing hypotheses

QAP correlation (1/2-tailed as per recent UCINET), MRQAP (Y-permutation + Dekker semi-partialling),
node-level permutation t-test/ANOVA/regression, E-I index, joint-count/categorical autocorrelation,
network autocorrelation lag & error models (port of unetautocorr), density comparison tests.

## Phase 5 — Ego networks & 2-mode

Ego measures: size/ties/pairs/density, composition & heterogeneity (incl. the new categorical
alter-composition routine), Gould & Fernandez brokerage, structural holes with UCINET's
formulas (constraint, effective size, efficiency, hierarchy) + documented igraph delta,
Burt-style ego betweenness. Two-mode: affiliations/dual projection, bipartite density/centrality
recap, SDSM/backbone (logit + BiCM, matching UCINET), 2-mode core-periphery.

## Phase 6 — Polish & release

- Vignettes: *Getting started (for UCINET users)*, *UCINET menu → xUcinet crosswalk* (every menu
  item → function call), *Differences ledger*, *For igraph users*.
- Cheatsheet PDF; `xhelp()` fuzzy finder; final pass on error messages.
- r-universe binaries; CRAN submission; book-website pointer updated; announce.

## Sequencing notes & risks

- **Do D8 (compat decision) before writing any code** — it fixes package name and export list.
- The ##h/##d port is the highest-risk item and gates everything; schedule it first and test
  round-trips against UCINET itself early.
- sna/igraph delegation: verify numeric identity per routine on the golden battery *before*
  wiring it in; when in doubt, implement natively — a slow correct routine beats a fast
  slightly-different one for this package's mission.
- Fixture regeneration is manual (Windows + UCINET CLI); keep the battery script small enough
  to re-run in minutes so it actually gets re-run.
- Ongoing habit: any xUcinet improvement over UCINET gets a UCINET work item logged so the two
  re-converge (per the stated policy).
