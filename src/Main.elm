module Main exposing (main)

import Browser
import Html exposing (Html, h1, text)



-- MAIN


main : Program () Model Never
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }



-- MODEL


type alias Model =
    {}


init : Model
init =
    {}



-- UPDATE


update : Never -> Model -> Model
update msg _ =
    never msg



-- VIEW


view : Model -> Html Never
view _ =
    h1 [] [ text "Tennis Scouting" ]
