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
| G2 | Settled 20 Sep 2026 in conversation (rules a–f as written below). |
| G3 | |
| 5.1 | xdichotomize function maxcor. This is the method of Borgatti, S. P., & Quintane, E. (2018). Techniques: Dichotomizing a network. Connections, 38(1), 1-11. |
| 5.2 | |
| 5.3 | |
| 5.4 | |
| 5.5 |xjoin() should have mode = c('col','row','mat') parameter where col is default. choosing col appends columns (a 50x3 matrix and a 50x4 become a 50x7 matrix). row appends rows, and mat adds multiple matrices to the dataset, as in the sampson dataset. xmultiplex should be included |
| 5.6 | |
| 5.7 |Need to add Row (or Receiver) and Col (or Sender) methods. Row creates a matrix whose rows are the attribute vector. every row is identical. Col creates a matrix whose cols are the vector. every column is the same. these are used to test receiver and sender effects in qap regressions  |
| 5.8 |the two-dataset call `xmatch(net, attr)` should return the list |
| 5.9 | |
| 5.10 |Let's go with alternative (a duplicate option)|
| 5.11 |go with the alternative: drop them and have the aliases stop with a message. |
| 10.1 | |
| 10.2 | fold overall clustering coefficient into xtransitivity report. do not calculate node level clustering coef. Add note to ucinet bug list: remove node leveel clustering coef|
| 10.3 | |
| 10.4 | Output the same measures as ucinet network>whole networks>multiple measures|
| 10.5 | |
| 10.6 |Use ucinet's Network>Mixing tables w/ expected values as a model for xdensitybygroups; for xhomophily, copy ucinet's Network>Whole networks|homophily>categorical; drop keyplayer|
| 8.1 | |
| 8.2 | |
| 8.3 | |
| 8.4 | |
| 11.1 | data should be symmetrized by maximum|
| 11.2 | |
| 11.3 | |
| 11.4 | |
| 11.5 | |
| 12.1 | copy ucinet's options for how to handle the diagonal. default should be reciprocal |
| 12.2 | Not sure what this procedure is doing. nor the algorithm. will it be written in R? slow|
| 12.3 | is this different from xblockmodel? how to implement? tabu search in R will be too slow. see if existing package exists that we can import |
| 12.4 | copy ucinet's current code for network>core-periphery>categorical |
| 13.1 | |
| 13.2 | |
| 13.3 | |
| 14.1 | |
| 14.2 | |
| 14.3 | |
| 14.4 | |
| 14.5 | |
| 7.1 | |
| 7.2 | dont use underscores|
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

**G2. Datasets versus reports, and how results feed the next routine.** Settled with Steve in
the Cowork session of 20 Sep 2026 (revised from the first draft, which had xgeodesic and
xsimilarities returning reports). Six rules:

(a) *Dataset or report.* A routine returns a `xucinet` dataset when what UCINET writes is a
matrix you would save and use as input again: every transformation (xdichotomize, xsymmetrize,
xtranspose, xnormalize, xrecode, ximpute, xcombine, xcombinenodes, xjoin, xunpack,
xattributetomatrix, xmultiplex) and also xgeodesic, xsimilarities, xaffiliations, xbipartite.
The user who types `mycorr <- xsimilarities(net, method = "correlation")` gets a dataset, as in
UCINET: `mycorr$data`, `mycorr[1, 2]`, `xsave(mycorr, ...)` all work, `mycorr` prints as
`print.xucinet` (plain matrix with title), `xdisplay(mycorr)` gives UCINET's layout. The title
is set the way UCINET names the output dataset (`campnet-sym`, `campnet-geo`, `campnet-cor`)
and a `history` attribute records the operation and any notice (cells filled, duplicates
summed). A routine returns a `xucinet_output` report when what UCINET writes is a set of
results about the network: node tables, summaries, or a matrix together with tables (structural
equivalence with its clustering, structural holes with its dyadic matrices, cliques). Outputs
that are rarely input to anything (a frequency distribution, a triad census) are reports and
need no coercion path. There is no third class; a report is not to be used as a dataset, and
chapter 5 teaches one dataset class.

(b) *Coercion of a report, matrix first.* When a routine's `net` or `x` argument receives a
`xucinet_output`, `xnet()`/`as_xucinet()` take a matrix if the object has one (the first of
`$matrices`, with a one-line message naming it and how to choose another; one matrix per
relation becomes a multi-relation dataset), and `$nodes` only if it has none. So
`xmds(xstructuralequivalence(net), type = "s")` scales the similarity matrix, not the cluster
column. When the matrix is taken, `$nodes` is attached as `$attributes` of the resulting
dataset, keyed by label, so `xplot(xstructuralequivalence(net), node_color = "Cluster")` works.
When `$nodes` is taken (xcentrality, xdegree, any node-level routine) it becomes a
node-by-variable 2-mode dataset with the mode set explicitly, id columns (`Cluster`,
`Component`, `Faction`, `Core`) excluded by a marker on the data frame, and a message saying
what was kept. Arguments that want a node vector (`attribute =`, `node_size =`, `partition =`)
read `$nodes` and take the named column, or the first numeric one.

(c) *Node-level reports behave as data frames.* Centrality scores are used far more often as
regressors than read as a table. So for every `xucinet_output` with a node table:
`as.data.frame(res)` returns `$nodes` joined with the network's attribute table by label;
`$` falls through to the node table when the name is not a slot (`mycent$Betweenness`); and
because `model.frame()` calls `as.data.frame()` on a classed `data` argument,
`lm(Betweenness ~ gender, data = mycent)` and `xregression(Betweenness ~ gender, data = mycent)`
both work. Printing is unchanged (the report). The chapter 14 prompt assumes `data = <any
result>`.

(d) *Titles in pipes.* `xnet(net, substitute(net))` keeps the caller's expression as the title
only for bare matrices and data frames; a `xucinet` or a report that carries a title keeps it.
Otherwise `campnet |> xsymmetrize() |> xdegree()` would be headed by the nested call, and a
magrittr pipe by `.`.

(e) *Pipes.* The native pipe works with every routine because the data are the first argument
(D4); formula-first routines (xregression, xmrqap, xautoregression) take `data = _`. No
magrittr dependency. Chapter 5 shows one pipe example and otherwise uses nested or stepwise
calls.

(f) *xsimilarities default.* `mode = "cols"` is the default, so `xsimilarities(xcentrality(net))`
correlates the measures. (xmds and xhclust keep `type=` required; nothing is inferred there.)
The name `xcorrelation` for the chapter 14 permutation test is questioned (a valuable name for a
rarely used routine); tabled, see 14.1.

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

*Sections 5.1–5.7 rewritten 21 Sep 2026 from the UCINET source (`C:\Dev\ucinet\Source`; units
named in each). The first draft was from memory and was wrong in several places.*

**5.1. xdichotomize.** Transform | Dichotomize (`uc_Dichotomize.pas`/`.dfm`). The rule is "if
x(i,j) *op* value then y(i,j) = then-value else else-value": operators Greater Than (default),
Greater Than or Equal to, Equal to, Less Than or Equal to, Less Than, Not equal to; cutoff
value 0; then-value 1 and else-value 0 (either may be `NA`). "Diagonals of output matrix":
set to zero, set to missing, set to then-value, set to else-value (**the default**), follow the
rule. Output name `<input>_GT_0` (dots in the cutoff become `p`); the log prints the matrix,
number of 1s, number of cells, density. There is no density-target option and no "maxcor"
anywhere in UCINET; the older CLI `dichot` (`xdichotomize.pas`) accepts `mean` as the cutoff.
Two things to settle. (i) The ch05 text (written in the 8 Sep rewrite) says
`xdichotomize(cutoff =, density =, method = "maxcor")`. Steve, 21 Sep: "maxcor" is what
Transform | Dichotomize Interactive does (`uc_DichotomizationApp.pas`): for every distinct
value v of X it dichotomises X with the chosen operator at v (off-diagonal cells unless the
diagonal is valid, missing cells excluded) and tabulates the z-score of v, its frequency, the
Pearson correlation between the dichotomised matrix and X, the number of ones and the density,
and the user picks a row. In xucinet, `method = "maxcor"` picks the row with the largest
correlation automatically. Decided: implement it that way; `cutoff` and `density` remain as
the other two ways of choosing the cutoff, so `method = c("cutoff","density","maxcor")` with
`cutoff` the default; the chosen cutoff, its correlation and density go into `history`.
Ledger entry: not a UCINET batch routine (UCINET's is interactive). Open detail: whether the
whole table is worth exposing (`xdichotomize(net, method = "maxcor", table = TRUE)` printing
it, or a separate small function); recommendation: no, the three `history` numbers suffice.
(ii) The diagonal. The menu default writes the else-value (0) on the
diagonal; the Phase 0 goldens made with the CLI showed the rule applied to the diagonal
(ledger entry 1, "UCINET 6.849 no longer zeroes it"). Claude Code compares the CLI unit with
the form and reports; recommendation: R follows the menu form (`diagonal = c("else","zero",
"missing","then","rule")`, default `"else"`), and entry 1 is corrected. Signature:
`xdichotomize(net, cutoff = 0, op = ">", then = 1, else = 0, density = NULL, diagonal =
"else")`, op as the six strings `">"`, `">="`, `"=="`, `"<="`, `"<"`, `"!="`; multi-relation
input handled per relation; 2-mode allowed (no diagonal question).

**5.2. xsymmetrize.** Transform | Symmetrize (`xsymmetrize.pas`, engine `usym.symmetrize` in
G2Tools). Sixteen methods, in dialog order: Maximum (default), Minimum, Average, Sum,
Difference, Product, Division, Lower Half, Upper Half, Upper > Lower, Upper >= Lower, Upper =
Lower, Upper <= Lower, Upper < Lower, Upper NOT EQUAL Lower, abs(diff)/sum. Missing-value rule:
"Choose non-missing value" (default) or "Both missing". Square 1-mode only. The log prints,
per relation, the density before, the number and percentage of symmetric pairs, the number and
percentage of reciprocated dyads, the matrix, the density after, and the correlation with the
input. Recommendation: all sixteen under lowercase names (`"max"`, `"min"`, `"mean"`, `"sum"`,
`"difference"`, `"product"`, `"division"`, `"lower"`, `"upper"`, `"upper>lower"` … or spelled
`"gt"`, `"ge"`, `"eq"`, `"le"`, `"lt"`, `"ne"`, and `"absdiffsum"`), `method = "max"` default,
`missing = c("nonmissing","both")`; the six summary statistics go into `history`; the result
has `directed = FALSE`.

**5.3. xnormalize.** Transform | Normalize (`Xstdize.pas`, dialog `Normdlg`). Dimension:
Matrix, Rows, Columns (**the default**, `dim = 3`), Both. Method: Marginal (sum, the default),
Mean, Std-Dev, Z-Score, Euclidean, Maximum, SQRT-Marginal, Correspondence. Targets: marginal
sum 1 (a "constant" field, default 0, is added to cells first), mean 0, standard deviation 1,
Euclidean norm 1, maximum 1; "Both" iterates rows and columns until every margin is within the
tolerance (0.001) or 100 iterations, and warns on non-convergence. "Diagonal valid?" defaults
to **Yes**; when No, the diagonal is set missing before normalising. Non-square data force the
diagonal valid. Recommendation: `xnormalize(net, by = c("cols","rows","matrix","both"), method
= c("sum","mean","sd","zscore","euclidean","max","sqrtsum","correspondence"), diagonal = TRUE,
tolerance = 0.001, maxit = 100)`, defaults as UCINET's; the iteration count in `history`.

**5.4. xgeodesic.** Network | Cohesion | Geodesic Distances (`uc_geodesicdistances.pas`/
`.dfm`). Input: non-valued adjacency only (the dialog's only "type of data" item; valued
distances are a different routine, not in the crosswalk). Output transformation: none
(default) or reciprocal distances. Undefined (unreachable) pairs: with no transformation,
missing (default), N, or largest distance + 1; with reciprocal, missing, 1/N, 1/(largest+1),
or zero (default). Diagonal: missing, 0 (default with no transformation), 1. The log prints
the matrix, the average and standard deviation of the off-diagonal distances, and a frequency
table of distance values. Recommendation: `xgeodesic(net, directed = NULL, unreachable =
c("missing","n","max+1"), reciprocal = FALSE, diagonal = 0)`, returning a dataset (G2 a) with
the average, sd and frequency table in `history`; `weighted =` and `method = "frequency"` from
the first draft are dropped, since neither is in this routine (the count of geodesics is
UCINET's separate "No. of Geodesics" routine and xbetweenness already computes it
internally). The shared geodesic code in `R/centrality-internals.R` is the engine.

**5.5. xjoin, xunpack, xcombine, xmultiplex; time stack.** (a) Data | Join | Join Matrices
(`uc_JoinMatrices.pas`): stacks datasets of identical dimensions into one multi-relation
dataset; datasets of the wrong size are skipped with a log line; relation labels by matrix
name, filename + matrix name, filename + number, or "smart labels" (default: filename when a
dataset has one matrix, filename-matrixname when names collide). Join Rows and Join Columns
are the other two items (append as rows or columns). (b) Data | Unpack (`uc_UnPack.pas`):
writes each selected relation of a stack as its own dataset, with an optional prefix. (c)
Transform | Matrix Operations | Between datasets | Statistical summaries
(`xbetweendatasetaggregations.pas`): over several separate datasets, cellwise Sum, Average,
Minimum, Maximum, Elementwise multiplication, with "use boolean math", "ignore diagonal in
square matrices" and a missing-values flag. Within dataset | Aggregations
(`xwithindatasetaggregations.pas`) does the same across the relations of one stack (Sum
default, Average, Minimum, Maximum, Std Deviation; "rows & cols - aggregate across matrices"
is the option that yields one matrix; diagonal valid default No). (d) Transform | Graph
Theoretic | Multiplex (`uc_MultiplexCoder.pas`): codes each cell as the integer whose binary
digits say which relations have a tie there (relation k contributes 2^(k-1)); the log prints
a legend. (e) Transform | Time Stack (`uc_timestack.pas`): stacks networks with different node
sets, matching on labels, nodes to keep Intersection or Union (default), absent nodes as
missing (default) or zeros, plus a node-by-network id vector. Recommendation: `xjoin(...,
names = NULL)` accepts networks or a list with identical labels and stacks them (relation
names from the arguments, titles, or `names`); `xunpack(net, relation = NULL)` returns a list
of one-relation datasets, or one when `relation` is given; `xcombine(net, relations = NULL,
method = c("sum","mean","min","max","sd","product"), diagonal = FALSE)` collapses the relations
of a stack (or a list of separate networks) into one matrix, the union of the two UCINET
menus; `xmultiplex(net)` as UCINET's coder with the legend in `history`. Time Stack is not a
separate function: `xjoin(xmatch(t1, t2, t3, nodes = "union", fill = NA))` does it, and the
help page for xjoin says so.

**5.6. xcombinenodes.** Two UCINET routines. Transform | Aggregate | Collapse (`Xcollaps.pas`)
takes typed instructions ("ROWS 1 2 3", "COLS …", "BOTH …", "MATRICES …"), methods Average,
Sum (default), Maximum, Minimum, diagonal valid default No. Transform | Aggregate | Block -
Aggregate by Partitions (`uc_blockmatrix.pas`) takes a row partition and a column partition
from attribute datasets matched by label, methods Average (default), Count > 0, Maximum,
Minimum, Std Deviation, Sum, "utilize diagonal (reflexive ties)" unchecked by default, and
prints the number-of-ties and density tables plus an autocorrelation. The crosswalk's
`xcombinenodes(net, attribute, method = c("sum","mean","density","max"))` is the second
routine, and UCINET's "density" there is the Average of the cells. Recommendation:
`xcombinenodes(net, attribute, method = c("mean","sum","count","max","min","sd"), diagonal =
FALSE)`, `attribute` per G3, `mean` default as UCINET's Block; the Collapse instruction
format is not reproduced (a partition vector covers it). Group labels from the attribute
values.

**5.7. xattributetomatrix.** Data | Attribute to matrix (`uc_AttributeToMatrix.pas`, formulas
in `G2Tools\uattributetomatrix.pas`). Methods: Exact Matches (default; 1 if equal), Difference
(a_i − a_j, asymmetric), Absolute Difference, Squared Difference, Product, Sum, Identity
Coefficient (2·a_i·a_j / (a_i² + a_j²)), Dup. rows (receiver effect: cell (i,j) = a_j), Dup.
columns (sender effect: cell (i,j) = a_i), Min/Max (min(a_i,a_j)/max(a_i,a_j), 1 when equal).
Attribute normalisation first: none (default), centre, standardise. Missing attribute values
give missing cells. Output names `<input>-same<var>`, `-diff`, `-absdiff`, `-sqrdiff`,
`-prod`, `-sum`, `-ident`, `-receiver`, `-sender`, `-minmax`. Recommendation:
`xattributetomatrix(attribute, method = c("same","diff","absdiff","sqrdiff","product","sum",
"identity","receiver","sender","minmax"), normalize = c("none","center","standardize"), net =
NULL)` where `attribute` is a vector, a column name of `net$attributes`, or `data$col`; labels
from the vector's names or from `net`; returns a 1-mode `xucinet`, `directed = TRUE` for the
three asymmetric methods and `FALSE` otherwise. The two-attribute form from the first draft is
dropped (not in UCINET).

**5.8. xmatch.** Revised 20 Sep 2026 after Steve pointed out that UCINET has one routine for
matching a network to an attribute dataset and another for matching two networks, each with
the choice of intersection, union, or one dataset as the authority, and that the R function
should take any number of datasets (three time points, keep the nodes present in all).
Recommendation: `xmatch(..., nodes = c("first","intersection","union","last"), by =
"rownames", fill = NA, attach = FALSE)`. `...` is any mix of networks and attribute data
frames; one function serves both UCINET routines because R dispatches on class. `nodes` picks
the node set and order: `first` (default; the ch05 case, network then attributes), `last`,
`intersection` (nodes in every dataset, ordered as in the first), `union` (every node
anywhere, ordered by first appearance, absent nodes filled with `fill`; Claude Code reads what
UCINET fills with under union and sets the default to match). `by` names the label column of a
data frame or `"rownames"`. Labels match exactly (case-sensitive), as UCINET's do. A message
reports per dataset how many nodes were dropped and added. Networks keep class, mode,
directedness, relation stack and title; data frames stay data frames. Returns a named list in
argument order (names from the arguments or titles): `m <- xmatch(t1, t2, t3, nodes =
"intersection"); m$t1`. With exactly one network and one or more data frames, `attach = TRUE`
returns the network alone with the frames joined into `$attributes`, which is the form the
ch05 text uses. Open for Steve: whether the two-dataset call `xmatch(net, attr)` should
return the list (consistent) or just the reordered attribute frame (simpler in the chapter). Source
check 21 Sep: Data | Match datasets has Match 1-Mode Datasets, Match 2-Mode Datasets, Match
1-Mode Net w/ Attrib Data (`uc_MatchNetAttrib`: keep network nodes, attribute nodes,
intersection, union (default); sort by first occurrence (default), alphabetical, numerical;
case sensitive on) and Match Multiple Datasets (`uc_MatchAnyDatasets`: primary (default),
intersection, union; sort by primary order (default), lexicographic, numerical; rows and
columns kept identical for 1-mode). Absent cells under union are left at the allocation value
(zero, to be confirmed by Claude Code); Time Stack offers missing (default) or zeros. So
`nodes = c("first","intersection","union","last")` matches UCINET's choices, `fill = NA` is the
Time Stack default and `fill = 0` the Match default; a `sort = c("first","alphabetical",
"numerical")` argument is added.

**5.9. xsimilarities, ximpute, xrecode.** Rewritten 21 Sep 2026 from the UCINET source
(`C:\Dev\ucinet\Source`, units named below); the first draft listed measures from memory and
invented a "Data | Missing values" routine that does not exist.

*(a) xsimilarities.* UCINET's current routine is Tools | Similarities & Distances
(`uc_SimDis.pas`/`.dfm`; the CLI `similarities` command and Tools | Legacy Routines |
Similarities are the older `xsimilarities.pas`, five measures only). One dialog, two radio
groups. Similarity measures, in dialog order: Pearson correlation, covariance, cross-products,
average cross-products, matches, Jaccard, valued Jaccard, identity coefficient, cosine/Tucker's,
Cohen's kappa, Yule's Q. Dissimilarity measures: Euclidean distance, Manhattan distance, average
absolute difference, normed SSD, proportion of non-matches, Jaccard distance, Hamming distance,
sum of squared differences. Mode: rows, columns, matrices; the dialog default is **Columns**
(`pMode.ItemIndex = 1`). "Diagonal values are valid" is unchecked by default and forced on for
data that are not 1-mode; when not valid, `setdiagonal(bna)` makes the diagonal missing before
the profiles are compared, so cells (i,i) and (j,j) drop out of every pair. "Matrices" mode
vectorises each relation (off-diagonal cells unless the diagonal is valid) and compares
relations. The log prints the matrix and then `Cronbach's Alpha` for it. Output name:
`<input>-<first three letters of the measure>-<R|C|M>` (`campnet-Pea-C`). Recommendation:
one function, `xsimilarities(net, method = "correlation", mode = c("cols","rows","relations"),
diagonal = FALSE)`, with `method` accepting all nineteen measures under lowercase names
(`"correlation"`, `"covariance"`, `"crossproducts"`, `"avgcrossproducts"`, `"matches"`,
`"jaccard"`, `"valuedjaccard"`, `"identity"`, `"cosine"`, `"kappa"`, `"yulesq"`, `"euclidean"`,
`"manhattan"`, `"avgabsdiff"`, `"nssd"`, `"nonmatches"`, `"jaccarddistance"`, `"hamming"`,
`"ssd"`), ported from `utsimilarity.pas`/`usim.pas` in G2Tools so the numbers match; returns a
`xucinet` dataset (G2 a) titled as UCINET names it; the result carries a `history` line saying
whether the measure is a similarity or a dissimilarity (xmds and xhclust still require
`type=`; nothing is inferred). Question: keep Cronbach's alpha (in `history`, or dropped)?
Recommendation: dropped from R, since it is a by-product of the correlation case only.

*(b) Missing values.* UCINET has three Transform-menu items. (1) **Replace Missing Values**
(`uc_replacena.pas`): fills each missing cell of the input from a source dataset of the same
shape, transposed by default ("Matrix containing replacement values needs to be transposed",
checked), and the source may be the input itself, which is reconstruction from the transpose;
output `-rna`. (2) **Znidarsic et al Imputation of Ties** (`uc_ImputeMissing.pas`, algorithms in
`G2Tools\uimputemissing.pas`): methods RE (reconstruct from transpose; ties among missing
respondents: zero, 1 if density >= cutoff, random with p = density, leave missing; dialog
default zero, cutoff 0.5), MEAN (mean of incoming ties, for valued data; round to integer
checked, round-half-up), MO (modal incoming, for binary), **REMO** (RE then MO; the dialog
default), TM (global mean, rounding as MEAN), kNNMedian (k = 3), NTI (set all missing to a
value, default 0), RAND, COPY (copy friends' choices). The diagonal is set to missing before
imputation and is not imputed; output `-imp`; log title "Imputation of Missing Values for
Networks". (3) **Give Non-Responders Missing Rows** (`uc_MissingRows.pas`): marks the rows of
non-responders, chosen by an attribute, as missing; a preparation step for (2). The 3e text
(5.5.5, "Impute missing ties") and the 1e name xImputeMissingData refer to (2). Recommendation:
`ximpute(net, method = c("remo","re","mo","mean","tm","knn","nti","random","copy"), ties =
c("zero","density","random","missing"), cutoff = 0.5, round = TRUE, k = 3, value = 0, seed =
NULL)` as a port of `uimputemissing.pas` with the dialog defaults; `xreplacemissing(net, source
= net, transpose = TRUE)` for (1), a separate function because it is a separate UCINET routine
(alternative: `ximpute(method = "replace", source = )`, one export fewer); (3) not implemented
unless the ch05 text mentions it (Claude Code checks with the lint). Both return `xucinet`
datasets with the number of cells filled in `history`.

*(c) xrecode.* Transform | Recode (`Xrecode.pas`, `xRecodeDlg.pas`): a schedule of rules
"values *first* to *last* become *newvalue*", ranges inclusive; every rule is tested against
the **original** cell value and the last matching rule wins; applies to selected rows,
columns and matrices (default ALL); "Include diagonal values?" defaults to No for square data
and is forced to Yes otherwise; missing cells are left alone; output `-Rec`; the log prints the
schedule and the matrix. Recommendation: `xrecode(net, from, to, diagonal = FALSE, rows = NULL,
cols = NULL, relations = NULL)` where `from` is a numeric vector of single values or a
two-column matrix (or list of `c(low, high)`) of inclusive ranges and `to` the replacement per
rule, with UCINET's semantics (original value tested, last rule wins); `rows`/`cols` take
labels or indices. Transform | Reverse (`reversevalues`) is a special case (`xrecode` with a
computed schedule) and gets no function unless the text uses it.

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
formula variables are user names, which is fine. `data =` accepts any node-level result object
(G2 c). Tabled 20 Sep: whether `xcorrelation` is the right name for the node-level permutation
correlation, since it is a valuable name and the routine is rarely used; to be decided before
the chapter 14 prompt runs, with the crosswalk updated if it changes.

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
