# xucinet 2.0.0.9000 (development)

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
