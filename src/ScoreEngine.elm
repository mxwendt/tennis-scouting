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
-}
type alias MatchState =
    { pointScore : { playerA : GameScore, playerB : GameScore }
    , gameScore : { playerA : Int, playerB : Int }
    , setScores : List { playerA : Int, playerB : Int }
    , tiebreak : Maybe { playerA : Int, playerB : Int }
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


{-| Applies a single recorded point to the current match state.

This is the step function used inside the fold in `deriveMatchState`.
For Step 1 it handles:

  - Advancing the point score within the current game.
  - Detecting when a game is won and resetting the point score.
  - Incrementing the game score for the winner.

Later steps will extend this function to handle set completion, match
completion, tiebreaks, serving rotation, and break-point detection.

-}
applyPoint : MatchConfig -> Point -> MatchState -> MatchState
applyPoint config point state =
    let
        winner =
            pointWinner point
    in
    case applyPointToGame config.deuceFormat winner state.pointScore of
        GameContinues newPointScore ->
            { state | pointScore = newPointScore }

        GameWonBy gameWinner ->
            { state
                | pointScore = emptyPointScore
                , gameScore = incrementGameScore gameWinner state.gameScore
            }


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
