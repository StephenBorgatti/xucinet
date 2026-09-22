# xucinet 2.0.0.9000 (development)

## Chapter 5: transformations (22 September 2026)

* `xtranspose()`, `xdichotomize()`, `xsymmetrize()`, `xnormalize()` and
  `xrecode()`: the first of the chapter 5 transformations. Each returns a
  `xucinet` dataset rather than a report (design question G2), titled the way
  UCINET names the dataset it saves, with a `history` attribute carrying the
  figures the UCINET log prints.
* `xdichotomize()` follows the Transform | Dichotomize menu form: six
  operators, configurable `then` and `otherwise` values, and five ways to
  treat the diagonal, defaulting to the else-value as the dialog does. It can
  also choose the cutoff itself, by target `density` or by `method = "maxcor"`.
* `xsymmetrize()` offers all sixteen of the dialog's methods.
* Differences ledger entries 13 and 14.

## Chapter 6: multivariate techniques (18 September 2026)

* `xmds()`: classical and non-metric multidimensional scaling of a proximity
  matrix, ported from borgworld's `bclassicalmds()` and `bnonmetricmds()`.
  `type=` is required. `xshepard()` draws the Shepard diagram of a non-metric
  result.
* `xcorrespondence()`: correspondence analysis, ported from borgworld's
  `bcorresp()`, with the total inertia computed from the full spectrum.
* `xhclust()`: Johnson's hierarchical clustering, ported from borgworld's
  `bhiclus()`, reported in UCINET's layout: text cluster diagram, one partition
  per distinct merge level, measures of cluster adequacy, cluster sizes.
* `as_xucinet()` accepts `dist` objects.
* `new_xucinet_output()` gains `fields` (header lines) and `preamble`
  (preformatted lines printed before the tables).
* Differences ledger entries 6-12.
