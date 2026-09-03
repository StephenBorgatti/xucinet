# xUcinet 2.0 — Design Specification

*Draft 2026-07-27. Status of each decision is marked PROPOSED (my recommendation, act unless overridden) or OPEN (needs Steve's call).*

## 1. Vision

An R package that is UCINET's twin: same concepts, same routine names (conceptually), same
numbers, same-looking output. A UCINET user should be able to move to R — and back — without
relearning anything except R punctuation. An instructor should be able to teach a course where
half the class uses UCINET and half uses xUcinet and everyone's answers match.

Secondary goals, in priority order:

1. **Easy to learn for non-R users.** Guessable syntax, aggressive defaults, forgiving inputs,
   error messages that teach.
2. **Consistent interface.** Learning three functions teaches you the other three hundred.
3. **Minimal typing.** `xdensity(net)` should just work.
4. **Fidelity.** Outputs numerically identical to UCINET wherever UCINET's formula is defensible.
   Where xUcinet improves on UCINET, the improvement gets back-ported to UCINET so they re-converge.

## 2. Non-goals

- Not a general-purpose graph library (igraph exists). We wrap/reuse, we don't compete.
- Not a GUI (possible later: RStudio addin / menu helper — out of scope for 2.0).
- Not NetDraw. Provide good default plots via ggraph/visNetwork, not a full interactive editor.
- No promise of scaling to million-node graphs. Target: classroom through serious-research sizes
  (up to ~10⁴–10⁵ nodes for cheap measures), same as UCINET.

## 3. Guiding principles

1. **UCINET numbers win.** When igraph/sna/statnet compute a measure differently (constraint,
   normalizations, treatment of isolates, disconnected-graph closeness, etc.), implement UCINET's
   formula natively rather than adopting theirs. Every intentional deviation goes in a public
   "Differences from UCINET" ledger (vignette), with a plan to reconcile.
2. **Accept anything, return something rich.** Every analysis function accepts a matrix,
   data frame, igraph object, statnet `network`, tidygraph object, xUcinet network object,
   or a UCINET dataset filename — coerced internally by one shared function.
3. **Original node order everywhere.** Node-level results print and return in input order,
   never sorted by value (matches UCINET convention and keeps rows alignable across measures).
4. **Print like UCINET, return like R.** The printed report mimics UCINET's output log (title,
   assumptions made, aligned numeric columns, ~3 decimals); the returned object is a proper R
   structure you can compute on.
5. **Defaults mirror UCINET's dialog defaults.** If UCINET's Degree dialog defaults to
   "treat as symmetric: auto", so does `xdegree()`.

## 4. Core design decisions

### D1. Core data object — PROPOSED

An S3 class **`xucinet`** that mirrors a UCINET dataset (##h/##d) in spirit:

```r
structure(list(
  data      = <matrix | 3-D array | named list of matrices>,  # multi-relation stacks
  rownames  = ..., colnames = ...,       # node labels (kept on the matrices too)
  mode      = "1-mode" | "2-mode",
  directed  = TRUE | FALSE | NA,          # NA = not yet determined; auto-detected on use
  title     = "...",                      # dataset name, used in printed output headers
), class = "xucinet")
```

- Constructors/coercers: `as_xucinet()` from matrix, data.frame (adjacency or edge list —
  auto-detected by shape), igraph, network, tbl_graph, and from a ##h filename.
- Exporters: `as_igraph()`, `as_network()`, `as_tbl_graph()`, `as.matrix()`.
- Plain matrices remain first-class citizens: every function `f(net, ...)` calls
  `as_xucinet(net)` internally, so users who live in matrix-land never see the class.
- Attributes (node covariates) live in ordinary data frames, matched to networks by row name —
  not buried inside the network object. (See D2 for the project bundle.)

Why not igraph as the core: igraph objects hide the matrix, drop dimnames semantics UCINET
relies on, and make "identical output" harder. Why not bare matrices: no home for mode/
directedness/title/multi-relation metadata.

### D2. The "project" concept — OPEN (lean yes, simplified)

Old xUCINET bundled networks + attributes into a "project" list (mirroring a UCINET folder of
files). Keep the concept but make it trivial: a project is just a named list with class
`xucinet_project`; `xcreateproject()`, `xaddtoproject()` survive as conveniences; **no function
requires a project**. All analysis functions take the network directly.

Question for Steve: was the project structure something users liked, or friction? If friction,
demote to "supported for book compatibility, not featured."

### D3. Function naming — RESOLVED (2026-07-27): all lowercase

**Package-wide invariant: everything the user types is lowercase — no shift key, ever.**
Function names, argument names, argument values, dataset names. Rationale: kills the #1
beginner failure (case errors → "could not find function"), matches UCINET's case-insensitive
CLI, matches Steve's typing preference; solid precedent in base R (`rownames`, `tolower`)
and igraph.

- **`x` prefix + run-together lowercase**: `xdensity()`, `xdegree()`, `xconcor()`,
  `xqapcorr()`. The prefix is the discoverability mechanism: type `x` + Tab and the whole
  package unfolds.
- **Keep names as short as guessability allows** (UCINET CLI names are the model) —
  run-together lowercase gets hard to scan when long, so brevity is part of the convention.
  Unavoidably long names just stay dense (`xstructuralholes`).
- Names track UCINET menu/CLI names, not igraph's: `xstructuralholes`, not `constraint`.
- One routine = one function. UCINET dialog checkboxes become arguments, not separate functions.
- No obligation to v0.x CamelCase names (clean break per D8).
- Datasets lowercase too: `campnet`, `davis`, `sampson`, `zachary`, `hightech`, plus the rest
  of the classic UCINET stable.

### D4. Argument grammar — PROPOSED

Fixed vocabulary, used identically everywhere. First argument is always the network.

| Argument | Meaning | Default |
|---|---|---|
| `net` | the network (any accepted form) | required |
| `relation` | which matrix in a multi-relation stack (index or name) | all / 1 as appropriate |
| `directed` | override auto-detection | `NULL` = auto-detect from symmetry, report assumption in output |
| `weighted` | use values vs. dichotomize | routine-appropriate UCINET default; auto-binarize **with the same warning UCINET prints** |
| `normalize` | normalized version of measure | UCINET's dialog default |
| `mode` | for 2-mode data: `"rows"`, `"cols"`, `"both"` | `"both"` |
| `attribute` | node attribute vector / column name / `data$column` | — |
| `nperm` | permutations for tests | UCINET's default (e.g. 5000 for QAP) |
| `seed` | RNG seed | `NULL` |
| `save` | dataset name → writes ##h/##d (and/or into project) like UCINET's Output dataset box | `NULL` = don't write |

Rules: no abbreviations users must memorize (`normalize`, not `norm`); all options are lowercase
strings matched with partial + case-insensitive matching (`mode="r"` works); logicals accept
TRUE/FALSE only. Every function's help page shows the corresponding UCINET menu path and the
default-laden one-liner first.

### D5. Output contract — AGREED (2026-07-27), with clarifications

Every analysis function returns an object of class `xucinet_output` (plus a routine-specific
subclass) containing, as applicable:

```r
res <- xdegree(net)
res              # autoprints the UCINET-style report
res$nodes        # node-level data frame, ORIGINAL node order
res$summary      # descriptive-stats block (mean, sd, min, max, ...)
res$matrix       # matrix-valued results (distances, similarities, permuted/blocked matrices)
res$assumptions  # what auto-detection decided (directedness, binarized, etc.)
res$call         # how it was produced
```

- **Autoprint semantics (confirmed):** `xcentrality(net)` typed alone auto-prints the full
  UCINET-style report (menu-interface feel); `x <- xcentrality(net)` is silent — typing `x`
  later replays the report. Standard R visibility rules; no extra machinery.
- **"Original node order" defined:** the storage order of the input dataset (matrix row
  1..n / label order in the ##h file). Node-level tables never sort by value by default;
  an optional `sort=` argument offers sorted display.
- **Multiple matrices:** `res$matrices` is a named list; `print()` renders each as its own
  titled section in UCINET-log order (e.g. structural holes: node table, then dyadic
  redundancy, then constraint; CONCOR: partition, permuted/blocked matrix, density tables).
  Multi-relation input → one labeled section per relation. `xsave()` writes same-dimension
  results as a multi-relation stack or as separate datasets with UCINET-style derived names
  (`campnet-geo`).
- `print()` reproduces the UCINET output log format: title line, input dataset name,
  assumption notes, aligned columns, 3-decimal rounding (display only — stored values full
  precision). Where feasible, byte-similar to UCINET's text output.
- Shared methods for the whole package: `print`, `summary`, `as.data.frame`, `plot` (where
  sensible), `xsave(res, "name")`.
- **Session log parity — OPEN:** UCINET appends every routine's output to a running log.
  Optional `xlogfile("mylog.txt")` that tees all printed reports to a text file. Cheap to build,
  very UCINET-ish. Recommend yes.

### D6. File interoperability — AGREED (the linchpin), plus new `.uci` format

**New single-file JSON format `.uci` (agreed direction 2026-07-27; schema to be drafted):**
Steve has long intended to move UCINET's native format to JSON; doing it now lets the schema
be defined once and implemented in both programs simultaneously. Contents: matrix payload
(dense, or sparse edge-list for large networks), labels, mode, directedness, multi-relation
stacks, node attributes, schema version, provenance. xUcinet reads/writes both formats from
day one with `.uci` as its default save; UCINET gets reader/writer in a future update
(XE7 System.JSON quirks known and workable, or a small dedicated writer for speed) and stays
backward compatible with ##h/##d forever. ##h/##d support in xUcinet remains mandatory
regardless — decades of existing datasets.

- **Native, full-fidelity read/write of UCINET ##h/##d files in pure R.** This is what makes
  "switch back and forth" real. The exact binary format will be ported from the Delphi source
  (`utucifile.pas` / G3Tools) — we own the reference implementation, so this can be exact,
  including labels, multi-relation stacks, and missing-value codes.
- Missing values: UCINET's `>= 1e37` convention maps to R `NA` on read; `NA` writes as `1e38`
  (bna) so UCINET reads it as missing. Users never see 1e37/1e38.
- Also read: DL (all the format families the Data Importer handles), VNA, Excel, edge-list CSV.
- Also write: DL, VNA, Excel.
- `xreaducinet("campnet")` / `xsaveucinet(net, "campnet-sym")`, plus filename-as-`net`
  convenience: `xdensity("campnet")` loads then computes, exactly like the UCINET CLI.

### D7. Formula fidelity & the differences ledger — PROPOSED

- Implementation strategy per routine, in order of preference:
  1. Delegate to igraph/sna **only after verifying numeric identity** with UCINET on the golden
     test suite (including edge cases: isolates, disconnected graphs, self-loops, valued ties,
     directed asymmetry).
  2. Otherwise implement natively in R (vectorized; Rcpp only if profiling demands it).
- Known danger zones to implement natively from the start: Burt constraint/structural holes
  (igraph differs), closeness on disconnected graphs (UCINET's options), betweenness
  normalization conventions, eigenvector scaling, flow betweenness, reciprocity definitions,
  E-I index, brokerage, CONCOR, core/periphery, REGE, all the QAP/MRQAP machinery
  (semi-partialling variants), and anything involving UCINET-specific options igraph lacks.
- The **Differences vignette** lists every place xUcinet ≠ UCINET or xUcinet ≠ igraph/sna,
  with formulas and citations. When xUcinet deliberately improves on UCINET, the entry carries
  a "UCINET catch-up planned" flag (per the stated policy of updating UCINET to match).

### D8. Backward compatibility with v0.x / the book — RESOLVED (2026-07-27)

Joint project: **Filip Agneessens is a coauthor.** The package targets the **next edition of
the book**, so the syntax may be redesigned freely — no obligation to preserve v0.x names or
signatures (keep them where they're already good). Old-edition readers stay on old xUCINET
0.x; new-edition readers use 2.0. Version 2.0.0.

Package name: **`xucinet`** (all lowercase, per the D3 everything-lowercase invariant).

### D9. Dependencies — PROPOSED

- **Imports (hard):** keep minimal — `Matrix` (sparse), maybe nothing else beyond base.
- **Used-if-verified (Imports or Suggests per routine):** `igraph`, `sna` (Butts's formulas
  often match UCINET's — check first, it saves native implementations), `blockmodeling`,
  `ergm` (only if we expose ERGM at all — OPEN; recommend deferring to statnet and just
  documenting the bridge), `ggraph`/`ggplot2`, `visNetwork`, `readxl`/`writexl`.
- No tidyverse hard dependency; pipe-friendly but base-R at the core. Works on a clean R
  install with one `install.packages()`.

### D10. Auto-transformation policy — PROPOSED

UCINET's habit of "this routine needs binary symmetric data — I dichotomized/symmetrized for
you (warning)" is a big part of its beginner-friendliness. Replicate it: routines that require
binary/symmetric input transform automatically, print the same notice UCINET does, and record
it in `res$assumptions`. Argument overrides (`weighted=`, `directed=`, `symmetrize=`) let users
take control.

### D11. Two-mode and multi-relation — PROPOSED

- 2-mode is a first-class citizen (as in UCINET): `mode="rows"/"cols"/"both"` argument,
  2-mode-aware variants where UCINET has them (2-mode centrality, bipartite core/periphery,
  dual projection, SDSM/backbone extraction, 2-mode Louvain — matching the recent UCINET
  additions).
- Multi-relation stacks (Sampson, KnokeBureaucracies): `relation=` selects; routines that
  operate per-relation loop and label output sections like UCINET does.

### D12. Randomness & tests — PROPOSED

All permutation/bootstrap routines: `nperm` defaults matching UCINET dialogs, `seed=` argument,
p-values defined exactly as UCINET defines them (proportion as extreme, same tail conventions —
including the recent 1-vs-2-tailed QAP options). Document that UCINET and R RNGs differ, so
p-values match in distribution, not digit-for-digit.

### D13. Visualization — PROPOSED

`xplot(net, node_color=, node_size=, edge_width=, layout=, interactive=FALSE)` — one function,
ggraph backend (visNetwork when `interactive=TRUE`), defaults chosen to look like a clean
NetDraw/UCINET-Draw picture (spring embedding, labels on, sensible sizes). Measure outputs plug
in directly: `xplot(net, node_size = xdegree(net))`. Not a NetDraw replacement.

### D14. Error handling & learnability — PROPOSED

- Argument checking up front with messages that say what to do:
  `"'net' has 3 columns and looks like an edge list; expected sender, receiver[, weight]. Did you mean xfromedgelist()?"`
- Misspelled argument detection (partial matching plus "did you mean `normalize=`?").
- `xhelp("degree")` — fuzzy finder from UCINET menu names / plain English to functions.
- Every example in every help page runs on a shipped dataset in one line.

### D15. Licensing & distribution — PROPOSED

- GPL-3 (ecosystem-compatible with igraph/sna/blockmodeling; no obstacle to porting logic from
  UCINET's own source since Steve owns it).
- Host at **github.com/stephenborgatti/xucinet**. pkgdown site on
  GitHub Pages; `remotes::install_github()` from day one; **r-universe** for binary installs
  without users needing Rtools (worth it — the target audience won't have Rtools); CRAN once
  the API stabilizes (end of Phase 5). Book website updated to point at GitHub.

## 5. Testing & fidelity infrastructure

The decisive advantage: we own UCINET and its CLI. So:

0. **Console CLI (`ucinetcl`) — agreed to pursue:** a new `{$APPTYPE CONSOLE}` Delphi target
   linking the existing CLI machinery (Xalgebra dispatch → Xdpmat/Xdpfunc/Xdpman), settings
   via tmeminifile, log stream redirected to stdout/file, commands fed from a script file.
   Compilable with dcc32 and runnable headlessly, which makes golden-fixture generation fully
   automated (Claude can regenerate and verify fixtures itself while porting routines).
   Risks: VCL linkage (fine if no form is shown) and CLI paths that secretly pop dialogs —
   flush out via a compile-and-run spike. UCINET-side task; the single best enabler for the
   fidelity program.
1. **Golden fixtures:** a UCINET CLI script runs every ported routine over a fixed battery of
   datasets (campnet, Sampson, Davis, Zachary, plus adversarial cases: isolates, disconnected,
   self-loops, valued, asymmetric, missing values, 2-mode, multi-relation) and dumps outputs.
2. **testthat** compares xUcinet values to fixtures at 1e-6 tolerance; a subset also compares
   *printed* output text near-verbatim.
3. Fixtures are versioned with the UCINET build that generated them; regenerating them is one
   script, so when UCINET catches up to an xUcinet improvement, tests re-sync.
4. Standard CI (GitHub Actions: R CMD check on win/mac/linux, oldrel/release/devel) runs value
   tests against stored fixtures; fixture generation itself stays a manual Windows-side step.

## 6. Decisions log & remaining open questions

Resolved 2026-07-27 (discussion with Steve):
- Joint project, Filip Agneessens coauthor; targets next book edition; syntax free to change
  (old edition → old xUCINET 0.x). Version 2.0.0. (D8)
- Core data object (D1/D2), argument grammar (D4), output contract incl. autoprint +
  original-order + multi-matrix sections (D5), formula-fidelity policy (D7), auto-transform
  with UCINET-style warnings (D10): agreed as specced.
- Original node order confirmed as the default everywhere; Steve: UCINET itself should
  probably stop sorting outputs by value ("it probably confuses people") — logged as a
  UCINET-side catch-up item (audit routines that sort node-level tables, switch to storage
  order, keep any sort option opt-in).
- New `.uci` JSON format: yes, now — schema defined jointly for UCINET + xUcinet (D6).
- Console CLI `ucinetcl` for automated golden generation: agreed in principle, **deferred** —
  Steve will schedule it later. Until then, golden fixtures are generated manually via the
  GUI/CLI on the Windows side.
- **Delphi upgrade planned:** Steve is buying a powerful new machine and installing current
  Delphi, which becomes the UCINET development machine (migration from XE7, with Claude's
  help). Runs in parallel with xUcinet; it's acceptable for UCINET-side changes (.uci
  reader/writer, unsorted outputs, catch-up items) to land later than the R package.
- xplot scope confirmed: plotting is a function (static ggraph / visNetwork widget), not a
  NetDraw-like interactive application.

- GitHub account: **stephenborgatti** → repo github.com/stephenborgatti/xucinet.
- Package name: **`xucinet`** — all lowercase, matching the D3 everything-lowercase
  invariant (function names, arguments, values, datasets, package). Confirmed by Steve.

Still open:
1. Keep or demote the v0.x "project" structure (default in spec: keep, thin, optional).
2. Session log file feature `xlogfile()` (recommend yes).
3. ERGM/ALAAM exposure: wrap statnet minimally, or leave out of 2.0? (Recommend: out of 2.0,
   document the `as_network()` bridge.)
4. Scope confirmation for Phase 1 (see PLAN.md) — anything that must move earlier?
