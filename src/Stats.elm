module Stats exposing (MatchStats, compute)

import Match exposing (MatchConfig, Player(..), Point, RallyTag(..), ServeOutcome(..), ServePhase(..))
import ScoreEngine exposing (deriveMatchState)


{-| Per-player match statistics derived from the point log.
-}
type alias MatchStats =
    { -- Serve
      firstServeIn : Int
    , firstServeAttempts : Int
    , firstServePointsWon : Int
    , firstServePointsPlayed : Int
    , secondServePointsWon : Int
    , secondServePointsPlayed : Int
    , aces : Int
    , doubleFaults : Int
    , serviceGamesWon : Int
    , serviceGamesPlayed : Int

    -- Return
    , returnPointsWon : Int
    , returnPointsPlayed : Int
    , breakPointsWon : Int
    , breakPointOpportunities : Int
    , breakPointsSaved : Int
    , breakPointsFaced : Int

    -- Rally
    , winners : Int
    , unforcedErrors : Int
    , forcedErrors : Int

    -- Points totals
    , totalPointsWon : Int
    , totalPointsPlayed : Int
    }


emptyStats : MatchStats
emptyStats =
    { firstServeIn = 0
    , firstServeAttempts = 0
    , firstServePointsWon = 0
    , firstServePointsPlayed = 0
    , secondServePointsWon = 0
    , secondServePointsPlayed = 0
    , aces = 0
    , doubleFaults = 0
    , serviceGamesWon = 0
    , serviceGamesPlayed = 0
    , returnPointsWon = 0
    , returnPointsPlayed = 0
    , breakPointsWon = 0
    , breakPointOpportunities = 0
    , breakPointsSaved = 0
    , breakPointsFaced = 0
    , winners = 0
    , unforcedErrors = 0
    , forcedErrors = 0
    , totalPointsWon = 0
    , totalPointsPlayed = 0
    }


{-| Derives all statistics for a given player from the point log.

Break-point counts are taken from the score engine (which already accumulates
them during the fold); service game counts are computed by detecting game
boundaries via sequential match-state comparisons; all other stats are
computed by a single pass over the point list.

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

        opponentBps =
            case player of
                PlayerA ->
                    matchState.breakPoints.playerB

                PlayerB ->
                    matchState.breakPoints.playerA

        totalPoints =
            matchState.totalPoints

        totalWon =
            case player of
                PlayerA ->
                    totalPoints.wonByPlayerA

                PlayerB ->
                    totalPoints.wonByPlayerB

        serviceGames =
            computeServiceGames player config points

        base =
            List.foldl (accumulatePoint player) emptyStats points
    in
    { base
        | breakPointsWon = bps.converted
        , breakPointOpportunities = bps.opportunities
        , breakPointsFaced = opponentBps.opportunities
        , breakPointsSaved = opponentBps.opportunities - opponentBps.converted
        , serviceGamesWon = serviceGames.won
        , serviceGamesPlayed = serviceGames.played
        , totalPointsWon = totalWon
        , totalPointsPlayed = totalPoints.played
    }


{-| Computes service games won and played for a player by detecting game
boundaries between consecutive match states. O(n²) in the number of points,
which is acceptable for typical match lengths (≤ ~350 points).
-}
computeServiceGames : Player -> MatchConfig -> List Point -> { won : Int, played : Int }
computeServiceGames player config points =
    let
        n =
            List.length points

        stateAt i =
            deriveMatchState config (List.take i points)
    in
    List.foldl
        (\i acc ->
            let
                prevState =
                    stateAt i

                newState =
                    stateAt (i + 1)

                -- Detect whether a game boundary was crossed on this point
                gameScoreIncreased =
                    newState.gameScore.playerA
                        > prevState.gameScore.playerA
                        || newState.gameScore.playerB
                        > prevState.gameScore.playerB

                regularSetEnd =
                    List.length newState.setScores
                        > List.length prevState.setScores
                        && prevState.tiebreak
                        == Nothing

                tiebreakEnd =
                    prevState.tiebreak /= Nothing && newState.tiebreak == Nothing

                gameEnded =
                    gameScoreIncreased || regularSetEnd || tiebreakEnd
            in
            if not gameEnded then
                acc

            else
                let
                    -- The server of the game is the first server of a tiebreak,
                    -- or the current server for regular games.
                    server =
                        case prevState.tiebreak of
                            Just tb ->
                                tb.firstServer

                            Nothing ->
                                prevState.currentServer

                    -- Determine whether the target player won this game.
                    gameWinnerIsPlayer =
                        if gameScoreIncreased then
                            (player
                                == PlayerA
                                && newState.gameScore.playerA
                                > prevState.gameScore.playerA
                            )
                                || (player
                                        == PlayerB
                                        && newState.gameScore.playerB
                                        > prevState.gameScore.playerB
                                   )

                        else
                            -- Set-ending game (regular or tiebreak): winner has
                            -- the higher game count in the new set entry.
                            case List.head (List.reverse newState.setScores) of
                                Just finalSet ->
                                    if player == PlayerA then
                                        finalSet.playerA > finalSet.playerB

                                    else
                                        finalSet.playerB > finalSet.playerA

                                Nothing ->
                                    False
                in
                if server == player then
                    { won =
                        acc.won
                            + (if gameWinnerIsPlayer then
                                1

                               else
                                0
                              )
                    , played = acc.played + 1
                    }

                else
                    acc
        )
        { won = 0, played = 0 }
        (List.range 0 (n - 1))


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
                    |> addAce

            else
                { stats | returnPointsPlayed = stats.returnPointsPlayed + 1 }

        ServeWinner phase ->
            if isServing then
                stats
                    |> addFirstServeAttempt
                    |> addServePhaseStats phase True
                    |> addWinner

            else
                { stats | returnPointsPlayed = stats.returnPointsPlayed + 1 }

        DoubleFault ->
            if isServing then
                stats
                    |> addFirstServeAttempt
                    |> addUnforcedError
                    |> addDoubleFault

            else
                { stats
                    | returnPointsPlayed = stats.returnPointsPlayed + 1
                    , returnPointsWon = stats.returnPointsWon + 1
                }

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
                        { stats
                            | returnPointsPlayed = stats.returnPointsPlayed + 1
                            , returnPointsWon =
                                if wonByPlayer then
                                    stats.returnPointsWon + 1

                                else
                                    stats.returnPointsWon
                        }

                afterTag =
                    afterServe |> applyRallyTag player rallyWinner maybeTag
            in
            case maybeTag of
                Nothing ->
                    if not wonByPlayer then
                        { afterTag | forcedErrors = afterTag.forcedErrors + 1 }

                    else
                        afterTag

                Just _ ->
                    afterTag



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


addAce : MatchStats -> MatchStats
addAce stats =
    { stats | aces = stats.aces + 1 }


addDoubleFault : MatchStats -> MatchStats
addDoubleFault stats =
    { stats | doubleFaults = stats.doubleFaults + 1 }


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
