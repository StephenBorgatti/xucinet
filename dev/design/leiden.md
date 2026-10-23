# Leiden community detection: the shared specification

Written 23 Oct 2026 (Claude Code) for xucinet #41 and ucinet #46. `xleiden()` (R) and
`G2Tools\uleiden.pas` (Delphi) implement exactly this, step for step, so that one seed gives
one partition in both programs. Anything not fixed here (an iteration order, a tie rule, the
number of random draws) is a bug in this document.

Source: Traag, Waltman and van Eck (2019), "From Louvain to Leiden: guaranteeing well-connected
communities", *Scientific Reports* 9, 5233, Algorithm A.2 in the supplement.

## Decisions (Steve, 23 Oct 2026)

- Objective: modularity with a resolution parameter gamma (default 1). No CPM.
- Randomness: seeded, with Delphi's `System.Random`; `seed = NULL` in R picks one from 1 to
  1000 and reports it. The UCINET dialog has a seed box (default 1).
- `xcommunities()` gets a Leiden column.
- UCINET: after 6.850, on branch `leiden` (off `v6850`) in `ucinet` and `tools`.
- 1-mode data only in this version.

## Input

1. Pick the relation; missing cells are 0; negative values are set to 0 (note
   "Negative values removed.").
2. If the matrix is not symmetric, symmetrize it: `max` (default), `min`, `average` or `sum`
   (note "Data symmetrized by <method>."). There is no "do not symmetrize".
3. The diagonal is set to 0.

Call the result `W` (n x n, symmetric, non-negative, zero diagonal). If n < 2 or the total
of `W` is 0, the partition is every node alone and nothing below runs (no random draws).

## Notation

At every level the graph is a symmetric matrix `W` that may have a diagonal (aggregated
graphs carry the weight inside a community on it, both directions counted).

- `k_v = sum_u W[v,u]`, diagonal included (the weighted degree).
- `tw = sum_{v,u} W[v,u]`, the total (2m for a graph). It is the same at every level.
- The neighbours of v are the u != v with `W[v,u] > 0`, always taken in increasing index.
- `eps = 1e-12 * tw`, the tolerance for every comparison below.
- For a node v and a set C not containing v: `w(v,C) = sum_{u in C} W[v,u]` and
  `K(C) = sum_{u in C} k_u`.
- The gain of v joining C: `g(v,C) = w(v,C) - gamma * k_v * K(C) / tw`; `g(v, empty) = 0`.

Moving v from A to B changes modularity at resolution gamma by `2 / tw * (g(v,B) - g(v,A - v))`,
so every comparison uses `delta = g(v,B) - g(v,A - v)`, in units of tie weight.

## Random numbers

Delphi's generator, as in `delphi_rng()` (R/community-internals.R):
`RandSeed := RandSeed * $08088405 + 1 (mod 2^32)` before every draw, and

- `Random(n)` = `floor(UInt32(RandSeed) * n / 2^32)`, an integer 0..n-1;
- `Random` (no argument) = `UInt32(RandSeed) / 2^32`, a real in [0, 1).

`RandSeed := seed` once, before the first iteration.

**Shuffle(a[1..len])**: for i from len down to 2: `j := 1 + Random(i)`; swap a[i] and a[j].
(len - 1 draws; none when len < 2. The same as the 2-mode Louvain's ShuffleArray.)

## The algorithm

### Leiden (the whole run)

```
P := every node alone (labels 1..n)
for iteration := 1 to 50:
    P_new := OneIteration(W, P)
    if P_new is the same partition as P (renumbered by first appearance): P := P_new; stop
    P := P_new
```

The number of iterations run is reported. Reaching 50 adds the note "Stopped after 50
iterations without converging."

### OneIteration(W, P)

```
G := W;  Pg := P;  map[i] := i for every original node i
loop:
    Pg := MoveNodesFast(G, Pg)
    if Pg has as many communities as G has nodes: stop
    R := RefinePartition(G, Pg)
    if R has as many communities as G has nodes: stop
    renumber R by first appearance over the nodes of G (1..n')
    G' := H' G H, where H is the n x n' indicator of R      (diagonal kept)
    Pg'[r] := Pg[any member of r], then renumbered by first appearance over r = 1..n'
    map[i] := R[map[i]] for every original node i
    G := G';  Pg := Pg'
return Pg[map[i]] for every original node i, renumbered by first appearance
```

### MoveNodesFast(G, P)

Labels are 1..n (n the number of nodes of G); `K[c]` and `size[c]` are kept for every label.

```
queue := Shuffle(1..n);  inqueue[v] := true for all v
while queue is not empty:
    v := remove the first node of queue;  inqueue[v] := false
    A := P[v]
    scan v's neighbours u in increasing order, accumulating w(v, P[u] - v) for each label;
        the candidate labels are those met, in order of first meeting, A left out
    gA := g(v, A - v) = w(v, A - v) - gamma * k_v * (K[A] - k_v) / tw
    best := A;  bestgain := 0
    for each candidate C in order:
        delta := (w(v,C) - gamma * k_v * K[C] / tw) - gA
        if delta > bestgain + eps: best := C; bestgain := delta
    if size[A] > 1:                                  (the empty community)
        delta := 0 - gA
        if delta > bestgain + eps: best := the lowest label with size 0; bestgain := delta
    if best != A:
        move v to best (update K, size)
        for each neighbour u of v in increasing order:
            if P[u] != best and not inqueue[u]: append u to queue; inqueue[u] := true
return P
```

### RefinePartition(G, P)

```
R[v] := v for every v                                (every node alone)
for each community S of P, in order of its smallest member:
    members := the nodes of S in increasing order;  KS := sum of k_v over S
    for v in S:  wS[v] := w(v, S - v)
    well(v) := wS[v] - gamma * k_v * (KS - k_v) / tw >= -eps
    cand := the well(v) nodes of S, in increasing order;  Shuffle(cand)
    for refined communities r inside S keep K[r], size[r] and
        e[r] := w(r, S - r) (weight from r to the rest of S); initially K[v] = k_v,
        size[v] = 1, e[v] = wS[v]
    for v in cand, in shuffled order:
        if size[R[v]] > 1: skip v                    (only nodes still alone move)
        r0 := R[v]
        scan v's neighbours u in S in increasing order, accumulating w(v, r) for each
            refined label r = R[u]; the labels met, in order of first meeting, are
            the targets
        options := [(r0, 0)]                         (staying, delta 0)
        for each target r in order:
            if e[r] - gamma * K[r] * (KS - K[r]) / tw >= -eps:       (r well connected)
                delta := w(v,r) - gamma * k_v * K[r] / tw
                if delta >= -eps: append (r, delta) to options
        if options has one entry: continue           (no draw)
        dmax := the largest delta in options
        weight_j := exp((delta_j - dmax) / theta), theta = 0.01
        x := Random * (sum of weights)                (one draw)
        pick the first option whose running sum of weights exceeds x (the last if none)
        if the pick r != r0:
            e[r] := e[r] + wS[v] - 2 * w(v,r);  K[r] += k_v;  size[r] += 1;  size[r0] := 0
            R[v] := r
return R
```

theta (the randomness of the refinement) is fixed at 0.01, igraph's default; it is not an
option.

## Output

- The partition, renumbered 1..k by first appearance.
- Clusters; Modularity, Newman's Q at resolution 1 on the matrix every community routine
  reports on (symmetrized by maximum, diagonal ignored; `community_modularity()`), so that
  it compares with the other routines; Quality, modularity at the chosen resolution on `W`:
  `sum_c (W_c / tw - gamma * (K_c / tw)^2)`, with W_c the total inside c both directions;
  Iterations.
- The UCINET report prints the parameters, these statistics, and the partition; it saves the
  partition as a one-column dataset (default name `<input>-leid`).

## Floating point

Win32 Delphi evaluates double expressions in x87 extended precision, so its numbers can
differ from R's in the last bits. Every comparison carries `eps`, so the two agree unless two
options differ by about `eps`; the refinement's draw can differ only if `x` falls within
rounding of a boundary. A seed where R and UCINET disagree is worth a look, not a fix.

## Cross-check (23 Oct 2026)

`ucinet\Planning\tests\leiden\` (branch `leiden`): 107 CLI runs and 4 dialog runs (zachary,
campnet under all four symmetrizations, padgett with both relations, a valued network, a
150-node network, a network with negative and missing cells and an isolate; resolutions 0.5,
1, 1.5 and 2; seeds 1-10, -7 and 123456789) give exactly `xleiden()`'s partition every time,
and the dialog logs its statistics: 115 of 115 checks (`compare_leiden.out.txt`). Different
seeds do give different partitions there (three distinct ones on the 150-node network over
ten seeds), so the agreement is not an accident of every seed converging to one answer.

UCINET stores tie values in single precision. Integer weights are exact in both programs;
for fractional weights compare R on the values read back from the UCINET file, as
`compare_leiden.R` does, not on the original doubles.
