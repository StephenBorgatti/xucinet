# Differences from UCINET

Every place xucinet knowingly departs from UCINET, or matches something in
UCINET that is itself under review. SPEC D7 asks for this as a vignette; issue
#10 will build one, and it should render from this file rather than restate it.

Entries are added when a golden test forces the question, so the list is short
by construction: if a difference is not here, the goldens say the two agree.

---

## 1. `dichotomize()` and the diagonal

**Status:** matched for 1-mode, deliberately not for 2-mode.
**Decided:** Steve, 5 September 2026.

UCINET's `dichot()` zeroes the diagonal as part of dichotomising. Comparing our
result against `g_baker_bin`, which UCINET wrote from
`dichot(baker_journals GT 0)`, the only cells that differed were the twenty on
the diagonal: UCINET 0, ours 1, because `baker_journals` records each journal's
citations to itself.

xucinet now zeroes the diagonal too, but **only for 1-mode data**. A 2-mode
matrix has no diagonal in any meaningful sense: cell (i, i) is row-node i tied
to column-node i, two unrelated things, and zeroing it would silently delete
real ties. For davis that would drop 12 of the 89 attendances.

No density changes either way for 1-mode, because density excludes the diagonal
regardless. The difference is in the transform, and would show up the moment
`xdichotomize()` is exported in Phase 1.

*UCINET catch-up: none needed for 1-mode. Worth checking what UCINET's `dichot()`
does to a 2-mode matrix, which we have not tested.*

---

## 2. Average degree on 2-mode data

**Status:** matched, but the UCINET side is under review.
**Raised:** Steve, 5 September 2026.

UCINET's `density()` divides the tie total by the number of **columns**. For
davis, 18 women by 14 events and 89 attendances, it reports 89/14 = 6.357, not
89/18 = 4.944.

Every square network agrees either way, so only 2-mode data tells the
denominators apart; this went unnoticed until davis entered the golden battery.

xucinet matches UCINET, and `test-goldens.R` is pinned to UCINET's value. But
ties/ncols looks more like an oversight than a definition — for a 2-mode network
neither margin is obviously "the" node set, and the row mode has at least as
good a claim. If UCINET changes, this entry and the pinned test change with it.

*UCINET catch-up: under review.*

---

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
