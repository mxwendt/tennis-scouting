## Context

The `match-summary` spec is fully written and covers every stat, display mode, and trigger — but none of it is implemented. The current state of the codebase:

- `Stats.elm` computes 6 stats per player (first-serve %, first/second-serve points won, winners, unforced errors, break points won), but is missing aces, double faults, service games won %, return points won, break points saved, forced errors, and total points won/played.
- `LiveTracking.elm` has an inline stats panel (6 stats, collapsible) and a dead "View summary" button in the footer (cursor-default, no onClick).
- `Main.elm` routes completed matches to `LiveTrackingPage`, not a summary page.
- No `MatchSummary.elm` module exists.

The `ScoreEngine.MatchState` already tracks `totalPoints` and per-player `breakPoints`. Service games won must be computed separately (see Decisions).

## Goals / Non-Goals

**Goals:**
- Implement the full match-summary spec: all stats, auto-trigger at set/match end, on-demand footer button, read-only access from match list
- Extend `Stats.elm` with the missing stat fields
- Create `MatchSummary.elm` as a standalone view module usable in both overlay and page mode
- Wire up the existing (dead) "View summary" footer button in `LiveTracking.elm`
- Route completed matches from the match list to a `MatchSummaryPage`

**Non-Goals:**
- Per-set stat breakdowns (only aggregate totals, as specified)
- Exporting or sharing the summary
- Modifying the live-stats panel (it stays as a quick 6-stat view during point entry)
- Any backend or sync changes

## Decisions

### 1. Single `MatchSummary.elm` module with a mode parameter

The summary needs to render in two contexts: as a full-screen overlay over `LiveTracking.elm` (dismissable) and as a standalone page opened from the match list (has a back button). Both render the same content.

**Decision**: `MatchSummary.elm` exposes a `view` function that takes a `Mode` type (`Overlay` | `Page`) along with the match data. The module is stateless — no `Model` or `update` — since the summary is purely derived from the point log.

**Alternative considered**: Separate `MatchSummaryOverlay.elm` and `MatchSummaryPage.elm`. Rejected because the content is identical and duplication would be hard to keep in sync.

### 2. Overlay state lives in `LiveTracking.Model`

The spec requires the overlay to appear automatically at set/match end and to be openable on demand. `LiveTracking.elm` already manages match state, so it's the right place to control overlay visibility.

**Decision**: Add `summaryVisible : Bool` to `LiveTracking.Model`. The `update` function raises this flag when a set or match ends (detected after `SavePointTapped` by comparing `matchStatus` before and after). It also handles `ViewSummaryTapped` (footer button) and `DismissSummaryTapped`.

**Alternative considered**: Letting `Main.elm` control the overlay by raising an event. Rejected because it would push set/match-end detection logic up to the parent, which already delegates all tracking state to `LiveTracking`.

### 3. Service games won computed in `Stats.elm` via a single pass

The spec requires "Service Games Won %" (service games held ÷ total service games played). `MatchState` doesn't track this directly — it has break point counts but not service game win/loss totals.

**Decision**: Extend `Stats.elm` to compute service games won by replaying the point log. Track the current game's server and accumulate `serviceGamesPlayed` / `serviceGamesWon` each time a game ends (detected by score transitions in `ScoreEngine`). This keeps `ScoreEngine.elm` unchanged.

**Alternative considered**: Adding service game tracking to `ScoreEngine`. Rejected to avoid expanding the ScoreEngine's surface area; Stats.elm is the right place for per-player derived stats.

### 4. Read-only access: new `MatchSummaryPage` in `Main.elm`

Completed matches (where `matchStatus = WonBy _`) should open the summary page, not live tracking. In-progress matches continue to open `LiveTrackingPage`.

**Decision**: Add `MatchSummaryPage Match` to `Main.Page`. The `OpenMatch` handler in `Main.update` inspects `ScoreEngine.deriveMatchState` to check `matchStatus` and routes accordingly.

**Alternative considered**: Always opening `LiveTrackingPage` and showing the summary as a full-screen overlay. Rejected because a completed match shouldn't suggest point entry is available; a dedicated page is clearer.

### 5. Forced errors: rally points with no tag

The spec defines "Forced Errors" as "rally points saved without a Winner or Unforced Error tag". These are `InRally` points where the opponent wins and no rally tag is present.

**Decision**: Compute `forcedErrors` in `Stats.elm` as: `InRally` points where `rallyWinner /= player` and `maybeTag = Nothing`. This is a simple addition to `accumulatePoint`.

## Risks / Trade-offs

- **Overlay z-index on mobile**: As a Tailwind `fixed inset-0` overlay rendered by `LiveTracking.elm`, the summary must appear above all other elements. The overlay div must use `z-50` or higher. → Low risk given the simple single-page layout.
- **Service games won accuracy for tiebreaks**: A set tiebreak is counted as one service game — but who "served" it is ambiguous (both players serve). The stat will count the tiebreak as a service game for the first server, consistent with how break points are attributed in `ScoreEngine.elm`. → Acceptable trade-off; spec does not special-case tiebreaks.
- **Backwards compatibility**: Existing `Stats.elm` callers (the live-stats panel in `LiveTracking.elm`) reference named fields. Adding new fields to `MatchStats` is non-breaking in Elm; callers that do not use the new fields need no changes.

## Migration Plan

No migration required. The change is purely additive — no stored data format changes, no breaking API changes. Existing matches stored in local storage are unaffected.
