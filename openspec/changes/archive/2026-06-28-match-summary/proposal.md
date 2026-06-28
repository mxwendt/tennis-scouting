## Why

The match-summary spec defines a rich statistical breakdown view, but it is not yet implemented — the app has no summary page, no auto-trigger at set/match end, and no way to open the summary from the match list. Coaches need this view at changeovers and after the match to make tactical decisions.

## What Changes

- Add a new `MatchSummary.elm` module that renders the full summary: score, serve stats, return stats, rally stats, and points totals for both players
- Extend `Stats.elm` to cover the missing stats required by the spec: aces, double faults, service games won %, return points won, break points saved, forced errors, and total points won/played
- Auto-display the summary as a full-screen overlay in `LiveTracking.elm` when a set ends or the match ends, with a dismiss action
- Add a "View summary" button in the live-tracking footer to open the summary on demand between points
- Add a `MatchSummaryPage` to `Main.elm` so the summary can be shown in read-only mode when the user taps a completed match in the match list
- Update the match list row in `Main.elm` to open the summary (instead of live tracking) for completed matches

## Capabilities

### New Capabilities

- `match-summary-view`: Full-screen summary view with set-by-set score, serve statistics, return statistics, rally statistics, and points totals for both players; supports live overlay mode (dismissable) and read-only page mode

### Modified Capabilities

- `match-summary`: Adding the stats fields and auto-display triggers that the spec requires but are not yet computed or surfaced in the UI
- `live-stats`: Existing inline stats panel in `LiveTracking.elm` is superseded by the new summary overlay; `Stats.elm` gains additional computed fields

## Impact

- `src/Stats.elm` — new fields added to `MatchStats`; existing callers (live-tracking stats panel) updated
- `src/MatchSummary.elm` — new file
- `src/LiveTracking.elm` — overlay state, auto-trigger logic, footer button, and dismiss handling added
- `src/Main.elm` — new `MatchSummaryPage`, updated routing for completed matches, new `Msg` variants
- `src/ScoreEngine.elm` — may need to expose service-games-won counts if not already derivable from `MatchState`; read-only, no logic changes
