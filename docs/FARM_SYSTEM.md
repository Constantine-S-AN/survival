# Farm System

This project now has a first playable day-side farm slice wired into the meta loop.

## Scope

- Scene: `res://scenes/day/farm/Farm.tscn`
- Controller: `res://scripts/day/farm/farm_controller.gd`
- Plot view: `res://scripts/day/farm/farm_plot.gd`
- Data: `res://data/seeds.json`, `res://data/crops.json`
- Save owner: `ProfileStore.meta_progress.farm_state`

## Current Crop Catalog

The current starter slice ships with five crops:

- `wheat`
- `herb`
- `kelpberry`
- `emberleaf`
- `mooncap`

`wheat` and `herb` are the starter staples. `kelpberry` and `emberleaf` come from the day shop and create meaningful early economy choices because they can be sold safely or routed into dedicated restaurant dishes. `mooncap` is the combat-driven premium crop path.

## Runtime Flow

1. Enter the farm from the Day Hub.
2. Select a tool:
   - `Till`
   - `Water`
   - `Harvest`
   - `Plant <seed>`
3. Click a plot to apply the selected action.
4. Launch night combat to end the day.
5. On `Start Next Day`, watered crops advance one growth day.
6. Harvested crops enter the shared day inventory and become available to restaurant systems.

## Data Model

`data/seeds.json`

- `id`
- `name`
- `description`
- `crop_id`
- `plant_stamina_cost`
- `starts_unlocked`

`data/crops.json`

- `id`
- `seed_id`
- `name`
- `growth_days`
- `harvest_yield`
- `sell_value`
- `ingredient_tags`

More crops can be added by extending those JSON arrays. The runtime uses `DataRegistry` lookups instead of hardcoded crop tables.

## Save Shape

Farm state is stored under `meta_progress.farm_state`:

```json
{
  "columns": 3,
  "rows": 2,
  "plots": [
    {
      "tilled": true,
      "crop": {
        "seed_id": "wheat_seed",
        "crop_id": "wheat",
        "planted_day": 1,
        "growth_days": 2,
        "growth_progress_days": 1,
        "watered_day": 2
      }
    }
  ]
}
```

This keeps plot persistence independent from the farm UI and lets the meta loop own save/load.

## Current Rules

- Till costs `1` stamina.
- Plant cost comes from `seeds.json`.
- Water costs `1` stamina.
- Harvest costs `1` action and no stamina.
- A crop advances only if it was watered on the previous day.
- Harvest resets the plot to empty.

## Balance Role

Farm output is intentionally useful but not dominant.

- raw crop sales are a safe fallback when the player needs gold fast
- the better payoff usually comes from feeding crops into restaurant service
- shop-only crops exist to widen planning, not to replace the core night-combat progression path
- the farm is strongest when the player spends early actions setting up later days rather than trying to brute-force same-day profit

## Test Coverage

`tests/test_runner.gd` covers:

- planting 2 crop types,
- day-to-day growth,
- harvest entering shared inventory,
- farm state surviving return to hub,
- farm state surviving save/load reload,
- continued routing through night combat and return summary.
