# Headless Failure Audit: Worldified Phase Coverage Pass

Audit date: 2026-03-08

## Commands Run

- `./scripts/ci/run_plugin_focused_tests.sh --skip-import`
  - Result: `PASS`
- `./scripts/ci/run_headless_tests.sh`
  - Result: `failed=56`

## Scope Separation

This note records unrelated broad-suite failures observed while adding focused phase-driven eligibility and world-cue regression coverage for the worldified daytime loop.

The phase-coverage task changes are limited to:

- additive debug snapshot fields for `DayHud`, `DayWorld`, and `MetaLoopController`
- new focused phase/cue smoke helpers and smoke scenes
- focused runner updates to include the new phase smokes

The failures below still come from the older `tests/test_runner.gd` meta-loop scaffold path rather than the new focused phase smokes.

## Unrelated Broad-Suite Failure Pattern

From `tmp/logs/headless_tests_20260308_153751_28067.log`:

- the legacy restaurant/day-advance scaffold remains out of sync, for example:
  - `restaurant service opens with stocked ingredients`
  - `restaurant records the service day (actual=4 expected=2)`
  - `save/load preserves the current daytime phase (actual=afternoon expected=evening)`
  - `second return summary advances to day 3 (actual=7 expected=3)`
- later scaffold expectations around day-3 onboarding, order surfacing, and shop progression are also still drifting, for example:
  - `day hub onboarding advances to the third-day guidance (actual= expected=Day 3 Guide)`
  - `day 3 featured orders still tie premium fish back into the restaurant loop`
  - `shop can sell harvested herbs for gold`
  - `shop can buy the first new seed type`
  - `shop can buy a restaurant upgrade`

## Conclusion

The new focused worldified phase/cue smoke coverage is green, and the plugin-focused smoke runner remains green with the added phase scenes included.

The remaining broad-suite failures should still be handled as a separate `tests/test_runner.gd` scaffold re-baselining effort rather than folded into this task.
