# Chapter 14 goldens — testing hypotheses

Nothing here has been generated yet; the batch in `make_goldens.txt` is part
of the single goldens sweep.

**Only observed statistics are compared exactly.** UCINET draws its
permutations with its own generator, so its p-values can only be compared
with xucinet's to within sampling error: for a proportion p from N
permutations the standard error is sqrt(p(1-p)/N), and the tests allow three
of them.

| fixture | routine | what it is |
|---|---|---|
| `g14_qap_padgett` | `xqap` | QAP results, Marriage by Business |
| `g14_mrqap_hightech` | `xmrqap` | Dekker coefficients, Advice on Friendship and ReportTo |
| `g14_lrqap_hightech` | `xlrqap` | LR-QAP coefficients, same model |
| `g14_nodereg_camp92_coef` | `xregression` | node-level regression coefficients |
