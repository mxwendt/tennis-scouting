module ScoreEngine exposing
    ( GameScore(..)
    , MatchState
    , MatchStatus(..)
    , deriveMatchState
    , otherPlayer
    , pointWinner
    )

import Match exposing (..)



-- OUTPUT TYPES
-- These types are produced exclusively by the engine. The UI reads them but
-- never constructs them directly, so they live here rather than in Match.


{-| The score of one player within the current game, in standard tennis
notation. DeuceScore and Advantage are introduced in Step 2.
-}
type GameScore
    = Love
    | Fifteen
    | Thirty
    | Forty
    | DeuceScore
    | Advantage Player


{-| Whether the match is still in progress or has been won.
-}
type MatchStatus
    = InProgress
    | WonBy Player


{-| The complete derived state of the match at any point in time.
This is the return type of `deriveMatchState` and the single source of truth
for all displays and statistics.

The `tiebreak` field is `Just` while a tiebreak is in progress, holding the
current tiebreak point score and the player who served the first tiebreak
point. It returns to `Nothing` once the tiebreak is complete.

-}
type alias MatchState =
    { pointScore : { playerA : GameScore, playerB : GameScore }
    , gameScore : { playerA : Int, playerB : Int }
    , setScores : List { playerA : Int, playerB : Int }
    , tiebreak : Maybe { playerA : Int, playerB : Int, firstServer : Player }
    , currentServer : Player
    , isBreakPoint : Bool
    , matchStatus : MatchStatus
    , totalPoints : { played : Int, wonByPlayerA : Int, wonByPlayerB : Int }
    }



-- HELPERS


{-| Returns the other player.
-}
otherPlayer : Player -> Player
otherPlayer player =
    case player of
        PlayerA ->
            PlayerB

        PlayerB ->
            PlayerA


{-| Derives which player won a given point from its serve outcome.

  - Ace and ServeWinner are awarded to the server.
  - DoubleFault is awarded to the receiver.
  - InRally carries the winner explicitly.

-}
pointWinner : Point -> Player
pointWinner point =
    case point.outcome of
        Ace ->
            point.server

        ServeWinner ->
            point.server

        DoubleFault ->
            otherPlayer point.server

        InRally winner _ ->
            winner



-- GAME SCORE HELPERS


getScore : Player -> { playerA : GameScore, playerB : GameScore } -> GameScore
getScore player scores =
    case player of
        PlayerA ->
            scores.playerA

        PlayerB ->
            scores.playerB


setScore :
    Player
    -> GameScore
    -> { playerA : GameScore, playerB : GameScore }
    -> { playerA : GameScore, playerB : GameScore }
setScore player score scores =
    case player of
        PlayerA ->
            { scores | playerA = score }

        PlayerB ->
            { scores | playerB = score }



-- GAME RESULT


type GameResult
    = GameContinues { playerA : GameScore, playerB : GameScore }
    | GameWonBy Player


{-| Applies a point won by the given player to the current point score.

Step 1 handles clean game scoring: Love → 15 → 30 → 40 → game won.
Step 2 adds full deuce / advantage logic, controlled by the DeuceFormat.

-}
applyPointToGame :
    DeuceFormat
    -> Player
    -> { playerA : GameScore, playerB : GameScore }
    -> GameResult
applyPointToGame deuceFormat winner scores =
    case getScore winner scores of
        Love ->
            GameContinues (setScore winner Fifteen scores)

        Fifteen ->
            GameContinues (setScore winner Thirty scores)

        Thirty ->
            GameContinues (setScore winner Forty scores)

        Forty ->
            -- Check whether the opponent is also at Forty (40–40).
            case getScore (otherPlayer winner) scores of
                Forty ->
                    case deuceFormat of
                        StandardDeuce ->
                            GameContinues { playerA = DeuceScore, playerB = DeuceScore }

                        NoAd ->
                            GameWonBy winner

                _ ->
                    GameWonBy winner

        DeuceScore ->
            -- Check whether the opponent currently holds the Advantage.
            -- If so, the winner has just broken back → return to deuce.
            -- Otherwise, grant the winner the Advantage (or the game under NoAd).
            case getScore (otherPlayer winner) scores of
                Advantage _ ->
                    GameContinues { playerA = DeuceScore, playerB = DeuceScore }

                _ ->
                    case deuceFormat of
                        StandardDeuce ->
                            GameContinues (setScore winner (Advantage winner) scores)

                        NoAd ->
                            GameWonBy winner

        Advantage advPlayer ->
            if winner == advPlayer then
                GameWonBy winner

            else
                -- Opponent took back the advantage → return to deuce.
                GameContinues { playerA = DeuceScore, playerB = DeuceScore }



-- SET SCORE HELPERS


{-| Checks whether a set has been won given the current game score and set format.

A standard set is won when a player reaches 6 games with a lead of at least 2.
A pro set is won when a player reaches 8 games with a lead of at least 2.

Returns `Just Player` for the winner, or `Nothing` if the set is still in
progress. Tiebreak detection (6–6 / 8–8) is handled separately.

-}
setWonBy : SetFormat -> { playerA : Int, playerB : Int } -> Maybe Player
setWonBy setFormat scores =
    let
        threshold =
            case setFormat of
                StandardSet ->
                    6

                ProSet ->
                    8
    in
    if scores.playerA >= threshold && scores.playerA - scores.playerB >= 2 then
        Just PlayerA

    else if scores.playerB >= threshold && scores.playerB - scores.playerA >= 2 then
        Just PlayerB

    else
        Nothing


{-| Returns `True` when the game score has reached the tiebreak trigger point:
6–6 for a standard set, 8–8 for a pro set. Called only after `setWonBy`
returns `Nothing`, so the score is guaranteed to be tied at the threshold.
-}
isTiebreakScore : SetFormat -> { playerA : Int, playerB : Int } -> Bool
isTiebreakScore setFormat scores =
    let
        threshold =
            case setFormat of
                StandardSet ->
                    6

                ProSet ->
                    8
    in
    scores.playerA == threshold && scores.playerB == threshold



-- MATCH SCORE HELPERS


{-| Returns the number of sets a player must win to win the match.
-}
setsNeededToWin : MatchFormat -> Int
setsNeededToWin matchFormat =
    case matchFormat of
        BestOfThree ->
            2

        BestOfFive ->
            3


{-| Counts how many sets in the archived set-score list the given player has won.
A player wins a set when their game count is strictly greater than the opponent's.
-}
setsWonBy : Player -> List { playerA : Int, playerB : Int } -> Int
setsWonBy player setScoresList =
    List.length
        (List.filter
            (\s ->
                case player of
                    PlayerA ->
                        s.playerA > s.playerB

                    PlayerB ->
                        s.playerB > s.playerA
            )
            setScoresList
        )



-- TIEBREAK HELPERS


{-| Returns the target number of points required to win a tiebreak.

  - In any non-final set: first to 7 (standard tiebreak).
  - In the final set of the match: first to 10 (match tiebreak).

`completedSets` is the number of sets already archived in `setScores` at the
time the tiebreak begins; this determines whether the current set is the final
possible set.

-}
tiebreakTarget : MatchFormat -> Int -> Int
tiebreakTarget matchFormat completedSets =
    let
        maxSets =
            case matchFormat of
                BestOfThree ->
                    3

                BestOfFive ->
                    5
    in
    if completedSets == maxSets - 1 then
        10

    else
        7


{-| Returns the player who serves at a given tiebreak point index (0-based).

The serving pattern is: the first server serves point 0, then serving
alternates every 2 points.

    index → server
    0     → firstServer
    1, 2  → otherPlayer firstServer
    3, 4  → firstServer
    5, 6  → otherPlayer firstServer
    …

Formula: if `(index + 1) // 2` is even, `firstServer` serves; otherwise the
other player serves.

-}
tiebreakServerFor : Player -> Int -> Player
tiebreakServerFor firstServer pointIndex =
    if modBy 2 ((pointIndex + 1) // 2) == 0 then
        firstServer

    else
        otherPlayer firstServer



-- INITIAL STATE


emptyPointScore : { playerA : GameScore, playerB : GameScore }
emptyPointScore =
    { playerA = Love, playerB = Love }


initialMatchState : MatchConfig -> MatchState
initialMatchState config =
    { pointScore = emptyPointScore
    , gameScore = { playerA = 0, playerB = 0 }
    , setScores = []
    , tiebreak = Nothing
    , currentServer = config.initialServer
    , isBreakPoint = False
    , matchStatus = InProgress
    , totalPoints = { played = 0, wonByPlayerA = 0, wonByPlayerB = 0 }
    }



-- APPLY POINT (FOLD STEP)


incrementGameScore :
    Player
    -> { playerA : Int, playerB : Int }
    -> { playerA : Int, playerB : Int }
incrementGameScore player scores =
    case player of
        PlayerA ->
            { scores | playerA = scores.playerA + 1 }

        PlayerB ->
            { scores | playerB = scores.playerB + 1 }


{-| Applies a single tiebreak point to the current match state.

Increments the tiebreak score for the point winner, then either:

  - Detects a tiebreak win (winner has reached the target with a 2-point lead),
    archives the set (incrementing the winner's game count by 1 to produce a
    score such as 7–6 or 10–9), resets for the next set, and sets
    `currentServer` to the player who did not serve first in the tiebreak.
  - Or continues the tiebreak, updating `currentServer` to whoever serves the
    next tiebreak point according to the rotation.

-}
applyTiebreakPoint :
    MatchConfig
    -> Point
    -> { playerA : Int, playerB : Int, firstServer : Player }
    -> MatchState
    -> MatchState
applyTiebreakPoint config point tb state =
    let
        winner =
            pointWinner point

        newTb =
            case winner of
                PlayerA ->
                    { tb | playerA = tb.playerA + 1 }

                PlayerB ->
                    { tb | playerB = tb.playerB + 1 }

        winnerScore =
            case winner of
                PlayerA ->
                    newTb.playerA

                PlayerB ->
                    newTb.playerB

        loserScore =
            case winner of
                PlayerA ->
                    newTb.playerB

                PlayerB ->
                    newTb.playerA

        target =
            tiebreakTarget config.matchFormat (List.length state.setScores)

        tbWon =
            winnerScore >= target && winnerScore - loserScore >= 2
    in
    if tbWon then
        let
            -- The tiebreak winner gains one game, turning e.g. 6–6 into 7–6.
            newGameScore =
                incrementGameScore winner state.gameScore

            newSetScores =
                state.setScores ++ [ newGameScore ]

            newMatchStatus =
                if setsWonBy winner newSetScores == setsNeededToWin config.matchFormat then
                    WonBy winner

                else
                    InProgress

            -- After a tiebreak the player who did NOT serve first in the
            -- tiebreak serves first in the next set.
            nextServer =
                otherPlayer tb.firstServer
        in
        { state
            | pointScore = emptyPointScore
            , gameScore = { playerA = 0, playerB = 0 }
            , setScores = newSetScores
            , tiebreak = Nothing
            , currentServer = nextServer
            , matchStatus = newMatchStatus
        }

    else
        let
            totalPlayed =
                newTb.playerA + newTb.playerB
        in
        { state
            | tiebreak = Just newTb
            , currentServer = tiebreakServerFor tb.firstServer totalPlayed
        }


{-| Applies a single regular (non-tiebreak) point to the current match state.

Handles:

  - Advancing the point score within the current game.
  - Detecting when a game is won and resetting the point score.
  - Incrementing the game score for the winner.
  - Detecting when a set is won (via `setWonBy`) and archiving it.
  - Detecting the tiebreak trigger (6–6 or 8–8) and opening a new tiebreak.
  - Detecting when the match is won and setting `matchStatus` to `WonBy`.

-}
applyRegularPoint : MatchConfig -> Point -> MatchState -> MatchState
applyRegularPoint config point state =
    let
        winner =
            pointWinner point
    in
    case applyPointToGame config.deuceFormat winner state.pointScore of
        GameContinues newPointScore ->
            { state | pointScore = newPointScore }

        GameWonBy gameWinner ->
            let
                newGameScore =
                    incrementGameScore gameWinner state.gameScore

                nextServer =
                    otherPlayer state.currentServer
            in
            case setWonBy config.setFormat newGameScore of
                Just setWinner ->
                    let
                        newSetScores =
                            state.setScores ++ [ newGameScore ]

                        newMatchStatus =
                            if setsWonBy setWinner newSetScores == setsNeededToWin config.matchFormat then
                                WonBy setWinner

                            else
                                InProgress
                    in
                    { state
                        | pointScore = emptyPointScore
                        , gameScore = { playerA = 0, playerB = 0 }
                        , setScores = newSetScores
                        , matchStatus = newMatchStatus
                        , currentServer = nextServer
                    }

                Nothing ->
                    if isTiebreakScore config.setFormat newGameScore then
                        -- Tiebreak triggered: the player who would normally serve
                        -- the next game serves the first tiebreak point.
                        { state
                            | pointScore = emptyPointScore
                            , gameScore = newGameScore
                            , tiebreak =
                                Just
                                    { playerA = 0
                                    , playerB = 0
                                    , firstServer = nextServer
                                    }
                            , currentServer = nextServer
                        }

                    else
                        { state
                            | pointScore = emptyPointScore
                            , gameScore = newGameScore
                            , currentServer = nextServer
                        }


{-| Applies a single recorded point to the current match state.

This is the step function used inside the fold in `deriveMatchState`.
Dispatches to `applyTiebreakPoint` when a tiebreak is in progress, or to
`applyRegularPoint` otherwise. Returns the state unchanged if the match has
already been won.

-}
applyPoint : MatchConfig -> Point -> MatchState -> MatchState
applyPoint config point state =
    case state.matchStatus of
        WonBy _ ->
            state

        InProgress ->
            case state.tiebreak of
                Just tb ->
                    applyTiebreakPoint config point tb state

                Nothing ->
                    applyRegularPoint config point state



-- MAIN DERIVATION FUNCTION


{-| Derives the complete match state from a match config and a full point log.

This is the public entry point of the score engine. It folds over the list
of recorded points from left to right, applying each one in sequence via
`applyPoint`. The function is deterministic: the same config and point log
always produce the same state. No mutable state is involved.

-}
deriveMatchState : MatchConfig -> List Point -> MatchState
deriveMatchState config points =
    List.foldl (applyPoint config) (initialMatchState config) points
