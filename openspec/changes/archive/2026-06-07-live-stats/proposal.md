## Why

The live-stats panel is fully specified but not yet implemented. Trackers and coaches have no way to see key match statistics (serve percentages, winners, errors, break points) without leaving the tracking screen or manually counting from the point log.

## What Changes

- Add a collapsible stats panel to the Live Tracking screen, rendered between the scoreboard and the point-entry steps
- Compute six per-player statistics on the fly from the point log each time the view renders
- Add a toggle message and expanded/collapsed state to the LiveTracking model
- Add stat-computation helpers (either in `ScoreEngine.elm` or a new `Stats.elm` module)

## Capabilities

### New Capabilities

_None — the `live-stats` spec already exists._

### Modified Capabilities

_None — the existing `live-stats` requirements are complete and unchanged._

## Impact

- **`src/LiveTracking.elm`**: new `statsExpanded` field in Model, new `ToggleStatsTapped` message, new `viewStats` view helper inserted into `view`
- **`src/ScoreEngine.elm`** or new **`src/Stats.elm`**: pure functions to compute the six statistics from `List Point` and `MatchConfig`
- **`tests/`**: unit tests covering each statistic computation (correct counting of serve phases, winners, errors, break-point fractions)
- No new NPM or Elm dependencies required
- No breaking changes to existing data or interfaces
