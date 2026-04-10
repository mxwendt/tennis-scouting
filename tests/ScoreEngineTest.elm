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
    , deuceFormat = StandardDeuce
    }


{-| A simple rally point awarded to the given player (server is always PlayerA
in these helpers; serve outcome tests use explicit Point records instead).
-}
pointWonBy : Player -> Point
pointWonBy winner =
    { server = PlayerA
    , outcome = InRally winner Nothing
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
                        [ { server = PlayerA, outcome = Ace } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "serve winner is won by server (PlayerA)" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = ServeWinner } ]
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
                        [ { server = PlayerA, outcome = InRally PlayerB Nothing } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Love, playerB = Fifteen }
            , test "rally won by PlayerA while PlayerB serves → PlayerA scores" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerB, outcome = InRally PlayerA Nothing } ]
                        |> .pointScore
                        |> Expect.equal { playerA = Fifteen, playerB = Love }
            , test "rally with a tag still attributes correctly" <|
                \_ ->
                    deriveMatchState defaultConfig
                        [ { server = PlayerA, outcome = InRally PlayerA (Just Winner) } ]
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
                    pointWinner { server = PlayerA, outcome = Ace }
                        |> Expect.equal PlayerA
            , test "ServeWinner → server wins" <|
                \_ ->
                    pointWinner { server = PlayerB, outcome = ServeWinner }
                        |> Expect.equal PlayerB
            , test "DoubleFault → receiver wins" <|
                \_ ->
                    pointWinner { server = PlayerA, outcome = DoubleFault }
                        |> Expect.equal PlayerB
            , test "InRally PlayerA → PlayerA wins regardless of server" <|
                \_ ->
                    pointWinner { server = PlayerB, outcome = InRally PlayerA Nothing }
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
