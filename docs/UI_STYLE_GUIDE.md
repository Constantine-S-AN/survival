# M4 UI Style Guide (T1)

## Goal
Unify all in-game UI around a neon tactical style so T2-T7 can focus on layout and interaction improvements without re-solving visual consistency.

## Source Of Truth
- Theme file: `res://ui/theme/NeonTheme.tres`
- Reusable components: `res://ui/components/*`
- Component scripts: `res://scripts/ui/components/*`

## Color Tokens
- `bg/base`: `#0f1522` (deep navy)
- `bg/surface`: `#0f192f` (surface panel)
- `bg/overlay`: `#060912` (modal overlay)
- `accent/primary`: `#61e4fa` (interactive highlight)
- `accent/strong`: `#8bf4ff` (hover/focus glow)
- `text/main`: `#e5eeff`
- `text/muted`: `#9ab3cf`
- `danger`: `#ffb2b2`

## Spacing Scale
- `4`: badge vertical padding
- `8`: tight stacks and label groups
- `10`: control baseline separation
- `12`: card internal spacing
- `16`: panel/container spacing
- `20`: modal/container padding

## Type Variations
- `HeadingLabel`: page or modal title
- `SubheadingLabel`: emphasis line / context subtitle
- `BodyMutedLabel`: helper text and secondary stats

## Panel Variations
- `SurfacePanel`: default page panel
- `HudPanel`: compact runtime HUD panel
- `OverlayPanel`: modal/high-focus surfaces
- `CardPanel`: card container for selectable content
- `BadgePanel`: compact inline stat badges
- `TooltipPanel`: floating helper text

## Buttons
- `Button`: default action style
- `PrimaryButton`: primary path action (`Start`, `Retry`, confirmation)
- Hover/focus/pressed states are defined in theme and can be enhanced by component scripts.

## Transitions & Motion
- Global transition entry: autoload `SceneTransition` (`res://scenes/ui/SceneTransition.tscn`).
- Transition API:
  - `fade_in(duration := 0.2)`
  - `fade_out(duration := 0.2)`
  - `transition_to(scene_path, duration := 0.2)`
  - `play_pulse(duration := 0.14)`
- Reentrancy rule: transitions are queue-driven; rapid repeated button presses are serialized to avoid stuck black screens.
- Input rule: during blocking transitions, both pointer and keyboard input are intercepted globally.
- Motion baseline (`res://scripts/ui/ui_motion.gd`):
  - `hover_scale(control, scale := 1.02, duration := 0.08)`
  - `press_bounce(control, duration := 0.10)`
  - `focus_ring(control)`
- Motion toggles:
  - Per-component: `NeonButton.enable_motion`
  - Global: `UIMotion.set_motion_enabled(enabled)`
  - Reserved for future Settings integration: `Reduce Motion`.

## Reusable Components Added In T1
- `NeonButton.tscn`: button with hover/press scale affordance.
- `NeonCard.tscn`: card container with subtle lift-on-hover.
- `StatBadge.tscn`: two-column compact badge for key values.
- `NoiseMeter.tscn`: label + progress + tier readout.
- `TooltipBubble.tscn`: transient tooltip container with optional timeout.
- `SceneFader.tscn`: reusable full-screen fade layer (used by T2).

## Integration In Existing UI
- `res://scenes/ui/UI.tscn`: theme attached at root, HUD/LevelUp/GameOver styled.
- `res://scenes/ui/CharacterSelect.tscn`: theme + primary start CTA.
- `res://scenes/ui/MapSelect.tscn`: theme + primary start CTA.
- `res://scenes/ui/ContractSelect.tscn`: theme + primary start CTA.
- `res://scripts/ui/ui_layer.gd`: runtime-created widgets adopt matching variations.

## Accessibility Baseline
- High contrast text against dark surfaces.
- Focus ring enabled via button focus style.
- Primary actions consistently highlighted to reduce decision latency.

## Notes
- Font remains project default in T1 because no dedicated font asset exists yet.
- If a custom font is added later, bind it in `NeonTheme.tres` once to apply globally.
