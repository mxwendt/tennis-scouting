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
        , describe "3.1 — aces and double faults"
            [ test "ace on first serve increments aces" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.aces 1
            , test "ace does not increment opponent's aces" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe) ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal stats.aces 0
            , test "double fault increments doubleFaults" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.doubleFaults 1
            , test "double fault does not increment opponent's doubleFaults" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal stats.doubleFaults 0
            , test "serve winner does not count as ace" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (ServeWinner FirstServe) ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.aces 0
            ]
        , describe "3.2 — return points won"
            [ test "double fault gives receiver a return point won" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 1, 1 )
            , test "ace: receiver has return point played but not won" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe) ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 1, 0 )
            , test "serve winner: receiver has return point played but not won" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (ServeWinner FirstServe) ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 1, 0 )
            , test "return rally won: return points played and won both increment" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerB ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 1, 1 )
            , test "return rally lost: played increments, won stays" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerA ]

                        stats =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 1, 0 )
            , test "serving player has no return points" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA (Ace FirstServe)
                            , rallyWon PlayerA FirstServe PlayerA
                            ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.returnPointsPlayed, stats.returnPointsWon ) ( 0, 0 )
            ]
        , describe "3.3 — forced errors"
            [ test "rally lost with no tag is a forced error" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerB ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.forcedErrors 1
            , test "rally won with no tag is not a forced error" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerA ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.forcedErrors 0
            , test "rally lost with UE tag is not a forced error (it is an unforced error)" <|
                \_ ->
                    let
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerB UnforcedError ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.forcedErrors 0
            , test "rally lost with Winner tag is not a forced error" <|
                \_ ->
                    let
                        points =
                            [ rallyTagged PlayerA FirstServe PlayerB Winner ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.forcedErrors 0
            , test "double fault is not a forced error" <|
                \_ ->
                    let
                        points =
                            [ serve PlayerA DoubleFault ]

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal stats.forcedErrors 0
            ]
        , describe "3.4 — break points saved"
            [ test "break point saved: 3 break points faced at 0-40, all saved" <|
                \_ ->
                    let
                        -- Reach 0-40 (3 break points at 0-40, 15-40, 30-40),
                        -- then PlayerA saves all and wins the game.
                        reach40 =
                            List.repeat 3 (rallyWon PlayerA FirstServe PlayerB)

                        saveAndWin =
                            List.repeat 5 (rallyWon PlayerA FirstServe PlayerA)

                        points =
                            reach40 ++ saveAndWin

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.breakPointsFaced, stats.breakPointsSaved ) ( 3, 3 )
            , test "break point not saved: opponent had 1 opportunity and 1 converted" <|
                \_ ->
                    let
                        -- Reach Love-40, PlayerB converts
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerB)

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.breakPointsFaced, stats.breakPointsSaved ) ( 1, 0 )
            , test "no break point opportunities faced: both zero" <|
                \_ ->
                    let
                        -- PlayerA holds to 15 with no break points
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerA)

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.breakPointsFaced, stats.breakPointsSaved ) ( 0, 0 )
            ]
        , describe "3.5 — total points"
            [ test "total points played equals sum of both players' served points" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerA
                            , rallyWon PlayerA FirstServe PlayerB
                            , serve PlayerB (Ace FirstServe)
                            ]

                        statsA =
                            compute PlayerA defaultConfig points

                        statsB =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal ( statsA.totalPointsPlayed, statsB.totalPointsPlayed ) ( 3, 3 )
            , test "total points won sum equals total points played" <|
                \_ ->
                    let
                        points =
                            [ rallyWon PlayerA FirstServe PlayerA
                            , rallyWon PlayerA FirstServe PlayerB
                            , serve PlayerB (Ace FirstServe)
                            ]

                        statsA =
                            compute PlayerA defaultConfig points

                        statsB =
                            compute PlayerB defaultConfig points
                    in
                    Expect.equal (statsA.totalPointsWon + statsB.totalPointsWon) statsA.totalPointsPlayed
            ]
        , describe "3.6 — service games"
            [ test "player holds a service game: 1 played, 1 won" <|
                \_ ->
                    let
                        -- PlayerA wins 4 straight on serve (Love game)
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerA)

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.serviceGamesPlayed, stats.serviceGamesWon ) ( 1, 1 )
            , test "player's service game is broken: 1 played, 0 won" <|
                \_ ->
                    let
                        -- PlayerA loses 4 straight on serve
                        points =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerB)

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.serviceGamesPlayed, stats.serviceGamesWon ) ( 1, 0 )
            , test "opponent's service game not counted for player" <|
                \_ ->
                    let
                        -- PlayerB serves first and holds their game.
                        -- PlayerA should have 0 service games.
                        playerBFirstConfig =
                            { defaultConfig | initialServer = PlayerB }

                        points =
                            List.repeat 4 (rallyWon PlayerB FirstServe PlayerB)

                        stats =
                            compute PlayerA playerBFirstConfig points
                    in
                    Expect.equal ( stats.serviceGamesPlayed, stats.serviceGamesWon ) ( 0, 0 )
            , test "two service games: one held, one broken" <|
                \_ ->
                    let
                        -- PlayerA holds, then PlayerB holds, then PlayerA is broken
                        holdA =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerA)

                        holdB =
                            List.repeat 4 (rallyWon PlayerB FirstServe PlayerB)

                        breakA =
                            List.repeat 4 (rallyWon PlayerA FirstServe PlayerB)

                        points =
                            holdA ++ holdB ++ breakA

                        stats =
                            compute PlayerA defaultConfig points
                    in
                    Expect.equal ( stats.serviceGamesPlayed, stats.serviceGamesWon ) ( 2, 1 )
            ]
        ]
