# Score Logic

## Summary

The score logic is the rules engine at the heart of the app. It takes a raw sequence of recorded points and derives the complete, always-accurate state of the match from them — current point score, game score, set score, who is serving, whether the current point is a break point, and whether the match is over. Every other feature in the app that displays or summarises match data depends on this engine being correct.

---

## Goals

- Accurately track match state at all times based solely on the recorded point log
- Support all match formats and scoring variants configurable at setup
- Automatically determine and track the serving player throughout the match, including tiebreaks
- Automatically detect and record break point opportunities and outcomes
- Serve as the single source of truth for all statistics and score displays

---

## Requirements

### Game scoring

- Points within a game progress through: 0, 15, 30, 40, then game won
- When both players reach 40 (deuce), the game continues until one player wins two consecutive points
- Advantage is awarded after the first point won at deuce; if the advantage player loses the next point, the score returns to deuce
- When no-ad scoring is selected at setup, the first player to win the point at deuce wins the game — there is no advantage

### Set scoring

- A standard set is won by the first player to reach 6 games with a lead of at least 2 games
- A pro set is won by the first player to reach 8 games with a lead of at least 2 games
- If the score reaches 6–6 in a standard set (or 8–8 in a pro set), a tiebreak is played

### Tiebreak scoring

- In any non-final set, a standard tiebreak is played at 6–6 (or 8–8): first to 7 points, win by 2
- In the final set, a match tiebreak is played at 6–6 (or 8–8): first to 10 points, win by 2
- Both tiebreak types use win-by-2 — there is no point cap

### Match scoring

- A best-of-3 match is won by the first player to win 2 sets
- A best-of-5 match is won by the first player to win 3 sets
- The match ends as soon as the winning condition is met

### Serving rotation

- The serving player for the first point of the match is set during Match Setup
- The serving player alternates after every game
- At the start of a tiebreak, the player who did not serve the last game serves the first point
- Within a tiebreak, the serve alternates every 2 points after the opening point (i.e. 1, then 2, 2, 2, ...)
- The engine must always be able to derive the correct server from the point log alone, given the initial server

### Break point detection

- A break point exists when the receiving player is one point away from winning the game, and the serving player has not yet won the game
- Specifically: the score is 0–40, 15–40, or 30–40 in favour of the receiver, or the receiver has the advantage at deuce
- In no-ad scoring, the single deuce point is a break point if the receiver is the one to win it
- The engine must flag each point as a break point opportunity at the moment it is played
- The outcome (converted or saved) must be recorded automatically based on who wins the point

### Let serves

- Let serves are not recorded in the point log
- The tracker waits for the replayed serve and enters that result instead
- The engine makes no provision for let serves; they are transparent to scoring

### Derived state

The engine must be able to derive all of the following from the point log at any time:

- Current point score for both players (in standard tennis notation: 0, 15, 30, 40, Deuce, Advantage)
- Current game score within the set
- Current set scores for all completed and in-progress sets
- Whether a tiebreak is in progress, and the tiebreak point score
- Who is currently serving
- Whether the current point is a break point opportunity
- Whether the current game, set, or match has ended, and who won it
- Total points played and won per player across any scope (game, set, full match)

### Accuracy constraint

- All statistics and displays in the app are derived from the point log via this engine — there is no separate score counter that can drift out of sync
- The engine must be deterministic: the same point log must always produce the same derived state

---

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
- Break point detected at advantage receiver
- Break point NOT detected at 40–40 (standard deuce, not yet advantage)
- Break point detected at deuce under no-ad scoring
- Break point converted and saved both recorded correctly
- A full best-of-3 match played to completion
- Match state correctly shows match won once winning condition is met
- Pro set triggered at 8–8

---

## Technical Decisions

- **Single pure derivation function** — a single function takes the match config and the full point log and returns complete match state. No incremental updates, no mutable state. Recomputed in full after every saved point.

- **Fold over the point log** — match state is derived by folding over the list of recorded points. Each step is a pure function from current state and next point to new state. Game, set, and match state are computed as separate layers within the fold.

- **Algebraic data types for all score concepts** — game score, set state, tiebreak type, and player are all modelled as union types. Exhaustive pattern matching is enforced by the compiler, eliminating unhandled branches.

- **`Player` as a union type** — `PlayerA | Player B` used everywhere a player needs to be identified. No strings or booleans.

- **`MatchConfig` record** — carries match format, set format, tiebreak format, deuce format, and initial server. Passed into the derivation function alongside the point log. Fixed at match start and never mutated.

- **Serving rotation as pure derivation** — the current server is computed from the initial server, total games played, and tiebreak point index. Never stored as separate state.

- **Break point detection as a pure predicate** — evaluated against the current game state and deuce format before each point is committed. No special tracking field required.

- **Tiebreak serving encapsulated separately** — tiebreak point index determines serving via its own function, keeping the main fold clean and testable in isolation.

- **Score never persisted** — only the raw point log and match config are stored locally. Score state is always rederived on load, making it impossible for stored score state to drift out of sync with the point log.

- **Unit tests written before any UI** — one test per scoring rule and one per edge case listed above. Tests run against the pure derivation function directly, with no rendering required.

---

## Implementation Steps

### Step 1 — Core types and basic game scoring

Define all foundational types: `Player`, `MatchConfig`, `Point`, `ServeOutcome`, `RallyTag`, `GameScore`, and a minimal `MatchState`. Implement game scoring from 0 to 40 and game won, excluding deuce. The engine should correctly derive the point score within a game and detect when a game is won before either player reaches 40–40.

Reviewable outcome: given a list of points, the engine returns the correct point score (0, 15, 30, 40) and correctly increments the game score when a player wins 4 clean points.

---

### Step 2 — Deuce and no-ad scoring

Extend game scoring to handle 40–40. Implement standard deuce (advantage, return to deuce, win from advantage, indefinite repetition) and no-ad scoring (single point at deuce wins the game, no Advantage state). The `DeuceFormat` field in `MatchConfig` switches behaviour.

Reviewable outcome: games that go to deuce are correctly resolved under both formats, deuce loops do not cause errors, and the Advantage variant is never produced under no-ad config.

---

### Step 3 — Set scoring

Implement set-level scoring: track game counts per set, detect when a set is won (first to 6 with win-by-2 for standard; first to 8 for pro set), and open a new set when one ends. The engine should correctly accumulate completed set scores and track the in-progress set.

Reviewable outcome: sets won 6–0, 6–4, and 7–5 are all correctly recorded; the set does not end at 6–5; pro set ends at 8–6 not 6–4.

---

### Step 4 — Match scoring

Implement match-level scoring: track sets won per player, detect when the match is won (first to 2 sets for best-of-3, first to 3 for best-of-5), and set `matchStatus` to `WonBy` when the winning condition is met. The engine must stop processing points once the match is over.

Reviewable outcome: a best-of-3 match correctly ends after 2 sets, a best-of-5 after 3; `matchStatus` is `InProgress` until the final set is won.

---

### Step 5 — Serving rotation (normal games)

Implement server tracking for normal play: the initial server comes from `MatchConfig`, and the server alternates after every completed game. The `currentServer` field in `MatchState` must be correct at the start of every game, across sets.

Reviewable outcome: given any sequence of completed games, the engine returns the correct server for the next game; server is correct at the start of the second set.

---

### Step 6 — Tiebreak scoring and serving

Implement tiebreak detection (at 6–6 in standard sets, 8–8 in pro sets), tiebreak scoring (first to 7 with win-by-2 for non-final sets; first to 10 with win-by-2 for the final set), and tiebreak serving rotation (the player who did not serve the last game serves the first tiebreak point; serving alternates every 2 points thereafter). After the tiebreak, normal serving rotation resumes correctly for the next set.

Reviewable outcome: tiebreaks are triggered at the right game score, won at the right point score (including extended tiebreaks), the correct player serves each tiebreak point, and the server at the start of the next set is correct.

---

### Step 7 — Break point detection

Implement break point detection as a predicate derived from the current game state and deuce format. Flag `isBreakPoint` as `True` at 0–40, 15–40, 30–40, advantage receiver (standard deuce), and deuce (no-ad). Record whether each break point was converted or saved based on who wins the point.

Reviewable outcome: `isBreakPoint` is correctly `True` or `False` at every game score, including no-ad deuce; converted and saved break points are both recorded correctly.

---

### Step 8 — Point totals and derived statistics

Implement total point counting: total points played, points won by each player across the full match. Ensure all serve outcomes (ace, serve winner, double fault, rally win) attribute the point to the correct player.

Reviewable outcome: after any sequence of points, total points played and won per player are accurate; double faults correctly attribute the point to the receiver, not the server.
