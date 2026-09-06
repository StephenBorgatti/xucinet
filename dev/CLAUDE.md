# xucinet — instructions for Claude Code sessions

Read `dev/SPEC.md` (design) and `dev/PLAN.md` (phases) before changing anything. The addendum at the
end of `dev/SPEC.md` records the naming decisions, and the chapter 9 addendum (6 Sep 2026) the
output conventions for node-level routines; the routine-by-routine list of
names and signatures is the crosswalk spreadsheet in the book repo (`asnr2e/crosswalk/`).

## Non-negotiable conventions

- Everything the user types is lowercase: function names (`xdegree`, `xqap`), argument names,
  argument values, dataset names. No camelCase anywhere in the exported API.
- Function names track UCINET's menu names, not igraph's. One UCINET routine = one function;
  dialog checkboxes become arguments. Argument vocabulary is fixed (SPEC D4): `net`, `relation`,
  `directed`, `weighted`, `normalize`, `mode`, `attribute`, `nperm`, `seed`, `save`. For file
  I/O: `filetype` (container) and `layout` (matrix / edgelist / nodelist). Never `format`.
- Every analysis function's first argument is `net`, and the first line of its body is
  `net <- xnet(net, substitute(net), ...)` (coerces, and keeps the caller's expression as the
  dataset title for the printed report). Users may pass matrices, data frames, igraph, network,
  xucinet objects, or file names.
- Every analysis function returns `new_xucinet_output(...)` (SPEC D5): `$nodes` in original
  node order, `$summary`, `$matrices`, `$assumptions`, `$call`. Printing reproduces UCINET's
  output log. Never sort node tables by value by default.
- UCINET numbers win. Delegate to igraph/sna only after a golden test proves numeric identity;
  otherwise implement natively. Every deliberate difference goes in the differences vignette.
- Auto-transformations (dichotomize, symmetrize) print the same notice UCINET prints and are
  recorded in `$assumptions`.
- Matrices are printed in UCINET's own layout — numbered column header, column labels wrapped
  into the value width, dashed rule, numbered and right-aligned row labels — by
  `cat_uci_matrix()` in `R/output.R`. That applies to `xdisplay()` and to every matrix section
  of a printed report, including the whole-network statistics block, which UCINET renders as a
  one-row matrix labelled with the dataset name. Decimals are decided per column, then every
  column is padded to one width for the whole matrix. `print.xucinet()`, which shows the raw
  network object rather than a report, deliberately keeps R's plain matrix printing.
- Every deliberate departure from UCINET, and anything we match that UCINET may itself have
  wrong, goes in `inst/DIFFERENCES.md` with who decided it and when.
- ASNR 1e names (e.g. `xDegreeCentrality`) are exported as thin deprecated wrappers in
  `R/aliases-1e.R`, each calling the 2.0 function and emitting a one-line message. They are
  not documented in vignettes.

## Workflow

- Roxygen for docs: edit the `#'` comments, then `devtools::document()`. Do not hand-edit
  `NAMESPACE` or `man/` once roxygen has been run for the first time.
- Tests with testthat (edition 3). A routine is not done until it has a test against a UCINET
  golden fixture in `inst/goldens/`.
- Run `devtools::check()` before committing anything that touches `R/`. CI runs R CMD check on
  Windows and Ubuntu.
- `devtools::check()` runs as its own step and must report **0 errors, 0 warnings** before a
  commit is made. Never chain it into `git` — `check() | tail` and `check() && git commit`
  both hide the non-zero exit status behind the last command in the pipeline, and a warning
  gets pushed. Read the result, then commit as a separate action.
- Commit messages: short imperative subject; body says which UCINET routine and which book
  section the change serves.
- Do not add dependencies to `Imports` without a note in the commit explaining why base R
  would not do. `igraph`, `sna`, `network`, `jsonlite`, `readxl` stay in `Suggests` and are
  loaded with `requireNamespace()`.

## Book coupling

The book chapters (Word files in Dropbox, not in git) reference these functions by name.
The book repo's `tools/lint_docx.py` checks every `x...(` in the chapters against this
package's export list, so renaming an exported function is a book edit as well as a code edit.
