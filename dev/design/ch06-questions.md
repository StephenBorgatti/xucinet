# Chapter 6 — design questions

## Steve's answers (18 September 2026, Cowork session)

Given by Steve before the routines were written that day; the recommendations
below stand unless a row here says otherwise.

| # | decision |
|---|---|
| 1 | As recommended: copy, cite commit, vendor sources in `inst/reference/borgworld/`; `MASS` to Imports; ggplot2 not taken. |
| 2 | As recommended: matrix, `dist`, `xucinet`; `as_xucinet()` learns `dist`; `type` never inferred. |
| 3 | As recommended: `stop()` with both values glossed. |
| 4 | As recommended: UCINET's report layout, borgworld's numbers. One change in implementation: the Shepard data live in `res$shepard`, not `res$matrices$Shepard`, so the report does not print one row per pair. |
| 4c | **UCINET's text cluster diagram** (`format_uci_dendrogram()` in `R/output.R`, ported from `Udendro.pas`). |
| 5 | As recommended: base graphics via a shared `plot_coords()`, `asp = 1`; D13 narrowed to network plots. |
| 6 | As recommended. Helpers `expect_procrustes_equal()`, `expect_equal_up_to_sign()`, `expect_same_partition()` in `tests/testthat/helper-goldens.R`. |
| 7 | As recommended: entries 6–11 written, plus 12 (equal axis scaling). |
| 8 | **Skip Gamma, retain Modularity** ("community detection and clustering coincide when the data consist of a graph"); Corr and Silhouette also kept. Modularity follows UCINET's `calcmoca` formula (Newman's Q) rather than borgworld's loop. |
| 9 | **Off-diagonal maximum everywhere.** `xmds()` on similarity input does not reproduce `bclassicalmds`/`bnonmetricmds` when the diagonal holds the maximum. |
| 10 | As recommended: configuration by default; `xshepard()` separate. |
| 11 | As recommended: no row ≥ column limit; NA to the overall mean; zero margins dropped and named; full-spectrum inertia. |
| 12 | As recommended: `k` adds a `Cluster` column. |
| 13 | As recommended: `x` for proximity input; `type`, `dim`, `k`, `method`, `labels` added to the D4 vocabulary. `save =` deferred: no routine in the package has it yet, and it should land for all of them at once. |

Found while porting (not in the questions): `bcophenetic()` indexes the `dist`
object returned by `cophenetic()` with `lower.tri()` of its matrix form, so it
correlates the wrong cells and reports 0.08 for cities where the value is 0.71.
The port computes it on matching lower triangles; borgworld should be fixed.

---


*Multivariate techniques: MDS (6.2), correspondence analysis (6.3), Johnson's
hierarchical clustering (6.4). Written 8 September 2026, before any code, on the
model of the chapter 9 centrality pilot. Every question carries a recommendation;
answer inline or by striking one out.*

**Where this file lives.** You asked for `docs/design/ch06-questions.md`. `docs/`
is the pkgdown build output and is listed in `.gitignore`, so a file there cannot
be committed and would be deleted by the next `pkgdown::build_site()`. It is here
instead, beside `dev/SPEC.md` and `dev/PLAN.md`, which is where the tracked
design notes already live.

## Sources read

**borgworld** — cloned at `6b0f0df` (3 December 2025, HEAD of `main`). The six
functions and the helpers they reach:

| function | file | last touched |
|---|---|---|
| `bmds` | `R/b_mds.R` | `2b8f2b7`, 14 Oct 2025 |
| `bclassicalmds`, `print.bmds` | `R/b_classicalmds.R` | `d9ca8bc`, 14 Oct 2025 |
| `bnonmetricmds`, `print.bnmds`, `shepard.bnmds` | `R/b_nonmetricmds.R` | `2b8f2b7`, 14 Oct 2025 |
| `bhiclus`, `bcophenetic`, `create_partition_table`, `print_ascii_dendrogram`, `plot_graphical_dendrogram`, `print.bhiclus`, `summary.bhiclus` | `R/b_hiclus.R` | `2eb26f4`, 25 Oct 2025 |
| `bmoca` | `R/b_moca.R` | `2b8f2b7`, 14 Oct 2025 |
| `bcorresp`, `print.bcorresp`, `summary.bcorresp` | `R/b_corresp.R` | `51d6dca`, 14 Oct 2025 |

borgworld has **no `tests/` directory** — `testthat` is in `Suggests` but there
is no test suite. So borgworld's numbers are not themselves pinned by anything,
and porting is the moment they first get tests.

**UCINET** — read in the previous session from `~/Dropbox/code/Ucinet/Source`
plus `~/Dropbox/code/Tools/{G1Tools,G2Tools}`. You said afterwards that this may
be the wrong tree; there is also an unextracted `~/Dropbox/CodeXE8/CodeXE8.7z`
(1.8 GB, January 2026). Every UCINET claim below is cited by unit and procedure
so it can be re-checked cheaply against whichever tree is current. Nothing in the
port depends on it — UCINET enters only as the oracle in question 6 and as the
report layout in question 4.

---

## 1. Porting, not depending

**Question.** borgworld is GitHub-only and xucinet is CRAN-bound, so borgworld
cannot go in `Imports`. Confirm the code is copied in; list what each function
drags with it; name any dependency xucinet does not have.

**Recommendation — copy, with provenance in a comment.** Each ported block gets
a header comment naming the borgworld function, file and commit, in the same
spirit as the Delphi citations in `R/xdegree.R`:

** yes, copy/paraphrase code. do not rely borgworld existing.

```r
# Ported from borgworld::bclassicalmds() (R/b_classicalmds.R, commit d9ca8bc,
# 14 October 2025). Numbers are borgworld's; the report is UCINET's.
```

and `inst/reference/borgworld/` gets the six source files vendored unchanged,
exactly as `inst/reference/delphi/` holds the Delphi units. That is what makes
"the port reproduces borgworld" checkable a year from now when borgworld has
moved on.

**What each function pulls in.**

| xucinet function | borgworld code it needs | new? |
|---|---|---|
| `xmds(method = "classical")` | `bclassicalmds` body | — |
| `xmds(method = "nonmetric")` | `bnonmetricmds` body; `shepard.bnmds` body (see Q4/Q5) | — |
| `xhclust` | `bhiclus` body, `create_partition_table`, `bcophenetic`, `print_ascii_dendrogram`, `plot_graphical_dendrogram`, and — if we keep it, Q8 — `bmoca` | — |
| `xcorrespondence` | `bcorresp` computational block (lines 169–283) and its base-R plotting branch | — |

`bmds` itself is **not ported**: it is a dispatcher whose whole job is fuzzy
method-name matching (`^c|^m|^p` → classical, `^n|^o|^i|^k` → nonmetric) and a
`verbose` message. `xmds()` replaces it with `match.arg()`, which is the
package's own convention and gives partial matching for free.

**Dependencies.**

- **`MASS`** → `Imports`. Needed for `isoMDS`. It is a Recommended package, ships
  with every R install, and adds nothing to install time. Fine.
- **`cluster`** → only reached by `bmoca` for `silhouette()`, and `bmoca` already
  has a hand-rolled fallback behind `requireNamespace()`. Also Recommended. If we
  port `bmoca` at all (Q8), put `cluster` in `Suggests` and keep the fallback.
- **`ggplot2`** → `bcorresp`'s preferred plotting path. **Do not take it.** It is
  not a Recommended package, it would be xucinet's first heavy dependency, and
  SPEC D9 says keep `Imports` minimal. `bcorresp` already carries a complete
  base-R plotting branch (`R/b_corresp.R` lines 441+) behind
  `requireNamespace("ggplot2")`; port that branch and drop the ggplot2 one.
- **`grDevices`, `graphics`** → `Imports`. Needed for any plot at all; both are
  base-distribution.
- `clipr`, `dplyr`, `rlang`, `sandwich`, `stringr`, `tidyr`, `tidytext`,
  `googlesheets4`, `psych` are in borgworld's `Imports` but **none of the six
  functions touches any of them**. Nothing to carry.
- `bcorresp.export()` uses `utils::write.csv` and `bcorresp` uses
  `grDevices::pdf`/`dev.off` for `save.plot`. Drop both: `save =` (SPEC D4) is
  how xucinet writes results, and it writes UCINET datasets, not CSV.

**Note on `verbose`.** `bmds`, `bclassicalmds` and `bcorresp` emit `message()`
and `cat()` chatter (`"Using classical (metric) MDS"`, `"=== bcorresp Analysis
Results ==="`). All of it goes; the printed report is `print.xucinet_output()`'s
job and SPEC D5 says construction is silent.

---

## 2. Input

**Question.** borgworld takes a matrix. xucinet should also take an `xucinet`
object (1-mode for `xmds`/`xhclust`, 1- or 2-mode for `xcorrespondence`) and a
`dist`. Can `type =` ever be inferred?

**Recommendation — accept all three; never infer `type`. You are right.**

Coercion follows SPEC D4 with one wrinkle: the first argument is `x`, not `net`,
so the standard first line becomes

```r
x <- xnet(x, substitute(x))
```

which still captures the caller's expression as the dataset title, so
`xmds(cities, "d")` prints `Input dataset: cities` like every other routine.
`xnet()` already accepts matrices, data frames, igraph, network, `xucinet` and
file names; `dist` is the one class it does not know, and the cleanest fix is to
teach `as_xucinet()` about `dist` once (`as.matrix()` on it, mode `"1-mode"`,
`directed = FALSE`) rather than special-case it in three routines. That also makes
`xdisplay(dist(...))` work, which is a small free win.

**Why `type` cannot be inferred, in the cases that tempt you:**

- **Geodesic distances.** Diagonal 0, all values ≥ 0, integer. Looks like a
  distance — and is one. But `xreach()` output, `2-step reach`, and a
  co-membership count have exactly the same shape and are *similarities*.
- **Correlations.** Diagonal 1, range [-1, 1]. Almost always a similarity, but a
  matrix of `1 - r` has diagonal 0 and range [0, 2] and is a dissimilarity, and
  nothing distinguishes it from a distance matrix with a coincidental range.
- **An adjacency matrix.** Diagonal 0, values 0/1. Reads as a distance matrix
  under every heuristic and is a similarity under every interpretation. This is
  the case that kills inference: it is also the single most likely thing a reader
  of this book will pass in.

A guess that is right 90% of the time is worse than no guess, because the 10%
comes back as a *plausible* map that is inside out, with nothing on screen saying
so. UCINET has the same dialog control and does not infer either
(`MMDSDlg.dfm`/`MDSDlg.dfm`/`HierDlg.dfm` each carry a
`Similarities/Dissimilarities` combo).

**Sub-question: should `type` be recorded in `$assumptions`?** Yes — one line,
`Type of Data: Similarities`, which is verbatim what UCINET's
`log.putstr('Type of Data:', ...)` writes, plus a second line naming the
conversion when one happened (Q9).

**2-mode.** `xmds` and `xhclust` reject a rectangular matrix with the same error
shape `xdegree()` uses ("needs a square matrix; this one is 18 x 14").
`xcorrespondence` takes any rectangular matrix; see Q11 on the row ≥ column
question.

---

## 3. Missing `type =`

**Question.** borgworld prompts interactively. Should xucinet `stop()`?

**Recommendation — `stop()`, always, with both values named. Confirmed.**

borgworld's three copies of the prompt block are identical and all end in the
same `stop()` when `!interactive()`, so the non-interactive branch is already
borgworld's own behaviour; we are deleting the interactive branch, not inventing
a policy. The reasons to delete it:

- Practices and the book's generators run under `Rscript` and `knitr`, where
  `readline()` returns `""` immediately and the prompt becomes an obscure
  "Invalid choice" error.
- A function that blocks on stdin cannot be tested.
- SPEC D14 wants errors that teach. The message should be the teaching:

```
xmds() needs to know what kind of matrix this is.
  type = "similarities"     larger values mean closer  (correlations, co-membership counts, ties)
  type = "dissimilarities"  larger values mean further (distances, geodesics)
  e.g. xmds(cities, type = "dissimilarities")
```

The gloss matters more than the list. "Similarities vs dissimilarities" is
exactly the vocabulary a beginner is unsure about, so spell out which direction
each one means and give an example that runs.

---

## 4. What they compute and print, and how it maps onto `xucinet_output`

Read as: *this is what the borgworld code does*, then *this is what UCINET's
report shows*, then *this is what I propose xucinet does*.

### 4a. `xmds(method = "classical")` — from `bclassicalmds`

**Computes.**

1. If `type = "similarities"`: `d <- max(x, na.rm = TRUE) - x`, then
   `diag(d) <- 0`. **The max is taken over the whole matrix, diagonal
   included.** (See Q9 — `bhiclus` excludes the diagonal, and the two disagree.)
2. Negative dissimilarities → `warning()` and clamp to 0.
3. `stats::cmdscale(d, k = dim, eig = TRUE, add = FALSE)`.
4. `eig` is the full length-*n* eigenvalue vector from `cmdscale`.
5. `GOF1 = sum(abs(eig[1:k])) / sum(abs(eig))`;
   `GOF2 = sum(pos_eig[1:k]^2) / sum(pos_eig^2)` where `pos_eig = eig[eig > 0]`.
   Note these are **not** `cmdscale`'s own `$GOF` pair, and `GOF2` squares the
   eigenvalues, so it is a share of squared eigenvalues, not of inertia.
6. `stress = sqrt(sum((d - dhat)^2) / sum(d^2))`, summed over **all n² cells**
   (the diagonal contributes 0 to both), with `dhat = as.matrix(dist(coords))`.
   This is Kruskal's stress formula 1 with the raw dissimilarities used as
   disparities.

**Prints** (`print.bmds`): a banner, the call, n, dim, type, stress at 4 dp, GOF1
and GOF2 at 4 dp, then `head()` of the coordinates with a "(Showing first 6 of
N)" line.

**UCINET shows** something different in two places worth deciding on.

- UCINET's stress is `stressform1` in `Tools/G1Tools/ummds.pas`:
  `sqrt(Σ_{i<j}(dist_ij − d_ij)² / Σ_{i<j} dist_ij²)` — the **denominator is the
  sum of squared *configuration* distances**, where borgworld's is the sum of
  squared *data*. The two agree only at a perfect fit. This is a real numeric
  difference, not a rounding one.
- UCINET's classical route prints an `Eigenvalues` table with `Value` and `Prop`
  columns (`getinitialcoordinates` in `Xmmds.pas`; the CLI `classicmds()` in
  `Xdpmat.pas` prints them one per line at 3 dp).

**Proposed `xucinet_output`:**

| slot | contents |
|---|---|
| `$nodes` | `Dim1 … Dimk`, one row per object, **original order** (`cmdscale` preserves it) |
| `$summary` | `Stress`, `GOF1`, `GOF2` |
| `$matrices$Eigenvalues` | two columns, `Value` and `Prop` (`eig / sum(eig[eig > 0])`), one row per positive eigenvalue — UCINET's own table |
| `$assumptions` | type; the similarity→dissimilarity conversion if one happened; the clamp warning if it fired |

`print()` renders: title block, `Input dataset:`, `Type of Data:`, assumptions,
the `Eigenvalues` matrix, the `MDS Coordinates` table, then the `$summary` block
as a one-row matrix — which is how `xdensity()` already does whole-network
statistics, and is `cat_uci_matrix()` all the way down. **All rows, never
`head()`**: SPEC D5 says original node order and no truncation, and the `head()`
in `print.bmds` is exactly the borgworld habit that the xucinet report replaces.

**Which stress?** Recommend **reporting borgworld's** (denominator = Σ data²) and
saying so on the line: `Stress (Kruskal formula 1)`. Reasons: it is the standard
textbook definition, it is the one `isoMDS` reports for the non-metric branch so
the two `xmds` methods stay comparable, and matching UCINET's variant here would
make classical and non-metric stress incomparable *within* our own function.
Ledger entry (Q7).

### 4b. `xmds(method = "nonmetric")` — from `bnonmetricmds`

**Computes.** Same conversion and clamp as 4a, then

```r
d_dist     <- as.dist(d_matrix)
init       <- cmdscale(d_dist, k = dim)        # classical start
MASS::isoMDS(d_dist, y = init, k = dim, maxit = 100, tol = 1e-3)
```

and reports `isoMDS$stress / 100` (isoMDS returns a percentage) plus
`isoMDS$n_iter`.

**Fact worth flagging: there is no randomness.** Your brief says "including the
same random seed for isoMDS". `bnonmetricmds` seeds `isoMDS` with a classical
solution, which is deterministic, so `isoMDS` never calls the RNG. The port is
reproducible without `set.seed()` and the test needs no seed. If you *want* a
random-start option later it would be a new argument, not a fidelity issue.

** good

**Fact worth flagging: `bnonmetricmds` does not draw a Shepard plot.** Its
`plot = TRUE` draws the **configuration scatter** — points, labels, grid, with
`Stress = 0.123 - Good fit` in the `sub` line. `shepard.bnmds()` is a separate
exported function that takes the original dissimilarity matrix as a second
argument, is not a method on any generic (there is no `shepard` generic in
borgworld's NAMESPACE), and **is never called by anything**. So "produces a
Shepard plot, as `bnonmetricmds` does" is not something the code currently does.
See Q10 for the decision this needs.

**Proposed `xucinet_output`:** as 4a minus the eigenvalue table, plus

- `$summary`: `Stress`, `Iterations`
- `$matrices$Shepard`: three columns, `Dissimilarity`, `Distance`, `Disparity`,
  one row per pair, labelled `i-j` — so the Shepard plot is data in the object
  and can be drawn later, from the result, without re-running anything

Drop the `"Excellent / Good / Fair / Poor / Questionable"` verdict from the
report. It is Kruskal's 1964 rule of thumb, it is dimension- and n-dependent
(MINISSA's own `spstrs` expected-stress formula in `ug2minissa.pas` says as
much), and a program that grades your solution in one word invites people to stop
thinking. Keep it in the help page as prose if you want it.

### 4c. `xhclust` — from `bhiclus` + `bcophenetic`

**Computes.**

1. If `type = "similarities"`: max over the **off-diagonal only** (`diag <- NA`
   first), then `prox <- max_val - prox`. Then `diag(prox) <- 0` either way.
2. `hclust(as.dist(prox), method = method)` with `method` one of
   `average` / `single` / `complete`.
3. `create_partition_table()`: an *n* × (*n*−1) integer matrix, columns `P1 …
   P(n-1)`, **one column per merge step**, cluster ids renumbered 1..k in order
   of first appearance.
4. `bmoca(prox, table, type = "d")` → per-partition `n_clusters`, `Corr`,
   `Gamma`, `Modularity`, `Silhouette`.
5. `bcophenetic(prox, hc, type = "d")` → `cor()` of the lower triangles of the
   proximity matrix and `stats::cophenetic(hc)`. (The sign flip in `bcophenetic`
   never fires from inside `bhiclus`, because the matrix has already been
   converted to dissimilarities and `type = "d"` is passed literally.)

**Prints.** An ASCII dendrogram (`print_ascii_dendrogram`) — labels stacked
vertically one character per line, a `------` rule, then one row per merge step
with the height at `%6.1f` and `X` spanning each multi-member cluster in
`hclust$order` position — then a graphical `plot(hclust, hang = -1)`, then
`print.bhiclus` gives n, method, type, cophenetic correlation, the full partition
table and the MOCA table.

**UCINET's `Johnson's Hierarchical`** (`XCluster.pas` → `Johnson2` in
`Tools/G1Tools/Uclus.pas`) prints: the title block, `Method:` and `Type of
Data:`, the text dendrogram (`Text_Dendrogram` in `Tools/G1Tools/Udendro.pas`), a
MOCA table, a cluster-sizes-as-proportion-of-N table, and saves a partition
indicator matrix whose column labels are `<j>(<k>)<level>`.

Three places where UCINET and borgworld differ on the same computation:

- **Linkage naming.** UCINET's default is `WTD_AVERAGE (average between all
  pairs)`, which is `avgcomp(x,y,s1,s2) = (x*s1 + y*s2)/(s1+s2)` — size-weighted,
  i.e. **UPGMA**, i.e. R's `hclust(method = "average")`. They agree. Its
  `SIMPLE_AVERAGE` is `(x+y)/2` = R's `"mcquitty"` = WPGMA, which the decided
  signature does not offer. Note that UCINET's adjective is the opposite way
  round from R's folklore ("weighted average" is the *unweighted* pair-group
  method); the help page should say so once so nobody re-derives the confusion.
- **Levels vs steps.** `Johnson2` records a new partition **only when the merge
  distance changes** (`if dist <> lastd then inc(npart)`), so tied merges collapse
  into one level and UCINET's table has one row per *distinct level*. borgworld's
  has one column per *merge step*. On data with ties — which binary network data
  always has — the two tables have different widths.

** we should follow standard practice. if ucinet disagrees, we will fix ucinet.

- **Tie-breaking.** `GetClosestPair` scans `i = 2..n` outer, `j = 1..i-1` inner
  over the still-active list in original index order and replaces only on a strict
  `>` / `<`, so among tied pairs the first one reached wins. `hclust` has its own
  rule. Documented difference (Q6, Q7).

**Proposed `xucinet_output`:**

| slot | contents |
|---|---|
| `$nodes` | the partition-by-level table, **collapsed to distinct levels as UCINET does**, one column per level, column names `L(k) <level>` in UCINET's own spelling, plus a `Cluster` column when `k` is given (Q12) |
| `$summary` | `Cophenetic correlation`, `Levels`, `Method`, `Type` |
| `$matrices$"Cluster Adequacy (MOCA)"` | the `bmoca` table, if we keep it (Q8) |
| `$matrices$"Cluster sizes"` | proportions, as UCINET's `handlesizes` — cheap, and it is in UCINET's report |
| `$hclust` | the raw `hclust` object, so `cutree()`, `as.dendrogram()` and everything downstream still work |
| `$assumptions` | type; the conversion; symmetrization if the input was asymmetric |

`print()` shows the header block, assumptions, the **text cluster diagram**, then
the level table, then MOCA and sizes, then `$summary`.

**Which text diagram?** Recommend **UCINET's layout, not borgworld's**, as a new
`cat_uci_dendrogram()` beside `cat_uci_matrix()` in `R/output.R`. This is the one
place I would not carry borgworld's code across, and the reason is the same one
that governed chapter 9: the *method* is ported, the *report* is UCINET's.
Concretely UCINET's has a title line, the level column sized to the widest level
label rather than a fixed `%6.1f`, decimals chosen from the level magnitudes
(`getdd` in `XCluster.pas`: 4 dp below 1, 3 below 10, 2 below 100, 1 below 1000,
0 if the levels are whole), numbered column-index header rows for n > 9, and item
ordering from `GetBestPermOfHiClus` (`Tools/G1Tools/utextdendrogram.pas`) rather
than `hclust$order`. borgworld's version is recognisably the same picture drawn
looser. If you would rather ship borgworld's and tighten it when the goldens
land, say so and it becomes a ledger entry instead.

### 4d. `xcorrespondence` — from `bcorresp`

**Computes** (`R/b_corresp.R` lines 169–283), and this part is textbook-clean:

```
N  = sum(X);  P = X/N
r  = rowSums(P);  c = colSums(P);  E = r c'
S  = diag(1/sqrt(r)) (P − E) diag(1/sqrt(c))       # standardized residuals
svd(S) → u, d, v
eigenvalues        = d^2                            # principal inertias
row.coords         = diag(1/sqrt(r)) u[,1:k] %*% diag(d[1:k])   # principal
col.coords         = diag(1/sqrt(c)) v[,1:k] %*% diag(d[1:k])   # principal
chi2               = N * total.inertia,  df = (nr−1)(nc−1)
```

plus contributions, `cos2`, and per-row/column inertias.

**This matches UCINET exactly on the parts that matter.** `Xcorresp.pas`'s
`handlemarginals` builds the same `S`, and its default `How to scale row and col
scores = Coordinates` applies `transf = sing * x / mass` with `mass = sqrt(r_i)`
— principal coordinates for both margins, the same symmetric map. So the numbers
should agree to floating point, up to axis signs.

**Where they differ is the printed eigenvalue table**, and it is worth
understanding before choosing:

- UCINET prints a table headed `SINGULAR VALUES` with columns
  `FACTOR VALUE PERCENT CUM % RATIO PRE CUM PRE`, where `VALUE` is the **singular
  value** `d` and `PERCENT` is its share of **Σd**, not of Σd². (`PrintEigenvaluesPre`
  in `Xcorresp.pas`; `usepre` is a hard-coded `true`, so the PRE columns always
  appear.)
- borgworld prints `Eigenvalue` = `d²` with `Var(%)` = share of **Σd²** = share of
  total inertia.

**Recommend borgworld's.** Percent-of-inertia is what "variance explained" means
in CA everywhere else, it is what `ca::ca` and FactoMineR report, and a share of
Σd has no interpretation. Print both columns and let the reader see the
relationship: `Singular value`, `Inertia`, `Percent`, `Cumulative`. Ledger entry.

** I agree. another instance where ucinet needs to be changed

**Proposed `xucinet_output`:**

| slot | contents |
|---|---|
| `$nodes` | **row** scores, `Dim1 … Dimk`, original row order |
| `$matrices$"Column Scores"` | column scores, original column order |
| `$matrices$"Singular Values"` | `Singular value`, `Inertia`, `Percent`, `Cumulative` |
| `$matrices$"Row Contributions"`, `"Column Contributions"` | the `contrib` tables |
| `$summary` | `Total inertia`, `Chi-square`, `df`, `p-value` |
| `$assumptions` | dimensions kept; anything dropped or replaced (Q11) |

`$nodes` can only hold one node set and CA has two, so rows go in `$nodes` and
columns in `$matrices`; `print()` renders them as consecutive titled sections
`Row Scores` and `Column Scores`, which is what UCINET does
(`u.displayasmatrix` then `v.displayasmatrix`, both at width 7 and 3 dp).
Recommend leaving `cos2` out of the printed report and keeping it in the object —
UCINET does not print it and the report is long enough.

---

## 5. Plotting

**Question.** borgworld's plots are base graphics. What did we settle for `xplot`
(SPEC D13)? Do these move to it? `plot = TRUE` must survive non-interactive
rendering.

**State of play, factually:** SPEC D13 proposes
`xplot(net, node_color =, node_size =, edge_width =, layout =, interactive =)`
on a **ggraph** backend, with visNetwork when `interactive = TRUE`. It is
**PROPOSED, not agreed**, `xplot()` does not exist, there is no plotting code
anywhere in `R/`, and `ggplot2`/`ggraph` are in neither `Imports` nor `Suggests`.
Chapter 6 is therefore the first thing in the package that draws anything.

Also factually: **`bcorresp`'s plots are ggplot2, not base graphics** — ggplot2
is the preferred path and there is a complete base-R fallback behind
`requireNamespace()`. The MDS and dendrogram plots are base.

**Recommendation — base graphics for chapter 6, and D13 should be narrowed.**

** agreed

`xplot()` as specced is a *network* drawing function: nodes, edges, layouts,
spring embedding. None of chapter 6 draws a network. An MDS map, a CA biplot and
a dendrogram are ordinary statistical graphics that happen to have labels, and
routing them through a ggraph-based network plotter would be forcing them into
the wrong tool. Recommend:

1. **Keep base graphics** for all four chapter 6 plots. That means no new
   dependency at all, `plot = TRUE` works on a bare R install, and the book's
   figures render identically under `Rscript`, RStudio and knitr.
2. **Share one internal drawing routine** so they *do* look alike:
   `plot_coords(coords, labels, main, sub, groups = NULL)`, a tightened version
   of borgworld's `bplotcoord()` (`R/b_plotcoord.R`, which already does smart
   label positioning). `xmds` and `xcorrespondence` both call it; the CA biplot
   passes rows and columns as two `groups`. That gets the cross-chapter
   consistency you want without a framework.
3. **Add `asp = 1`.** borgworld's MDS plot does not set it, so the axes are
   scaled independently and the map is stretched. In an MDS plot the distances
   *are* the result, so unequal axis scaling is not a style choice, it is a wrong
   picture. UCINET agrees — its scatterplot viewer is opened with
   `puniformaxes.checked := true` in all three routines. This is a small
   deliberate improvement on borgworld; ledger entry.
4. **Narrow SPEC D13** to say: `xplot()` is for networks and is ggraph-backed
   when it lands; measure and scaling plots are base graphics via
   `plot_coords()`. Otherwise D13 reads as a promise that chapter 6 breaks.

** yes

**Non-interactive safety.** Base graphics need no guard — `plot()` writes to
whatever device is current, and knitr supplies one. Three things do need doing:

- `plot_graphical_dendrogram()` calls `par(no.readonly = TRUE)` and restores on
  exit inside a `try()`. Keep the restore, drop the `try()`, and set only `mar`.
- Return the result **invisibly from the plotting branch** so a chunk with
  `plot = TRUE` does not also dump the report unless the user asked.
- `xmds(..., plot = TRUE)` with `dim = 1` currently draws nothing silently
  (`if (plot && dim >= 2)`). Make it draw a 1-D strip, or say so in a message.

---

## 6. Acceptance criteria

Two oracles, and they answer different questions. **borgworld** answers "is the
port faithful"; **UCINET** answers "do we agree with the program we are the twin
of". Where UCINET has no counterpart, `stats` does.

### Tolerances

| comparison | tolerance | why |
|---|---|---|
| xucinet vs borgworld | `1e-12` | identical arithmetic on identical inputs; anything looser hides a transcription error |
| xucinet vs UCINET, values | `1e-6` | UCINET stores results as `single`, so ~1e-7 relative is the floor; the existing chapter 9 tests use 1e-5/1e-6 |
| xucinet vs `stats::cmdscale` | `1e-10` | same function, so this only checks the wrapper |
| non-metric stress vs UCINET | `0.02` absolute, one-sided | different algorithm; see below |

### Per routine

**`xhclust`** — exact match to UCINET's merge levels and partitions.

- Fixtures via the CLI: `hiclus()` **is** a command-language keyword
  (`'hiclus|jhc|johnson'` in `Xdpfunc.pas`), syntax
  `<out> = hiclus(<proximitymat> [WTAVG|min|max|avg] [SIM|dissim])`, and it writes
  the partition matrix as a dataset with column labels `L(<k>)<level>`. So levels
  *and* partitions both come back in one `##h`/`##d` pair and
  `golden_matrix()` reads them as they stand. No new helper needed.
- Two things to compare separately: the **level vector**, parsed out of the column
  labels, at 1e-6; and the **partition matrix**, compared as a set partition per
  column, not by cluster id — `renumber` and our own numbering could agree on the
  grouping and disagree on the labels. New helper: `expect_same_partition(a, b)`,
  which compares `outer(a, a, "==")` against `outer(b, b, "==")`. Cheap and
  exactly the right invariant.
- **Watch the CLI/menu split.** The CLI's `hiclus()` defaults `sim = TRUE` and
  symmetrizes an asymmetric matrix with `sy_sum`; the menu form defaults to
  *Dissimilarities* (`simtype: integer = 1` in `XCluster.pas`) and symmetrizes by
  averaging. Same routine, three different defaults. Generate fixtures with `sim`
  and `dissim` both stated explicitly, on symmetric inputs, so neither default is
  load-bearing. This is the same trap as the degree CLI/menu disagreement already
  in `dev/UCINET-ISSUES.md`, and it probably deserves its own entry there.
- **Tie-breaking is where this will first fail.** UCINET takes the first tied pair
  in original index order; `hclust` does not. Recommend: run the comparison on
  `cities` (real-valued road distances, no ties) as the strict test, and on a
  binary network as the tie test, and if the tie test disagrees, record *which*
  merges differ rather than loosening the test. A difference in merge order that
  leaves the level vector identical is cosmetic; one that changes a level is not.

**`xmds(method = "nonmetric")`** — stress within tolerance, configuration by
Procrustes.

- UCINET's non-metric MDS is **MINISSA** (Guttman–Lingoes), not Kruskal:
  `xmds3.pas` → `Minissa` in `Tools/G2Tools/ug2minissa.pas`, which alternates a
  rank-image phase (`Image2`) and a monotone-regression phase (`Fit2`), starts
  from TORSCA by default, and stops on `crit = 5e-4` / `lastit = 50`. `isoMDS` is
  Kruskal's, monotone regression only, classical start. The loss function is
  nominally the same — `Loss` computes `sqrt(Σ(d−dhat)²/Σd²)` over pairs, which
  is stress formula 1 — but the two will land in different local optima on any
  data with real structure.
- So: compare stress **one-sided at 0.02** — `expect_lte(ours, theirs + 0.02)` —
  and treat a *lower* stress as a pass, not a failure. A solution that fits better
  is not a defect.
- Compare configurations after **Procrustes**. New helper in
  `helper-goldens.R`:

  ```r
  # Optimal rotation + reflection + translation + scaling of A onto B, then the
  # residual as a proportion of B's total sum of squares. Orthogonal Procrustes:
  # centre both, svd(t(Bc) %*% Ac), R = V t(U).
  procrustes_rss <- function(a, b) { ... }
  expect_procrustes_equal <- function(a, b, tolerance = 0.05, info = NULL)
  ```

  and set the threshold at **0.05** of total sum of squares — tight enough to
  catch a genuinely different configuration, loose enough to survive two
  algorithms reaching the same shape by different routes. If it fails, the
  outcome is a ledger entry naming the dataset, not a widened tolerance.
- Also test **against borgworld at 1e-12**, which is the test that actually keeps
  the port honest, and needs no seed (see 4b: the start is classical, so there is
  no RNG).

**`xmds(method = "classical")`** — no UCINET oracle worth using.

UCINET's `Classic MDS` menu item and its `classicmds()` CLI function do exist, but
they preprocess first: `preprocess` in `Xmmds.pas` rescales the matrix to [0,1]
by `(x − min)/range` over the **whole** matrix, and `ted()` in `ummds.pas` then
adds the largest triangle-inequality violation to **every cell including the
diagonal**. Neither is standard Torgerson scaling and neither is what borgworld
does, so a fixture comparison would be measuring the preprocessing, not the
method. Test instead:

- against `stats::cmdscale(as.matrix(cities), k = 2)` at 1e-10 — `cities` is
  9 × 9 road distances, is already shipped, and is the book's own worked example
  for sections 6.2/6.4/6.6, so it is the right test data on every count;
- against borgworld at 1e-12;
- and one structural check: on a matrix of Euclidean distances computed from a
  known 2-D configuration, `xmds` must recover that configuration to 1e-10 after
  Procrustes, and the third eigenvalue must be ~0. That is the "known exact
  solution" test, and it is stronger than any fixture.
** yes

**`xcorrespondence`** — scores up to sign, inertias at 1e-6.

- No CLI keyword: `fcorresp` is absent from `Xdpfunc.pas`, so fixtures come from
  the menu run, which already writes `CorrespondenceRScores`,
  `CorrespondenceCScores`, `CorrespondenceEigen` and `CorrespondenceRCScores` as
  datasets. Good enough — the goldens README's "results are datasets, not scraped
  text" rule holds.
- **Sign is not free.** Both programs post-process signs and they do it
  differently. UCINET's `fixnegatives` flips a whole score matrix when *every*
  entry of column 1 is negative, and `forceagreement` flips V when the matrix is
  square and `|u| = |v|` with opposite signs. `svd()` gives whatever LAPACK gives.
  So compare column by column with a sign-invariant helper:

  ```r
  expect_equal_up_to_sign <- function(a, b, tolerance = 1e-6, info = NULL)
    # per column: expect_equal(a[,j], b[,j]) OR expect_equal(a[,j], -b[,j])
  ```

  Per *column*, not per matrix: axis 1 can match and axis 2 be flipped, and a
  whole-matrix comparison would miss it.
- **Inertias at 1e-6, but read the right column.** UCINET's `Singular Values`
  table holds `d`, not `d²`. Square it before comparing, and pin that in the test
  with a comment, because it will otherwise look like a factor-of-something bug.
- Run it on `davis` (18 × 14, 2-mode, already in the goldens battery) and on a
  small square table, since `forceagreement` only fires when `nrow == ncol`.

### Fixture housekeeping

New folder `inst/goldens/ch06/` with its own `make_goldens.txt`, its own
`UCINET-VERSION` (currently `6.849`, matching `Config/ucinet/reference`), and the
session log saved beside it per the README. Inputs: `cities` (the book's own),
`davis`, and one small binary network for the tie case. `skip_if_no_golden()`
means the tests can be committed before the batch is run.

---

## 7. First differences-ledger entries

`inst/DIFFERENCES.md` currently has five entries; the vignette renders it. Six
new ones, numbered 6–11:

**6. Metric MDS is not offered.** UCINET's `Tools | Scaling/Decomposition` has
three items — *Classic MDS*, *Metric MDS*, *Non-metric MDS* — and its Metric MDS
minimizes stress by per-point Nelder–Mead simplex (`metricmds` in
`Tools/G1Tools/ummds.pas`, `maxit = 100`, convergence at 5e-8), after rescaling
the data to [0,1] and adding a triangle-inequality constant. `xmds()` offers
`classical` and `nonmetric` only. Reason: iterative metric MDS is the option
nobody in the literature asks for — classical scaling answers the metric question
in closed form and non-metric answers the ordinal one — and reproducing UCINET's
particular simplex would be reproducing an implementation rather than a method.
Users wanting it stay in UCINET.

**7. `type` is required.** UCINET's dialogs default the
Similarities/Dissimilarities control (Metric MDS to *Similarities*, Johnson's
menu form to *Dissimilarities*, the `hiclus()` CLI to *similarities* — three
defaults for the same question in one program, which is itself the argument).
`xmds()` and `xhclust()` require it. Reason in Q2/Q3.

**8. MDS orientation and CA axis signs may differ.** An MDS configuration is
determined only up to rotation, reflection and translation, and CA axes only up to
sign; UCINET, borgworld and xucinet each fix them differently (UCINET's
`fixnegatives`/`forceagreement`, ours whatever LAPACK returns). A map that looks
mirror-imaged against UCINET's is the same map. Say this in the entry *and* in
both help pages, because it is the single most likely "the numbers don't match"
support question in the chapter.

**9. Classical MDS stress uses the standard denominator.** xucinet reports
Kruskal stress formula 1 with Σ(data)² in the denominator; UCINET's `stressform1`
uses Σ(configuration distance)². The two coincide only at perfect fit. Ours keeps
classical and non-metric stress on one scale and matches the textbook definition.

**10. Correspondence analysis reports inertia, not singular values.** UCINET's
table is headed `SINGULAR VALUES` and its `PERCENT` column is a share of the sum
of the singular values; xucinet reports the principal inertias `d²` and a share of
total inertia, which is what "variance explained" means in CA. Both columns are
printed so the relationship is visible.

**11. Johnson's clustering: level collapsing and tie-breaking.** Two sub-points
in one entry. (a) UCINET records one partition per *distinct* merge level, so
tied merges collapse; `hclust` gives one per merge step. xucinet follows UCINET
and collapses. (b) Where merge distances tie, UCINET takes the first pair in
original index order and `hclust` uses its own rule, so the two can produce
different — equally correct — merge orders at the same levels. Named datasets
where this happens go in the entry as they are found.

Plus, if the `asp = 1` decision in Q5 is taken, a short note that MDS and CA plots
use equal axis scaling. That is a difference from borgworld rather than from
UCINET, which suggests the ledger may eventually want a second section — see Q13.

---

## Questions I found that were not on your list

## 8. Does `bmoca` come across?

`bhiclus` calls `bmoca()` and prints its table; UCINET has the same thing twice
(the MOCA block inside Johnson's report, and *Cluster Analysis | Measures of
Clustering Adequacy (MOCA)* as its own menu item). But `bmoca` is 260 lines with
four measures, an O(n²) modularity loop, and a `cluster` dependency, and one of
its measures is questionable: `Gamma` is documented as "Hubert's Gamma" but
computes `sum(prox * same) / length(prox) / (sd(prox) * sd(same))`, which is not
Hubert's Γ (Γ is a concordance count over pairs of pairs) and is not scaled to
[-1, 1].

**Recommendation.** Port `bmoca` in chapter 6 but report only `n_clusters`,
`Corr` and `Silhouette`, dropping `Gamma` and `Modularity` for now. `Corr` is the
one the book uses to pick a level and the one UCINET leads with; `Modularity`
belongs with Phase 2's community detection, where it can be defined once and
tested against UCINET's own; `Gamma` should not ship under that name until it
either is Hubert's Γ or is renamed. Alternatively defer MOCA entirely to its own
`xmoca()` and have `xhclust()` not print it — say which you prefer.

** accept recommendation

## 9. The similarity→dissimilarity conversion is inconsistent, and it matters

`bclassicalmds` and `bnonmetricmds` use `max(x)` over the **whole matrix**;
`bhiclus` sets the diagonal to `NA` first and uses `max(offdiag)`. For a
correlation matrix (diagonal 1) the first gives `d = 1 − r` and the second gives
`d = max(r_offdiag) − r`, which differ by a constant added to every off-diagonal
cell — and classical MDS is *not* invariant to that constant. The same data gives
two different maps depending on which borgworld function you call.

**Recommendation — one rule, and it should be the off-diagonal one.** A
self-similarity is conventional (1 for correlations, n for co-membership counts,
whatever the diagonal happens to hold for a network) and letting it set the
maximum lets an arbitrary convention shift every distance. Use `max` over the
off-diagonal everywhere, document it in one place, and record the change from
`bclassicalmds`/`bnonmetricmds` as a port note. This is a deliberate departure
from borgworld's numbers for similarity input to the two MDS methods, so it needs
your explicit yes — it means `xmds(cor_mat, "s")` will not reproduce
`bclassicalmds(cor_mat, "s")`.

** yes

(For dissimilarity input, and for `cities`, nothing changes.)

## 10. What exactly does `xmds(method = "nonmetric", plot = TRUE)` draw?

Per 4b, `bnonmetricmds` draws the configuration and `shepard.bnmds` is never
called. Three options:

1. **Configuration only**, and a separate `xshepard(result)` for the diagnostic.
2. **Both**, side by side via `par(mfrow = c(1, 2))`.
3. **Both**, sequentially, so knitr emits two figures.

**Recommendation: (1).** One call, one figure is the convention everywhere else
in the package, and a chunk that silently emits two plots is annoying in a book.
The Shepard data lives in `$matrices$Shepard` either way (4b), so `xshepard()` is
a three-line function over the result and costs nothing. If your brief meant
"the Shepard plot must be reachable", (1) satisfies it; if it meant "must appear
by default", say so and it becomes (3).

## 11. `xcorrespondence` input constraints

Four behaviours to settle, all of which differ between the two sources:

- **Rows ≥ columns.** UCINET refuses a matrix with more columns than rows
  ("This procedure requires that the input matrix have at least as many rows as
  columns. Please run Data|Transpose first" — `Xcorresp.pas`). borgworld does not
  care and neither does the mathematics. **Recommend: no restriction**, and a
  ledger note. It is a UCINET implementation limit, not a property of CA.
- **Negative values.** borgworld `stop()`s. Correct — CA on negative counts is
  meaningless. Keep, with a better message.
- **`NA`.** borgworld replaces with 0 and warns. UCINET replaces with the
  **overall mean** and warns. These give different answers. **Recommend UCINET's**
  (mean substitution): zero is a real, meaningful count in a contingency table and
  silently inventing zeros distorts the margins, whereas the mean leaves the grand
  total closer to right. Assumption line either way.
- **All-zero rows/columns.** borgworld drops them with a warning. UCINET nudges
  the mass to 0.001 and warns. **Recommend dropping**, as borgworld does — a
  zero-margin category has no profile and no position, and 0.001 puts it somewhere
  arbitrary. Name the dropped labels in `$assumptions`, not just the count.

**And one real bug to fix in the port.** `bcorresp` truncates `eigenvalues` to
`ncp` *before* computing `total_inertia`, so `variance.explained`,
`cumulative.variance` and `chi2` are all computed against a truncated total. With
borgworld's default `ncp = min(nr-1, nc-1)` that is the full rank and nothing goes
wrong, but `xcorrespondence(x, dim = 2)` would hit it every time: total inertia
would be the inertia of the first two axes, "percent explained" would always sum
to 100, and the chi-square would be wrong. **Compute the full spectrum, then keep
`dim` columns of coordinates.** Worth a test of its own — `sum(percent)` must be
< 100 whenever `dim` < rank.

## 12. What does `k =` do in `xhclust`?

`bhiclus` has no `k`. Options: (a) add a `Cluster` column to `$nodes` holding
`cutree(hc, k)`; (b) print only that level of the diagram; (c) both.

**Recommendation: (a).** The level table is the routine's output and should not
change shape because the user asked about one level; `k` adds a column and one
`$summary` line (`Clusters requested: 3`), and `$nodes$Cluster` is then directly
usable as `xplot(net, node_color = xhclust(...)$nodes$Cluster)` — which is the
reason to have `k` at all. Note that `k` may be unattainable exactly when levels
are tied, in which case `cutree` returns the nearest; that should be an assumption
line, not an error.

## 13. Two argument-vocabulary points that need a SPEC addendum

Small, but they are exactly the kind of thing chapter 9 established by writing it
down, and leaving them unwritten means re-arguing them in chapter 7.

- **`x`, not `net`.** SPEC D4 says "First argument is always the network" and
  names it `net`; the chapter 6 signatures use `x`. That is right — these take a
  proximity matrix, which is often not a network at all (`cities` is road
  mileage), and calling it `net` would mislead. Recommend an addendum sentence:
  *routines whose input is a proximity matrix rather than a network name their
  first argument `x`; everything else about D4, including the
  `xnet(x, substitute(x))` first line, is unchanged.*
- **`type`, `dim`, `k`, `method`, `labels` are new vocabulary.** D4 fixes a
  vocabulary and these are not in it. Recommend adding them to the D4 table with
  their chapter 6 meanings, so that Phase 3's blockmodelling routines inherit
  `k` and `method` rather than inventing `nclusters` and `linkage`.
- **`save =` is missing from all three signatures.** D4 lists it as the standard
  way to write results out as UCINET datasets. Recommend adding it, defaulting to
  `NULL`, writing coordinates for `xmds`, row/column scores for
  `xcorrespondence` and the partition matrix for `xhclust` — which is exactly
  what each UCINET routine saves.

---

## Summary of what I need from you

| # | question | my recommendation |
|---|---|---|
| 1 | port or depend | copy, cite commit, vendor sources; `MASS` → Imports; drop ggplot2 | steve:agree
| 2 | input types | matrix, `dist`, `xucinet`; teach `as_xucinet()` about `dist`; never infer `type` | steve:agree
| 3 | missing `type` | `stop()` with both values glossed | steve:agree
| 4 | output object | tables as laid out above; UCINET's report layout, borgworld's numbers | steve:agree
| 5 | plotting | base graphics via a shared `plot_coords()`; add `asp = 1`; narrow D13 | steve:agree
| 6 | acceptance | borgworld at 1e-12, UCINET at 1e-6, Procrustes at 0.05 RSS, stress one-sided at 0.02 | steve:agree
| 7 | ledger | six entries, 6–11 | steve:agree
| 8 | `bmoca` | port, but report `n_clusters`/`Corr`/`Silhouette` only | steve:agree
| 9 | sim→dissim `max` | off-diagonal everywhere — **changes borgworld's numbers, needs your yes** | steve:agree
| 10 | Shepard plot | configuration by default, `xshepard()` for the diagnostic | steve:agree
| 11 | CA input rules | no row≥col limit; mean-substitute `NA`; drop zero margins; **fix the truncated-inertia bug** | steve:agree
| 12 | `k =` | adds a `Cluster` column, does not change the table | steve:agree
| 13 | SPEC addendum | `x` for proximity input; add `type`/`dim`/`k`/`method`/`labels` to D4; add `save =` | steve:agree

The ones that actually block coding are **9** (it changes numbers), **11** (it
changes numbers), **4c** (which text dendrogram) and **8** (whether MOCA ships).
The rest can be settled while the port is being written.
