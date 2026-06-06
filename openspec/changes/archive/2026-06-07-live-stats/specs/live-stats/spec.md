## MODIFIED Requirements

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

#### Scenario: All six stats visible for both players
- **WHEN** the stats panel is expanded
- **THEN** all six statistics are shown simultaneously for both Player A and Player B

#### Scenario: First serve percentage calculation
- **WHEN** a player has recorded first-serve attempts (including faults followed by a second serve)
- **THEN** 1st Serve % = (first serves in) ÷ (total first serve attempts) as a percentage

#### Scenario: First serve points won calculation
- **WHEN** a player's first serve is in
- **THEN** 1st Serve Points Won counts only points won on those first-serve points

#### Scenario: Second serve points won excludes double faults
- **WHEN** a player has served second serves
- **THEN** 2nd Serve Points Won denominator excludes double faults

#### Scenario: Winners count includes auto-tagged events
- **WHEN** a point is recorded as an Ace, ServeWinner, or rally Winner tag
- **THEN** the winner's Winners count is incremented

#### Scenario: Unforced errors count includes double faults
- **WHEN** a point is recorded as DoubleFault or rally UnforcedError tag
- **THEN** the server's or tagging player's Unforced Errors count is incremented

#### Scenario: Break points shown as fraction
- **WHEN** Player A has converted 2 of 3 break-point opportunities
- **THEN** Break Points Won displays "2/3"

#### Scenario: Zero break point opportunities
- **WHEN** a player has had no break-point opportunities
- **THEN** Break Points Won displays "0/0"

#### Scenario: Stats are independent per player
- **WHEN** stats are computed
- **THEN** each statistic is computed separately for Player A and Player B

### Requirement: Auto-update
The system SHALL refresh all six statistics immediately after every saved point, derived from the score engine and point log.

#### Scenario: Stats update after point saved
- **WHEN** a point is saved
- **THEN** all six statistics for both players are updated immediately in the panel

### Requirement: Collapsible panel
The system SHALL allow the panel to be collapsed and expanded independently of point entry. The collapsed state hides the stats to maximise space for point entry.

#### Scenario: Collapse the panel
- **WHEN** the tracker taps the collapse toggle while the panel is expanded
- **THEN** all stats are hidden and only the panel header (with an expand affordance) is visible

#### Scenario: Expand the panel
- **WHEN** the tracker taps the expand toggle while the panel is collapsed
- **THEN** all six statistics for both players are shown again

#### Scenario: Panel default state
- **WHEN** the Live Tracking screen first loads
- **THEN** the stats panel is expanded by default

### Requirement: Derived from point log
The system SHALL derive all statistics from the point log via the score engine. No separate stat counters are maintained that could drift out of sync.

#### Scenario: Stats derived on each render
- **WHEN** the view renders
- **THEN** statistics are computed from the current point log, not from separate counters
