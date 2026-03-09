# Audio + Micro-Feedback Pass 1

## Goals

This pass improves the day-night loop through small, low-risk feedback hooks instead of new systems. The focus was on making actions, prompts, popups, and key loop handoffs feel more responsive while keeping the tone subtle and readable.

## Feedback Categories Improved

- Player actions:
  - Farm tool use now gets slightly richer zone feedback by action type.
  - Harvesting and pickups reuse lightweight confirmation/reward SFX hooks.
  - Hotbar selection changes now gently pulse the HUD instead of only swapping text.
- Movement and world feel:
  - The daytime player gets a restrained walk bob/squash pass for a softer sense of movement.
  - Shop, restaurant, and dock interaction points now answer prompt reveal and activation with small zone pulses.
- UI and overlay feedback:
  - Day HUD prompt, guide, status, hotbar, and departure-ready state now animate on meaningful state changes.
  - Shop and restaurant prompt panels and popups now open with small fade/scale cues.
  - Return summary cards now enter with light staggered reveal and button hover/press feedback.
  - Departure and next-day handoff overlays now reuse confirmation/reward cues at key beats.

## What Changed

- `scripts/player/day_player_controller.gd`
  - Added a subtle walk bob and squash/stretch while moving.
- `scripts/meta/day_world.gd`
  - Added feedback routing for focus, till, plant, water, harvest, pickup, and departure-ready moments.
  - Added lightweight dock-ready reinforcement when night departure becomes available.
  - Added button hover/press feedback to the night departure popup.
  - Added gentle audio hooks for night popup open/close, departure, return arrival, and next-day handoff.
- `scripts/ui/day_hud.gd`
  - Added small pulses for prompt reveals, guide changes, hotbar switches, status changes, and the moment night becomes available.
  - Added hover/click feedback to the HUD action buttons.
- `scripts/day/shop/shop_controller.gd`
  - Added prompt reveal pulses, zone response pulses, popup open animation, and button/list hover feedback.
  - Added confirm hooks for seed, sell, and upgrade actions.
- `scripts/day/restaurant/restaurant_controller.gd`
  - Added prompt reveal pulses, zone response pulses, popup open animation, and button/list hover feedback.
  - Added light click/confirm feedback for menu toggles and service start.
  - Result popup now uses reward-weighted feedback when it opens.
- `scripts/meta/return_summary_view.gd`
  - Added small staged card reveal and button hover/press feedback.

## Asset Note

- No new external audio assets or plugins were added in this pass.
- Existing `UISfx` hooks and repo-tracked audio files were reused to keep the implementation rollback-friendly and test-safe.

## Deferred

- No ambient bed or looping location audio was added yet.
- Footstep audio was deferred because the current available assets are better suited to UI/action cues than repeated movement playback.
- Popup close animations remain intentionally simple; this pass prioritized response on reveal and interaction.
- Combat/night-run feedback was left untouched.

## Acceptance Note

- Farm actions respond more clearly without adding spam.
- Shop and restaurant interaction points feel more alive when approached and opened.
- Dock departure readiness lands with a clearer but still compact cue.
- Return summary and next-day handoff read as part of the same loop, not isolated screens.
