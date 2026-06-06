# live-score-display Specification

## Purpose

The live score display is a persistent bar at the top of the Live Tracking screen. It shows the current match state at a glance — player names, point scores, and set-by-set game scores — without interfering with point entry. The tracker never interacts with it directly; it updates automatically after every saved point.

## Requirements

### Requirement: Always visible
The system SHALL keep the live score display visible at all times on the Live Tracking screen, including during active point entry.

### Requirement: Player names
The system SHALL display both player names in the score bar, Player A on the left and Player B on the right.

### Requirement: Point score display
The system SHALL display the current point score for both players in large text beneath their names, using standard tennis notation (0, 15, 30, 40, Ad, Deuce).

### Requirement: Set score grid
The system SHALL display a compact 3-column grid (S1, S2, S3) between the player names showing the game score for each set for both players.

- The current set column SHALL be visually highlighted
- Columns for sets not yet played SHALL show a dash (—)
- The grid shows both players' game scores for each set in the same column

#### Scenario: Mid-match display
- GIVEN the match is in the second set and set 1 finished 6–4 in favour of Player A
- WHEN the tracker views the score bar
- THEN S1 shows 6 (Player A) / 4 (Player B), S2 shows the current game score, S3 shows — / —

#### Scenario: Current set highlighted
- GIVEN the match is in set 2
- WHEN the tracker views the score bar
- THEN the S2 column is highlighted and S1 and S3 are not

### Requirement: Serving indicator
The system SHALL display a small dot next to the name of the player who is currently serving, as derived by the score engine.

### Requirement: Auto-update
The system SHALL update the score display immediately after every saved point, always reflecting the current derived state from the score engine.

## Test Cases

- Score bar is visible during point entry and between points
- Current point score is shown correctly for both players (0, 15, 30, 40, Ad, Deuce)
- Completed set scores are shown correctly in their set columns
- Current set column is highlighted
- Sets not yet played show — in their columns
- Serving indicator dot is shown next to the correct player's name
- Serving indicator updates correctly after each game
- Score updates immediately after a point is saved
- Tiebreak point score is shown correctly within the current set column
- Score bar layout uses Player A on the left and Player B on the right
