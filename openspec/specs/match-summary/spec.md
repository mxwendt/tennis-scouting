# match-summary Specification

## Purpose

The Match Summary presents a full statistical breakdown of the match, accessible at any time between points and shown automatically at the end of each set and at match end. It is the primary output the coach reviews during changeovers and after the match. All statistics are derived from the point log and are always accurate.

## Requirements

### Requirement: Auto-display at set end
The system SHALL display the Match Summary as a full-screen overlay automatically when a set ends.

#### Scenario: Set ends — summary appears
- GIVEN a set has just been won
- WHEN the match state updates
- THEN the Match Summary overlay appears automatically over the Live Tracking screen

#### Scenario: Tracker dismisses set-end summary
- GIVEN the Match Summary overlay is shown after a set ends
- WHEN the tracker taps to dismiss
- THEN the overlay closes and point entry begins for the next set

### Requirement: Auto-display at match end
The system SHALL display the Match Summary overlay automatically when the match ends.

### Requirement: On-demand access between points
The system SHALL allow the tracker to open the Match Summary at any time between points by tapping View summary in the footer.

### Requirement: Read-only access from Match List
The system SHALL allow the Match Summary to be viewed in read-only mode from the Match List for completed matches.

### Requirement: Score summary
The system SHALL display the full set-by-set score at the top of the summary (e.g. 7–5, 6–3) and total games won for each player.

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

- Match Summary overlay appears automatically when a set ends
- Match Summary overlay appears automatically when the match ends
- Tapping the overlay dismisses it and point entry resumes (set-end case)
- View summary button opens the summary between points
- Summary is accessible in read-only mode from the Match List for completed matches
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
