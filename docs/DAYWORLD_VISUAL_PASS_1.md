# DayWorld Visual Pass 1

## Intent

Push the daytime overworld toward a readable top-down pixel life-sim town without changing routing, economy, save/load, dialogue, daily orders, or reward flow.

This pass stays additive and rollback-friendly:

- keep the current DayWorld shell and interaction zones
- reuse the existing in-repo Tiny Swords art direction where it helps
- prefer layout, composition, lighting, and HUD cleanup over new systems

## Audit

The current DayWorld already works mechanically, but the presentation still reads like a shell:

- large ground areas are blocked in with simple rectangles, so the farm, town center, and dock do not separate cleanly at a glance
- several landmarks rely on sparse props and primitive shapes, which weakens location identity
- some foliage props are sourced from sprite sheets but rendered like full textures, which likely creates noisy strip-like scenery instead of single prop silhouettes
- the dock communicates function, but not enough anticipation or “departure point” energy
- the HUD inherits a neon/admin-shell tone that clashes with the daytime life-sim space

## Visual Direction

One coherent direction:

- use the existing Tiny Swords top-down building/foliage set as the main visual language
- support it with simple built-in Godot shapes for fences, crates, planters, lamps, awnings, signs, and glows
- avoid mixing in unrelated packs unless the current repo clearly lacks a needed category

Target read:

- farm: fenced, practical, green, and work-focused
- restaurant: warm frontage, service-ready, inviting
- shop: compact market stall, stocked and easy to spot
- dock: stronger shoreline framing, cargo clutter, beacon, and clear readiness state

## Implementation Focus

1. Recompose the ground so main routes and sub-areas are legible before reading prompts.
2. Replace weak or incorrect prop usage with cropped single-frame foliage and cleaner landmark clusters.
3. Add additive landmark props: fences, crates, barrels, posts, planters, boardwalk details, and shoreline dressing.
4. Strengthen phase presentation with warmer storefronts, clearer evening lighting, and a more obvious dock-ready cue.
5. Restyle the Day HUD and prompts so they feel diegetic and supportive instead of debug/admin-like.

## Asset Policy For This Pass

- Prefer no new downloads if the existing Tiny Swords pack plus built-in Godot drawing is sufficient.
- If a new pack becomes necessary, it must stay stylistically close to the current top-down pixel set and be documented with source and reuse terms.
