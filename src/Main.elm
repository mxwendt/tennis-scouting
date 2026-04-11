port module Main exposing (main)

import Browser
import Html exposing (Html, button, div, h1, p, text)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Encode as Encode
import Match exposing (DeuceFormat(..), Match, MatchConfig, MatchFormat(..), MatchMetadata, Player(..), Point, RallyTag(..), ServeOutcome(..), SetFormat(..), Surface(..), TiebreakFormat(..))
import MatchSetup


port saveState : Encode.Value -> Cmd msg



-- MODEL


type Page
    = MatchListPage
    | MatchSetupPage MatchSetup.Model
    | LiveTrackingPage Match


type alias Model =
    { page : Page
    , matches : List Match
    , nextId : Int
    , today : String
    }


type alias SavedState =
    { nextId : Int
    , matches : List Match
    }



-- MAIN


main : Program Decode.Value Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- INIT


init : Decode.Value -> ( Model, Cmd Msg )
init flags =
    let
        today =
            flags
                |> Decode.decodeValue (Decode.field "today" Decode.string)
                |> Result.withDefault "2025-01-01"

        saved =
            flags
                |> Decode.decodeValue (Decode.field "savedState" (Decode.nullable decodeSavedState))
                |> Result.withDefault Nothing
                |> Maybe.withDefault { nextId = 1, matches = [] }
    in
    ( { page = MatchListPage
      , matches = saved.matches
      , nextId = saved.nextId
      , today = today
      }
    , Cmd.none
    )



-- MSG


type Msg
    = OpenMatchSetup
    | MatchSetupMsg MatchSetup.Msg
    | OpenMatch Match
    | NavigateToMatchList



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OpenMatchSetup ->
            ( { model | page = MatchSetupPage (MatchSetup.init model.today) }
            , Cmd.none
            )

        MatchSetupMsg subMsg ->
            case model.page of
                MatchSetupPage setupModel ->
                    let
                        ( newSetupModel, event ) =
                            MatchSetup.update subMsg setupModel
                    in
                    case event of
                        MatchSetup.NoEvent ->
                            ( { model | page = MatchSetupPage newSetupModel }
                            , Cmd.none
                            )

                        MatchSetup.FormSubmitted config metadata ->
                            let
                                newMatch =
                                    { id = model.nextId
                                    , config = config
                                    , metadata = metadata
                                    , points = []
                                    }

                                newMatches =
                                    model.matches ++ [ newMatch ]

                                newModel =
                                    { model
                                        | matches = newMatches
                                        , nextId = model.nextId + 1
                                        , page = LiveTrackingPage newMatch
                                    }
                            in
                            ( newModel
                            , saveState
                                (encodeSavedState
                                    { nextId = newModel.nextId
                                    , matches = newMatches
                                    }
                                )
                            )

                        MatchSetup.FormCancelled ->
                            ( { model | page = MatchListPage }
                            , Cmd.none
                            )

                _ ->
                    ( model, Cmd.none )

        OpenMatch match ->
            ( { model | page = LiveTrackingPage match }
            , Cmd.none
            )

        NavigateToMatchList ->
            ( { model | page = MatchListPage }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    case model.page of
        MatchListPage ->
            viewMatchList model

        MatchSetupPage setupModel ->
            Html.map MatchSetupMsg (MatchSetup.view setupModel)

        LiveTrackingPage match ->
            viewLiveTracking match



-- MATCH LIST


viewMatchList : Model -> Html Msg
viewMatchList model =
    div
        [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto" ]
        [ div
            [ class "flex items-center justify-between px-5 pt-5 pb-4" ]
            [ h1
                [ class "text-[22px] font-bold m-0" ]
                [ text "Matches" ]
            , button
                [ onClick OpenMatchSetup
                , class "bg-amber-400 text-gray-900 border-0 rounded-[10px] py-[10px] px-[18px] text-sm font-semibold cursor-pointer"
                ]
                [ text "New Match" ]
            ]
        , if List.isEmpty model.matches then
            viewEmptyState

          else
            div [ class "px-4" ]
                (List.map viewMatchRow (List.reverse model.matches))
        ]


viewEmptyState : Html Msg
viewEmptyState =
    div
        [ class "flex flex-col items-center justify-center py-20 px-8 text-center" ]
        [ div
            [ class "text-[40px] mb-4" ]
            [ text "🎾" ]
        , p
            [ class "text-base text-gray-400 m-0 mb-2" ]
            [ text "No matches yet" ]
        , p
            [ class "text-sm text-gray-500 m-0" ]
            [ text "Tap New Match to start tracking" ]
        ]


viewMatchRow : Match -> Html Msg
viewMatchRow match =
    button
        [ onClick (OpenMatch match)
        , class "flex items-center justify-between w-full bg-gray-800 border-0 rounded-xl py-[14px] px-4 mb-2 cursor-pointer text-left text-gray-50 box-border"
        ]
        [ div []
            [ div
                [ class "text-[15px] font-semibold mb-1" ]
                [ text (match.metadata.playerAName ++ " vs " ++ match.metadata.playerBName) ]
            , div
                [ class "text-xs text-gray-400" ]
                [ text match.metadata.date ]
            ]
        , div
            [ class "text-[11px] text-amber-400 font-medium" ]
            [ text "In Progress" ]
        ]



-- LIVE TRACKING (stub)


viewLiveTracking : Match -> Html Msg
viewLiveTracking match =
    div
        [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto" ]
        [ div
            [ class "flex items-center py-4 px-5 border-b border-gray-700" ]
            [ button
                [ onClick NavigateToMatchList
                , class "bg-transparent border-0 text-gray-400 text-[15px] cursor-pointer p-0"
                ]
                [ text "← Matches" ]
            ]
        , div
            [ class "py-6 px-5" ]
            [ div
                [ class "text-center mb-8" ]
                [ div
                    [ class "text-[22px] font-bold mb-[6px]" ]
                    [ text (match.metadata.playerAName ++ " vs " ++ match.metadata.playerBName) ]
                , div
                    [ class "text-[13px] text-gray-400" ]
                    [ text match.metadata.date ]
                ]
            , div
                [ class "bg-gray-800 rounded-xl p-5 text-center text-gray-500 text-sm" ]
                [ text "Live tracking coming soon" ]
            ]
        ]



-- JSON ENCODING


encodeSavedState : SavedState -> Encode.Value
encodeSavedState state =
    Encode.object
        [ ( "nextId", Encode.int state.nextId )
        , ( "matches", Encode.list encodeMatch state.matches )
        ]


encodeMatch : Match -> Encode.Value
encodeMatch match =
    Encode.object
        [ ( "id", Encode.int match.id )
        , ( "config", encodeMatchConfig match.config )
        , ( "metadata", encodeMatchMetadata match.metadata )
        , ( "points", Encode.list encodePoint match.points )
        ]


encodeMatchConfig : MatchConfig -> Encode.Value
encodeMatchConfig config =
    Encode.object
        [ ( "initialServer", encodePlayer config.initialServer )
        , ( "matchFormat", encodeMatchFormat config.matchFormat )
        , ( "setFormat", encodeSetFormat config.setFormat )
        , ( "tiebreakFormat", encodeTiebreakFormat )
        , ( "deuceFormat", encodeDeuceFormat config.deuceFormat )
        ]


encodeMatchMetadata : MatchMetadata -> Encode.Value
encodeMatchMetadata metadata =
    Encode.object
        [ ( "playerAName", Encode.string metadata.playerAName )
        , ( "playerBName", Encode.string metadata.playerBName )
        , ( "surface"
          , case metadata.surface of
                Nothing ->
                    Encode.null

                Just surface ->
                    encodeSurface surface
          )
        , ( "date", Encode.string metadata.date )
        ]


encodePoint : Point -> Encode.Value
encodePoint point =
    Encode.object
        [ ( "server", encodePlayer point.server )
        , ( "outcome", encodeServeOutcome point.outcome )
        ]


encodeServeOutcome : ServeOutcome -> Encode.Value
encodeServeOutcome outcome =
    case outcome of
        Ace ->
            Encode.string "Ace"

        ServeWinner ->
            Encode.string "ServeWinner"

        DoubleFault ->
            Encode.string "DoubleFault"

        InRally winner maybeTag ->
            Encode.object
                [ ( "type", Encode.string "InRally" )
                , ( "winner", encodePlayer winner )
                , ( "tag"
                  , case maybeTag of
                        Nothing ->
                            Encode.null

                        Just tag ->
                            encodeRallyTag tag
                  )
                ]


encodeRallyTag : RallyTag -> Encode.Value
encodeRallyTag tag =
    case tag of
        Winner ->
            Encode.string "Winner"


encodePlayer : Player -> Encode.Value
encodePlayer player =
    case player of
        PlayerA ->
            Encode.string "PlayerA"

        PlayerB ->
            Encode.string "PlayerB"


encodeMatchFormat : MatchFormat -> Encode.Value
encodeMatchFormat format =
    case format of
        BestOfThree ->
            Encode.string "BestOfThree"

        BestOfFive ->
            Encode.string "BestOfFive"


encodeSetFormat : SetFormat -> Encode.Value
encodeSetFormat format =
    case format of
        StandardSet ->
            Encode.string "StandardSet"

        ProSet ->
            Encode.string "ProSet"


encodeTiebreakFormat : Encode.Value
encodeTiebreakFormat =
    Encode.string "StandardPlusMatchTiebreak"


encodeDeuceFormat : DeuceFormat -> Encode.Value
encodeDeuceFormat format =
    case format of
        StandardDeuce ->
            Encode.string "StandardDeuce"

        NoAd ->
            Encode.string "NoAd"


encodeSurface : Surface -> Encode.Value
encodeSurface surface =
    case surface of
        Hard ->
            Encode.string "Hard"

        Clay ->
            Encode.string "Clay"

        Grass ->
            Encode.string "Grass"

        Carpet ->
            Encode.string "Carpet"



-- JSON DECODING


decodeSavedState : Decode.Decoder SavedState
decodeSavedState =
    Decode.map2 SavedState
        (Decode.field "nextId" Decode.int)
        (Decode.field "matches" (Decode.list decodeMatch))


decodeMatch : Decode.Decoder Match
decodeMatch =
    Decode.map4
        (\id config metadata points ->
            { id = id, config = config, metadata = metadata, points = points }
        )
        (Decode.field "id" Decode.int)
        (Decode.field "config" decodeMatchConfig)
        (Decode.field "metadata" decodeMatchMetadata)
        (Decode.field "points" (Decode.list decodePoint))


decodeMatchConfig : Decode.Decoder MatchConfig
decodeMatchConfig =
    Decode.map5
        (\server format set tb deuce ->
            { initialServer = server
            , matchFormat = format
            , setFormat = set
            , tiebreakFormat = tb
            , deuceFormat = deuce
            }
        )
        (Decode.field "initialServer" decodePlayer)
        (Decode.field "matchFormat" decodeMatchFormat)
        (Decode.field "setFormat" decodeSetFormat)
        (Decode.field "tiebreakFormat" decodeTiebreakFormat)
        (Decode.field "deuceFormat" decodeDeuceFormat)


decodeMatchMetadata : Decode.Decoder MatchMetadata
decodeMatchMetadata =
    Decode.map4
        (\a b s d ->
            { playerAName = a
            , playerBName = b
            , surface = s
            , date = d
            }
        )
        (Decode.field "playerAName" Decode.string)
        (Decode.field "playerBName" Decode.string)
        (Decode.field "surface" (Decode.nullable decodeSurface))
        (Decode.field "date" Decode.string)


decodePoint : Decode.Decoder Point
decodePoint =
    Decode.map2
        (\server outcome -> { server = server, outcome = outcome })
        (Decode.field "server" decodePlayer)
        (Decode.field "outcome" decodeServeOutcome)


decodeServeOutcome : Decode.Decoder ServeOutcome
decodeServeOutcome =
    Decode.oneOf
        [ Decode.string
            |> Decode.andThen
                (\s ->
                    case s of
                        "Ace" ->
                            Decode.succeed Ace

                        "ServeWinner" ->
                            Decode.succeed ServeWinner

                        "DoubleFault" ->
                            Decode.succeed DoubleFault

                        _ ->
                            Decode.fail ("Unknown serve outcome: " ++ s)
                )
        , Decode.map2
            InRally
            (Decode.field "winner" decodePlayer)
            (Decode.field "tag" (Decode.nullable decodeRallyTag))
        ]


decodeRallyTag : Decode.Decoder RallyTag
decodeRallyTag =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "Winner" ->
                        Decode.succeed Winner

                    _ ->
                        Decode.fail ("Unknown rally tag: " ++ s)
            )


decodePlayer : Decode.Decoder Player
decodePlayer =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "PlayerA" ->
                        Decode.succeed PlayerA

                    "PlayerB" ->
                        Decode.succeed PlayerB

                    _ ->
                        Decode.fail ("Unknown player: " ++ s)
            )


decodeMatchFormat : Decode.Decoder MatchFormat
decodeMatchFormat =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "BestOfThree" ->
                        Decode.succeed BestOfThree

                    "BestOfFive" ->
                        Decode.succeed BestOfFive

                    _ ->
                        Decode.fail ("Unknown match format: " ++ s)
            )


decodeSetFormat : Decode.Decoder SetFormat
decodeSetFormat =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "StandardSet" ->
                        Decode.succeed StandardSet

                    "ProSet" ->
                        Decode.succeed ProSet

                    _ ->
                        Decode.fail ("Unknown set format: " ++ s)
            )


decodeTiebreakFormat : Decode.Decoder TiebreakFormat
decodeTiebreakFormat =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "StandardPlusMatchTiebreak" ->
                        Decode.succeed StandardPlusMatchTiebreak

                    _ ->
                        Decode.fail ("Unknown tiebreak format: " ++ s)
            )


decodeDeuceFormat : Decode.Decoder DeuceFormat
decodeDeuceFormat =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "StandardDeuce" ->
                        Decode.succeed StandardDeuce

                    "NoAd" ->
                        Decode.succeed NoAd

                    _ ->
                        Decode.fail ("Unknown deuce format: " ++ s)
            )


decodeSurface : Decode.Decoder Surface
decodeSurface =
    Decode.string
        |> Decode.andThen
            (\s ->
                case s of
                    "Hard" ->
                        Decode.succeed Hard

                    "Clay" ->
                        Decode.succeed Clay

                    "Grass" ->
                        Decode.succeed Grass

                    "Carpet" ->
                        Decode.succeed Carpet

                    _ ->
                        Decode.fail ("Unknown surface: " ++ s)
            )
