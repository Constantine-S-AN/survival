# Survive: Neon Sonar

A fast, readability-first roguelite built in Godot 4.x.

You survive in a fog-heavy battlefield where information is temporary and costly: sonar reveals threats, but every aggressive action raises Noise, and Noise escalates danger.

## Project Snapshot
- Engine: Godot 4.6.x
- Genre: Top-down action roguelite
- Core loop: Menu -> Run Setup -> Combat -> Upgrade Draft -> Death Summary -> Retry
- Focus: production-grade UI/UX polish, deterministic data-driven tuning, stable headless testing + CI

## Core Gameplay Pillars
- Fog + sonar information economy:
  Vision is constrained by design. Sonar reveals space and targets, but only for limited windows.
- Noise-risk combat pacing:
  Attack, dash, and active skill usage increase Noise; higher tiers intensify spawn pressure.
- Build direction from constrained choices:
  Three-card upgrade drafts, tag synergies, rarity rules, prerequisites, and exclusivity branches.
- Run-level risk/reward contracts:
  Pre-run contract picks modify XP, rarity, drop, and meta-currency multipliers.

## Showcase Features (Current)
- Unified neon UI system:
  Main Menu, Run Setup Wizard, in-run HUD, upgrade draft, summary/progress screens.
- Scene transition + motion baseline:
  Global transition controller, reusable micro-motion utilities, reduced-motion-ready architecture.
- Runtime contract modifier closure:
  Preview multipliers in setup and actual runtime effect on roll/drop/meta summary output.
- Stable automated verification:
  Headless test runner watchdog/exit discipline and CI workflow for import + tests.

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
- UI style guide: `docs/UI_STYLE_GUIDE.md`
- Design notes: `docs/DESIGN_NOTES.md`
- Trailer / capture references: `media/TRAILER_CAPTURE.md`, `media/SHOTLIST.md`

## License & Credits
- License: `LICENSE`
- Third-party/asset credits: `CREDITS.md`
