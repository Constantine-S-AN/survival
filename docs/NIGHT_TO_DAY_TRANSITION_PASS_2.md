# Night-to-Day Transition Pass 2

## Goals

This pass makes the trip back from the night run feel like a return to the harbor and a handoff into the next day, instead of only a detached results page followed by a raw state flip.

The target was to keep the existing reward, save/load, and progression flow intact while improving three beats:

- arriving back at the dock
- understanding what tonight changed
- stepping into the next morning with clearer momentum

## Design Choices

- The worldified dock stays visible behind the return summary so the player feels like they came back to a place, not a separate menu.
- The return summary remains compact, but its copy now frames the result as a harbor arrival and explicitly points at tomorrow's strongest opportunities.
- DayWorld now adds a lightweight arrival camera settle on fresh return, plus a short morning handoff beat when the next day begins.
- Temporary guide emphasis after the summary continue ties night gains back into visible farm / restaurant / shop landmarks instead of relying only on dense text.
- Reward application, save/load, pending summary persistence, and next-day advancement remain on the existing MetaLoop path.

## What Changed

- Fresh night returns now trigger a short harbor-arrival presentation on the DayWorld dock with stronger dock focus and a compact world banner.
- Reloading into a pending return summary restores the settled dock-backed state without replaying the fresh arrival beat.
- The return summary copy now emphasizes:
  - what tonight secured
  - what opened because of the run
  - what tomorrow is most likely to convert into progress
- Continuing the summary now triggers a lightweight next-day handoff:
  - dock-focused camera relaxes back into the normal daytime framing
  - a short morning banner appears
  - landmark guidance gets a temporary boost toward the farm / kitchen / shop depending on the haul
- Input safety still routes through the existing blocked-overlay flow, so world interaction stays locked while the summary is pending and reward settlement still occurs once.

## Deferred

- No combat-side return cutscene was added.
- No new audio pass was added for docking, unloading, or morning restart.
- No large dock NPC choreography or cargo-handling animation was introduced.
- The summary is still a UI card, not an in-world walk-and-talk sequence.
