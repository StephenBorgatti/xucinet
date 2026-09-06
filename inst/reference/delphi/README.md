# Delphi reference

Units from UCINET and its G1/G2 tool libraries, copied here unchanged so the R
port can be checked against the source of truth rather than against a
written-down description of it. We own this code, so the port can be exact.

Two families: the ones that define the `##h`/`##d` file format, and the ones
that define the printed report.

## The file format

| file | taken from | what the port uses it for |
|---|---|---|
| `utucdataset.pas` | `Tools/G2Tools` | `tucdataset.loadhdr*` / `savehdr` — the header layout of every version, `readfixedlabels` / `readvariablelabels` / `readunicodelabels`, `readtitle`, `readdimensions`, `getfileversion` |
| `ucommon.pas` | `Tools/G2Tools` | the `datatype` enum and its ordinals, `dtsize`, `na = 1E37`, `bna = 1E38`, `defaultucversion` |
| `uufile.pas` | `Tools/G1Tools` | `ufile.loadblock` (raw `blockread`), and `seekrow` / `seekmatrix`, which is where the `.##d` element order is actually defined |
| `utsmat.pas` | `Tools/G2Tools` | `tsmat.loadmat` / `loadrows` (the `.##d` read loop), and `isna`, which defines the missing-value test |

## What the format is

`.##h` is the header, `.##d` is the data. The header version is decided by the
first six bytes, which are a Delphi `ShortString`: one length byte then five
characters.

| version | opening | date record | dimensions | labels | extra |
|---|---|---|---|---|---|
| 4010 | *(none — file starts at `dt`)* | none | `smallint` (2 bytes) | fixed 10 | |
| 4020 | `05 "DATE:"` | 10 bytes | `smallint` | fixed 20 | |
| 5000 | `05 "DATE:"` | 10 bytes | `smallint` | variable, 8-bit | |
| 6000 | `05 "DATE:"` | 10 bytes | `smallint` | variable, UTF-16LE | |
| 6404 | `05 "V6404"` | 10 bytes | `integer` (4 bytes) | variable, UTF-16LE | |
| 6405 | `05 "V6405"` | 10 bytes | `integer` | variable, UTF-16LE | trailing `istable` byte |

For 4020/5000/6000 the version is not in the file: all three say `DATE:`, and
the `labtype` field of the date record (0/1/2/3) picks 4010/4020/5000/6000.

After the opening the layout is the same in every version:

```
dt        1 byte    index into the datatype enum
ndim      2 bytes   number of dimensions, normally 2 or 3
dims      ndim * 2 or 4 bytes   dims[1] = NCOLS, dims[2] = NROWS, dims[3] = nlevels
title     1 length byte, then that many characters
haslab    ndim bytes, one boolean each
labels    column labels, then row labels, then matrix (relation) labels,
          each block present only if its haslab byte is set
```

`dims[1]` is the **column** count and `dims[2]` the **row** count — the order is
easy to get backwards. `readdimensions` in `utucdataset.pas` is the authority.

The date record is five Delphi `Word`s — `year, month, day, dow, labtype` — so
**10 bytes**, not 20. A comment inside `loadhdr6404` says a word is four bytes;
that comment is wrong. Decoding `Borgatti_Campnet.##h` as 10 bytes yields
2024-03-20 with `dow = 4`, matching both the file's own timestamp and the fact
that 20 March 2024 was a Wednesday.

Fixed labels of size *n* are one length byte plus *n - 1* characters, because
`readfixedlabels` reads *n* bytes starting at the ShortString's length byte.
Variable labels are a 2-byte count **of bytes** (not characters) followed by
that many bytes; for the UTF-16LE versions the character count is half the byte
count.

`.##d` has no header at all. It is `nm` matrices back to back, each stored row by
row, with elements of `dtsize[dt]` bytes. From `ufile.seekrow`, element (i, j) of
matrix k sits at byte `dtsize[dt] * ((k-1)*nr*nc + (i-1)*nc + (j-1))`. So the
file is exactly `nr * nc * nm * dtsize[dt]` bytes, which is what the port checks
on every read.

## Missing values

`tsmat.isna` is `cell[i,j] >= na` with `na = 1E37`, and `cell` is a `single`.
UCINET writes `bna = 1E38` for a missing value. Note that `1E37` stored as a
`single` is 9.99999993e36, which is *below* 1e37, so UCINET does not itself treat
a stored single `1e37` as missing; the port reproduces that rather than
"improving" it with a tolerance.

## The printed report

Added 6 September 2026. Steve's point was that the layout of a report is
determined by code we can read, and that reading it beats sampling an output
log, because a log shows one path through a routine that branches on its dialog
controls. These are the units that decide what a report looks like.

| file | taken from | what it defines |
|---|---|---|
| `utlogfile.pas` | `Tools/G2Tools` | `tlogfile.stdcreate` (the report title block), `putfn` / `putstr` / `putint` / `putfloat` (the header field lines — `putstr` right-pads the label to `pwidth`, which is the 40-column field `print.xucinet_output()` uses), `lf` |
| `utmat.pas` | `Tools/G2Tools` | `tmat.display` / `displayasmatrix(f, w, d)` — the matrix layout `cat_uci_matrix()` reproduces: a six-wide row-index field, wrapped column labels, per-column widths, the dashed rule. `w` and `d` are width and decimals, `-1` for automatic |
| `utstrvec.pas` | `Tools/G2Tools` | `binbywidth`, which is how an over-wide column label is wrapped: plain `copy(s, b, w)` slicing into fixed-width chunks left to right, as many header lines as the widest label needs. `pad` is `lpad`, so each chunk is right-aligned |
| `uc_DegreeCentrality.pas` | `Ucinet/Source` | the worked example of a node-level report: the nine header lines, `store()` / `store('n')` giving `Degree` / `Outdeg` / `Indeg` and `nDegree` / `nOutdeg` / `nIndeg`, the `Degree Measures` table, and `Graph Centralization -- as proportion, not percentage` at four decimals |
| `uc_ClosenessMeasures.pas` + `.dfm` | `Ucinet/Source` | the closeness dialog, which has no method selector: Freeman, Valente-Forman and reciprocal-distance closeness are reported together, each with its own options group. The `.dfm` `ItemIndex` values are the defaults |

Three things reading these corrected, which a single log would have left wrong:
the degree headings (not `NrmDegree`, and no `Share` column at all); graph
centralization being a titled matrix and a proportion rather than a percentage
line; and both the raw and the normalized column groups being optional, so a
four-column table is the default tick state and not a fixed shape. The third is
recorded as ledger entry 5 in `inst/DIFFERENCES.md`, since we deliberately
always emit all four.
