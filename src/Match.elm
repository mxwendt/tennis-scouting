module Match exposing
    ( DeuceFormat(..)
    , Match
    , MatchConfig
    , MatchFormat(..)
    , MatchMetadata
    , Player(..)
    , Point
    , RallyTag(..)
    , ServeOutcome(..)
    , SetFormat(..)
    , Surface(..)
    , TiebreakFormat(..)
    )

-- PLAYER


type Player
    = PlayerA
    | PlayerB



-- MATCH CONFIG


type MatchFormat
    = BestOfThree
    | BestOfFive


type SetFormat
    = StandardSet -- first to 6, win by 2
    | ProSet -- first to 8, win by 2


{-| The tiebreak format for the match.

  - StandardPlusMatchTiebreak: standard tiebreak (first to 7) in all non-final
    sets; match tiebreak (first to 10) in the final set.

-}
type TiebreakFormat
    = StandardPlusMatchTiebreak


type DeuceFormat
    = StandardDeuce -- advantage scoring
    | NoAd -- single point at deuce wins the game


type alias MatchConfig =
    { initialServer : Player
    , matchFormat : MatchFormat
    , setFormat : SetFormat
    , tiebreakFormat : TiebreakFormat
    , deuceFormat : DeuceFormat
    }



-- MATCH METADATA


type Surface
    = Hard
    | Clay
    | Grass
    | Carpet


type alias MatchMetadata =
    { playerAName : String
    , playerBName : String
    , surface : Maybe Surface
    , date : String
    }



-- MATCH


type alias Match =
    { id : Int
    , config : MatchConfig
    , metadata : MatchMetadata
    , points : List Point
    }



-- POINT


type RallyTag
    = Winner


type ServeOutcome
    = Ace
    | ServeWinner
    | DoubleFault
    | InRally Player (Maybe RallyTag) -- Player = who won the rally


type alias Point =
    { server : Player
    , outcome : ServeOutcome
    }
