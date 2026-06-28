## REMOVED Requirements

### Requirement: Auto-display at set end
**Reason**: Replaced by on-demand navigation. The tracker opens the summary deliberately via the footer button; auto-interrupting point entry at set end was removed.
**Migration**: N/A — no stored data affected.

### Requirement: Auto-display at match end
**Reason**: Same as above. The summary is accessible on demand from the footer button or from the Match List.
**Migration**: N/A — no stored data affected.

## MODIFIED Requirements

### Requirement: On-demand access between points
The system SHALL allow the tracker to open the Match Summary at any time between points by tapping View summary in the footer. Tapping the button navigates to the full Match Summary page. The tracker returns to live tracking via the Continue button in the summary header.

#### Scenario: View summary button navigates to summary page
- **WHEN** the tracker taps View summary in the footer
- **THEN** the app navigates to the Match Summary page

#### Scenario: Continue returns to live tracking
- **WHEN** the tracker taps Continue in the Match Summary header
- **THEN** the app returns to the Live Tracking screen at the same point in the match

### Requirement: Read-only access from Match List
The system SHALL allow the Match Summary to be viewed in read-only mode from the Match List for completed matches. Tapping a completed match in the match list SHALL navigate directly to the Match Summary page. In-progress matches SHALL continue to open the Live Tracking screen.

#### Scenario: Completed match opens summary
- **WHEN** the user taps a completed match in the match list
- **THEN** the app navigates to the Match Summary page for that match

#### Scenario: In-progress match opens live tracking
- **WHEN** the user taps an in-progress match in the match list
- **THEN** the app navigates to the Live Tracking screen for that match

### Requirement: Score summary
The system SHALL display the following in the Score section:

- The game score of the active (in-progress) set, shown after any completed sets and before the Total Games row. This row is omitted when the match is complete.
- The full set-by-set score for all completed sets.
- Total games won for each player (sum of all sets including the current in-progress set).

#### Scenario: Active set score shown during match
- **WHEN** the match is in progress and the summary is viewed
- **THEN** the current set's game score appears after the completed sets and before Total Games

#### Scenario: Active set score omitted after match ends
- **WHEN** the match is complete and the summary is viewed
- **THEN** no active set row is shown; only completed set scores and total games appear
