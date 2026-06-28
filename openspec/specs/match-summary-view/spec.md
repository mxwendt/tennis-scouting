# match-summary-view Specification

## Purpose

The Match Summary View is the full-screen page that presents all match statistics. It is opened on demand from the Live Tracking footer or by tapping a completed match in the Match List. The header adapts to the entry point so the user is always returned to the right place.

## Requirements

### Requirement: Two-column player comparison layout
The system SHALL display all statistics in a two-column layout with one column per player, so both players' values for each stat are visible simultaneously at a glance.

#### Scenario: Stats displayed side by side
- **WHEN** the match summary is shown
- **THEN** Player A's and Player B's values appear in the same row for every stat

### Requirement: Stat sections with headers
The system SHALL group statistics under clearly labelled section headers: Score, Serve, Return, Rally, and Points.

#### Scenario: Sections are visually separated
- **WHEN** the match summary is shown
- **THEN** each of the five stat groups (Score, Serve, Return, Rally, Points) is preceded by a section header and visually distinct from adjacent groups

### Requirement: Scrollable content
The system SHALL allow the user to scroll through the full summary if it exceeds the viewport height, without cutting off any statistics.

#### Scenario: Full summary accessible on small screens
- **WHEN** the summary content is taller than the screen
- **THEN** the user can scroll to reach all sections

### Requirement: Context-aware header
The system SHALL display a header appropriate to how the summary was opened:

- When opened from the Live Tracking screen via the footer button, the header SHALL show a prominent amber **Continue** button that returns the tracker to live tracking.
- When opened from the Match List for a completed match, the header SHALL show a **← Matches** back link that returns to the match list.

#### Scenario: Continue button shown when opened from live tracking
- **WHEN** the tracker taps View summary during a live match
- **THEN** the summary header shows a "Continue" button

#### Scenario: Tapping Continue returns to live tracking
- **WHEN** the tracker taps Continue in the summary header
- **THEN** the app returns to the Live Tracking screen at the same point in the match

#### Scenario: Back link shown when opened from match list
- **WHEN** the user opens a completed match from the Match List
- **THEN** the summary header shows a "← Matches" back link

#### Scenario: Tapping back link returns to match list
- **WHEN** the user taps the back link on the summary page
- **THEN** the app navigates to the match list
