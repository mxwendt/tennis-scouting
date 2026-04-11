module MatchSetup exposing (Event(..), Model, Msg, init, update, view)

import Html exposing (Html, button, div, h1, input, text)
import Html.Attributes exposing (class, disabled, placeholder, type_, value)
import Html.Events exposing (onClick, onInput)
import Match exposing (DeuceFormat(..), MatchConfig, MatchFormat(..), MatchMetadata, Player(..), SetFormat(..), Surface(..), TiebreakFormat(..))



-- MODEL


type alias Model =
    { playerAName : String
    , playerBName : String
    , initialServer : Maybe Player
    , matchFormat : MatchFormat
    , setFormat : SetFormat
    , deuceFormat : DeuceFormat
    , surface : Maybe Surface
    , date : String
    }


init : String -> Model
init today =
    { playerAName = ""
    , playerBName = ""
    , initialServer = Nothing
    , matchFormat = BestOfThree
    , setFormat = StandardSet
    , deuceFormat = StandardDeuce
    , surface = Nothing
    , date = today
    }



-- EVENT


type Event
    = NoEvent
    | FormSubmitted MatchConfig MatchMetadata
    | FormCancelled



-- MSG


type Msg
    = PlayerANameChanged String
    | PlayerBNameChanged String
    | InitialServerSelected Player
    | MatchFormatSelected MatchFormat
    | SetFormatSelected SetFormat
    | DeuceFormatSelected DeuceFormat
    | SurfaceToggled Surface
    | DateChanged String
    | SubmitForm
    | CancelForm



-- VALIDATION


isFormValid : Model -> Bool
isFormValid model =
    not (String.isEmpty (String.trim model.playerAName))
        && not (String.isEmpty (String.trim model.playerBName))
        && model.initialServer
        /= Nothing



-- UPDATE


update : Msg -> Model -> ( Model, Event )
update msg model =
    case msg of
        PlayerANameChanged name ->
            ( { model | playerAName = name }, NoEvent )

        PlayerBNameChanged name ->
            ( { model | playerBName = name }, NoEvent )

        InitialServerSelected player ->
            ( { model | initialServer = Just player }, NoEvent )

        MatchFormatSelected format ->
            ( { model | matchFormat = format }, NoEvent )

        SetFormatSelected format ->
            ( { model | setFormat = format }, NoEvent )

        DeuceFormatSelected format ->
            ( { model | deuceFormat = format }, NoEvent )

        SurfaceToggled surface ->
            ( { model
                | surface =
                    if model.surface == Just surface then
                        Nothing

                    else
                        Just surface
              }
            , NoEvent
            )

        DateChanged date ->
            ( { model | date = date }, NoEvent )

        SubmitForm ->
            case model.initialServer of
                Just server ->
                    ( model
                    , FormSubmitted
                        { initialServer = server
                        , matchFormat = model.matchFormat
                        , setFormat = model.setFormat
                        , tiebreakFormat = StandardPlusMatchTiebreak
                        , deuceFormat = model.deuceFormat
                        }
                        { playerAName = String.trim model.playerAName
                        , playerBName = String.trim model.playerBName
                        , surface = model.surface
                        , date = model.date
                        }
                    )

                Nothing ->
                    ( model, NoEvent )

        CancelForm ->
            ( model, FormCancelled )



-- VIEW


view : Model -> Html Msg
view model =
    div
        [ class "min-h-screen bg-gray-900 text-gray-50 max-w-[480px] mx-auto" ]
        [ viewHeader
        , viewContent model
        ]


viewHeader : Html Msg
viewHeader =
    div
        [ class "sticky top-0 z-10 bg-gray-900 border-b border-gray-700 flex items-center justify-between py-4 px-5" ]
        [ h1
            [ class "text-xl font-bold m-0" ]
            [ text "New Match" ]
        , button
            [ onClick CancelForm
            , class "bg-transparent border-0 rounded-md text-gray-400 text-sm font-semibold cursor-pointer py-2 px-4"
            ]
            [ text "Cancel " ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    div
        [ class "px-4 pt-4 pb-10" ]
        [ viewPlayersSection model
        , viewInitialServerSection model
        , viewMatchFormatSection model
        , viewSetFormatSection model
        , viewTiebreakFormatSection
        , viewDeuceFormatSection model
        , viewSurfaceSection model
        , viewDateSection model
        , viewSubmitButton model
        ]


viewPlayersSection : Model -> Html Msg
viewPlayersSection model =
    viewCard "Players"
        [ div
            [ class "flex flex-col gap-[10px]" ]
            [ div []
                [ div
                    [ class "text-[11px] text-gray-500 mb-[6px]" ]
                    [ text "Player A — being scouted" ]
                , input
                    [ type_ "text"
                    , placeholder "Name"
                    , value model.playerAName
                    , onInput PlayerANameChanged
                    , class "bg-gray-700 border-0 rounded-lg text-gray-50 text-[15px] py-[11px] px-[14px] w-full box-border outline-none"
                    ]
                    []
                ]
            , div []
                [ div
                    [ class "text-[11px] text-gray-500 mb-[6px]" ]
                    [ text "Player B — opponent" ]
                , input
                    [ type_ "text"
                    , placeholder "Name"
                    , value model.playerBName
                    , onInput PlayerBNameChanged
                    , class "bg-gray-700 border-0 rounded-lg text-gray-50 text-[15px] py-[11px] px-[14px] w-full box-border outline-none"
                    ]
                    []
                ]
            ]
        ]


viewInitialServerSection : Model -> Html Msg
viewInitialServerSection model =
    let
        playerALabel =
            if String.isEmpty model.playerAName then
                "Player A"

            else
                model.playerAName

        playerBLabel =
            if String.isEmpty model.playerBName then
                "Player B"

            else
                model.playerBName
    in
    viewCard "Initial Server"
        [ div [ class "flex gap-2" ]
            [ viewSegmentButton playerALabel (model.initialServer == Just PlayerA) (InitialServerSelected PlayerA)
            , viewSegmentButton playerBLabel (model.initialServer == Just PlayerB) (InitialServerSelected PlayerB)
            ]
        ]


viewMatchFormatSection : Model -> Html Msg
viewMatchFormatSection model =
    viewCard "Match Format"
        [ div [ class "flex gap-2" ]
            [ viewSegmentButton "Best of 3" (model.matchFormat == BestOfThree) (MatchFormatSelected BestOfThree)
            , viewSegmentButton "Best of 5" (model.matchFormat == BestOfFive) (MatchFormatSelected BestOfFive)
            ]
        ]


viewSetFormatSection : Model -> Html Msg
viewSetFormatSection model =
    viewCard "Set Format"
        [ div [ class "flex gap-2" ]
            [ viewSegmentButton "Standard" (model.setFormat == StandardSet) (SetFormatSelected StandardSet)
            , viewSegmentButton "Pro Set" (model.setFormat == ProSet) (SetFormatSelected ProSet)
            ]
        ]


viewTiebreakFormatSection : Html Msg
viewTiebreakFormatSection =
    viewCard "Tiebreak Format"
        [ div
            [ class "bg-gray-700 rounded-lg py-[11px] px-[14px] text-sm text-gray-400" ]
            [ text "Standard + match tiebreak" ]
        ]


viewDeuceFormatSection : Model -> Html Msg
viewDeuceFormatSection model =
    viewCard "Deuce Format"
        [ div [ class "flex gap-2" ]
            [ viewSegmentButton "Standard" (model.deuceFormat == StandardDeuce) (DeuceFormatSelected StandardDeuce)
            , viewSegmentButton "No-Ad" (model.deuceFormat == NoAd) (DeuceFormatSelected NoAd)
            ]
        ]


viewSurfaceSection : Model -> Html Msg
viewSurfaceSection model =
    viewCard "Surface"
        [ div
            [ class "grid grid-cols-2 gap-2" ]
            [ viewSurfaceButton "Hard" Hard model.surface
            , viewSurfaceButton "Clay" Clay model.surface
            , viewSurfaceButton "Grass" Grass model.surface
            , viewSurfaceButton "Carpet" Carpet model.surface
            ]
        , div
            [ class "mt-2 text-[11px] text-gray-500" ]
            [ text "Optional — for context only" ]
        ]


viewDateSection : Model -> Html Msg
viewDateSection model =
    viewCard "Date"
        [ input
            [ type_ "date"
            , value model.date
            , onInput DateChanged
            , class "bg-gray-700 border-0 rounded-lg text-gray-50 text-[15px] py-[11px] px-[14px] w-full box-border outline-none"
            ]
            []
        ]


viewSubmitButton : Model -> Html Msg
viewSubmitButton model =
    let
        valid =
            isFormValid model
    in
    div [ class "mt-2" ]
        [ button
            [ onClick SubmitForm
            , disabled (not valid)
            , class
                (if valid then
                    "bg-amber-400 text-gray-900 border-0 rounded-[14px] p-[18px] text-base font-semibold w-full cursor-pointer"

                 else
                    "bg-gray-700 text-gray-500 border-0 rounded-[14px] p-[18px] text-base font-semibold w-full cursor-default"
                )
            ]
            [ text "Start Match" ]
        ]



-- HELPERS


viewCard : String -> List (Html Msg) -> Html Msg
viewCard label children =
    div
        [ class "bg-gray-800 rounded-xl py-3 px-[14px] mb-[10px]" ]
        (div
            [ class "text-[11px] text-gray-500 tracking-[0.05em] uppercase font-medium mb-[10px]" ]
            [ text label ]
            :: children
        )


viewSegmentButton : String -> Bool -> Msg -> Html Msg
viewSegmentButton label isSelected msg =
    button
        [ onClick msg
        , class
            (if isSelected then
                "bg-amber-400 text-gray-900 border-0 rounded-lg py-[11px] px-4 text-[13px] font-medium cursor-pointer flex-1 text-center"

             else
                "bg-gray-700 text-gray-300 border-0 rounded-lg py-[11px] px-4 text-[13px] font-medium cursor-pointer flex-1 text-center"
            )
        ]
        [ text label ]


viewSurfaceButton : String -> Surface -> Maybe Surface -> Html Msg
viewSurfaceButton label surface selectedSurface =
    let
        isSelected =
            selectedSurface == Just surface
    in
    button
        [ onClick (SurfaceToggled surface)
        , class
            (if isSelected then
                "bg-amber-400 text-gray-900 border-0 rounded-lg py-[11px] px-4 text-[13px] font-medium cursor-pointer"

             else
                "bg-gray-700 text-gray-300 border-0 rounded-lg py-[11px] px-4 text-[13px] font-medium cursor-pointer"
            )
        ]
        [ text label ]
