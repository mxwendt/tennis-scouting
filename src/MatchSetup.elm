module MatchSetup exposing (Event(..), Model, Msg, init, update, view)

import Html exposing (Html, button, div, h1, input, text)
import Html.Attributes exposing (disabled, placeholder, style, type_, value)
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
        [ style "min-height" "100vh"
        , style "background" "#111827"
        , style "color" "#F9FAFB"
        , style "font-family" "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        , style "max-width" "480px"
        , style "margin" "0 auto"
        ]
        [ viewHeader
        , viewContent model
        ]


viewHeader : Html Msg
viewHeader =
    div
        [ style "position" "sticky"
        , style "top" "0"
        , style "z-index" "10"
        , style "background" "#111827"
        , style "border-bottom" "1px solid #374151"
        , style "display" "flex"
        , style "align-items" "center"
        , style "justify-content" "space-between"
        , style "padding" "16px 20px"
        ]
        [ h1
            [ style "font-size" "17px"
            , style "font-weight" "600"
            , style "margin" "0"
            , style "color" "#F9FAFB"
            ]
            [ text "New Match" ]
        , button
            [ onClick CancelForm
            , style "background" "transparent"
            , style "border" "none"
            , style "color" "#9CA3AF"
            , style "font-size" "15px"
            , style "cursor" "pointer"
            , style "padding" "4px 0"
            ]
            [ text "Cancel" ]
        ]


viewContent : Model -> Html Msg
viewContent model =
    div
        [ style "padding" "16px 16px 40px" ]
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
            [ style "display" "flex"
            , style "flex-direction" "column"
            , style "gap" "10px"
            ]
            [ div []
                [ div
                    [ style "font-size" "11px"
                    , style "color" "#6B7280"
                    , style "margin-bottom" "6px"
                    ]
                    [ text "Player A — being scouted" ]
                , input
                    [ type_ "text"
                    , placeholder "Name"
                    , value model.playerAName
                    , onInput PlayerANameChanged
                    , style "background" "#374151"
                    , style "border" "none"
                    , style "border-radius" "8px"
                    , style "color" "#F9FAFB"
                    , style "font-size" "15px"
                    , style "padding" "11px 14px"
                    , style "width" "100%"
                    , style "box-sizing" "border-box"
                    , style "outline" "none"
                    ]
                    []
                ]
            , div []
                [ div
                    [ style "font-size" "11px"
                    , style "color" "#6B7280"
                    , style "margin-bottom" "6px"
                    ]
                    [ text "Player B — opponent" ]
                , input
                    [ type_ "text"
                    , placeholder "Name"
                    , value model.playerBName
                    , onInput PlayerBNameChanged
                    , style "background" "#374151"
                    , style "border" "none"
                    , style "border-radius" "8px"
                    , style "color" "#F9FAFB"
                    , style "font-size" "15px"
                    , style "padding" "11px 14px"
                    , style "width" "100%"
                    , style "box-sizing" "border-box"
                    , style "outline" "none"
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
        [ div [ style "display" "flex", style "gap" "8px" ]
            [ viewSegmentButton playerALabel (model.initialServer == Just PlayerA) (InitialServerSelected PlayerA)
            , viewSegmentButton playerBLabel (model.initialServer == Just PlayerB) (InitialServerSelected PlayerB)
            ]
        ]


viewMatchFormatSection : Model -> Html Msg
viewMatchFormatSection model =
    viewCard "Match Format"
        [ div [ style "display" "flex", style "gap" "8px" ]
            [ viewSegmentButton "Best of 3" (model.matchFormat == BestOfThree) (MatchFormatSelected BestOfThree)
            , viewSegmentButton "Best of 5" (model.matchFormat == BestOfFive) (MatchFormatSelected BestOfFive)
            ]
        ]


viewSetFormatSection : Model -> Html Msg
viewSetFormatSection model =
    viewCard "Set Format"
        [ div [ style "display" "flex", style "gap" "8px" ]
            [ viewSegmentButton "Standard" (model.setFormat == StandardSet) (SetFormatSelected StandardSet)
            , viewSegmentButton "Pro Set" (model.setFormat == ProSet) (SetFormatSelected ProSet)
            ]
        ]


viewTiebreakFormatSection : Html Msg
viewTiebreakFormatSection =
    viewCard "Tiebreak Format"
        [ div
            [ style "background" "#374151"
            , style "border-radius" "8px"
            , style "padding" "11px 14px"
            , style "font-size" "14px"
            , style "color" "#9CA3AF"
            ]
            [ text "Standard + match tiebreak" ]
        ]


viewDeuceFormatSection : Model -> Html Msg
viewDeuceFormatSection model =
    viewCard "Deuce Format"
        [ div [ style "display" "flex", style "gap" "8px" ]
            [ viewSegmentButton "Standard" (model.deuceFormat == StandardDeuce) (DeuceFormatSelected StandardDeuce)
            , viewSegmentButton "No-Ad" (model.deuceFormat == NoAd) (DeuceFormatSelected NoAd)
            ]
        ]


viewSurfaceSection : Model -> Html Msg
viewSurfaceSection model =
    viewCard "Surface"
        [ div
            [ style "display" "grid"
            , style "grid-template-columns" "1fr 1fr"
            , style "gap" "8px"
            ]
            [ viewSurfaceButton "Hard" Hard model.surface
            , viewSurfaceButton "Clay" Clay model.surface
            , viewSurfaceButton "Grass" Grass model.surface
            , viewSurfaceButton "Carpet" Carpet model.surface
            ]
        , div
            [ style "margin-top" "8px"
            , style "font-size" "11px"
            , style "color" "#6B7280"
            ]
            [ text "Optional — for context only" ]
        ]


viewDateSection : Model -> Html Msg
viewDateSection model =
    viewCard "Date"
        [ input
            [ type_ "date"
            , value model.date
            , onInput DateChanged
            , style "background" "#374151"
            , style "border" "none"
            , style "border-radius" "8px"
            , style "color" "#F9FAFB"
            , style "font-size" "15px"
            , style "padding" "11px 14px"
            , style "width" "100%"
            , style "box-sizing" "border-box"
            , style "outline" "none"
            ]
            []
        ]


viewSubmitButton : Model -> Html Msg
viewSubmitButton model =
    let
        valid =
            isFormValid model
    in
    div [ style "margin-top" "8px" ]
        [ button
            [ onClick SubmitForm
            , disabled (not valid)
            , style "background"
                (if valid then
                    "#FBBF24"

                 else
                    "#374151"
                )
            , style "color"
                (if valid then
                    "#111827"

                 else
                    "#6B7280"
                )
            , style "border" "none"
            , style "border-radius" "14px"
            , style "padding" "18px"
            , style "font-size" "16px"
            , style "font-weight" "600"
            , style "width" "100%"
            , style "cursor"
                (if valid then
                    "pointer"

                 else
                    "default"
                )
            ]
            [ text "Start Match" ]
        ]



-- HELPERS


viewCard : String -> List (Html Msg) -> Html Msg
viewCard label children =
    div
        [ style "background" "#1F2937"
        , style "border-radius" "12px"
        , style "padding" "12px 14px"
        , style "margin-bottom" "10px"
        ]
        (div
            [ style "font-size" "11px"
            , style "color" "#6B7280"
            , style "letter-spacing" "0.05em"
            , style "text-transform" "uppercase"
            , style "font-weight" "500"
            , style "margin-bottom" "10px"
            ]
            [ text label ]
            :: children
        )


viewSegmentButton : String -> Bool -> Msg -> Html Msg
viewSegmentButton label isSelected msg =
    button
        [ onClick msg
        , style "background"
            (if isSelected then
                "#FBBF24"

             else
                "#374151"
            )
        , style "color"
            (if isSelected then
                "#111827"

             else
                "#D1D5DB"
            )
        , style "border" "none"
        , style "border-radius" "8px"
        , style "padding" "11px 16px"
        , style "font-size" "13px"
        , style "font-weight" "500"
        , style "cursor" "pointer"
        , style "flex" "1"
        , style "text-align" "center"
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
        , style "background"
            (if isSelected then
                "#FBBF24"

             else
                "#374151"
            )
        , style "color"
            (if isSelected then
                "#111827"

             else
                "#D1D5DB"
            )
        , style "border" "none"
        , style "border-radius" "8px"
        , style "padding" "11px 16px"
        , style "font-size" "13px"
        , style "font-weight" "500"
        , style "cursor" "pointer"
        ]
        [ text label ]
