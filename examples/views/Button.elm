module Button where

import Html exposing (Html, a, text)
import Html.Attributes exposing (classList)
import String exposing (toLower)


type alias Model =
  { color : Color
  , message : String
  }

type Color
  = Primary
  | Secondary
  | Success
  | Alert
  | Warning
  | Disabled

view : Model -> Html
view model =
  a
    [ classList
        [ ("button", True)
        , ((toLower << toString) model.color, True)
        ]
    ]
    [ text model.message ]
