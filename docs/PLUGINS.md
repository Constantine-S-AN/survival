# Plugin Setup

## Installed Now

- `gd-plug` `0.2.6`
  - Vendored directly in `addons/gd-plug/`
  - Source commit: `a24ea096f1ca7dcba22c12d93fdf98036265e281`
  - Vendored directly because it is the bootstrap dependency manager. Keeping its core in-repo avoids a circular "install the installer first" step.
- Dialogue Manager `v3.10.1`
  - Vendored in `addons/dialogue_manager/`
  - Managed by [`plug.gd`](../plug.gd)
  - Source commit: `b160e4dff4014135ed16af268c604b748cc17f2d`
  - Upstream compatibility note: release line for Godot 4.6
- QuestSystem 2 `2.0.1.4_4`
  - Vendored in `addons/quest_system/`
  - Managed by [`plug.gd`](../plug.gd)
  - Source commit: `f31db6f3622f1d027b3fae389688b2bb71229612`
  - Upstream compatibility note: QuestSystem 2 release line for Godot 4.4+

## Update Flow

1. Update the pinned commit constants in [`plug.gd`](../plug.gd).
2. Run `./scripts/plugins/sync_plugins.sh`.
3. Run `./scripts/ci/validate_plugins.sh`.
4. Review the vendored diffs under `addons/` before committing.

`gd-plug` clones remote repos into `.plugged/` while syncing. The sync wrapper removes that cache by default after install so Godot does not scan upstream clone trees when you reopen the project. Set `KEEP_GD_PLUG_CACHE=1` if you want to inspect the cache locally.

## Manual Editor Steps

`Dialogue Manager` is now enabled in `project.godot`, and its `DialogueManager` autoload is committed so dialogue can run in normal gameplay without an editor-side activation step.

`QuestSystem` is now enabled in `project.godot`, and its `QuestSystem` autoload is committed for runtime use. Its startup update check is also pinned off in `project.godot` so editor opens stay quiet and offline-friendly.

No extra editor activation step is required for either enabled plugin.

## Validation

Use `./scripts/ci/validate_plugins.sh` to verify:

- pinned plugin files exist where expected
- the project still imports headlessly
- the existing headless test suite still passes

Use `godot --headless --path . res://tests/smoke/QuestSystemDailyOrdersSmoke.tscn --quit-after 10` for a focused QuestSystem + daily-orders autoload smoke test.

## Dialogue Content

- Gameplay dialogue source lives in `data/dialogue/`.
- The first integrated flow is `data/dialogue/day_hub_intro.dialogue`.
- Return Summary event dialogue now also lives in `data/dialogue/return_summary_events.dialogue`.
- Restaurant special-customer event dialogue lives in `data/dialogue/restaurant_special_customer.dialogue`.
- The runtime hook for these dialogue uses lives in `scripts/meta/day_hub_intro_dialogue_layer.gd`, mounted from `scenes/meta/MetaLoopRoot.tscn`.
- Dialogue one-shot guards persist in the profile save as `dialogue_state.seen_dialogue_ids`.

## Quest Content

- Daily order definitions live in `data/quests/daily_orders/` as QuestSystem `Quest` resources.
- The runtime bridge that keeps those quests in sync with the existing hybrid loop lives in `scripts/meta/daily_orders.gd`.
- The Day Hub entry point is `scenes/meta/DailyOrdersBoard.tscn`, mounted inside `scenes/meta/DayHub.tscn`.
- Quest persistence stays in the existing profile save under `daily_orders_state`; rewards still route through the existing meta economy and inventory save.
- Daily Orders rewards can safely grant gold, reputation, material bundles, and seed unlocks through the shared progression model.
- Daily Orders refresh at the start of each new in-game day. Completed but unclaimed orders are auto-claimed during rollover, while unfinished orders expire with the old board.

## Evaluated But Not Integrated

- `LimboAI`
  - Not integrated. It is useful if the project is about to adopt behavior trees/HSMs, but it would introduce a larger AI/editor surface area than this task needs and does not map cleanly onto the existing meta-loop work already in place.
- `GLoot`
  - Not integrated. It overlaps directly with the current inventory and persistence model, so adding it now would create avoidable pressure to refactor inventory, reward serialization, and save compatibility.
