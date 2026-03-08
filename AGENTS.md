# AGENTS

## Project Goal

This is a Godot hybrid loop game: daytime planning and progression through farm + restaurant management, then nighttime combat runs that feed materials and rewards back into the daytime economy.

## Main Entry Points

- `project.godot`: autoloads, enabled plugins, core project settings
- `scenes/meta/MetaLoopRoot.tscn`: main game scene
- `scripts/meta/meta_loop_controller.gd`: primary day/night loop controller
- `scenes/meta/DayHub.tscn`: daytime routing hub
- `scripts/core/profile_store.gd`: canonical profile/save persistence
- `scripts/meta/daily_orders.gd`: QuestSystem bridge for daily orders
- `data/dialogue/`: Dialogue Manager content
- `data/quests/daily_orders/`: QuestSystem daily order resources

## Commands

- Open project: `godot --editor --path .`
- Headless import: `godot --headless --path . --import`
- Plugin-focused tests: `./scripts/ci/run_plugin_focused_tests.sh`
- Headless tests: `./scripts/ci/run_headless_tests.sh`
- Plugin sync: `./scripts/plugins/sync_plugins.sh`
- Plugin validation: `./scripts/ci/validate_plugins.sh`

## Repo Rules

- Do not touch unrelated unstaged changes.
- Do not replace or refactor the current inventory/save architecture to fit a plugin framework.
- Prefer small additive changes over broad rewrites.
- Stage only task-related files.
- Keep plugin work reproducible and repo-tracked; prefer `gd-plug` flow unless vendoring is clearly safer.

## Workflow Notes

- Dialogue Manager and QuestSystem are already vendored in `addons/` and enabled from `project.godot`.
- Use QuestSystem narrowly for contained features; do not grow it into a broad story framework without explicit direction.
- Route new progression rewards through the existing shared economy/inventory systems, not parallel plugin-owned state.
