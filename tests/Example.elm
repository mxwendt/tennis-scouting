module Example exposing (..)

import Expect
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Sanity checks"
        [ test "addition works" <|
            \_ ->
                Expect.equal 4 (2 + 2)
        , test "string concatenation works" <|
            \_ ->
                Expect.equal "Tennis Scouting" ("Tennis" ++ " " ++ "Scouting")
        ]
