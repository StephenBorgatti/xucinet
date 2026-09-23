# Chapter 8 goldens — ego networks

The UCINET results the chapter 8 routines are written against. Nothing here
has been generated yet: the batch in `make_goldens.txt` is part of the single
goldens sweep at the end, and until it runs every test that names a fixture
below calls `skip_if_no_golden(<name>, "ego")` and skips.

Three routines have a command-line form: `holes()` (Structural Holes, the
ego-network model), `egocomp()` (Alter Composition, categorical) and
`categohom()` (Ego-Alter Similarity, categorical). Everything else is a menu
run, described in part B of `make_goldens.txt`.

## Fixtures the tests expect

| fixture | routine | what it is |
|---|---|---|
| `g8_egonet_campnet` | `xegonet` | Egonet Basic Measures, UNDIRECTED (the default) |
| `g8_egonet_campnet_out` | `xegonet` | OUT-NEIGHBORHOOD |
| `g8_egonet_campnet_in` | `xegonet` | IN-NEIGHBORHOOD |
| `g8_egonet_iso` | `xegonet` | g9_iso: the isolate row is where UCINET issue 17 shows |
| `g8_holes_campnet` | `xstructuralholes` | CLI `holes()`, union ego nets |
| `g8_holes_hightech` | `xstructuralholes` | valued: hightech, first relation (Advice) |
| `g8_holes_sampson` | `xstructuralholes` | ranked choices: sampson, first relation |
| `g8_holes_iso` | `xstructuralholes` | an isolate and pendants |
| `g8_holes_disc` | `xstructuralholes` | disconnected |
| `g8_holes_campnet_dr` | `xstructuralholes` | menu run: dyadic redundancy |
| `g8_holes_campnet_dc` | `xstructuralholes` | menu run: dyadic constraint |
| `g8_tiecomp_sampson` | `xtiecomposition` | all ten relations, Undirected (OR) |
| `g8_vtiecomp_camp92` | `xvaluedtiecomposition` | Outgoing only, first relation |
| `g8_egocomp_campnet_gender` | `xaltercomposition` | categorical, CLI `egocomp()` |
| `g8_compcont_hightech_age` | `xaltercomposition` | continuous, hightech Advice by Age |
| `g8_egohom_campnet_gender` | `xegoaltersimilarity` | categorical, CLI `categohom()` |
| `g8_egohomcont_hightech_age` | `xegoaltersimilarity` | continuous, all six measures |

## Where the tests expect UCINET to differ

Four UCINET bugs were found reading the source for this chapter
(`dev/UCINET-ISSUES.md`, issues 17 to 20). R does the correct thing, and the
tests that touch them call `expect_differs_from_ucinet()`:

- 17: Egonet Basic Measures reports zeros for an isolate. `g8_egonet_iso` is
  compared on every row but the isolate's.
- 18: Tie Composition ignores *Include ties to self*. No fixture uses it.
- 19: Valued Tie Composition, *Both in and out*, adds the outgoing value for
  an incoming tie. The fixture uses *Outgoing only*, the default, so it agrees.
- 20: Alter Composition | Continuous: the SD filters do nothing, and *Ignore
  tie strengths* drops one column too many. No fixture uses either.
