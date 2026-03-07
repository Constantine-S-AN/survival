# Meta-Loop Scaffold

## What Changed
- The game now boots into [`scenes/meta/MetaLoopRoot.tscn`](../scenes/meta/MetaLoopRoot.tscn) instead of directly into combat.
- A new [`scripts/meta/meta_loop_controller.gd`](../scripts/meta/meta_loop_controller.gd) owns top-level routing between:
  - Main Menu
  - Day Hub
  - Farm
  - Restaurant
  - Night Combat
  - Return Summary
- Existing combat is reused through [`scenes/meta/NightCombatRoot.tscn`](../scenes/meta/NightCombatRoot.tscn), which embeds the current [`scenes/game/GameRoot.tscn`](../scenes/game/GameRoot.tscn) as a night session.

## Persistent State
Meta progression now persists through `ProfileStore` under `profile["meta_progress"]`.

Stored fields:
- `day_state.current_day`
- `day_state.current_phase`
- `day_state.stamina`
- `day_state.max_stamina`
- `day_state.pending_night_gold_bonus`
- `day_state.pending_night_material_bonus`
- `economy.gold`
- `inventory.materials`
- `inventory.unlocked_seeds`
- `inventory.unlocked_recipes`
- `pending_return_summary`

Schema notes:
- `PROFILE_SCHEMA_VERSION` is now `3`
- Legacy profiles are migrated forward automatically

## Current Vertical Slice

### Day Hub
- Shows day, gold, stamina, phase, unlocked seeds, unlocked recipes, and inventory summary.
- Routes to Farm, Restaurant, or Night Combat.

### Farm
- Uses stamina to generate materials.
- Starts with `wheat_seed` unlocked.
- `herb_seed` unlocks after the first successful night.

### Restaurant
- Converts materials into pending night bonuses.
- Starts with `field_stew` unlocked.
- `sweet_bread` unlocks later through the loop economy.

### Night Combat
- Launches the existing combat runtime in embedded mode.
- Returns a run summary back to the meta loop instead of remaining the only root flow.

### Return Summary
- Applies gold/material rewards.
- Shows unlocks and updated inventory.
- Advances to the next day and restores stamina.

## Test Coverage
Headless coverage now includes:
- menu -> day hub
- farm screen
- restaurant screen
- night launch
- return summary
- next day progression
- persistence across reload

Primary test location:
- [`tests/test_runner.gd`](../tests/test_runner.gd)
