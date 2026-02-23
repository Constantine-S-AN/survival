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
- Queue policy: for blocking transitions, `last-wins` is applied while one transition is running (older pending transitions are dropped).
- Input rule: during blocking transitions, both pointer and keyboard input are intercepted globally.
- Safety rule: transition watchdog auto-unblocks input if a blocking transition stalls unexpectedly.
- Motion baseline (`res://scripts/ui/ui_motion.gd`):
  - `hover_scale(control, scale := 1.02, duration := 0.08)`
  - `press_bounce(control, duration := 0.10)`
  - `focus_ring(control)`
- Motion toggles:
  - Per-component: `NeonButton.enable_motion`
  - Global: `UIMotion.set_motion_enabled(enabled)`
  - Reserved for future Settings integration: `Reduce Motion`.

## Main Menu Layout Spec
- Scene: `res://scenes/ui/menu/MainMenu.tscn`
- Script: `res://scripts/ui/menu/main_menu.gd`
- Structure:
  - Full-screen background layer with gradient + scanline/noise shader.
  - Centered information stack:
    - Title (`s u r v i v e`) with expanded tracking feel.
    - Subtitle (`FOG / SONAR / NOISE`) as compact product pitch line.
    - Primary action stack with fixed spacing (`16px`):
      - `Play`
      - `Profile` (placeholder feedback)
      - `Settings` (placeholder feedback)
      - `Quit`
  - Bottom-right version line (`project version + Godot version`).
- Interaction:
  - Keyboard navigation: `Up/Down` focus, `Enter` activate, `Esc` quit.
  - All actions use `NeonButton` with motion enabled.

## Background Motion Rules
- Motion must remain low-frequency and low-amplitude to avoid distraction:
  - Pulse band alpha oscillation target: about `0.5% - 1.5%`.
  - Background pulse speed target: roughly `0.4 - 0.7 Hz`.
  - No fast strobe or large positional swings in menu idle state.
- Visual noise/scanline should stay subtle and never reduce text readability.

## Run Setup Wizard Spec
- Scene: `res://scenes/ui/run_setup/RunSetup.tscn`
- Script: `res://scripts/ui/run_setup/run_setup.gd`
- Three-step flow:
  - `Step 1`: Character
  - `Step 2`: Map
  - `Step 3`: Contracts (max 3)
- Layout:
  - Left: stepper with current highlight and completed check marks.
  - Center: card list using `NeonCard` + `NeonButton`.
  - Right: live summary with selected entries + contract multipliers + top-5 `tag_weights`.
  - Contract cards must show an explicit `Affects:` line so players can see reward impact without opening docs.
- Summary multipliers preview keys:
  - `xp_mult`
  - `rarity_mult`
  - `drop_mult`
  - `meta_currency_mult`
  - Display format recommendation: `x1.20 (+20%)`.
- Output contract for start:
  - `character_id`, `map_id`, `contract_ids`, and derived `multipliers` payload.
- Keyboard baseline:
  - Arrow keys move within cards (when cards area is focused).
  - `Enter` activates focused control.
  - `Tab` rotates `Stepper -> Cards -> Nav -> Start`.
  - `Shift+Tab` rotates backward.

## In-Run HUD Spec
- Scene: `res://scenes/ui/hud/HUD.tscn`
- Script: `res://scripts/ui/hud/hud.gd`
- Adapter: `res://scripts/ui/hud/hud_state.gd`
- Hierarchy:
  - Top center: noise-first panel (value, `Tier N`, tier progress, threshold hint).
  - Left top: survival status (`HP` bar + level/kills/time badges).
  - Right top: build snapshot (weapon + top tags).
  - Bottom center: action cooldowns (`Q Sonar`, `Space Dash`) + contract status.
- Build snapshot copy:
  - Keep only three lines: title, weapon line, `Key tags: [...]`.
  - Remove placeholder body copy in shipped HUD.
- Tier change feedback:
  - On tier boundary transitions, show `THREAT TIER N` and a short pulse.
  - Target duration: `0.12s - 0.18s`.
- Damage feedback:
  - Low-health tint is subtle and persistent at low HP.
  - Damage spike flash is short and low-alpha; avoid full-screen strobe.
- Cooldown display:
  - Show module only if cooldown total exists.
  - On cooldown, show remaining seconds only.
  - At ready state, avoid repetitive `Ready` text.
- Verification runner:
  - `res://tests/ui/t5_hud_runner.tscn`

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
