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

No editor plugins were auto-enabled in `project.godot`.

That is intentional: both Dialogue Manager and QuestSystem add autoload singletons when enabled, and this project already has a custom save model, shared inventory, and meta loop. Leaving them disabled keeps runtime behavior unchanged until you explicitly opt in.

When you are ready to use either addon in-editor:

1. Open the project in Godot.
2. Enable `Dialogue Manager` and/or `QuestSystem` in the Plugins section of Project Settings.
3. If you enable `QuestSystem`, consider turning off its startup update check in Project Settings if you want fully offline editor opens.

Expected side effect after enabling:

- Dialogue Manager adds the `DialogueManager` autoload.
- QuestSystem adds the `QuestSystem` autoload.

Keep those runtime-facing changes in a separate commit from the vendoring/update commit if you want a cleaner rollout.

## Validation

Use `./scripts/ci/validate_plugins.sh` to verify:

- pinned plugin files exist where expected
- the project still imports headlessly
- the existing headless test suite still passes

## Evaluated But Not Integrated

- `LimboAI`
  - Not integrated. It is useful if the project is about to adopt behavior trees/HSMs, but it would introduce a larger AI/editor surface area than this task needs and does not map cleanly onto the existing meta-loop work already in place.
- `GLoot`
  - Not integrated. It overlaps directly with the current inventory and persistence model, so adding it now would create avoidable pressure to refactor inventory, reward serialization, and save compatibility.
