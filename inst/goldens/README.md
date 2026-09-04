# Golden fixtures

UCINET's own output, kept so the test suite can prove xucinet returns the same
numbers. Two kinds live here.

| folder | what it holds |
|---|---|
| `ucinet/` | `##h`/`##d` files in every header version, for the format reader (issue #3). Inputs, not results. |
| `density/` | the Density goldens (issue #7): the four input datasets, the UCINET batch that measures them, and the results it writes. |

## Regenerating

Each family has a `make_goldens.txt`, a UCINET CLI script. From UCINET's command
line box:

```
->cd <package>\inst\goldens\density
->run make_goldens.txt
```

Commit whatever it writes. Also save the output log next to it as
`make_goldens.log`: the saved datasets carry the numbers, but only the log shows
the printed format, which is what the report renderer is matched against.

Regenerate whenever UCINET changes, and note the build that produced them.

## Why results are datasets, not scraped text

Each measure is assigned to a dataset, so UCINET writes a `##h`/`##d` pair:

```
g_campnet_den = density(campnet)
```

`xreaducinet()` then reads it exactly. Scraping the log would mean parsing text
and rounding everything to the three decimals UCINET displays, which is far
short of the 1e-6 the tests compare at. `parse_golden_log()` is still available
in `tests/testthat/helper-goldens.R` for the log, and for any routine whose CLI
form will not hand back a dataset.

## Adding a routine

Roughly ten lines. Say the routine is `xdegree`:

1. Make `inst/goldens/degree/`, and copy in the input `##h`/`##d` datasets it
   should be measured on.
2. Write `make_goldens.txt` there, assigning each result to a dataset whose name
   starts `g_`:
   ```
   dec 8
   g_campnet_deg = degree(campnet)
   dsp g_campnet_deg
   ```
3. In `tests/testthat/test-goldens.R`:
   ```r
   test_that("degree of campnet matches UCINET", {
     skip_if_no_golden("g_campnet_deg", "degree")
     expect_equal(xdegree(campnet)$nodes$Degree,
                  as.vector(golden_matrix("g_campnet_deg", "degree")),
                  tolerance = 1e-6)
   })
   ```
4. Run the batch in UCINET, commit the `g_*` files.

`skip_if_no_golden()` means step 3 can be committed before step 4 happens: the
test skips until the fixture exists, so CI stays green in between and turns into
a real comparison the moment the files land.

## Status

`density/` is written and waiting to be run. Everything in
`tests/testthat/test-goldens.R` skips until it has been.
