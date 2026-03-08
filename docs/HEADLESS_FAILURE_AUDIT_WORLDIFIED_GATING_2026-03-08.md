# Headless Failure Audit: Worldified Gating Coverage Pass

Audit date: 2026-03-08

## Commands Run

- `./scripts/ci/run_plugin_focused_tests.sh --skip-import`
  - Result: `PASS`
- `./scripts/ci/run_headless_tests.sh`
  - Result: `failed=56`

## Scope Separation

This note records unrelated broad-suite failures observed while adding focused duplicate-trigger and modal-gating smoke coverage for the worldified daytime loop.

The gating task changes are limited to:

- additive gated debug interaction hooks for `DayWorld`, `Restaurant`, and `Shop`
- an idempotent `return_summary` continue path
- new focused smoke scenes and helper methods

The failures below still come from the older `tests/test_runner.gd` meta-loop scaffold path rather than the new focused smokes.

## Unrelated Broad-Suite Failure Pattern

From `tmp/logs/headless_tests_20260308_152559_13925.log`:

- restaurant service/day-count assertions in the legacy scaffold are still drifting, for example:
  - `restaurant service opens with stocked ingredients`
  - `restaurant records the service day (actual=4 expected=2)`
  - `meta loop preserves day across reload (actual=6 expected=2)`
  - `second return summary advances to day 3 (actual=7 expected=3)`
- later scaffold expectations around onboarding/orders/shop progression are also still out of sync, for example:
  - `day hub onboarding advances to the third-day guidance (actual= expected=Day 3 Guide)`
  - `day 3 featured orders still tie premium fish back into the restaurant loop`
  - `shop can sell harvested herbs for gold`
  - `shop can buy the first new seed type`
  - `shop can buy a restaurant upgrade`

## Conclusion

The focused worldified gating/one-shot smoke coverage is green, and the plugin-focused smoke runner remains green with the new scenes included.

The remaining broad-suite failures should still be handled as a separate `tests/test_runner.gd` scaffold re-baselining effort rather than folded into this task.
