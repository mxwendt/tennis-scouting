# match-list Specification

## Purpose

The Match List is the opening screen of the app. It shows all saved matches — both in-progress and completed — and provides the entry point for starting a new match, resuming an existing one, or reviewing a past result. It is the first screen the tracker sees when they open the app.

## Requirements

### Requirement: Display all saved matches
The system SHALL display all saved matches as a scrollable list. Each match card SHALL show player names, date, and the current score (for in-progress matches) or final result (for completed matches).

### Requirement: New Match button
The system SHALL provide a prominent New Match button that navigates to the Match Setup screen.

#### Scenario: New match created
- GIVEN the tracker taps New Match and completes Match Setup
- WHEN Start Match is tapped
- THEN a new match appears in the Match List as in-progress with the correct player names and date

### Requirement: Resume in-progress match
The system SHALL allow the tracker to tap an in-progress match to navigate directly to the Live Tracking screen for that match with the full match state restored.

#### Scenario: Match resumed correctly
- GIVEN there is an in-progress match in the list
- WHEN the tracker taps it
- THEN the Live Tracking screen opens with the correct point log, score, and config restored

### Requirement: View completed match
The system SHALL allow the tracker to tap a completed match to view its Match Summary in read-only mode.

#### Scenario: Completed match summary
- GIVEN there is a completed match in the list
- WHEN the tracker taps it
- THEN the Match Summary is shown in read-only mode

### Requirement: Discard match
The system SHALL provide a Discard option on every match that permanently deletes it after the tracker confirms a prompt.

#### Scenario: Discard confirmed
- GIVEN the tracker taps Discard on a match
- WHEN the confirmation prompt is accepted
- THEN the match is permanently deleted and removed from the list

#### Scenario: Discard cancelled
- GIVEN the tracker taps Discard on a match
- WHEN the confirmation prompt is dismissed
- THEN the match remains in the list unchanged

### Requirement: Persistence
The system SHALL persist all match data in local storage. The match list SHALL correctly reflect all matches after an app close and reopen.

### Requirement: Empty state
The system SHALL display an appropriate empty state when no matches have been saved.

## Test Cases

- Match list shows all saved matches on app open
- Each match card shows player names, date, and score or result
- In-progress matches show the current score
- Completed matches show the final result
- New Match button navigates to Match Setup
- Tapping an in-progress match resumes it in the Live Tracking screen
- Correct match state is restored on resume (score, point log, config, current server)
- Tapping a completed match opens the Match Summary in read-only view
- Discard option is present on every match card
- Confirming discard permanently removes the match from the list
- Cancelling discard leaves the match unchanged
- Match list persists correctly after app close and reopen
- Empty state is displayed when no matches exist
