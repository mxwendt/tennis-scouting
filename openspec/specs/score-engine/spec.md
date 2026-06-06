# score-engine Specification

## Purpose

The score engine is the rules engine at the heart of the app. It derives the complete, always-accurate state of the match from a raw sequence of recorded points and a match configuration. Every feature that displays or summarises match data depends on this engine. It is implemented as a single pure derivation function — given the `MatchConfig` and the full point log, it returns complete `MatchState`. No mutable state, no incremental updates. Score state is never persisted; it is always rederived from the point log on load.

## Requirements

### Requirement: Game scoring
The system SHALL track point progression within a game using standard tennis scoring (0, 15, 30, 40) and detect when a game is won.

#### Scenario: Clean game win
- GIVEN four points have been played in a game
- WHEN one player wins all four
- THEN the game is awarded to that player (0, 15, 30, 40, Game)

### Requirement: Standard deuce
The system SHALL support standard deuce scoring where a player must win two consecutive points after reaching 40-all.

#### Scenario: Game won from advantage
- GIVEN the score is deuce (40–40) and one player wins the next point
- WHEN that same player wins the following point
- THEN the game is awarded to that player

#### Scenario: Return to deuce
- GIVEN one player has advantage
- WHEN the other player wins the next point
- THEN the score returns to deuce

### Requirement: No-ad scoring
The system SHALL support no-ad scoring where the first player to win the point at deuce wins the game immediately, with no advantage state produced.

#### Scenario: No-ad deuce point
- GIVEN the deuce format is no-ad and the score is 40–40
- WHEN either player wins the next point
- THEN the game is immediately awarded to that player

### Requirement: Standard set scoring
The system SHALL award a set to the first player to reach 6 games with a lead of at least 2 games.

#### Scenario: Set won 6–4
- GIVEN the set score is 5–4
- WHEN the leading player wins one more game
- THEN the set is awarded with a score of 6–4

#### Scenario: Set not won at 6–5
- GIVEN the set score is 5–5 and one player reaches 6
- WHEN the other player has 5 games
- THEN the set is not yet won and play continues

### Requirement: Pro set scoring
The system SHALL support pro set format where the set is won by the first player to reach 8 games with a lead of at least 2 games.

### Requirement: Tiebreak triggering
The system SHALL trigger a tiebreak when the set score reaches 6–6 in a standard set or 8–8 in a pro set.

### Requirement: Standard tiebreak scoring
The system SHALL score standard tiebreaks (played in all non-final sets) as first to 7 points, win by 2, with no point cap.

#### Scenario: Tiebreak won at 7–5
- GIVEN the tiebreak score is 6–5
- WHEN the leading player wins the next point
- THEN the tiebreak and set are won at 7–5

#### Scenario: Extended tiebreak
- GIVEN the tiebreak score is 6–6
- WHEN points continue
- THEN the tiebreak ends only when one player leads by 2 (e.g. 8–6, 9–7)

### Requirement: Match tiebreak scoring
The system SHALL score match tiebreaks (played in the final set at 6–6 or 8–8) as first to 10 points, win by 2, with no point cap.

### Requirement: Match scoring
The system SHALL track sets won per player and declare the match won when one player reaches the required number of sets (2 for best-of-3, 3 for best-of-5). No further points SHALL be processed after the match is won.

#### Scenario: Best-of-3 match ends
- GIVEN the match format is best-of-3 and one player has won 1 set
- WHEN that player wins another set
- THEN the match is over and matchStatus is set to WonBy that player

### Requirement: Serving rotation
The system SHALL derive the current server from the initial server, total games played, and tiebreak point index. The server SHALL never be stored as separate state.

#### Scenario: Server alternates after each game
- GIVEN player A served the previous game
- WHEN a new game begins
- THEN player B is the current server

#### Scenario: Tiebreak first point server
- GIVEN the set score is 6–6 and player A served the last game before the tiebreak
- WHEN the tiebreak begins
- THEN player B serves the first tiebreak point

#### Scenario: Tiebreak mid-point rotation
- GIVEN a tiebreak is in progress
- WHEN the tiebreak point index advances
- THEN the server changes after point 1, then every 2 points (pattern: 1, 2, 2, 2, ...)

### Requirement: Break point detection
The system SHALL flag each point as a break point when the receiving player is one point away from winning the game and the point is not during a tiebreak.

Under standard deuce scoring:

| Score (receiver's score listed second) | Break point? |
|---|---|
| 0–40 | Yes |
| 15–40 | Yes |
| 30–40 | Yes |
| Advantage receiver | Yes |
| 40–40 (Deuce) | No |
| Advantage server | No |

Under no-ad scoring, the single deuce point IS a break point.

#### Scenario: Break point at 0–40
- GIVEN the game score is 0–40 (receiver leads)
- WHEN the next point begins
- THEN the point is flagged as a break point

#### Scenario: No break point at deuce (standard)
- GIVEN the score is 40–40 and the deuce format is standard
- WHEN the next point begins
- THEN the point is NOT flagged as a break point

#### Scenario: Break point at deuce (no-ad)
- GIVEN the score is 40–40 and the deuce format is no-ad
- WHEN the next point begins
- THEN the point IS flagged as a break point

#### Scenario: No break points during tiebreaks
- GIVEN a tiebreak is in progress at any score
- WHEN any point is played
- THEN it is NOT flagged as a break point

### Requirement: Let serves
The system SHALL make no provision for let serves. Lets are not recorded; the replayed serve is entered instead.

### Requirement: Determinism
The system SHALL be deterministic — the same point log and match config SHALL always produce the same derived state.

### Requirement: Score never persisted
The system SHALL store only the raw point log and match config. All match state SHALL be rederived on load, making it impossible for stored state to drift out of sync.

## Test Cases

- A complete standard game won to love (4 points)
- A game that goes to deuce and is won by the server
- A game that goes to deuce and is won by the receiver (break of serve)
- A game under no-ad scoring won at deuce
- A set won 6–0
- A set won 7–5
- A set that reaches 6–6 and is decided by a tiebreak
- A standard tiebreak won 7–5
- A standard tiebreak that extends past 7 (e.g. 8–6)
- A match tiebreak won 10–8
- A match tiebreak that extends past 10 (e.g. 11–9)
- Correct server after every game in a set
- Correct server for the first point of a tiebreak
- Correct server mid-tiebreak (point 1, 2, 3, 4, 5)
- Correct server at the start of the set following a tiebreak
- Break point detected at 0–40
- Break point detected at 15–40
- Break point detected at 30–40
- Break point detected at advantage receiver (standard deuce)
- Break point NOT detected at 40–40 (standard deuce)
- Break point NOT detected at advantage server
- Break point detected at deuce under no-ad scoring
- Break point converted and saved both recorded correctly
- A full best-of-3 match played to completion
- Match state correctly shows match won once winning condition is met
- Pro set triggered at 8–8

## Technical Notes

- **Single pure derivation function** — a single function takes `MatchConfig` and the full point log and returns complete `MatchState`. Recomputed in full after every saved point.
- **Fold over the point log** — state is derived by folding over the list of recorded points. Each step is a pure function from (current state, next point) to new state.
- **Algebraic data types** — game score, set state, tiebreak type, and player are all union types. Exhaustive pattern matching enforced by the compiler; unhandled branches are compile errors.
- **`Player` as union type** — `PlayerA | PlayerB` used everywhere a player must be identified. No strings or booleans.
- **`MatchConfig` record** — carries match format, set format, tiebreak format, deuce format, and initial server. Fixed at match start, never mutated.
- **Serving rotation as pure derivation** — computed from initial server, total games played, and tiebreak point index. Never stored as separate state.
- **Break point detection as a pure predicate** — evaluated against the current game state and deuce format before each point is committed. No special tracking field required.
- **Tiebreak serving encapsulated separately** — tiebreak point index determines serving via its own function, keeping the main fold clean and testable in isolation.
