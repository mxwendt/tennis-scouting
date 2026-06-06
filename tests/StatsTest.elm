module StatsTest exposing (..)

import Expect
import Match exposing (DeuceFormat(..), MatchConfig, MatchFormat(..), Player(..), Point, RallyTag(..), ServeOutcome(..), ServePhase(..), SetFormat(..), TiebreakFormat(..))
import Stats exposing (compute)
import Test exposing (Test, describe, test)



-- HELPERS


defaultConfig : MatchConfig
defaultConfig =
    { initialServer = PlayerA
    , matchFormat = BestOfThree
    , setFormat = StandardSet
    , tiebreakFormat = StandardPlusMatchTiebreak
    , deuceFormat = StandardDeuce
    }


serve : Player -> ServeOutcome -> Point
serve server outcome =
    { server = server, outcome = outcome }


rallyWon : Player -> ServePhase -> Player -> Point
rallyWon server phase winner =
    { server = server, outcome = InRally phase winner Nothing }


rallyTagged : Player -> ServePhase -> Player -> RallyTag -> Point
rallyTagged server phase winner tag =
    { server = server, outcome = InRally phase winner (Just tag) }



-- SUITE


suite : Test
suite =
    describe "Stats"
        [ describe "2.1 — first serve attempts and in"
            [ test "ace on first serve: 1 attempt, 1 in" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServeAttempts, stats.firstServeIn ) ( 1, 1 )
            , test "rally on second serve (fault preceded): 1 attempt, 0 in" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (InRally SecondServe PlayerA Nothing) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServeAttempts, stats.firstServeIn ) ( 1, 0 )
            , test "double fault: 1 attempt, 0 in" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServeAttempts, stats.firstServeIn ) ( 1, 0 )
            , test "two first-serve points: 2 attempts, 2 in" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe)
                            , rallyWon PlayerA FirstServe PlayerA
                            ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServeAttempts, stats.firstServeIn ) ( 2, 2 )
            , test "opponent's serve not counted for player" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerB (Ace FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServeAttempts, stats.firstServeIn ) ( 0, 0 )
            ]
        , describe "2.2 — first serve points won"
            [ test "player wins on first serve: counted" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerA ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServePointsPlayed, stats.firstServePointsWon ) ( 1, 1 )
            , test "player loses on first serve: played counted, won not" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerB ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServePointsPlayed, stats.firstServePointsWon ) ( 1, 0 )
            , test "second-serve point not counted in first-serve points" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA SecondServe PlayerA ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.firstServePointsPlayed, stats.firstServePointsWon ) ( 0, 0 )
            ]
        , describe "2.3 — second serve points won, double faults excluded"
            [ test "second-serve rally won: 1 played, 1 won" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA SecondServe PlayerA ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.secondServePointsPlayed, stats.secondServePointsWon ) ( 1, 1 )
            , test "second-serve rally lost: 1 played, 0 won" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA SecondServe PlayerB ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.secondServePointsPlayed, stats.secondServePointsWon ) ( 1, 0 )
            , test "double fault excluded from second-serve played denominator" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.secondServePointsPlayed 0
            ]
        , describe "2.4 — winners"
            [ test "ace counts as winner for server" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.winners 1
            , test "serve winner counts as winner for server" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (ServeWinner FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.winners 1
            , test "rally winner tag counts as winner for rally winner" <|
                \_ ->
                    let
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerA Winner ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.winners 1
            , test "rally won without tag: not a winner" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA SecondServe PlayerA ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.winners 0
            , test "opponent's rally winner not credited to player" <|
                \_ ->
                    let
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerB Winner ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.winners 0
            ]
        , describe "2.5 — unforced errors"
            [ test "double fault counts as unforced error for server" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.unforcedErrors 1
            , test "unforced error tag: error credited to the player who lost the point" <|
                \_ ->
                    let
                        -- PlayerB wins because PlayerA made an unforced error
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerB UnforcedError ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.unforcedErrors 1
            , test "unforced error tag: winner does not get an unforced error" <|
                \_ ->
                    let
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerB UnforcedError ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal stats.unforcedErrors 0
            ]
        , describe "2.6 — break points"
            [ test "break point converted: 1 opportunity, 1 won" <|
                \_ ->
                    let
                        -- PlayerA serves. PlayerB wins 4 straight → Love-40 (break point), then conversion.
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerB)

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.breakPointOpportunities, stats.breakPointsWon ) ( 1, 1 )
            , test "break point missed then converted: 2 opportunities, 1 won" <|
                \_ ->
                    let
                        -- Reach Love-40 (break point), PlayerA saves, then PlayerB converts.
                        reach40 =
                            List.repeat 3 (rallyWon PlayerA FirstServe PlayerB)

                        savedPoint =
                            [ rallyWon PlayerA FirstServe PlayerA ]

                        -- Now at 15-40, still break point, PlayerB wins.
                        convertPoint =
                            [ rallyWon PlayerA FirstServe PlayerB ]

                        points =
                            reach40 ++ savedPoint ++ convertPoint

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.breakPointOpportunities, stats.breakPointsWon ) ( 2, 1 )
            , test "no break point opportunities: both zero" <|
                \_ ->
                    let
                        -- PlayerA wins every point cleanly (never reach break point).
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerA)

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.breakPointOpportunities, stats.breakPointsWon ) ( 0, 0 )
            ]
        ]
