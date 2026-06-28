## 1. Extend Stats.elm with missing stat fields

- [x] 1.1 Add `aces`, `doubleFaults`, `serviceGamesWon`, `serviceGamesPlayed`, `returnPointsWon`, `returnPointsPlayed`, `breakPointsSaved`, `breakPointsFaced`, `forcedErrors`, `totalPointsWon`, and `totalPointsPlayed` fields to the `MatchStats` record and `emptyStats`
- [x] 1.2 Compute `aces` and `doubleFaults` in `accumulatePoint` (Ace outcomes → aces; DoubleFault → doubleFaults)
- [x] 1.3 Compute `returnPointsWon` and `returnPointsPlayed` in `accumulatePoint` (InRally and Ace/ServeWinner points where player is receiving)
- [x] 1.4 Compute `forcedErrors` in `accumulatePoint` (InRally points where `rallyWinner /= player` and `maybeTag = Nothing`)
- [x] 1.5 Compute `totalPointsWon` and `totalPointsPlayed` from `MatchState.totalPoints` in the `compute` function
- [x] 1.6 Compute `serviceGamesWon` and `serviceGamesPlayed` by replaying the point log with `ScoreEngine.deriveMatchState` per-prefix to detect game boundaries; accumulate per-player service game outcomes
- [x] 1.7 Populate `breakPointsSaved` and `breakPointsFaced` from `MatchState.breakPoints` (the opponent's break point opportunities and conversions become the player's faced/saved counts)
- [x] 1.8 Run `npm test` to confirm all existing Stats tests still pass

## 2. Create MatchSummary.elm view module

- [x] 2.1 Create `src/MatchSummary.elm` with a `Mode` type (`Overlay | Page`) and a stateless `view : Mode -> Match.Match -> Html msg` function
- [x] 2.2 Implement the score section: set-by-set score grid and total games won row
- [x] 2.3 Implement the serve section: First Serve %, First Serve Points Won %, Second Serve Points Won %, Aces, Double Faults, Service Games Won %
- [x] 2.4 Implement the return section: Return Points Won %, Break Points Won (fraction), Break Points Saved (fraction)
- [x] 2.5 Implement the rally section: Winners, Unforced Errors, Forced Errors, Winner / UE Ratio
- [x] 2.6 Implement the points section: Total Points Played, Total Points Won (count and %)
- [x] 2.7 Lay out each section with a section header and a two-column player-comparison table (player names as column headers)
- [x] 2.8 In Overlay mode render a fixed full-screen container (`fixed inset-0 z-50 overflow-y-auto`) with a sticky dismiss button; in Page mode render a scrollable full-screen container with a back button in the header
- [x] 2.9 Run `npm run format` and `npm run review` to verify the new module

## 3. Wire overlay into LiveTracking.elm

- [x] 3.1 Add `summaryVisible : Bool` to `LiveTracking.Model` and initialise it to `False` in `LiveTracking.init`
- [x] 3.2 Add `ViewSummaryTapped` and `DismissSummaryTapped` to `LiveTracking.Msg`
- [x] 3.3 In the `SavePointTapped` branch of `LiveTracking.update`, detect when a set or the match ends (compare `matchStatus` before and after applying the point) and set `summaryVisible = True`
- [x] 3.4 Handle `ViewSummaryTapped` by setting `summaryVisible = True`
- [x] 3.5 Handle `DismissSummaryTapped` by setting `summaryVisible = False`
- [x] 3.6 In `LiveTracking.view`, when `summaryVisible = True`, render `MatchSummary.view MatchSummary.Overlay model.match` on top of the normal tracking UI
- [x] 3.7 Wire the existing "View summary" footer button to `ViewSummaryTapped` (remove `cursor-default`, add `onClick ViewSummaryTapped`)
- [x] 3.8 Pass dismiss message through to `MatchSummary.view` so the dismiss button fires `DismissSummaryTapped`
- [x] 3.9 Run `npm run format` and `npm run review`

## 4. Add MatchSummaryPage to Main.elm

- [x] 4.1 Add `MatchSummaryPage Match.Match` to the `Page` type in `Main.elm`
- [x] 4.2 Add `OpenSummary Match.Match` and `SummaryBackTapped` to `Main.Msg`
- [x] 4.3 In `Main.update`, handle `OpenSummary`: transition to `MatchSummaryPage`
- [x] 4.4 In `Main.update`, handle `SummaryBackTapped`: transition to `MatchListPage`
- [x] 4.5 In `Main.view`, add a branch for `MatchSummaryPage match` that renders `MatchSummary.view (MatchSummary.Page SummaryBackTapped) match`
- [x] 4.6 Update the `OpenMatch` handler to check `ScoreEngine.deriveMatchState` — if `matchStatus = WonBy _`, dispatch `OpenSummary`; otherwise dispatch `LiveTrackingPage` as before
- [x] 4.7 Update `viewMatchRow` in `Main.elm` so completed matches show a visual indicator (e.g. a "Final" badge) distinguishing them from in-progress matches
- [x] 4.8 Run `npm run format` and `npm run review`

## 5. Tests and verification

- [x] 5.1 Add elm-test cases for the new `Stats.elm` fields: aces, double faults, return points won, forced errors, service games won, break points saved, total points
- [x] 5.2 Add elm-test cases to verify that `Stats.compute` results are consistent with `ScoreEngine.deriveMatchState` on the same point log
- [x] 5.3 Run `npm test` and confirm all tests pass
- [x] 5.4 Run `npm run format` and `npm run review` for a final clean pass across all changed files

## 6. Redesign live-tracking summary integration

- [x] 6.1 Remove stats accordion (`viewStats`, `viewStatRow`, `pct`, `fraction`) from `LiveTracking.elm`
- [x] 6.2 Remove `statsExpanded` from `LiveTracking.Model` and `ToggleStatsTapped` from `Msg`
- [x] 6.3 Remove overlay approach: drop `summaryVisible`, `DismissSummaryTapped`, auto-trigger in `SavePointTapped`, and overlay render from `LiveTracking`
- [x] 6.4 Add `NavigateToSummary` to `LiveTracking.Event`; wire `ViewSummaryTapped` to fire it; enable the footer "View summary" button
- [x] 6.5 Add `SummaryFromLivePage LiveTracking.Model` to `Main.Page` and `LiveSummaryBackTapped` to `Main.Msg`
- [x] 6.6 Handle `LiveTracking.NavigateToSummary` in `Main.update` → transition to `SummaryFromLivePage`
- [x] 6.7 Handle `LiveSummaryBackTapped` in `Main.update` → restore `LiveTrackingPage` from stored model
- [x] 6.8 Simplify `MatchSummary.Mode` to `FromLiveTracking msg` (amber "Continue" button) and `FromMatchList msg` (grey back link)
- [x] 6.9 Update both `Main.view` call sites to use the new `Mode` constructors

## 7. Add active set score to summary

- [x] 7.1 In `MatchSummary.viewScoreSection`, insert the current set's game score row after completed sets and before Total Games, only when `InProgress`
- [x] 7.2 Remove the "Sets — —" placeholder row from `viewSetScoreRows`
