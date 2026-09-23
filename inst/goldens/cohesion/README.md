# Chapter 10 goldens — whole-network measures

The UCINET results the chapter 10 routines are written against. Nothing here
has been generated yet: the batch in `make_goldens.txt` is part of the single
goldens sweep at the end, and until it runs every test that names a fixture
below calls `skip_if_no_golden(<name>, "cohesion")` and skips.

## `xcohesion()` is the exception, and needs nothing here

Its fixtures already exist. The Phase 0 density run saved UCINET's whole
33-measure block for three datasets — `../density/G_CAMPNET_COH`,
`G_BAKER_COH` and `G_HIGHTECH_COH` — because the Density form and
Network | Whole-Network Measures both call `ucohesion.getcohesion`. So
`xcohesion()` is golden-tested today, on all 33 measures across all five
columns, and its tests run rather than skip.

## Fixtures the tests expect

| fixture | routine | what it is |
|---|---|---|
| `g10_recip_campnet_dyad` | `xreciprocity` | dyad-based |
| `g10_recip_campnet_arc` | `xreciprocity` | arc-based |
| `g10_recip_sampson` | `xreciprocity` | a second, denser network |
| `g10_recip_camp92` | `xreciprocity` | valued: the case where the report's two halves disagree |
| `g10_trans_campnet_trip` | `xtransitivity` | triplets, the dialog default |
| `g10_trans_campnet_tri` | `xtransitivity` | triads |
| `g10_trans_hightech` | `xtransitivity` | three relations at once |
| `g10_trans_disc` | `xtransitivity` | disconnected |
| `g10_cyc_campnet` | `xcyclicality` | |
| `g10_cyc_sampson` | `xcyclicality` | |
| `g10_comp_campnet_weak` | `xcomponents` | weak, the dialog default |
| `g10_comp_campnet_strong` | `xcomponents` | strong |
| `g10_comp_disc_weak` | `xcomponents` | several components |
| `g10_comp_iso_weak` | `xcomponents` | an isolate, which must come back as a component of size 1 |
| `g10_hom_campnet_gender` | `xhomophily` | the seven measures, by Gender |
| `g10_mix_campnet_obs` | `xdensitybygroups` | observed mixing |
| `g10_mix_campnet_exp` | `xdensitybygroups` | expected, Density model |
| `g10_mix_campnet_den` | `xdensitybygroups` | density table |
| `g10_mix_campnet_ratio` | `xdensitybygroups` | observed over expected |

## Two things only the log records

`xcomponents()`'s five heterogeneity figures — Component ratio, Heterogeneity,
Normalized heterogeneity, Entropy, Normalized entropy — are printed and not
saved to a dataset, so the session log is the only record of them. The same
goes for the within/between matrix that Homophily | Categorical prints above
its scores, which is what `$matrices$Mixing` is checked against.

Please save UCINET's own log rather than pasting from the window.

## Would unblock work

`g10_mix_campnet_exp_config` and `g10_mix_campnet_exp_fixedout`, if the two
other expected-value models are run, are what would let those models be
ported. They are refused at the moment rather than guessed.

The same applies to the closeness and eigenvector centralizations:
`xcentralization()` covers degree and betweenness only, because UCINET reports
a figure for all four but the chapter 9 goldens hold none of the other two.
Those belong with the chapter 9 family rather than here, but they are the
other thing a UCINET session would unblock.
