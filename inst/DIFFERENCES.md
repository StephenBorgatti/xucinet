# Differences from UCINET

Every place xucinet knowingly departs from UCINET, or matches something in
UCINET that is itself under review. Rendered as the differences vignette rather
than restated there, so the ledger has one home.

Entries are added when a golden test forces the question, so the list is short
by construction: if a difference is not here, the goldens say the two agree.

**An entry lives only as long as the difference does.** When UCINET adopts our
behaviour, the entry is *removed* rather than reworded, the fixtures are
regenerated from the build that fixed it, and xucinet follows UCINET with no
option to keep the old way. The history is not lost — it moves to the UCINET
issue list kept in the development repository, which never deletes anything,
because the old behaviour is still in every earlier build.

**"UCINET fix pending"** on an entry means the difference is one UCINET has
agreed to close. Until it does, xucinet implements the behaviour we think is
correct rather than reproducing a known bug, and the test that covers it is
marked as expected to differ from UCINET below the fixing version.

The build all of this is measured against is declared in DESCRIPTION as
`Config/ucinet/reference`, and each folder of golden fixtures records the build
that produced it. The test suite fails if the two disagree.

---

## 1. A truncated DL file

**Status:** deliberate difference — **UCINET fix pending** (scheduled for
UCINET 6.850). We refuse; UCINET accepts.
**Checked:** 6 September 2026, confirmed independently 7 September 2026.

`krebs.txt`, in UCINET's own `Datafiles`, declares `N=56, NM=5` — 280 rows of 56
values — and holds 278 full rows plus a partial row of 12: 15,580 values where
15,680 are needed. xucinet refuses it, naming both counts.

The same data survives complete as an `.rda` in the `zalmquist/networkdata`
package, and it settles the question: all five relations are 56 x 56, every
value the DL file does contain agrees with it, and the file stops at row 55,
column 13 of the fifth matrix. So the declaration is right, our parser is right,
and the file is short by its last row and a half.

UCINET does not refuse it. `importfullmatrix` in `udlm.pas` runs

```pascal
for i:= 1 to m.nr do begin
  ...
  for j:= 1 to m.nc do if diagonal or (i<>j) then m.fput(i,j,fread(f));
  end;
```

with no end-of-file guard and no comparison against the number of values
actually present, and `fread` in `UtFile.pas` swallows the IO error at end of
file:

```pascal
{$i-} read(f,x); {$i+}
if ioresult = 0 then fread:= x else fread:= bna;
```

`bna` is 1e38, the missing-value marker. So the file imports without complaint
and the tail of the data comes back all-missing. Anything ever computed from
`krebs.txt` was computed on a partly-missing matrix.

Refusing is the correct behaviour — a short matrix that looks complete is worse
than an error — so xucinet refuses, and will go on refusing after UCINET starts
refusing too. At that point this entry is removed.

---

## 2. Two extra average-degree lines for 2-mode data

**Status:** deliberate addition. Not a disagreement about any number.
**Decided:** Steve, 6 September 2026; narrowed 7 September 2026.

For 2-mode data `xdensity()` prints UCINET's `Avg Degree` and then two more
lines, `Avg Degree (rows)` and `Avg Degree (cols)`. For davis, 18 women by 14
events and 89 attendances, that is 2.781, 4.944 and 6.357.

UCINET's own figure is the first of the three and we match it exactly. The other
two are an addition: "attendances per woman" and "attendances per event" are
what a reader of a 2-mode table wants, and neither is recoverable from 89/32
without knowing both margins. Square networks are unaffected — one line, ties
over n, as always.

*The denominator itself is no longer a difference.* UCINET used to divide by the
column count alone and now divides by the nodes of both modes, which is what we
argued for; that entry has been removed under the rule at the top of this file.
The history is in the UCINET issue list.

---

## 3. Standard deviation: not a difference, but worth recording

UCINET reports the **population** standard deviation: `uestimator.calc` in
`ustats.pas` sets `variance := mcssq/n`, not `mcssq/(n-1)`. R's `sd()` divides
by n-1, so an R-native implementation is quietly wrong against UCINET.

We had this bug. UCINET's own Density report for campnet prints 0.381 where
`stats::sd()` gives 0.382. Fixed, and the difference is now pinned by a test, so
this is recorded as a trap rather than as a divergence.

---

## 4. Node tables always carry every column

**Status:** deliberate simplification — **UCINET fix pending** for the
centralization half of it.
**Decided:** Steve, 6 September 2026.

UCINET builds a centrality table conditionally. In `uc_DegreeCentrality.pas` the
raw columns are written only if *Output raw totals* is ticked and the normalized
ones only if *Output averages (normalized)* is:

```pascal
if raw.Checked then begin store; runcentralization; end;
if normalized.checked then begin ... store('n'); end;
```

So the four-column table a directed network usually produces — `Outdeg`,
`Indeg`, `nOutdeg`, `nIndeg` — is the default tick state rather than a fixed
shape, and unticking one box changes the columns underneath the user.

xucinet always emits all four. `normalize` selects which column is read as the
primary value; it does not change the shape of `$nodes`. The reason is that
`$nodes` is a data frame people index by name and bind into other frames, and a
table whose columns appear and disappear with an argument is a poor thing to
compute on. The cost is that a user who wants exactly UCINET's two-column output
has a column to drop.

The headings themselves are UCINET's own, unchanged: `Degree`, `Outdeg`,
`Indeg`, and the same again under `store('n')` as `nDegree`, `nOutdeg`,
`nIndeg`.

The **fix pending** half is narrower. Because `runcentralization` sits inside the
raw-totals branch, unticking a display preference silently empties the graph
centralization matrix. xucinet computes centralization whenever UCINET has one
for the measure, regardless of which columns are printed. When UCINET does the
same, that paragraph goes and the rest of this entry stays.

---

## 5. The centrality suite reports closeness, not farness

**Status:** deliberate difference — **UCINET fix pending**.
**Found:** 7 September 2026, writing `xcentrality()` against `G9_MC_ISO`.

UCINET's `mcent()` labels a column **Closeness** and fills it with the total
geodesic distance from each node, unreachable pairs counted as `n`. That is
*farness*: bigger means further away, so the column runs in the opposite
direction to its own name, and to the Closeness routine one menu item above it.
For `g9_iso` it reports 47, 42, 43 where `xcloseness()` reports 0.191, 0.214,
0.209.

`xcentrality()` puts `xcloseness()`'s Freeman score in that column, because
chapter 9 decision 7 says every column is computed by the individual routine so
that the suite and the single-measure functions cannot disagree. Following
UCINET here would mean the suite contradicting `xcloseness()` on the same data
under the same heading.

The same applies to **BetaCent**: `mcent()` normalizes it differently from the
Beta Centrality dialog, so the two UCINET routines disagree with each other. We
follow the dialog, which is the documented measure.

*UCINET catch-up: rename the column to Farness, or divide into it. Either fixes
the direction; the name and the number currently disagree.*

---

## 6. Metric MDS is not offered

**Status:** deliberate omission. Decided 8 September 2026; recorded 18 September 2026.

UCINET's *Tools | Scaling/Decomposition* has three MDS items: *Classic MDS*,
*Metric MDS* and *Non-metric MDS*. Its Metric MDS minimizes stress by a per-point
Nelder-Mead simplex (`metricmds` in `Tools/G1Tools/ummds.pas`) after rescaling
the data to [0, 1] and adding a triangle-inequality constant. `xmds()` offers
`classical` and `nonmetric` only. Classical scaling answers the metric question
in closed form and non-metric scaling answers the ordinal one; reproducing
UCINET's particular simplex would reproduce an implementation rather than a
method. A reader who needs UCINET's metric MDS numbers runs UCINET.

Note also that UCINET's *Classic MDS* preprocesses the matrix (rescaling and the
triangle constant, `preprocess` in `Xmmds.pas`) before Torgerson scaling, so its
coordinates differ from `xmds(method = "classical")`, which is `stats::cmdscale()`
on the dissimilarities as given. There is no golden for classical MDS for this
reason; it is tested against `cmdscale()`, against a known exact configuration
and against borgworld.

## 7. `type =` is required

**Status:** deliberate difference. Decided 8 September 2026.

UCINET's dialogs default the *Similarities / Dissimilarities* control, and not
consistently: Metric MDS to *Similarities*, Johnson's menu form to
*Dissimilarities*, the `hiclus()` command to *similarities*. `xmds()` and
`xhclust()` have no default and stop with a message naming both values. A
matrix of 0/1 ties, a matrix of geodesic distances and a matrix of
co-membership counts have the same shape, and a guess that is wrong one time in
ten comes back as a plausible map that is inside out.

## 8. MDS orientation and correspondence-analysis axis signs

**Status:** not a difference in results, but the most likely "the numbers don't
match" question in chapter 6. Recorded 18 September 2026.

An MDS configuration is determined only up to rotation, reflection and
translation; a correspondence-analysis axis only up to sign. UCINET, borgworld
and xucinet each fix them differently: UCINET's `fixnegatives` and
`forceagreement` in `Xcorresp.pas` flip score matrices by rule, `svd()` and
`cmdscale()` return whatever LAPACK returns. A map that looks rotated or
mirror-imaged against UCINET's is the same map. The goldens are compared after
Procrustes alignment (MDS) or column by column up to sign (CA), and both help
pages say so.

## 9. Stress denominators

**Status:** deliberate difference. Decided 18 September 2026 (design question 4a).

`xmds()` reports Kruskal's stress formula 1 with the sum of squared *data* in
the denominator, for both methods, so that a classical and a non-metric
solution of the same matrix are on one scale. UCINET's `stressform1` in
`ummds.pas` divides by the sum of squared *configuration distances*. The two
agree only at perfect fit. UCINET's non-metric routine is MINISSA
(Guttman-Lingoes), not Kruskal's algorithm, so its stress is also reached by a
different route; the golden test accepts our stress if it is within 0.02 of
UCINET's or lower.

## 10. Correspondence analysis reports inertia, not a share of singular values

**Status:** deliberate difference in the printed table; the scores agree.
Decided 18 September 2026 (design question 4d).

UCINET's table is headed `SINGULAR VALUES` and its `PERCENT` column is each
singular value's share of the *sum of singular values*. `xcorrespondence()`
prints the singular value, its square (the principal inertia) and the share of
*total inertia*, which is what "variance explained" means in correspondence
analysis elsewhere. To compare with UCINET's `VALUE` column, read our
`Singular value` column; the `PERCENT` columns are not comparable.

UCINET also refuses a table with more columns than rows ("run Data|Transpose
first"). That is an implementation limit, not a property of the method;
`xcorrespondence()` accepts either shape.

## 11. Johnson's clustering: level collapsing and tie-breaking

**Status:** (a) matched; (b) documented difference. Recorded 18 September 2026.

(a) UCINET's `Johnson2` (`Tools/G1Tools/Uclus.pas`) records a new partition
only when the merge distance changes, so tied merges collapse into one level.
`xhclust()` does the same, which is why its partition table can have fewer
than `n - 1` columns and why it differs from `hclust()`'s one-per-step view
(and from borgworld's `bhiclus`, which follows `hclust()`).

(b) Where merge distances tie, `GetClosestPair` takes the first tied pair in
original index order and `stats::hclust()` uses its own rule. The merge
*levels* are the same either way; the *partitions* at a tied level can differ,
and both are correct. Datasets on which this happens are listed here as the
goldens find them: none yet (the batch has not been run).

Two smaller notes. `Corr` in the cluster-adequacy table is signed so that
higher is better for both input types; for dissimilarity input UCINET prints
the raw correlation, which is the same number with the opposite sign. And
UCINET's table carries `Q`, `Q-prime` and `E-I` beside `Corr`; ours carries
`Modularity` (UCINET's `Q`, same formula) and `Silhouette`, and omits
`Q-prime` and `E-I` until the community-detection routines define them once.

## 12. Plots use equal axis scaling

**Status:** a difference from borgworld, not from UCINET. Decided 18 September
2026 (design question 5).

The MDS and correspondence-analysis maps are drawn with `asp = 1`. In a scaling
plot the distances are the result, so unequal axis scaling is a wrong picture,
not a style choice; UCINET's scatterplot viewer sets uniform axes for the same
reason. borgworld's `bclassicalmds` and `bnonmetricmds` plots do not.

## 13. Dichotomize: the diagonal follows the menu form, not the CLI

**Status:** a choice between two UCINET behaviours. Decided 22 September 2026
(design question 5.1(ii)).

UCINET dichotomizes in two places and they do not agree about the diagonal.

`G2Tools\udichotomize.pas`, the older command-line form, has five operators
(no "not equal"), a hard-wired 1/0 result, and a single boolean `diagok`:
apply the rule to the diagonal or leave the diagonal alone. It is forced on
for a non-square matrix.

`uc_Dichotomize.pas` with `uc_Dichotomize.dfm`, the Transform | Dichotomize
menu form, has six operators, a configurable "then" and "else" value either of
which may be missing, and a five-way `yDiagonals` radio group: set to zero,
set to missing, set to the "then" value, set to the "else" value, or follow
the dichotomization rule. Its `ItemIndex` is 3, so **the default writes the
"else" value on the diagonal**.

`xdichotomize()` follows the menu form, because that is the routine a reader
of the book will use: `diagonal = "else"` is the default and `"rule"` is one
of the five choices. The Phase 0 goldens were made with the command line and
so show the rule applied to the diagonal; a golden regenerated from the menu
will not, which is what `inst/goldens/transform/` is for.

The internal helper the analysis routines call, `dichotomize_matrix()`, keeps
the command-line behaviour unchanged, because that is what `copyfromtmat`
hands to `xdegree()`, `xdensity()` and the rest.

## 14. Dichotomize by density or by correlation are not UCINET batch routines

**Status:** an addition to UCINET. Decided 22 September 2026 (design question
5.1(i)).

`xdichotomize(method = "density")` and `xdichotomize(method = "maxcor")`
choose the cutoff from the data instead of taking one.

Neither is a batch routine in UCINET. There is no density target anywhere in
Transform | Dichotomize. `maxcor` is what Transform | Dichotomize Interactive
(`uc_DichotomizationApp.pas`) does by hand: for every distinct value of the
matrix it dichotomizes at that value and tabulates the value's z-score, its
frequency, the Pearson correlation between the dichotomized matrix and the
original, the number of ones and the density, and the user reads the table and
picks a row. `method = "maxcor"` picks the row with the largest correlation
without asking, and records the cutoff, the density and the correlation in the
result's `history`. The table itself is not exposed; the three numbers in
`history` are what a script needs.

The older command-line form also accepts `mean` as a cutoff, which is a third
way of computing one; it is not offered here, since the menu form has no such
option and `cutoff = mean(as.matrix(net))` says it plainly.

## 15. Random imputation fills only the missing cells

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 15, raised
22 September 2026.

`ximpute(method = "random")` replaces the missing cells and leaves the
observed ties alone, drawing the replacements from the ties that were
actually observed.

UCINET's `runrandom` does neither. Its binary branch has no `isna` test, so it
overwrites every off-diagonal cell with a fresh coin flip and the observed
network is lost. Its valued branch builds the pool it draws from without
checking validity, so a missing cell can be drawn and the result still has
holes. Both are in `G2Tools\uimputemissing.pas`; the other eight methods test
`d.isna(i,j)` before writing.

A known defect is not a number worth matching, so this is one of the places
where xucinet is deliberately not UCINET. When it is fixed, the fixtures are
regenerated and this entry goes.

## 16. Reciprocity treats valued data two ways in one report, as UCINET does

**Status:** reproduced, not corrected. Recorded 22 September 2026.

`xreciprocity()` does not dichotomize, because Network | Cohesion |
Reciprocity does not. It prints

> Data are valued. Remember that xij = 3 will not match xji = 2

and then computes. The consequence is that the two halves of its own report
use different tests:

- the whole-network **Dyad** and **Arc** ratios come from
  `tnodelist.getreciprocity`, which asks `isarc`, i.e. whether the value is
  above zero. A pair `(3, 2)` is reciprocated.
- the **node-level** table comes from `runindividuals`, which tests
  `m.cell[i,j] <> m.cell[j,i]`, equality of the values themselves. The same
  pair `(3, 2)` is non-symmetric.

So a valued network can show an arc reciprocity of 1 above a node table in
which nobody is symmetric. That is what the warning is for, and it is
UCINET's behaviour rather than an oversight here, so the notice is reproduced
in `$assumptions` and spells the consequence out rather than leaving the
reader to find it.

Dichotomizing first would make the report self-consistent and would no longer
be UCINET. Users who want that can pass
`xreciprocity(xdichotomize(net, diagonal = "rule"))`.

Since 23 September 2026 the two halves live in different functions (entry 32):
the ratios in `xreciprocity()`, the node table in `xegoreciprocity()` and its
Symmetric column also in `xegonet()`. The difference in tests is unchanged,
and each function carries the half of the notice that concerns it.

## 17. Structural holes: UCINET's ego-network model, not igraph's constraint

**Status:** deliberate, following UCINET. Recorded 23 September 2026 (issue
#14). SPEC D7 names constraint as a danger zone; this is why.

`xstructuralholes()` defaults to UCINET's *ego network model*, in which
everything is computed inside each node's ego network. `igraph::constraint()`
computes Burt's measure over the whole network. With `z` the tie values and
`S` the set of nodes the proportions are taken over:

    p(i,j) = (z(i,j) + z(j,i)) / sum over k in S of (z(i,k) + z(k,i))
    c(i,j) = (p(i,j) + sum over q of p(i,q) p(q,j))^2
    constraint(i) = sum over i's contacts j of c(i,j)

- **igraph:** `S` is every node, for `p(i,·)` and for `p(q,·)` alike.
- **UCINET, ego-network model (the default here):** `S` is ego's network
  only, so `p(q,j)` for an alter `q` is `q`'s share of its ties *inside ego's
  network*. An alter with many ties outside it looks more exclusively tied to
  ego's other contacts than it is, and constraint comes out higher.
- **UCINET, whole-network model (`method = "whole"`):** `S` is every node, as
  in igraph. On an undirected binary network the two agree to rounding, and the
  test suite asserts that; it also asserts that the default does *not* agree,
  so a silent convergence would be noticed.

Two further conventions differ. UCINET reports constraint as missing for an
ego with one alter (the dialog's *Set pendants to NA*) where the formula gives
1, and igraph returns `NaN` for an isolate where UCINET's dialog gives missing
constraint and effective size 0. Both dialog values are arguments here
(`isolate`, `pendant`).

## 18. Egonet basic measures: an isolate's ratios are missing, not zero

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 17, raised
23 September 2026.

`xegonet()` reports an ego with no alters as having Size, Ties, Pairs and the
other counts 0, and Density, AvgRecipDist, Diameter, CompRatio, ReachEffic,
nBroker and nEgoBetween missing. UCINET reports zeros throughout: its code sets
those values to missing and then jumps past the lines that store them. For an
ego with one alter, AvgRecipDist is missing here and 0 in UCINET, because there
are no pairs to average over.

Matched, though UCINET may itself have it wrong: **nClosed** is the tie count
among alters, as UCINET computes it, although UCINET's footnote describes it
as the number of closed triads, which is half of that on symmetric data.

## 19. Tie composition: the diagonal checkbox, and incoming values under "both"

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issues 18 and 19,
raised 23 September 2026.

- `xtiecomposition(diagonal = TRUE)` counts ties to self. UCINET's *Include
  ties to self* box is never passed to the routine that counts, so it has no
  effect there.
- `xvaluedtiecomposition(ties = "both")` adds the value of each incoming
  tie. UCINET adds the value of the *outgoing* cell for it, which is usually
  zero. The defaults (*Undirected (OR)* for the count, *Outgoing only* for the
  values) are not affected.

## 20. Continuous alter composition: no SD filters, and always nine columns

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 20, raised
23 September 2026.

UCINET's Egonet Alter Composition | Continuous dialog offers to filter out
alters more than a given number of standard deviations above or below the
mean. In the source the filter is never applied, so `xaltercomposition()` has
no arguments for it rather than arguments that would do what UCINET does,
which is nothing.

With *Ignore tie strengths* UCINET's table loses `Num` as well as `WtdNum`;
here `weighting = "none"` keeps all nine columns, `WtdNum` then equalling
`Num`.

## 21. Ego-network routines report the first relation, not every relation

**Status:** deliberate, 23 September 2026 (issue #14).

UCINET's Valued Tie Composition, both Ego-Alter Similarity forms and the
`holes()` command loop over every relation of a multi-relation dataset and
print one table each. `xvaluedtiecomposition()`, `xegoaltersimilarity()`,
`xstructuralholes()`, `xaltercomposition()` and `xegonet()` do what every
xucinet node-level routine does: they use the relation named by `relation`,
the first by default, and say in the report which one it was. Use
`relation =` to pick another. `xtiecomposition()` is the exception, since
comparing the relations is its purpose: it uses them all, as UCINET does.

---

## 22. No node-level clustering coefficient

**Status:** deliberate, 22 September 2026 (design question 10.2); UCINET is to
follow (`dev/UCINET-ISSUES.md` issue 16).

UCINET's Clustering Coefficient routine, under Network | Whole Networks,
reports an overall coefficient, a weighted overall coefficient and a
coefficient for every node. `xtransitivity()` reports the overall
coefficient (the mean of the node values) in its `$summary` and has no node table, and there is no
`xclustering()` export.

Two reasons. A whole-network routine does not return a node table (SPEC
addendum, 23 September 2026). And the node-level coefficient is the density of
ego's neighbourhood, which falls with degree almost mechanically and is
undefined below two neighbours, so a column of it invites a ranking that
mostly reflects degree. For binary data the same number is ego-network density
with ego removed, which is available from the ego-network routines.

## 23. Normalize: Correspondence and SQRT-Marginal under Dimension = Matrix

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 23, raised
23 September 2026.

`xnormalize(method = "correspondence")` divides each cell by the square root of
its row total times its column total, and gives the same result whatever `by`
says, which is what UCINET's `runrowcols` does for Rows, Columns and Both. Under
Dimension = Matrix UCINET's `runmatrix` has no branch for it and returns the
input unchanged. The same is true of SQRT-Marginal: `xnormalize(by = "matrix",
method = "sqrtsum")` divides by the square root of the matrix total, and UCINET
changes nothing.

## 24. Homophily: binary treatment applies to every measure

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 21 (Steve,
23 September 2026).

`xhomophily(weighted = FALSE)` dichotomizes at > 0 before computing anything.
UCINET's Whole Networks | Homophily | Categorical applies its *Treat data as
binary* choice to the mixing matrix only, so there `H`, `h-star`, `Corr`,
`Yules Q` and the `E-I Index` are the same whichever treatment is chosen. With
the default, valued treatment, the two agree.

## 25. Mixing tables skip missing cells

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 25, raised
23 September 2026.

`xmixing()` leaves missing cells out of every table. UCINET's Mixing Tables
tests `val <> na` where a missing cell is stored as a larger number, so each
missing cell is added in as 1e38. On complete data the two agree.

## 26. Mixing Tables is two functions: every model at once, density apart

**Status:** deliberate. Steve, 23 September 2026 (`dev/STATUS.md`, Next
0(e)).

UCINET's Network | Mixing Tables prints four tables per run: the observed
mixing table, the expected table under the one model chosen in the dialog
(Density by default), the density table, and observed over expected. xucinet
divides that report differently, in two ways:

- **`xmixing()` reports all three expected-value models in one call**, with no
  `model` argument: `Observed`, then `Expected (density)`,
  `Expected (configuration)` and `Expected (fixed outdegree)`, then the three
  matching `Ratio` tables. UCINET needs three runs for the same numbers. The
  shape of the result then never depends on an argument (SPEC addendum,
  23 September 2026, rule 4).
- **The density table is not in `xmixing()`.** It is `xdensitybygroups()`'s
  only table, as that function's name says, and the same table
  `xcombinenodes()` gives.

Every number is UCINET's; only the grouping into reports differs.

## 27. Louvain: moves must raise modularity, and each level's Q is its own

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 26 (Steve,
23 September 2026).

`xlouvain()` is a native port of UCINET's Louvain Method: nodes visited in
index order, each candidate move scored by recomputing modularity in full,
levels aggregated until nothing merges. It departs from UCINET in two places,
both bugs in UCINET's `utlouvain.pas`:

- **The move test.** UCINET compares a candidate move with the modularity the
  pass started from, not with the modularity of leaving the node where it is.
  Once earlier moves have raised Q, it can make a move that lowers Q, as long
  as the result still beats the starting value. `xlouvain()` moves a node only
  if the move raises the current Q.
- **The reported Q.** UCINET labels each level with the Q from the last node
  it evaluated, which is not reliably the level's own modularity.
  `xlouvain()` recomputes Q from each level's final partition.

## 28. Fast greedy and label propagation run on igraph

**Status:** deliberate. Design answer G1 and the chapter 11 prompt, 20 and
23 September 2026.

`xfastgreedy()` is `igraph::cluster_fast_greedy()`, Clauset, Newman and
Moore's agglomeration from single nodes. UCINET's own FastGreedy
(`uc_FastGreedy.pas`) starts by default from a partition built from cliques
(*Initial Partition* = Clique-based) and switches to a Louvain variant on
networks of more than 100 nodes, so its partition can differ. With *Initial
Partition* set to Identity, on 100 nodes or fewer, the two should agree.

`xlabelpropagation()` is `igraph::cluster_label_prop()`. Label propagation is
random, and UCINET's uses Delphi's generator, so the two agree only by chance
on a network without clear groups.

## 29. Missing cells in factions and Louvain

**Status:** UCINET fix pending. `dev/UCINET-ISSUES.md` issue 27, raised
23 September 2026.

`xfactions()` and `xlouvain()` treat a missing cell as no tie. UCINET stores a
missing value as 1e38: Factions' dichotomize turns it into a tie, and Louvain
adds it into its modularity as a tie of weight 1e38. On complete data they
agree.

## 30. Cliques: no clustering of the clique-by-clique overlap

**Status:** deliberate simplification, 23 September 2026.

UCINET's Cliques ends with two hierarchical clusterings: of the actor-by-actor
co-membership matrix, and of the clique-by-clique overlap matrix. `xcliques()`
reports the first, which is what chapter 11 uses, and not the second.

## 31. Closeness centralization comes from the legacy Closeness routine

**Status:** deliberate addition, Steve, 23 September 2026.

UCINET's current Network | Centrality | Closeness dialog
(`uc_ClosenessMeasures.pas`) prints no centralization. `xcloseness()$summary`
has one anyway, ported from the legacy Closeness routine (`xcloseness.pas`,
`runFreemanCloseness`, which printed "Network Centralization = "): with
`c_i = 100 (n - 1) / farness_i`,

    (2n - 3) * sum(max c - c_i) / (n^2 - 3n + 2)      a percentage,

in- and out-versions for directed data. Like the legacy routine it is computed
only for a connected network; otherwise it is missing and the notice
"Network centralization not computed for unconnected graphs." is recorded.
The command line's `centralization()` (`runcentralization` in `Xdpmat.pas`)
divides the same sum by a star's, which is the same figure as a proportion;
the test suite checks the two agree. `xcentralization(measure = "closeness")`
reads it from `xcloseness()`, as it does the other three.

## 32. Level of analysis: what each function returns (SPEC addendum, 23 September 2026)

**Status:** deliberate, Steve, 23 September 2026.

A function returns the output that belongs to its level of analysis, always the
same fields whatever its arguments, and arguments choose only what is printed.
Where that moves output away from the UCINET dialog that prints it:

- `xreciprocity()` has no node table; UCINET's Reciprocity dialog prints one
  under the ratios. The table is `xegoreciprocity()` (UCINET's Egonet
  Reciprocity menu opens the same dialog), and its Symmetric column is also
  the seventeenth column of `xegonet()`, which UCINET's Egonet Basic Measures
  does not have. `method` sets which ratio is printed first.
- `xhomophily()` has no mixing matrix; it is `xmixing()`'s Observed table.
- `xtransitivity()` always returns the triplet and the triad measures; the triad
  ratio is named `Triad Transitivity` so that the two can sit in one list.
  `method` chooses which are printed, and the printed label changes with it.
- `xegoaltersimilarity()` returns a column for every continuous measure;
  `method` chooses which are printed.
- `xcentralization()` returns all four centralizations in one row.
- `xhclust()` always has a Cluster column, missing when `k` is not given.
- `xstructuralholes()` returns the same eleven columns under both models; the
  whole-network model prints UCINET's five.
- `xgirvannewman()` goes on cutting until no ties are left and keeps every
  partition; `k` sets which are printed, stopping where UCINET stops.

## 33. Inverse-weighted degree: diagonal, totals and normalization

**Status:** UCINET fix pending (UCINET issue 28). Steve, 23 September 2026.

`xinverseweighteddegree()` ports Network | Centrality | Inverse-Weighted Degree
(`uc_iwdcentrality.pas`, `Tiwdcentrality.run`) with its three faults corrected:

- the diagonal is always excluded (UCINET tests a `diagok` flag that is never
  set, so whether it counts is undefined);
- the row and column totals are those of the relation analysed (UCINET
  accumulates them across the relations of a multi-relation dataset);
- the normalized score is `raw / (n - 1)` (UCINET multiplies by the largest
  value in the matrix, which leaves binary data unchanged and scales valued
  data up).

On binary, single-relation data with an empty diagonal the numbers are
UCINET's.

## 34. Blockmodel: an image matrix UCINET does not print

**Status:** deliberate addition, 23 September 2026 (design question 12.2).

`xblockmodel()` is Transform | Aggregate | Block - Aggregate by Partitions
(`uc_blockmatrix.pas`) as a report: the blocked matrix, the aggregated matrix
and the autocorrelation, all UCINET's. It adds an image matrix, each block set
to 1 when its value reaches a cutoff, by default the relation's density (the
alpha criterion), because the book's Figure 12.5 shows one and UCINET's dialog
prints none.

## 35. Core/periphery: reproducible random starts, whole off-diagonal blocks, and MINRES versus the eigenvector

**Status:** UCINET fix pending for the second point (UCINET issue 29);
deliberate for the others. 23 September 2026.

- UCINET's categorical routine calls `randomize`, so two runs of UCINET can
  give different partitions where fits are close. `xcoreperiphery()` draws its
  random starts from the Delphi generator under `seed`, so a run can be
  repeated, but no seed reproduces a UCINET run: only the fit is comparable.
- With `c2p` or `p2c` set, UCINET computes the fit on an arbitrary subset of
  the off-diagonal blocks (UCINET issue 29). xucinet uses the whole blocks.
- The continuous model is UCINET's MINRES: unless the diagonal is valid, it is
  replaced by the squared loadings and re-estimated, so the scores are not the
  principal eigenvector, which is what the model gives with the diagonal
  valid. The book (12.8) notes the relation; the test suite checks both.
- `$matrices` also holds the densities of the categorical blocks, which the
  book's Figure 12.10 reports and UCINET's log does not print.
- The 2-mode routine is held: UCINET's is a genetic algorithm on the
  row-by-column correlation, while section 13.6 describes dual projection
  (STATUS open question).
