# break-point-tracking Specification

## Purpose

Break point tracking automatically detects when the current point is a break point opportunity and records whether it was converted or saved. No input from the tracker is required. Detection is derived entirely from the live score and deuce format. The outcome is logged automatically when the point is saved. Break point data surfaces in the Live Stats Panel during the match and the Match Summary afterwards.

## Requirements

### Requirement: Break point detection
The system SHALL flag a point as a break point when the receiving player is one point away from winning the game, the serving player has not yet won the game, and the point is not during a tiebreak.

Under standard deuce scoring:

| Score (receiver's score listed second) | Break point? |
|---|---|
| 0–40 | Yes |
| 15–40 | Yes |
| 30–40 | Yes |
| Advantage receiver | Yes |
| 40–40 (Deuce) | No — advantage must be won first |
| Advantage server | No |

Under no-ad scoring, the single point played at deuce IS a break point. Only one break point opportunity exists per deuce exchange.

### Requirement: No tiebreak break points
The system SHALL NOT flag any tiebreak point as a break point, regardless of the tiebreak score.

#### Scenario: Tiebreak point not flagged
- GIVEN a tiebreak is in progress at any score
- WHEN a point is played
- THEN it is NOT flagged as a break point

### Requirement: Automatic outcome recording
The system SHALL record the break point outcome automatically when the flagged point is saved, based solely on who wins the point.

| Outcome | Condition |
|---|---|
| Converted | The receiver wins the point |
| Saved | The server wins the point |

#### Scenario: Break point converted
- GIVEN the current point is flagged as a break point
- WHEN the receiver wins the point
- THEN a converted break point is recorded for the receiver

#### Scenario: Break point saved
- GIVEN the current point is flagged as a break point
- WHEN the server wins the point
- THEN a saved break point is recorded for the server

#### Scenario: Double fault on break point
- GIVEN the current point is flagged as a break point
- WHEN the server double faults
- THEN the break point is recorded as converted (the receiver wins the point)

### Requirement: Per-player tracking
The system SHALL track break points separately for each player in their role as receiver:

- Break Points Won: break points converted ÷ total break point opportunities faced as receiver
- Break Points Saved: break points saved ÷ total break point opportunities faced as server

### Requirement: Multiple break points per game
The system SHALL count each individual break point opportunity as a separate entry.

#### Scenario: 0–40 — three separate opportunities
- GIVEN the score is 0–40 (three simultaneous break points)
- WHEN the server wins the next point (score becomes 15–40)
- THEN one saved break point is recorded; the next point at 15–40 is a new separate break point opportunity

### Requirement: No-ad deuce produces exactly one break point
The system SHALL count exactly one break point per deuce exchange under no-ad scoring. The server cannot save it and face a second one in the same deuce exchange.

### Requirement: Standard deuce produces new break points after save
The system SHALL count a new break point opportunity each time the score reaches advantage receiver again (after returning to deuce following a saved break point) under standard deuce.

## Test Cases

- Break point detected at 0–40
- Break point detected at 15–40
- Break point detected at 30–40
- Break point detected at advantage receiver (standard deuce)
- Break point NOT detected at 40–40 / deuce (standard deuce)
- Break point NOT detected at advantage server
- Break point IS detected at deuce under no-ad scoring
- Only one break point opportunity counted per deuce exchange under no-ad scoring
- Break point converted when receiver wins the point
- Break point saved when server wins the point
- Double fault on a break point is recorded as converted
- Multiple break points in the same game (e.g. 0–40) are each counted as separate opportunities
- Break points are not detected during tiebreaks
- Break Points Won stat updates correctly in the Live Stats Panel after each saved point
- Break Points Won and Break Points Saved appear correctly in the Match Summary
- Stats are accurate and independent for Player A and Player B
