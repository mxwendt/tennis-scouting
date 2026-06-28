# finish-match Specification

## Purpose
TBD - created by archiving change finish-match. Update Purpose after archive.
## Requirements
### Requirement: Match stores a finished flag
The `Match` record SHALL include a `finished : Bool` field. This field SHALL be serialised to and deserialised from localStorage. When the field is absent in stored data (legacy records), it SHALL deserialise as `False`.

#### Scenario: New match has finished = False
- **WHEN** a match is created via the setup flow
- **THEN** `match.finished` is `False`

#### Scenario: Legacy data without finished field loads correctly
- **WHEN** the app loads localStorage data that does not contain a `finished` field on a match record
- **THEN** that match is loaded with `finished = False`

---

### Requirement: Finish button is available during live tracking
The LiveTracking screen SHALL show a Finish button when `trackingStarted` is `True` (at least one point has been recorded). The Finish button SHALL NOT be visible before any point is recorded.

#### Scenario: Finish button hidden before first point
- **WHEN** the user is on the LiveTracking screen and no points have been recorded yet
- **THEN** the Finish button is not visible

#### Scenario: Finish button visible after first point
- **WHEN** the user is on the LiveTracking screen and at least one point has been recorded
- **THEN** the Finish button is visible

---

### Requirement: Finish action marks match as finished and navigates to summary
When the user taps Finish in live tracking, the system SHALL set `match.finished = True`, persist the updated match to localStorage, and navigate to `MatchSummaryPage`.

#### Scenario: Tapping Finish saves and navigates
- **WHEN** the user taps the Finish button during live tracking
- **THEN** `match.finished` is set to `True`, the state is saved to localStorage, and the Match Summary screen is shown

#### Scenario: Match summary after finish shows correct status
- **WHEN** the user arrives at Match Summary via the Finish action
- **THEN** the summary reflects the current score at the moment of finishing and a Resume button is visible

---

### Requirement: Match list shows "Stopped" for manually finished in-progress matches
In the match list, a match with `finished = True` and a score-engine status of `InProgress` SHALL display the label `"Stopped"`. A match with `finished = True` and a score-engine status of `WonBy` SHALL display `"Final"`. A match with `finished = False` and score `InProgress` SHALL display `"In Progress"`.

#### Scenario: Manually finished mid-match shows Stopped
- **WHEN** `match.finished` is `True` and the score engine reports `InProgress`
- **THEN** the match list row shows the label "Stopped"

#### Scenario: Naturally finished match still shows Final
- **WHEN** `match.finished` is `False` and the score engine reports `WonBy`
- **THEN** the match list row shows the label "Final"

#### Scenario: Active match shows In Progress
- **WHEN** `match.finished` is `False` and the score engine reports `InProgress`
- **THEN** the match list row shows the label "In Progress"

---

### Requirement: Opening a manually finished match routes to summary
When the user opens a match from the list and `match.finished` is `True`, the system SHALL navigate to `MatchSummaryPage` regardless of the score-engine result.

#### Scenario: Manually finished match opens to summary
- **WHEN** the user taps a match row where `match.finished` is `True`
- **THEN** the Match Summary screen is shown

#### Scenario: Routing priority — finished flag beats score engine
- **WHEN** `match.finished` is `True` and the score engine also reports `InProgress`
- **THEN** the Match Summary screen is shown (not LiveTracking)

---

### Requirement: Resume button is shown only for manually finished matches
`MatchSummaryPage` SHALL render a Resume button when `match.finished` is `True`. When `match.finished` is `False` (including naturally-won matches), no Resume button SHALL be shown.

#### Scenario: Resume visible for manually finished match
- **WHEN** the Match Summary screen is shown and `match.finished` is `True`
- **THEN** a Resume button is visible

#### Scenario: Resume not visible for naturally won match
- **WHEN** the Match Summary screen is shown and `match.finished` is `False` (score engine reports `WonBy`)
- **THEN** no Resume button is shown

---

### Requirement: Resume action marks match as not finished and opens live tracking
When the user taps Resume, the system SHALL immediately set `match.finished = False`, persist the updated match to localStorage, and navigate to `LiveTrackingPage` for that match. No confirmation step is required.

#### Scenario: Resume saves and navigates to live tracking
- **WHEN** the user taps the Resume button
- **THEN** `match.finished` is set to `False`, the state is saved to localStorage, and the LiveTracking screen is shown for that match

#### Scenario: Reopening a resumed match from the list opens live tracking
- **WHEN** the user resumes a match, returns to the match list, and taps the match again
- **THEN** the LiveTracking screen is shown (because `match.finished` is now `False` and score is `InProgress`)

