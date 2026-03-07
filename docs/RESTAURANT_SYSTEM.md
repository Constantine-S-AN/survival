# Restaurant System

The first restaurant slice lives in `scenes/day/restaurant/Restaurant.tscn` and is driven by `scripts/day/restaurant/restaurant_controller.gd`, `scripts/day/restaurant/menu_planner.gd`, and `scripts/day/restaurant/service_simulator.gd`.

## Loop

1. The player enters Restaurant from the Day Hub.
2. They review shared inventory ingredients from farm and night combat.
3. They select up to three unlocked recipes for today's menu.
4. Opening service runs a deterministic simulation based on:
   - selected menu composition,
   - available ingredient stock,
   - recipe price and prep complexity,
   - current restaurant reputation,
   - owned restaurant upgrades,
   - optional night-material synergies.
5. The result updates shared meta state:
   - gold,
   - restaurant reputation,
   - sold dish lifetime stats,
   - last service summary for later review.

## Data

- `data/recipes.json`
  - data-first recipe definitions, ingredient requirements, pricing, complexity, tags, and optional night-material synergy
- `data/restaurant_upgrades.json`
  - future-facing restaurant upgrades already validated and loaded through `DataRegistry`

## Persistence

Restaurant state is stored inside `ProfileStore.meta_progress.restaurant_state`:

- `selected_menu_recipe_ids`
- `last_service_day`
- `last_service_summary`
- `owned_upgrade_ids`

Economy state also persists restaurant-specific progression:

- `restaurant_reputation`
- `sold_dishes_stats`

This keeps the restaurant loop aligned with the existing autoload/profile save pattern instead of introducing a second save system.
