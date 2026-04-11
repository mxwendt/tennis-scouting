module LiveTracking exposing (Event(..), Model, Msg(..), PointEntry(..), init, update, view)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Match exposing (Match, Player(..), ServeOutcome(..), ServePhase(..))
import ScoreEngine exposing (GameScore(..), MatchState, deriveMatchState)



-- MODEL


type PointEntry
    = ServeResultEntry ServePhase
    | WhoWonEntry ServePhase
    | RallyResultEntry ServeOutcome


type alias Model =
    { match : Match
    , pointEntry : PointEntry
    , trackingStarted : Bool
    }


init : Match -> Model
init match =
    { match = match
    , pointEntry = ServeResultEntry FirstServe
    , trackingStarted = False
    }



-- EVENT


type Event
    = NoEvent
    | MatchUpdated Match
    | NavigateBack



-- MSG


type Msg
    = AceTapped
    | ServeWinnerTapped
    | FaultTapped
    | DoubleFaultTapped
    | InRallyTapped
    | RallyWonBy Player
    | SavePointTapped
    | UndoTapped
    | RestartTapped
    | ChangeServeResultTapped
    | BackTapped



-- UPDATE


update : Msg -> Model -> ( Model, Event )
update msg model =
    case msg of
        BackTapped ->
            ( model, NavigateBack )

        AceTapped ->
            case model.pointEntry of
                ServeResultEntry phase ->
                    ( { model
                        | pointEntry = RallyResultEntry (Ace phase)
                        , trackingStarted = True
                      }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        ServeWinnerTapped ->
            case model.pointEntry of
                ServeResultEntry phase ->
                    ( { model
                        | pointEntry = RallyResultEntry (ServeWinner phase)
                        , trackingStarted = True
                      }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        FaultTapped ->
            case model.pointEntry of
                ServeResultEntry FirstServe ->
                    ( { model
                        | pointEntry = ServeResultEntry SecondServe
                        , trackingStarted = True
                      }
                    , NoEvent
                    )

                ServeResultEntry SecondServe ->
                    -- Tapping the disabled Fault button reverses the fault,
                    -- returning to first-serve state. Equivalent to Undo.
                    ( { model
                        | pointEntry = ServeResultEntry FirstServe
                        , trackingStarted = False
                      }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        DoubleFaultTapped ->
            case model.pointEntry of
                ServeResultEntry SecondServe ->
                    ( { model
                        | pointEntry = RallyResultEntry DoubleFault
                        , trackingStarted = True
                      }
                    , NoEvent
                    )

                _ ->
                    -- No-op: button is truly disabled in first-serve state.
                    ( model, NoEvent )

        InRallyTapped ->
            case model.pointEntry of
                ServeResultEntry phase ->
                    ( { model
                        | pointEntry = WhoWonEntry phase
                        , trackingStarted = True
                      }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        RallyWonBy winner ->
            case model.pointEntry of
                WhoWonEntry phase ->
                    ( { model
                        | pointEntry = RallyResultEntry (InRally phase winner Nothing)
                      }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        SavePointTapped ->
            case model.pointEntry of
                RallyResultEntry outcome ->
                    let
                        matchState =
                            deriveMatchState model.match.config model.match.points

                        oldMatch =
                            model.match

                        point =
                            { server = matchState.currentServer
                            , outcome = outcome
                            }

                        newMatch =
                            { oldMatch | points = oldMatch.points ++ [ point ] }
                    in
                    ( { model
                        | match = newMatch
                        , pointEntry = ServeResultEntry FirstServe
                        , trackingStarted = False
                      }
                    , MatchUpdated newMatch
                    )

                _ ->
                    ( model, NoEvent )

        UndoTapped ->
            case model.pointEntry of
                ServeResultEntry FirstServe ->
                    ( model, NoEvent )

                ServeResultEntry SecondServe ->
                    ( { model
                        | pointEntry = ServeResultEntry FirstServe
                        , trackingStarted = False
                      }
                    , NoEvent
                    )

                WhoWonEntry phase ->
                    ( { model | pointEntry = ServeResultEntry phase }
                    , NoEvent
                    )

                RallyResultEntry outcome ->
                    ( { model | pointEntry = undoFromRallyResult outcome }
                    , NoEvent
                    )

        RestartTapped ->
            ( { model
                | pointEntry = ServeResultEntry FirstServe
                , trackingStarted = False
              }
            , NoEvent
            )

        ChangeServeResultTapped ->
            case model.pointEntry of
                ServeResultEntry _ ->
                    ( model, NoEvent )

                WhoWonEntry phase ->
                    ( { model | pointEntry = ServeResultEntry phase }
                    , NoEvent
                    )

                RallyResultEntry outcome ->
                    ( { model | pointEntry = ServeResultEntry (servePhaseOf outcome) }
                    , NoEvent
                    )



-- UPDATE HELPERS


undoFromRallyResult : ServeOutcome -> PointEntry
undoFromRallyResult outcome =
    case outcome of
        Ace phase ->
            ServeResultEntry phase

        ServeWinner phase ->
            ServeResultEntry phase

        DoubleFault ->
            ServeResultEntry SecondServe

        InRally phase _ _ ->
            WhoWonEntry phase


servePhaseOf : ServeOutcome -> ServePhase
servePhaseOf outcome =
    case outcome of
        Ace phase ->
            phase

        ServeWinner phase ->
            phase

        DoubleFault ->
            SecondServe

        InRally phase _ _ ->
            phase



-- VIEW


view : Model -> Html Msg
view model =
    let
        matchState =
            deriveMatchState model.match.config model.match.points
    in
    div [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto flex flex-col" ]
        [ viewHeader
        , div [ class "flex-1 overflow-y-auto" ]
            [ viewScoreboard matchState model.match
            , div [ class "px-4 pb-8 flex flex-col gap-3" ]
                [ viewStep1Collapsed matchState model.match
                , viewStep2 model
                , viewStep3 model
                , viewStep4 model
                ]
            ]
        , viewFooter model
        ]


viewHeader : Html Msg
viewHeader =
    div
        [ class "sticky top-0 z-10 bg-gray-900 border-b border-gray-700 flex items-center justify-between py-4 px-5" ]
        [ button
            [ onClick BackTapped
            , class "bg-transparent border-0 rounded-md text-gray-400 text-sm font-semibold cursor-pointer py-2 "
            ]
            [ text "← Matches" ]
        ]


viewScoreboard : MatchState -> Match -> Html Msg
viewScoreboard matchState match =
    div [ class "mx-4 mt-4 mb-1 bg-gray-800 rounded-xl p-4" ]
        [ div [ class "flex flex-col gap-[10px]" ]
            [ viewScoreRow PlayerA match.metadata.playerAName matchState
            , viewScoreRow PlayerB match.metadata.playerBName matchState
            ]
        ]


viewScoreRow : Player -> String -> MatchState -> Html Msg
viewScoreRow player name matchState =
    let
        isServing =
            matchState.currentServer == player

        setScoreValues =
            List.map
                (\s ->
                    case player of
                        PlayerA ->
                            s.playerA

                        PlayerB ->
                            s.playerB
                )
                matchState.setScores

        currentGames =
            case player of
                PlayerA ->
                    matchState.gameScore.playerA

                PlayerB ->
                    matchState.gameScore.playerB

        pointLabel =
            case matchState.tiebreak of
                Just tb ->
                    case player of
                        PlayerA ->
                            String.fromInt tb.playerA

                        PlayerB ->
                            String.fromInt tb.playerB

                Nothing ->
                    gameScoreLabel player matchState.pointScore
    in
    div [ class "flex items-center gap-2" ]
        [ div [ class "w-3 flex-shrink-0 text-center" ]
            [ if isServing then
                span [ class "text-amber-400 text-[10px]" ] [ text "●" ]

              else
                text ""
            ]
        , div [ class "flex-1 text-[15px] font-medium truncate" ]
            [ text name ]
        , div [ class "flex items-center gap-4" ]
            (List.map
                (\s ->
                    div [ class "text-[15px] text-gray-400 w-4 text-center" ]
                        [ text (String.fromInt s) ]
                )
                setScoreValues
                ++ [ div [ class "text-[15px] w-4 text-center" ]
                        [ text (String.fromInt currentGames) ]
                   , div [ class "text-[15px] w-8 text-right font-semibold" ]
                        [ text pointLabel ]
                   ]
            )
        ]


gameScoreLabel : Player -> { playerA : GameScore, playerB : GameScore } -> String
gameScoreLabel player scores =
    let
        myScore =
            case player of
                PlayerA ->
                    scores.playerA

                PlayerB ->
                    scores.playerB
    in
    case myScore of
        Love ->
            "0"

        Fifteen ->
            "15"

        Thirty ->
            "30"

        Forty ->
            "40"

        DeuceScore ->
            "40"

        Advantage p ->
            if p == player then
                "Ad"

            else
                "–"


viewStep1Collapsed : MatchState -> Match -> Html Msg
viewStep1Collapsed matchState match =
    let
        serverName =
            case matchState.currentServer of
                PlayerA ->
                    match.metadata.playerAName

                PlayerB ->
                    match.metadata.playerBName
    in
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-[6px]" ]
            [ text "Who is serving?" ]
        , div [ class "text-[15px] font-medium" ]
            [ text serverName ]
        ]


viewStep2 : Model -> Html Msg
viewStep2 model =
    case model.pointEntry of
        ServeResultEntry phase ->
            viewStep2Active phase

        WhoWonEntry _ ->
            viewStep2Collapsed "In — rally"

        RallyResultEntry outcome ->
            viewStep2Collapsed (serveOutcomeLabel outcome)


viewStep2Active : ServePhase -> Html Msg
viewStep2Active phase =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Serve result" ]
        , div [ class "grid grid-cols-2 gap-2" ]
            [ viewOutcomeButton "Serve winner" Enabled ServeWinnerTapped
            , viewOutcomeButton "Ace" Enabled AceTapped
            , viewFaultButton phase
            , viewDoubleFaultButton phase
            , button
                [ onClick InRallyTapped
                , class "col-span-2 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                ]
                [ text "In — rally" ]
            ]
        ]


type ButtonState
    = Enabled
    | LooksDisabled
    | Disabled


viewOutcomeButton : String -> ButtonState -> Msg -> Html Msg
viewOutcomeButton label state msg =
    case state of
        Enabled ->
            button
                [ onClick msg
                , class "bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                ]
                [ text label ]

        LooksDisabled ->
            -- Still interactive — tapping it reverses the fault.
            button
                [ onClick msg
                , class "bg-gray-800 text-gray-500 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                ]
                [ text label ]

        Disabled ->
            button
                [ disabled True
                , class "bg-gray-800 text-gray-500 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-not-allowed"
                ]
                [ text label ]


viewFaultButton : ServePhase -> Html Msg
viewFaultButton phase =
    case phase of
        FirstServe ->
            viewOutcomeButton "Fault" Enabled FaultTapped

        SecondServe ->
            viewOutcomeButton "Fault" LooksDisabled FaultTapped


viewDoubleFaultButton : ServePhase -> Html Msg
viewDoubleFaultButton phase =
    case phase of
        FirstServe ->
            viewOutcomeButton "Double fault" Disabled DoubleFaultTapped

        SecondServe ->
            viewOutcomeButton "Double fault" Enabled DoubleFaultTapped


viewStep2Collapsed : String -> Html Msg
viewStep2Collapsed outcomeLabel =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3 flex items-center justify-between" ]
        [ div []
            [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-[6px]" ]
                [ text "Serve result" ]
            , div [ class "text-[15px] font-medium" ]
                [ text outcomeLabel ]
            ]
        , button
            [ onClick ChangeServeResultTapped
            , class "bg-transparent border-0 text-amber-400 text-[14px] font-medium cursor-pointer px-0 py-0"
            ]
            [ text "Change" ]
        ]


viewStep3 : Model -> Html Msg
viewStep3 model =
    case model.pointEntry of
        ServeResultEntry _ ->
            viewStepLocked "Who won the point?"

        WhoWonEntry _ ->
            viewStep3Active model.match

        RallyResultEntry (InRally _ winner _) ->
            let
                winnerName =
                    case winner of
                        PlayerA ->
                            model.match.metadata.playerAName

                        PlayerB ->
                            model.match.metadata.playerBName
            in
            viewStepCollapsed "Who won the point?" winnerName

        RallyResultEntry _ ->
            viewStepHidden


viewStep3Active : Match -> Html Msg
viewStep3Active match =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Who won the point?" ]
        , div [ class "flex gap-2" ]
            [ button
                [ onClick (RallyWonBy PlayerA)
                , class "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                ]
                [ text match.metadata.playerAName ]
            , button
                [ onClick (RallyWonBy PlayerB)
                , class "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                ]
                [ text match.metadata.playerBName ]
            ]
        ]


viewStep4 : Model -> Html Msg
viewStep4 model =
    case model.pointEntry of
        ServeResultEntry _ ->
            viewStepLocked "Rally result"

        WhoWonEntry _ ->
            viewStepLocked "Rally result"

        RallyResultEntry _ ->
            viewStep4Active


viewStep4Active : Html Msg
viewStep4Active =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Rally result" ]
        , div [ class "bg-gray-700 rounded-lg px-[14px] py-[11px] text-[13px] text-gray-400 mb-3" ]
            [ text "Tagging coming soon" ]
        , button
            [ onClick SavePointTapped
            , class "w-full bg-amber-400 text-gray-900 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
            ]
            [ text "Save point" ]
        ]


viewStepLocked : String -> Html Msg
viewStepLocked label =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3 opacity-40" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium" ]
            [ text label ]
        ]


viewStepHidden : Html Msg
viewStepHidden =
    text ""


viewStepCollapsed : String -> String -> Html Msg
viewStepCollapsed label summary =
    div [ class "bg-gray-800 rounded-xl px-[14px] py-3" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-[6px]" ]
            [ text label ]
        , div [ class "text-[15px] font-medium" ]
            [ text summary ]
        ]


viewFooter : Model -> Html Msg
viewFooter model =
    div [ class "sticky bottom-0 bg-gray-900 border-t border-gray-700 px-4 py-4" ]
        [ if model.trackingStarted then
            div [ class "flex gap-3" ]
                [ button
                    [ onClick UndoTapped
                    , class "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                    ]
                    [ text "Undo" ]
                , button
                    [ onClick RestartTapped
                    , class "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
                    ]
                    [ text "Restart" ]
                ]

          else
            button
                [ class "w-full bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-default"
                ]
                [ text "View summary" ]
        ]


serveOutcomeLabel : ServeOutcome -> String
serveOutcomeLabel outcome =
    case outcome of
        Ace _ ->
            "Ace"

        ServeWinner _ ->
            "Serve winner"

        DoubleFault ->
            "Double fault"

        InRally _ _ _ ->
            "In — rally"
