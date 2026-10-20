# xhclust(): report merge levels in the units of the input (similarities)

Written 19 Oct 2026 in Cowork, at Steve's request; split on 20 Oct 2026 into this package part
(issue #40) and a book part (`asnr2e/docs/prompts/xhclust-similarity-levels.md`, asnr2e#9).

## The problem

With `type = "similarities"`, `xhclust()` converts the matrix to dissimilarities as
`max(off-diagonal) - x` (`to_dissimilarity()` in `R/proximity-internals.R`) and then reports
everything on that converted scale: the level labels of the text cluster diagram, the
column names of `$nodes` (`1(8)206`), `$levels`, and the y axis of the `plot = TRUE`
dendrogram. For the REGE coefficients of the book's Matrix 12.6 the diagram therefore reads
0.0000, 0.0308, 0.0337, ... 0.5182, which a reader cannot match to the matrix.

UCINET does not do this. `Johnson2` and `JohnsonF2` in `Tools/G1Tools/Uclus.pas` (tools repo)
take `sim: boolean` and cluster the similarities directly: `GetClosestPair` looks for the
*largest* value when `sim` is true, single link uses `maxcomp` and complete link `mincomp`, and
`level.cell^[npart] := dist` stores the similarity itself. The 3e Figure 12.8 (UCINET output)
shows levels 88.377, 85.295, ... for that reason. So this is an undocumented difference from
UCINET, not a design decision; it is not in `inst/DIFFERENCES.md`.

## What to change (Steve, 19 Oct 2026: the dendrograms should show the REGE coefficients)

For `type = "similarities"`, report levels as similarities, as UCINET does; dissimilarity input
is unchanged.

1. Keep clustering on `d = mx - x` internally (the partitions are the same either way), but
   convert every reported level back: `level = mx - height`.
2. Text cluster diagram (`format_uci_dendrogram()` via `level_lab`): similarity levels, which
   decrease down the diagram, as in UCINET. `hclust_decimals()` then sees the similarity values.
3. `$nodes` column names and `$levels`: similarity levels.
4. `plot = TRUE`: draw the dendrogram with the y axis in input units. For similarities the
   axis runs downwards from the largest merge value (tick labels `mx - y`), or equivalently
   plot `as.dendrogram()` with heights `mx - level` and relabel the axis; the label should say
   "Similarity" (or "Level") rather than "Level" on a dissimilarity scale. Check it in
   greyscale.
5. `$hclust` stays a plain `stats::hclust` on the dissimilarities (so `cutree()` works), but
   document that its heights are `mx - level` for similarity input; consider storing `mx` in the
   result (e.g. `$max_similarity`) so callers can convert.
6. The `Note: Similarities converted to dissimilarities as ...` assumption line: keep it only if
   the report still shows anything on the converted scale; otherwise drop it.
7. Callers: `xrege()`, `xstructuralequivalence()`, `xbicliques()` and `xcliques()` use
   `xhclust()` internally; check their printed reports and `$hclust` users.
8. Tests: update `tests/testthat/_snaps/xhclust.md` and the tests listed by
   `grep -rl xhclust tests`; add a test that the single-link levels of the REGE matrix for
   `sampson` (Esteem, Disesteem) start 0.88377, 0.85295, 0.85003, 0.80413 (to 5 decimals) and
   that the nine-cluster partition is {Bonaventure, Ambrose, Hugh, Boniface, Mark, Albert},
   {Berthold, Victor}, {Peter, Gregory}, {Basil, Elias, Simplicius} plus singletons.

Run `devtools::check()` (0 errors, 0 warnings) before committing; update `dev/STATUS.md`.
