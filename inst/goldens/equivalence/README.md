# Chapter 12 goldens — equivalence, blockmodels, core/periphery

The UCINET results the chapter 12 routines are written against. Nothing here
has been generated yet: the batch in `make_goldens.txt` is part of the single
goldens sweep, and until it runs every test that names a fixture below calls
`skip_if_no_golden(<name>, "equivalence")` and skips.

## Fixtures the tests expect

| fixture | routine | what it is |
|---|---|---|
| `g12_se_campnet_euc` | `xstructuralequivalence` | Euclidean distances, dialog defaults |
| `g12_se_campnet_cor` | `xstructuralequivalence` | correlations |
| `g12_se_sampson` | `xstructuralequivalence` | Esteem and Disesteem stacked |
| `g12_se_hightech` | `xstructuralequivalence` | Advice, directed |
| `g12_block_campnet` | `xblockmodel` | aggregated matrix, campnet by gender |
| `g12_contcp_campnet` | `xcoreperiphery` | continuous coreness |
| `g12_contcp_zachary` | `xcoreperiphery` | continuous coreness |
| `g12_catcp_campnet` | `xcoreperiphery` | categorical partition |
| `g12_catcp_zachary` | `xcoreperiphery` | categorical partition |
| `g12_catcp_baker` | `xcoreperiphery` | categorical partition, Baker dichotomized |

## Categorical core/periphery depends on UCINET's random starts

UCINET's categorical routine calls `randomize`, so its random starts cannot be
reproduced from a seed. Where the fit has a unique best partition the
partition is compared; otherwise only the fit in the log is (ledger entry 35).
