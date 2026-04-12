module LiveTracking exposing (Event(..), Model, Msg(..), PointEntry(..), init, update, view)

import Html exposing (Html, button, div, span, text)
import Html.Attributes exposing (class, disabled)
import Html.Events exposing (onClick)
import Match exposing (Match, MatchFormat(..), Player(..), RallyTag(..), ServeOutcome(..), ServePhase(..))
import ScoreEngine exposing (GameScore(..), MatchState, deriveMatchState, otherPlayer)



-- MODEL


type PointEntry
    = ServeResultEntry ServePhase
    | WhoWonEntry ServePhase
    | RallyResultEntry ServeOutcome


type alias Model =
    { match : Match
    , pointEntry : PointEntry
    , trackingStarted : Bool
    , step1Expanded : Bool
    , serverOverride : Maybe Player
    }


init : Match -> Model
init match =
    { match = match
    , pointEntry = ServeResultEntry FirstServe
    , trackingStarted = False
    , step1Expanded = False
    , serverOverride = Nothing
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
    | WinnerTagTapped
    | UnforcedErrorTagTapped
    | SavePointTapped
    | UndoTapped
    | RestartTapped
    | ChangeServeResultTapped
    | BackTapped
    | Step1Tapped
    | ServerOverrideTapped Player



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

        WinnerTagTapped ->
            case model.pointEntry of
                RallyResultEntry (InRally phase winner tag) ->
                    let
                        newTag =
                            case tag of
                                Just Winner ->
                                    Nothing

                                _ ->
                                    Just Winner
                    in
                    ( { model | pointEntry = RallyResultEntry (InRally phase winner newTag) }
                    , NoEvent
                    )

                _ ->
                    ( model, NoEvent )

        UnforcedErrorTagTapped ->
            case model.pointEntry of
                RallyResultEntry (InRally phase winner tag) ->
                    let
                        newTag =
                            case tag of
                                Just UnforcedError ->
                                    Nothing

                                _ ->
                                    Just UnforcedError
                    in
                    ( { model | pointEntry = RallyResultEntry (InRally phase winner newTag) }
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
                            { server = Maybe.withDefault matchState.currentServer model.serverOverride
                            , outcome = outcome
                            }

                        newMatch =
                            { oldMatch | points = oldMatch.points ++ [ point ] }
                    in
                    ( { model
                        | match = newMatch
                        , pointEntry = ServeResultEntry FirstServe
                        , trackingStarted = False
                        , serverOverride = Nothing
                        , step1Expanded = False
                      }
                    , MatchUpdated newMatch
                    )

                _ ->
                    ( model, NoEvent )

        UndoTapped ->
            case model.pointEntry of
                ServeResultEntry FirstServe ->
                    case model.serverOverride of
                        Just _ ->
                            ( { model
                                | serverOverride = Nothing
                                , trackingStarted = False
                                , step1Expanded = False
                              }
                            , NoEvent
                            )

                        Nothing ->
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

                RallyResultEntry (InRally phase winner (Just _)) ->
                    ( { model | pointEntry = RallyResultEntry (InRally phase winner Nothing) }
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
                , serverOverride = Nothing
                , step1Expanded = False
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

        Step1Tapped ->
            ( { model | step1Expanded = not model.step1Expanded }, NoEvent )

        ServerOverrideTapped player ->
            let
                matchState =
                    deriveMatchState model.match.config model.match.points

                effectiveServer =
                    Maybe.withDefault matchState.currentServer model.serverOverride
            in
            if player == effectiveServer then
                ( { model | step1Expanded = False }, NoEvent )

            else
                ( { model
                    | serverOverride = Just player
                    , step1Expanded = False
                    , trackingStarted = True
                  }
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

        effectiveMatchState =
            case model.serverOverride of
                Just server ->
                    { matchState | currentServer = server }

                Nothing ->
                    matchState
    in
    div [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto flex flex-col" ]
        [ viewHeader
        , div [ class "flex-1 overflow-y-auto" ]
            [ viewScoreboard effectiveMatchState model.match
            , div [ class "px-4 pb-8 flex flex-col gap-2" ]
                [ viewStep1 model effectiveMatchState
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
    div [ class "mx-4 mt-2 mb-4 bg-gray-900 rounded-xl py-4" ]
        [ div [ class "flex flex-col gap-[10px]" ]
            [ viewScoreRow PlayerA match.metadata.playerAName match.config.matchFormat matchState
            , viewScoreRow PlayerB match.metadata.playerBName match.config.matchFormat matchState
            ]
        ]


viewScoreRow : Player -> String -> MatchFormat -> MatchState -> Html Msg
viewScoreRow player name matchFormat matchState =
    let
        isServing =
            matchState.currentServer == player

        totalSets =
            case matchFormat of
                BestOfThree ->
                    3

                BestOfFive ->
                    5

        completedSetValues =
            List.map
                (\s ->
                    case player of
                        PlayerA ->
                            s.playerA

                        PlayerB ->
                            s.playerB
                )
                matchState.setScores

        futureSetsCount =
            totalSets - 1 - List.length completedSetValues

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
                completedSetValues
                ++ [ div [ class "text-[15px] w-4 text-center" ]
                        [ text (String.fromInt currentGames) ]
                   ]
                ++ List.repeat futureSetsCount
                    (div [ class "text-[15px] text-gray-400 w-4 text-center" ]
                        [ text "0" ]
                    )
                ++ [ div [ class "text-[15px] w-8 text-right font-semibold" ]
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


playerName : Match -> Player -> String
playerName match player =
    case player of
        PlayerA ->
            match.metadata.playerAName

        PlayerB ->
            match.metadata.playerBName


viewStep1 : Model -> MatchState -> Html Msg
viewStep1 model matchState =
    if model.step1Expanded then
        viewStep1Expanded model.match matchState model.serverOverride

    else
        viewStep1Collapsed model.match matchState model.serverOverride


viewStep1Collapsed : Match -> MatchState -> Maybe Player -> Html Msg
viewStep1Collapsed match matchState serverOverride =
    let
        effectiveServer =
            Maybe.withDefault matchState.currentServer serverOverride
    in
    div
        [ onClick Step1Tapped
        , class "bg-gray-800 rounded-xl p-4 flex items-center justify-between cursor-pointer"
        ]
        [ div []
            [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-[6px]" ]
                [ text "Who is serving?" ]
            , div [ class "text-[15px] font-medium" ]
                [ text (playerName match effectiveServer) ]
            ]
        , span
            [ class "text-amber-400 text-[14px] font-medium" ]
            [ text "Change" ]
        ]


viewStep1Expanded : Match -> MatchState -> Maybe Player -> Html Msg
viewStep1Expanded match matchState serverOverride =
    let
        effectiveServer =
            Maybe.withDefault matchState.currentServer serverOverride
    in
    div [ class "bg-gray-800 rounded-xl p-4" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Who is serving?" ]
        , div [ class "flex gap-2" ]
            [ viewServerButton (playerName match PlayerA) PlayerA effectiveServer
            , viewServerButton (playerName match PlayerB) PlayerB effectiveServer
            ]
        ]


viewServerButton : String -> Player -> Player -> Html Msg
viewServerButton name player effectiveServer =
    let
        cls =
            if player == effectiveServer then
                "flex-1 bg-amber-400 text-gray-900 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"

            else
                "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
    in
    button
        [ onClick (ServerOverrideTapped player)
        , class cls
        ]
        [ text name ]


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
    div [ class "bg-gray-800 rounded-xl px-4 py-3" ]
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
    div [ class "bg-gray-800 rounded-xl px-4 py-3 flex items-center justify-between" ]
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
    div [ class "bg-gray-800 rounded-xl p-4" ]
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

        RallyResultEntry (InRally _ winner tag) ->
            viewStep4RallyActive model.match winner tag

        RallyResultEntry _ ->
            viewStep4ServeActive


viewStep4ServeActive : Html Msg
viewStep4ServeActive =
    div [ class "bg-gray-800 rounded-xl p-4" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Rally result" ]
        , button
            [ onClick SavePointTapped
            , class "w-full bg-amber-400 text-gray-900 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
            ]
            [ text "Save point" ]
        ]


viewStep4RallyActive : Match -> Player -> Maybe RallyTag -> Html Msg
viewStep4RallyActive match winner maybeTag =
    let
        loser =
            otherPlayer winner
    in
    div [ class "bg-gray-800 rounded-xl p-4" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium mb-3" ]
            [ text "Rally result" ]
        , div [ class "flex gap-2 mb-3" ]
            [ viewTagButton "Winner"
                ("by " ++ playerName match winner)
                (maybeTag == Just Winner)
                WinnerTagTapped
            , viewTagButton "Unforced error"
                ("by " ++ playerName match loser)
                (maybeTag == Just UnforcedError)
                UnforcedErrorTagTapped
            ]
        , button
            [ onClick SavePointTapped
            , class "w-full bg-amber-400 text-gray-900 border-0 rounded-xl py-4 text-[15px] font-semibold cursor-pointer"
            ]
            [ text "Save point" ]
        ]


viewTagButton : String -> String -> Bool -> Msg -> Html Msg
viewTagButton label subline isSelected msg =
    let
        cls =
            if isSelected then
                "flex-1 bg-amber-400 text-gray-900 border-0 rounded-xl py-3 px-3 cursor-pointer text-left"

            else
                "flex-1 bg-gray-700 text-gray-50 border-0 rounded-xl py-3 px-3 cursor-pointer text-left"

        sublineCls =
            if isSelected then
                "text-[12px] text-gray-800 mt-[2px]"

            else
                "text-[12px] text-gray-400 mt-[2px]"
    in
    button
        [ onClick msg
        , class cls
        ]
        [ div [ class "text-[14px] font-semibold" ] [ text label ]
        , div [ class sublineCls ] [ text subline ]
        ]


viewStepLocked : String -> Html Msg
viewStepLocked label =
    div [ class "bg-gray-800 rounded-xl p-4 opacity-40" ]
        [ div [ class "text-[11px] text-gray-500 uppercase tracking-[0.05em] font-medium" ]
            [ text label ]
        ]


viewStepHidden : Html Msg
viewStepHidden =
    text ""


viewStepCollapsed : String -> String -> Html Msg
viewStepCollapsed label summary =
    div [ class "bg-gray-800 rounded-xl p-4" ]
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
