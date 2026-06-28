## Context

Match completion is currently derived entirely from `ScoreEngine.deriveMatchState`: a match is `WonBy` only when the score reaches a natural end. There is no stored "finished" state and no way to exit tracking early or reopen a completed match in live mode.

`MatchSummary` is a stateless view module (`view : Mode msg -> Match -> Html msg`) with no `Model` or `update`. `LiveTracking` follows the full TEA component pattern with its own `Model`, `Msg`, `update`, and `Event` type for parent communication.

## Goals / Non-Goals

**Goals:**
- Store `finished : Bool` on `Match` so manual-finish state survives app restart
- Add a Finish action to `LiveTracking` that persists `finished = True` and routes to summary
- Add a Resume action to `MatchSummaryPage` (only when `finished == True`) with a two-step inline confirmation
- Update match list label and `OpenMatch` routing to reflect the new field
- Decode old localStorage data cleanly (no `finished` field → `False`)

**Non-Goals:**
- Making `MatchSummary` a stateful TEA component
- Capturing a reason for finishing (retired, walkover, etc.)
- Resume on naturally-won matches (score engine `WonBy`)

## Decisions

### 1. `finished : Bool` on `Match`, not on `LiveTracking.Model`

`LiveTracking.Model` is ephemeral (lost on page navigation). Storing `finished` there would not survive reopening the app. The flag must live on `Match` so it is serialised to localStorage alongside the point history.

**Alternative considered:** A separate "finished match IDs" set in `SavedState`. Rejected — keeping the flag on `Match` keeps the data cohesive and simplifies encoding/decoding.

---

### 2. No resume confirmation — single-tap executes immediately

Resume is a single-tap action with no confirmation step. The `MatchSummaryPage` page variant in `Main` carries just the match:

```
MatchSummaryPage Match
```

`MatchSummary.view` receives the resume callback via an extended `Mode` variant:

```
type Mode msg
    = FromLiveTracking msg
    | FromMatchList msg
    | FromMatchListFinished { onBack : msg, onResume : msg }
```

Main selects `FromMatchListFinished` when `match.finished == True`, and `FromMatchList` otherwise.

---

### 3. `MatchFinished` — a new `LiveTracking.Event`

The Finish button emits a new event `MatchFinished` (alongside the existing `NavigateToSummary`). Main handles it by:
1. Setting `finished = True` on the match
2. Saving to localStorage
3. Routing to `MatchSummaryPage { match = updatedMatch, confirmingResume = False }`

Using a dedicated event (rather than reusing `NavigateToSummary`) keeps the two flows distinct: `NavigateToSummary` is a peek at stats mid-match with a "Continue" button; `MatchFinished` is a terminal action with a "Resume" button.

---

### 4. `OpenMatch` routing: `finished` check before score-engine check

```
finished == True  →  MatchSummaryPage (with resume)
matchStatus == WonBy  →  MatchSummaryPage (no resume)
InProgress  →  LiveTrackingPage
```

The `finished` flag takes precedence. A manually-finished match with a score still `InProgress` correctly routes to summary.

---

### 5. Backward-compatible decode

The new `finished` field is decoded with a fallback:

```elm
Decode.field "finished" Decode.bool
    |> Decode.maybe
    |> Decode.map (Maybe.withDefault False)
```

Old localStorage data without the field decodes as `False`, leaving all existing matches in their current state.

## Risks / Trade-offs

- **Accidental resume** — Without a confirmation step, a mis-tap on Resume immediately reopens live tracking. This is recoverable (tap Finish again from live tracking), and the simpler interaction was preferred over the safety guard.
- **`MatchSummaryPage` variant shape change** — `Main.Page` currently stores `MatchSummaryPage Match`. No extra state is needed, so the variant remains `MatchSummaryPage Match`.

## Migration Plan

- No server or shared data; localStorage is per-device.
- Old data decodes safely via the `Maybe.withDefault False` fallback (see Decision 5).
- No user action required.

## Open Questions

- (none)
