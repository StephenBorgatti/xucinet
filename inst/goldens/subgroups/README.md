# Chapter 11 goldens — subgroups

The UCINET results the chapter 11 routines are written against. Nothing here
has been generated yet: the batch in `make_goldens.txt` is part of the single
goldens sweep, and until it runs every test that names a fixture below calls
`skip_if_no_golden(<name>, "subgroups")` and skips.

Partitions are compared as set partitions (`expect_same_partition()`), so
cluster numbering does not matter. Cliques are compared column by column,
because their order is part of what is being tested.

## Fixtures the tests expect

| fixture | routine | what it is |
|---|---|---|
| `g11_cliq_campnet` | `xcliques` | clique indicator matrix (node by clique), minimum 3, Weak |
| `g11_cliq_hightech_fr` | `xcliques` | hightech Friendship |
| `g11_cliq_zachary` | `xcliques` | zachary |
| `g11_fact_campnet_2` | `xfactions` | partition, 2 factions, Hamming, **seed 1** |
| `g11_fact_campnet_3` | `xfactions` | 3 factions, seed 1 |
| `g11_fact_zachary_2` | `xfactions` | zachary, 2 factions, seed 1 |
| `g11_gn_zachary` | `xgirvannewman` | the partitions dataset |
| `g11_gn_campnet` | `xgirvannewman` | the partitions dataset |
| `g11_louv_zachary` | `xlouvain` | the partitions dataset |

## Louvain is expected to differ

UCINET issue 26: UCINET's Louvain compares each move with the modularity from
before the pass and reports the last node's Q for each level. xucinet fixes
both (Steve, 23 September 2026), so `g11_louv_zachary` is expected to differ
until UCINET does too. The test says so with `expect_differs_from_ucinet(26)`.
When the fix lands, regenerate this fixture from the fixing build and the test
becomes a partition comparison.

## The seed matters for factions

Factions is random, and xucinet reproduces Delphi's generator, so the same
seed should give the same partition. The dialog fills in a random seed each
time it opens; **type 1 into *Random number seed*** before each run, and keep
the log, which records it.
