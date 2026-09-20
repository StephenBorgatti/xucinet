# Design questions for the remaining chapters (5, 10, 8, 11, 12, 13, 14, 7)

Written 20 September 2026 in a Cowork session, from the crosswalk (`asnr2e/crosswalk/crosswalk.py`),
the requirements list in `asnr2e/docs/plan.md` ("Decoupling decision"), SPEC.md and its two
addenda, and the UCINET dialogs as remembered; Claude Code will verify every UCINET claim against
`C:\Dev\ucinet\Source` when it implements the chapter and record the unit and procedure.

Purpose: answer once, then all remaining routines are coded without waiting on design rounds.
Goldens are generated in one batch at the end (decision of 20 Sep 2026, `asnr2e/docs/plan.md`).
Only questions that change the API or the numbers are asked. Everything not asked follows the
existing conventions: SPEC D1–D14 and the 6 Sep and 18 Sep addenda, CLAUDE.md, UCINET dialog
defaults, UCINET's report layout, one function per UCINET routine, `save=` deferred.

Chapters are in the order they will be coded (dependencies first): 5, 10, 8, 11, 12, 13, 14, 7.

## Steve's answers

Fill the table, or strike through a recommendation inline. A blank row means "as recommended".

| # | decision |
|---|---|
| G1 | |
| G2 | |
| G3 | |
| 5.1 | |
| 5.2 | |
| 5.3 | |
| 5.4 | |
| 5.5 | |
| 5.6 | |
| 5.7 | |
| 5.8 | |
| 5.9 | |
| 5.10 | |
| 5.11 | |
| 10.1 | |
| 10.2 | |
| 10.3 | |
| 10.4 | |
| 10.5 | |
| 10.6 | |
| 8.1 | |
| 8.2 | |
| 8.3 | |
| 8.4 | |
| 11.1 | |
| 11.2 | |
| 11.3 | |
| 11.4 | |
| 11.5 | |
| 12.1 | |
| 12.2 | |
| 12.3 | |
| 12.4 | |
| 13.1 | |
| 13.2 | |
| 13.3 | |
| 14.1 | |
| 14.2 | |
| 14.3 | |
| 14.4 | |
| 14.5 | |
| 7.1 | |
| 7.2 | |
| 7.3 | |

---

## G. Questions that cut across chapters

**G1. igraph as an Import.** SPEC D9 keeps igraph in Suggests. Chapter 11 (fast greedy, Louvain,
label propagation, Girvan-Newman), chapter 13 (bipartite projections are cheap in base R, but
2-mode Louvain is not) and chapter 7 (layouts) all need graph algorithms that would be slow and
error-prone to rewrite in base R. Options: (a) igraph moves to Imports, used as the engine for
community detection and layouts, with results checked against UCINET goldens where UCINET has
the routine; (b) igraph stays in Suggests and those functions stop with "install igraph" when it
is absent; (c) native ports of UCINET's Delphi. Recommendation: (a). igraph is on CRAN, actively
maintained, and installs on a clean R without Rtools. "UCINET numbers win" still holds: where
the golden shows a difference (tie-breaking in Louvain, Girvan-Newman on ties), the ledger
records it and the routine keeps a `method=` or `seed=` argument that reproduces UCINET when it
can. Decision needed before chapter 11 starts.

**G2. Transformations return a network, not a report.** Chapter 5 routines (xdichotomize,
xsymmetrize, xtranspose, xnormalize, xrecode, ximpute, xcombine, xcombinenodes, xjoin, xunpack,
xattributetomatrix, xbipartite, xaffiliations) produce a dataset, and UCINET's log for them is
one line plus the matrix. Recommendation: they return a `xucinet` object (so they chain and feed
any other routine), silently, with the title set the way UCINET names the output dataset
(`campnet-sym`, `campnet-geo`, `davis-aff`), and with a `history` attribute recording the
operation. `xgeodesic` and `xsimilarities` are the two that also print a UCINET-style report in
UCINET; recommendation: they return `xucinet_output` with the matrix in `$matrices`, and
`as_xucinet()` on such an object takes the first matrix, so `xmds(xgeodesic(net), type = "d")`
works. Alternative: everything returns `xucinet_output` and nothing chains without `$matrices`.

**G3. Attribute arguments.** Chapters 8, 10, 12, 14 take a node attribute. D4 says `attribute`
accepts a vector, a column name, or `data$column`. Recommendation for the column-name case:
`attribute = "gender"` is looked up first in `net$attributes` (the data frame `xattributes()`
returns, present on shipped datasets), then in an optional `data =` argument. Type detection
where a routine branches on categorical vs continuous (8.4, 8.5, 10.5): character, factor and
logical are categorical; numeric is continuous unless `type = "categorical"` is given; integer
vectors with five or fewer distinct values print a note suggesting `type=` but are treated as
continuous. Same rule everywhere.

---

## Chapter 5 — data management and transformations

Routines: xdichotomize, xsymmetrize, xtranspose, xnormalize, xgeodesic, xcombine, xcombinenodes,
xattributetomatrix, xmatch, xjoin, xunpack, xrecode, ximpute, xsimilarities, xmultiplex;
projects (5.11); `xread()` change (5.10). Signatures are in the crosswalk chapter 5 block.

**5.1. xdichotomize.** Crosswalk: `xdichotomize(net, cutoff=NULL, op=">", density=NULL,
method=c("value", ...))`, and the ch05 text names `method="maxcor"`. UCINET's Dichotomize dialog
has the six operators (GT, GE, LT, LE, EQ, NE) and a cutoff. Recommendation: `cutoff` with `op`
(the six operators as strings `">"`, `">="`, `"<"`, `"<="`, `"=="`, `"!="`), default `> 0`;
`density =` chooses the cutoff that gives the requested density (the largest cutoff whose
density is at least the target); the diagonal is thresholded like every other cell (Phase 0
decision, ledger entry 1). Question: what is `method="maxcor"` in the ch05 text? If it is not a
UCINET option, either define it (the cutoff maximising the correlation between the binary and
the original matrix) or remove it from the text.

**5.2. xsymmetrize methods.** UCINET's Symmetrize offers maximum, minimum, average, sum, upper
half, lower half, and four more (difference, product, division, and "upper > lower"). Crosswalk
lists `max, min, sum, mean, upper, lower`. Recommendation: the six in the crosswalk plus
`"product"` and `"difference"`, since they cost nothing; `method = "max"` default as in UCINET.
A directed network becomes `directed = FALSE` on output.

**5.3. xnormalize.** UCINET's Normalize dialog: which (rows, columns, both, whole matrix) and
criterion (sum, mean, maximum, minimum, Euclidean norm, standard deviation / z-score), with
"both" iterating until convergence. Crosswalk: `by = c("rows","cols","matrix")`,
`method = c("sum","max","mean", ...)`. Recommendation: add `by = "both"` with UCINET's iterative
procedure and UCINET's iteration limit, and the full criterion list. Default: rows, sum.

**5.4. xgeodesic.** Crosswalk: `xgeodesic(net, directed=NULL, unreachable=NA)`. UCINET's
Geodesic Distance dialog stores unreachable pairs as a user-chosen value and offers nearness
transformations. Recommendation: `unreachable = NA` default in R (UCINET's stored value is
whatever the dialog default is; the golden will show it, and `unreachable =` reproduces it);
`weighted = FALSE` default, with `weighted = TRUE` giving Dijkstra on tie values as costs;
`method = c("distance","frequency")` to also return the number of geodesics, which xbetweenness
already computes internally; nearness transformations left out (the ch05 text does not use
them). Returns `xucinet_output` (see G2).

**5.5. xcombine and xjoin.** xjoin stacks networks into a multi-relation dataset (Data | Join),
xunpack splits one; xcombine collapses relations into one matrix by min, max, sum or mean
(Transform | Matrix operations | Between datasets | Statistical summaries). Recommendation:
`xcombine(net, relations = NULL, method = c("max","min","sum","mean"))` also accepts a list of
separate networks with matching labels, since users will often have them separately; `xjoin`
accepts any number of networks or a list, checks labels match (reorders by label if they do
not, with a message), and takes relation names from the argument names or the titles.
`xmultiplex` (Transform | Multiplex) codes each cell by which relations are present
(UCINET's combination coding); confirm it is wanted, since only 5.9 mentions it.

**5.6. xcombinenodes.** UCINET's Transform | Collapse aggregates rows and columns by an attribute
with sum, average, maximum, minimum, or density. Recommendation: exactly those five,
`method = "sum"` default as UCINET; the result is a group-by-group `xucinet` with the group
labels; for density the diagonal uses within-group possible ties, n(n-1) for 1-mode.

**5.7. xattributetomatrix.** UCINET's Data | Attribute to matrix offers exact matches,
difference, absolute difference, sum, product, and the "same or different" coding. Crosswalk:
`method = c("same","diff","absdiff","sum", ...)`. Recommendation: `same` (1 if equal), `diff`
(a_i - a_j), `absdiff`, `sum`, `product`, `max`, `min`; also `xattributetomatrix(a, b)` for two
attributes (UCINET's "exact match" between two vectors is not needed; drop). Output: 1-mode
`xucinet`, symmetric where the method is, labels from the attribute's names or the network
passed as `net =`.

**5.8. xmatch.** `xmatch(net, attributes, by = "rownames")` reorders an attribute data frame
to the network's node order. Recommendation: `by` names a column or `"rownames"`; nodes absent
from the attributes get NA rows with a message listing them; attribute rows for nodes not in
the network are dropped with a message; the result is the reordered data frame, and
`xmatch(net, attributes, attach = TRUE)` returns the network with `$attributes` set. Labels are
matched exactly (case-sensitive), because UCINET labels are.

**5.9. xsimilarities and ximpute and xrecode.** (a) xsimilarities (Tools | Similarities &
Distances): measures correlation, Euclidean distance, simple matching, Jaccard, positive
matches, cosine (UCINET lists more); `mode = c("rows","cols")`; for 1-mode data UCINET's dialog
has "diagonal valid" defaulting to no. Recommendation: those six, diagonal excluded for 1-mode
unless `diagonal = TRUE`, and for directed 1-mode data the profile is the row and column
concatenated only when `method = "profile"` is chosen in chapter 12 (see 12.1); here plain rows
or columns. (b) ximpute (Data | Missing values): methods reconstruction (fill a_ij from a_ji),
zero, row mean, column mean, overall mean; recommendation: `method = c("reconstruction","zero",
"mean")` with `mean` meaning the overall mean, and a message giving the number of cells filled.
(c) xrecode: `xrecode(net, from, to)` where `from` is a vector of values or a list of
`c(low, high)` ranges and `to` the replacement for each; values not matched are unchanged.
Confirm these three or say what to drop.

**5.10. xread on duplicate edgelist pairs.** The ch05 text says duplicates are summed; the code
keeps the last value. Recommendation: sum, with a message giving the number of duplicated
pairs, recorded in the object's `history`. Alternative: `duplicates = c("sum","last","error")`.

**5.11. Projects (SPEC D2, still open).** The 1e aliases xCreateProject, xAddToProject,
xAddAttributesToProject, xRemoveFromProject exist and call nothing. The ch05 rewrite is built
on xread() and does not need a project. Recommendation: implement `xcreateproject(name)`,
`xaddtoproject(project, ...)`, `xremovefromproject(project, name)` as a named list of
class `xucinet_project` with a print method listing its contents, about forty lines, so the
aliases work for 1e readers; nothing else in the package accepts a project. Alternative: drop
them and have the aliases stop with a message.

---

## Chapter 10 — whole-network measures

Routines: xreciprocity, xtransitivity, xcyclicality, xcomponents, xcohesion, xcentralization,
xdensitybygroups, xhomophily; xkeyplayer (10.6); xcoreperiphery is chapter 12 and its
`$fit` is what 10.4 uses.

**10.1. xreciprocity.** UCINET's Reciprocity reports the dyad-based ratio (mutual dyads over
non-null dyads) and the arc-based ratio (reciprocated arcs over all arcs), and offers a hybrid.
Crosswalk: `method = c("dyad","arc")`. Recommendation: compute both always and put both in
`$summary`, with `method` choosing which is printed first; valued data dichotomised with
UCINET's notice.

**10.2. xtransitivity and clustering.** UCINET's Transitivity routine reports the proportion of
transitive triples under a chosen definition (adjacency, weak, strong, Euclidean, ...); UCINET's
Clustering Coefficient routine is separate (overall, weighted overall, per-node). The 3e text
in 10.2.3 discusses transitivity and the clustering coefficient together. Recommendation:
`xtransitivity(net, directed = NULL, type = c("adjacency","weak","strong"))` reports the
transitivity proportion and the number of triads of each kind as UCINET does, and
`xclustering(net, weighted = FALSE)` is a separate function for the clustering coefficients
(overall, weighted, and per-node in `$nodes`), because the two UCINET routines print different
things. `xcyclicality` as UCINET's Cyclicality routine. Alternative: fold the clustering
coefficient into xtransitivity's `$summary` and do not export xclustering.

**10.3. xcomponents.** UCINET's Components reports the number of components, sizes, membership,
with a minimum-size option, and strong components for directed data. Recommendation:
`xcomponents(net, type = c("weak","strong"), min = 1)`; `$nodes` has the component id per
node (original order), `$summary` the count and the size distribution; also `xcomponents()`
on 2-mode data treats the bipartite graph. Isolates are components of size 1, as in UCINET.

**10.4. xcohesion.** The text asserts it reports connectedness, fragmentation, compactness and
breadth (10.3.2), and the requirements list has "k-reach proportions still open". UCINET's
Density routine already writes the cohesion block (the Phase 0 goldens `G_CAMPNET_COH`,
`G_BAKER_COH`, `G_HIGHTECH_COH` hold it, 33 values for a 1-relation dataset). Recommendation:
`xcohesion(net, directed = NULL)` reproduces exactly the measures in that block, in UCINET's
order and with UCINET's headings, one row per relation, and nothing more; the block already
covers the four the text names plus average distance, diameter and the rest. k-reach
proportions are left out of the text unless the block contains them (Claude Code will report
what the block holds).

**10.5. xcentralization.** Crosswalk: `xcentralization(net, measure = c("degree","closeness",
"betweenness","eigenvector"))`. The centrality routines already put centralization in
`$summary`. Recommendation: xcentralization is a thin function that calls the centrality
routine and returns its centralization as a one-row `$summary`, so the two cannot disagree;
no separate computation.

**10.6. xdensitybygroups, xhomophily, xkeyplayer.** (a) xdensitybygroups (Density by groups):
the group-by-group density matrix plus the count matrix; `test = TRUE` (the ch05 and ch14
text) runs a permutation test. Question: which UCINET test is meant, "ANOVA density models"
(constant homophily, variable homophily, structural blockmodel) or the relational contingency
table? Recommendation: ANOVA density models, and the test is coded with chapter 14 (the same
permutation engine), so chapter 10 ships `xdensitybygroups()` with `test = FALSE` only.
(b) xhomophily is UCINET's E-I index: whole-network E-I with expected value, maximum and
minimum possible, permutation p-value, group-level and node-level E-I. Recommendation: name
stays `xhomophily` as in the frozen crosswalk, `nperm = 5000` and `seed`, output as UCINET's
three tables; the Table 10.6 sign issue in the 3e errors list is a generator matter.
(c) xkeyplayer is in the crosswalk at 10.3.1 but D-7 dropped Keyplayer. Recommendation: drop;
remove the row from the crosswalk.

---

## Chapter 8 — ego networks

Routines: xtiecomposition, xvaluedtiecomposition, xaltercomposition, xegoaltersimilarity,
xstructuralholes, xegonet. 1e aliases: xTieComposition, xValuedTieComposition,
xMultipleTieComposition, xAlterCompositionCat/Con, xEgoAlterSimilarityCat/Con,
xEgonetStructure, xStructuralHoles.

**8.1. What xegonet is.** Crosswalk: `xegonet(net, directed = NULL, include_ego = FALSE)` for
8.6.2, and the 1e name is xEgonetStructure. UCINET's Ego Networks | Egonet basic measures
prints about twenty columns per ego (size, ties, pairs, density, average distance, diameter,
weak components, normalised components, two-step reach, reach efficiency, brokerage,
normalised brokerage, ego betweenness, normalised ego betweenness, ...). Recommendation:
xegonet reports exactly UCINET's Egonet basic measures table with UCINET's headings, with the
dialog's options as arguments: `directed` (UCINET: in-neighbourhood, out-neighbourhood,
undirected), `include_ego`. No separate function to extract the ego subgraph; the ch08 text
does not ask for one. `xMultipleTieComposition` maps to `xtiecomposition(net, relations = )`.

**8.2. Attribute-type detection.** 8.4 and 8.5 have categorical and continuous variants
(1e: two functions each; 2.0: one function with `type = NULL`). Rule as in G3. For the
categorical composition UCINET reports, per ego, the count and proportion of alters in each
category plus heterogeneity (Blau) and IQV; for continuous, the mean, sd, min, max of alters
and the ego-alter difference. Recommendation: reproduce UCINET's Ego Network Composition
tables exactly; `$nodes` has one column per category for the categorical case.

**8.3. xstructuralholes.** UCINET's formulas, not igraph's (SPEC D7 danger zone): effective
size, efficiency, constraint, hierarchy, plus the dyadic redundancy and dyadic constraint
matrices in `$matrices`. Questions to settle: (a) directed data: UCINET's Structural Holes
dialog symmetrises by taking (z_ij + z_ji) as Burt does, or by max; Claude Code reads
`uc_StructuralHoles.pas` and follows the dialog default. (b) valued ties: used as weights as
UCINET does. (c) The ledger entry states the igraph delta (constraint on isolates, ego-network
boundary). Recommendation: as stated; `$nodes` columns use UCINET's headings (`EffSize`,
`Efficie`, `Constra`, `Hierarc` if that is what the source writes).

**8.4. xtiecomposition and xvaluedtiecomposition.** 8.2 counts, per ego, ties of each kind
across relations (multi-relation input); 8.3 summarises tie values per ego (`direction =
c("out","in")`). Recommendation: as the crosswalk signatures; for a single-relation binary
network xtiecomposition reduces to out-degree and in-degree and says so.

---

## Chapter 11 — subgroups

Routines: xcliques, xgirvannewman, xfactions, xfastgreedy, xlouvain, xlabelpropagation,
xcommunities; xwalktrap (ASNR only).

**11.1. xcliques output.** The text asserts it returns the co-membership matrix, its
hierarchical clustering, and the clique participation (actor-by-clique) matrix. UCINET's
Cliques prints the clique list, the actor-by-clique matrix, the co-membership matrix and the
clustering of the co-membership matrix. Recommendation: `xcliques(net, min = 3)` returns
`$cliques` (a list of label vectors), `$matrices$participation` (actor by clique),
`$matrices$comembership`, and `$clustering` (an xhclust result on the co-membership matrix,
average linkage, as UCINET does); the print method prints them in UCINET's order. Directed
data are symmetrised by minimum with UCINET's notice (UCINET's default for cliques).

**11.2. Community detection engines.** Depends on G1. With igraph in Imports: xfastgreedy,
xlouvain, xlabelpropagation, xgirvannewman call igraph; each reports the partition per
node in `$nodes`, the modularity in `$summary`, and (for Girvan-Newman) one partition per
number of clusters with its Q, as UCINET prints. `xcommunities(net, method = )` is the
dispatcher and returns the same shape whatever the method. Recommendation: igraph, with
`seed` on the stochastic ones and UCINET's own results as goldens where UCINET has the
routine (Girvan-Newman, Louvain, factions); document any tie-breaking differences.

**11.3. xfactions.** UCINET's Factions: number of factions, fit measure (correlation,
Hamming), random restarts, with the ideal image being block-diagonal. Recommendation:
`xfactions(net, k, method = c("correlation","hamming"), restarts = 10, seed = NULL)`, native
port of UCINET's combinatorial optimisation from the Delphi so numbers match; the "Cohen
agreement and Freeman segregation" sentence in the ch11 text is deleted (asnr2e STATUS open
question 2) unless you say otherwise, because the 3e text does not use those criteria.

**11.4. xlouvain resolution and 2-mode.** `xlouvain(net, resolution = 1)`; on 2-mode input
uses dual projection as the 13.5.1 text says. Question: does UCINET's 2-mode Louvain use dual
projection (project rows and columns, run Louvain on each, combine) or bipartite modularity
(Barber)? Recommendation: follow what UCINET does, from `uc_Louvain*.pas`; Claude Code reports
which it is. If UCINET does bipartite modularity, the 13.5.1 text is edited to say so.

**11.5. xwalktrap.** D-7 drops Walktrap (follows 3e); the crosswalk row "11.4.2 (ASNR)" and
the 1e aliases xWalkTrap/xWalktrap remain. Recommendation: no 2.0 function; the aliases stop
with a message naming `xcommunities(method = "louvain")` as the replacement. Same for
xQuickClus if any alias exists.

---

## Chapter 12 — equivalence and blockmodels

Routines: xstructuralequivalence, xblockmodel, xblockoptimize, xrege, xcoreperiphery.

**12.1. xstructuralequivalence.** Crosswalk: `method = c("correlation","euclidean","match", ...)`.
UCINET's Profile Similarity routine: measure, whether the diagonal is valid, whether to
include the transpose for directed data (rows and columns concatenated), and the built-in
clustering. Requirements list: built-in clustering defaults to weighted average. Recommendation:
`xstructuralequivalence(net, method = c("correlation","euclidean","match"), diagonal = FALSE,
k = NULL)`; profiles are rows concatenated with columns for directed data (UCINET's default),
rows only for symmetric; the diagonal is excluded from profiles unless `diagonal = TRUE`;
the similarity matrix goes to `$matrices`, and the clustering (weighted average, WPGMA, by
`xhclust(method = "weighted")`, which xhclust gains here) is printed as UCINET prints it, with
`k` adding a partition column. CONCOR: not in the crosswalk. Question: is CONCOR wanted as
`method = "concor"` or a separate xconcor? Recommendation: leave it out of 2.0 unless the ch12
text uses it.

**12.2. xblockmodel.** `xblockmodel(net, partition)`: density table, image matrix at a cutoff
(default: the overall density, UCINET's alpha criterion), the permuted and blocked matrix
display (UCINET's blocked layout in `cat_uci_matrix` style with block separators), and the
fit (proportion of cells matching the image). Recommendation: `cutoff = NULL` means overall
density; `partition` accepts a vector, a column name of the attributes, or a chapter 11/12
result object (its `$nodes` partition column). The blocked matrix display is ported from
UCINET's `blockedmatrix` display code; confirm that this display is wanted for 2.0 or that the
density table and image suffice.

**12.3. xblockoptimize.** UCINET's Optimization blockmodeling (tabu search): number of blocks,
type of equivalence (structural, regular), fit criterion, restarts, seed. Recommendation:
`xblockoptimize(net, k, type = c("structural","regular"), method = c("correlation","hamming"),
restarts = 10, seed = NULL)`, native port of the Delphi tabu procedure so the objective function
and the fit reported match UCINET; goldens compare fit values and partitions after restarts
with the seed noted, and the ledger records that with different RNGs only the fit is expected
to agree.

**12.4. xrege and xcoreperiphery.** (a) xrege: `iterations = 3` as UCINET's default; output the
regular equivalence similarity matrix and its clustering as UCINET prints them; 2-mode REGE
(13.7.2) via the same function on rectangular input if UCINET's routine takes it. (b)
xcoreperiphery: `type = c("categorical","continuous")`, `k = NULL`. Categorical: UCINET's
combinatorial optimisation with correlation fit and the choice of ideal pattern (core-core
ones, periphery-periphery zeros, off-diagonal blocks either ignored or ones); recommendation:
the dialog default pattern, ported from the Delphi. Continuous: UCINET's MINRES default,
reporting coreness scores in `$nodes` and the fit (correlation) in `$summary`; `$fit` is what
10.4 uses. 2-mode: dual projection categorical CP as in 13.6 (Everett and Borgatti), with
row and column core membership in `$nodes`. Restarts and seed as in 12.3.

---

## Chapter 13 — two-mode

Routines: xaffiliations, xbipartite, xbicliques; 2-mode behaviour of xlouvain (11.4),
xcoreperiphery (12.4), xsimilarities (5.9), xhclust, xrege (12.4), centrality (done).

**13.1. xaffiliations.** UCINET's Data | Affiliations: projection to rows or columns by
cross-products or minimums, with optional normalisation (Bonacich 1972). Crosswalk:
`mode = c("rows","cols")`, `method = c("crossproduct","min", ...)`. Recommendation: those two
methods plus `"jaccard"`; the diagonal is kept as UCINET writes it (row sums for
cross-products), since removing it is one `diag<-` away and keeping it matches the fixtures;
the output is a 1-mode undirected valued `xucinet` titled `davis-aff` style.

**13.2. xbipartite.** Converts a 2-mode matrix to the (nr + nc) square bipartite adjacency
matrix with zero diagonal blocks, labels rows then columns, undirected. Recommendation: as
stated, with a `mode = "1-mode"` result; an attribute data frame with the mode of each node is
returned in `$attributes` so `xplot(node_color = "mode")` and 2-mode aware routines can use it.

**13.3. xbicliques.** UCINET's Bi-cliques: minimum rows and columns. Recommendation:
`xbicliques(net, min_rows = 3, min_cols = 3)`, returning the same shape as xcliques
(`$cliques` as lists of row and column labels, participation matrices for each mode); native
enumeration (bicliques are maximal complete bipartite subgraphs; the Delphi is the source).

---

## Chapter 14 — testing hypotheses

Routines: xcorrelation, xregression, xautoregression, xqap, xmrqap, xlrqap;
xdensitybygroups(test = TRUE) (10.6).

**14.1. Formula interface.** The crosswalk gives `xregression(y ~ x, data, nperm = 5000)`,
`xmrqap(y ~ x1 + x2, nets, nperm = 2000, method = c("dsp","yperm"))`, `xlrqap(...)`,
`xautoregression(y ~ x, data, net, model = c("lag","error"))`. This is the first formula
interface in the package. Recommendation: keep it; for node-level routines `data` is a data
frame (or omitted, in which case names are looked up in the calling environment and in
`net$attributes` if `net` is given); for QAP routines `nets` is a named list of networks or a
multi-relation `xucinet`, and the formula names are relation names. `xqap(net1, net2)` and
`xcorrelation(x, y)` keep the two-argument form (no formula). Everything lowercase still: the
formula variables are user names, which is fine.

**14.2. p-values and tails.** UCINET reports, for permutation tests, the proportion of
permutations as large, as small, and (in recent versions) as extreme, and the QAP correlation
dialog now has 1- and 2-tailed options. Recommendation: every permutation routine reports all
three proportions with UCINET's headings; the `$summary` "p-value" column is the two-tailed
proportion as extreme, and the ledger notes where UCINET's dialog default is one-tailed.
`nperm` defaults: 5000 for correlation, regression and QAP correlation; 2000 for MRQAP and
LR-QAP (UCINET's defaults; Claude Code confirms from the dfm files). `seed = NULL`, R's RNG;
p-values agree with UCINET in distribution, not digit for digit (D12); goldens compare the
observed statistics exactly and the p-values to a tolerance derived from nperm.

**14.3. xqap measures and xmrqap methods.** QAP correlation reports Pearson, simple matching,
Jaccard, Goodman-Kruskal gamma and Hamming distance in one table, as UCINET does.
Recommendation: `xqap(net1, net2, nperm = 5000, seed = NULL)` reports all five (no `method`
argument; the crosswalk's `method = c("pearson","jaccard", ...)` is dropped); xmrqap
`method = c("dsp","yperm")` with Double Dekker semi-partialling as default (UCINET's default);
xlrqap as UCINET's LR-QAP with its default of y-permutation. Standardised coefficients, R²,
adjusted R², and the permutation-based proportions as UCINET prints them. Diagonal excluded;
missing cells dropped pairwise, as UCINET.

**14.4. xautoregression.** Port of UCINET's Network Autocorrelation routine (lag and error
models, ML estimation). Recommendation: port from the Delphi (`unetautocorr`), no dependency
on sna's `lnam`; report rho, coefficients, standard errors and log-likelihood in UCINET's
layout; the weight matrix is row-normalised by default as in UCINET (`normalize = TRUE`).

**14.5. Node-level tests.** 3e chapter 14 covers permutation t-tests and ANOVA for a categorical
node attribute against a continuous one, plus the vector correlation and regression. The
crosswalk names only xcorrelation and xregression. Recommendation: add `xttest(y, group,
nperm = 5000)` and `xanova(y, group, nperm = 5000)` if the ch14 text refers to those UCINET
routines (Claude Code checks the merged ch14.docx via lint), otherwise nothing.

---

## Chapter 7 — visualisation

Routines: xplot, xlayout.

**7.1. Backend.** SPEC D13 says ggraph; the 18 Sep addendum narrowed D13 to network plots and
chose base graphics for the chapter 6 plots. Options: (a) base graphics, igraph layouts (given
G1), drawn by the package; (b) ggraph (adds ggplot2, ggraph, tidygraph). Recommendation: (a).
It matches the chapter 6 plots, has no new dependency beyond igraph, renders identically under
Rscript, RStudio and knitr, and the book's figures are static. Interactive plots
(`interactive = TRUE`, visNetwork) are out of 2.0.

**7.2. Signature.** `xplot(net, layout = c("spring","circle","mds","random") | matrix,
node_color = NULL, node_size = NULL, node_shape = NULL, label = TRUE, edge_width = NULL,
edge_color = NULL, arrows = NULL, isolates = TRUE, legend = TRUE, ...)`. `node_color`,
`node_size`, `node_shape` accept an attribute name, a vector, or a `xucinet_output` (the first
numeric column of `$nodes`), so `xplot(net, node_size = xdegree(net))` works; `isolates =
FALSE` drops isolates (7.5); `arrows = NULL` follows `directed`; 2-mode input draws the
bipartite graph with shapes by mode. `xlayout(net, layout = "spring", seed = NULL)` returns the
coordinate matrix so 7.6 can reuse it: `xplot(net2, layout = xlayout(net1))`. Recommendation:
as stated; `layout = "spring"` is igraph's Fruchterman-Reingold, seeded, which looks like
NetDraw's spring embedding. Confirm the argument names (`node_color` etc. carry an underscore,
which is the only place the API does; the crosswalk fixed them and the ch07 text uses them).

**7.3. Exporting.** 7.7 in the text waits for xplot and currently says `ggsave()`. With base
graphics the export is `png()`/`pdf()` around the call. Recommendation: `xplot(..., file =
"fig.png", width = , height = , dpi = 300)` writes the file and returns invisibly, so the text
has one idiom, and the ch07 merge (`tools/merge-edits/edits07.py`) is finished on that basis.
