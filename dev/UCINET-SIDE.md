# For the UCINET development machine

A page to point Claude Code at when it is running on the Delphi XE7 machine,
which has the UCINET source but knows nothing about xucinet.

Give it this and nothing else:

> The R package xucinet is UCINET's twin and is measured against this build.
> Read https://raw.githubusercontent.com/stephenborgatti/xucinet/main/dev/UCINET-SIDE.md
> and follow it.

The repository is public, so that URL needs no authentication, no clone and no
`gh` login. Everything below is readable the same way by swapping the filename.

---

## The two jobs

**1. Keep the build number honest.** xucinet declares one UCINET build as its
reference and checks every golden fixture against it. That only works if the
build number changes whenever behaviour changes.

**2. Say what changed.** When a UCINET routine's output moves, the fixtures that
captured the old output are wrong, and the R side has no way to know unless it
is told.

---

## Bumping the build number

The version lives in `Source/Uci.dproj`, in three places that must move
together:

```xml
<VerInfo_MinorVer>849</VerInfo_MinorVer>
<VerInfo_Build>849</VerInfo_Build>
<VerInfo_Keys>...FileVersion=6.849.0.849;...</VerInfo_Keys>
```

Bump **`VerInfo_Build`**, and keep `VerInfo_MinorVer` and the `FileVersion`
string equal to it. `VerInfo_Build` is the one that matters: the displayed
version is major-dot-build, from `majorbuild()` in `Tools/G1Tools/uversion.pas`,
which does `result := major + '.' + build`. `VerInfo_Release` is 0 and unused, so
a 6.849.1 would appear nowhere a user or a test can see it.

**When to bump:** any change that alters what a routine outputs — a value, a
column heading, a matrix title, the shape of a saved dataset, the wording of a
header line. Not for refactors, comments or UI-only work.

This is not bureaucracy. On 7 September 2026 a fix to `eigenvec()` shipped
inside 6.849, so the buggy binary and the fixed one reported the same version.
The R side's fixtures went from wrong to right with every recorded version
string unchanged, and nothing in its test suite could have caught it. Only the
output *file names* changing gave it away; had the fix altered values instead,
wrong numbers would have been silently blessed as correct.

---

## The shared issue list

`dev/UCINET-ISSUES.md` in the xucinet repository is the queue. Raw URL:

```
https://raw.githubusercontent.com/stephenborgatti/xucinet/main/dev/UCINET-ISSUES.md
```

Read it before starting work — it is where the R side records UCINET bugs it has
found rather than silently copying them. Each entry says what was seen, where in
the Delphi, and what a fix would be, and most of them name the unit and the
procedure.

Entries are numbered and **never deleted**. Statuses:

| status | meaning for you |
|---|---|
| **open — fix pending** | Wanted. xucinet has already implemented the correct behaviour and is deliberately differing until this lands. |
| **open — no xucinet impact** | Real but cosmetic or UI-only. Fix when convenient. |
| **fixed in UCINET x.y** | Done. Left in place because the old behaviour is in every earlier build. |

---

## When you fix one

Do these four things, and tell Steve the first three so they reach the R side:

1. **Bump the build**, as above.
2. **Note which routines changed output**, by name. The R side has golden
   fixtures per routine and needs to know which to regenerate; regenerating all
   of them is possible but means re-running batch files by hand.
3. **Note any change to output names or shapes** — a renamed column, an extra
   level in a saved stack, a different suffix on a companion dataset. These
   break the test harness in a way that pure value changes do not, because the
   harness looks fixtures up by name.
4. Leave the issue entry alone. The R side moves it to *fixed in UCINET x.y*
   when it has regenerated the fixtures and confirmed the new behaviour, so that
   the entry and the fixtures change in the same commit.

If you want to write the change up yourself, the format that lands cleanly is
just this, in a message or a file Steve can paste:

```
UCINET 6.850
- issue 3: eigenvec() now honours the assigned output name for asymmetric input.
  Output names changed: <out> and <out>-eig in both branches, replacing
  <input>-eval / -lvec / -lveci / -rvec / -rveci.
- routines with changed output: eigenvec
```

---

## What not to do from that machine

Do not edit the xucinet repository. The two sides are deliberately kept apart:
UCINET changes land in the Delphi tree, and the R side follows them in its own
commit, after regenerating fixtures against the new build. A change that arrives
in both at once cannot be checked, because there is no moment where old fixtures
meet new behaviour and the test suite has a chance to complain.

Note also that the UCINET source is **not under version control** — it is a
Dropbox folder, and it already contains files with "conflicted copy" in their
names from two machines writing at once. Be careful about editing the same file
from two places, and prefer telling Steve to making a change you cannot revert.

---

## Background, if it is wanted

- `dev/UCINET-ISSUES.md` — the queue, and the conventions that govern it.
- `inst/DIFFERENCES.md` — the user-facing ledger of where xucinet and UCINET
  differ today. An entry there is removed when UCINET catches up.
- `dev/SPEC.md` — the design, including the chapter 9 addendum on how node-level
  routines report.
- `inst/reference/delphi/` — the Delphi units the R port was written against,
  vendored so the port can be checked against the source rather than a
  description of it.
