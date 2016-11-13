module Util.ModelE exposing (..)

import Html exposing (Html)

type alias ModelE e model = Result (e, model) model

getModel : ModelE e model -> model
getModel r =
  case r of
    Ok model ->
      model
    Err (_, model) ->
      model

updateE : (msg -> model -> Result e (model, Cmd msg)) -> msg -> ModelE e model -> (ModelE e model, Cmd msg)
updateE update msg modelE =
  let 
    model = 
      getModel modelE
    r = 
      update msg model
  in 
    case r of
      Err error ->
        (Err (error, model), Cmd.none)
      Ok (model, cmd) ->
        (Ok model, cmd)

viewE : (model -> Maybe e -> Html msg) -> ModelE e model -> Html msg 
viewE view modelE =
  case modelE of
    Ok model ->
      view model Nothing
    Err (error, model) ->
      view model (Just error)