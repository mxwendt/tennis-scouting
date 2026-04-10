module Match exposing
    ( DeuceFormat(..)
    , MatchConfig
    , MatchFormat(..)
    , Player(..)
    , Point
    , RallyTag(..)
    , ServeOutcome(..)
    , SetFormat(..)
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


type DeuceFormat
    = StandardDeuce -- advantage scoring
    | NoAd -- single point at deuce


type alias MatchConfig =
    { initialServer : Player
    , matchFormat : MatchFormat
    , setFormat : SetFormat
    , deuceFormat : DeuceFormat
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
