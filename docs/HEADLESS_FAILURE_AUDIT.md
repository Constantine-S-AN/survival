# Headless Failure Audit

Audit date: 2026-03-08

## Commands Run

- `./scripts/ci/run_headless_tests.sh`
  - Result: `failed=47`
- `./scripts/ci/run_plugin_focused_tests.sh --skip-import`
  - Result: `PASS`

## Conclusion

The committed plugin integrations are currently isolated from the broad-suite failures.

- No failures in the broad suite point into the committed plugin integration files:
  - `scripts/meta/day_hub_intro_dialogue_layer.gd`
  - `scripts/meta/daily_orders.gd`
  - `scripts/meta/daily_orders_board.gd`
  - `scripts/quests/daily_order_quest.gd`
  - `data/dialogue/`
  - `data/quests/daily_orders/`
- The plugin-focused coverage for Dialogue Manager and QuestSystem stays green.
- The broad-suite failures overlap the current dirty worktree in `meta_loop`, `restaurant`, `shop`, and the test harness itself.

## Failure Buckets

### 1. Clearly Unrelated Dirty Worktree Issues

This is the main bucket: `46` failures are exercised through files that are currently dirty in the worktree.

Dirty files overlapping the failing areas:

- `tests/test_runner.gd`
- `scripts/meta/meta_loop_controller.gd`
- `scripts/meta/day_state.gd`
- `scripts/meta/economy_state.gd`
- `scripts/meta/inventory.gd`
- `scripts/day/restaurant/menu_planner.gd`
- `scripts/day/restaurant/restaurant_controller.gd`
- `scripts/day/shop/shop_controller.gd`
- `scenes/day/restaurant/Restaurant.tscn`
- `scenes/day/shop/Shop.tscn`
- `scripts/core/localization.gd`

Failure clusters:

- Bootstrap / day progression / onboarding
  - `meta loop enters day hub from main menu`
  - `meta loop starts each daytime loop in the morning`
  - `meta loop starts with a full daytime action budget`
  - `day hub shows an early-day onboarding title`
  - `day hub onboarding explains the hybrid loop`
  - `meta loop keeps the current daytime screen visible while paused`
  - `farm till succeeds on plot 0`
  - `farm can spend more of the day preparing a second plot`
  - `farm plants herb on plot 1 before the first night`
  - `farm actions can fully consume the shared daytime action budget`
  - `reload before summary continue preserves the current combat day`
  - `meta loop advances to next day after summary`
  - `day hub onboarding advances to the second-day guidance`
  - `second plot keeps its planted herb when day 1 time is invested in farm prep`

- Restaurant / save-load / day-state cascade
  - `restaurant keeps selected menu recipe`
  - `restaurant service opens with stocked ingredients`
  - `restaurant service generates gold`
  - `restaurant records the service day`
  - `restaurant service consumes a major chunk of the day`
  - `restaurant service can finish the remaining daytime action budget`
  - `restaurant service records sold dish stats`
  - `restaurant service summary stores the served day`
  - `restaurant service summary stores sold dish counts`
  - `restaurant service summary records herb consumption`
  - `restaurant service inventory applies consumed wheat exactly`
  - `meta loop preserves day across reload`
  - `save/load preserves the current daytime phase`
  - `save/load preserves an exhausted daytime action budget`
  - `meta loop preserves restaurant gold after reload`
  - `meta loop preserves restaurant service day after reload`
  - `save/load preserves the selected menu plan after service`
  - `save/load preserves sold dish statistics`
  - `save/load preserves the last service summary day`
  - `save/load preserves same-day watering`
  - `save/load preserves the second planted crop`
  - `save/load preserves same-day watering on the second crop`
  - `farm work stops once the daytime budget is exhausted`
  - `using the last farm action exhausts the shared daytime budget`
  - `farm status explains when no daytime actions remain`
  - `second return summary advances to day 3`
  - `day hub onboarding advances to the third-day guidance`
  - `restaurant summary persists across day transitions`
  - `Kelpfire Noodles becomes craftable from night loot on day 3`

- Shop
  - `shop can sell harvested herbs for gold`
  - `shop can buy the first new seed type`
  - `shop can buy a restaurant upgrade`

Strong indicator that this is not a plugin regression:

- Several failures show impossible day drift for the old baseline expectations, for example:
  - `restaurant records the service day (actual=4 expected=2)`
  - `meta loop preserves day across reload (actual=6 expected=2)`
  - `second return summary advances to day 3 (actual=7 expected=3)`
- The dirty `tests/test_runner.gd` also adds new pause/menu transitions inside `_run_meta_loop_scaffold_tests`, which makes downstream expectation drift highly likely unless the whole scenario was re-baselined together.

### 2. Regressions Plausibly Caused by Recent Plugin Integrations

Confirmed plugin-regression failures: `0`

Evidence:

- `./scripts/ci/run_plugin_focused_tests.sh --skip-import` passes.
- No broad-suite failure references the committed Dialogue Manager or QuestSystem bridge files.
- The failing assertions all sit inside the broad meta-loop scaffold scenario and overlap files already dirty outside the plugin work.

### 3. Pre-existing / Incomplete Test Expectations

There is `1` clear stale expectation in the broad suite:

- `profile migration upgrades schema to v6 (actual=7 expected=6)`

Reason:

- `scripts/core/profile_store.gd` now defines `PROFILE_SCHEMA_VERSION := 7`.
- `tests/test_runner.gd` still expects schema `6`.

This is a test maintenance mismatch, not a runtime regression.

## Safe-Fix Decision

No code fix was applied in this audit pass.

Reason:

- The smallest candidate fixes all require editing files that are already dirty and outside the committed plugin integration surface.
- Updating `tests/test_runner.gd` expectations or changing the current `meta_loop` / `restaurant` / `shop` runtime would risk mixing this audit with unrelated in-progress work.

## Recommended Next Step

To restore the broad suite cleanly, stabilize or shelve the current dirty worktree in this order:

1. `tests/test_runner.gd`
2. `scripts/meta/meta_loop_controller.gd`
3. `scripts/day/restaurant/*` and `scenes/day/restaurant/Restaurant.tscn`
4. `scripts/day/shop/shop_controller.gd` and `scenes/day/shop/Shop.tscn`
5. `scripts/meta/day_state.gd`, `scripts/meta/economy_state.gd`, `scripts/meta/inventory.gd`

Then rerun:

- `./scripts/ci/run_plugin_focused_tests.sh`
- `./scripts/ci/run_headless_tests.sh`
