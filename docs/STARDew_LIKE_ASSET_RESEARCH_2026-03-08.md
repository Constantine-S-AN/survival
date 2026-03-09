# Stardew-Like Asset Research

Date: 2026-03-08

## Summary

Direct reuse of Stardew Valley game art is not a safe default for this project.
I did not find an official reusable game-asset license on the official Stardew Valley domains during this pass, so I treated extracted/ripped Stardew assets as off-limits and searched for legally usable near-style alternatives instead.

## Downloaded Local Candidates

### 1. Sunnyside World

- Source: https://danieldiggle.itch.io/sunnyside
- Local zip: `assets/external/stardew_like_candidates/raw/Sunnyside-World-ASSET-PACK-V2-1.zip`
- Local unpacked root: `assets/external/stardew_like_candidates/unpacked/Sunnyside-World-ASSET-PACK-V2-1/`
- Why it is strong:
  - closest overall to a cozy farm-life action RPG set
  - includes tilesets, crops, buildings, interiors, characters, animals, UI parts
  - broadest package if we want one pack to drive a full pass
- License notes from source page:
  - usable in free and commercial projects
  - modification allowed
  - credit appreciated, not required
  - tutorial/education redistribution allowed with a link back
  - no repack/resale
  - no AI training

### 2. Pixel Art Top Down - Basic

- Source: https://cainos.itch.io/pixel-art-top-down-basic
- Local zip: `assets/external/stardew_like_candidates/raw/Pixel-Art-Top-Down---Basic-v1-2-3.zip`
- Local unpacked root: `assets/external/stardew_like_candidates/unpacked/Pixel-Art-Top-Down---Basic-v1-2-3/`
- Why it is strong:
  - clean terrain/wall/prop foundations
  - easiest pack to blend into a hand-authored top-down town
  - good if we want sturdier pathing/ground readability without importing a full new style bible
- License notes from source page:
  - usable in free and commercial projects
  - modification allowed
  - credit not required
  - no redistribution or resale

### 3. Harvest Farm - Free Pack

- Source: https://cubedeveloper.itch.io/harvest-farm-topdown-pixelart-asset-pack
- Local zip: `assets/external/stardew_like_candidates/raw/Harvest-Farm---Free-pack.zip`
- Local unpacked root: `assets/external/stardew_like_candidates/unpacked/Harvest-Farm---Free-pack/`
- Why it is useful:
  - small, lightweight, easy to mine for farm props/tiles/crop staging
  - fastest option if we only want to improve a farm corner instead of reshaping the whole look
- License notes from bundled readme:
  - usable in commercial and non-commercial projects
  - modification allowed
  - derivative style expansion allowed
  - no resale of the asset pack itself
  - shipped projects may distribute with credit

## Visual Read

- Closest all-in-one Stardew-like direction: `Sunnyside World`
- Best structural base for terrain + village readability: `Cainos Basic`
- Best small additive farm booster: `Harvest Farm`

## Recommended Import Strategy

If the goal is “closer to Stardew” without copying Stardew directly:

1. Use `Sunnyside World` selectively for crops, fences, farm clutter, cozy props, and some UI motifs.
2. Use `Cainos Basic` for terrain readability, walls, ruins, and clean top-down structural pieces.
3. Use `Harvest Farm` only as a small additive source for farm-specific props if needed.

## Preview

- Local preview sheet: `docs/progress/stardew_like_asset_candidates_2026-03-08.png`

## Deferred

- I did not import these into active scenes yet.
- I did not commit the downloaded candidate assets in this pass.
- If we want, the next step is to curate one direction and do a controlled replacement pass in `DayWorld`, `Farm`, `Shop`, and `DayHud` with explicit license notes.
