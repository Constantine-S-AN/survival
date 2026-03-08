# Headless Failure Audit: Worldified Save/Load Coverage Pass

Audit date: 2026-03-08

## Commands Run

- `./scripts/ci/run_plugin_focused_tests.sh --skip-import`
  - Result: `PASS`
- `./scripts/ci/run_headless_tests.sh`
  - Result: `failed=2`

## Scope Separation

This note records unrelated broad-suite failures observed while adding focused save/load smoke coverage for the worldified daytime loop.

The save/load task changes are limited to additive restore-state plumbing and new smoke scenes/helpers. The failures below come from the broad `TestRunner` suite and are not part of the new focused save/load coverage.

## Unrelated Broad-Suite Failures

From `tmp/logs/headless_tests_20260308_150945_9739.log`:

- `profile migration upgrades schema to v6 (actual=7 expected=6)`
- `day 2 featured orders point at the first meaningful night return`

## Conclusion

The focused worldified save/load smoke matrix is green, and the plugin-focused smoke runner remains green with the new save/load scenes included.

The remaining broad-suite failures should be handled separately from this task:

- a schema-version expectation in the profile migration coverage
- a featured-orders expectation in the broader `TestRunner` day-2 scaffold
