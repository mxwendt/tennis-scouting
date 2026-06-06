# match-setup Specification

## Purpose

Match Setup is the form the tracker fills in before tracking begins. It collects all information the score engine needs to run correctly, plus the match metadata needed for identification and review. Completing the form creates a new match record, saves it to local storage, and navigates to the Live Tracking screen. The configuration is fixed once the match starts and cannot be changed mid-match.

## Requirements

### Requirement: Entry point
The system SHALL only open Match Setup when the tracker taps New Match from the Match List. Resuming an existing match SHALL bypass this screen entirely.

### Requirement: Required fields
The system SHALL require Player A Name, Player B Name, and Initial Server to be filled in before the match can start. The Start Match button SHALL be disabled until all three are present.

#### Scenario: Start Match blocked without required fields
- GIVEN the form is open
- WHEN Player A Name, Player B Name, or Initial Server is missing
- THEN the Start Match button is disabled

#### Scenario: Start Match enabled with required fields
- GIVEN Player A Name and Player B Name are filled in and Initial Server is selected
- WHEN the tracker views the form
- THEN the Start Match button is enabled

### Requirement: Fields collected
The system SHALL collect the following fields:

| Field | Options | Notes |
|---|---|---|
| Player A Name | Free text | The player being scouted |
| Player B Name | Free text | The opponent |
| Initial Server | Player A / Player B | Who serves the first point |
| Match Format | Best of 3 / Best of 5 | Determines sets needed to win |
| Set Format | Standard / Pro set | Standard = first to 6; Pro set = first to 8 |
| Tiebreak Format | Standard + match tiebreak | Standard (first to 7) in non-final sets; match tiebreak (first to 10) in final set |
| Deuce Format | Standard deuce / No-ad | Standard = advantage scoring; No-ad = single point at deuce wins |
| Surface | Hard / Clay / Grass / Carpet | Context only, does not affect scoring |
| Date | Date | Defaults to today |

### Requirement: Default values
The system SHALL pre-fill the following defaults so the tracker can start quickly without touching every field:

| Field | Default |
|---|---|
| Match Format | Best of 3 |
| Set Format | Standard |
| Deuce Format | Standard deuce |
| Date | Today's date |
| Surface | No default (optional) |

### Requirement: Match config passed to score engine
The system SHALL pass Match Format, Set Format, Tiebreak Format, Deuce Format, and Initial Server to the score engine as `MatchConfig`. Player names, surface, and date are metadata and are not consumed by the score engine.

### Requirement: Persistence on start
The system SHALL save the match config and metadata to local storage immediately when Start Match is tapped.

#### Scenario: Match persists after app close
- GIVEN the tracker has tapped Start Match with valid inputs
- WHEN the app is closed and reopened
- THEN the match appears in the Match List as in-progress with the correct config

### Requirement: Config is immutable after start
The system SHALL fix the match config (format, surface, date, player names, initial server) once the match starts. No mid-match editing is permitted.

### Requirement: Navigation on start
The system SHALL navigate to the Live Tracking screen immediately after Start Match is tapped successfully.

## Test Cases

- Form cannot be submitted with Player A Name empty
- Form cannot be submitted with Player B Name empty
- Form cannot be submitted without Initial Server selected
- Form can be submitted with only Player A Name, Player B Name, and Initial Server (all other fields use defaults)
- Date field defaults to today's date
- Match Format defaults to Best of 3
- Set Format defaults to Standard
- Deuce Format defaults to Standard deuce
- Surface field is optional — submitting without it is valid
- Tapping Start Match with valid inputs creates a match and navigates to Live Tracking
- The created match appears in the Match List as in-progress
- The match config persists across an app close and reopen
- The match config cannot be changed after the match has started
