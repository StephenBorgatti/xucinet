# Chapter 5 goldens — transformations and data management

The UCINET results the chapter 5 routines are written against. Nothing here has
been generated yet: the batch in `make_goldens.txt` is part of the single
goldens sweep at the end (decision of 20 Sep 2026, code first / goldens last),
and until it runs every test that names a fixture below calls
`skip_if_no_golden(<name>, "transform")` and skips.

Fixture names are `g5_<routine>_<dataset><_option>`, matching the `g9_` scheme
the chapter 9 goldens use.

## Inputs

All are shipped datasets, already readable by UCINET from this package:

| dataset | why |
|---|---|
| `campnet` | binary, directed, 18 nodes — the everyday case |
| `camp92` | the valued version of the same 18 nodes, so dichotomize has something to threshold |
| `hightech` | three relations, so the stack is exercised |
| `davis` | 2-mode, 18 women by 14 events |
| `g9_disc` | disconnected, so geodesic has unreachable pairs (already in `../centrality/`) |

`camp92` carries `Gender` and `Role` in `camp92_attr`, which is what the
attribute-to-matrix and collapse fixtures key on.

## Fixtures the tests expect

| fixture | routine | what it is |
|---|---|---|
| `g5_sym_campnet_max` | `xsymmetrize` | maximum |
| `g5_sym_campnet_min` | `xsymmetrize` | minimum |
| `g5_sym_campnet_avg` | `xsymmetrize` | average |
| `g5_dich_camp92_1` | `xdichotomize` | valued data, cutoff `> 1` |
| `g5_dich_camp92_3` | `xdichotomize` | valued data, cutoff `> 3` |
| `g5_dich_hightech` | `xdichotomize` | multi-relation, cutoff `> 0` |
| `g5_norm_campnet_rowsum` | `xnormalize` | rows, sum |
| `g5_norm_campnet_colmax` | `xnormalize` | columns, maximum |
| `g5_norm_campnet_both` | `xnormalize` | both, iterated |
| `g5_geo_campnet` | `xgeodesic` | distances |
| `g5_geo_disc` | `xgeodesic` | disconnected: shows UCINET's stored value for unreachable pairs |
| `g5_simil_campnet_corr` | `xsimilarities` | correlation, rows |
| `g5_simil_campnet_eucl` | `xsimilarities` | Euclidean distance, rows |
| `g5_simil_davis_jacc` | `xsimilarities` | Jaccard, columns, 2-mode |
| `g5_attr_camp92_same` | `xattributetomatrix` | Gender, exact match |
| `g5_attr_camp92_absdiff` | `xattributetomatrix` | Gender, absolute difference |
| `g5_coll_campnet_sum` | `xcombinenodes` | collapse by Gender, sum |
| `g5_coll_campnet_den` | `xcombinenodes` | collapse by Gender, density |

## What the unreachable fixture is for

`g5_geo_disc` is the one fixture whose *value* matters as much as its numbers.
`xgeodesic()` returns `NA` for an unreachable pair, because that is what
UCINET's own log describes ("Undefined distances were assigned missing
values"), but the dialog lets the user store something else and the stored
value is what lands in the dataset. The fixture settles which it is, and the
test then pins `unreachable =` to reproduce it.

## Regenerating

From UCINET's command line box:

```
->cd <package>\inst\goldens\transform
->run make_goldens.txt
```

Commit whatever it writes, plus the session log as `log_make_goldens.txt`, and
set the build number in `UCINET-VERSION`. Save UCINET's own log rather than
pasting from the window — the report layouts are checked against these logs
byte for byte.
