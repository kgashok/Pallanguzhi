module App.BoardView where

import Data.Maybe
import App.FixedMatrix72 as FM
import App.Turn as Turn
import Data.Array as Array
import Pux.CSS as C
import Pux.Html as H
import App.Board (Pit, PitRef, Player, Board, getStore, isBlocked)
import App.FixedMatrix72 (Row(B, A))
import App.Hand (Hand)
import App.Turn (Turn)
import CSS (gray)
import Data.Traversable (sequence)
import Prelude (bind, const, pure, show, ($), (<), (<$>), (<<<), (<>), (==), (#))
import Pux.CSS (Color, em, pct, hsl, px, style)
import Pux.Html (Html, div, text)
import Pux.Html.Events (onClick)

class BoardView state action | state -> action where
  getBoard :: state -> Board
  getHand :: state -> Maybe Hand
  getTurn :: state -> Maybe Turn
  getCurrentPlayer :: state -> Maybe Player
  getPitAction :: state -> PitRef -> Maybe action

isPlaying :: forall state action. BoardView state action => state -> Player -> Boolean
isPlaying state player = fromMaybe false $ do
  currentPlayer <- getCurrentPlayer state
  pure $ player == currentPlayer

type PitState = Maybe Turn

pitState :: forall state action. BoardView state action
         => state -> PitRef -> PitState
pitState state ref = do
  hand <- getHand state
  if ref == hand.pitRef
    then getTurn state
    else Nothing

pitColor :: PitState -> Color
pitColor (Just (Turn.Capture _)) = hsl 300.0 1.0 0.3
pitColor (Just Turn.Lift) = hsl 150.0 1.0 0.3
pitColor (Just Turn.Sow) = C.lighten 0.4 $ pitColor Nothing
pitColor _ = hsl 70.0 1.0 0.3

view :: forall action state. BoardView state action
     => state -> Html action
view state =
  div []
  [ viewStore state A
  , viewRow A
  , viewRow B
  , viewStore state B
  ]
  where
    board =
      getBoard state
    viewRow player =
      div [] $ FM.mapRowWithIndex player (viewPit state) board.cells

viewStore :: forall action state. BoardView state action
          => state -> Row -> Html action
viewStore state player =
  H.pre [css] [ text s ]
    where s = viewPlayer player <> showPadded seeds
          seeds = getStore player board
          board = getBoard state
          color = if isPlaying state player
                    then pitColor (Just Turn.Sow)
                    else pitColor Nothing # C.darken 0.1
          css = style do
            C.display C.inlineFlex
            C.textAlign C.center
            C.fontSize (em 2.5)
            C.backgroundColor color
            C.width (pct 20.0)
            C.height (em 2.0)
            C.marginLeft (pct 35.0)
            C.border C.solid (px 1.0) C.black
            C.padding (em 0.0) (em padding) (em 0.0) (em padding)
              where padding = 0.5


viewPit :: forall action state. BoardView state action
        => state -> PitRef -> Pit -> Html action
viewPit state ref count =
  H.div (getJusts [css, event]) [body]
  where
    body = div [style do apply4 C.margin (em 1.0) ] [text content ]
    blocked = isBlocked ref (getBoard state)
    content = if blocked then "X" else showPadded count
    event = onClick <$> const <$> getPitAction state ref
    color = pitColor $ pitState state ref
    css = Just $ style do
      C.display C.inlineFlex
      C.width (pct 10.0)
      C.height (em 3.0)
      C.textAlign C.center
      C.fontSize (em 2.5)
      C.backgroundColor $ if blocked then gray else color
      C.padding (em 0.0) (em padding) (em 0.0) (em padding)
      apply4 C.margin (em 0.0)
      C.border C.solid (px 1.0) C.black
        where padding = 0.5

showPadded :: Int -> String
showPadded n =
  if n < 10
    then " " <> show n <> extra
    else show n <> extra
      where extra = "  "

viewPlayer :: Player -> String
viewPlayer A = "A"
viewPlayer B = "B"

getJusts :: forall a. Array (Maybe a) -> Array a
getJusts = fromMaybe [] <<< sequence <<< Array.filter isJust

apply4 :: forall a b. (a -> a -> a -> a -> b) -> a -> b
apply4 f a = f a a a a
