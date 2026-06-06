## 1. Stats Module

- [x] 1.1 Create `src/Stats.elm` with `MatchStats` type alias and `compute : Player -> List Point -> MatchStats` function
- [x] 1.2 Implement first-serve counting: `firstServeAttempts` (fault + any non-fault first-serve outcome), `firstServeIn` (non-fault first-serve outcomes)
- [x] 1.3 Implement `firstServePointsWon` and `firstServePointsPlayed` (points where first serve was in)
- [x] 1.4 Implement `secondServePointsWon` and `secondServePointsPlayed` (second-serve points, excluding double faults from denominator)
- [x] 1.5 Implement `winners`: Ace + ServeWinner (credited to server) + InRally with Winner tag (credited to rally winner)
- [x] 1.6 Implement `unforcedErrors`: DoubleFault (credited to server) + InRally with UnforcedError tag (credited to rally loser)
- [x] 1.7 Implement `breakPointsWon` and `breakPointOpportunities` from the point log (re-derive from ScoreEngine state per point)

## 2. Stats Tests

- [x] 2.1 Test `firstServeIn` / `firstServeAttempts`: fault then second serve counts as one attempt; ace counts as one attempt and one in
- [x] 2.2 Test `firstServePointsWon`: only points won when first serve was in are counted
- [x] 2.3 Test `secondServePointsPlayed` excludes double faults from denominator
- [x] 2.4 Test `winners` includes aces, serve winners, and rally winners; does not include points won on second serve without a tag
- [x] 2.5 Test `unforcedErrors` includes double faults and rally unforced errors
- [x] 2.6 Test `breakPointsWon` and `breakPointOpportunities` for a known point sequence

## 3. LiveTracking Model & Update

- [x] 3.1 Add `statsExpanded : Bool` field to `LiveTracking.Model`; initialise to `True` in `init`
- [x] 3.2 Add `ToggleStatsTapped` to `LiveTracking.Msg`
- [x] 3.3 Handle `ToggleStatsTapped` in `update`: flip `model.statsExpanded`

## 4. Stats Panel View

- [x] 4.1 Add `viewStats : Bool -> Match.Match -> Html Msg` that takes `statsExpanded` and the match, calls `Stats.compute` for both players, and renders the panel
- [x] 4.2 Render collapsed state: header row with player names and a "Show stats" / chevron affordance; no stat rows visible
- [x] 4.3 Render expanded state: header row with toggle, plus one row per stat showing label, Player A value, and Player B value
- [x] 4.4 Format percentage stats as `"N%"` (rounded to nearest integer; show `"–"` when denominator is zero)
- [x] 4.5 Format break-points stat as `"won/opp"` (e.g. `"2/3"`; `"0/0"` when no opportunities)
- [x] 4.6 Wire `viewStats` into the `view` function between `viewScoreboard` and the step-card block

## 5. Verification

- [x] 5.1 Run `npm run format` and fix any elm-format issues
- [x] 5.2 Run `npm run review` and fix any elm-review issues
- [x] 5.3 Run `npm test` and confirm all tests pass
