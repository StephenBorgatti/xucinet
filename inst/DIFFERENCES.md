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

**Status:** deliberate difference — **UCINET fix pending**. We refuse; UCINET
accepts.
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
