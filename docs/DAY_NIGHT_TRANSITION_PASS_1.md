# Day-Night Transition Pass 1

## Goals

This pass tightens the moment where the daytime overworld hands off to the night run.

The target was to make the dock feel like an active departure point, make the confirmation feel specific to "casting off" instead of generic routing, and give the shift into night combat a short but readable mood bridge without touching the existing reward, save/load, or combat architecture.

## Design Choices

- The dock now gets stronger evening emphasis through brighter beaconing, stronger harbor glow, and a few extra departure-side props.
- The confirmation remains compact, but the copy now clearly tells the player that leaving closes out the current daytime town phase.
- The transition sequence stays short and low-risk:
  - dock backdrop dim
  - HUD fade/retraction
  - slight camera push/zoom
  - stronger harbor tint
  - centered transition copy
- Input safety is handled inside the existing DayWorld layer instead of moving departure into a new system.

## What Changed

- Dock readiness visuals were reinforced with extra lamp/beacon emphasis, stronger ready glows, and a more active departure staging area.
- Night departure copy was rewritten to feel like boarding/casting off rather than opening a route.
- The confirmation popup now includes a compact note that departing ends the current day-town phase.
- The transition overlay now acts as a real departure beat instead of only a short static fade.
- Day HUD buttons are locked during confirmation/transition and the HUD fades out during cast-off.
- Transition state now blocks hotbar cycling and other stray world interactions more aggressively.
- The popup backdrop now darkens the world and blocks clicks behind it, so departure feels modal and deliberate.

## Deferred

- No combat-side intro sequence was added after the night scene loads.
- No new audio content was added in this pass.
- No large dock cutscene, NPC pathing, or map expansion was introduced.
- The transition is still sub-second and lightweight by design; a heavier cinematic pass can build on this later if wanted.
