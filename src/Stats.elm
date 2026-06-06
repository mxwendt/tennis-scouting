module Stats exposing (MatchStats, compute)

import Match exposing (MatchConfig, Player(..), Point, RallyTag(..), ServeOutcome(..), ServePhase(..))
import ScoreEngine exposing (deriveMatchState)


{-| Per-player match statistics derived from the point log.
-}
type alias MatchStats =
    { firstServeIn : Int
    , firstServeAttempts : Int
    , firstServePointsWon : Int
    , firstServePointsPlayed : Int
    , secondServePointsWon : Int
    , secondServePointsPlayed : Int
    , winners : Int
    , unforcedErrors : Int
    , breakPointsWon : Int
    , breakPointOpportunities : Int
    }


emptyStats : MatchStats
emptyStats =
    { firstServeIn = 0
    , firstServeAttempts = 0
    , firstServePointsWon = 0
    , firstServePointsPlayed = 0
    , secondServePointsWon = 0
    , secondServePointsPlayed = 0
    , winners = 0
    , unforcedErrors = 0
    , breakPointsWon = 0
    , breakPointOpportunities = 0
    }


{-| Derives all six statistics for a given player from the point log.

Break-point counts are taken from the score engine (which already accumulates
them during the fold); all other stats are computed by a single pass over the
point list.

-}
compute : Player -> MatchConfig -> List Point -> MatchStats
compute player config points =
    let
        matchState =
            deriveMatchState config points

        bps =
            case player of
                PlayerA ->
                    matchState.breakPoints.playerA

                PlayerB ->
                    matchState.breakPoints.playerB

        base =
            List.foldl (accumulatePoint player) emptyStats points
    in
    { base
        | breakPointsWon = bps.converted
        , breakPointOpportunities = bps.opportunities
    }


accumulatePoint : Player -> Point -> MatchStats -> MatchStats
accumulatePoint player point stats =
    let
        isServing =
            point.server == player
    in
    case point.outcome of
        Ace phase ->
            if isServing then
                stats
                    |> addFirstServeAttempt
                    |> addServePhaseStats phase True
                    |> addWinner

            else
                stats

        ServeWinner phase ->
            if isServing then
                stats
                    |> addFirstServeAttempt
                    |> addServePhaseStats phase True
                    |> addWinner

            else
                stats

        DoubleFault ->
            if isServing then
                stats
                    |> addFirstServeAttempt
                    |> addUnforcedError

            else
                stats

        InRally phase rallyWinner maybeTag ->
            let
                wonByPlayer =
                    rallyWinner == player

                afterServe =
                    if isServing then
                        stats
                            |> addFirstServeAttempt
                            |> addServePhaseStats phase wonByPlayer

                    else
                        stats
            in
            afterServe |> applyRallyTag player rallyWinner maybeTag



-- STAT HELPERS


addFirstServeAttempt : MatchStats -> MatchStats
addFirstServeAttempt stats =
    { stats | firstServeAttempts = stats.firstServeAttempts + 1 }


addServePhaseStats : ServePhase -> Bool -> MatchStats -> MatchStats
addServePhaseStats phase wonByServer stats =
    case phase of
        FirstServe ->
            { stats
                | firstServeIn = stats.firstServeIn + 1
                , firstServePointsPlayed = stats.firstServePointsPlayed + 1
                , firstServePointsWon =
                    if wonByServer then
                        stats.firstServePointsWon + 1

                    else
                        stats.firstServePointsWon
            }

        SecondServe ->
            { stats
                | secondServePointsPlayed = stats.secondServePointsPlayed + 1
                , secondServePointsWon =
                    if wonByServer then
                        stats.secondServePointsWon + 1

                    else
                        stats.secondServePointsWon
            }


addWinner : MatchStats -> MatchStats
addWinner stats =
    { stats | winners = stats.winners + 1 }


addUnforcedError : MatchStats -> MatchStats
addUnforcedError stats =
    { stats | unforcedErrors = stats.unforcedErrors + 1 }


applyRallyTag : Player -> Player -> Maybe RallyTag -> MatchStats -> MatchStats
applyRallyTag player rallyWinner maybeTag stats =
    case maybeTag of
        Nothing ->
            stats

        Just Winner ->
            if rallyWinner == player then
                addWinner stats

            else
                stats

        Just UnforcedError ->
            if rallyWinner /= player then
                addUnforcedError stats

            else
                stats
