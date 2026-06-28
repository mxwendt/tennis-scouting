module LiveTrackingTest exposing (..)

import Expect
import LiveTracking exposing (..)
import Match exposing (Match, MatchConfig, MatchFormat(..), MatchMetadata, Player(..), RallyTag(..), ServeOutcome(..), ServePhase(..), SetFormat(..), TiebreakFormat(..))
import Test exposing (Test, describe, test)



-- HELPERS


defaultConfig : MatchConfig
defaultConfig =
    { initialServer = PlayerA
    , matchFormat = BestOfThree
    , setFormat = StandardSet
    , tiebreakFormat = StandardPlusMatchTiebreak
    , deuceFormat = Match.StandardDeuce
    }


defaultMetadata : MatchMetadata
defaultMetadata =
    { playerAName = "Alice"
    , playerBName = "Bob"
    , surface = Nothing
    , date = "2025-01-01"
    }


defaultMatch : Match
defaultMatch =
    { id = 1
    , config = defaultConfig
    , metadata = defaultMetadata
    , points = []
    , finished = False
    }


freshModel : Model
freshModel =
    init defaultMatch


applyMsg : Msg -> Model -> Model
applyMsg msg model =
    update msg model |> Tuple.first


applyMsgs : List Msg -> Model -> Model
applyMsgs msgs model =
    List.foldl applyMsg model msgs



-- SUITE


suite : Test
suite =
    describe "Step 2 — Serve Result"
        [ describe "Serve winner"
            [ test "tapping Serve winner advances to Step 4 (rally result)" <|
                \_ ->
                    freshModel
                        |> applyMsg ServeWinnerTapped
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry (ServeWinner FirstServe))
            , test "tapping Serve winner starts tracking" <|
                \_ ->
                    freshModel
                        |> applyMsg ServeWinnerTapped
                        |> .trackingStarted
                        |> Expect.equal True
            , test "saving after Serve winner records the point for the server" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ ServeWinnerTapped, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = ServeWinner FirstServe } ]
                        points
            , test "saving after Serve winner resets to first-serve state" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ ServeWinnerTapped, SavePointTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "saving after Serve winner clears tracking" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ ServeWinnerTapped, SavePointTapped ]
                        |> .trackingStarted
                        |> Expect.equal False
            ]
        , describe "Ace"
            [ test "tapping Ace advances to Step 4 (rally result)" <|
                \_ ->
                    freshModel
                        |> applyMsg AceTapped
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry (Ace FirstServe))
            , test "tapping Ace starts tracking" <|
                \_ ->
                    freshModel
                        |> applyMsg AceTapped
                        |> .trackingStarted
                        |> Expect.equal True
            , test "saving after Ace records the point for the server" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ AceTapped, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = Ace FirstServe } ]
                        points
            ]
        , describe "Fault"
            [ test "tapping Fault transitions to second-serve state" <|
                \_ ->
                    freshModel
                        |> applyMsg FaultTapped
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry SecondServe)
            , test "tapping Fault starts tracking" <|
                \_ ->
                    freshModel
                        |> applyMsg FaultTapped
                        |> .trackingStarted
                        |> Expect.equal True
            , test "tapping the disabled Fault button reverses to first-serve state" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, FaultTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "fault reversal clears tracking" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, FaultTapped ]
                        |> .trackingStarted
                        |> Expect.equal False
            ]
        , describe "Double fault"
            [ test "tapping Double fault without prior Fault is a no-op" <|
                \_ ->
                    freshModel
                        |> applyMsg DoubleFaultTapped
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "tapping Double fault without prior Fault does not start tracking" <|
                \_ ->
                    freshModel
                        |> applyMsg DoubleFaultTapped
                        |> .trackingStarted
                        |> Expect.equal False
            , test "tapping Double fault after Fault advances to Step 4" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped ]
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry DoubleFault)
            , test "tapping Double fault after Fault starts tracking" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped ]
                        |> .trackingStarted
                        |> Expect.equal True
            , test "saving after Double fault records the point" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ FaultTapped, DoubleFaultTapped, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = DoubleFault } ]
                        points
            ]
        , describe "In — rally"
            [ test "tapping In — rally advances to Step 3 (who won)" <|
                \_ ->
                    freshModel
                        |> applyMsg InRallyTapped
                        |> .pointEntry
                        |> Expect.equal (WhoWonEntry FirstServe)
            , test "tapping In — rally does not record a point" <|
                \_ ->
                    freshModel
                        |> applyMsg InRallyTapped
                        |> .match
                        |> .points
                        |> Expect.equal []
            , test "tapping In — rally starts tracking" <|
                \_ ->
                    freshModel
                        |> applyMsg InRallyTapped
                        |> .trackingStarted
                        |> Expect.equal True
            , test "tapping In — rally after Fault carries second-serve phase to Step 3" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, InRallyTapped ]
                        |> .pointEntry
                        |> Expect.equal (WhoWonEntry SecondServe)
            ]
        , describe "Tracking trigger"
            [ test "initial model has tracking not started" <|
                \_ ->
                    freshModel
                        |> .trackingStarted
                        |> Expect.equal False
            , test "Fault tap starts tracking" <|
                \_ ->
                    freshModel |> applyMsg FaultTapped |> .trackingStarted |> Expect.equal True
            , test "Ace tap starts tracking" <|
                \_ ->
                    freshModel |> applyMsg AceTapped |> .trackingStarted |> Expect.equal True
            , test "Serve winner tap starts tracking" <|
                \_ ->
                    freshModel |> applyMsg ServeWinnerTapped |> .trackingStarted |> Expect.equal True
            , test "In — rally tap starts tracking" <|
                \_ ->
                    freshModel |> applyMsg InRallyTapped |> .trackingStarted |> Expect.equal True
            ]
        , describe "Serve phase preserved through Step 4"
            [ test "Ace on second serve records SecondServe phase" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ FaultTapped, AceTapped, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = Ace SecondServe } ]
                        points
            , test "Serve winner on second serve records SecondServe phase" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ FaultTapped, ServeWinnerTapped, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = ServeWinner SecondServe } ]
                        points
            ]
        , describe "Undo"
            [ test "Undo from second-serve state returns to first serve" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Undo from second-serve state clears tracking" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, UndoTapped ]
                        |> .trackingStarted
                        |> Expect.equal False
            , test "Undo from Step 3 (WhoWon) returns to serve result" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ InRallyTapped, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Undo from Step 4 (Ace) returns to serve result" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ AceTapped, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Undo from Step 4 (ServeWinner) returns to serve result" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ ServeWinnerTapped, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Undo from Step 4 (DoubleFault) returns to second-serve state" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry SecondServe)
            , test "Undo from Step 4 (InRally) returns to Step 3 (WhoWon)" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ InRallyTapped, RallyWonBy PlayerB, UndoTapped ]
                        |> .pointEntry
                        |> Expect.equal (WhoWonEntry FirstServe)
            ]
        , describe "Restart"
            [ test "Restart always resets to first-serve state" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped, RestartTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Restart clears tracking" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ AceTapped, RestartTapped ]
                        |> .trackingStarted
                        |> Expect.equal False
            ]
        , describe "Change serve result"
            [ test "Change from Step 3 (WhoWon first serve) returns to Step 2 first serve" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ InRallyTapped, ChangeServeResultTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Change from Step 3 (WhoWon second serve) returns to Step 2 second serve" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, InRallyTapped, ChangeServeResultTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry SecondServe)
            , test "Change from Step 4 (Ace first serve) returns to Step 2 first serve" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ AceTapped, ChangeServeResultTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry FirstServe)
            , test "Change from Step 4 (DoubleFault) returns to Step 2 second serve" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped, ChangeServeResultTapped ]
                        |> .pointEntry
                        |> Expect.equal (ServeResultEntry SecondServe)
            ]
        , describe "Step 3 — Who won the rally"
            [ test "RallyWonBy advances from Step 3 to Step 4" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA ]
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA Nothing))
            , test "saving after rally win records the correct outcome" <|
                \_ ->
                    let
                        points =
                            freshModel
                                |> applyMsgs [ InRallyTapped, RallyWonBy PlayerB, SavePointTapped ]
                                |> .match
                                |> .points
                    in
                    Expect.equal
                        [ { server = PlayerA, outcome = InRally FirstServe PlayerB Nothing } ]
                        points
            ]
        , describe "Step 4 — Rally result"
            [ describe "Serve path"
                [ test "Step 4 on Ace path holds no tag" <|
                    \_ ->
                        freshModel
                            |> applyMsg AceTapped
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (Ace FirstServe))
                , test "Step 4 on Serve winner path holds no tag" <|
                    \_ ->
                        freshModel
                            |> applyMsg ServeWinnerTapped
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (ServeWinner FirstServe))
                , test "Step 4 on Double fault path holds no tag" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ FaultTapped, DoubleFaultTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry DoubleFault)
                , test "Undo on serve path steps back to Step 2" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ AceTapped, UndoTapped ]
                            |> .pointEntry
                            |> Expect.equal (ServeResultEntry FirstServe)
                ]
            , describe "Rally path — tagging"
                [ test "Step 4 opens after Step 3 with no tag selected" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA Nothing))
                , test "tapping Winner selects it" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, WinnerTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA (Just Winner)))
                , test "tapping Winner again deselects it" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, WinnerTagTapped, WinnerTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA Nothing))
                , test "tapping Unforced error selects it" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, UnforcedErrorTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA (Just UnforcedError)))
                , test "tapping Unforced error again deselects it" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, UnforcedErrorTagTapped, UnforcedErrorTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA Nothing))
                , test "selecting Winner while Unforced error is active deselects Unforced error" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, UnforcedErrorTagTapped, WinnerTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA (Just Winner)))
                , test "selecting Unforced error while Winner is active deselects Winner" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, WinnerTagTapped, UnforcedErrorTagTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA (Just UnforcedError)))
                , test "Save point without tag records outcome as untagged" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerB, SavePointTapped ]
                            |> .match
                            |> .points
                            |> Expect.equal [ { server = PlayerA, outcome = InRally FirstServe PlayerB Nothing } ]
                , test "Save point with Winner tag records the winner tag" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, WinnerTagTapped, SavePointTapped ]
                            |> .match
                            |> .points
                            |> Expect.equal [ { server = PlayerA, outcome = InRally FirstServe PlayerA (Just Winner) } ]
                , test "Save point with Unforced error tag records the unforced error tag" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerB, UnforcedErrorTagTapped, SavePointTapped ]
                            |> .match
                            |> .points
                            |> Expect.equal [ { server = PlayerA, outcome = InRally FirstServe PlayerB (Just UnforcedError) } ]
                , test "Undo on rally path with tag selected deselects the tag" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, WinnerTagTapped, UndoTapped ]
                            |> .pointEntry
                            |> Expect.equal (RallyResultEntry (InRally FirstServe PlayerA Nothing))
                , test "Undo on rally path with no tag steps back to Step 3" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, UndoTapped ]
                            |> .pointEntry
                            |> Expect.equal (WhoWonEntry FirstServe)
                ]
            , describe "Save point shared behaviour"
                [ test "Save point resets to first-serve state" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, SavePointTapped ]
                            |> .pointEntry
                            |> Expect.equal (ServeResultEntry FirstServe)
                , test "Save point clears trackingStarted" <|
                    \_ ->
                        freshModel
                            |> applyMsgs [ InRallyTapped, RallyWonBy PlayerA, SavePointTapped ]
                            |> .trackingStarted
                            |> Expect.equal False
                ]
            ]
        , describe "Collapsed Step 2 summary label"
            [ test "Ace outcome produces label Ace" <|
                \_ ->
                    freshModel
                        |> applyMsg AceTapped
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry (Ace FirstServe))
            , test "ServeWinner outcome produces correct entry" <|
                \_ ->
                    freshModel
                        |> applyMsg ServeWinnerTapped
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry (ServeWinner FirstServe))
            , test "DoubleFault outcome produces correct entry" <|
                \_ ->
                    freshModel
                        |> applyMsgs [ FaultTapped, DoubleFaultTapped ]
                        |> .pointEntry
                        |> Expect.equal (RallyResultEntry DoubleFault)
            , test "InRally outcome in Step 3 is WhoWonEntry" <|
                \_ ->
                    freshModel
                        |> applyMsg InRallyTapped
                        |> .pointEntry
                        |> Expect.equal (WhoWonEntry FirstServe)
            ]
        ]
