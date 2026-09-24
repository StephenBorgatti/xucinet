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

**Scheduled for UCINET 6.850 (Steve, 24 September 2026): every open entry**, including the
cosmetic ones and those with no xucinet impact, and any entry opened before 6.850 is built.
One version bump for the batch. Claude Code does the work in `C:\Dev\ucinet` and
`C:\Dev\tools` on branch `v6850`; the plan and Steve's decisions are in
`C:\Dev\ucinet\Planning\6.850-plan.md`. The per-entry "scheduled for 6.850" notes below
predate this and are kept.

---

## 1. A truncated DL file imports silently, padded with missing values

**bug** · **open — fix pending** · found 6 September 2026, `krebs.txt` · **scheduled for UCINET 6.850** (Steve, 23 September 2026)

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

**inconsistency** · **fixed in UCINET 6.849** · found 7 September 2026, PART A
of the centrality goldens; fixed and verified the same day

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

**Fixed and verified**, 7 September 2026. `regen_eigenvec.txt` was run and the
fixtures are in the repository.

The fix also tidied the output rather than merely renaming it. Where the bug
wrote five separate files named after the input, the assigned dataset now holds
the vectors as levels of one stack, and the eigenvalues go beside it under the
same `-eig` suffix the symmetric branch always used:

| input | output | shape |
|---|---|---|
| campnet (asymmetric) | `G9_EIGV_CAMPNET` | 18 x 18, four levels: `Right`, `Left`, `RightIm`, `LeftIm` |
| | `G9_EIGV_CAMPNET-eig` | 18 x 3 |
| g9_disc (symmetric) | `G9_EIGV_DISC` | 12 x 12, one level |
| | `G9_EIGV_DISC-eig` | 12 x 1 |
| baker_journals (asymmetric, valued) | `G9_EIGV_BAKER` | 20 x 20, four levels |
| | `G9_EIGV_BAKER-eig` | 20 x 3 |

So the naming rule is now `<out>` and `<out>-eig` in both branches, and the
harness can find them by the name the batch asked for. The five `CAMPNET-*`
strays have been deleted. Nothing else in the centrality folder was affected:
`eigencent()` honoured its assigned name throughout, so every `G9_EIGC_*`
fixture stands, and the reference build is unchanged at 6.849, so no other
family needed regenerating.

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

## 10. The build number does not change when behaviour does

**request** · **open — fix pending** · raised 7 September 2026

Issue 3 was found and fixed on the same day, and both the buggy binary and the
fixed one report **6.849** from Help | About. Two builds that produce different
output share a version string.

That is a problem for us specifically, because of the convention this file
opens with. `Config/ucinet/reference` and the `UCINET-VERSION` manifests exist
to make "which UCINET produced this fixture" answerable, and the whole scheme
rests on the build number changing when the behaviour does. Here it did not, so
the centrality fixtures went from wrong to right while every recorded version
string stayed the same. Nothing in the test suite could have caught it; only the
file names changing gave it away.

**Fix:** bump the build number on any change that alters output, even a small
one. Concretely, in `Source/Uci.dproj`, three places that have to move together:

```xml
<VerInfo_MinorVer>849</VerInfo_MinorVer>
<VerInfo_Build>849</VerInfo_Build>
<VerInfo_Keys>...FileVersion=6.849.0.849;...</VerInfo_Keys>
```

*Not* a fourth component, which was my first suggestion and is wrong. The
displayed version is major-dot-**build**, not major-dot-minor:

```pascal
function majorbuild(fn:string): string;
begin
  s:= getversionstring(fn);
  decodeversionstring(s,major,minor,release,build);
  result:= major + '.' + build;
end;
```

`VerInfo_Release` is 0 and unused, so a 6.849.1 would not appear in the About
box or in the footer of any output log — the two places we actually read the
version from. `VerInfo_Build` is the number that shows, so `VerInfo_Build` is
the number to bump. `VerInfo_MinorVer` is kept equal to it by convention and
should move with it.

Until then, the manifests are honest about the build but not sufficient to
identify it, and `Notes:` in each one carries the date and script as a partial
substitute. This is also the strongest argument for request 9: a build stamp
written into the file at least records *something* the fixture cannot lose.

---

## 11. mcent's "Closeness" column holds farness

**bug** · **open — fix pending** · found 7 September 2026, `G9_MC_ISO`

`mcent()` labels a column **Closeness** and fills it with the total geodesic
distance from each node, unreachable pairs counted as `n`. Bigger means further
away, so the column runs in the opposite direction to its own name — and in the
opposite direction to the Closeness routine one menu item above it, which for
`g9_iso` reports 0.191, 0.214, 0.209 where the suite reports 47, 42, 43.

Anyone reading the suite's table as centrality reads it backwards, and anyone
comparing the suite against Closeness finds them disagreeing about the same
nodes on the same data.

**Fix:** rename the column Farness, or divide into it. Either resolves it; at
present the heading and the number say opposite things.

xucinet puts `xcloseness()`'s Freeman score in that column. Ledger entry 5.

---

## 12. mcent and the Beta Centrality dialog normalize differently

**inconsistency** · **open — fix pending** · found 7 September 2026

`mcent()`'s `BetaCent` column and the Beta Centrality dialog give different
numbers for the same measure on the same data at the same beta. For `g9_iso`
the ratio is a constant 546.5, so the scores agree in shape and differ only in
scaling — the dialog normalizes to *ssq = n*, the suite to something else.

This is the same shape of problem as issue 4, where the CLI and the menu
disagree about degree: two routes to one measure, two answers.

**Fix:** have the suite call the same normalization the dialog does.

xucinet follows the dialog, which is the documented measure, so its suite
disagrees with `mcent()` here too. Ledger entry 5.

---

## 13. The Induced Centrality footnote list has ten entries for nine columns

**bug, cosmetic** · **open — no xucinet impact** · found 7 September 2026

`uc_ContributionCentrality.pas` writes nine columns and then ten footnotes:

```pascal
log.writeln(' 5. No. of transitive triples');
...
log.writeln(' 9. No. of transitive triples');
```

Item 9 repeats item 5 word for word, and there is no ninth column for it to
describe, so from item 9 on the numbering no longer lines up with the table.
The `cycles` field is computed in `calcmatrixmeasures` but never written to the
output, which is probably where the stray line came from.

**Fix:** delete the duplicate, or add the cycles column the footnote implies.

---

## 14. The Induced Centrality reversal note is missing its minus sign

**bug, cosmetic** · **open — no xucinet impact** · found 7 September 2026

```pascal
log.writeln('Measures 2 and 6 are calculated in reverse: X(G-k) = X(G)');
```

It prints `X(G-k) = X(G)`, which says the two are equal. The code does
`v1.sumdist - v.sumdist`, so it should read `X(G-k) - X(G)`.

The sentence is doing real work -- SumDist and Fragmentation genuinely run the
opposite way from the other seven columns, because for those two an increase is
the damage -- so a reader who takes it literally gets the sign wrong.

**Fix:** one character.

---

## 15. RAND imputation overwrites observed ties, and can impute a missing value

**Status:** reported here, not yet reported to Steve. xucinet implements the
correct behaviour; the differences ledger says so.

`timputation.runrandom` in `G2Tools\uimputemissing.pas` has two defects, one
in each branch.

The binary branch rewrites the whole matrix:

```pascal
procedure runbin;
begin
  den:= d.getaverage(false);
  for i:= 1 to d.n do
    for j:= 1 to d.n do if i <> j then
      if random < den
        then y.cell[i,j]:= 1
        else y.cell[i,j]:= 0;
end;
```

There is no `if d.isna(i,j)` test, so every observed tie is thrown away and
replaced by a coin flip. The other eight methods all test it. An imputation
routine that discards the data it was given cannot be what was meant.

The valued branch builds its pool without checking validity:

```pascal
for i:= 1 to d.n do
  for j:= 1 to d.n do if i <> j then
    list.Add(d.cell[i,j]);
```

Missing cells go into the list, so a cell drawn at random may itself be
missing and the "imputed" matrix still has holes in it.

**What xucinet does:** `ximpute(method = "random")` fills only the missing
cells, and draws from the observed ties. Ledger entry 15.

**Fix:** a validity test in each branch.

---

## 16. The node-level clustering coefficient should be withdrawn

**Status:** Steve's decision, 22 September 2026 (design question 10.2), recorded
here so the UCINET side follows. Not a defect in the arithmetic.

UCINET's Clustering Coefficient routine reports an overall coefficient, a
weighted overall coefficient, and a coefficient per node. Steve's instruction
for chapter 10 was to keep the overall figure, fold it into the transitivity
report, and **not** compute the node-level one; and to note here that it should
come out of UCINET too.

The reason is that the per-node coefficient invites a reading it does not
support. It is the density of ego's neighbourhood, so it falls as degree rises
almost mechanically, and a node with fewer than two neighbours has none at all.
Ranking nodes by it, which is what a per-node column invites, mostly ranks them
by inverse degree.

**What xucinet does:** `xtransitivity()` carries `Clustering Coefficient` in its
`$summary`, and there is no node-level column and no `xclustering()` export.

**Fix in UCINET:** drop the per-node column from the Clustering Coefficient
routine's output, or move it behind an option that is off by default.

**Decided, 24 September 2026 (Steve):** drop the per-node column from the whole-network
routine, and add a node-level routine, Network | Ego networks | Clustering Coefficient.
Steve's reason for offering both: users do not realize that the weighted overall
coefficient equals transitivity, or that the node-level coefficient is the density of
ego's network. For 6.850 only, the whole-network routine's log says where the node-level
coefficient went. The same rule applies to Reciprocity's node table and the E-I Index's
node scores (plan, decisions 5-8).

---

## 17. Egonet Basic Measures reports zeros for an ego with no alters

**Status:** reported here 23 September 2026 (chapter 8, issue #14). **Scheduled for
UCINET 6.850** (Steve, 23 September 2026). xucinet implements the correct behaviour;
ledger entry 18.

`densitydsl` in `Xegonet.pas` handles the empty ego network like this:

```pascal
if m.rdsl.n = 0 then begin
  npairs:= bna; avgdist:= bna; avgrdist:= bna; diam:= bna;
  numweak:= bna; pweak:= bna; efficiency:= bna; cratio:= bna;
  goto cleanup;
  end;
```

and the sixteen `x.cell^[ego]^[k] := ...` assignments come after the label it
jumps past. So the missing values are set and never stored; the output row
stays as `allocsize` left it, all zeros. An isolate gets Density 0, Diameter 0,
nBroker 0 and so on, which read as measured values rather than undefined ones.

A smaller case of the same thing: with one alter there are no pairs, and
`avgrdist` is set to 0 before the loop and never divided, so AvgRecipDist is 0
where it is undefined.

**What xucinet does:** counts (Size, Ties, Pairs, nWeakComp, 2StepReach,
2StepPct, Broker, nClosed, EgoBetween) are 0 for an isolate; the ratios
(Density, AvgRecipDist, Diameter, CompRatio, ReachEffic, nBroker, nEgoBetween)
are missing. AvgRecipDist is missing with one alter.

**Fix:** store the row before `cleanup`, or fill it with the missing values in
the early exit.

A related wording point, not a bug in the numbers: column 14, nClosed, is
documented in the log as "the number of closed triads ego is involved in" but
holds `nties`, the directed tie count among alters, which on symmetric data is
twice the number of closed triads. xucinet reproduces the number; either the
footnote or the value should change.

---

## 18. Egonet Tie Composition ignores "Include ties to self"

**Status:** reported here 23 September 2026. **Scheduled for UCINET 6.850** (Steve,
23 September 2026). xucinet implements the correct behaviour; ledger entry 19.

`TEgonetTieComposition.run` declares `diagok` and never reads the
`DiagonalOk` checkbox into it, and calls
`etc.addmat(net, whichties.ItemIndex, op, cut)` without the fifth argument, so
`addmat`'s `diagok` is always its default, `false`. The checkbox does nothing.
The valued-tie form next to it does read its own checkbox.

**What xucinet does:** `xtiecomposition(diagonal = TRUE)` counts ties to self.

**Fix:** `etc.addmat(net, whichties.ItemIndex, op, cut, diagonalok.Checked)`.

---

## 19. Egonet Valued Tie Composition, "Both in and out", uses the wrong cell

**Status:** reported here 23 September 2026. **Scheduled for UCINET 6.850** (Steve,
23 September 2026). xucinet implements the correct behaviour; ledger entry 19.

In `analyzer` in `uc_egonetvaluedtiecomposition.pas`, case 0:

```pascal
if net.istie(i,m,op,cut) then uni.addcase(net.cell[i,m]);
if net.istie(m,i,op,cut) then uni.addcase(net.cell[i,m]);
```

The second line tests the incoming tie `x(m,i)` and then adds the outgoing
value `x(i,m)`, which is usually zero or missing when the tie is one-way. Case
2 (incoming only) correctly adds `net.cell[m,i]`.

**What xucinet does:** `xvaluedtiecomposition(direction = "both")` adds the
incoming tie's own value.

**Fix:** `uni.addcase(net.cell[m,i])` on the second line.

---

## 20. Egonet Alter Composition | Continuous: the SD filters never filter

**Status:** reported here 23 September 2026. **Scheduled for UCINET 6.850** (Steve,
23 September 2026). The filters are left out of `xaltercomposition()`; ledger entry 20.

Three defects in `uc_EgoNetStrength.pas`, all in code the default settings do
not reach:

1. `runfilteredstats` contains a local `qualifies` function and never calls
   it; its body is a copy of `runstats`. Ticking either filter changes nothing.
2. Both edit boxes are parsed into the same variable:
   `trystrtofloat(sdabove.Text, highsd)` and then
   `trystrtofloat(sdbelow.Text, highsd)`, so `lowsd` is never set.
3. With *Ignore tie strengths*, `meas.setdim(meas.nr, nvar-1, ...)` keeps
   seven of the nine columns, dropping `Num` and `WtdNum`. `nvar` is 8, a
   leftover from before `CV` was added; the intent was evidently to drop
   `WtdNum` alone.

**What xucinet does:** no filter arguments, since there is no behaviour to
reproduce; all nine columns always.

**Fix:** call `qualifies` in `runfilteredstats`, parse the second box into
`lowsd`, and use `setdim(meas.nr, meas.nc - 1, ...)`.

---

## 21. Whole-Network Homophily: "Treat data as" changes only the mixing matrix

**bug** · **open — fix pending** (Steve, 23 September 2026: add to the bug list)

`calcwhomophily` takes the raw cell value for the internal and external totals
whatever the *Treat data as* radio group says, and branches on it only when
filling the mixing matrix `mrs`. So `H`, `h-star`, `Corr`, `Yules Q` and the
`E-I Index` are identical for binary and valued treatment; only the mixing
matrix changes. The dialog reads as though the choice applies to everything.

**What xucinet does:** since 23 September 2026 (issue #16), `xhomophily(weighted
= FALSE)` dichotomizes before every measure. Ledger entry 24.

**Fix:** use the dichotomized value in the internal and external totals when
the data are treated as binary.

---

## 22. Mixing Tables: an attribute taken from a row of the attribute file is not read

**bug** · **open — no xucinet impact** · found 23 September 2026 (Cowork)

In `TMixingTables.getattr` (`uc_MixingTables.pas`), the branch for
`dimension.itemindex = 1` loops over `j` but assigns `attr.cell[i]`:

```pascal
1: begin
     if not attr.allocsize(m.nc) then goto cleanup;
     for j:= 1 to m.nc do
       attr.cell[i]:= round(m.cell[k,j]);
     end;
```

`i` is not set in that branch, so the partition vector is not filled. Choosing
a column of the attribute file (the default) is unaffected.

**What xucinet does:** `xmixing()` takes the attribute as a vector or a named
column, so it has no row/column choice to get wrong.

**Fix:** `attr.cell[j]:= round(m.cell[k,j]);`

---

## 23. Normalize: Correspondence with Dimension = Matrix does nothing

**bug** · **open — fix pending** · found 23 September 2026 (Cowork)

In `Xstdize.pas`, method 8 (Correspondence) is handled in `runrowcols`, which
computes x(i,j)/sqrt(R_i·C_j) from the row and column totals whatever the
dimension (Rows, Columns or Both give the same result). `runmatrix`, which
handles Dimension = Matrix, has no branch for method 8, so every cell passes
through unchanged and the output equals the input without a warning.

**What xucinet does:** `xnormalize(method = "correspondence")` gives the same
result for every `by`. Ledger entry 23.

**The same gap for SQRT-Marginal** (method 7), found 23 September 2026 by
Claude Code porting the fix: `runmatrix` has branches for methods 1 to 6 only,
so SQRT-Marginal under Dimension = Matrix also returns the input unchanged.
`xnormalize(by = "matrix", method = "sqrtsum")` divides by the square root of
the matrix total, as the Rows and Columns dimensions do for their margins.

**Fix:** route method 8 to `runrowcols` for every dimension, or refuse
Dimension = Matrix for it; add a method 7 branch to `runmatrix`.

---

## 24. A headless batch driver for menu routines

**request** · **open — no xucinet impact** · **scheduled for UCINET 6.850**
(Steve, 23 September 2026)

Menu routines (the `uc_*.pas` forms) can only be run through their dialogs, so
golden fixtures for them are made by hand. SPEC section 5, item 0 describes the
console target (`ucinetcl`) that would run them from a script. Until it exists,
each goldens batch is a manual Windows session.

---

## 25. Mixing Tables sums missing cells as 1e38

**bug** · **open — fix pending** · found 23 September 2026 (Claude Code, issue #16)

Every loop in `G2Tools/unetmixingmodels.pas` guards a cell with

```pascal
val := AdjMatrix.cell[i,j];
if val <> ucommon.na then ...
```

but a missing cell is stored as `bna = 1e38`, and `na = 1e37` is the threshold
(`tsmat.isna` is `cell >= na`). The test is never false for a missing cell, so
each one is added into the observed table and the expected-value totals as
1e38. A network with a single missing cell gives a Mixing Tables report of
astronomically large numbers.

**What xucinet does:** `xmixing()` skips missing cells. Ledger entry 25.

**Fix:** `if val < ucommon.na`, or `if not AdjMatrix.isna(i,j)`.

---

## 26. Louvain: moves are tested against the Q from before the pass, and the reported Q can be wrong

**bug** · **open — fix pending** · found 23 September 2026 (Claude Code, reported by
Cowork after reading the unit)

`G2Tools/utlouvain.pas`, class `tlouvain`, used by Network | Subgroups | Louvain
(`uc_Louvain.pas`) and the CLI `louvain` command.

1. *The move test.* `getbestmove` starts from `result.deltaq := currentq` and moves the
   node to a neighbouring cluster whenever the full Q with the node there (`getdeltaq`,
   which calls `getq` on the current partition) exceeds that value. `currentq` is set
   once, before `movenodes`, and is not updated as nodes move during the pass or between
   sweeps of the `while anymoved` loop. So each node is compared with the Q from before the
   pass, not with the Q of leaving it where it is. The two differ whenever the node's own
   cluster is not among its neighbours' clusters, which is every node on the first pass,
   since the default start is the identity partition. Once earlier moves have raised Q, a
   node can be moved to a cluster that lowers Q, provided the result still beats the
   pre-pass value. Standard Louvain compares against staying put.
2. *The reported Q.* At the end of `movenodes`, `currentq := best.deltaq`, the value from
   the evaluation of the last node visited. If that node did not move, it is the stale
   pre-pass Q; if it moved, it is the Q after its move, which is the final Q only if no
   later sweep changed anything. The Q written into each level's label by `storepart`
   (`nclus|Q`) is therefore not reliably the modularity of that level's partition. The
   comment above the assignment says "calculating full q, not deltaq".
3. Because the acceptance threshold does not rise during a pass, it is not clear that the
   `while anymoved` loop always terminates; not observed, not tested.

**What xucinet does:** `xlouvain()` is a native, deterministic port (nodes visited in
order, as UCINET does, which igraph cannot reproduce), with the move tested against the
current Q (a move is made only if it raises Q) and Q recomputed from each level's final
partition. Ledger entry 27, "UCINET fix pending" (written 23 Sep, issue #17). The golden
fixtures for Louvain should come from a fixed build; until then the golden test is marked
as expected to differ.

**Fix:** in `getbestmove`, initialise `result.deltaq := getq` (the Q of the current
partition, or equivalently the Q with the node in its own cluster); after the loop in
`movenodes`, `currentq := getq`.

---

## 27. Factions and Louvain read a missing cell as a tie of 1e38

**bug** · **open — fix pending** · found 23 September 2026 (Claude Code, issue #17)

A missing cell is stored as `bna = 1e38`. Two chapter 11 routines do not test for it:

- `uc_factions.pas`, `dichotomize`: `if rowp[j] > 1 then rowp[j] := 1`, so a missing cell
  becomes a tie, and `buildedgelist` then counts it.
- `utlouvain.pas`: `resetneighbors` takes `net.cell[i,j] > 0` as a neighbour, and `getq`
  adds `net.cell[ii,jj]` unguarded, so a missing cell enters modularity as a tie of
  weight 1e38. (`getrowsum` does skip it, so the degrees and the total do not match the
  cells.)

**What xucinet does:** `xfactions()` and `xlouvain()` treat a missing cell as no tie.
Ledger entry 29.

**Fix:** test `isna` (or `< na`) before using a cell, as `getrowsum` already does.

---

## 28. Inverse-Weighted Degree: an unset diagonal flag, totals carried across relations, and a doubtful normalization

**bug** · **open — fix pending** · found 23 September 2026 (Cowork, reading the unit)

`uc_iwdcentrality.pas`, `Tiwdcentrality.run` (Network | Centrality | Inverse-Weighted
Degree).

1. `diagok` is a local boolean that is never assigned, and both loops test
   `(i<>j) or diagok`. Delphi does not initialize local variables, so whether the diagonal
   counts is undefined. The dialog has no diagonal option.
2. The row and column totals `r` and `c` are allocated once, before the loop over
   relations, and never reset inside it. For a multi-relation dataset every relation after
   the first is weighted by totals accumulated over all earlier relations. `maxval` is reset
   per relation; the totals are not.
3. The normalized scores are `maxval * raw / (n-1)`. Each term `x(i,j)/c(j)` or
   `x(i,j)/r(i)` is at most 1 whatever the scale of the data, so the maximum possible
   raw score is n-1 and `raw/(n-1)` would normalize it. Multiplying by `maxval` leaves
   binary data unchanged but scales valued data up by its largest value. Steve,
   23 September 2026: the normalized score is `raw/(n-1)` for binary and valued data
   alike; the `maxval` factor is a bug.

What the routine computes, for the record: column 1 (`OutIWD`) is
sum over j of x(i,j)/c(j), i's ties weighted by the inverse of each alter's indegree;
column 2 (`InIWD`) is sum over i of x(i,j)/r(i), the column sums of the row-stochastic
matrix. For symmetric data only the first is reported, as `IWD`. Missing cells are recoded
(`recodena`) before summing. The default output is normalized.

**What xucinet does:** `xinverseweighteddegree()` excludes the diagonal, computes the totals
per relation, and normalizes as `raw/(n-1)`. Ledger entry with the code.

**Fix:** `diagok := false` (or a dialog option); zero `r` and `c` at the top of the loop
over relations; drop `maxval*` from the normalization.

---

## 29. Categorical core/periphery: off-diagonal blocks lose cells when their density is set

**bug** · **open — fix pending** · found 23 September 2026 (chapter 12, issue #23)

`G2Tools/utcpcat.pas`, `tcatcp.evaluate`, local procedure `addcases`
(Network | Core/Periphery | Categorical | Borgatti & Everett).

```pascal
for i:= 0 to list1.count-1 do
  for j:= 0 to list2.count-1 do if (i <> j) or diagok
    then corr.addcase(x,mat.cell[list1[i],list2[j]]);
```

`i` and `j` are positions in the core and periphery lists, not node numbers.
For the core-core and periphery-periphery blocks that is harmless (the same
list, so equal positions are the same node). For the off-diagonal blocks,
used only when *Desired density for core to periphery ties* or *periphery to
core* is set, it drops the cell pairing the k-th core node with the k-th
peripheral node, for every k, although those are different nodes. The fit is
then computed on an arbitrary subset of each off-diagonal block. With the
default (both densities NA) the code is not reached.

Also: the local `diag` is computed and never used; the test reads `diagok`
directly, so with the diagonal allowed the off-diagonal blocks are whole.

**What xucinet does:** `xcoreperiphery()` counts the off-diagonal blocks whole
and says so in its notes when `c2p` or `p2c` is given. Ledger entry 35.

**Fix:** test `(list1[i] <> list2[j]) or diagok`, or skip the test when
`list1 <> list2`.

---

## 30. Affiliations: "Covariance" is the sum of cross-products of deviations

**bug** · **open — fix pending** · found 24 September 2026 (chapter 13, issue #26)

`G2Tools/ug2simdis.pas`, procedure `Covariance` (used by Data | Affiliations,
Method "Covariance"):

```pascal
if nxy < 1 then z:= bna else z:= sxy;
```

`sxy` is the running sum of `(x - mean x)(y - mean y)`; it is never divided by
`nxy`. So the value reported as a covariance is `n` times the covariance (the
population form), and a projection by covariance scales with the number of
events. `utsimilarity.pas`, which Tools | Similarities uses, divides by n.

**What xucinet does:** `xaffiliations(method = "covariance")` divides by the
number of cells both vectors have. Ledger entry 38.

**Fix:** `z:= sxy/nxy`.

---

## 31. Double Dekker MRQAP: the fast path permutes b / SE² rather than t

**bug** · **open — fix pending** · found 24 September 2026 (chapter 14, issue #27)

`G1Tools/umrqapdekker.pas`, `tmrqapdekker.regressresidual`. With no missing
data (the optimized path) the observed and permuted statistics are

```pascal
se_sq := mse_val * inv_kk;          // the variance of b[k]
ot := ob.cell[k] / se_sq;           // and likewise ts := bk / se_sq
```

that is b divided by its variance, not by its standard error. Since the
variance changes from one permutation to the next, b / SE² does not rank the
permutations as t does, and the p-values differ from those the same data give
on the fallback path (any missing cell), which divides by `se_fb`, the
standard error. The dialog's "Statistics to track: T-Statistics" is therefore
not what the fast path tracks.

Also on the fallback path: the design matrix is built over the cells that are
not missing, but the permuted column is written with its own counter, skipping
cells whose *permuted* source is missing, so the column's rows fall out of
step with the other columns whenever a missing cell is permuted into place.

**What xucinet does:** `xmrqap()` uses t = b / SE on every path, and each
permutation keeps the cells present in Y, the other X's and the permuted
residual. Ledger entry 41.

**Fix:** `ts := bk / sqrt(se_sq)` and `ot := ob.cell[k] / sqrt(se_sq)`; in the
fallback path, rebuild the design matrix per permutation over the cells valid
after permuting.

---

## 32. MRQAP (Y permutation): symmetry is decided without looking at Y

**bug** · **open — fix pending** · found 24 September 2026 (chapter 14, issue #27)

`xmrqapna.pas`, `readdata`: `tmp.checksymmetry(temp); symmetric:= temp;` runs
on `tmp` before anything has been loaded into it, and Y itself is never
checked; `symmetric` then depends on the X matrices only. With symmetric X's
and an asymmetric Y, only the lower triangle is used and half of the dyads are
dropped.

**What xucinet does:** one triangle only when Y and every X are symmetric.
Ledger entry 41.

**Fix:** `ymat.checksymmetry(temp)` in place of `tmp.checksymmetry(temp)`.

---

## 33. ANOVA density models: adjusted R-square off by one, seed ignored, missing cells read as values

**bug** · **open — fix pending** · found 24 September 2026 (chapter 14, issue #27)

`XCatC2.pas`, `autocorranova`:

1. `adjrsqr:= rsqr - (1.0-rsqr)*(nx-1.0)/(nobs-nx)`, with `nx` the number of
   predictors, is R² − (1 − R²)(k − 1)/(n − k); the adjusted R-square is
   R² − (1 − R²)k/(n − k − 1).
2. `randseed:= seed` reads a unit-level `seed`, not `seedvalue`, the number
   the dialog shows and the user can type, so the seed box has no effect.
3. The matrix is used as loaded: a missing cell enters the regression as the
   missing-value code (1E37).

(Node-level regression has the same seed problem: `getypermsig` is passed
Delphi's global `randseed`, and the dialog's seed box is never read.)

**What xucinet does:** the standard adjusted R-square, R's generator under
`seed`, missing cells dropped. Ledger entry 42.

**Fix:** the standard formula; `randseed:= seedvalue`; skip cells `>= na`.

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
- **`eigenvec()` ignored its assigned output name for asymmetric input** —
  **fixed in UCINET 6.849**, same day it was reported. Issue 3 above has the
  detail; the fixtures were regenerated and the strays deleted.
