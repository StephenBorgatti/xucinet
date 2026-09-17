# Instructions for Claude Code sessions

The conventions live in [dev/CLAUDE.md](dev/CLAUDE.md), together with the design
spec, the phase plan and the issue lists. They were moved out of the repository
root because pkgdown publishes every top-level `.md` as a page on the site.

This file exists only so that Claude Code, which reads its instructions from the
repository root and nowhere else, still finds them.

@dev/CLAUDE.md

## Session routine

- Start: read `dev/STATUS.md`, then run `gh issue list`. Open issues are the task
  queue. The book-side plan is `asnr2e/docs/plan.md` in the sibling repository
  (`../asnr2e`); read it when a task touches names, signatures or output layout,
  because the book text already asserts them.
- Every task larger than a typo is a GitHub issue. If the prompt gives a task that
  is not yet an issue, create it first (`gh issue create`), reference it in commits
  (`Refs #N`, `Closes #N`), and close it with a comment saying what was done and
  where. Anything that needs Steve (a decision, a UCINET run) gets the label
  `steve`.
- End: update `dev/STATUS.md` and commit it, even if nothing else was done. It
  is a status, not a log: overwrite "Where things stand", "Done this session" and
  "Next"; append to "Decisions" and "Open questions for Steve"; delete an open
  question once answered, moving the answer to "Decisions" (and to `dev/SPEC.md`
  if it is a design rule).
- Steve also works on this project in Cowork sessions, which have no memory of
  Claude Code sessions. `dev/STATUS.md`, `dev/`, and the issues are the only
  channels between the two.
