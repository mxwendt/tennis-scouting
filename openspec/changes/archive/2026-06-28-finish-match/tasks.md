## 1. Data Model

- [x] 1.1 Add `finished : Bool` to the `Match` record in `src/Match.elm`
- [x] 1.2 Add `finished = False` to the `newMatch` literal in `MatchSetupMsg` handler in `src/Main.elm`

## 2. Persistence

- [x] 2.1 Add `finished` field to `encodeMatch` in `src/Main.elm`
- [x] 2.2 Update `decodeMatch` in `src/Main.elm` to decode `finished` with `Maybe.withDefault False` fallback for legacy records

## 3. Routing & Page Shape

- [x] 3.1 ~~Change `MatchSummaryPage Match` to `MatchSummaryPage Match Bool`~~ `MatchSummaryPage` keeps a single `Match` argument (no confirming state needed)
- [x] 3.2 Update `OpenMatch` routing in `src/Main.elm` to check `match.finished` first, then the score-engine result
- [x] 3.3 Add `SummaryResumeTapped` to `Msg` in `src/Main.elm`
- [ ] 3.4 ~~Handle `SummaryResumeTapped` transitioning to confirming state~~ (removed — no confirmation step)
- [x] 3.5 Handle `SummaryResumeTapped` in `update`: set `finished = False`, save, navigate to `LiveTrackingPage`
- [x] 3.6 Update all `MatchSummaryPage` pattern-matches in `view` and `update`

## 4. Match List Label

- [x] 4.1 Update `viewMatchRow` in `src/Main.elm` to show "Stopped" when `match.finished == True` and score is `InProgress`

## 5. LiveTracking — Finish Action

- [x] 5.1 Add `MatchFinished` to `Event` in `src/LiveTracking.elm`
- [x] 5.2 Add `FinishMatchTapped` to `Msg` in `src/LiveTracking.elm`
- [x] 5.3 Handle `FinishMatchTapped` in `update`: emit `MatchFinished`
- [x] 5.4 Update `viewFooter` to show a Finish button alongside "View summary" when `not (List.isEmpty model.match.points)` and `not model.trackingStarted`
- [x] 5.5 Handle `LiveTracking.MatchFinished` event in `src/Main.elm`: set `finished = True`, save, navigate to `MatchSummaryPage match False`

## 6. Match Summary — Resume Button

- [x] 6.1 Add `FromMatchListFinished` variant to `Mode msg` in `src/MatchSummary.elm`, carrying `onBack`, `onResume`, `onConfirmResume`, and `confirming : Bool`
- [x] 6.2 Add `viewFinishedHeader` to `src/MatchSummary.elm` rendering back link + Resume button (two-step inline confirmation)
- [x] 6.3 Update `view` in `src/MatchSummary.elm` to dispatch to `viewFinishedHeader` for the new mode
- [x] 6.4 Update `view` in `src/Main.elm` to pass `FromMatchListFinished` mode when `match.finished == True`, `FromMatchList` otherwise
