# DayWorld Stardew-Like Import Pass 1

Date: 2026-03-08

## Goal

Formally replace the current daytime presentation with a stronger Stardew-like direction using the downloaded legal substitute packs, while keeping the existing DayWorld, Shop, Restaurant, inventory, save/load, and meta-loop logic intact.

## Packs Used

- `Sunnyside World`
  - used for player/NPC sprites, landmark buildings, crops, props, rugs, tables, chairs, smoke, boats, and decorative clutter
- `Pixel Art Top Down - Basic`
  - used for DayWorld foliage, tree silhouettes, bushes, and some structural tile foundations
- `Harvest Farm - Free Pack`
  - used for farm soil/plot visuals, rock/stump pickup dressing, and floor/tile accents

## What Changed

### DayWorld

- Replaced the prior landmark composition with imported farm, restaurant, shop, and dock structures.
- Rebuilt the farm frontage with imported windmill, well, trough, animal, crate, barrel, flower, crop, and stump sprites.
- Rebuilt the restaurant frontage with imported building art, patio dressing, plated-food props, and chimney smoke.
- Rebuilt the shop frontage with imported building art, crates, chests, coins, anvil, jars, books, pennants, and entry dressing.
- Rebuilt the dock area with imported dock structure, coracle, barrel, campfire, cargo, and shoreline dressing.
- Replaced ambient town residents with imported animated Sunnyside characters.
- Replaced farm plot growth visuals and DayWorld pickups with imported crop/prop sprites.
- Replaced DayWorld terrain atlas generation with an imported mixed atlas from Cainos + Harvest + Sunnyside cells/sprites.

### Shop

- Replaced the in-shop player and ambient NPC presentation with imported Sunnyside characters.
- Replaced the procedural shop floor atlas with an imported mixed atlas.
- Rebuilt the visible shop dressing around seed shelves, counter, request corner, upgrade corner, waiting nook, and display table using imported clutter and furniture.

### Restaurant

- Replaced the in-restaurant player, patrons, and floor runner with imported Sunnyside characters.
- Replaced the restaurant floor atlas with an imported mixed atlas.
- Rebuilt menu, prep, service, summary, and table dressing using imported rugs, tables, chairs, jars, mugs, plates, flowers, barrels, and smoke.

## Why This Pass Matters

- The world now reads as one coherent borrowed style direction instead of procedural placeholders plus mixed free-pack fragments.
- The first view of the town is much closer to a cozy farm-town RPG composition.
- Shop and restaurant interiors are now visually aligned with the exterior direction instead of reverting to the previous interior pack look.
- Repeated interactions such as planting, watering, harvesting, shopping, and dining happen against imported authored art rather than abstract geometry blocks.

## Source / License Notes

Relevant source/license summary:

- `Sunnyside World`: free/commercial use allowed, modification allowed, no resale/repack of the asset pack, no AI training.
- `Pixel Art Top Down - Basic`: free/commercial use allowed, modification allowed, no redistribution/resale.
- `Harvest Farm - Free Pack`: commercial/non-commercial use allowed, modification allowed, no resale of the pack itself.

Only the specific source files required by the current scenes/scripts should be committed with this pass, not the full downloaded candidate archives.

## Deferred

- No direct Stardew Valley asset reuse.
- No broad HUD/theme redesign in this pass.
- No new NPC schedule system or new gameplay rules.
- No attempt to fully replace every fallback polygon helper if it is now visually minor.
