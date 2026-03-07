# Survive: Neon Sonar

A hybrid day-night roguelite built in Godot 4.x.

By day, you plan a small farm, menu, and shop economy. By night, you run a fog-heavy combat dive where information is temporary and costly: sonar reveals threats, but every aggressive action raises Noise, and Noise escalates danger.

## Project Snapshot
- Engine: Godot 4.6.x
- Genre: Hybrid action roguelite + management planner
- Core loop: Day Hub -> Farm / Restaurant / Shop -> Night Combat -> Return Summary -> Next Day
- Focus: readable systems, data-driven tuning, stable persistence, and headless regression coverage

## Core Gameplay Pillars
- Hybrid opportunity-cost planning:
  Farm work, restaurant service, shopping, and resting all consume shared daytime budget.
- Daytime economy with meaningful tradeoffs:
  Crops can be sold safely, cooked for better margins, or saved for unlock paths and premium dishes.
- Fog + sonar information economy:
  Vision is constrained by design. Sonar reveals space and targets, but only for limited windows.
- Noise-risk combat pacing:
  Attack, dash, and active skill usage increase Noise; higher tiers intensify spawn pressure.
- Night-only progression materials:
  Combat runs feed rare ingredients, crop unlocks, recipe unlocks, and premium daytime menu paths.
- Build direction from constrained choices:
  Combat still uses three-card upgrade drafts, tag synergies, rarity rules, prerequisites, and exclusivity branches.

## Showcase Features (Current)
- Unified neon day-night UI:
  Main Menu, Day Hub, Farm, Restaurant, Shop, return summary, run setup, combat HUD, and upgrade draft.
- Shared persistence across the hybrid loop:
  Day, phase, stamina, action budget, inventory, farm plots, menu state, upgrades, and combat return payload all save/load through the same profile model.
- Expanded starter content:
  5 crops, 8 recipes, 5 night-only materials, and multiple shop upgrades/unlock paths in the opening slice.
- Lightweight onboarding:
  First-three-day guidance, loop callouts, and clearer action/tooltips for new players.
- Stable automated verification:
  Headless tests cover crop progression, menu ingredient consumption, combat reward transfer, save/load restoration, and shop/upgrade flows.

## Current Vertical Slice
- Daytime actions are segmented into Morning, Noon, Afternoon, Evening, and Night.
- Farm work sets up future harvests rather than same-day profit.
- Restaurant service is the best daytime gold when ingredients are planned well.
- Night combat supplies scarce materials and unlock progress that the daytime economy cannot replace.
- The first three in-game days are tuned around meaningful choices instead of a single dominant route.

## Quick Start
### Run Latest in One Command
```bash
./play_latest.sh
```

What it does:
1. Switches to `main` (default)
2. Fetches + fast-forward pulls latest from `origin/main`
3. Launches game with `godot --path .`

Optional flags:
```bash
./play_latest.sh --no-update
./play_latest.sh --allow-dirty
./play_latest.sh --branch main
./play_latest.sh --godot /Applications/Godot.app/Contents/MacOS/Godot
```

### Run Normally
```bash
godot --path .
```

### Run Headless Tests
```bash
godot --headless --path . res://tests/TestRunner.tscn --quit-after 3600
```

### Unified Local/CI Test Entry
```bash
./scripts/ci/run_headless_tests.sh
```

## Controls (Default)
- Move: `WASD` / Arrow keys
- Dash: `Space` / `Shift`
- Sonar active skill: `Q` / `E`
- Attack mode toggle: `Tab`
- Debug panel: `F1`
- Fog toggle: `F2`
- Sonar visual toggle: `F3`
- Data hot reload: `F5`

## Data-Driven Tuning
All major runtime behavior is JSON-driven under `/data`:
- Day-night crop / recipe loop: `data/seeds.json`, `data/crops.json`, `data/recipes.json`, `data/shop_inventory.json`, `data/special_ingredients.json`, `data/restaurant_upgrades.json`, `data/unlocks.json`, `data/night_loot_tables.json`
- Characters: `data/characters.json`
- Weapons: `data/weapons.json`
- Upgrades: `data/upgrades.json`
- Enemies / elites / bosses: `data/enemies.json`, `data/elites.json`, `data/bosses.json`
- Maps / hazards / events: `data/maps.json`, `data/hazards.json`, `data/events.json`
- Contracts: `data/contracts.json`
- Fog / sonar / noise: `data/fog.json`, `data/sonar.json`, `data/noise.json`

## Repository Structure
- `scenes/`: gameplay and UI scene graph
- `scripts/`: gameplay systems, UI controllers, CI/test helpers
- `ui/`: reusable themed UI components and global theme assets
- `tests/`: deterministic and regression runners
- `docs/`: design and style guides
- `assets/`: textures, fonts, icons, shaders, audio
- `.github/workflows/`: CI automation

## CI
Workflow: `.github/workflows/ci.yml`
- Step 1: headless import warm-up
- Step 2: run headless tests via unified script
- Step 3 (optional by config): export verification

## Export (Example)
```bash
godot --headless --path . --export-release "macOS" exports/macos/Survive-Neon-Sonar.app
godot --headless --path . --export-release "Windows Desktop" exports/NeonSonar.exe
```

## Documentation
- Day loop: `docs/DAY_LOOP.md`
- Farm system: `docs/FARM_SYSTEM.md`
- Restaurant system: `docs/RESTAURANT_SYSTEM.md`
- Save model: `docs/SAVE_MODEL.md`
- UI style guide: `docs/UI_STYLE_GUIDE.md`
- Design notes: `docs/DESIGN_NOTES.md`
- Trailer / capture references: `media/TRAILER_CAPTURE.md`, `media/SHOTLIST.md`

## License & Credits
- License: `LICENSE`
- Third-party/asset credits: `CREDITS.md`
