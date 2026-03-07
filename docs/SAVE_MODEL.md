# Save Model

The profile file uses `PROFILE_SCHEMA_VERSION = 6` in [profile_store.gd](/Users/shijiean/Desktop/project/survive/scripts/core/profile_store.gd). The day-night hybrid slice lives inside `profile.meta_progress`, which currently uses `schema_version = 5`.

`ProfileStore.get_meta_progress_state()` is the canonical read path for the hybrid loop. `ProfileStore.set_meta_progress_state()` is the canonical write path. Both normalize the payload before it becomes live state.

## Ownership

| Save path | Runtime owner | Notes |
| --- | --- | --- |
| `meta_progress.day_state.current_day` | `MetaLoopController` / `DayState` | Increments only when the player continues past the return summary. |
| `meta_progress.day_state.current_phase` | `MetaLoopController` / `DayState` | Moves through morning, noon, afternoon, evening, night. |
| `meta_progress.day_state.stamina` | `MetaLoopController` / `DayState` | Spent by daytime farm actions; restored or reduced by next-day penalties. |
| `meta_progress.day_state.action_budget` | `MetaLoopController` / `DayState` | Shared daytime time budget. |
| `meta_progress.day_state.pending_*` | `RewardPipeline` via `MetaLoopController` | Carries night bonuses and next-day stamina penalties across the combat boundary. |
| `meta_progress.economy.gold` | `MetaLoopController` / `EconomyState` | Mutated by shop, service, and combat rewards. |
| `meta_progress.economy.restaurant_reputation` | `MetaLoopController` / `EconomyState` | Mutated by restaurant service results. |
| `meta_progress.economy.sold_dishes_stats` | `MetaLoopController` / `EconomyState` | Running dish sales totals. |
| `meta_progress.inventory.materials` | `MetaLoopController` / `InventoryState` | Includes produce, combat materials, and shop sell inventory. |
| `meta_progress.inventory.unlocked_seeds` | `MetaLoopController` / `InventoryState` | Starter seeds plus shop and combat-driven unlocks. |
| `meta_progress.inventory.unlocked_recipes` | `MetaLoopController` / `InventoryState` | Starter recipes plus restaurant/combat unlocks. |
| `meta_progress.farm_state` | `MetaLoopController` | Stores plot tilled state and crop payload per plot. |
| `meta_progress.restaurant_state.selected_menu_recipe_ids` | `MetaLoopController` | The current planned menu. This is intentionally persisted. |
| `meta_progress.restaurant_state.last_service_day` | `MetaLoopController` | Used to lock repeat service on the same day. |
| `meta_progress.restaurant_state.last_service_summary` | `MetaLoopController` | Used to preserve the latest result summary across scene changes and reloads. |
| `meta_progress.restaurant_state.owned_upgrade_ids` | `MetaLoopController` | Purchased restaurant upgrades. |
| `meta_progress.pending_return_summary` | `MetaLoopController` | Post-combat summary payload shown before the player advances to the next day. |

## Normalization Rules

`ProfileStore._normalize_meta_progress()` is responsible for clamping and filtering hybrid-loop data before it reaches gameplay.

- `day_state.current_phase` is normalized through `DayClock`.
- `stamina`, `max_stamina`, `action_budget`, and `max_action_budget` are clamped to sane ranges.
- `inventory.materials` entries are lowercased and clamped to non-negative integers.
- starter seeds and starter recipes are always restored even if the save is missing them.
- farm plots are resized to the configured grid and missing plots are filled with empty plot payloads.
- invalid farm crop payloads are dropped.
  - unknown crop ids are removed.
  - unknown seed ids are removed.
  - crop/seed mismatches are removed.
  - `growth_progress_days` is clamped to `growth_days`.
- restaurant menu ids are filtered to known recipes.
- owned restaurant upgrades are filtered to known upgrade ids.
- `last_service_summary` and `pending_return_summary` are preserved as dictionaries when present.

## Save Triggers

The day-night loop writes `meta_progress` from `MetaLoopController._save_meta_progress()`. The current save points are:

- waiting forward to evening from the day hub
- launching night combat
- finishing a night session, after rewards are resolved and the return summary payload is built
- continuing from the return summary into the next day
- any successful farm action
- restaurant menu toggle and menu clear
- successful restaurant service
- shop seed purchase
- shop material sale
- shop upgrade purchase

Pure scene transitions such as opening the farm, returning to the hub, or reopening the restaurant do not mutate the save by themselves.

## Combat Boundary

Night rewards are resolved before the return summary is shown. That means:

- inventory and economy rewards are already in shared state when `pending_return_summary` is populated
- save/load after combat but before pressing continue should restore the return summary screen and the already-earned inventory/economy changes
- day advancement, crop day rollover, and next-day stamina application happen only when the player continues from the return summary
