module ScoreEngineTest exposing (..)

import Expect
import Match exposing (..)
import ScoreEngine exposing (..)
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


{-| A simple rally point awarded to the given player (server is always PlayerA
in these helpers; serve outcome tests use explicit Point records instead).
-}
pointWonBy : Player -> Point
pointWonBy winner =
    { server = PlayerA
    , outcome = InRally FirstServe winner Nothing
    }


nPointsWonBy : Int -> Player -> List Point
nPointsWonBy n player =
    List.repeat n (pointWonBy player)


{-| A clean 4-point game won by the given player (no points dropped).
-}
gameWonBy : Player -> List Point
gameWonBy player =
    nPointsWonBy 4 player


configNoAd : MatchConfig
configNoAd =
    { defaultConfig | deuceFormat = NoAd }


{-| 3 points won by each player, leaving the game at Forty–Forty.
-}
toFortyForty : List Point
toFortyForty =
    nPointsWonBy 3 PlayerA ++ nPointsWonBy 3 PlayerB


{-| Reaches Forty–Forty and then PlayerA wins one more point, triggering the
transition from Forty–Forty into DeuceScore under StandardDeuce.
-}
enterDeuce : List Point
enterDeuce =
    toFortyForty ++ [ pointWonBy PlayerA ]


{-| Builds a sequence of n clean 4-point games all won by the given player.
-}
nGamesWonBy : Int -> Player -> List Point
nGamesWonBy n player =
    List.concat (List.repeat n (gameWonBy player))


configProSet : MatchConfig
configProSet =
    { defaultConfig | setFormat = ProSet }


configBestOfFive : MatchConfig
configBestOfFive =
    { defaultConfig | matchFormat = BestOfFive }


{-| A complete set won 6–0 by the given player (6 clean games).
-}
setWonBy6_0 : Player -> List Point
setWonBy6_0 player =
    nGamesWonBy 6 player


{-| Reaches 6–6 within a single standard set by alternating game wins
(A then B) six times. Neither player ever gains the 2-game lead needed
to win the set outright, so the tiebreak is triggered on the final game.
With `defaultConfig` (initialServer PlayerA) the tiebreak first server is
PlayerA, because 12 games have been played and the serve has flipped back.
-}
sixSixPoints : List Point
sixSixPoints =
    List.concat (List.repeat 6 (gameWonBy PlayerA ++ gameWonBy PlayerB))


{-| Reaches 8–8 within a single pro set by alternating game wins
(A then B) eight times.
-}
eightEightPoints : List Point
eightEightPoints =
    List.concat (List.repeat 8 (gameWonBy PlayerA ++ gameWonBy PlayerB))



-- SUITE


suite : Test
suite =
    describe "Step 1 — Core types and basic game scoring"
        [ describe "Point score progression within a game"
            [ test "empty point log → Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            , test "1 point won by PlayerA → 15–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 1 PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "2 points won by PlayerA → 30–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 2 PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Thirty, playerB = Love }
            , test "3 points won by PlayerA → 40–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 3 PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Forty, playerB = Love }
            , test "1 point won by PlayerB → Love–15" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 1 PlayerB)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Fifteen }
            , test "2 points won by PlayerB → Love–30" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 2 PlayerB)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Thirty }
            , test "3 points won by PlayerB → Love–40" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 3 PlayerB)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Forty }
            , test "PlayerA wins 2 then PlayerB wins 1 → 30–15" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerA
                        , pointWonBy PlayerB
                        ]
                        |> .pointScore
                        |> Expect.equal { playerA = Thirty, playerB = Fifteen }
            , test "alternating points: A B A → 30–15" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        ]
                        |> .pointScore
                        |> Expect.equal { playerA = Thirty, playerB = Fifteen }
            ]
        , describe "Game won to love (4–0, no points dropped)"
            [ test "PlayerA wins 4 straight → game score 1–0" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "PlayerA wins 4 straight → point score resets to Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            , test "PlayerB wins 4 straight → game score 0–1" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerB)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 1 }
            , test "PlayerB wins 4 straight → point score resets to Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerB)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            ]
        , describe "Non-love game wins (points dropped, no deuce reached)"
            [ test "PlayerA wins 4–1 (reaches 40–15) → game score 1–0" <|
                \_ ->
                    -- A B A A A  →  15-0, 15-15, 30-15, 40-15, game
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        , pointWonBy PlayerA
                        , pointWonBy PlayerA
                        ]
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "PlayerA wins 4–2 (reaches 40–30) → game score 1–0" <|
                \_ ->
                    -- A B A B A A  →  15-0, 15-15, 30-15, 30-30, 40-30, game
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        , pointWonBy PlayerA
                        ]
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "PlayerA wins 4–2 (40–30) → point score resets to Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerA
                        , pointWonBy PlayerA
                        ]
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            , test "PlayerB wins game from 0–30 down (reaches 30–40) → game score 0–1" <|
                \_ ->
                    -- A A B B B B  →  15-0, 30-0, 30-15, 30-30, 30-40, game
                    deriveMatchState defaultConfig
                        [ pointWonBy PlayerA
                        , pointWonBy PlayerA
                        , pointWonBy PlayerB
                        , pointWonBy PlayerB
                        , pointWonBy PlayerB
                        , pointWonBy PlayerB
                        ]
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 1 }
            ]
        , describe "Multiple consecutive games"
            [ test "two games won by PlayerA → game score 2–0" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ gameWonBy PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 2, playerB = 0 }
            , test "one game each → game score 1–1" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ gameWonBy PlayerB)
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 1 }
            , test "three games: A B A → game score 2–1" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ gameWonBy PlayerB ++ gameWonBy PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 2, playerB = 1 }
            , test "partial second game does not advance game score" <|
                \_ ->
                    -- PlayerA wins game 1, then leads 30-0 in game 2 — still 1-0
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ nPointsWonBy 2 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "partial second game shows correct in-progress point score" <|
                \_ ->
                    -- PlayerA wins game 1, then wins 2 points in game 2 → 30-Love
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ nPointsWonBy 2 PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Thirty, playerB = Love }
            ]
        , describe "Serve outcomes correctly assign the point winner"
            [ test "ace is won by server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = Ace FirstServe } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "serve winner is won by server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = ServeWinner FirstServe } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "double fault is won by receiver (PlayerB when PlayerA serves)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = DoubleFault } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Fifteen }
            , test "double fault is won by receiver (PlayerA when PlayerB serves)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerB, outcome = DoubleFault } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "rally won by PlayerB while PlayerA serves → PlayerB scores" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = InRally FirstServe PlayerB Nothing } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Fifteen }
            , test "rally won by PlayerA while PlayerB serves → PlayerA scores" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerB, outcome = InRally FirstServe PlayerA Nothing } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "rally with a tag still attributes correctly" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = InRally FirstServe PlayerA (Just Winner) } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            ]
        , describe "otherPlayer helper"
            [ test "otherPlayer of PlayerA is PlayerB" <|
                \_ ->
                    otherPlayer PlayerA
                        |> Expect.equal PlayerB
            , test "otherPlayer of PlayerB is PlayerA" <|
                \_ ->
                    otherPlayer PlayerB
                        |> Expect.equal PlayerA
            ]
        , describe "pointWinner helper"
            [ test "Ace → server wins" <|
                \_ ->
                    pointWinner { server = PlayerA, outcome = Ace FirstServe }
                        |> Expect.equal PlayerA
            , test "ServeWinner → server wins" <|
                \_ ->
                    pointWinner { server = PlayerB, outcome = ServeWinner FirstServe }
                        |> Expect.equal PlayerB
            , test "DoubleFault → receiver wins" <|
                \_ ->
                    pointWinner { server = PlayerA, outcome = DoubleFault }
                        |> Expect.equal PlayerB
            , test "InRally PlayerA → PlayerA wins regardless of server" <|
                \_ ->
                    pointWinner { server = PlayerB, outcome = InRally FirstServe PlayerA Nothing }
                        |> Expect.equal PlayerA
            ]
        , describe "Initial state"
            [ test "match status starts as InProgress" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .matchStatus
                        |> Expect.equal InProgress
            , test "current server is the configured initial server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "current server is PlayerB when configured as initial server" <|
                \_ ->
                    deriveMatchState { defaultConfig | initialServer = PlayerB } []
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "game score starts at 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            , test "set scores list starts empty" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .setScores
                        |> Expect.equal []
            , test "no tiebreak in progress initially" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .tiebreak
                        |> Expect.equal Nothing
            ]
        ]


step2Suite : Test
step2Suite =
    describe "Step 2 — Deuce and no-ad scoring"
        [ describe "Reaching 40–40"
            [ test "toFortyForty → pointScore = Forty–Forty (not DeuceScore yet)" <|
                \_ ->
                    deriveMatchState defaultConfig toFortyForty
                        |> .pointScore
                        |> Expect.equal { playerA = Forty, playerB = Forty }
            , test "toFortyForty → gameScore still 0–0 (no game awarded)" <|
                \_ ->
                    deriveMatchState defaultConfig toFortyForty
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            ]
        , describe "Entering deuce (DeuceScore)"
            [ test "enterDeuce → pointScore = DeuceScore–DeuceScore" <|
                \_ ->
                    deriveMatchState defaultConfig enterDeuce
                        |> .pointScore
                        |> Expect.equal { playerA = DeuceScore, playerB = DeuceScore }
            ]
        , describe "Standard deuce — Advantage"
            [ test "from DeuceScore, PlayerA wins → Advantage PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerA ])
                        |> .pointScore
                        |> Expect.equal { playerA = Advantage PlayerA, playerB = DeuceScore }
            , test "from DeuceScore, PlayerB wins → Advantage PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerB ])
                        |> .pointScore
                        |> Expect.equal { playerA = DeuceScore, playerB = Advantage PlayerB }
            ]
        , describe "Standard deuce — winning the game"
            [ test "server wins from Advantage → gameScore 1–0" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerA, pointWonBy PlayerA ])
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "server wins from Advantage → pointScore resets to Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerA, pointWonBy PlayerA ])
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            , test "receiver wins from Advantage (break) → gameScore 0–1" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerB, pointWonBy PlayerB ])
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 1 }
            , test "receiver wins from Advantage (break) → pointScore resets to Love–Love" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerB, pointWonBy PlayerB ])
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            ]
        , describe "Standard deuce — returning to deuce"
            [ test "from Advantage PlayerA, PlayerB wins → back to DeuceScore" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerA, pointWonBy PlayerB ])
                        |> .pointScore
                        |> Expect.equal { playerA = DeuceScore, playerB = DeuceScore }
            , test "from Advantage PlayerB, PlayerA wins → back to DeuceScore" <|
                \_ ->
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerB, pointWonBy PlayerA ])
                        |> .pointScore
                        |> Expect.equal { playerA = DeuceScore, playerB = DeuceScore }
            ]
        , describe "Standard deuce — multiple deuce cycles"
            [ test "two full deuce cycles then PlayerA wins the game → gameScore 1–0" <|
                \_ ->
                    -- toFortyForty → 40-40
                    -- A wins → DeuceScore (both)
                    -- A wins → Adv A
                    -- B wins → DeuceScore (both)
                    -- B wins → Adv B
                    -- A wins → DeuceScore (both)
                    -- A wins → Adv A
                    -- A wins → game
                    deriveMatchState defaultConfig
                        (toFortyForty
                            ++ [ pointWonBy PlayerA
                               , pointWonBy PlayerA
                               , pointWonBy PlayerB
                               , pointWonBy PlayerB
                               , pointWonBy PlayerA
                               , pointWonBy PlayerA
                               , pointWonBy PlayerA
                               ]
                        )
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            ]
        , describe "No-ad scoring"
            [ test "at 40–40, PlayerA wins first point → game for PlayerA (gameScore 1–0)" <|
                \_ ->
                    deriveMatchState configNoAd (toFortyForty ++ [ pointWonBy PlayerA ])
                        |> .gameScore
                        |> Expect.equal { playerA = 1, playerB = 0 }
            , test "at 40–40, PlayerB wins first point → game for PlayerB (gameScore 0–1)" <|
                \_ ->
                    deriveMatchState configNoAd (toFortyForty ++ [ pointWonBy PlayerB ])
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 1 }
            , test "point score resets to Love–Love after no-ad deuce win" <|
                \_ ->
                    deriveMatchState configNoAd (toFortyForty ++ [ pointWonBy PlayerA ])
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            , test "Advantage variant never produced in no-ad scoring" <|
                \_ ->
                    -- Confirming pointScore equals Love–Love implicitly rules out
                    -- any Advantage constructor having been set.
                    deriveMatchState configNoAd (toFortyForty ++ [ pointWonBy PlayerA ])
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            ]
        ]


step3Suite : Test
step3Suite =
    describe "Step 3 — Set scoring"
        [ describe "Standard set won 6–0"
            [ test "PlayerA wins 6 games → setScores = [{ playerA = 6, playerB = 0 }]" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 6 PlayerA)
                        |> .setScores
                        |> Expect.equal [ { playerA = 6, playerB = 0 } ]
            , test "PlayerA wins 6 games → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 6 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            , test "PlayerB wins 6 games → setScores = [{ playerA = 0, playerB = 6 }]" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 6 PlayerB)
                        |> .setScores
                        |> Expect.equal [ { playerA = 0, playerB = 6 } ]
            , test "PlayerB wins 6 games → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 6 PlayerB)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            ]
        , describe "Standard set won 6–4"
            [ test "PlayerB leads 4 games then PlayerA wins 6 → setScores = [{ playerA = 6, playerB = 4 }]" <|
                \_ ->
                    -- PlayerB wins 4 first so the score climbs to 0–4,
                    -- then PlayerA wins 6 straight to reach 6–4 (lead of 2).
                    deriveMatchState defaultConfig
                        (nGamesWonBy 4 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .setScores
                        |> Expect.equal [ { playerA = 6, playerB = 4 } ]
            , test "6–4 set → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nGamesWonBy 4 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            ]
        , describe "Set does NOT end at 6–5 (lead of only 1)"
            [ test "score at 6–5 → setScores is still empty" <|
                \_ ->
                    -- PlayerB wins 5 first (0–5), then PlayerA wins 6 (6–5).
                    -- At 6–5 the lead is only 1, so the set must stay open.
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .setScores
                        |> Expect.equal []
            , test "score at 6–5 → gameScore is { playerA = 6, playerB = 5 }" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 6, playerB = 5 }
            ]
        , describe "Standard set won 7–5"
            [ test "PlayerB leads 5 then PlayerA wins 7 → setScores = [{ playerA = 7, playerB = 5 }]" <|
                \_ ->
                    -- 0–5 after 5 PlayerB games; then PlayerA wins 7 straight.
                    -- Score passes through 6–5 (no win) and resolves at 7–5.
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerB ++ nGamesWonBy 7 PlayerA)
                        |> .setScores
                        |> Expect.equal [ { playerA = 7, playerB = 5 } ]
            , test "7–5 set → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerB ++ nGamesWonBy 7 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            ]
        , describe "Two completed sets"
            [ test "two 6–0 sets → setScores has two entries" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nGamesWonBy 6 PlayerA ++ nGamesWonBy 6 PlayerA)
                        |> .setScores
                        |> Expect.equal
                            [ { playerA = 6, playerB = 0 }
                            , { playerA = 6, playerB = 0 }
                            ]
            , test "after two sets, gameScore is 0–0 (fresh third set)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nGamesWonBy 6 PlayerA ++ nGamesWonBy 6 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            , test "games played after set 1 are tracked in the new set's gameScore" <|
                \_ ->
                    -- PlayerA wins set 1 (6–0), then wins 2 more games in set 2.
                    deriveMatchState defaultConfig
                        (nGamesWonBy 6 PlayerA ++ nGamesWonBy 2 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 2, playerB = 0 }
            ]
        , describe "Pro set — does NOT end at 6–4"
            [ test "pro set: score at 6–4 → setScores is empty" <|
                \_ ->
                    deriveMatchState configProSet
                        (nGamesWonBy 4 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .setScores
                        |> Expect.equal []
            , test "pro set: score at 6–4 → gameScore is { playerA = 6, playerB = 4 }" <|
                \_ ->
                    deriveMatchState configProSet
                        (nGamesWonBy 4 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 6, playerB = 4 }
            ]
        , describe "Pro set won 8–6"
            [ test "pro set: PlayerB leads 6 then PlayerA wins 8 → setScores = [{ playerA = 8, playerB = 6 }]" <|
                \_ ->
                    -- 0–6 after 6 PlayerB games; PlayerA needs 8 wins to reach 8–6.
                    deriveMatchState configProSet
                        (nGamesWonBy 6 PlayerB ++ nGamesWonBy 8 PlayerA)
                        |> .setScores
                        |> Expect.equal [ { playerA = 8, playerB = 6 } ]
            , test "pro set 8–6 → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState configProSet
                        (nGamesWonBy 6 PlayerB ++ nGamesWonBy 8 PlayerA)
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            ]
        ]


step4Suite : Test
step4Suite =
    describe "Step 4 — Match scoring"
        [ describe "matchStatus starts as InProgress"
            [ test "empty point log → matchStatus = InProgress" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .matchStatus
                        |> Expect.equal InProgress
            ]
        , describe "Best-of-3: matchStatus after one set"
            [ test "after 1 set won → matchStatus still InProgress" <|
                \_ ->
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerA)
                        |> .matchStatus
                        |> Expect.equal InProgress
            ]
        , describe "Best-of-3: match won after 2 sets (2–0)"
            [ test "PlayerA wins 2 sets straight → matchStatus = WonBy PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "PlayerA wins 2 sets → setScores has 2 entries" <|
                \_ ->
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA)
                        |> .setScores
                        |> List.length
                        |> Expect.equal 2
            , test "PlayerB wins 2 sets straight → matchStatus = WonBy PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerB ++ setWonBy6_0 PlayerB)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerB)
            ]
        , describe "Best-of-3: match won after 2 sets (2–1)"
            [ test "PlayerA wins sets 1 and 3, PlayerB wins set 2 → WonBy PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerB ++ setWonBy6_0 PlayerA)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "PlayerB wins sets 2 and 3, PlayerA wins set 1 → WonBy PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerB ++ setWonBy6_0 PlayerB)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerB)
            ]
        , describe "Best-of-3: points after match is won are ignored"
            [ test "extra points after match won do not change matchStatus" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA ++ nPointsWonBy 10 PlayerB)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "extra points after match won do not change setScores length" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA ++ nPointsWonBy 10 PlayerB)
                        |> .setScores
                        |> List.length
                        |> Expect.equal 2
            ]
        , describe "Best-of-5: matchStatus after 2 sets"
            [ test "after 2 sets won (best-of-5) → matchStatus still InProgress" <|
                \_ ->
                    deriveMatchState configBestOfFive (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA)
                        |> .matchStatus
                        |> Expect.equal InProgress
            ]
        , describe "Best-of-5: match won after 3 sets (3–0)"
            [ test "PlayerA wins 3 sets straight (best-of-5) → WonBy PlayerA" <|
                \_ ->
                    deriveMatchState configBestOfFive
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA)
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "3–0 best-of-5 → setScores has 3 entries" <|
                \_ ->
                    deriveMatchState configBestOfFive
                        (setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA ++ setWonBy6_0 PlayerA)
                        |> .setScores
                        |> List.length
                        |> Expect.equal 3
            ]
        , describe "Best-of-5: match won after 3 sets (3–2)"
            [ test "3–2 match → WonBy PlayerA after 5 sets" <|
                \_ ->
                    deriveMatchState configBestOfFive
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ setWonBy6_0 PlayerA
                        )
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "3–2 match → setScores has 5 entries" <|
                \_ ->
                    deriveMatchState configBestOfFive
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ setWonBy6_0 PlayerA
                        )
                        |> .setScores
                        |> List.length
                        |> Expect.equal 5
            ]
        ]


step5Suite : Test
step5Suite =
    describe "Step 5 — Serving rotation (normal games)"
        [ describe "Initial server comes from config"
            [ test "empty log, initialServer PlayerA → currentServer = PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "empty log, initialServer PlayerB → currentServer = PlayerB" <|
                \_ ->
                    deriveMatchState { defaultConfig | initialServer = PlayerB } []
                        |> .currentServer
                        |> Expect.equal PlayerB
            ]
        , describe "Server alternates after each completed game"
            [ test "after 1 game → server flips to PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after 2 games → server flips back to PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 2 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after 3 games → server is PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 3 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after 4 games → server is PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 4 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after 5 games → server is PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig (nGamesWonBy 5 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "initialServer PlayerB, after 1 game → currentServer = PlayerA" <|
                \_ ->
                    deriveMatchState { defaultConfig | initialServer = PlayerB }
                        (gameWonBy PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            ]
        , describe "Server does not change mid-game"
            [ test "1 game + 1 point into next game → server is still PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ nPointsWonBy 1 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "1 game + 3 points into next game → server is still PlayerB" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ nPointsWonBy 3 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "1 game + deuce game in progress → server is still PlayerB" <|
                \_ ->
                    -- enterDeuce plays 7 points leaving the score at DeuceScore
                    -- (game not yet won, so no flip)
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ enterDeuce)
                        |> .currentServer
                        |> Expect.equal PlayerB
            ]
        , describe "Server correct across set boundaries"
            [ test "after 6-0 set (6 games) → server back to PlayerA" <|
                \_ ->
                    -- 6 flips from PlayerA → PlayerA (even)
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after 6-0 set + 1 game of set 2 → server is PlayerB" <|
                \_ ->
                    -- 7 flips from PlayerA → PlayerB (odd)
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ gameWonBy PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after 7-5 set (12 games) → server back to PlayerA" <|
                \_ ->
                    -- 5-5 then PlayerA takes the last 2 games for 7-5 (12 total)
                    -- 12 flips from PlayerA → PlayerA (even)
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerA
                            ++ nGamesWonBy 5 PlayerB
                            ++ nGamesWonBy 2 PlayerA
                        )
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after 7-5 set + 1 game of set 2 → server is PlayerB" <|
                \_ ->
                    -- 13 flips from PlayerA → PlayerB (odd)
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerA
                            ++ nGamesWonBy 5 PlayerB
                            ++ nGamesWonBy 2 PlayerA
                            ++ gameWonBy PlayerA
                        )
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "initialServer PlayerB, after 6-0 set → currentServer = PlayerB" <|
                \_ ->
                    -- 6 flips from PlayerB → PlayerB (even)
                    deriveMatchState { defaultConfig | initialServer = PlayerB }
                        (setWonBy6_0 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "server correct mid second set (2 games in)" <|
                \_ ->
                    -- After 6-0 set (6 games) + 2 games of set 2 → 8 flips → PlayerA
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA ++ nGamesWonBy 2 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            ]
        ]


step6Suite : Test
step6Suite =
    describe "Step 6 — Tiebreak scoring and serving"
        [ describe "Tiebreak triggered at the correct game score"
            [ test "6–6 standard set → tiebreak is Just { 0, 0 }" <|
                \_ ->
                    deriveMatchState defaultConfig sixSixPoints
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 0, playerB = 0 })
            , test "6–6 standard set → gameScore stays 6–6 while tiebreak is in progress" <|
                \_ ->
                    deriveMatchState defaultConfig sixSixPoints
                        |> .gameScore
                        |> Expect.equal { playerA = 6, playerB = 6 }
            , test "6–5 standard set → no tiebreak triggered" <|
                \_ ->
                    -- PlayerB wins 5 games then PlayerA wins 6: score is 6–5.
                    -- The set is not won (need a 2-game lead) and it is not 6–6.
                    deriveMatchState defaultConfig
                        (nGamesWonBy 5 PlayerB ++ nGamesWonBy 6 PlayerA)
                        |> .tiebreak
                        |> Expect.equal Nothing
            , test "8–8 pro set → tiebreak is Just { 0, 0 }" <|
                \_ ->
                    deriveMatchState configProSet eightEightPoints
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 0, playerB = 0 })
            , test "7–8 pro set → no tiebreak triggered" <|
                \_ ->
                    deriveMatchState configProSet
                        (nGamesWonBy 7 PlayerA ++ nGamesWonBy 8 PlayerB)
                        |> .tiebreak
                        |> Expect.equal Nothing
            ]
        , describe "Tiebreak point scoring"
            [ test "1 tiebreak point won by PlayerA → tiebreak score { 1, 0 }" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 1 PlayerA)
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 1, playerB = 0 })
            , test "2 A then 1 B tiebreak points → tiebreak score { 2, 1 }" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 2 PlayerA
                            ++ nPointsWonBy 1 PlayerB
                        )
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 2, playerB = 1 })
            , test "tiebreak points do not affect pointScore (stays Love–Love)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 3 PlayerA)
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Love }
            ]
        , describe "Standard tiebreak won (first to 7, win by 2)"
            [ test "tiebreak won 7–5 → tiebreak = Nothing" <|
                \_ ->
                    -- PlayerB wins 5 first, then PlayerA wins 7.
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                        )
                        |> .tiebreak
                        |> Expect.equal Nothing
            , test "tiebreak won 7–5 → setScores = [{ playerA = 7, playerB = 6 }]" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                        )
                        |> .setScores
                        |> Expect.equal [ { playerA = 7, playerB = 6 } ]
            , test "tiebreak won 7–5 → gameScore resets to 0–0" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                        )
                        |> .gameScore
                        |> Expect.equal { playerA = 0, playerB = 0 }
            , test "tiebreak NOT won at 6–6 (win-by-2 still required)" <|
                \_ ->
                    -- Each player reaches 6 tiebreak points: no one has a 2-point lead.
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 6 PlayerA
                            ++ nPointsWonBy 6 PlayerB
                        )
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 6, playerB = 6 })
            , test "extended tiebreak won 8–6 → setScores = [{ playerA = 7, playerB = 6 }]" <|
                \_ ->
                    -- Reaches 6–6 in the tiebreak, then PlayerA wins 2 more.
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 6 PlayerB
                            ++ nPointsWonBy 8 PlayerA
                        )
                        |> .setScores
                        |> Expect.equal [ { playerA = 7, playerB = 6 } ]
            , test "tiebreak won by PlayerB 7–3 → setScores = [{ playerA = 6, playerB = 7 }]" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 3 PlayerA
                            ++ nPointsWonBy 7 PlayerB
                        )
                        |> .setScores
                        |> Expect.equal [ { playerA = 6, playerB = 7 } ]
            ]
        , describe "Match tiebreak (final set, first to 10, win by 2)"
            [ test "final-set tiebreak triggered at 6–6 in best-of-3 set 3" <|
                \_ ->
                    -- Sets 1 and 2 complete (1–1), then 6–6 in set 3.
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ sixSixPoints
                        )
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 0, playerB = 0 })
            , test "match tiebreak NOT won at 9–8 (need 10 with win-by-2)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ sixSixPoints
                            ++ nPointsWonBy 8 PlayerB
                            ++ nPointsWonBy 9 PlayerA
                        )
                        |> .tiebreak
                        |> Maybe.map (\tb -> { playerA = tb.playerA, playerB = tb.playerB })
                        |> Expect.equal (Just { playerA = 9, playerB = 8 })
            , test "match tiebreak won 10–8 → matchStatus = WonBy PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ sixSixPoints
                            ++ nPointsWonBy 8 PlayerB
                            ++ nPointsWonBy 10 PlayerA
                        )
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            , test "match tiebreak won 10–8 → setScores has 3 entries" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ sixSixPoints
                            ++ nPointsWonBy 8 PlayerB
                            ++ nPointsWonBy 10 PlayerA
                        )
                        |> .setScores
                        |> List.length
                        |> Expect.equal 3
            , test "extended match tiebreak won 11–9 → matchStatus = WonBy PlayerA" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (setWonBy6_0 PlayerA
                            ++ setWonBy6_0 PlayerB
                            ++ sixSixPoints
                            ++ nPointsWonBy 9 PlayerB
                            ++ nPointsWonBy 11 PlayerA
                        )
                        |> .matchStatus
                        |> Expect.equal (WonBy PlayerA)
            ]
        , describe "Tiebreak serving rotation"
            [ test "first tiebreak point served by the player who did not serve the last game" <|
                \_ ->
                    -- With defaultConfig (initialServer PlayerA) and sixSixPoints (12 games),
                    -- serving has flipped an even number of times → tiebreak first server = PlayerA.
                    deriveMatchState defaultConfig sixSixPoints
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after tiebreak point 1 (index 0 played), server changes to other player" <|
                \_ ->
                    -- Tiebreak first server = PlayerA. After point at index 0,
                    -- the server for index 1 is PlayerB.
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 1 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after tiebreak point 2 (index 1 played), same player serves again" <|
                \_ ->
                    -- Points at indices 1 and 2 are both served by PlayerB.
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 2 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after tiebreak point 3 (index 2 played), server switches back" <|
                \_ ->
                    -- Points at indices 3 and 4 are served by PlayerA.
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 3 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after tiebreak point 4 (index 3 played), same player serves again" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 4 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerA
            , test "after tiebreak point 5 (index 4 played), server switches to other player" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 5 PlayerA)
                        |> .currentServer
                        |> Expect.equal PlayerB
            ]
        , describe "Server at the start of the set following a tiebreak"
            [ test "after tiebreak set, first server of new set is the tiebreak receiver" <|
                \_ ->
                    -- Tiebreak first server was PlayerA; post-tiebreak server is
                    -- PlayerB (the player who did not serve first in the tiebreak).
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                        )
                        |> .currentServer
                        |> Expect.equal PlayerB
            , test "after tiebreak set, first game of new set flips server to PlayerA" <|
                \_ ->
                    -- PlayerB serves the first game of set 2; after it ends the
                    -- server flips to PlayerA.
                    deriveMatchState defaultConfig
                        (sixSixPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                            ++ gameWonBy PlayerA
                        )
                        |> .currentServer
                        |> Expect.equal PlayerA
            ]
        , describe "Pro set tiebreak"
            [ test "pro set tiebreak won 7–5 → setScores = [{ playerA = 9, playerB = 8 }]" <|
                \_ ->
                    deriveMatchState configProSet
                        (eightEightPoints
                            ++ nPointsWonBy 5 PlayerB
                            ++ nPointsWonBy 7 PlayerA
                        )
                        |> .setScores
                        |> Expect.equal [ { playerA = 9, playerB = 8 } ]
            , test "pro set 7–8 is still in progress (no tiebreak yet, set not won)" <|
                \_ ->
                    deriveMatchState configProSet
                        (nGamesWonBy 7 PlayerA ++ nGamesWonBy 8 PlayerB)
                        |> .tiebreak
                        |> Expect.equal Nothing
            ]
        ]


step7Suite : Test
step7Suite =
    describe "Step 7 — Break point detection"
        [ describe "isBreakPoint at specific game scores"
            [ test "0–40 (Love–Forty) → isBreakPoint = True" <|
                \_ ->
                    -- PlayerA serves; PlayerB (receiver) has 3 points → Love–Forty.
                    deriveMatchState defaultConfig (nPointsWonBy 3 PlayerB)
                        |> .isBreakPoint
                        |> Expect.equal True
            , test "15–40 → isBreakPoint = True" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nPointsWonBy 1 PlayerA ++ nPointsWonBy 3 PlayerB)
                        |> .isBreakPoint
                        |> Expect.equal True
            , test "30–40 → isBreakPoint = True" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nPointsWonBy 2 PlayerA ++ nPointsWonBy 3 PlayerB)
                        |> .isBreakPoint
                        |> Expect.equal True
            , test "40–40 raw (Forty–Forty, before deuce transition) → isBreakPoint = False" <|
                \_ ->
                    -- toFortyForty ends at Forty–Forty; the deuce logic fires on
                    -- the NEXT point, so this is not yet a break point.
                    deriveMatchState defaultConfig toFortyForty
                        |> .isBreakPoint
                        |> Expect.equal False
            , test "DeuceScore (StandardDeuce) → isBreakPoint = False" <|
                \_ ->
                    -- enterDeuce reaches DeuceScore–DeuceScore under StandardDeuce.
                    -- Advantage has not been established yet, so not a break point.
                    deriveMatchState defaultConfig enterDeuce
                        |> .isBreakPoint
                        |> Expect.equal False
            , test "Advantage receiver (StandardDeuce) → isBreakPoint = True" <|
                \_ ->
                    -- After enterDeuce, PlayerB (receiver) wins one more → Advantage PlayerB.
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerB ])
                        |> .isBreakPoint
                        |> Expect.equal True
            , test "Advantage server (StandardDeuce) → isBreakPoint = False" <|
                \_ ->
                    -- After enterDeuce, PlayerA (server) wins one more → Advantage PlayerA.
                    deriveMatchState defaultConfig (enterDeuce ++ [ pointWonBy PlayerA ])
                        |> .isBreakPoint
                        |> Expect.equal False
            , test "Forty–Forty (NoAd) → isBreakPoint = True" <|
                \_ ->
                    -- Under NoAd the raw 40–40 state is the deciding point (no
                    -- DeuceScore transition; the game ends immediately). The
                    -- receiver is one point from winning → break point.
                    -- Note: enterDeuce does NOT work here because under NoAd the
                    -- extra point at 40–40 ends the game rather than reaching DeuceScore.
                    deriveMatchState configNoAd toFortyForty
                        |> .isBreakPoint
                        |> Expect.equal True
            , test "after a completed game, isBreakPoint resets to False (new game at Love–Love)" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .isBreakPoint
                        |> Expect.equal False
            , test "break point for PlayerA when PlayerB is serving" <|
                \_ ->
                    -- PlayerA wins game 1 (PlayerA serves); PlayerB serves game 2.
                    -- PlayerA gets to Forty (0–40 from PlayerB's side) → break point for PlayerA.
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA ++ nPointsWonBy 3 PlayerA)
                        |> .isBreakPoint
                        |> Expect.equal True
            ]
        , describe "Break point outcomes — converted and saved"
            [ test "break point converted: receiver wins at 0–40 → playerB.opportunities = 1, converted = 1" <|
                \_ ->
                    -- PlayerA serves; PlayerB reaches 0–40 then wins the game (break).
                    deriveMatchState defaultConfig
                        (nPointsWonBy 3 PlayerB ++ nPointsWonBy 1 PlayerB)
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 1 }
            , test "break point saved: server wins at 0–40 → playerB.opportunities = 1, converted = 0" <|
                \_ ->
                    -- PlayerA wins at 0–40, saving the break point (score becomes 15–40).
                    deriveMatchState defaultConfig
                        (nPointsWonBy 3 PlayerB ++ nPointsWonBy 1 PlayerA)
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 0 }
            , test "two break point opportunities: saved then converted → opportunities = 2, converted = 1" <|
                \_ ->
                    -- 0–40 saved (A wins), then 15–40 converted (B wins).
                    deriveMatchState defaultConfig
                        (nPointsWonBy 3 PlayerB
                            ++ nPointsWonBy 1 PlayerA
                            ++ nPointsWonBy 1 PlayerB
                        )
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 2, converted = 1 }
            , test "break point at Advantage receiver converted → playerB.opportunities = 1, converted = 1" <|
                \_ ->
                    -- Reach DeuceScore, then PlayerB gets Advantage, then PlayerB wins.
                    deriveMatchState defaultConfig
                        (enterDeuce
                            ++ [ pointWonBy PlayerB, pointWonBy PlayerB ]
                        )
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 1 }
            , test "break point at Advantage receiver saved (back to deuce) → opportunities = 1, converted = 0" <|
                \_ ->
                    -- PlayerB gets Advantage, then PlayerA saves → back to DeuceScore.
                    deriveMatchState defaultConfig
                        (enterDeuce
                            ++ [ pointWonBy PlayerB, pointWonBy PlayerA ]
                        )
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 0 }
            , test "no break point in a clean hold → playerB.opportunities = 0" <|
                \_ ->
                    -- PlayerA holds serve without PlayerB ever reaching Forty.
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 0, converted = 0 }
            , test "break point converted by PlayerA when PlayerB serves → playerA.converted = 1" <|
                \_ ->
                    -- PlayerA wins game 1, then breaks PlayerB's serve in game 2.
                    deriveMatchState defaultConfig
                        (gameWonBy PlayerA
                            ++ nPointsWonBy 3 PlayerA
                            ++ nPointsWonBy 1 PlayerA
                        )
                        |> .breakPoints
                        |> .playerA
                        |> Expect.equal { opportunities = 1, converted = 1 }
            , test "NoAd deuce break point saved (server wins) → opportunities = 1, converted = 0" <|
                \_ ->
                    -- Under NoAd, deuce is a break point; if the server wins it is saved.
                    deriveMatchState configNoAd
                        (toFortyForty ++ [ pointWonBy PlayerA ])
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 0 }
            , test "NoAd deuce break point converted (receiver wins) → opportunities = 1, converted = 1" <|
                \_ ->
                    deriveMatchState configNoAd
                        (toFortyForty ++ [ pointWonBy PlayerB ])
                        |> .breakPoints
                        |> .playerB
                        |> Expect.equal { opportunities = 1, converted = 1 }
            ]
        , describe "isBreakPoint is False during a tiebreak"
            [ test "mid-tiebreak (3 points in) → isBreakPoint = False" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 3 PlayerA)
                        |> .isBreakPoint
                        |> Expect.equal False
            , test "tiebreak point score does not affect break point stats" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 7 PlayerA)
                        |> .breakPoints
                        |> Expect.equal
                            { playerA = { opportunities = 0, converted = 0 }
                            , playerB = { opportunities = 0, converted = 0 }
                            }
            ]
        ]


step8Suite : Test
step8Suite =
    describe "Step 8 — Point totals and derived statistics"
        [ describe "total points played"
            [ test "no points → played = 0" <|
                \_ ->
                    deriveMatchState defaultConfig []
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 0
            , test "1 point → played = 1" <|
                \_ ->
                    deriveMatchState defaultConfig [ pointWonBy PlayerA ]
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 1
            , test "4 points → played = 4" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 4 PlayerA)
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 4
            , test "a full game (4 points) adds 4 to played" <|
                \_ ->
                    deriveMatchState defaultConfig (gameWonBy PlayerA)
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 4
            ]
        , describe "points won per player"
            [ test "4 points won by PlayerA → wonByPlayerA = 4, wonByPlayerB = 0" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 4 PlayerA)
                        |> .totalPoints
                        |> Expect.equal { played = 4, wonByPlayerA = 4, wonByPlayerB = 0 }
            , test "4 points won by PlayerB → wonByPlayerA = 0, wonByPlayerB = 4" <|
                \_ ->
                    deriveMatchState defaultConfig (nPointsWonBy 4 PlayerB)
                        |> .totalPoints
                        |> Expect.equal { played = 4, wonByPlayerA = 0, wonByPlayerB = 4 }
            , test "mixed points" <|
                \_ ->
                    deriveMatchState defaultConfig
                        (nPointsWonBy 3 PlayerA ++ nPointsWonBy 2 PlayerB)
                        |> .totalPoints
                        |> Expect.equal { played = 5, wonByPlayerA = 3, wonByPlayerB = 2 }
            ]
        , describe "serve outcome attribution"
            [ test "Ace awards point to the server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = Ace FirstServe } ]
                        |> .totalPoints
                        |> Expect.equal { played = 1, wonByPlayerA = 1, wonByPlayerB = 0 }
            , test "ServeWinner awards point to the server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = ServeWinner FirstServe } ]
                        |> .totalPoints
                        |> Expect.equal { played = 1, wonByPlayerA = 1, wonByPlayerB = 0 }
            , test "DoubleFault awards point to the receiver (PlayerB when PlayerA serves)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = DoubleFault } ]
                        |> .totalPoints
                        |> Expect.equal { played = 1, wonByPlayerA = 0, wonByPlayerB = 1 }
            , test "DoubleFault awards point to PlayerA when PlayerB serves" <|
                \_ ->
                    -- Start game 2 where PlayerB serves by first winning a game for PlayerA.
                    let
                        points =
                            gameWonBy PlayerA
                                ++ [ { server = PlayerB, outcome = DoubleFault } ]
                    in
                    deriveMatchState defaultConfig points
                        |> .totalPoints
                        |> Expect.equal { played = 5, wonByPlayerA = 5, wonByPlayerB = 0 }
            , test "InRally awards point to the rally winner regardless of server" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = InRally FirstServe PlayerB Nothing } ]
                        |> .totalPoints
                        |> Expect.equal { played = 1, wonByPlayerA = 0, wonByPlayerB = 1 }
            ]
        , describe "points counted across game and set boundaries"
            [ test "a full set (6 games x 4 points) → played = 24" <|
                \_ ->
                    deriveMatchState defaultConfig (setWonBy6_0 PlayerA)
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 24
            , test "tiebreak points are counted" <|
                \_ ->
                    -- sixSixPoints = 6 × (4 + 4) = 48 points; plus 7 tiebreak points.
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 7 PlayerA)
                        |> .totalPoints
                        |> .played
                        |> Expect.equal 55
            , test "tiebreak points attributed to correct player" <|
                \_ ->
                    -- sixSixPoints: PlayerA wins 24, PlayerB wins 24 (48 total).
                    -- 7 tiebreak points all for PlayerA → wonByPlayerA = 31, wonByPlayerB = 24.
                    deriveMatchState defaultConfig
                        (sixSixPoints ++ nPointsWonBy 7 PlayerA)
                        |> .totalPoints
                        |> Expect.equal { played = 55, wonByPlayerA = 31, wonByPlayerB = 24 }
            ]
        ]
