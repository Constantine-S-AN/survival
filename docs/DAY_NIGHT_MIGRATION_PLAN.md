# Day/Night Migration Plan

## Goal
Convert the current combat-first roguelite into a day/night hybrid loop:

`Main Menu -> Save/Profile -> Day Hub -> Farm/Restaurant actions -> Night Launch -> Combat -> Return Summary -> Next Day`

Constraints for this plan:
- Preserve the current combat feel, combat UI, and neon presentation wherever possible.
- Avoid a giant rewrite.
- Prefer wrappers, adapters, and new orchestration code over moving stable combat systems early.

## Current Repo Audit

### Current boot and runtime structure
- The game boots directly into [`scenes/game/GameRoot.tscn`](../scenes/game/GameRoot.tscn).
- `GameRoot` owns the full top-level state machine: menu, setup, combat, level up, pause, and game over.
- `GameRoot` mounts two children only: `World` and `UI`.
- [`scripts/game/world.gd`](../scripts/game/world.gd) already contains a strong combat-runtime boundary:
  - player and combat managers
  - map runtime and hazards/events
  - combat VFX/SFX and camera feedback
  - reward multiplier plumbing
- [`scripts/ui/ui_layer.gd`](../scripts/ui/ui_layer.gd) acts as an overlay host for:
  - main menu
  - run setup
  - HUD
  - upgrade draft
  - pause
  - run summary

### Current scene structure
- Combat core:
  - `scenes/world/World.tscn`
  - `scenes/player/Player.tscn`
  - `scenes/enemy/Enemy.tscn`
  - `scenes/enemy/BossEchoDecoy.tscn`
  - `scenes/projectile/Projectile.tscn`
  - `scenes/pickup/XPPickup.tscn`
- UI shell:
  - `scenes/ui/menu/MainMenu.tscn`
  - `scenes/ui/run_setup/RunSetup.tscn`
  - `scenes/ui/summary/RunSummary.tscn`
  - `scenes/ui/pause/PauseMenu.tscn`
  - `scenes/ui/hud/HUD.tscn`
- Legacy/secondary selection scenes still exist, but the current flow is actually routed through `RunSetup`:
  - `scenes/ui/CharacterSelect.tscn`
  - `scenes/ui/MapSelect.tscn`
  - `scenes/ui/ContractSelect.tscn`

### Current script/data ownership
- `GameRoot` currently owns too much:
  - top-level scene routing
  - pre-run selection state
  - run seed and runtime summary assembly
  - reward/meta-currency calculation
  - death-to-summary flow
- `World` and related combat scripts are already modular enough to become a reusable NightCombat package.
- [`scripts/core/data_registry.gd`](../scripts/core/data_registry.gd) is a combat-content registry, not a general game-content registry yet.
- [`scripts/core/profile_store.gd`](../scripts/core/profile_store.gd) persists one global file only:
  - language
  - unlocked characters
  - aggregate progress
  - meta currency total
  - last selected character/map/contracts
- There is no save slot system and no serialized day-side campaign state.

### Current data layout
All current JSON is night/combat oriented:
- `characters.json`
- `weapons.json`
- `upgrades.json`
- `enemies.json`
- `elites.json`
- `bosses.json`
- `spawn_curve.json`
- `maps.json`
- `hazards.json`
- `events.json`
- `contracts.json`
- `fog.json`
- `sonar.json`
- `noise.json`

There is no current JSON namespace for:
- day actions
- crops/farm state
- restaurant recipes/orders
- save slot summaries
- hub progression

### Current gameplay loop
Current live loop:

`Main Menu -> Run Setup -> Combat -> Level Up -> Run Summary -> Retry/Menu`

Target loop requires adding three missing layers:
- save/profile selection
- persistent day-side hub state
- a clean handoff between persistent day state and disposable night session state

## Recommended Ownership Split

### Reusable NightCombat module
These should become the reusable night-session package with minimal behavioral change:

| Current asset | Future role | Notes |
| --- | --- | --- |
| `scenes/world/World.tscn` + `scripts/game/world.gd` | Night combat world root | Keep intact early; wrap instead of rewrite |
| `scenes/player/Player.tscn` + `scripts/entities/player.gd` | Night combat player runtime | Remains session-owned |
| `scenes/enemy/*` + `scripts/entities/enemy.gd` | Night combat enemy runtime | No day ownership |
| `scenes/projectile/Projectile.tscn` + `scripts/entities/projectile.gd` | Night combat projectile runtime | No day ownership |
| `scenes/pickup/XPPickup.tscn` + `scripts/entities/xp_pickup.gd` | Night combat pickup runtime | No day ownership |
| `scripts/managers/enemy_manager.gd` | Night spawn/combat manager | Keep inside combat module |
| `scripts/managers/projectile_manager.gd` | Night projectile manager | Keep inside combat module |
| `scripts/managers/sonar_manager.gd` | Night sonar manager | Keep inside combat module |
| `scripts/managers/pool_manager.gd` | Night pooling runtime | Keep inside combat module |
| `scripts/weapons/weapon_runtime.gd` | Night weapon runtime | Session-owned |
| `scripts/core/map_runtime.gd` | Night biome/hazard/event runtime | Session-owned |
| `scripts/core/run_stats.gd` | Night run stats payload | Session-owned |
| `scenes/ui/hud/HUD.tscn` + `scripts/ui/hud/*` | Night HUD | Reuse style unchanged |
| `scenes/ui/upgrade/*` + `scripts/ui/upgrade/*` | Night level-up UI | Reuse style unchanged |
| `scenes/ui/summary/*` + `scripts/ui/summary/*` | Night return summary UI | Extend payload, keep visuals |
| `scenes/ui/pause/*` + `scripts/ui/pause/*` | Night pause UI | Reuse unchanged |
| `ui/*` + `scripts/ui/components/*` | Shared visual language | Shared across day and night |

### Meta-loop controller
These should become the campaign shell and routing layer:

| Current asset | Future role | Notes |
| --- | --- | --- |
| `scenes/game/GameRoot.tscn` + `scripts/game/game_root.gd` | Split into `MetaLoopController` plus `NightCombatSession` wrapper | Highest-priority split |
| `scenes/ui/menu/MainMenu.tscn` + `scripts/ui/menu/main_menu.gd` | Main menu shell | Reuse look, change button destinations |
| `scenes/ui/SceneTransition.tscn` + `scripts/ui/scene_transition.gd` | Shared transition service | Keep global |
| `scripts/core/profile_store.gd` | Global settings store or migration source | Do not let combat keep saving directly long-term |

### Day-side systems
Most day-side logic should be new. The only current asset that is a strong candidate for reuse is the run setup flow:

| Current asset | Future role | Notes |
| --- | --- | --- |
| `scenes/ui/run_setup/RunSetup.tscn` + `scripts/ui/run_setup/run_setup.gd` | `NightLaunch` scene/panel | Same card-based selection UX can survive |
| `scenes/ui/summary/RunSummary.tscn` + `scripts/ui/summary/run_summary.gd` | `ReturnSummary` panel | Add day-advance data, keep visuals |
| `scenes/ui/CharacterSelect.tscn` / `MapSelect.tscn` / `ContractSelect.tscn` | Optional reuse only | Currently bypassed; do not build plan around them |

## Target Folder Structure

### Final target structure
```text
docs/
  DAY_NIGHT_MIGRATION_PLAN.md

scenes/
  app/
    AppRoot.tscn
  meta/
    MainMenu.tscn
    SaveProfile.tscn
  day/
    DayHub.tscn
    FarmPanel.tscn
    RestaurantPanel.tscn
    NightLaunch.tscn
    ReturnSummary.tscn
  night/
    NightCombatRoot.tscn
    world/
      World.tscn
    player/
      Player.tscn
    enemy/
      Enemy.tscn
      BossEchoDecoy.tscn
    projectile/
      Projectile.tscn
    pickup/
      XPPickup.tscn
    ui/
      NightCombatUI.tscn
      hud/
      upgrade/
      summary/
      pause/

scripts/
  app/
    meta_loop_controller.gd
  save/
    save_store.gd
    campaign_state.gd
    day_state.gd
    night_run_request.gd
    night_run_result.gd
  meta/
    save_profile_view.gd
  day/
    day_hub_controller.gd
    farm_panel.gd
    restaurant_panel.gd
    night_launch_controller.gd
    return_summary_controller.gd
    day_action_service.gd
  night/
    night_combat_session.gd
    night_combat_root.gd
    world/
    ui/

data/
  day/
    day_actions.json
    crops.json
    restaurant_recipes.json
    restaurant_orders.json
    hub_layout.json
    night_modifiers.json
  meta/
    progression.json
  night/
    characters.json
    weapons.json
    upgrades.json
    enemies.json
    elites.json
    bosses.json
    spawn_curve.json
    maps.json
    hazards.json
    events.json
    contracts.json
    fog.json
    sonar.json
    noise.json
```

### Lowest-risk transition rule
Do not physically move the existing combat files in the first half of the migration.

Safer sequence:
1. Add new `app/`, `meta/`, and `day/` folders first.
2. Wrap the current combat stack as `night` without relocating files yet.
3. Move files only after the wrapper API is stable and tests cover the new loop.

## Target State Flow

### Recommended flow
1. `AppRoot` boots shared autoloads and shows `MainMenu`.
2. `MainMenu` routes to `SaveProfile`.
3. `SaveProfile` creates or loads a campaign slot.
4. `MetaLoopController` loads the active `CampaignState`.
5. `DayHub` shows:
   - current day
   - inventory/currency
   - farm state
   - restaurant state
   - pending night bonuses or penalties
6. Player spends day actions in `FarmPanel` and `RestaurantPanel`.
7. `NightLaunch` assembles a `NightRunRequest` from:
   - campaign state
   - chosen character/map/contracts
   - day-generated modifiers
   - optional seed override/debug data
8. `NightCombatSession` runs a disposable combat session.
9. Combat emits `NightRunResult`.
10. `ReturnSummary` displays run data plus day consequences.
11. `MetaLoopController` applies results to the campaign, advances the day, saves, and returns to `DayHub`.

### State contract recommendation
Use explicit request/result payloads instead of letting day and night read each other directly.

Recommended handoff objects:
- `NightRunRequest`
  - `save_slot_id`
  - `day_index`
  - `character_id`
  - `map_id`
  - `contract_ids`
  - `seed`
  - `persistent_modifiers`
  - `temporary_day_modifiers`
  - `inventory_snapshot`
- `NightRunResult`
  - `completed`
  - `defeat`
  - `survive_time_seconds`
  - `kills`
  - `run_stats`
  - `meta_currency_earned`
  - `inventory_rewards`
  - `character_unlocks`
  - `night_flags`
  - `summary_payload`

### Planning assumption
For the initial hybrid loop, assume:
- one night mission resolves one full day
- the day advances after every night mission, win or lose

That assumption keeps the state machine simple. If design later wants retries without day advance, the same request/result boundary still works.

## Data Ownership

### Campaign-owned persistent data
This should live in a per-save `CampaignState`:
- `save_slot_id`
- `schema_version`
- `profile_name`
- `current_day`
- `soft_currency`
- `meta_currency`
- `inventory`
- `farm`
- `restaurant`
- `permanent_unlocks`
- `permanent_upgrades`
- `last_night_loadout`
- `night_history`
- `hub_flags`

### Day-owned short-lived data
This should be nested under the active campaign save, but reset or roll forward each day:
- `remaining_actions`
- `selected_day_actions`
- `pending_night_modifiers`
- `queued_recipe_outputs`
- `harvest_ready_flags`
- `launch_ready`

### Night-owned disposable data
This should stay inside the combat session only:
- runtime player stats
- XP and level state
- upgrade stacks
- current HP/noise
- map runtime snapshot
- live enemies/projectiles/pickups
- run seed
- temporary drop counts

### Registry ownership
- Keep `DataRegistry` night-focused at first.
- Add a separate day-side loader or clearly namespaced methods for day content.
- Do not make combat code depend on day JSON directly.

## Save/Load Ownership

### Recommended ownership model
- `ProfileStore`
  - global settings only
  - language
  - accessibility/options
  - last selected save slot
- `SaveStore`
  - all campaign slot I/O
  - slot manifest
  - per-slot campaign JSON
  - migration from legacy single-profile data

### Recommended file layout
```text
user://profile.json
user://saves/manifest.json
user://saves/slot_001/campaign.json
user://saves/slot_002/campaign.json
```

### Migration recommendation
When save slots first land:
1. Keep `profile.json` for settings.
2. If no save slots exist but legacy progress exists, auto-create `slot_001`.
3. Import into that slot:
   - `unlocked_characters`
   - `meta_currency_total`
   - `run_count`
   - `last_selected_character_id`
   - `last_selected_map_id`
   - `last_selected_contract_ids`
4. Mark the slot as imported so migration does not repeat.

### Save trigger ownership
Only `MetaLoopController` should decide when to save.

Suggested save points:
- after slot create/load
- after each day action
- after launch configuration changes
- after night result is applied
- after day advance

Night combat should never write save files directly.

## Lowest-Risk Integration Points

1. Add a new `AppRoot` and leave the current combat stack callable as a child scene.
2. Treat current `GameRoot` as a temporary `NightCombatSession` adapter before splitting it fully.
3. Reuse `RunSetupView` for `NightLaunch` instead of building a new pre-night UI from scratch.
4. Reuse `RunSummaryView` for `ReturnSummary` and extend the payload instead of replacing the screen.
5. Keep `World` and combat managers untouched in early milestones.
6. Add `SaveStore` instead of overloading `ProfileStore` immediately.
7. Add new day JSON files without refactoring existing combat JSON paths at the same time.
8. Keep current headless combat tests as the regression safety net while day-side tests are added separately.

## Proposed New Scenes

| Scene | Purpose |
| --- | --- |
| `scenes/app/AppRoot.tscn` | New main scene and scene host |
| `scenes/meta/SaveProfile.tscn` | Save slot/profile creation and selection |
| `scenes/day/DayHub.tscn` | Primary daytime overview and routing scene |
| `scenes/day/FarmPanel.tscn` | Crop and harvest actions |
| `scenes/day/RestaurantPanel.tscn` | Cooking/service actions and temporary buffs |
| `scenes/day/NightLaunch.tscn` | Pre-night setup, adapted from current run setup |
| `scenes/day/ReturnSummary.tscn` | Post-night summary and next-day transition |
| `scenes/night/NightCombatRoot.tscn` | Reusable wrapper around current combat stack |

## Proposed New Scripts

| Script | Purpose |
| --- | --- |
| `scripts/app/meta_loop_controller.gd` | Owns top-level routing and state transitions |
| `scripts/save/save_store.gd` | Save slot manifest, campaign load/save, migration |
| `scripts/save/campaign_state.gd` | Canonical persistent campaign model |
| `scripts/save/day_state.gd` | Per-day mutable state model |
| `scripts/save/night_run_request.gd` | Typed handoff into combat |
| `scripts/save/night_run_result.gd` | Typed result payload from combat |
| `scripts/day/day_hub_controller.gd` | Hub state and routing |
| `scripts/day/day_action_service.gd` | Applies farm/restaurant effects to campaign state |
| `scripts/day/farm_panel.gd` | Farm UI controller |
| `scripts/day/restaurant_panel.gd` | Restaurant UI controller |
| `scripts/day/night_launch_controller.gd` | Adapts current run setup to day-owned launch flow |
| `scripts/day/return_summary_controller.gd` | Applies result summary and next-day progression |
| `scripts/night/night_combat_session.gd` | Wrapper API around the current combat session |

## Proposed New JSON Files

| JSON | Purpose |
| --- | --- |
| `data/day/day_actions.json` | AP costs, action categories, unlock rules, outputs |
| `data/day/crops.json` | Crop types, growth timing, harvest yields |
| `data/day/restaurant_recipes.json` | Ingredient costs, buffs, rewards |
| `data/day/restaurant_orders.json` | Day-specific orders or service demands |
| `data/day/hub_layout.json` | Hub sections, unlock order, labels, art hooks |
| `data/day/night_modifiers.json` | Maps day outcomes to night-side modifiers |
| `data/meta/progression.json` | Campaign economy, unlock pacing, permanent upgrades |

## Phased Milestones

### M1: App Shell Split
Deliver:
- Add `AppRoot` and `MetaLoopController`.
- Route `MainMenu -> Save/Profile placeholder -> current combat`.
- Keep current combat behavior unchanged once a night starts.

Acceptance criteria:
- The game no longer boots straight into combat-only `GameRoot`.
- A player can enter the current combat run from the new shell.
- Existing combat HUD, upgrade draft, pause, and summary still behave the same.
- Current headless combat tests still pass.

### M2: Save/Profile and Campaign Save Model
Deliver:
- Add `SaveStore`.
- Add save slot manifest and per-slot campaign JSON.
- Migrate legacy `profile.json` progress into the first slot.

Acceptance criteria:
- A player can create at least one save slot and load it.
- Reloading the game restores the selected slot and current day state.
- Legacy progress imports into a new campaign slot exactly once.
- Language/settings remain in `profile.json`.

### M3: Day Hub Skeleton
Deliver:
- Add `DayHub`, `FarmPanel`, `RestaurantPanel`, and `ReturnSummary` shell screens.
- Add `DayState` with action points and pending night modifiers.
- Implement the target top-level loop with placeholder day actions.

Acceptance criteria:
- Full loop works end to end:
  `Main Menu -> Save/Profile -> Day Hub -> Farm/Restaurant -> Night Launch -> Combat -> Return Summary -> Next Day`
- Day actions visibly change the pending night package.
- The active campaign autosaves after day actions and after day advance.

### M4: NightCombat Extraction
Deliver:
- Split `GameRoot` responsibilities into:
  - meta shell ownership
  - reusable `NightCombatSession` ownership
- Launch combat through an explicit `NightRunRequest`.
- Return a `NightRunResult` instead of letting combat mutate save state directly.

Acceptance criteria:
- Night combat can be started from the day hub and from a standalone debug/test harness.
- Combat no longer calls save I/O directly.
- Run summary data arrives through the result payload.
- Combat visuals and runtime feel are unchanged from the current build.

### M5: Data-Driven Day Systems
Deliver:
- Add day JSON files and load them through a day-side registry/service.
- Replace placeholder farm/restaurant actions with data-driven content.
- Persist inventory, farm growth, and restaurant outputs in campaign saves.

Acceptance criteria:
- Changing day JSON changes available actions or outputs without code edits.
- Farm and restaurant choices alter the next night through `night_modifiers.json`.
- Save/load preserves day-side inventory and progression correctly across restarts.

### M6: Regression Coverage and Polish
Deliver:
- Add end-to-end tests for save selection, day actions, night launch, and next-day advance.
- Clean up remaining adapter code.
- Decide which progression remains global versus per-save.

Acceptance criteria:
- A three-day campaign can be played across multiple launches without state loss.
- End-to-end smoke coverage exists for the full hybrid loop.
- Old combat-only entry points are either removed or clearly marked debug-only.
- The project can be extended with more day content without touching combat runtime code.

## Recommended First Implementation Order
If implementation starts tomorrow, the safest sequence is:

1. Add `AppRoot` and `MetaLoopController`.
2. Add `SaveStore` and slot JSON.
3. Add `DayHub` with placeholder farm/restaurant actions.
4. Wrap the current combat stack behind `NightCombatSession`.
5. Reuse `RunSetup` as `NightLaunch`.
6. Reuse `RunSummary` as `ReturnSummary`.
7. Only then begin moving files into `night/` namespaces if still worth the churn.

## Risks To Watch
- `GameRoot` currently mixes shell logic with run logic, so splitting too much at once risks combat regressions.
- `ProfileStore` currently mixes settings and progression; extending it directly into multi-slot campaign storage will get messy fast.
- The repo already contains dirty changes in several core combat files; avoid basing the migration on large edits there until ownership is cleaner.
- `CharacterSelect`, `MapSelect`, and `ContractSelect` scenes are not the current live path, so investing in them first is likely wasted work.

## Recommendation
Do not rewrite combat first.

Build a new meta shell around the existing combat runtime, formalize the request/result boundary, move save ownership out of combat, then add day systems on top. That gets the hybrid loop online with the least risk and preserves the strongest part of the current repo: the combat stack and its UI polish.
