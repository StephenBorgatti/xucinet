# Differences from UCINET

Every place xucinet knowingly departs from UCINET, or matches something in
UCINET that is itself under review. SPEC D7 asks for this as a vignette; issue
#10 will build one, and it should render from this file rather than restate it.

Entries are added when a golden test forces the question, so the list is short
by construction: if a difference is not here, the goldens say the two agree.

---

## 1. `dichotomize()` and the diagonal

**Status:** resolved 7 September 2026. No longer a difference — UCINET changed.

UCINET's `dichot()` used to zero the diagonal as part of dichotomising. Through
Phase 0 we matched that for 1-mode data and refused it for 2-mode, where cell
(i, i) is row-node i tied to column-node i and zeroing it would have deleted 12
of davis's 89 attendances.

UCINET 6.849 no longer zeroes it, for either. Regenerating the density goldens
changed `g_baker_bin`, which UCINET writes from `dichot(baker_journals GT 0)`:
the twenty diagonal cells that used to come back 0 now come back 1, because
`baker_journals` counts each journal's citations to itself.

So the special case is gone from `dichotomize()` and the two programs agree.
The entry is kept rather than deleted because the old behaviour is still in
every UCINET before 6.849, and anyone comparing against an older run needs to
know why the diagonal moved.

---

## 2. Average degree on 2-mode data

**Status:** we report UCINET's figure plus two more. Third revision.

This one has now been three different numbers, which is worth recording as much
as the answer is.

Through Phase 0, UCINET's `density()` divided the tie total by the number of
**columns**: davis, 18 women by 14 events and 89 attendances, gave 89/14 =
6.357. We matched it, pinned it, and flagged it here as probably an oversight,
since for a 2-mode network neither margin is obviously "the" node set.

On 6 September 2026 we split it instead, reporting 89/18 and 89/14 as separate
lines. That lasted a day.

UCINET 6.849 now divides by the number of **nodes**, counting both modes:
89/32 = 2.781, in the CLI and in the menu report alike. That answers the
original objection properly — it uses both margins rather than choosing one —
and it is consistent with the 1-mode case, which was always ties/n.

xucinet reports UCINET's `Avg Degree` and adds `Avg Degree (rows)` and
`Avg Degree (cols)` beside it for 2-mode data only. The margins are kept because
"attendances per woman" and "attendances per event" are what a reader of a
2-mode table wants, and neither can be recovered from 89/32 without knowing both
margins. Square networks are unaffected: one line, ties/n, as before.

*Left open for Steve: whether the two margin lines earn their place now that
UCINET's own figure is defensible. Dropping them is a two-line change.*

## 3. Standard deviation: not a difference, but worth recording

UCINET reports the **population** standard deviation: `uestimator.calc` in
`ustats.pas` sets `variance := mcssq/n`, not `mcssq/(n-1)`. R's `sd()` divides
by n-1, so an R-native implementation is quietly wrong against UCINET.

We had this bug. UCINET's own Density report for campnet prints 0.381 where
`stats::sd()` gives 0.382. Fixed, and the difference is now pinned by a test, so
this is recorded as a trap rather than as a divergence.

---

## 4. A truncated DL file

**Status:** deliberate difference. We refuse; UCINET accepts.
**Checked:** 6 September 2026, at Steve's request.

`krebs.txt`, in UCINET's own `Datafiles`, declares `N=56, NM=5` — 280 rows of 56
values — and holds 278 full rows plus a partial row of 12: 15,580 values where
15,680 are needed. xucinet refuses it, naming both counts.

UCINET does not. `importfullmatrix` in `udlm.pas` runs

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
and the tail of the data comes back all-missing. The file has presumably been
imported that way before, and any analysis run on it was run on a partly-missing
matrix.

Refusing is the safer behaviour — a short matrix that looks complete is worse
than an error — so xucinet keeps it, and this entry records that the two
programs differ.

*UCINET catch-up: a bounds check in `importfullmatrix`, and a look at whatever
was computed from `krebs.txt`.*

---

## 5. Node tables always carry every column

**Status:** deliberate simplification.
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
shape, and unticking one box changes the columns underneath the user. Untick
raw totals and there is no graph centralization either, since
`runcentralization` is called only in that branch.

xucinet always emits all four, and always reports centralization where UCINET
has one. `normalize` selects which column is read as the primary value; it does
not change the shape of `$nodes`. The reason is that `$nodes` is a data frame
people index by name and bind into other frames, and a table whose columns
appear and disappear with an argument is a poor thing to compute on. The cost is
that a user who wants exactly UCINET's two-column output has a column to drop.

The headings themselves are UCINET's own, unchanged: `Degree`, `Outdeg`,
`Indeg`, and the same again under `store('n')` as `nDegree`, `nOutdeg`,
`nIndeg`.

*UCINET catch-up: none proposed. The checkboxes are long-standing and harmless
in a GUI; the difference is that our output is a data structure first.*
