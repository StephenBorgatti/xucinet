# UCINET ##h/##d format fixtures

One dataset per header version, so `test-io-ucinet.R` checks the reader against
bytes UCINET actually wrote rather than bytes we wrote. The layout each version
uses is described in `inst/reference/delphi/README.md`.

| fixture | version | shape | what it exercises | provenance |
|---|---|---|---|---|
| `hightech-v4020` | 4020 | 21 x 21 x 3 | fixed 20-byte labels; `haslab = 001`, so only the relation names are stored and nodes fall back to 1..n | UCINET (Krackhardt high-tech) |
| `davis-v5000` | 5000 | 18 x 14 | variable-length 8-bit labels; `ndim = 2`, i.e. no level dimension at all | UCINET (Davis southern women) |
| `davis-byte-v5000` | 5000 | 18 x 14 | the same data stored as `byte` rather than `single` | UCINET |
| `sampson-v6000` | 6000 | 18 x 18 x 10 | variable-length UTF-16 labels; ten relations, named `SAMPLK1` … `SAMPNPR` | UCINET (Sampson monastery) |
| `campnet` | 6404 | 18 x 18 | 4-byte integer dimensions; a directed 1-mode network | UCINET (book battery) |
| `davis` | 6404 | 18 x 14 | 2-mode, where rows and columns differ and must not be swapped | UCINET (book battery) |
| `supremecourt` | 6404 | 376 x 9 | nine genuine missing cells, written by UCINET as 1e38 | UCINET (book battery) |
| `campnet-v4010-selfwritten` | 4010 | 18 x 18 | no magic bytes, no date record, fixed 10-byte labels | **xucinet** |
| `campnet-v6405-selfwritten` | 6405 | 18 x 18 | the trailing `istable` byte | **xucinet** |

## The two self-written fixtures

There is no UCINET-written 4010 or 6405 dataset to copy:

- **4010** predates the `DATE:` header. Of 67,592 `.##h` files on the author's
  machine, three classify as 4010, and all three are damaged — 157 KB headers
  with nonsense dates, which UCINET cannot read either. The 4010 reader is ported
  from `loadhdr4010` and exercised only by our own writer, so it is the one
  version not confirmed against UCINET.
- **6405** is new: `defaultucversion` only recently became 6405, and exactly one
  6405 file exists on that machine (not a public dataset, so not committed). The
  reader *was* checked against it during development — it parses, round-trips,
  and its trailing `istable` byte is 0 — but the committed fixture is ours.

Replacing either with a genuine UCINET file would strengthen the suite. Saving
any dataset from current UCINET produces a 6405 one.

## Provenance of the rest

`campnet`, `davis` and `supremecourt` are copied from the book's own
`3e/data/DataUCINET` battery. `hightech-v4020`, `davis-v5000`,
`davis-byte-v5000` and `sampson-v6000` are older-format copies of the same
classic published datasets, which ship with UCINET itself. Where a dataset
appears in two versions the test suite checks the values agree, which is what
makes the older readers trustworthy rather than merely self-consistent.
