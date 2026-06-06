# live-tracking Specification

## Purpose

The Live Tracking screen is the primary working environment for the tracker during a match. It hosts the point entry panel, the persistent score display, and the collapsible live stats panel. It is navigated to immediately after Match Setup and remains active for the duration of the match. The screen is designed for fast, low-distraction data entry usable with one hand on a phone outdoors.

## Requirements

### Requirement: Screen layout
The system SHALL present the Live Tracking screen as a vertically stacked layout: live score display at the top, point entry panel in the middle, and a footer at the bottom.

### Requirement: Footer — between points
The system SHALL show a single full-width View summary button in the footer when no point tracking is in progress (after Save point, before the tracker starts the next point).

### Requirement: Footer — tracking in progress
The system SHALL replace the View summary button with two equal-width buttons — Undo and Restart — in the footer as soon as point tracking has started.

#### Scenario: Footer switches to Undo / Restart
- GIVEN the tracker is between points and the footer shows View summary
- WHEN the tracker taps any button in Step 1 or Step 2
- THEN the footer switches to show Undo and Restart

#### Scenario: Footer switches back after Save point
- GIVEN tracking is in progress and the footer shows Undo and Restart
- WHEN the tracker taps Save point
- THEN the point is committed and the footer switches back to View summary

### Requirement: View summary button
The system SHALL open the Match Summary overlay when View summary is tapped.

### Requirement: Automatic set-end and match-end summary
The system SHALL display the Match Summary overlay automatically when a set ends or the match ends. The tracker SHALL be able to dismiss it with a single tap to continue to the next set.

#### Scenario: Set ends automatically
- GIVEN a set has just been won
- WHEN the match state updates
- THEN the Match Summary overlay appears automatically over the Live Tracking screen

#### Scenario: Tracker dismisses set-end summary
- GIVEN the Match Summary overlay is shown after a set ends
- WHEN the tracker taps to dismiss
- THEN the overlay closes and the point entry panel is ready for the next set

### Requirement: Usability constraints
The system SHALL ensure all tappable buttons are at least 60×60 pixels. The screen SHALL function with one-handed use on a mobile phone.

## Test Cases

- Footer shows View summary between points
- Footer shows Undo and Restart once tracking has started
- Footer switches back to View summary after Save point
- View summary button opens the Match Summary overlay
- Match Summary overlay appears automatically when a set ends
- Match Summary overlay appears automatically when the match ends
- Tapping the Match Summary overlay dismisses it and the next point entry begins
- All tappable buttons are at least 60×60px
- Screen is usable with one hand on a mobile device
