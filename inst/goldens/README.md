# Golden fixtures

UCINET-generated outputs used by the test suite to check that xucinet returns
identical numbers. `make_goldens.txt` is a UCINET CLI batch script run on the
Windows side; each routine writes its result to `<dataset>-<routine>.txt`
here. Regenerate whenever UCINET changes, and commit the outputs.

Layout: one file per (dataset, routine, options) triple, plain text as UCINET
prints it; tests parse the numeric block.
