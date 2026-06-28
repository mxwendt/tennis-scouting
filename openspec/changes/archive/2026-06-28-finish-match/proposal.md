## Why

During live tracking a match may end early — player retirement, weather, or simply stopping coverage — with no way to mark it closed. And when a `finished` match turns out to not be over (e.g. a mis-tap or a misread score), there is no path back to live tracking.

## What Changes

- Add a `finished : Bool` field to `Match` (defaults to `False`)
- Add a **Finish** button to the LiveTracking footer, visible only after at least one point has been recorded (`trackingStarted == True`); tapping it sets `finished = True`, saves, and navigates to `MatchSummaryPage`
- Add a **Resume** button to `MatchSummaryPage`, rendered only when `match.finished == True`; it uses a two-step inline confirmation before setting `finished = False`, saving, and navigating to `LiveTrackingPage`
- Update `OpenMatch` routing: `match.finished == True` routes to `MatchSummaryPage` (ahead of the score-engine check)
- Update the match list status label: `finished == True` and score still `InProgress` shows `"Stopped"` instead of `"In Progress"`

## Capabilities

### New Capabilities

- `finish-match`: Manually mark a match as finished from live tracking at any point after the first point is recorded, and resume a manually-finished match from the summary screen

### Modified Capabilities

- (none — no existing spec files)

## Impact

- `src/Match.elm` — `Match` record gains `finished : Bool`
- `src/Main.elm` — `OpenMatch` routing updated; new `ResumeMatch` message added; encode/decode updated for `finished` field
- `src/LiveTracking.elm` — new `FinishMatchTapped` message and `MatchFinished` event; footer updated
- `src/MatchSummary.elm` — Resume button added (conditional on `finished`); new origin context variant or message
- Persisted `localStorage` data gains a new field; old data without `finished` must decode cleanly as `False`
