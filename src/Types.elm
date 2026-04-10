module Types exposing
    ( DeuceFormat(..)
    , GameScore(..)
    , MatchConfig
    , MatchFormat(..)
    , MatchState
    , MatchStatus(..)
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
    | UnforcedError


type ServeOutcome
    = Ace
    | ServeWinner
    | DoubleFault
    | InRally Player (Maybe RallyTag) -- Player = who won the rally


type alias Point =
    { server : Player
    , outcome : ServeOutcome
    }



-- SCORE


type GameScore
    = Love
    | Fifteen
    | Thirty
    | Forty
    | DeuceScore
    | Advantage Player


type MatchStatus
    = InProgress
    | WonBy Player


type alias MatchState =
    { pointScore : { ourPlayer : GameScore, opponent : GameScore }
    , gameScore : { ourPlayer : Int, opponent : Int }
    , setScores : List { ourPlayer : Int, opponent : Int }
    , tiebreak : Maybe { ourPlayer : Int, opponent : Int }
    , currentServer : Player
    , isBreakPoint : Bool
    , matchStatus : MatchStatus
    , totalPoints : { played : Int, wonByOurPlayer : Int, wonByOpponent : Int }
    }
