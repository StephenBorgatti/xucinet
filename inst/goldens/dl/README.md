# DL specimens

Real DL files, from `Ucinet/Datafiles` where UCINET ships them. Until these
arrived the DL reader was tested only against fixtures written from the keyword
table in `udlreader.pas`, which is the wrong way round: fixtures written from a
spec agree with the spec by construction.

They keep their `.dl` extension here for clarity, but note that UCINET ships
them as `.txt`, which is why `detect_filetype()` looks at a `.txt` file's first
token rather than trusting the extension.

| file | family | what it exercises that nothing else did |
|---|---|---|
| `games-nodelist1-embedded.dl` | nodelist1 | `LABELS EMBEDDED`, and `n 14` with no equals sign. Also an ego with no alters (`I3`), which has to survive as an isolate. |
| `samplike-edgelist1-embedded.dl` | edgelist1 | `LABELS EMBEDDED` on an edge list, with valued ties |
| `interaction-el1-quoted.dl` | edgelist1 | `format = el1`, the abbreviation; quoted multi-word labels (`"Hani Hanjour"`); a `matrix label:` block; a `comment =` line between blocks; and `LABELS EMBEDDED` sitting *inside* the labels block |

Each of these broke the reader when first run, which is the point of having them.

## Not included

- **`planned.txt`** is the same family as `interaction.txt` and adds nothing.
- **`krebs.txt`** is truncated. It declares `N=56, NM=5`, which needs 280 rows of
  56 values, and holds 278 full rows plus a partial row of 12 — 15,580 values
  where 15,680 are required. The reader refuses it and says so. Worth knowing if
  anyone reaches for that file expecting five matrices; it is a defect in the
  file, not in the reader.
