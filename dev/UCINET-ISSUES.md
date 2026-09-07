# UCINET bugs and feature requests

Windows UCINET is the standard xucinet is measured against, so where the two
disagree, UCINET wins by default. That only works if the places UCINET is itself
wrong are written down instead of silently copied. This is that list.

Opened 7 September 2026 at Steve's suggestion. It is a working list for the
UCINET side, not a public document: it lives in `dev/` and is not shipped.

**How this differs from `inst/DIFFERENCES.md`.** The ledger records what xucinet
does and why, for users. This records what UCINET should do, for us. An item can
be in both — a deliberate difference here is usually a catch-up item there — but
most entries here never reach a user, because we match UCINET and say nothing.

Each entry says what was seen, where in the source, and what a fix would be.
Severity is a judgement, not a promise: **bug** means it produces a wrong or
misleading answer, **inconsistency** means two routes to the same measure
disagree, **request** means it works and could be better.

---

## 1. A truncated DL file imports silently, padded with missing values

**bug** — found 6 September 2026, `krebs.txt`

`importfullmatrix` in `udlm.pas` loops `for i := 1 to m.nr` / `for j := 1 to
m.nc` with no end-of-file guard, and no check that the file held as many values
as the header declared. `fread` in `UtFile.pas` swallows the IO error at end of
file and returns `bna`:

```pascal
{$i-} read(f,x); {$i+}
if ioresult = 0 then fread := x else fread := bna;
```

`krebs.txt`, which ships in UCINET's own `Datafiles`, declares `N=56, NM=5` —
15,680 values — and holds 15,580. It imports without complaint, and the tail of
the last matrix is all missing. Anything ever computed from that file was
computed on a partly-missing matrix.

**Fix:** count the values read and refuse, or at minimum warn, when the count
falls short. xucinet refuses it and names both counts; ledger entry 4.

---

## 2. 2-Mode Centrality reports eigenvector centrality as negative

**bug** — found 7 September 2026, `g9m_2mode_davis`

Every eigenvector value in both tables is negative, rows and columns alike:

```
     1    EVELYN  0.571  0.230  0.800  0.097 -0.335
     ...
     8        E8  0.778  0.290  0.846  0.244 -0.507
```

The sign of an eigenvector is arbitrary, but centrality is conventionally
reported with the principal eigenvector's sign flipped positive, and the
1-mode routines do that — `eigencent` on the same data returns positives. So
this is an inconsistency that reads as an error: a user comparing 1-mode and
2-mode output sees centrality "going the wrong way".

**Fix:** flip the sign when the majority of entries are negative, as the 1-mode
path already does.

---

## 3. `eigenvec()` ignores the output name it was assigned, for asymmetric input

**inconsistency** — found 7 September 2026, PART A of the centrality goldens

`g9_eigv_disc = eigenvec(g9_disc)` saved `G9_EIGV_DISC` and
`G9_EIGV_DISC-eig`, as asked. `g9_eigv_campnet = eigenvec(campnet)`, with an
asymmetric matrix, saved `CAMPNET-eval`, `CAMPNET-lvec`, `CAMPNET-rvec`,
`CAMPNET-lveci` and `CAMPNET-rveci` — names derived from the input, ignoring
the assignment entirely.

This matters for scripted work: a batch file cannot predict what it will get,
so a golden-fixture run silently produces files under names nothing is looking
for.

**Fix:** honour the assigned name in both branches, suffixing it for the extra
outputs (`<out>`, `<out>-eval`, `<out>-lvec`) as the symmetric branch already
does with `-eig`.

---

## 4. The CLI and the menu disagree about degree

**inconsistency** — found 7 September 2026

`degree(campnet)` from the command line returns three columns headed `Degree`,
`Outdegree`, `Indegree`, and its `norm` keyword *replaces* the values with means
rather than adding columns. **Network | Centrality | Degree** on the same data
returns four columns headed `Outdeg`, `Indeg`, `nOutdeg`, `nIndeg`, plus a graph
centralization matrix the CLI never produces.

Same measure, same data, different headings, different shape, different
contents. Both are defensible; having both is not.

**Fix:** one of them should call the other. The menu routine is the fuller one,
so the CLI function is the natural thing to reimplement in terms of it.

The same split exists for density: the CLI returns `Ties`, `Density`, `AvgDeg`,
while the menu returns `Density`, `No. of Ties`, `Std Dev`, `Avg Degree`. The
CLI has no standard deviation at all.

---

## 5. Graph centralization is not computed if raw totals are unticked

**request** — found 7 September 2026, `uc_DegreeCentrality.pas`

```pascal
if raw.Checked then begin store; runcentralization; end;
if normalized.checked then begin ... store('n'); end;
```

Centralization is computed inside the raw-totals branch. Untick *Output raw
totals* — a display preference — and the centralization matrix silently becomes
empty. Nothing in the dialog suggests the two are connected.

**Fix:** compute centralization unconditionally; it does not depend on which
columns are printed.

---

## 6. The header lines lose their closing parenthesis

**bug, cosmetic** — found 7 September 2026, every menu log

```
Input dataset:                          campnet (C:\...\inst\goldens\centrality\campnet
```

`putfn` opens a parenthesis for the full path and never closes it. Every report
UCINET writes has this, on every line that names a file.

**Fix:** one character in `tlogfile.putfn`.

---

## 7. The Valente-Forman option group offers one option

**request** — found 6 September 2026, `uc_ClosenessMeasures.dfm`

```
object ValenteMissing: TRadioGroup
  Caption = 'Handling undefined distances:'
  ItemIndex = 0
  Items.Strings = ('Set reverse distance to zero')
```

A radio group with a single item is a label wearing a control's clothes. Either
the other conventions should be offered, as they are for Freeman and reciprocal
distance, or this should be static text.

---

## 8. Node-level output is sorted by value

**request** — raised by Steve, 27 July 2026, and still open

UCINET sorts node-level tables by the measure. Steve's own view is that it
"probably confuses people", since the row order stops matching the dataset and
two measures on the same nodes come back in different orders.

**Fix:** print in storage order by default and make sorting an option. xucinet
already does this: `sort = NULL` is original order, `sort = "descending"` is
UCINET's view, and the descriptive statistics are computed before any sorting so
the choice cannot move a mean. SPEC decision 2 for chapter 9.

---

## Fixed since this list started

- **`dichot()` zeroed the diagonal.** Fixed in 6.849. It now keeps it, which is
  what we argued for: on 2-mode data zeroing the pseudo-diagonal deleted 12 of
  davis's 89 attendances. Ledger entry 1 is now "no longer a difference".
- **2-mode average degree divided by the column count.** Fixed in 6.849, which
  divides by the number of nodes across both modes: davis reports 89/32 = 2.781
  rather than 89/14 = 6.357. Ledger entry 2.
