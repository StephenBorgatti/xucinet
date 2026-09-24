# Chapter 13 goldens — two-mode networks

Nothing here has been generated yet; the batch in `make_goldens.txt` is part
of the single goldens sweep, and until it runs every test that names a
fixture below skips.

| fixture | routine | what it is |
|---|---|---|
| `g13_affil_davis_rows` | `xaffiliations` | women by women, cross-products |
| `g13_affil_davis_rowsmin` | `xaffiliations` | women by women, cross-minimums |
| `g13_affil_davis_cols` | `xaffiliations` | events by events |
| `g13_bipartite_davis` | `xbipartite` | the 32 by 32 bipartite matrix |
| `g13_biclique_davis` | `xbicliques` | nodes (women then events) by biclique, 3 by 3, in UCINET's order |

2-mode centrality is checked against the chapter 9 fixtures
(`centrality/g9m_2mode_davis`, `davis-colcent`) through `xcentrality()`.
