# xucinet 2.0.0.9000 (development)

## Chapter 7: visualization (issue #30)

* `xplot()`: network drawings in base graphics. Node colour, size, shape and
  label size from attributes, names or node-level results; tie width and
  darkness from values; several relations by colour and line style; tie
  cut-off, node filtering, ego networks, isolates left out in place;
  `file =` writes png, jpg, tiff, pdf or svg. No underscores in argument
  names (Steve, design 7.2). Ledger 44.
* `xlayout()`: spring (Fruchterman-Reingold), Kamada-Kawai, classical and
  non-metric MDS of geodesic distances, circle, random, grouped by an
  attribute, bipartite; the result is reused by label in `xplot(layout =)`.

## Chapter 14: testing hypotheses (issue #27)

* One permutation engine (`R/permute-internals.R`): every test reports
  UCINET's three proportions and counts p = (1 + count)/(1 + nperm)
  (ledger 40).
* `xregression()` and `xcorrelation()`: Node-level Regression, Y permutation
  of t; `nperm = 0` for the classical test.
* `xqap()`: QAP Correlation, all seven of the detailed analysis's measures.
* `xmrqap()`: Double Dekker semi-partialling (default) or Y permutation;
  `xlrqap()`: LR-QAP. UCINET issues 31 and 32, ledger 41.
* `xdensitybygroups(test = TRUE)`: the ANOVA density models (constant
  homophily, variable homophily, structural blockmodel), always fitted, with
  permutation p-values on request. UCINET issue 33, ledger 42.
* `xautoregression()`: network effects (lag) and disturbances (error) models
  by maximum likelihood, wrapping `sna::lnam()`, since UCINET has no routine
  (issue #28, ledger 43). Needs `sna` and `numDeriv`.

## Chapter 13: two-mode networks (issue #26)

* `xaffiliations()`: Data | Affiliations, all thirteen of the dialog's
  methods, including the SDSM backbone (Neal 2014), rows or columns, opposite-mode
  normalization; covariance divided by n (UCINET issue 30, ledger 38).
* `xbipartite()`: Transform | Bipartite, with each node's mode in
  `$attributes`.
* `xbicliques()`: UCINET's `biclique()`, in its order, with participation and
  co-membership per mode and the clustering of the book's Figure 13.4.
* `xdegree()`, `xcloseness()`, `xbetweenness()` and `xeigenvector()` take
  2-mode data, with `mode = "both"`, `"rows"` or `"cols"`, and report UCINET's
  2-Mode Centrality scores (ledger 37).

## Chapter 12: equivalence, blockmodels, core/periphery (issue #23)

* `xstructuralequivalence()`: UCINET's Profile similarity, every relation
  stacked into one profile, rows and columns, the five diagonal treatments
  (reciprocal swapping by default), seven measures, and UCINET's
  weighted-average clustering (size-weighted, which is `xhclust()`'s
  `"average"`).
* `xblockmodel()`: a given partition as a blockmodel: the blocked matrix,
  block values, an image matrix and UCINET's autocorrelation fit (ledger 34).
* `xcoreperiphery()`: the categorical and continuous models in one function,
  ported from UCINET's current code; reproducible under `seed` (ledger 35,
  UCINET issue 29). 2-mode waits on a decision.
* `xrege()`: White and Reitz's REGE as UCINET runs it (`sStdrege`), all
  relations, 3 iterations, clustered like the profile routine (ledger 36).

## Level of analysis and closeness centralization (23 September 2026, issue #20)

* A function returns the same fields whatever its arguments; arguments choose
  what is printed (SPEC addendum, 23 September 2026). Ledger entry 32.
* `xreciprocity()` is whole-network only. The node table is the new
  `xegoreciprocity()` (Network | Ego Networks | Egonet Reciprocity), and
  `xegonet()` gains its `Symmetric` column.
* `xhomophily()` no longer returns the mixing matrix; it is `xmixing()`'s.
* `xtransitivity()` always returns the triplet and the triad measures (the
  triad ratio as `Triad Transitivity`); `xegoaltersimilarity()` always returns
  every continuous measure; `xhclust()` always has a `Cluster` column;
  `xstructuralholes()` returns the same eleven columns under both models.
* `xgirvannewman()` keeps every partition down to isolates; `k` sets which are
  printed.
* `xcloseness()$summary` has a closeness centralization, from UCINET's legacy
  Closeness routine (ledger entry 31), and `xcentralization()` returns all
  four centralizations, with `measure = "closeness"` now available.
* Report objects gain `show_summary`, `show_columns` and `show_matrix_columns`.
* `xcommunities(net, ...)` runs all five community methods and returns a
  node-by-method membership table, with clusters and modularity per method; it
  no longer takes `method =` (Steve, issue #21).
* 1e aliases: `xNegativeDegreeCentrality()` is withdrawn (use `xdegree()` on
  the negative relation); `xNegativeWeightedCentrality()` runs
  `xpncentrality()` on the negated matrix (issue #21).
* The six ego-network routines take `ties =` instead of `direction =`, and
  `"undirected"` is now `"any"` (Steve; SPEC addendum; issue #22).
  `direction` stays in the centrality routines.
* `xinverseweighteddegree()`: UCINET's Inverse-Weighted Degree, with the three
  faults of UCINET issue 28 corrected (ledger entry 33; issue #22).

## Chapter 11: subgroups (23 September 2026)

* igraph moves from Suggests to Imports (design answer G1).
* `xcliques()`: maximal cliques in the order UCINET finds them (a step-for-step
  port of its Bron-Kerbosch), participation scores, the co-membership matrix
  and its average-link clustering. Weak (a tie either way) by default.
* `xfactions()`: UCINET's Factions, the tabu search with its four fit
  measures (Hamming, Phi, Modularity, Entailment). Delphi's random number
  generator is ported, so `seed =` reproduces UCINET's run.
* `xgirvannewman()`: ported natively, so tied edges are removed together as
  UCINET removes them; one partition per new component count, each with its
  modularity.
* `xlouvain()`: a native, deterministic port of UCINET's Louvain Method,
  without its two bugs (UCINET issue 26, ledger entry 27). 2-mode input waits
  on issue #18.
* `xfastgreedy()` and `xlabelpropagation()` on igraph (ledger entry 28).
* `xcommunities(method = )` runs any of the five and returns the same shape.
  Every partition routine reports `Cluster` and a `Modularity` computed the
  same way.
* The 1e Walktrap aliases stop and name `xcommunities()`; Walktrap is not in
  2.0 (design answer 11.5).
* Report objects gain `hide` (a matrix kept but not printed) and `epilogue`
  (lines printed last).
* Ledger entries 27-30; UCINET issue 27.
* Faster, same answers (issue #19): `xgirvannewman()` takes edge betweenness
  from `igraph::edge_betweenness()`; `xlouvain()` scores moves by the change in
  modularity; `xfactions()` scores moves from group totals and takes its
  starting distances from `igraph::distances()`. On a 200-node network the
  three went from 5.4, 4.8 and over 11 seconds to 0.2, 0.1 and 0.4. Tests hold
  each to the partitions of the straightforward version.

## Steve's answers of 23 September 2026

* `xmixing()`, new: Network | Mixing Tables. The observed mixing table, and
  the expected table and observed/expected ratio under all three of UCINET's
  models (Density, Configuration, Fixed outdegree) in one call.
* `xdensitybygroups()` now returns the density table only: its `model`
  argument and its Observed, Expected and Ratio tables have moved to
  `xmixing()`. `test =` stays for chapter 14. Ledger entry 26.
* `xeigenvector()` reports the eigenvector centralization, as a percentage,
  and `xcentralization(measure = "eigenvector")` returns it. Closeness has none
  to return: UCINET's Closeness dialog reports no centralization.
* `xnormalize()` now follows `Xstdize.pas`, the unit the Normalize menu runs,
  rather than `uNormalize.pas`: `"mean"` subtracts the mean instead of dividing
  by it; `constant` replaces zeros instead of being added to every cell; a row
  or column whose divisor is not positive comes back missing; `diagonal =
  FALSE` leaves the diagonal missing; `by = "both"` starts with the columns,
  stops when every margin is within tolerance of its target, and targets
  `nrow/ncol` for the column sums. New `method = "correspondence"`.
* `xhomophily(weighted = FALSE)` dichotomizes before every measure, not just
  the mixing matrix (UCINET issue 21).
* `xdichotomize()` accepts `elsevalue =` for `otherwise =`.
* `xhclust()` no longer prints the partition matrix, which UCINET saves but
  does not print; it is still in `$nodes`.
* Ledger entries 23-26; UCINET issue 25.

## Chapter 8: ego networks (23 September 2026)

* `xegonet()`: the sixteen columns of Egonet Basic Measures - size, ties,
  pairs, density, reciprocal distance, diameter, weak components, two-step
  reach, brokerage and ego betweenness - for the undirected, out- or
  in-neighbourhood. The crosswalk's `include_ego` is gone: the dialog has no
  such option.
* `xstructuralholes()`: effective size, efficiency, constraint, hierarchy,
  ego betweenness and the rest, with the dyadic redundancy and dyadic
  constraint matrices. UCINET's ego-network model by default, its
  whole-network model with `method = "whole"`; ledger entry 17 sets both
  beside `igraph::constraint()`.
* `xtiecomposition()` and `xvaluedtiecomposition()`: how each ego's ties are
  spread over the relations of a multi-relation network, and what their values
  are.
* `xaltercomposition()` and `xegoaltersimilarity()`: one function each for
  UCINET's categorical and continuous menu items, deciding which from the
  attribute (design question G3) unless `type =` says. The 1e aliases
  `xAlterCompositionCat()` and the rest set `type` for you.
* One `direction` argument across the chapter says which ties define the ego
  network, each function offering its own dialog's choices and default.
* Four UCINET bugs found and not copied: `dev/UCINET-ISSUES.md` issues 17-20,
  ledger entries 18-20. Ledger entry 21 records that these routines report the
  first relation of a multi-relation dataset, as every node-level routine here
  does, where UCINET loops over them all.

## Chapter 10: whole-network measures (23 September 2026)

* `xcohesion()`: the 33-measure block of Network | Whole-Network Measures,
  golden-tested against the existing Phase 0 density fixtures. `Components`
  there counts **strongly** connected components, and the K-core index and
  `Deg Centralization` describe the underlying undirected graph whatever
  `directed` says, both as UCINET does.
* `xreciprocity()`: the dyad and arc ratios, always both, with UCINET's six
  node-level proportions. Valued data are not dichotomized; see ledger entry 16
  for why the two halves of the report can then disagree.
* `xtransitivity()`: the twelve triplet measures, including the centred ones of
  Dekker, Krackhardt and Snijders (2019), or the triad counts under
  `method = "triads"`. The overall clustering coefficient is folded in and
  there is no node-level one (design question 10.2).
* `xcyclicality()`: the same two-paths closed the other way.
* `xcomponents()`: weak or strong, with membership, sizes and UCINET's
  heterogeneity figures. `Normalized heterogeneity` is the fragmentation of
  the network, which is the identity UCINET's log points out.
* `xcentralization()`: hands back the centrality routine's own figure rather
  than recomputing it. Degree and betweenness only for now: UCINET reports a
  closeness and an eigenvector centralization that `xcloseness()` and
  `xeigenvector()` do not carry, and no golden holds either figure.
* `xhomophily()`: the seven measures of Homophily | Categorical. Note that
  `weighted` affects only the mixing matrix, which is UCINET's behaviour.
* `xdensitybygroups()`: the density, observed, expected and ratio tables of
  Mixing Tables w/ Expected Values, under the Density model. `test =` arrives
  with chapter 14.
* `xkeyplayer` is dropped (design question 10.6) and its crosswalk row with it.
* Differences ledger entry 16; `dev/UCINET-ISSUES.md` issue 16.

## Chapter 5: transformations (22 September 2026)

* `xtranspose()`, `xdichotomize()`, `xsymmetrize()`, `xnormalize()` and
  `xrecode()`: the first of the chapter 5 transformations. Each returns a
  `xucinet` dataset rather than a report (design question G2), titled the way
  UCINET names the dataset it saves, with a `history` attribute carrying the
  figures the UCINET log prints.
* `xdichotomize()` follows the Transform | Dichotomize menu form: six
  operators, configurable `then` and `otherwise` values, and five ways to
  treat the diagonal, defaulting to the else-value as the dialog does. It can
  also choose the cutoff itself, by target `density` or by `method = "maxcor"`.
* `xsymmetrize()` offers all sixteen of the dialog's methods.
* `xgeodesic()`: geodesic distances, with UCINET's reciprocal transformation and
  its rules for unreachable pairs and the diagonal, which move together as the
  dialog's do. It returns a dataset, so `xmds(xgeodesic(net), type = "d")`
  works.
* `xsimilarities()`: all nineteen measures of Tools | Similarities & Distances,
  eleven similarities and eight distances, comparing rows, columns or
  relations. Note that UCINET's covariance divides by *n*, so it is not
  `stats::cov()`.
* `xattributetomatrix()`: all ten methods, including the `"sender"` and
  `"receiver"` forms a QAP regression wants as predictors.
* `xcombinenodes()`: aggregate a network by a partition, six statistics.
* `xmatch()`: put any number of networks and attribute tables on one node set.
* `xjoin()`, `xunpack()`, `xcombine()`, `xmultiplex()`: build, split, collapse
  and code multi-relation datasets.
* `ximpute()`: the nine Znidarsic et al. methods, and `xreplacemissing()` for
  Transform | Replace Missing Values.
* `xread()` and `xfromedgelist()` gain `duplicates = c("sum", "last", "error")`.
  **This changes what a repeated edge means:** duplicates are now summed, as the
  chapter 5 text says, where the reader previously kept the last value. An
  unweighted pair listed twice therefore comes back as 2. Pass
  `duplicates = "last"` for the old reading.
* Projects are not implemented (design question 5.11). `xCreateProject()` and
  the other three 1e project names still resolve, and stop with an explanation
  of what to do instead.
* Differences ledger entries 13, 14 and 15; `dev/UCINET-ISSUES.md` issue 15.
* `dev/COVERAGE.md`, regenerated by `dev/make-coverage.R`: every crosswalk row
  against its 2.0 function and how far along it is.

## Chapter 6: multivariate techniques (18 September 2026)

* `xmds()`: classical and non-metric multidimensional scaling of a proximity
  matrix, ported from borgworld's `bclassicalmds()` and `bnonmetricmds()`.
  `type=` is required. `xshepard()` draws the Shepard diagram of a non-metric
  result.
* `xcorrespondence()`: correspondence analysis, ported from borgworld's
  `bcorresp()`, with the total inertia computed from the full spectrum.
* `xhclust()`: Johnson's hierarchical clustering, ported from borgworld's
  `bhiclus()`, reported in UCINET's layout: text cluster diagram, one partition
  per distinct merge level, measures of cluster adequacy, cluster sizes.
* `as_xucinet()` accepts `dist` objects.
* `new_xucinet_output()` gains `fields` (header lines) and `preamble`
  (preformatted lines printed before the tables).
* Differences ledger entries 6-12.
