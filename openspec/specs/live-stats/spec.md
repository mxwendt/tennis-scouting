# live-stats Specification

## Purpose

The live stats panel shows a condensed, always up-to-date statistical summary during the match. It is collapsible so the tracker can focus on point entry when needed. All statistics update automatically after every saved point. It gives the coach or tracker a quick read on the match state without leaving the Live Tracking screen.

## Requirements

### Requirement: Six stats displayed
The system SHALL display the following six statistics side by side for both players:

| Stat | Description |
|---|---|
| 1st Serve % | First serves in ÷ total first serve attempts |
| 1st Serve Points Won | Points won when first serve is in (%) |
| 2nd Serve Points Won | Points won on second serve, excluding double faults (%) |
| Winners | Total tagged winners (including auto-tagged aces and serve winners) |
| Unforced Errors | Total tagged unforced errors (including auto-tagged double faults) |
| Break Points Won | Break points converted ÷ total opportunities (shown as fraction, e.g. 2/3) |

### Requirement: Auto-update
The system SHALL refresh all six statistics immediately after every saved point, derived from the score engine and point log.

### Requirement: Collapsible panel
The system SHALL allow the panel to be collapsed and expanded independently of point entry. The collapsed state hides the stats to maximise space for point entry.

### Requirement: Derived from point log
The system SHALL derive all statistics from the point log via the score engine. No separate stat counters are maintained that could drift out of sync.

## Test Cases

- All six stats are shown for both players simultaneously
- Stats update immediately after every saved point
- 1st Serve % correctly counts first serves in vs total first serve attempts (a fault followed by any second serve outcome counts as one first serve attempt)
- 1st Serve Points Won correctly counts only points won when the first serve was in
- 2nd Serve Points Won excludes double faults from the denominator
- Winners count includes auto-tagged aces and serve winners plus manually tagged rally winners
- Unforced Errors count includes auto-tagged double faults plus manually tagged rally errors
- Break Points Won is shown as a fraction (e.g. 2/3), not a percentage
- Panel can be collapsed to hide all stats
- Panel can be expanded to show all stats
- Stats are independently accurate for Player A and Player B
