## Context

The Live Tracking screen (`src/LiveTracking.elm`) already handles point entry and score display. The `live-stats` spec is fully written and defines six per-player statistics that must appear in a collapsible panel on the same screen. No backend exists — all data lives in the in-memory point log (`Match.points : List Point`).

The `ScoreEngine.elm` already derives `breakPoints` (opportunities and converted per player) and `totalPoints` as part of `MatchState`. Serve-phase data is embedded in `ServeOutcome` variants.

## Goals / Non-Goals

**Goals:**
- Implement the collapsible stats panel in `LiveTracking.elm` as specified
- Add pure stat-computation functions that work entirely from `List Point`
- Cover the computation logic with unit tests

**Non-Goals:**
- Persisting expanded/collapsed preference across sessions
- Adding stats to the Match Summary screen (separate capability)
- Changing the score engine or Match data model

## Decisions

### Stats module: new `src/Stats.elm` vs extending `ScoreEngine.elm`

**Decision**: New `src/Stats.elm`.

`ScoreEngine.elm` computes incremental game/set/match state via a fold over the point list. Stats are independent aggregates (simple counters over the same list) and do not need intermediate game-level state. Mixing them into ScoreEngine would conflate two concerns. A dedicated module keeps the public API focused and is easier to test in isolation.

`Stats.elm` will expose:
```
type alias MatchStats =
    { firstServeIn : Int
    , firstServeAttempts : Int
    , firstServePointsWon : Int
    , firstServePointsPlayed : Int
    , secondServePointsWon : Int
    , secondServePointsPlayed : Int
    , winners : Int
    , unforcedErrors : Int
    , breakPointsWon : Int
    , breakPointOpportunities : Int
    }

compute : Player -> List Point -> MatchStats
```

`MatchState.breakPoints` already tracks break-point counts; `Stats.compute` will re-derive them from the point log (keeping the "single source of truth" invariant from the spec) rather than reading from `MatchState`.

### Panel placement

Inserted between `viewScoreboard` and the step cards in the `view` function. This keeps stats visible while scrolling through the steps and matches the mental model: scoreboard → stats → point entry.

### Collapsed state

Add `statsExpanded : Bool` to `LiveTracking.Model`. Default: `True` (visible on first load). One new message `ToggleStatsTapped`. The collapsed state is not persisted.

### Break-point display

Formatted as `"won/opp"` (e.g. `"2/3"`). Zero opportunities renders as `"0/0"`. No special treatment needed.

## Risks / Trade-offs

- **Stats re-computed on every render** — because `deriveMatchState` already folds the full point list on every render, re-folding for stats adds an extra O(n) pass. In practice, matches contain at most a few hundred points, so this is negligible. If profiling ever shows it as a bottleneck, memoisation can be added later.
- **Break-point counts duplicate ScoreEngine** — `Stats.elm` recomputes break-point wins from the point log rather than reading `MatchState.breakPoints`. This avoids a dependency between modules and keeps stats self-contained, at the cost of a small amount of repeated logic.
