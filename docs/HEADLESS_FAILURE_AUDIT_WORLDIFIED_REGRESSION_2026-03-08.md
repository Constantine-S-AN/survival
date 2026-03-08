# Headless Failure Audit: Worldified Regression Coverage Pass

Audit date: 2026-03-08

## Commands Run

- `./scripts/ci/run_plugin_focused_tests.sh`
  - Result: `PASS`
- `./scripts/ci/run_headless_tests.sh`
  - Result: `failed=56`

## Scope Separation

This note records unrelated broad-suite failures discovered while adding worldified smoke coverage.

The new task changes only:

- `tests/smoke/day_world_shell_smoke.gd`
- `scripts/ci/run_plugin_focused_tests.sh`
- `scripts/meta/meta_loop_controller.gd`

The broad-suite failures still originate from the existing `tests/test_runner.gd` meta-loop scaffold expectations and its runtime assumptions.

## What Still Passes

- The smoke-focused scripted suite passes, including:
  - `DayWorldShellSmoke`
  - `RestaurantWorldShellSmoke`
  - `ShopWorldShellSmoke`
  - existing dialogue and daily-order smoke scenes

## Unrelated Broad-Suite Failure Pattern

`./scripts/ci/run_headless_tests.sh` still fails inside `_run_meta_loop_scaffold_tests()` in [`tests/test_runner.gd`](../tests/test_runner.gd).

Observed failure themes:

- day-count drift inside the legacy scaffold path
- restaurant service expectations no longer matching current loop timing
- save/load assertions keyed to older mid-loop baselines
- shop purchase assertions tied to older resource/gold assumptions

Representative failures from the run:

- `restaurant records the service day (actual=4 expected=2)`
- `meta loop preserves day across reload (actual=6 expected=2)`
- `second return summary advances to day 3 (actual=7 expected=3)`
- `shop can buy the first new seed type`
- `shop can buy a restaurant upgrade`

## Conclusion

The new worldified regression coverage is green through the smoke suite.

The remaining broad-suite failures should be handled as a separate re-baselining effort for `tests/test_runner.gd` and the assumptions in its older hybrid-loop scaffold.
