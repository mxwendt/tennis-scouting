# undo-restart Specification

## Purpose

Undo and Restart are recovery actions available while a point is being tracked. They allow the tracker to correct a mis-tap without losing their place or discarding too much work. Both are shown in the footer as soon as point tracking starts and disappear once the point is saved.

## Requirements

### Requirement: Undo — step back one tap
The system SHALL reverse the last tap within the current point entry when Undo is tapped. Undo SHALL behave differently depending on the current step.

#### Scenario: Undo a tag selection in Step 4 (rally path)
- GIVEN the tracker is on the rally path in Step 4 and has selected a tag
- WHEN the tracker taps Undo
- THEN the tag is deselected; the tracker remains in Step 4

#### Scenario: Undo from Step 4 with no tag (rally path)
- GIVEN the tracker is on the rally path in Step 4 with no tag selected
- WHEN the tracker taps Undo
- THEN Step 3 is reopened

#### Scenario: Undo from Step 4 (serve path)
- GIVEN the tracker is on the serve path in Step 4
- WHEN the tracker taps Undo
- THEN the flow returns to Step 2

#### Scenario: Undo a Step 1 server override
- GIVEN the tracker has overridden the server in Step 1
- WHEN the tracker taps Undo
- THEN Step 1 returns to its auto-selected collapsed state and the footer switches back to View summary

### Requirement: Restart — discard current point
The system SHALL discard all taps for the current point and return to the initial point entry state when Restart is tapped: Step 1 collapsed with auto-selected server, Step 2 open.

#### Scenario: Restart from any step
- GIVEN the tracker is at any step in the point entry flow
- WHEN the tracker taps Restart
- THEN all taps for the current point are discarded, Step 1 is collapsed with the auto-selected server, and Step 2 is open

### Requirement: Visibility
The system SHALL show Undo and Restart in the footer only when point tracking is in progress. Between points the footer SHALL show View summary instead.

### Requirement: Save point is final
The system SHALL NOT allow Undo or Restart to reverse a saved point. Once Save point is tapped and the point is committed to the log, these actions have no effect on it.

## Test Cases

- Undo and Restart are visible in the footer once tracking starts
- Undo and Restart are not visible between points (View summary is shown instead)
- Undo deselects the active tag on the rally path in Step 4
- Undo returns to Step 3 from Step 4 on the rally path when no tag is selected
- Undo returns to Step 2 from Step 4 on the serve path
- Undo returns Step 1 to auto-selected state after an override and switches footer back to View summary
- Restart discards all taps and resets the panel: Step 1 collapsed, Step 2 open
- Restart works correctly from Step 2, Step 3, and Step 4
- A saved point cannot be reversed with Undo or Restart
