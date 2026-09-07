# UCINET bugs and feature requests

Windows UCINET is the standard xucinet is measured against, so where the two
disagree, UCINET wins by default. That only works if the places UCINET is itself
wrong are written down instead of silently copied. This is that list.

Opened 7 September 2026 at Steve's suggestion. A working list for the UCINET
side, not a public document: it lives in `dev/` and is not shipped.

## The convention

Adopted 7 September 2026. It governs this file, `inst/DIFFERENCES.md`, the
golden fixtures and DESCRIPTION together, and none of the four makes sense
without the others.

**One reference version.** The package tracks a single UCINET build, declared in
DESCRIPTION as `Config/ucinet/reference` — currently **6.849**. Every family of
golden fixtures records the build that produced it in a `UCINET-VERSION` file
beside them, and `check_golden_version()` in `tests/testthat/helper-goldens.R`
fails the suite if a family and the declaration disagree. A fixture from another
build is not evidence about the build we claim to match.

*One departure from the letter of this, worth knowing:* the build number is
recorded per folder rather than inside each fixture, because UCINET's `##h`
header has no field for it — it records the file-format version (4010 … 6405)
and nothing about the program that wrote it, and it leaves the title of a result
dataset empty. Putting it in the header is request 9 below. `inst/goldens/ucinet`
is exempt outright: those are format inputs collected over many years, and being
older than the reference is the point of them.

**While a fix is pending.** xucinet implements the **correct** behaviour, not
UCINET's. The test that covers it is marked as expected to differ from UCINET
below the fixing version, and the matching entry in `inst/DIFFERENCES.md` says
*UCINET fix pending*. This inverts the usual "UCINET numbers win": a known bug is
not a number worth matching.

**When UCINET fixes it.** The entry here moves to **fixed in UCINET x.y** and
stays — entries are never deleted, because the old behaviour is still in every
earlier build and someone comparing against one needs to know. The affected
fixtures are regenerated from the fixing build, `Config/ucinet/reference` is
bumped, xucinet follows the fixed behaviour with **no compatibility option**,
and the corresponding ledger entry in `inst/DIFFERENCES.md` is **removed**, since
it is no longer a difference.

**How this differs from `inst/DIFFERENCES.md`.** The ledger records what xucinet
does and why, for users, and only while a difference exists. This file records
what UCINET should do, for us, permanently. Most entries here never reach a
user, because we match UCINET and say nothing.

## Status vocabulary

| status | meaning |
|---|---|
| **open — fix pending** | We implement the correct behaviour; a ledger entry says so; a test is marked as differing below the fixing version. |
| **open — no xucinet impact** | UI or workflow only. Nothing for us to implement. |
| **fixed in UCINET x.y** | We follow the fixed behaviour, fixtures regenerated from x.y, ledger entry removed. |

Severity is a judgement, not a promise: **bug** means a wrong or misleading
answer, **inconsistency** means two routes to the same measure disagree,
**request** means it works and could be better.

---

## 1. A truncated DL file imports silently, padded with missing values

**bug** · **open — fix pending** · found 6 September 2026, `krebs.txt`

xucinet already does the correct thing: it refuses the file and names both
counts. Ledger entry: *UCINET fix pending*.

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

**Confirmed independently, 7 September 2026.** Steve pointed at the same data as
an `.rda` in the `zalmquist/networkdata` package. It holds all five relations at
56 x 56 under the names BUSINESS_1, BUSINESS_2, ADVICE, TECHNICAL and CUSTOMER,
so the DL header's `N=56, NM=5` was right and the file, not the declaration, is
at fault.

Every one of the 15,580 values the file does contain agrees with the `.rda`
exactly, which also says our DL parser is reading it correctly. The file stops
at **row 55, column 13 of CUSTOMER** - 100 values short, the last row and a half
of the last matrix.

**Second fix, on the data rather than the code:** the copy in `Datafiles` can be
rewritten from the `.rda`, and should be, since it is the copy everyone gets.


---

## 2. 2-Mode Centrality reports eigenvector centrality as negative

**bug** · **open — fix pending** · found 7 September 2026, `g9m_2mode_davis`

Nothing to implement yet — 2-mode centrality is a Phase 1 routine. When it is
written it will flip the sign positive, and its test will be marked as
differing from UCINET below the fixing build.

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

**inconsistency** · **fixed in UCINET (build to be confirmed)** · found
7 September 2026, PART A of the centrality goldens

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

**Fixed.** Steve reports this is done in the current build.

*Fixtures to regenerate:* the two `eigenvec()` outputs, and the five stray files
the bug produced have to be deleted by hand because they are named after the
input and nothing will overwrite them.

| fixture | why |
|---|---|
| `G9_EIGV_CAMPNET` | never existed; the bug wrote `CAMPNET-eval`, `CAMPNET-lvec`, `CAMPNET-lveci`, `CAMPNET-rvec`, `CAMPNET-rveci` instead |
| `G9_EIGV_DISC`, `G9_EIGV_DISC-eig` | correct already, regenerated so the family comes from one build |
| `G9_EIGV_BAKER` | new — the other asymmetric input, valued, to check the fix holds there too |

The batch lines are in `inst/goldens/centrality/regen_eigenvec.txt`. Nothing
else in the centrality folder is affected: `eigencent()` honoured its assigned
name throughout, so every `G9_EIGC_*` fixture stands.

*Still needed before the reference can be bumped:* the build number that
contains the fix. `Config/ucinet/reference` and
`inst/goldens/centrality/UCINET-VERSION` both say 6.849 today, and the test
suite fails the moment they disagree with each other. If the fixing build is
newer than 6.849, the density fixtures need regenerating too, since the package
tracks one build.

---

## 4. The CLI and the menu disagree about degree

**inconsistency** · **open — fix pending** · found 7 September 2026

xucinet follows the menu, which is the fuller of the two, and says so in the
chapter 9 addendum. No ledger entry: we match one of UCINET's two answers
exactly, so there is no difference to declare to a user.

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

**request** · **open — fix pending** · found 7 September 2026,
`uc_DegreeCentrality.pas`

xucinet computes centralization whenever UCINET has one for the measure,
independently of which columns are printed — the correct behaviour. Covered by
ledger entry on always-present columns, which says *UCINET fix pending*.

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

**bug, cosmetic** · **open — no xucinet impact** · found 7 September 2026

Our reports name the dataset without its path, so there is no parenthesis to
balance. If we ever print the path we will close it.

```
Input dataset:                          campnet (C:\...\inst\goldens\centrality\campnet
```

`putfn` opens a parenthesis for the full path and never closes it. Every report
UCINET writes has this, on every line that names a file.

**Fix:** one character in `tlogfile.putfn`.

---

## 7. The Valente-Forman option group offers one option

**request** · **open — no xucinet impact** · found 6 September 2026,
`uc_ClosenessMeasures.dfm`

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

**request** · **open — fix pending** · raised by Steve, 27 July 2026

UCINET sorts node-level tables by the measure. Steve's own view is that it
"probably confuses people", since the row order stops matching the dataset and
two measures on the same nodes come back in different orders.

**Fix:** print in storage order by default and make sorting an option. xucinet
already does this: `sort = NULL` is original order, `sort = "descending"` is
UCINET's view, and the descriptive statistics are computed before any sorting so
the choice cannot move a mean. SPEC decision 2 for chapter 9.

---

## 9. The header records no UCINET build number

**request** · **open — no xucinet impact** · raised 7 September 2026

A `##h` header records the file-format version — 4010 through 6405 — and nothing
about the program that wrote the file. UCINET also leaves the title empty on the
result datasets its routines save. So a fixture cannot say which build produced
it, and a golden-fixture suite has to record that out of band, in a file beside
the fixtures that nothing enforces except our own test.

**Fix:** write the build into the header, or failing that into the dataset title
of anything a routine saves. Either would let a reader check provenance from the
file itself.

---

## Fixed since this list started

- **`dichot()` zeroed the diagonal** — **fixed in UCINET 6.849**. It now keeps
  it, which is what we argued for: on 2-mode data zeroing the pseudo-diagonal
  deleted 12 of davis's 89 attendances. The special case is gone from
  `dichotomize()`, the density fixtures were regenerated on 6.849, and the
  ledger entry has been removed.
- **2-mode average degree divided by the column count** — **fixed in UCINET
  6.849**, which divides by the number of nodes across both modes: davis reports
  89/32 = 2.781 rather than 89/14 = 6.357. xucinet follows it. The ledger entry
  about the denominator has been removed; what remains in the ledger is only
  that we print two extra per-margin lines beside UCINET's figure, which is an
  addition of ours and not a UCINET defect.
