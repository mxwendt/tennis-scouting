# point-entry Specification

## Purpose

Point Entry is the core interaction loop of the app. The tracker records every point through a fixed four-step sequence: who is serving, what happened on the serve, who won the point (rally path only), and the rally result. The flow is designed to be completable in under 3 taps in under 3 seconds. Completed steps collapse into a summary line; upcoming steps appear as muted placeholders. All steps for the current point can be reviewed and corrected before saving. This spec covers all four steps as a single unified flow.

## Requirements

### Requirement: Four-step flow
The system SHALL present point entry as a fixed four-step sequence: Step 1 (Who is serving?), Step 2 (Serve result), Step 3 (Who won the point? — rally path only), Step 4 (Rally result).

### Requirement: Step collapse behaviour
The system SHALL collapse a completed step into a single summary line showing the selected value and a Change link. Completed steps SHALL always be re-expandable by tapping them.

---

### Requirement: Step 1 — auto-selection
The system SHALL auto-select the current server in Step 1 based on the score engine's serving rotation. Step 1 SHALL be pre-collapsed at the start of every point — the tracker rarely needs to interact with it.

#### Scenario: First point of the match
- GIVEN the match has just started
- WHEN the tracker views Step 1
- THEN the initial server from Match Setup is pre-selected and the step is collapsed

#### Scenario: Subsequent points
- GIVEN a point has just been saved
- WHEN the next point begins
- THEN Step 1 is collapsed with the correct server derived by the score engine

### Requirement: Step 1 — override
The system SHALL allow the tracker to expand Step 1 and override the auto-selected server.

#### Scenario: Override accepted
- GIVEN the tracker taps the collapsed Step 1
- WHEN the tracker taps the non-auto-selected player in the expanded view
- THEN that player is recorded as the server and Step 1 collapses

#### Scenario: Override cancelled
- GIVEN the tracker has expanded Step 1
- WHEN the tracker taps the already-selected player
- THEN Step 1 collapses with no change to the server

### Requirement: Step 1 — tracking trigger
The system SHALL count an active tap of a player button in Step 1 as starting point tracking. Auto-collapsing Step 1 alone SHALL NOT start tracking.

### Requirement: Step 1 — relationship to Step 2
Step 2 SHALL open automatically when Step 1 is auto-collapsed at the start of a new point. If the tracker overrides Step 1, Step 2 remains open and waiting.

---

### Requirement: Step 2 — serve outcome buttons
The system SHALL present five fixed serve outcome buttons that never shift layout, regardless of serve state.

| Button | Default state | Colour | Description |
|---|---|---|---|
| Serve winner | Always enabled | Green | Serve touched but not returned — server wins |
| Ace | Always enabled | Green | Serve not touched — server wins |
| Fault | Enabled until tapped | Neutral | First serve fault — transitions to second serve |
| Double fault | Disabled until Fault tapped | Red | Second serve fault — receiver wins |
| In — rally | Always enabled | Neutral, full width | Rally begins — advances to Step 3 |

### Requirement: Step 2 — fault flow
The system SHALL handle first and second serve in a single step without layout changes. Tapping Fault SHALL disable Fault and enable Double fault. Tapping the now-disabled Fault button SHALL reverse the fault, re-enabling Fault and disabling Double fault.

#### Scenario: Fault tapped
- GIVEN the tracker taps Fault on the first serve
- WHEN the button state updates
- THEN Fault becomes disabled and Double fault becomes enabled; layout is unchanged

#### Scenario: Fault reversed by tapping disabled Fault
- GIVEN Fault has been tapped and the Fault button is now disabled
- WHEN the tracker taps the disabled Fault button
- THEN the fault is reversed: Fault becomes enabled, Double fault becomes disabled

### Requirement: Step 2 — point endings
The system SHALL immediately end the point and advance to Step 4 when Ace, Serve winner, or Double fault is tapped. In — rally SHALL advance to Step 3. Tapping Fault alone SHALL NOT end the point or advance the flow.

### Requirement: Step 2 — tracking trigger
The system SHALL count any tap in Step 2 as starting point tracking.

### Requirement: Step 2 — let serves
The system SHALL make no provision for let serves. The tracker ignores a let and enters the replayed serve instead. No let button exists.

---

### Requirement: Step 3 — rally winner selection
The system SHALL show Step 3 only after In — rally is selected in Step 2. The tracker SHALL select either Player A or Player B as the point winner. This step is required on the rally path.

#### Scenario: Step 3 appears after In — rally
- GIVEN the tracker taps In — rally in Step 2
- WHEN Step 3 opens
- THEN both player buttons are shown as tappable

#### Scenario: Step 3 selection advances flow
- GIVEN Step 3 is open
- WHEN the tracker taps either player
- THEN Step 3 collapses and Step 4 opens

---

### Requirement: Step 4 — serve path (auto-tag)
The system SHALL auto-tag serve-ending points and show only a Save point button on the serve path. No tag buttons are shown.

| Serve outcome | Auto-tag | Credited to |
|---|---|---|
| Ace | Winner | Server |
| Serve winner | Winner | Server |
| Double fault | Unforced error | Server |

### Requirement: Step 4 — rally path (optional tags)
The system SHALL show two optional ghost-style toggle tag buttons and a Save point button on the rally path.

| Tag | Subline | Meaning |
|---|---|---|
| Winner | by [winning player's name] | The winning player hit an outright winner |
| Unforced error | by [losing player's name] | The losing player made an unforced error |

#### Scenario: Tag selected and deselected
- GIVEN the tracker is on the rally path in Step 4
- WHEN the tracker taps Winner
- THEN Winner is selected; tapping it again deselects it

#### Scenario: Tags are mutually exclusive
- GIVEN the tracker has selected Winner
- WHEN the tracker taps Unforced error
- THEN Unforced error is selected and Winner is automatically deselected

### Requirement: Step 4 — untagged rally points
The system SHALL treat rally points saved without a tag as forced errors in statistics. No distinction is surfaced to the user.

### Requirement: Step 4 — Save point
The system SHALL require a Save point tap to commit any point on both the serve path and the rally path. Save point SHALL always be enabled regardless of tag selection.

#### Scenario: Point committed
- GIVEN the tracker taps Save point
- WHEN the point is committed to the log
- THEN the entry panel resets with Step 1 pre-selected for the next server and Step 2 open; the footer switches to View summary

---

### Requirement: Undo within point entry
The system SHALL step back one tap within the current point entry when Undo is tapped.

- On rally path, Step 4 with tag selected: deselects the active tag
- On rally path, Step 4 with no tag selected: returns to Step 3
- On serve path, Step 4: returns to Step 2
- In Step 1 after an override: returns Step 1 to its auto-selected collapsed state and switches footer to View summary

### Requirement: Restart
The system SHALL discard all taps for the current point and return to the initial state when Restart is tapped: Step 1 collapsed with auto-selection, Step 2 open.

## Test Cases

**Step 1 — Who is serving?**
- Step 1 is pre-selected with the correct initial server from the very first point
- Step 1 is collapsed and pre-selected at the start of every subsequent point
- Auto-selected server alternates correctly after each game
- Auto-selected server is correct at the start of a tiebreak (player who did not serve the last game)
- Auto-selected server alternates every 2 points within a tiebreak
- Auto-selected server is correct at the start of the set following a tiebreak
- Tapping the collapsed Step 1 expands it and shows both player buttons
- Tapping the already-selected player collapses the step with no change
- Tapping the other player overrides the server and triggers tracking started
- Auto-collapsed Step 1 does not trigger the tracking started state
- Tapping Undo after overriding the server returns Step 1 to its auto-selected collapsed state

**Step 2 — Serve result**
- Tapping Serve winner ends the point and attributes it to the server
- Tapping Ace ends the point and attributes it to the server
- Double fault is disabled until Fault is tapped
- Tapping Fault enables Double fault and disables Fault; layout does not shift
- Tapping the disabled Fault button reverses the fault (Fault re-enabled, Double fault disabled)
- Tapping Double fault after Fault ends the point and attributes it to the receiver
- Tapping In — rally does not end the point and advances to Step 3
- Button layout is identical in first serve and second serve states
- Any tap in Step 2 triggers the tracking started state

**Step 3 — Who won the point?**
- Step 3 only appears after In — rally
- Tapping either player collapses Step 3 and advances to Step 4

**Step 4 — Rally result**
- Ace, Serve winner, and Double fault reach Step 4 directly, skipping Step 3
- Serve path shows only Save point — no tag buttons
- Ace is auto-tagged as a Winner for the server
- Serve winner is auto-tagged as a Winner for the server
- Double fault is auto-tagged as an Unforced Error for the server
- Auto-tagged aces appear in the Winners stat for the server
- Auto-tagged serve winners appear in the Winners stat for the server
- Auto-tagged double faults appear in the Unforced Errors stat for the server
- Rally path shows both tag buttons and Save point
- Tapping Winner selects it; tapping again deselects it
- Tapping Unforced error selects it; tapping again deselects it
- Selecting one tag deselects the other
- Untagged rally point is recorded as a forced error in statistics
- Save point commits the point and resets the entry panel
- Save point is always enabled regardless of tag selection
- Undo on rally path with tag selected deselects the tag
- Undo on rally path with no tag selected returns to Step 3
- Undo on serve path returns to Step 2
- Restart from any step resets the panel to its initial state
