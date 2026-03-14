# Night Dungeon Content Pass

This pass moves the night run away from placeholder combat boxes and into a small authored room library that still fits the current scaffold.

## Goals

- Keep the existing room-graph, reward, extraction, and return flow intact.
- Make room identity legible through authored geometry instead of only labels.
- Add a small amount of tactical environment play:
  - cover blockers for routing and spacing
  - hazard zones that damage both sides
  - volatile props that can swing a fight when pathing goes wrong
- Keep content deterministic enough for tests.

## Authored Room Scenes

- `scenes/night/rooms/HarborRefugeRoom.tscn`
- `scenes/night/rooms/QuietNicheRoom.tscn`
- `scenes/night/rooms/SupplyCacheRoom.tscn`
- `scenes/night/rooms/OmenShrineRoom.tscn`
- `scenes/night/rooms/ReefChannelRoom.tscn`
- `scenes/night/rooms/ReefPillarRoom.tscn`
- `scenes/night/rooms/SwarmNestRoom.tscn`
- `scenes/night/rooms/UndertowForgeRoom.tscn`
- `scenes/night/rooms/AbyssSanctumRoom.tscn`

The rest/treasure/event rooms are lighter and mostly focus on identity and navigation readability. Combat and boss rooms carry the tactical setpieces.

## Room Variants

The floor still uses the same room IDs and routing so tests stay stable, but it now chooses between two authored template variants:

- `branching_intro_channels`
- `branching_intro_pillars`

That gives deterministic variation by seed without changing the meta-facing run structure.

## Encounter Variation

Enemy placements are now pulled from `data/night_spawn_sets.json`.

That keeps encounter category and reward logic in `night_encounters.json`, while letting room templates override spawn layouts cleanly per template.

## Environmental Data

`data/night_hazards.json` currently defines:

- `undertow_pool`: pulsing zone that pressures both player and enemies
- `shock_vent`: faster hazard pulse for tighter spaces
- `volatile_barrel`: proximity-triggered explosive prop

The room scenes place these as authored setpieces using:

- `scenes/night/rooms/setpieces/HazardZone.tscn`
- `scenes/night/rooms/setpieces/ExplosiveProp.tscn`
- `scenes/night/rooms/setpieces/CoverWall.tscn`
- `scenes/night/rooms/setpieces/CoverPillar.tscn`

## Testing Notes

The focused night-run test checks:

- authored room scenes are used instead of the generic placeholder room scenes
- authored combat rooms expose cover, hazards, and explosive props
- different deterministic seeds choose different authored combat-room scenes

This keeps the content pass visible in CI instead of relying on only visual inspection.
