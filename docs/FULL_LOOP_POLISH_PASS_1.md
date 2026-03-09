# Full Loop Polish Pass 1

## Audit Scope

This pass reviewed the full first-session loop across a fresh run and the first three in-game days:

- morning/day start
- daytime world activity
- evening departure readiness
- night departure
- night return
- next-day handoff

## Main Friction Points Found

1. Early-day guidance stayed too static.
   The day-hub guide, world guide, and idle prompt did not react enough once the player had already made progress, so the loop could keep explaining the broad plan instead of the next unresolved step.

2. Day 1 guidance implied an overstuffed route.
   The opening copy could read like the player should fully set up the farm and land a lunch-service win in the same first-day pass, which made the early loop feel busier than the action budget really supports.

3. Return-to-morning handoff could lose the next-step message.
   After a return summary, the player restarts near the dock. That meant local dock context could immediately compete with the new day’s actual first priority.

4. Cue ownership was split across systems.
   The guide card, idle prompt, landmark emphasis, and next-day banner were all useful on their own, but they were not consistently pointing at the same next action.

## What Was Improved

1. First-3-day guidance is now stateful.
   The onboarding guide for Days 1-3 now picks a focused next-step line from the live loop state:
   farm carryover, harvest timing, menu planning, service readiness, ready-to-claim orders, or dock departure.

2. Day 1 now frames the opening as a lane choice.
   The first-session copy was tightened so the player is pushed toward one clean early win instead of being told to overfill the day.

3. World prompts now follow the active guide focus during idle states.
   When the player is not actively targeting a world hotspot, the walkable-world prompt now mirrors the same focus line the guide is using.

4. Landmark emphasis follows the same focus.
   The walkable world now biases landmark glow guidance toward the currently active loop focus so the environment, HUD, and guide all reinforce the same route.

5. Next-day handoff banners are more actionable.
   The brief morning banner after a return summary now leads with the current day’s first concrete follow-through step instead of relying only on generic tomorrow framing.

6. Day-start handoff suppresses conflicting local prompts.
   The short next-day intro window now prevents the dock’s local prompt from immediately overriding the intended morning focus.

7. Dialogue copy was tightened where it repeated guidance.
   The Day 1 intro and first return-summary dialogue now reinforce the lane-choice and spend-the-haul framing with less repeated explanation.

## First 3 Days Acceptance Note

- Day 1: the guide now frames the opening as a farm-versus-kitchen lane choice, still surfaces the featured board leads, and cleanly pivots to dock departure once evening is ready.
- Day 2: the first post-night handoff now points directly at watering carryover crops before the rest of the route sprawls.
- Day 3: the second post-night handoff now points directly at the first harvest payoff before the player fans back into orders, kitchen, or shop routing.

## Deferred

- No new gameplay systems were added.
- No combat flow was rewritten.
- No save/load, inventory, or reward architecture was replaced.
- No broad UI rework or new admin modal flow was added.
- Adaptive guidance beyond the first three days remains for a later polish pass.
