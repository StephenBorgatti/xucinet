# xucinet — status

Updated 17 Sep 2026 (Cowork session, from the repo as cloned on the new machine; Claude
Code should correct anything here it knows better). Overwrite the first three sections each
session; append to the last two.

## Where things stand

- Version 2.0.0.9000. Phase 0 complete (class, coercers, print, IO for csv/xlsx/##h/uci/
  dl/vna, 39 datasets, 1e aliases, pkgdown site, CI on Windows and Ubuntu).
- Chapter 9 (centrality) complete: xdegree, xbetweenness, xcloseness, xeigenvector, xbeta,
  xpncentrality, xcentrality, xreach, xbetareach, xhubsauthorities, xinduced; goldens in
  `inst/goldens/centrality/`.
- Chapter 10: xdensity only (Phase 0 pilot). xcohesion, xcomponents, xreciprocity,
  xtransitivity, xcentralization, xdensitybygroups, xhomophily not started.
- Chapter 6: `dev/design/ch06-questions.md` written 8 Sep (prompt 1 of
  `asnr2e/docs/prompts/ch06-claude-code-prompts.md`). Awaiting Steve's inline answers. No
  goldens (`inst/goldens/multivariate/` does not exist yet), no code.
- Chapters 5, 7, 8, 11, 12, 13, 14 routines not started. The merged book text already
  names them; the list of what the text asserts is in `asnr2e/docs/plan.md`
  ("Decoupling decision", requirements list).
- Machine: repo cloned to `C:\Users\sborg2\GitHub\xucinet` on the new computer 16 Sep;
  R toolchain and gh authentication there still to verify.

## Done this session (17 Sep 2026)

- Added the session routine to `CLAUDE.md`; created this file.

## Next

1. Verify the toolchain on the new machine: `devtools::check()` passes, `gh auth status`
   OK, pkgdown builds.
2. Steve answers `dev/design/ch06-questions.md`; then chapter 6 prompt 2 (goldens batch),
   prompt 3 (implementation).
3. xplot() (SPEC D13) — needed to finish the chapter 7 text merge.
4. Chapter 10 whole-network routines (xcohesion et al.), then 8, 11, 12, 13, 14 in the
   order the book requirements list gives.

## Decisions

- 6 Sep 2026: seven chapter 9 design answers (node table columns follow UCINET headings;
  sort=NULL keeps node order; centralization in $summary; closeness default = UCINET
  dialog default; one section per relation; 2-mode normalization by opposite mode size;
  xcentrality one table with NA + note when undefined). Recorded in SPEC addendum.
- 8 Sep 2026: chapter 6 routines ported from borgworld; type= required; no metric MDS.
- 17 Sep 2026: `dev/STATUS.md` is the hand-off between Claude Code and Cowork sessions;
  issues are the task queue.

## Open questions for Steve

1. Answers to `dev/design/ch06-questions.md` (blocks chapter 6 prompts 2 and 3).
2. UCINET items found during Phase 0 (in `dev/UCINET-ISSUES.md`): 2-mode average degree
   divides by ncols; importfullmatrix pads a short file silently; headless batch driver for
   menu routines. Which of these are being fixed in UCINET, and in which version?
