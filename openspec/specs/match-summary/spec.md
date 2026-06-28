# match-summary Specification

## Purpose

The Match Summary presents a full statistical breakdown of the match, accessible at any time between points via the Live Tracking footer button and in read-only mode for completed matches from the Match List. It is the primary output the coach reviews during changeovers and after the match. All statistics are derived from the point log and are always accurate.

## Requirements

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
- The full set-by-set score for all completed sets (e.g. 7–5, 6–3).
- Total games won for each player (sum of all sets including any in-progress set).

#### Scenario: Active set score shown during match
- **WHEN** the match is in progress and the summary is viewed
- **THEN** the current set's game score appears after the completed sets and before Total Games

#### Scenario: Active set score omitted after match ends
- **WHEN** the match is complete and the summary is viewed
- **THEN** no active set row is shown; only completed set scores and total games appear

### Requirement: Serve statistics
The system SHALL display the following serve statistics for both players:

| Stat | Description |
|---|---|
| First Serve % | First serves in ÷ total first serve attempts |
| First Serve Points Won % | Points won when first serve is in |
| Second Serve Points Won % | Points won on second serve (excludes double faults from denominator) |
| Aces | Total aces |
| Double Faults | Total double faults |
| Service Games Won % | Service games held ÷ total service games played |

### Requirement: Return statistics
The system SHALL display the following return statistics for both players:

| Stat | Description |
|---|---|
| Return Points Won % | Points won when returning (first and second serve combined) |
| Break Points Won | Converted ÷ total opportunities (e.g. 3/5) |
| Break Points Saved | Saved ÷ total faced |

### Requirement: Rally statistics
The system SHALL display the following rally statistics for both players:

| Stat | Description |
|---|---|
| Winners | Total tagged winners (including auto-tagged aces and serve winners) |
| Unforced Errors | Total tagged unforced errors (including auto-tagged double faults) |
| Forced Errors | Rally points saved without a Winner or Unforced Error tag |
| Winner / UE Ratio | Winners ÷ unforced errors |

### Requirement: Points summary
The system SHALL display total points played and total points won (count and percentage) for both players.

### Requirement: Accuracy
The system SHALL derive all summary statistics from the point log via the score engine. No stat can drift out of sync with the raw data.

## Test Cases

- View summary button navigates to the Match Summary page
- Continue button in the summary header returns to the Live Tracking screen
- Summary is accessible in read-only mode from the Match List for completed matches
- In-progress matches open the Live Tracking screen from the Match List
- Active set game score appears in the Score section when the match is in progress
- Active set row is absent when the match is complete
- Set-by-set score is shown correctly at the top
- First Serve % is accurate
- First Serve Points Won % is accurate (only counts first-serve-in points)
- Second Serve Points Won % excludes double faults from the denominator
- Aces count is accurate
- Double Faults count is accurate
- Service Games Won % is accurate
- Return Points Won % includes both first and second serve return points
- Break Points Won is shown as a fraction (e.g. 3/5)
- Break Points Saved is shown as a fraction
- Winners include auto-tagged aces and serve winners plus manually tagged rally winners
- Unforced Errors include auto-tagged double faults plus manually tagged rally errors
- Forced Errors are rally points with no tag applied
- Winner / UE Ratio is computed correctly
- Total points played and won are accurate for both players
- All stats are independently correct for Player A and Player B
