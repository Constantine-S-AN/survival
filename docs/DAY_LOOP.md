# Day Loop

This vertical slice is a hybrid management/combat loop:

1. Start in the day hub.
2. Spend shared daytime actions across farm, restaurant planning/service, shop, or resting forward.
3. Reach evening or night.
4. Launch night combat.
5. Resolve combat rewards into shared inventory/economy state.
6. Show the return summary.
7. Continue into the next day, which advances crop growth and resets daytime pacing.

## Daytime Pacing

The day clock is segmented into:

- morning
- noon
- afternoon
- evening
- night

`action_budget` is the shared time currency for daytime. `stamina` is the shared effort currency for daytime labor. The current implementation uses them as follows:

- farm till, plant, water, and harvest all spend daytime action budget
- till and water also spend stamina, while harvest only spends time
- restaurant service spends a major chunk of the day
- waiting at the hub can fast-forward the day to evening
- night combat cannot launch before the player reaches the evening/night threshold

The intent is explicit opportunity cost: the player should not be able to fully farm, fully serve, and still launch combat without paying time/stamina costs.

## Shared State

The hybrid loop is stateful across all daytime scenes. The following are intended to persist across scene transitions and save/load:

- current day
- current day phase
- stamina and remaining action budget
- gold and restaurant reputation
- inventory materials
- unlocked seeds and recipes
- farm plot tilled/crop state
- selected restaurant menu
- last restaurant service summary
- owned restaurant upgrades
- pending post-combat return summary

Scene switches alone should not create or destroy inventory. Inventory changes should come only from controller actions:

- farm harvest adds produce
- restaurant service consumes ingredients and adds gold/reputation
- shop buy/sell mutates gold and inventory
- combat reward resolution mutates gold/materials/unlock progress

## Crop Progression

Crop progression is day-based, not scene-based.

- watering marks a crop for the current day
- crop growth advances only when the player finishes the combat summary and enters the next day
- a mid-day save/load should preserve the watered-day marker without advancing growth early
- a post-combat continue should apply the saved watered state once to the next day

## Restaurant Persistence

Restaurant state is intentionally sticky:

- `selected_menu_recipe_ids` persists so the player can plan service across scene changes or reloads
- `last_service_day` persists so same-day service lockouts survive reloads
- `last_service_summary` persists so the player can reopen the restaurant and still see the latest result
- menu ingredient consumption is applied at service time and should not be re-applied on reload

## Combat Reward Transfer

The return summary is a bridge, not a second reward pass.

- combat reward resolution applies shared inventory/economy changes immediately
- `pending_return_summary` stores the UI payload needed to resume on reload
- continuing from the summary clears the pending payload, advances the day, applies crop rollover, and restores daytime pacing for the next loop

This split is important for correctness: save/load after combat should restore both the already-earned rewards and the still-pending summary/next-day transition.
