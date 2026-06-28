module MatchSummary exposing (Mode(..), view)

import Html exposing (Html, button, div, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Match exposing (Match, Player(..))
import ScoreEngine exposing (MatchState, MatchStatus(..), deriveMatchState)
import Stats exposing (MatchStats, compute)


{-| Controls the header shown at the top of the summary:

  - `FromLiveTracking msg` — amber "Continue" button (user came from live tracking)
  - `FromMatchList msg` — grey "← Matches" back link (user came from the match list)

-}
type Mode msg
    = FromLiveTracking msg
    | FromMatchList msg


view : Mode msg -> Match -> Html msg
view mode match =
    let
        statsA =
            compute PlayerA match.config match.points

        statsB =
            compute PlayerB match.config match.points

        matchState =
            deriveMatchState match.config match.points

        nameA =
            match.metadata.playerAName

        nameB =
            match.metadata.playerBName

        header =
            case mode of
                FromLiveTracking onContinue ->
                    viewLiveHeader onContinue

                FromMatchList onBack ->
                    viewListHeader onBack
    in
    div [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto flex flex-col" ]
        [ header
        , div [ class "flex-1 overflow-y-auto" ]
            [ viewContent statsA statsB matchState nameA nameB ]
        ]



-- HEADERS


viewLiveHeader : msg -> Html msg
viewLiveHeader onContinue =
    div [ class "sticky top-0 z-10 bg-gray-900 border-b border-gray-700 flex items-center justify-between py-4 px-5" ]
        [ div [ class "text-base font-bold" ] [ text "Match Summary" ]
        , button
            [ onClick onContinue
            , class "bg-amber-400 text-gray-900 border-0 rounded-md py-2 px-4 text-sm font-semibold cursor-pointer"
            ]
            [ text "Continue" ]
        ]


viewListHeader : msg -> Html msg
viewListHeader onBack =
    div [ class "sticky top-0 z-10 bg-gray-900 border-b border-gray-700 flex items-center justify-between py-4 px-5" ]
        [ button
            [ onClick onBack
            , class "bg-transparent border-0 rounded-md text-gray-400 text-sm font-semibold cursor-pointer py-2"
            ]
            [ text "← Matches" ]
        , div [ class "text-base font-bold" ] [ text "Match Summary" ]
        , div [ class "w-20" ] []
        ]



-- CONTENT


viewContent : MatchStats -> MatchStats -> MatchState -> String -> String -> Html msg
viewContent statsA statsB matchState nameA nameB =
    div []
        [ viewPlayerNames nameA nameB
        , viewScoreSection matchState
        , viewServeSection statsA statsB
        , viewReturnSection statsA statsB
        , viewRallySection statsA statsB
        , viewPointsSection statsA statsB
        ]


viewPlayerNames : String -> String -> Html msg
viewPlayerNames nameA nameB =
    div [ class "flex items-center bg-gray-800 px-4 py-3 border-b border-gray-700" ]
        [ div [ class "w-5/12 text-right text-sm font-semibold text-amber-400 truncate" ] [ text nameA ]
        , div [ class "w-2/12 text-center text-xs text-gray-500" ] [ text "vs" ]
        , div [ class "w-5/12 text-sm font-semibold text-amber-400 truncate" ] [ text nameB ]
        ]



-- SCORE SECTION


viewScoreSection : MatchState -> Html msg
viewScoreSection matchState =
    let
        activeSetNumber =
            List.length matchState.setScores + 1

        activeSetRow =
            case matchState.matchStatus of
                InProgress ->
                    viewStatRow
                        ("Set " ++ String.fromInt activeSetNumber)
                        (String.fromInt matchState.gameScore.playerA)
                        (String.fromInt matchState.gameScore.playerB)

                WonBy _ ->
                    text ""
    in
    div []
        [ viewSectionHeader "Score"
        , viewSetScoreRows matchState
        , activeSetRow
        , viewTotalGamesRow matchState
        ]


viewSetScoreRows : MatchState -> Html msg
viewSetScoreRows matchState =
    let
        allSets =
            matchState.setScores
    in
    div []
        (List.indexedMap
            (\i setScore ->
                viewStatRow
                    ("Set " ++ String.fromInt (i + 1))
                    (String.fromInt setScore.playerA)
                    (String.fromInt setScore.playerB)
            )
            allSets
        )


viewTotalGamesRow : MatchState -> Html msg
viewTotalGamesRow matchState =
    let
        totalA =
            List.sum (List.map .playerA matchState.setScores)
                + matchState.gameScore.playerA

        totalB =
            List.sum (List.map .playerB matchState.setScores)
                + matchState.gameScore.playerB
    in
    viewStatRow "Total Games" (String.fromInt totalA) (String.fromInt totalB)



-- SERVE SECTION


viewServeSection : MatchStats -> MatchStats -> Html msg
viewServeSection statsA statsB =
    div []
        [ viewSectionHeader "Serve"
        , viewStatRow "1st Serve %" (pct statsA.firstServeIn statsA.firstServeAttempts) (pct statsB.firstServeIn statsB.firstServeAttempts)
        , viewStatRow "1st Serve Pts Won" (pct statsA.firstServePointsWon statsA.firstServePointsPlayed) (pct statsB.firstServePointsWon statsB.firstServePointsPlayed)
        , viewStatRow "2nd Serve Pts Won" (pct statsA.secondServePointsWon statsA.secondServePointsPlayed) (pct statsB.secondServePointsWon statsB.secondServePointsPlayed)
        , viewStatRow "Aces" (String.fromInt statsA.aces) (String.fromInt statsB.aces)
        , viewStatRow "Double Faults" (String.fromInt statsA.doubleFaults) (String.fromInt statsB.doubleFaults)
        , viewStatRow "Service Games Won" (pct statsA.serviceGamesWon statsA.serviceGamesPlayed) (pct statsB.serviceGamesWon statsB.serviceGamesPlayed)
        ]



-- RETURN SECTION


viewReturnSection : MatchStats -> MatchStats -> Html msg
viewReturnSection statsA statsB =
    div []
        [ viewSectionHeader "Return"
        , viewStatRow "Return Pts Won" (pct statsA.returnPointsWon statsA.returnPointsPlayed) (pct statsB.returnPointsWon statsB.returnPointsPlayed)
        , viewStatRow "Break Pts Won" (fraction statsA.breakPointsWon statsA.breakPointOpportunities) (fraction statsB.breakPointsWon statsB.breakPointOpportunities)
        , viewStatRow "Break Pts Saved" (fraction statsA.breakPointsSaved statsA.breakPointsFaced) (fraction statsB.breakPointsSaved statsB.breakPointsFaced)
        ]



-- RALLY SECTION


viewRallySection : MatchStats -> MatchStats -> Html msg
viewRallySection statsA statsB =
    div []
        [ viewSectionHeader "Rally"
        , viewStatRow "Winners" (String.fromInt statsA.winners) (String.fromInt statsB.winners)
        , viewStatRow "Unforced Errors" (String.fromInt statsA.unforcedErrors) (String.fromInt statsB.unforcedErrors)
        , viewStatRow "Forced Errors" (String.fromInt statsA.forcedErrors) (String.fromInt statsB.forcedErrors)
        , viewStatRow "Winner / UE Ratio" (ratio statsA.winners statsA.unforcedErrors) (ratio statsB.winners statsB.unforcedErrors)
        ]



-- POINTS SECTION


viewPointsSection : MatchStats -> MatchStats -> Html msg
viewPointsSection statsA statsB =
    div [ class "mb-8" ]
        [ viewSectionHeader "Points"
        , viewStatRow "Points Won" (String.fromInt statsA.totalPointsWon) (String.fromInt statsB.totalPointsWon)
        , viewStatRow "Points Won %" (pct statsA.totalPointsWon statsA.totalPointsPlayed) (pct statsB.totalPointsWon statsB.totalPointsPlayed)
        , viewStatRow "Total Points" (String.fromInt statsA.totalPointsPlayed) (String.fromInt statsB.totalPointsPlayed)
        ]



-- LAYOUT PRIMITIVES


viewSectionHeader : String -> Html msg
viewSectionHeader title =
    div [ class "px-4 py-2 bg-gray-800 text-xs font-semibold uppercase tracking-wider text-gray-400 border-b border-gray-700" ]
        [ text title ]


viewStatRow : String -> String -> String -> Html msg
viewStatRow label valueA valueB =
    div [ class "flex items-center px-4 py-3 border-b border-gray-800" ]
        [ div [ class "w-5/12 text-right text-gray-50 font-medium text-sm" ] [ text valueA ]
        , div [ class "w-2/12 text-center text-xs text-gray-500 leading-tight" ] [ text label ]
        , div [ class "w-5/12 text-gray-50 font-medium text-sm" ] [ text valueB ]
        ]



-- FORMAT HELPERS


{-| Format a percentage. Returns "—" when denominator is zero.
-}
pct : Int -> Int -> String
pct num denom =
    if denom == 0 then
        "—"

    else
        String.fromInt (round (100 * toFloat num / toFloat denom)) ++ "%"


{-| Format as a fraction string, e.g. "3/5".
-}
fraction : Int -> Int -> String
fraction num denom =
    String.fromInt num ++ "/" ++ String.fromInt denom


{-| Format a ratio to one decimal place. Returns "—" when denominator is zero.
-}
ratio : Int -> Int -> String
ratio num denom =
    if denom == 0 then
        "—"

    else
        let
            r =
                toFloat num / toFloat denom

            tenths =
                round (r * 10)

            whole =
                tenths // 10

            dec =
                modBy 10 tenths
        in
        if dec == 0 then
            String.fromInt whole

        else
            String.fromInt whole ++ "." ++ String.fromInt dec
